/// Scores which Adaptive Card element types a model actually emits.
///
/// The other probes ask "did the model emit something broken?" — a question a
/// tidy Markdown answer passes while completely failing the user. This one
/// names, per prompt, the element types that would answer it acceptably, and
/// runs every case twice: cold-start, and after two prose turns. The gap
/// between those two runs is the shapes a model loses once a conversation has
/// gone to Markdown, which is the number a prompt fix has to move.
///
/// The card seed is **on by default**, because `OllamaResponder.reply()`
/// prepends it unconditionally — a bare run here measures what the server
/// actually sends. `--no-seed-card` measures the pre-seed baseline, which no
/// user gets; reach for it only when establishing what the seed is worth.
///
/// ```sh
/// fvm dart run tool/model_probes/shape_ab.dart --model qwen2.5-coder:7b
/// fvm dart run tool/model_probes/shape_ab.dart --only carousel,gauge
/// fvm dart run tool/model_probes/shape_ab.dart --candidate /tmp/candidate.txt
/// fvm dart run tool/model_probes/shape_ab.dart --no-seed-card  # pre-seed
/// fvm dart run tool/model_probes/shape_ab.dart --channel tool --no-seed-card
/// ```
///
/// `--channel tool` runs the same 25 cases through the `render_adaptive_card`
/// tool (see `tool_channel.dart`) instead of asking for raw JSON in prose.
/// Only models `tool_call_probe.dart` verdicts `supported` can answer there.
library;

import 'dart:io';

import 'package:args/args.dart';
// Relative: these live outside lib/, beside this file.
import 'probe_results.dart';
import 'probe_support.dart';
import 'shape_cases.dart';
import 'tool_channel.dart';

/// Resolves `--only` to a case list, rejecting unknown ids.
///
/// A typo'd id would otherwise silently shrink the run and produce a score
/// against a smaller denominator than the reader assumes.
List<ShapeCase> selectCases(String? only) {
  if (only == null) return shapeCases;
  final wanted = only
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
  if (wanted.isEmpty) {
    stderr.writeln('--only was empty; pass at least one case id.');
    exit(2);
  }
  final selected = shapeCases.where((c) => wanted.contains(c.id)).toList();
  final unknown = wanted.difference(selected.map((c) => c.id).toSet());
  if (unknown.isNotEmpty) {
    stderr
      ..writeln('Unknown case id(s): ${(unknown.toList()..sort()).join(', ')}')
      ..writeln('Known ids: ${shapeCases.map((c) => c.id).join(', ')}');
    exit(2);
  }
  return selected;
}

/// Runs every case under one condition, returning the ids that passed.
///
/// A case counts as passing only when **every** sample passed, so a score is
/// "cases that held up" rather than "trials that happened to succeed".
Future<Set<String>> runCondition({
  required String label,
  required String systemPrompt,
  required List<ShapeCase> cases,
  required bool withHistory,
  required bool reinforce,
  required List<String> seedTurns,
  required ProbeArgs args,
  required HttpClient client,
  required String channel,
  required Map<String, dynamic> cardTool,
  required Object? format,
  List<ProbeCall>? collect,
}) async {
  stdout.writeln('\n########## $label ##########');
  final passing = <String>{};
  for (final c in cases) {
    var allPassed = true;
    for (var i = 0; i < args.samples; i++) {
      final outcome = channel == 'tool'
          ? await probeOnceViaTool(
              client: client,
              url: args.url,
              model: args.model,
              systemPrompt: systemPrompt,
              userPrompt: c.prompt,
              tool: cardTool,
              history: [
                ...seedTurns,
                if (withHistory) ...[shapeHistoryUser, shapeHistoryAssistant],
              ],
              options: const {'temperature': 0.0},
              timeout: args.timeout,
            )
          : await probeOnce(
              client: client,
              url: args.url,
              model: args.model,
              systemPrompt: systemPrompt,
              userPrompt: c.prompt,
              history: [
                ...seedTurns,
                if (withHistory) ...[shapeHistoryUser, shapeHistoryAssistant],
              ],
              reminder: reinforce ? reinforceReminder : null,
              format: format,
              options: const {'temperature': 0.0},
              timeout: args.timeout,
            );
      final result = judgeShape(c, outcome);
      if (!result.pass) allPassed = false;
      collect?.add(
        ProbeCall(
          caseId: c.id,
          sample: i,
          pass: result.pass,
          label: result.describe(),
          condition: withHistory ? 'warm' : 'cold',
          ms: outcome.ms,
        ),
      );
      stdout.writeln(
        '${result.pass ? "PASS" : "FAIL"}  ${c.id.padRight(13)} '
        '${outcome.ms.toString().padLeft(6)}ms  ${result.describe()}',
      );
    }
    if (allPassed) passing.add(c.id);
  }
  stdout.writeln(
    '== ${label.padRight(14)} shapes ${passing.length}/${cases.length} ==',
  );
  return passing;
}

