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
/// Nine phases, all against one resident model, strictly serial:
///   1. **identical repeat** — the cold prefill against the warm one.
///   2. **same system prompt, different question** — a fresh question
///      against the same cached system prompt, the server's steady-state
///      pattern between unrelated conversations.
///   3. **growing conversation** — the server's real pattern, full history
///      replayed each turn plus one new turn.
///   4. **interleaved** — an unrelated prompt between two identical ones,
///      to see whether the cached sequence survives it.
///   5. **retry after abort** — a call abandoned mid-prefill, then repeated,
///      which prices the timeout-and-retry pattern the sweep probes use.
///   6. **ordering** — fresh questions on the shared system prompt, each
///      sent after a different kind of cache hit: after a full prefill,
///      after an exact repeat, after a partial prefix hit, and after a call
///      that extended the previous one. Phases 2 and 3 already show a fresh
///      question missing after an exact repeat on some runners and hitting
///      after a full prefill; this phase repeats that split and adds the
///      orderings they never send, so a miss can be tied to what the
///      previous call was rather than to the question itself.
///   7. **first divergence** — two system prompts no earlier call sent,
///      each followed by three fresh questions, one of them with an exact
///      repeat before its first fresh question. Tests whether a miss belongs
///      to the first request that diverges from a prompt's first prefill,
///      whatever came before it.
///   8. **interleaved conversations** — two conversations on the *same*
///      system prompt, alternating turn by turn, which is what two users of
///      one chat server produce. Phase 4 switches system prompts instead, so
///      nothing before this phase measures the shape the chat server itself
///      generates.
///   9. **second branch** — a new conversation on a system prompt that two
///      earlier requests have already diverged from at different points,
///      which asks whether a runner keeps one restorable branch per prompt or
///      several.
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
/// `caseId` carries one of the nine phase names above (`identical-repeat`,
/// `new-question`, `growing-conversation`, `interleaved`,
/// `retry-after-abort`, `ordering`, `first-divergence`,
/// `interleaved-conversations`, `second-branch`); `condition` carries the
/// role within that phase (`cold`/`identical`, `turn-1`/`turn-2`/`turn-3`,
/// `after-exact`, `delta-fresh-1`, `a-turn-2`, `branch-1-again`, …).
/// The warmup call that loads the model and the final unload are plumbing,
/// not one of the nine measured phases, and are not recorded as `ProbeCall`s.
///
/// **Each call records a digest of its reply**, not the reply itself. At
/// `temperature 0` a warm repeat should answer a request byte for byte as its
/// cold original did, so a differing digest on an identical request says the
/// cache path changed the output, which is a correctness question rather than
/// a cost one. The text is not archived because a run holds 40 replies and
/// none of them is the measurement.
///
/// **`--entries` sets the glossary length**, 300 by default. It exists to
/// test whether cache reuse depends on prompt length: the same phases
/// on a longer or shorter system prompt, with nothing else changed. The
/// ceiling keeps the longest prompt the probe sends inside `num_ctx` on the
/// densest tokenizer measured so far — see [_maxGlossaryEntries]. The entry
/// count is recorded in `summary.glossaryEntries` and as the run's
/// `variant` (`entries300`), so a run at a non-default length cannot be
/// mistaken for a default one. Every run carries the variant, default
/// included: a bare `prefill_cache_probe.json` beside an `-entries450` one
/// would silently mean "the other length".
///
/// **`--system-file` sends a real system prompt instead of the glossary.**
/// The probe needs five system prompts that differ from each other, so it
/// appends a one-line session tag to the file's text, one tag per prompt. A
/// run with the chat server's own `card_system_prompt.txt` answers whether
/// the checkpoint behaviour measured on 300 uniform clauses survives a prompt
/// with prose, a schema and examples in it. `summary.systemSource` records
/// which was used, and the run's variant reads `cardprompt` rather than
/// `entries<n>`.
///
/// ```sh
/// fvm dart run tool/model_probes/prefill_cache_probe.dart \
///   --model llama3.2:latest
/// fvm dart run tool/model_probes/prefill_cache_probe.dart \
///   --model llama3.2:latest --entries 450
/// fvm dart run tool/model_probes/prefill_cache_probe.dart \
///   --model llama3.2:latest \
///   --json results/llama3.2_latest/prefill_cache_probe-entries300.json
/// ```
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';

// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_results.dart';
import 'probe_support.dart';

/// Default glossary length in the generated system prompt.
///
/// 300 glossary entries land near 2,100 tokens on `llama3.2:latest` and near
/// 3,200 on `qwen3.8:27b-nvfp4` — large enough that a cold prefill is
/// unmistakable against a warm one, small enough to stay well inside
/// `num_ctx`.
const _defaultGlossaryEntries = 300;

/// Largest `--entries` the probe accepts.
///
/// The densest tokenizer measured on this glossary is `qwen3.8:27b-nvfp4`.
/// Its longest prompt is the retry phase's `charlie` glossary, 3,477 tokens
/// at 300 entries, so 600 entries come to about 7,000 tokens, under a
/// [_numCtx] of 8192. Past that, Ollama truncates silently and every cache
/// figure describes the clipping instead.
const _maxGlossaryEntries = 600;

const _numCtx = 8192;
const _numPredict = 60;

/// The file `--system-file` named, or null when the probe generates its own.
String? _systemFileText;

String _systemPrompt(String tag, int glossaryEntries) {
  final fileText = _systemFileText;
  if (fileText != null) {
    // The tag leads, so the five prompts diverge at their first line the way
    // the five glossaries do. A tag appended instead leaves them sharing
    // every token but the last few, which makes a "prompt no earlier call
    // sent" reuse the cache and silently voids the first-divergence phase.
    return 'Session tag: $tag.\n\n$fileText';
  }
  final entries = List.generate(
    glossaryEntries,
    (i) => '$tag-term$i means concept${i * 7 % 991}.',
  ).join(' ');
  return 'You are a helpful assistant. Answer briefly. '
      'Reference glossary: $entries';
}

/// A short hash of a reply, enough to tell two replies apart.
String _digest(String reply) =>
    sha256.convert(utf8.encode(reply)).toString().substring(0, 12);

/// The Ollama settings that decide how the runner splits its cache.
///
/// Recorded per run because a slot count above one partitions the KV cache,
/// which is exactly the mechanism a cache measurement is about. An unset
/// variable is recorded as `unset` rather than omitted, so a later reader can
/// tell "the default applied" from "nobody looked".
Map<String, String> _cacheEnvironment() => {
  for (final name in [
    'OLLAMA_NUM_PARALLEL',
    'OLLAMA_KV_CACHE_TYPE',
    'OLLAMA_MAX_LOADED_MODELS',
    'OLLAMA_CONTEXT_LENGTH',
  ])
    name: Platform.environment[name] ?? 'unset',
};

int _ms(Map<String, dynamic> data, String key) =>
    data[key] is int ? (data[key] as int) ~/ 1000000 : 0;

