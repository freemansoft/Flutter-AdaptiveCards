/// Scores whether a model can *edit* the card it just sent.
///
/// Every other probe here judges a single reply. The server does not work that
/// way: a card reply's raw JSON is stored as `replyText` and replayed verbatim
/// as assistant history, so a follow-up turn arrives with the previous card
/// literally in context. "Now let me pick more than one of those" should be a
/// small edit to that structure — flip `isMultiSelect`, keep the choices.
///
/// This probe asks whether that holds. Turn 1 asks for a pick-one list; turn 2
/// asks to widen it, referring back rather than restating the items. A pass
/// requires all three of:
///
/// 1. turn 1 renders as a card containing an `Input.ChoiceSet`;
/// 2. turn 2 renders as a card whose `Input.ChoiceSet` is `isMultiSelect:true`;
/// 3. turn 2 keeps **every** choice turn 1 offered.
///
/// Point 3 is the one no existing probe covers, and it is the failure actually
/// observed: a model that cascades the format correctly and silently drops
/// items off the list. Shape-only scoring calls that a pass.
///
/// ```sh
/// fvm dart run tool/model_probes/cascade_ab.dart --model qwen2.5-coder:7b
/// fvm dart run tool/model_probes/cascade_ab.dart --only states
/// fvm dart run tool/model_probes/cascade_ab.dart --no-seed-card
/// ```
library;

import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:adaptive_chat_server_dart/src/seed_card.dart';
import 'package:args/args.dart';
// Relative: these live outside lib/, beside this file.
import 'cascade_cases.dart';
import 'probe_results.dart';
import 'probe_support.dart';

/// The `Input.ChoiceSet` findings from one reply, or why there were none.
class ChoiceSetReading {
  /// Creates a reading.
  const ChoiceSetReading({this.titles, this.multiSelect, this.failure});

  /// Choice titles in the order the model offered them.
  final List<String>? titles;

  /// The set's `isMultiSelect`, defaulting to false when the model omits it —
  /// which is what the Adaptive Cards spec says it means.
  final bool? multiSelect;

  /// Why no choice set could be read, or null on success.
  final String? failure;

  /// Whether a choice set was found.
  bool get ok => failure == null;
}

/// Reads the first `Input.ChoiceSet` out of [reply], judging the card exactly
/// as the server does before looking inside it.
ChoiceSetReading readChoiceSet(String reply) {
  final body = tryParseCardBody(reply);
  if (body == null) {
    // A null reason means the reply never attempted a card — it is prose, not
    // a broken card. Reporting both as "broken" would blame the model's JSON
    // for a turn where it simply answered in Markdown, which is a different
    // failure with a different fix.
    final reason = cardParseFailureReason(reply);
    return ChoiceSetReading(
      failure: reason == null ? 'prose (no card attempted)' : 'broken: $reason',
    );
  }
  final sets = body.where((e) => e['type'] == 'Input.ChoiceSet');
  if (sets.isEmpty) {
    final types = body.map((e) => e['type']).join(', ');
    return ChoiceSetReading(failure: 'no-choiceset (got $types)');
  }
  final set = sets.first;
  final choices = set['choices'];
  if (choices is! List || choices.isEmpty) {
    return const ChoiceSetReading(failure: 'choiceset with no choices');
  }
  return ChoiceSetReading(
    titles: [
      for (final c in choices)
        if (c is Map && c['title'] != null) '${c['title']}',
    ],
    // Absent means false per the spec, so it is read as a real answer rather
    // than as missing data — a turn-1 set without the key is a valid
    // single-select, and only turn 2 cares about the distinction.
    multiSelect: set['isMultiSelect'] == true,
  );
}

/// The verdict for one cascade run.
class CascadeResult {
  /// Creates a result.
  const CascadeResult({required this.pass, required this.detail});

  /// Whether all three requirements held.
  final bool pass;

  /// Human-readable outcome.
  final String detail;
}

/// Applies the three pass conditions to one turn-1 / turn-2 pair.
CascadeResult judgeCascade(String firstReply, String secondReply) {
  final one = readChoiceSet(firstReply);
  if (!one.ok) return CascadeResult(pass: false, detail: 't1 ${one.failure}');

  final two = readChoiceSet(secondReply);
  if (!two.ok) return CascadeResult(pass: false, detail: 't2 ${two.failure}');

  if (two.multiSelect != true) {
    return const CascadeResult(
      pass: false,
      detail: 't2 not-multi: isMultiSelect stayed false',
    );
  }

  // Compared case-insensitively: a model that re-cases a title has kept the
  // choice, and scoring that a drop would report a loss the user never sees.
  final before = one.titles!.map((t) => t.toLowerCase()).toSet();
  final after = two.titles!.map((t) => t.toLowerCase()).toSet();
  final dropped = before.difference(after);
  if (dropped.isNotEmpty) {
    return CascadeResult(
      pass: false,
      detail:
          't2 dropped ${dropped.length}/${before.length}: '
          '${(dropped.toList()..sort()).join(', ')}',
    );
  }
  final added = after.difference(before).length;
  return CascadeResult(
    pass: true,
    detail:
        'multi, kept ${before.length}/${before.length}'
        '${added > 0 ? ' (+$added new)' : ''}',
  );
}

