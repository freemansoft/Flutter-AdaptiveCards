/// Measures how much of a prompt Ollama serves from its prefix cache.
///
/// **This is a standalone diagnostic, not one of the seven sweep probes.**
/// It scores no cards and produces no pass rate — it reads
/// `prompt_eval_cached_count` (Ollama 0.33.3 and later) and
/// `prompt_eval_duration` to answer what a repeated prompt, a growing
/// conversation, and a retry after an aborted call actually cost. Run it by
/// hand when a cache or prefill question comes up; `sweep.sh` does not.
/// **Not added to `expectedProbes` in `check_results.dart`** for the same
/// reason — a standalone diagnostic that ran for one model would otherwise
/// be reported missing for every other launched model.
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
/// **Two decisions about `--json`, recorded here rather than left implicit:**
///
///   - **`pass` means the call completed**, not that the cache behaved as
///     hoped. This probe scores no cards and asserts no cache expectation —
///     baking today's idea of "good cache behaviour" into `pass` would
///     freeze that interpretation into a permanent archive. The
///     "aborted" call in the retry-after-abort phase is therefore recorded
///     as `pass: false`: it did not complete, by design, and that is a fact
///     about the call, not a verdict on the probe. Interpretation belongs in
///     `summary`/`notes` instead, following the precedent
///     `gguf_defaults_probe.dart` set for this directory.
///   - **Per-phase figures go into `summary` as structured values**
///     (`prompt`, `cached`, `prefillMs`, `totalMs` per call, keyed by
///     phase), not only inside `label`'s human-readable string, so a later
///     reader can compute against them without parsing prose. `label` still
///     carries the same figures in prose form, for a reader scanning the
///     file rather than querying it.
///
/// `caseId` carries one of the five phase names above (`identical-repeat`,
/// `new-question`, `growing-conversation`, `interleaved`,
/// `retry-after-abort`); `condition` carries the role within that phase
/// (`cold`/`identical`, `turn-1`/`turn-2`/`turn-3`, …). The warmup call that
/// loads the model and the final unload are plumbing, not one of the five
/// measured phases, and are not recorded as `ProbeCall`s.
///
/// ```sh
/// fvm dart run tool/model_probes/prefill_cache_probe.dart \
///   --model llama3.2:latest
/// fvm dart run tool/model_probes/prefill_cache_probe.dart \
///   --model llama3.2:latest --json results/llama3.2_latest/prefill_cache_probe.json
/// ```
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_results.dart';
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

/// What one `/api/chat` call reported, machine-readable rather than only
/// printed — the fields [ProbeRun.summary] needs, per the doc comment's
/// second decision.
class _CallResult {
  const _CallResult({
    required this.completed,
    this.prompt,
    this.cached,
    this.prefillMs,
    this.totalMs,
    this.reply,
  });

  /// Whether the call returned a reply, as opposed to being aborted or
  /// throwing. Deliberately not a judgement about cache behaviour — see the
  /// doc comment's first decision.
  final bool completed;

  /// `prompt_eval_count`: prompt tokens the call carried.
  final int? prompt;

  /// `prompt_eval_cached_count`: of those, how many were served from cache.
  final int? cached;

  /// `prompt_eval_duration`, in milliseconds.
  final int? prefillMs;

  /// `total_duration`, in milliseconds.
  final int? totalMs;

  /// The assistant's reply text, when the call completed.
  final String? reply;

  /// The structured figures, for [ProbeRun.summary].
  Map<String, dynamic> toSummary(String role) => {
    'label': role,
    if (prompt != null) 'prompt': prompt,
    if (cached != null) 'cached': cached,
    if (prefillMs != null) 'prefillMs': prefillMs,
    if (totalMs != null) 'totalMs': totalMs,
  };
}

