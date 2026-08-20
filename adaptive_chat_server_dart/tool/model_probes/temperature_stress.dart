/// Probes the card requests that actually break, across two temperatures.
///
/// These are the long, nested, quote-heavy and newline-heavy asks the card
/// system prompt spends most of its rules warning the model about — the ones
/// that separate settings when `temperature_matrix.dart` shows 7/7 for
/// everything.
///
/// Also counts **distinct outputs per cell**, which is how the claim that
/// temperature 0 is "deterministic" was disproved: greedy decoding repeats
/// short replies verbatim, but long generations still diverge.
///
/// ```sh
/// fvm dart run tool/model_probes/temperature_stress.dart \
///   --model qwen3.6:27b-coding-nvfp4 --samples 3
/// ```
///
/// Slow by design — a 12-month table on a 27B model runs ~80s per call, so a
/// 3-sample run is tens of minutes. Run it in the background.
library;

import 'dart:io';

// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_results.dart';
import 'probe_support.dart';

const _prompts = <String, String>{
  'codeblock':
      'Show me a Dart snippet that reads a JSON file and prints the "name" '
      'field, with a short explanation above it.',
  'bigtable':
      'Give me a table of all 12 months with the number of days and a '
      'notable holiday in each.',
  'nested':
      'Build me a full expense report form: a title, a date picker, an '
      'amount field, a category dropdown with 6 categories, a multiline '
      'notes box, and submit/cancel buttons.',
  'multiline':
      'Explain the three laws of robotics in a card, with each law on its '
      'own line as a numbered markdown list, and quote each law exactly.',
  'mixed':
      'Compare Flutter and React Native across 5 dimensions in a table, then '
      'ask me which one I am leaning toward with a choice set.',
};

const _settings = <String, Map<String, dynamic>>{
  'greedy(t=0)': {'temperature': 0.0},
  'recommended(t=0.6)': {'temperature': 0.6, 'top_p': 0.95, 'top_k': 20},
};

Future<void> main(List<String> argv) async {
  final args = parseProbeArgs(argv);
  final systemPrompt = loadCardSystemPrompt();
  final client = HttpClient()..idleTimeout = const Duration(minutes: 10);

  final collect = <ProbeCall>[];
  for (final setting in _settings.entries) {
    final outcomes = <ProbeOutcome>[];
    for (final prompt in _prompts.entries) {
      final hashes = <String>{};
      for (var i = 0; i < args.samples; i++) {
        final outcome = await probeOnce(
          client: client,
          url: args.url,
          model: args.model,
          systemPrompt: systemPrompt,
          userPrompt: prompt.value,
          options: setting.value,
          timeout: args.timeout,
        );
        outcomes.add(outcome);
        collect.add(
          ProbeCall(
            caseId: prompt.key,
            sample: i,
            pass: outcome.ok,
            label: outcome.label,
            setting: setting.key,
            ms: outcome.ms,
          ),
        );
        hashes.add(outcome.hash);
        stdout.writeln(
          '${setting.key.padRight(20)} ${prompt.key.padRight(10)} #$i  '
          '${outcome.ok ? "PASS" : "FAIL"}  ${outcome.ms}ms  '
          '${outcome.chars}c  ${outcome.hash}  ${outcome.label}',
        );
      }
      // Only meaningful with something to compare against: one sample is
      // trivially "identical every run" and would overstate determinism.
      final suffix = args.samples > 1 && hashes.length == 1
          ? ' (identical every run)'
          : '';
      stdout.writeln(
        '  -> ${prompt.key}: ${hashes.length} distinct output(s) across '
        '${args.samples} run(s)$suffix',
      );
    }
    printSummary(setting.key, outcomes);
  }
  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'temperature_stress',
      model: args.model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      summary: passSummary(collect),
      calls: collect,
    );
  }
  client.close();
}
