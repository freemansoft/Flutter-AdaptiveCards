/// Scores whether a pick-from-a-set question actually yields a clickable card.
///
/// The other probes ask "did the model emit something broken?" and a tidy
/// Markdown list of options passes that bar while completely failing the
/// user — it renders fine and cannot be clicked. This one requires a
/// renderable card that *contains* an `Input.ChoiceSet`, and it sends prior
/// prose turns first, because that is the condition under which the failure
/// actually appears.
///
/// ```sh
/// fvm dart run tool/model_probes/choiceset_ab.dart \
///   --model qwen2.5-coder:7b --candidate /tmp/candidate.txt
/// ```
library;

import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:args/args.dart';
// Relative: this file and its helper both live outside `lib/`.
import 'probe_support.dart';

/// Questions whose right answer is a set the user can pick from.
const _prompts = [
  'what are my options for deployment targets',
  'which log level should I use?',
  'what environments can I deploy to?',
  'what are my options for notification frequency',
  'help me pick a database engine',
  'what build modes can I choose from?',
];

/// Two prose turns, to establish Markdown as the conversation's format.
const _historyUser = 'what is CI/CD?';
const _historyAssistant =
    'CI/CD is a practice where code changes are automatically built, tested, '
    'and deployed.\n\n- **CI** builds and tests every commit.\n'
    '- **CD** ships passing builds to production.';

bool _hasChoiceSet(String reply) {
  final body = tryParseCardBody(reply);
  return body != null && cardContainsAnyType(body, {'Input.ChoiceSet'});
}

Future<int> _run(
  String label,
  String systemPrompt,
  ProbeArgs args,
  HttpClient client,
) async {
  var pass = 0;
  var total = 0;
  stdout.writeln('\n########## $label ##########');
  for (final prompt in _prompts) {
    for (var i = 0; i < args.samples; i++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: prompt,
        history: const [_historyUser, _historyAssistant],
        options: const {'temperature': 0.0},
        timeout: args.timeout,
      );
      final ok = _hasChoiceSet(outcome.reply);
      total++;
      if (ok) pass++;
      stdout.writeln(
        '${ok ? "PASS" : "FAIL"}  ${outcome.label.padRight(28)} $prompt',
      );
    }
  }
  stdout.writeln('== ${label.padRight(12)} choice-set $pass/$total ==');
  return pass;
}

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('baseline', defaultsTo: 'assets/card_system_prompt.txt')
    ..addOption('candidate')
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

  final client = HttpClient()..idleTimeout = const Duration(minutes: 5);
  await _run(
    'baseline',
    File(parsed['baseline'] as String).readAsStringSync().trim(),
    args,
    client,
  );
  final candidate = parsed['candidate'] as String?;
  if (candidate != null) {
    await _run(
      'candidate',
      File(candidate).readAsStringSync().trim(),
      args,
      client,
    );
  }
  // force: a socket still stuck mid-generation must not keep the
  // process alive after its work is done and its result written.
  client.close(force: true);
}