/// One `/api/chat` call, optionally abandoned partway through.
///
/// Returns the call's figures, or a call with [_CallResult.completed] false
/// when the call was aborted or failed — the caller reports the abort rather
/// than treating it as an error, since abandoning a call is the point of the
/// retry phase.
Future<_CallResult> _call(
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
    final prompt = data['prompt_eval_count'] as int?;
    final cached = data['prompt_eval_cached_count'] as int?;
    final prefillMs = _ms(data, 'prompt_eval_duration');
    final totalMs = _ms(data, 'total_duration');
    stdout.writeln(
      '  $label: prompt=$prompt cached=$cached prefill=${prefillMs}ms '
      'total=${totalMs}ms',
    );
    return _CallResult(
      completed: true,
      prompt: prompt,
      cached: cached,
      prefillMs: prefillMs,
      totalMs: totalMs,
      reply: (data['message'] as Map<String, dynamic>?)?['content'] as String?,
    );
  } on Object catch (exc) {
    stdout.writeln('  $label: no reply (${exc.runtimeType})');
    return const _CallResult(completed: false);
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

  final calls = <ProbeCall>[];
  final phaseSummaries = <String, List<Map<String, dynamic>>>{};

  /// Issues one call, prints it as before, and — when the caller asked for
  /// `--json` — records it as a [ProbeCall] under [phase] plus its
  /// structured figures under [phase] in [phaseSummaries].
  Future<_CallResult> record(
    String phase,
    String role,
    int sample,
    List<Map<String, String>> messages, {
    Duration? abortAfter,
  }) async {
    final result = await _call(
      url,
      model,
      role.padRight(9),
      messages,
      abortAfter: abortAfter,
    );
    calls.add(
      ProbeCall(
        caseId: phase,
        sample: sample,
        pass: result.completed,
        label:
            '$role: prompt=${result.prompt} cached=${result.cached} '
            'prefill=${result.prefillMs}ms total=${result.totalMs}ms',
        condition: role,
        ms: result.totalMs,
      ),
    );
    phaseSummaries.putIfAbsent(phase, () => []).add(result.toSummary(role));
    return result;
  }

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
  await record(
    'identical-repeat',
    'cold',
    0,
    ask('Define alpha-term7.'),
  );
  await record(
    'identical-repeat',
    'identical',
    1,
    ask('Define alpha-term7.'),
  );

  stdout.writeln('2. same system prompt, different question');
  await record(
    'new-question',
    'new-question',
    0,
    ask('Define alpha-term9 instead.'),
  );

  stdout.writeln('3. growing conversation');
  final history = ask('Define alpha-term12.');
  final first = await record('growing-conversation', 'turn-1', 0, history);
  history
    ..add({'role': 'assistant', 'content': first.reply ?? ''})
    ..add({'role': 'user', 'content': 'Now define alpha-term15.'});
  final second = await record(
    'growing-conversation',
    'turn-2',
    1,
    history,
  );
  history
    ..add({'role': 'assistant', 'content': second.reply ?? ''})
    ..add({'role': 'user', 'content': 'And alpha-term18?'});
  await record('growing-conversation', 'turn-3', 2, history);

  stdout.writeln('4. interleaved unrelated prompt');
  final other = _systemPrompt('bravo');
  await record('interleaved', 'other', 0, [
    {'role': 'system', 'content': other},
    {'role': 'user', 'content': 'Define bravo-term7.'},
  ]);
  await record(
    'interleaved',
    'back-to-a',
    1,
    ask('Define alpha-term7.'),
  );

  stdout.writeln('5. retry after aborting mid-prefill');
  final retry = _systemPrompt('charlie');
  List<Map<String, String>> retryAsk() => [
    {'role': 'system', 'content': retry},
    {'role': 'user', 'content': 'Define charlie-term7.'},
  ];
  await record(
    'retry-after-abort',
    'aborted',
    0,
    retryAsk(),
    abortAfter: const Duration(milliseconds: 400),
  );
  // The abandoned generation may still be running server-side; give it room
  // to finish so the retry measures cache reuse rather than queueing.
  await Future<void>.delayed(const Duration(seconds: 5));
  await record('retry-after-abort', 'retry', 1, retryAsk());

  await _unload(url, model);
  stdout.writeln('model unloaded');

  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'prefill_cache_probe',
      model: model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      temperature: 0,
      summary: phaseSummaries,
      calls: calls,
      notes:
          'Standalone cache/prefill diagnostic, not one of the seven sweep '
          'probes -- sweep.sh does not run it and it is not in '
          'expectedProbes. pass records only whether a call completed; it '
          'is not a judgement about cache reuse -- this probe asserts no '
          "cache expectation. The 'aborted' call in retry-after-abort is "
          'recorded pass:false by design, since it is deliberately '
          'abandoned mid-prefill. summary carries prompt/cached/prefillMs/ '
          'totalMs per call, keyed by phase, so a reader can compute cache '
          'hit ratios and prefill cost without parsing label. See '
          "ModelBehavior.md, 'Prompt-cache reuse and retry cost', for how "
          'these figures were read on this host and model.',
    );
  }
}
