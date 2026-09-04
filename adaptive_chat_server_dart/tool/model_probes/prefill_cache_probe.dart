/// Measures how much of a prompt Ollama serves from its prefix cache.
///
/// **This is a standalone diagnostic, not one of the seven sweep probes.**
/// It scores no cards and produces no pass rate — it reads
/// `prompt_eval_cached_count` (Ollama 0.33.3 and later) and
/// `prompt_eval_duration` to answer what a repeated prompt, a growing
/// conversation, and a retry after an aborted call actually cost. Run it by
/// hand when a cache or prefill question comes up; `sweep.sh` does not.
///
/// Four phases, all against one resident model, strictly serial:
///   1. **identical repeat** — the cold prefill against the warm one.
///   2. **growing conversation** — the server's real pattern, full history
///      replayed each turn plus one new turn.
///   3. **interleaved** — an unrelated prompt between two identical ones,
///      to see whether the cached sequence survives it.
///   4. **retry after abort** — a call abandoned mid-prefill, then repeated,
///      which prices the timeout-and-retry pattern the sweep probes use.
///
/// **Size the system prompt under `num_ctx`.** A prompt that overflows the
/// window is truncated silently, which pins `prompt_eval_count` at about
/// half the window and zeroes cache reuse — the figures then describe the
/// clipping rather than the cache. The generated prompt here is ~2,100
/// tokens against a default `num_ctx` of 8192 for exactly that reason.
///
/// ```sh
/// fvm dart run tool/model_probes/prefill_cache_probe.dart \
///   --model llama3.2:latest
/// ```
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_support.dart';

/// Tokens of filler in the generated system prompt.
///
/// 300 glossary entries land near 2,100 tokens — large enough that a cold
/// prefill is unmistakable against a warm one, small enough to stay well
/// inside `num_ctx`.
const _glossaryEntries = 300;

const _numCtx = 8192;
const _numPredict = 60;

String _systemPrompt(String tag) {
  final entries = List.generate(
    _glossaryEntries,
    (i) => '$tag-term$i means concept${i * 7 % 991}.',
  ).join(' ');
  return 'You are a helpful assistant. Answer briefly. '
      'Reference glossary: $entries';
}

int _ms(Map<String, dynamic> data, String key) =>
    data[key] is int ? (data[key] as int) ~/ 1000000 : 0;

/// One `/api/chat` call, optionally abandoned partway through.
///
/// Returns the assistant's reply text, or null when the call was aborted or
/// failed — the caller reports the abort rather than treating it as an error,
/// since abandoning a call is the point of the retry phase.
Future<String?> _call(
  String url,
  String model,
  String label,
  List<Map<String, String>> messages, {
  Duration? abortAfter,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('$url/api/chat');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'model': model,
        'stream': false,
        'keep_alive': '10m',
        'options': {
          'temperature': 0,
          'num_ctx': _numCtx,
          'num_predict': _numPredict,
        },
        'messages': messages,
      }),
    );
    Timer? timer;
    if (abortAfter != null) {
      timer = Timer(abortAfter, request.abort);
    }
    final response = await request.close();
    timer?.cancel();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    stdout.writeln(
      '  $label: prompt=${data['prompt_eval_count']} '
      'cached=${data['prompt_eval_cached_count']} '
      'prefill=${_ms(data, 'prompt_eval_duration')}ms '
      'total=${_ms(data, 'total_duration')}ms',
    );
    return (data['message'] as Map<String, dynamic>?)?['content'] as String?;
  } on Object catch (exc) {
    stdout.writeln('  $label: no reply (${exc.runtimeType})');
    return null;
  } finally {
    client.close(force: true);
  }
}

Future<void> _unload(String url, String model) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('$url/api/chat'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'model': model, 'keep_alive': 0}));
    await (await request.close()).drain<void>();
  } on Object {
    // An unload that fails leaves the model resident for its keep_alive and
    // costs nothing here; the next sweep's own unload will clear it.
  } finally {
    client.close(force: true);
  }
}

Future<void> main(List<String> argv) async {
  final args = parseProbeArgs(argv, defaultSamples: 1);
  final url = args.url;
  final model = args.model;
  stdout.writeln('model=$model url=$url num_ctx=$_numCtx');

  final system = _systemPrompt('alpha');
  List<Map<String, String>> ask(String question) => [
    {'role': 'system', 'content': system},
    {'role': 'user', 'content': question},
  ];

  stdout.writeln('warmup (loads the model)');
  await _call(url, model, 'warmup   ', [
    {'role': 'system', 'content': 'You are terse.'},
    {'role': 'user', 'content': 'Say OK.'},
  ]);

  stdout.writeln('1. identical repeat');
  await _call(url, model, 'cold     ', ask('Define alpha-term7.'));
  await _call(url, model, 'identical', ask('Define alpha-term7.'));

  stdout.writeln('2. same system prompt, different question');
  await _call(url, model, 'new quest', ask('Define alpha-term9 instead.'));

  stdout.writeln('3. growing conversation');
  final history = ask('Define alpha-term12.');
  final first = await _call(url, model, 'turn 1   ', history);
  history
    ..add({'role': 'assistant', 'content': first ?? ''})
    ..add({'role': 'user', 'content': 'Now define alpha-term15.'});
  final second = await _call(url, model, 'turn 2   ', history);
  history
    ..add({'role': 'assistant', 'content': second ?? ''})
    ..add({'role': 'user', 'content': 'And alpha-term18?'});
  await _call(url, model, 'turn 3   ', history);

  stdout.writeln('4. interleaved unrelated prompt');
  final other = _systemPrompt('bravo');
  await _call(url, model, 'other    ', [
    {'role': 'system', 'content': other},
    {'role': 'user', 'content': 'Define bravo-term7.'},
  ]);
  await _call(url, model, 'back to A', ask('Define alpha-term7.'));

  stdout.writeln('5. retry after aborting mid-prefill');
  final retry = _systemPrompt('charlie');
  List<Map<String, String>> retryAsk() => [
    {'role': 'system', 'content': retry},
    {'role': 'user', 'content': 'Define charlie-term7.'},
  ];
  await _call(
    url,
    model,
    'aborted  ',
    retryAsk(),
    abortAfter: const Duration(milliseconds: 400),
  );
  // The abandoned generation may still be running server-side; give it room
  // to finish so the retry measures cache reuse rather than queueing.
  await Future<void>.delayed(const Duration(seconds: 5));
  await _call(url, model, 'retry    ', retryAsk());

  await _unload(url, model);
  stdout.writeln('model unloaded');
}