/// Resolves `--only` to a case list, rejecting unknown ids.
List<CascadeCase> selectCases(String? only) {
  if (only == null) return cascadeCases;
  final wanted = only
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
  final selected = cascadeCases.where((c) => wanted.contains(c.id)).toList();
  final unknown = wanted.difference(selected.map((c) => c.id).toSet());
  if (unknown.isNotEmpty) {
    stderr
      ..writeln('Unknown case id(s): ${(unknown.toList()..sort()).join(', ')}')
      ..writeln('Known ids: ${cascadeCases.map((c) => c.id).join(', ')}');
    exit(2);
  }
  return selected;
}

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('only', help: 'Comma-separated case ids to run.')
    ..addFlag(
      'seed-card',
      defaultsTo: true,
      help:
          'Prepend the shipped seed exchange, as OllamaResponder does. On by '
          'default so a bare run measures what the server sends; '
          '--no-seed-card measures the unaided baseline.',
    )
    ..addOption('seed-card-file', help: 'Seed exchange to use.')
    ..addOption('json', help: 'Write the run to this JSON file.')
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

  final seedTurns = <String>[
    if (parsed['seed-card'] as bool)
      ...loadSeedCardMessages(
        parsed['seed-card-file'] as String? ?? defaultSeedCardPath(),
      ).map((m) => m.content),
  ];
  if ((parsed['seed-card'] as bool) && seedTurns.isEmpty) {
    stderr.writeln(
      'cascade_ab: --seed-card is on but the seed file loaded no turns; '
      'refusing to run, because the result would be labeled seed-card while '
      'measuring no seed at all.',
    );
    exitCode = 2;
    return;
  }

  final cases = selectCases(parsed['only'] as String?);
  final systemPrompt = loadCardSystemPrompt();
  final client = HttpClient()..idleTimeout = const Duration(minutes: 10);

  stdout.writeln(
    '\n===== ${args.model}'
    '${seedTurns.isEmpty ? ' [no-seed-card]' : ' [seed-card]'} =====',
  );
  var passing = 0;
  // Counted apart from failures: a case whose turn 1 produced no card never
  // exercised the cascade, so scoring it as a cascade failure would blame this
  // probe's question for a shortcoming the shape probe already measures.
  var notExercised = 0;
  final collect = <ProbeCall>[];
  for (final c in cases) {
    var allPassed = true;
    var everReachedTurnTwo = false;
    for (var i = 0; i < args.samples; i++) {
      final first = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: c.first,
        history: seedTurns,
        options: const {'temperature': 0.0},
        timeout: args.timeout,
      );
      // The server stores a card reply's raw JSON as replyText and replays it
      // verbatim, so the probe replays the model's own bytes rather than a
      // cleaned-up copy. Feeding back anything else measures a conversation
      // the server never has.
      final second = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: c.second,
        history: [...seedTurns, c.first, first.reply],
        options: const {'temperature': 0.0},
        timeout: args.timeout,
      );
      final result = judgeCascade(first.reply, second.reply);
      if (!result.pass) allPassed = false;
      if (!result.detail.startsWith('t1 ')) everReachedTurnTwo = true;
      collect.add(
        ProbeCall(
          caseId: c.id,
          sample: i,
          pass: result.pass,
          label: result.detail,
          ms: first.ms + second.ms,
        ),
      );
      stdout.writeln(
        '${result.pass ? "PASS" : "FAIL"}  ${c.id.padRight(10)} '
        '${result.detail}',
      );
    }
    if (allPassed) {
      passing++;
    } else if (!everReachedTurnTwo) {
      notExercised++;
    }
  }
  final exercised = cases.length - notExercised;
  stdout.writeln(
    exercised == 0
        ? '== cascade n/a — turn 1 produced no card in any case =='
        : '== cascade $passing/$exercised'
              '${notExercised > 0 ? ' ($notExercised not exercised: '
                        'turn 1 produced no card)' : ''} ==',
  );
  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'cascade_ab',
      model: args.model,
      variant: seedTurns.isEmpty ? 'unaided' : null,
      samples: args.samples,
      temperature: 0,
      assetsDir: probeAssetsDir(),
      summary: {
        'cases': cases.length,
        // `exercised` rather than `cases`: a model whose turn 1 never
        // produced a card did not cascade badly, it never cascaded, and
        // folding that into the denominator reports a turn-1 shortcoming
        // twice.
        'exercised': exercised,
        'passed': passing,
        'notExercised': notExercised,
      },
      calls: collect,
    );
  }
  // force: a socket still stuck mid-generation must not keep the
  // process alive after its work is done and its result written.
  client.close(force: true);
}
