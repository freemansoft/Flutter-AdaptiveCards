/// A/B-tests two card system prompts over the same set of user prompts.
///
/// Prompt wording is the only lever the server has over a local model's
/// reply shape, so a wording change needs the same evidence as a code
/// change: run both prompts over the failure cases and compare pass rates.
/// Verdicts come from `probe_support.judgeReply`, i.e. the server's own card
/// detection, so a "pass" here is a reply the running server would render.
///
/// ```sh
/// fvm dart run tool/model_probes/prompt_ab.dart \
///   --model qwen2.5-coder:7b \
///   --baseline assets/card_system_prompt.txt \
///   --candidate /tmp/candidate_prompt.txt \
///   --samples 2
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_support.dart';

/// The built-in set is code-flavoured because it was written for the
/// code-explanation investigation. It cannot express other shapes — pass
/// `--prompts` rather than editing this list.
const _defaultUserPrompts = [
  'show me a code snippet',
  'show me a code snippet and explain it',
  'show me a code snippet with a short explanation',
  'give me a code snippet',
  'show me an example of a for loop',
  'how do I read a file in dart? show me a code snippet',
  'write a python function that reverses a string',
  'what is a closure? show an example',
];

List<String> _loadPrompts(String? path) {
  if (path == null) return _defaultUserPrompts;
  return File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toList();
}

Future<void> _run(
  String label,
  String systemPrompt,
  ProbeArgs args,
  HttpClient client,
  List<String> prompts,
) async {
  final outcomes = <ProbeOutcome>[];
  stdout.writeln('\n########## $label ##########');
  for (final userPrompt in prompts) {
    for (var i = 0; i < args.samples; i++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        options: const {'temperature': 0.0},
      );
      outcomes.add(outcome);
      stdout.writeln(
        '${outcome.ok ? "PASS" : "FAIL"}  '
        '${outcome.label.padRight(28)} $userPrompt',
      );
    }
  }
  printSummary(label, outcomes);
}

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('baseline', defaultsTo: 'assets/card_system_prompt.txt')
    ..addOption('candidate')
    ..addOption('model')
    ..addOption('url')
    ..addOption('samples')
    ..addOption(
      'prompts',
      help:
          'File of user prompts, one per line. Lines starting with # and '
          'blank lines are ignored. Defaults to the built-in code set.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  final parsed = parser.parse(argv);
  if (parsed['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }
  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 2);

  final prompts = _loadPrompts(parsed['prompts'] as String?);

  final client = HttpClient()..idleTimeout = const Duration(minutes: 5);
  await _run(
    'baseline',
    File(parsed['baseline'] as String).readAsStringSync().trim(),
    args,
    client,
    prompts,
  );
  final candidate = parsed['candidate'] as String?;
  if (candidate != null) {
    await _run(
      'candidate',
      File(candidate).readAsStringSync().trim(),
      args,
      client,
      prompts,
    );
  }
  client.close();
}