/// What one `/api/chat` call reported, machine-readable rather than only
/// printed — the fields [ProbeRun.summary] needs, per the doc comment's
/// second decision.
class const _CallResult({
  /// Whether the call returned a reply, as opposed to being aborted or
  /// throwing. Deliberately not a judgement about cache behaviour — see the
  /// doc comment's first decision.
  required final bool completed,

  /// `prompt_eval_count`: prompt tokens the call carried.
  final int? prompt,

  /// `prompt_eval_cached_count`: of those, how many were served from cache.
  final int? cached,

  /// `prompt_eval_duration`, in milliseconds.
  final int? prefillMs,

  /// `total_duration`, in milliseconds.
  final int? totalMs,

  /// The assistant's reply text, when the call completed.
  final String? reply,
}) {
  /// The structured figures, for [ProbeRun.summary].
  Map<String, dynamic> toSummary(String role) => {
    'label': role,
    if (prompt != null) 'prompt': prompt,
    if (cached != null) 'cached': cached,
    if (prefillMs != null) 'prefillMs': prefillMs,
    if (totalMs != null) 'totalMs': totalMs,
    if (reply != null) 'replyDigest': _digest(reply!),
    if (reply != null) 'replyChars': reply!.length,
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

/// Parses `--entries` and hands the shared options on to [parseProbeArgs].
///
/// Returns null, with a message on stderr and a non-zero [exitCode], when
/// `--entries` is not a whole number in 1..[_maxGlossaryEntries].
(ProbeArgs, int)? _parseArgs(List<String> argv) {
  final parser = ArgParser()
    ..addOption('entries', defaultsTo: '$_defaultGlossaryEntries')
    ..addOption('system-file')
    ..addOption('model')
    ..addOption('url')
    ..addOption('samples')
    ..addOption('json')
    ..addOption('timeout')
    ..addFlag('help', abbr: 'h', negatable: false);
  final parsed = parser.parse(argv);
  if (parsed['help'] as bool) {
    stdout.writeln(parser.usage);
    return null;
  }
  final systemFile = parsed['system-file'] as String?;
  if (systemFile != null) {
    final file = File(systemFile);
    if (!file.existsSync()) {
      stderr.writeln('prefill_cache_probe: no such file: $systemFile');
      exitCode = 2;
      return null;
    }
    _systemFileText = file.readAsStringSync().trim();
  }
  final entries = int.tryParse(parsed['entries'] as String);
  if (entries == null || entries < 1 || entries > _maxGlossaryEntries) {
    stderr.writeln(
      'prefill_cache_probe: --entries must be 1..$_maxGlossaryEntries.',
    );
    exitCode = 2;
    return null;
  }
  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples', 'json', 'timeout'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);
  return (args, entries);
}

/// Signature of `main`'s `record` helper, so [_orderingPhase] can share it.
typedef _Record = Future<_CallResult> Function(
  String phase,
  String role,
  int sample,
  List<Map<String, String>> messages, {
  Duration? abortAfter,
});

/// Phase 6: a fresh question after each kind of preceding call.
///
/// Every `after-*` role names the request sent just before it: an exact
/// repeat, a fresh question, or a call that extended the one before. What the
/// cache did on that request is read from its own `cached` figure, not
/// assumed from its role, because runners differ on exactly that. Every
/// fresh question is one no earlier call asked. The
/// phase opens on a question after the retry phase's unrelated glossary,
/// which leaves only the instruction prefix to reuse.
Future<void> _orderingPhase(
  _Record record,
  List<Map<String, String>> Function(String question) ask,
) async {
  const phase = 'ordering';
  var sample = 0;
  Future<_CallResult> send(String role, List<Map<String, String>> m) =>
      record(phase, role, sample++, m);

  await send('seed', ask('Define alpha-term20.'));
  await send('exact', ask('Define alpha-term20.'));
  await send('after-exact', ask('Define alpha-term21.'));
  await send('after-question', ask('Define alpha-term22.'));
  await send('after-question-2', ask('Define alpha-term23.'));
  await send('exact-2', ask('Define alpha-term23.'));
  await send('after-exact-2', ask('Define alpha-term24.'));
  final history = ask('Define alpha-term25.');
  final base = await send('extend-base', history);
  history
    ..add({'role': 'assistant', 'content': base.reply ?? ''})
    ..add({'role': 'user', 'content': 'Now define alpha-term26.'});
  await send('extend', history);
  await send('after-extend', ask('Define alpha-term27.'));
}

/// Phase 7: the first fresh questions on two prompts no earlier call sent.
///
/// `delta` goes straight from its cold prefill to fresh questions; `echo`
/// takes an exact repeat first, the order phases 1 and 2 use. Three fresh
/// questions each show whether only the first divergence misses.
Future<void> _firstDivergencePhase(_Record record, int glossaryEntries) async {
  const phase = 'first-divergence';
  var sample = 0;
  for (final (tag, repeatFirst) in [('delta', false), ('echo', true)]) {
    final system = _systemPrompt(tag, glossaryEntries);
    List<Map<String, String>> ask(String question) => [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': question},
    ];
    await record(phase, '$tag-cold', sample++, ask('Define $tag-term7.'));
    if (repeatFirst) {
      await record(phase, '$tag-exact', sample++, ask('Define $tag-term7.'));
    }
    for (final n in [1, 2, 3]) {
      final question = ask('Define $tag-term${7 + n}.');
      await record(phase, '$tag-fresh-$n', sample++, question);
    }
  }
}

/// Phase 8: two conversations on one system prompt, alternating.
///
/// `a-turn-N` and `b-turn-N` replay their own history each time, so every
/// call after the first pair diverges from the conversation the runner served
/// immediately before it.
Future<void> _interleavedConversationsPhase(
  _Record record,
  List<Map<String, String>> Function(String question) ask,
) async {
  const phase = 'interleaved-conversations';
  var sample = 0;
  final a = ask('Define alpha-term30.');
  final b = ask('Define alpha-term40.');
  for (final turn in [1, 2, 3]) {
    for (final (tag, history, follow) in [
      ('a', a, 'Now define alpha-term3${turn}1.'),
      ('b', b, 'Now define alpha-term4${turn}1.'),
    ]) {
      final result = await record(phase, '$tag-turn-$turn', sample++, history);
      history
        ..add({'role': 'assistant', 'content': result.reply ?? ''})
        ..add({'role': 'user', 'content': follow});
    }
  }
}

/// Phase 9: a second divergence branch on one system prompt.
///
/// `branch-1` and `branch-2` diverge from the shared glossary at the same
/// point but with different questions; `branch-1-again` then returns to the
/// first branch. A runner that keeps one branch per prompt has to re-process
/// it; one that keeps several serves it warm.
Future<void> _secondBranchPhase(
  _Record record,
  List<Map<String, String>> Function(String question) ask,
) async {
  const phase = 'second-branch';
  var sample = 0;
  await record(phase, 'branch-1', sample++, ask('Define alpha-term50.'));
  await record(phase, 'branch-2', sample++, ask('Define alpha-term60.'));
  await record(phase, 'branch-1-again', sample++, ask('Define alpha-term50.'));
  await record(phase, 'branch-3', sample++, ask('Define alpha-term70.'));
}

Future<void> main(List<String> argv) async {
  final parsedArgs = _parseArgs(argv);
  if (parsedArgs == null) return;
  final (args, glossaryEntries) = parsedArgs;
  final url = args.url;
  final model = args.model;
  stdout.writeln(
    'model=$model url=$url num_ctx=$_numCtx entries=$glossaryEntries',
  );

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

  final system = _systemPrompt('alpha', glossaryEntries);
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
  await record('identical-repeat', 'cold', 0, ask('Define alpha-term7.'));
  await record('identical-repeat', 'identical', 1, ask('Define alpha-term7.'));

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
  final second = await record('growing-conversation', 'turn-2', 1, history);
  history
    ..add({'role': 'assistant', 'content': second.reply ?? ''})
    ..add({'role': 'user', 'content': 'And alpha-term18?'});
  await record('growing-conversation', 'turn-3', 2, history);

  stdout.writeln('4. interleaved unrelated prompt');
  final other = _systemPrompt('bravo', glossaryEntries);
  await record('interleaved', 'other', 0, [
    {'role': 'system', 'content': other},
    {'role': 'user', 'content': 'Define bravo-term7.'},
  ]);
  await record('interleaved', 'back-to-a', 1, ask('Define alpha-term7.'));

  stdout.writeln('5. retry after aborting mid-prefill');
  final retry = _systemPrompt('charlie', glossaryEntries);
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

  stdout.writeln('6. ordering');
  await _orderingPhase(record, ask);

  stdout.writeln('7. first divergence');
  await _firstDivergencePhase(record, glossaryEntries);

  stdout.writeln('8. interleaved conversations');
  await _interleavedConversationsPhase(record, ask);

  stdout.writeln('9. second branch');
  await _secondBranchPhase(record, ask);

  await _unload(url, model);
  stdout.writeln('model unloaded');

  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'prefill_cache_probe',
      variant: _systemFileText == null
          ? 'entries$glossaryEntries'
          : 'cardprompt',
      model: model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      // This probe never reads card_system_prompt.txt or seed_card.json --
      // _systemPrompt() generates a synthetic glossary instead. Recording
      // digests for assets the run never touched would make check_results
      // flag these runs as stale the next time either file changes, for an
      // asset dependency that never existed. tool_call_probe.dart and
      // shape_ab.dart set the precedent for overriding assetNames instead
      // of accepting the default.
      assetNames: const [],
      temperature: 0,
      summary: {
        'glossaryEntries': glossaryEntries,
        'systemSource': _systemFileText == null ? 'glossary' : 'system-file',
        'numCtx': _numCtx,
        'numPredict': _numPredict,
        'environment': _cacheEnvironment(),
        ...phaseSummaries,
      },
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
