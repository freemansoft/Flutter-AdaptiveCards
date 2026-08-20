/// Probes everyday card requests across several sampling temperatures.
///
/// Run when evaluating a new model, or when tempted to change
/// `defaultCardTemperature`. This is the *easy* set: short, common asks. If a
/// model cannot pass these it is unsuitable for the card path at any
/// temperature. Expect little separation between settings here — use
/// `temperature_stress.dart` for the cases that actually discriminate.
///
/// ```sh
/// fvm dart run tool/model_probes/temperature_matrix.dart \
///   --model qwen3.6:27b-coding-nvfp4 --samples 3
/// ```
library;

import 'dart:io';

// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_results.dart';
import 'probe_support.dart';

/// Short asks that should each produce a small card — plus one that should
/// stay Markdown, since a setting that breaks the card/text judgement is as
/// broken as one that breaks the JSON.
const _prompts = <String, String>{
  'date': 'Book me a meeting. Ask me for a date and a time.',
  'choice': 'What size shirt should I order? Offer S, M, L, XL.',
  'facts': 'Summarize the specs of the iPhone 15 Pro as labelled facts.',
  'table': 'Show me a table of the 4 largest planets with diameter and moons.',
  'chart': 'Chart the market share of the top 5 phone vendors.',
  'rating': 'Ask me to rate my support experience from 1 to 5.',
  'prose': 'In two sentences, why is the sky blue?',
};

/// `greedy` is what the server sends today; `recommended` mirrors the
/// sampling settings Qwen-family Modelfiles ship.
const _settings = <String, Map<String, dynamic>>{
  'greedy(t=0)': {'temperature': 0.0},
  'low(t=0.2)': {'temperature': 0.2, 'top_p': 0.95, 'top_k': 20},
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
        stdout.writeln(
          '${setting.key.padRight(20)} ${prompt.key.padRight(7)} #$i  '
          '${outcome.ok ? "PASS" : "FAIL"}  ${outcome.ms}ms  '
          '${outcome.chars}c  ${outcome.label}',
        );
      }
    }
    printSummary(setting.key, outcomes);
  }
  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'temperature_matrix',
      model: args.model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      summary: passSummary(collect),
      calls: collect,
    );
  }
  client.close();
}
