/// Checks whether a model actually honors Ollama's `format` constraint.
///
/// **Run this before trusting `--json-format json|schema` with a new model.**
/// Ollama accepts `format` for every model but applies it for only some, and
/// says nothing when it doesn't — you get an ordinary 200 with unconstrained
/// text. `qwen3.6:27b-coding-nvfp4` ignores it; `qwen2.5-coder:7b` honors it.
///
/// Two checks:
///   1. **the canary** — asks for prose under `format: json`. A model that
///      honors the constraint *cannot* answer with prose, so a prose answer
///      here is proof the constraint is inert.
///   2. **a card request** through all three `--json-format` modes, to see
///      whether the constraint changes any outcome in practice.
///
/// ```sh
/// fvm dart run tool/model_probes/json_format_probe.dart \
///   --model qwen2.5-coder:7b --samples 2
/// ```
library;

import 'dart:convert';
import 'dart:io';

// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_results.dart';
import 'probe_support.dart';

const _canaryPrompt = 'Say hello in plain English prose.';
const _cardPrompt =
    'Show me a Dart snippet that reads a JSON file and prints the "name" '
    'field, with a short explanation above it.';

Future<void> main(List<String> argv) async {
  final args = parseProbeArgs(argv, defaultSamples: 2);
  final systemPrompt = loadCardSystemPrompt();
  final schema = loadCardSchema();
  final client = HttpClient()..idleTimeout = const Duration(minutes: 5);

  stdout.writeln('=== canary: prose request under format=json ===');
  final canary = await _rawReply(
    client: client,
    url: args.url,
    model: args.model,
    // No card system prompt here: the question is only whether the grammar
    // constrains output, so keep everything else out of the way.
    systemPrompt: 'You are a helpful assistant.',
    userPrompt: _canaryPrompt,
    format: 'json',
  );
  final honored = _isJson(canary);
  stdout
    ..writeln('reply: ${canary.trim()}')
    ..writeln(
      honored
          ? 'VERDICT: format IS honored (reply is JSON) — json/schema modes '
                'are usable with this model.'
          : 'VERDICT: format is IGNORED (reply is prose) — --json-format '
                'json|schema buys nothing here; treat it as unavailable.',
    )
    ..writeln()
    ..writeln('=== card request through each --json-format mode ===');
  final collect = <ProbeCall>[];
  for (final mode in const ['none', 'json', 'schema']) {
    for (var i = 0; i < args.samples; i++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: _cardPrompt,
        options: const {'temperature': 0.0},
        format: switch (mode) {
          'json' => 'json',
          'schema' => schema,
          _ => null,
        },
        timeout: args.timeout,
      );
      collect.add(
        ProbeCall(
          caseId: 'card-request',
          sample: i,
          pass: outcome.ok,
          label: outcome.label,
          setting: 'format=$mode',
          ms: outcome.ms,
        ),
      );
      stdout.writeln(
        'format=${mode.padRight(6)} #$i  ${outcome.ok ? "PASS" : "FAIL"}  '
        '${outcome.ms}ms  ${outcome.chars}c  ${outcome.label}',
      );
    }
  }
  if (args.json != null) {
    // How a model ignores `format` matters as much as whether it does.
    // Returning the same good card under all three modes is inert and
    // harmless; returning an empty body under `json` destroys card
    // production, and only the per-mode calls can tell those apart.
    final byMode = <String, List<ProbeCall>>{};
    for (final c in collect) {
      byMode.putIfAbsent(c.setting!, () => []).add(c);
    }
    final noneCards = byMode['format=none']!.where((c) => c.isCard).length;
    final constrainedCards = collect
        .where((c) => c.setting != 'format=none' && c.isCard)
        .length;
    writeProbeRun(
      path: args.json!,
      probe: 'json_format_probe',
      model: args.model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      summary: {
        'honorsFormat': honored,
        'verdict': honored
            ? 'honored'
            : (constrainedCards == 0 && noneCards > 0
                  ? 'ignored-destructively'
                  : 'ignored-harmlessly'),
        ...passSummary(collect),
      },
      calls: collect,
    );
  }
  // force: a socket still stuck mid-generation must not keep the
  // process alive after its work is done and its result written.
  client.close(force: true);
}

bool _isJson(String text) {
  try {
    jsonDecode(text.trim());
    return true;
  } on FormatException {
    return false;
  }
}

/// One request returning the reply verbatim, bypassing card judging.
Future<String> _rawReply({
  required HttpClient client,
  required String url,
  required String model,
  required String systemPrompt,
  required String userPrompt,
  Object? format,
}) async {
  final request = await client.postUrl(Uri.parse('$url/api/chat'));
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'stream': false,
      'think': false,
      'keep_alive': '30m',
      'options': const {'temperature': 0.0},
      'format': ?format,
    }),
  );
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final data = jsonDecode(body) as Map<String, dynamic>;
  return (data['message'] as Map<String, dynamic>)['content'] as String;
}
