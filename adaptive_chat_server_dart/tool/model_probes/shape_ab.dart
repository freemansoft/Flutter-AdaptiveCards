/// Scores which Adaptive Card element types a model actually emits.
///
/// The other probes ask "did the model emit something broken?" — a question a
/// tidy Markdown answer passes while completely failing the user. This one
/// names, per prompt, the element types that would answer it acceptably, and
/// runs every case twice: cold-start, and after two prose turns. The gap
/// between those two runs is the shapes a model loses once a conversation has
/// gone to Markdown, which is the number a prompt fix has to move.
///
/// ```sh
/// fvm dart run tool/model_probes/shape_ab.dart --model qwen2.5-coder:7b
/// fvm dart run tool/model_probes/shape_ab.dart --only carousel,gauge
/// fvm dart run tool/model_probes/shape_ab.dart --candidate /tmp/candidate.txt
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
// Relative: these live outside lib/, beside this file.
import 'probe_support.dart';
import 'shape_cases.dart';

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
  required ProbeArgs args,
  required HttpClient client,
}) async {
  stdout.writeln('\n########## $label ##########');
  final passing = <String>{};
  for (final c in cases) {
    var allPassed = true;
    for (var i = 0; i < args.samples; i++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: c.prompt,
        history: withHistory
            ? const [shapeHistoryUser, shapeHistoryAssistant]
            : const [],
        options: const {'temperature': 0.0},
      );
      final result = judgeShape(c, outcome);
      if (!result.pass) allPassed = false;
      stdout.writeln(
        '${result.pass ? "PASS" : "FAIL"}  ${c.id.padRight(13)} '
        '${result.describe()}',
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
  required ProbeArgs args,
  required HttpClient client,
}) async {
  stdout.writeln('\n===== $label =====');
  final cold = await runCondition(
    label: 'cold-start',
    systemPrompt: systemPrompt,
    cases: cases,
    withHistory: false,
    args: args,
    client: client,
  );
  final warm = await runCondition(
    label: 'with-history',
    systemPrompt: systemPrompt,
    cases: cases,
    withHistory: true,
    args: args,
    client: client,
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
      defaultsTo: 'assets/card_system_prompt.txt',
      help: 'System prompt treated as the shipped one.',
    )
    ..addOption('candidate', help: 'A second system prompt to compare.')
    ..addOption('only', help: 'Comma-separated case ids to run.')
    ..addOption('model')
    ..addOption('url')
    ..addOption('samples')
    ..addFlag('help', abbr: 'h', negatable: false);
  final parsed = parser.parse(argv);
  if (parsed['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }
  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);

  final cases = selectCases(parsed['only'] as String?);
  final client = HttpClient()..idleTimeout = const Duration(minutes: 10);
  await runPrompt(
    label: 'baseline',
    systemPrompt: File(parsed['baseline'] as String).readAsStringSync().trim(),
    cases: cases,
    args: args,
    client: client,
  );
  final candidate = parsed['candidate'] as String?;
  if (candidate != null) {
    await runPrompt(
      label: 'candidate',
      systemPrompt: File(candidate).readAsStringSync().trim(),
      cases: cases,
      args: args,
      client: client,
    );
  }
  client.close();
}