/// Runs both conditions for one system prompt and prints the erosion delta.
Future<void> runPrompt({
  required String label,
  required String systemPrompt,
  required List<ShapeCase> cases,
  required bool reinforce,
  required List<String> seedTurns,
  required ProbeArgs args,
  required HttpClient client,
  required String channel,
  required Map<String, dynamic> cardTool,
  required Object? format,
  List<ProbeCall>? collect,
}) async {
  final flags = [
    if (reinforce) 'reinforce',
    if (seedTurns.isNotEmpty) 'seed-card',
    if (channel == 'tool') 'channel=tool',
  ];
  stdout.writeln(
    '\n===== $label${flags.isEmpty ? '' : ' [${flags.join(', ')}]'} =====',
  );
  final cold = await runCondition(
    label: 'cold-start',
    systemPrompt: systemPrompt,
    cases: cases,
    withHistory: false,
    reinforce: reinforce,
    seedTurns: seedTurns,
    args: args,
    client: client,
    channel: channel,
    cardTool: cardTool,
    format: format,
    collect: collect,
  );
  final warm = await runCondition(
    label: 'with-history',
    systemPrompt: systemPrompt,
    cases: cases,
    withHistory: true,
    reinforce: reinforce,
    seedTurns: seedTurns,
    args: args,
    channel: channel,
    cardTool: cardTool,
    format: format,
    client: client,
    collect: collect,
  );
  // Derived from the two sets, so the count can never disagree with the list.
  final eroded = (cold.difference(warm).toList())..sort();
  stdout.writeln(
    eroded.isEmpty
        ? '\n== eroded by history: none =='
        : '\n== eroded by history: ${eroded.join(', ')} (${eroded.length}) ==',
  );
}

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption(
      'baseline',
      help:
          'System prompt treated as the shipped one. Defaults to '
          'card_system_prompt.txt on the prose channel and '
          'card_tool_prompt.txt on the tool channel — the two are not '
          'interchangeable, since only the latter mentions the tool.',
    )
    ..addOption('candidate', help: 'A second system prompt to compare.')
    ..addOption('only', help: 'Comma-separated case ids to run.')
    ..addOption(
      'json-format',
      defaultsTo: 'none',
      allowed: ['none', 'json', 'schema'],
      help:
          'Constrained decoding for the prose channel, mirroring the '
          "server's --json-format. Only meaningful for a model whose "
          'json_format_probe verdict is honored on the runtime under test; '
          'a model that ignores the constraint produces an identical arm.',
    )
    ..addOption(
      'channel',
      defaultsTo: 'prose',
      allowed: ['prose', 'tool'],
      help:
          'Reply channel. prose asks for card JSON in the message body and '
          'guesses whether it is a card; tool offers a render_adaptive_card '
          'function and reads its arguments. Only models verdicted supported '
          'by tool_call_probe.dart can answer on the tool channel.',
    )
    ..addFlag(
      'reinforce',
      negatable: false,
      help:
          'N1: inject a shape reminder as a system message after the '
          'history, immediately before the current user turn.',
    )
    ..addFlag(
      'seed-card',
      defaultsTo: true,
      help:
          'Prepend the synthetic card-shaped exchange ahead of the replayed '
          'history, so a card is the established format. Reads the same asset '
          'the server ships, so a measurement here is a measurement of what '
          'runs. On by default because OllamaResponder.reply() seeds '
          'unconditionally — pass --no-seed-card only to measure the pre-seed '
          'baseline, which is not what any user gets.',
    )
    ..addOption(
      'seed-card-file',
      help:
          'Seed exchange to use with --seed-card (default: '
          'assets/seed_card.json). Point it at a candidate file to measure a '
          're-tuned seed the way prompt candidates use --candidate.',
    )
    ..addOption(
      'json',
      help:
          'Write the run to this JSON file: every call, plus the digests of '
          'the prompt assets it used. Written so a number in ModelBehavior.md '
          'can be re-derived and diffed rather than trusted, and so CI can '
          'detect a result gone stale without running a model.',
    )
    ..addOption('model')
    ..addOption('url')
    ..addOption('samples')
    ..addOption(
      'timeout',
      help:
          'Seconds one call may take before it is scored a timeout. A model '
          'that runs away generating otherwise stalls every model queued '
          'behind it.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  final parsed = parser.parse(argv);
  if (parsed['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }
  final args = parseProbeArgs([
    for (final option in [
      'model',
      'url',
      'samples',
      'json',
      'timeout',
    ])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);

  final channel = parsed['channel'] as String;
  final jsonFormat = parsed['json-format'] as String;
  if (channel == 'tool' && (parsed['seed-card'] as bool)) {
    stderr.writeln(
      'shape_ab: --channel tool cannot be combined with the seed card. The '
      'seed is a prose-channel artifact — a synthetic assistant turn holding '
      'raw card JSON — so seeding the tool channel measures neither channel '
      'cleanly. Pass --no-seed-card; the tool arm is compared against the '
      'recorded unaided prose run.',
    );
    exitCode = 2;
    return;
  }
  if (channel == 'tool' && jsonFormat != 'none') {
    stderr.writeln(
      'shape_ab: --channel tool already carries the schema in the tool '
      'definition, so --json-format on top of it measures neither '
      'constraint cleanly. Drop one.',
    );
    exitCode = 2;
    return;
  }

  final cases = selectCases(parsed['only'] as String?);
  final client = HttpClient()..idleTimeout = const Duration(minutes: 10);
  final reinforce = parsed['reinforce'] as bool;
  final probeFormat = resolveProbeFormat(jsonFormat);
  final cardTool = renderCardTool(loadCardSchema());
  // Flat alternating user/assistant contents, the shape `probeOnce` replays
  // history in. Populated unless --no-seed-card opted out of the seed.
  final seedTurns = <String>[
    if (parsed['seed-card'] as bool)
      ...loadSeedCardMessages(
        parsed['seed-card-file'] as String? ?? defaultSeedCardPath(),
      ).map((m) => m.content),
  ];
  if ((parsed['seed-card'] as bool) && seedTurns.isEmpty) {
    stderr.writeln(
      'shape_ab: --seed-card was passed but the seed file loaded no turns; '
      'see the warning above. Refusing to run, because the result would be '
      'labeled seed-card while measuring no seed at all.',
    );
    exitCode = 2;
    return;
  }
  // The prose-channel prompt tells the model the entire reply must be raw
  // JSON, which is false when a tool is offered instead — pairing them would
  // measure a contradiction, not the tool channel.
  final defaultPrompt = channel == 'tool'
      ? 'assets/card_tool_prompt.txt'
      : 'assets/card_system_prompt.txt';
  final baselinePath = parsed.wasParsed('baseline')
      ? parsed['baseline'] as String
      : defaultPrompt;
  final collect = <ProbeCall>[];
  await runPrompt(
    label: 'baseline',
    systemPrompt: File(baselinePath).readAsStringSync().trim(),
    cases: cases,
    reinforce: reinforce,
    seedTurns: seedTurns,
    args: args,
    client: client,
    channel: channel,
    cardTool: cardTool,
    format: probeFormat,
    collect: collect,
  );
  final candidate = parsed['candidate'] as String?;
  if (candidate != null) {
    await runPrompt(
      label: 'candidate',
      systemPrompt: File(candidate).readAsStringSync().trim(),
      cases: cases,
      reinforce: reinforce,
      seedTurns: seedTurns,
      args: args,
      client: client,
      channel: channel,
      cardTool: cardTool,
      format: probeFormat,
    );
  }
  final jsonPath = parsed['json'] as String?;
  if (jsonPath != null) {
    final seeded = parsed['seed-card'] as bool;
    final cold = collect.where((c) => c.condition == 'cold');
    final warm = collect.where((c) => c.condition == 'warm');
    // A case passes only if every sample of it passed, matching what the
    // probe printed and what ModelBehavior.md quotes.
    int shapes(Iterable<ProbeCall> calls) {
      final byCase = <String, bool>{};
      for (final c in calls) {
        byCase[c.caseId] = (byCase[c.caseId] ?? true) && c.pass;
      }
      return byCase.values.where((v) => v).length;
    }

    final run = ProbeRun(
      probe: 'shape_ab',
      model: args.model,
      variant: switch (channel) {
        'tool' => 'channel-tool',
        // The format mode is part of the identity of a run: an unconstrained
        // arm and a schema-constrained one are different measurements, and
        // sync_shape_table.dart selects the canonical row by an exact
        // `variant == 'seeded'` match. A constrained run recorded as plain
        // `seeded` would become a second candidate for that row.
        _ =>
          '${seeded ? 'seeded' : 'unaided'}'
              '${jsonFormat == 'none' ? '' : '-format-$jsonFormat'}',
      },
      measuredAt: DateTime.now().toIso8601String().split('T').first,
      machine: detectMachine(),
      ollama: detectOllamaVersion(),
      samples: args.samples,
      temperature: 0,
      assets: currentAssetDigests(
        probeAssetsDir(),
        assetNames: channel == 'tool'
            ? const ['card_tool_prompt.txt']
            : defaultProbeAssetNames,
      ),
      summary: {
        'cases': cases.length,
        'coldStart': shapes(cold),
        'withHistory': shapes(warm),
      },
      calls: collect,
    )..write(File(jsonPath));
    stdout.writeln(
      '\nwrote $jsonPath  (median ${run.medianMs}ms/call, '
      'total ${((run.totalMs ?? 0) / 1000).round()}s, on ${run.machine})',
    );
  }
  // force: a socket still stuck mid-generation must not keep the
  // process alive after its work is done and its result written.
  client.close(force: true);
}
