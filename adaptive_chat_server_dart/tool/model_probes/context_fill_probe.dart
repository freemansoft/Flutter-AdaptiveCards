/// Measures whether a model still functions once its context is mostly
/// filled, rather than only lightly used the way `shape_ab.dart`'s
/// two-turn "with history" condition does.
///
/// **This is a standalone diagnostic, not one of the seven sweep probes.**
/// It runs the same 25 cases and the same judge `shape_ab.dart` does, but
/// prepends a large deterministic filler block as history instead of the
/// short seed exchange, so a run says something about capacity on a tight
/// machine, not just about shape. **Not added to `expectedProbes` in
/// `check_results.dart`**, for the same reason `prefill_cache_probe.dart`
/// is not: that checker sweeps every `results-*` directory under
/// `tool/model_probes/` and would report every launched model missing the
/// standard seven probes. Results belong under
/// `tool/model_probes/context_fill_results/`, in a directory named
/// `host-ram-ollamaVERSION-fillN/model/context_fill_probe.json` — a sibling
/// tree, not a `results-*` directory, so it is never swept in. `N` is the
/// requested fill target (`--fill-tokens`), not `--num-ctx`: the ceiling
/// and the filler are different numbers, and the directory name states the
/// one that was actually sent.
///
/// **The filler is sized by a fixed heuristic, and that heuristic is not
/// safe.** [fillerCharsPerToken] sizes the filler in characters. An earlier
/// version of this comment argued the estimate need not be exact because
/// every call carries Ollama's own `prompt_eval_count`; that reasoning is
/// wrong, and measurement disproved it. The count tells you afterward that
/// a run overflowed its window, by which point the run is spoiled: `num_ctx`
/// was sized from the estimate before the first call. Measured against the
/// same 127,020 characters, the 4.0 constant holds at 4.29 to 4.30
/// chars/token on `llama3.2:latest`, `granite4.1:8b` and `gpt-oss:20b`, and
/// fails elsewhere — 2.99 on both `qwen3.8:27b-nvfp4` and
/// `qwen3.6:27b-coding-nvfp4`, 2.74 on `nemotron-3-nano:4b`. A 28000-token
/// target becomes 42542 or 46287 real tokens there, overflowing the 35851
/// window sized for it, and Ollama drops the history message whole. Six
/// models were recorded that way and read as discarding history they had
/// room for; the fit control in
/// `context_fill_results/m1max-64gb-ollama0333-fitcontrol-calibrated/` shows all six
/// keep it once it fits.
///
/// **The filler is now calibrated per model, and the constant is only a
/// fallback.** Before sizing anything the probe sends one short sample
/// ([calibrationSampleChars] characters at [calibrationNumCtx]) and derives
/// this model's own chars-per-token from Ollama's reported
/// `prompt_eval_count`. `qwen2.5-coder:7b` measures 3.08 against the
/// assumed 4.0. The run records `charsPerTokenUsed` and a
/// `charsPerTokenMeasured` flag, so an archive says whether its filler was
/// measured or guessed. `--no-calibrate` restores the old fixed behavior.
/// Calibration costs one extra model load, which is why the sample is
/// small and its window fixed.
///
/// The derived ratio runs slightly low, because the count includes the
/// calibration call's own system prompt and chat-template overhead. The
/// filler therefore lands under its target rather than over: a
/// `--fill-tokens 8000` run on `qwen2.5-coder:7b` achieved roughly 7,000.
/// That is the direction to err in, since the target is approximate by
/// nature and only overflowing `num_ctx` invalidates a run. Read the
/// achieved figure from each call's `tokens=`, never from `--fill-tokens`.
///
/// **`num_ctx` budgets the system prompt, not just the filler.** An earlier
/// version sized `num_ctx` off `--fill-tokens` alone; the card system
/// prompt itself costs an estimated ~4,800 tokens, so a run's actual
/// request was already short of its own window before the filler mattered.
/// [defaultNumCtxFor] now adds [estimateTokenCount] of the system prompt on
/// top. See ModelBehavior.md's context-fill section for what that bug
/// produced (five of eight models silently dropped the entire filler
/// message rather than trimming it) and how a corrected run compares.
///
/// **The runner is force-evicted before each run.** A resident model does
/// not reliably re-apply a later request's `num_ctx` — measured directly,
/// raising `num_ctx` from 32096 to 45000 against an already-loaded
/// `qwen2.5-coder:7b` left `prompt_eval_count` unchanged. Without an
/// eviction first, which of several models in a sequential sweep "got" the
/// requested context depended on incidental load order, not on the model.
///
/// **The runner's own allocated context is recorded, not just the
/// requested one.** `num_ctx` in a run's summary is what the probe asked
/// for, which is silent about clamping: a model that ingested the filler
/// and a model that discarded it archive the identical number. After the
/// first case has loaded the runner, [readRunnerStatus] reads `/api/ps`
/// once and the summary gains `runnerContextLength`, `runnerContextClamped`
/// and `runnerSizeVram`. One read rather than per call, because the runner
/// does not resize mid-run. Best effort: an `/api/ps` that fails or omits
/// the field records nothing rather than costing the sweep its result, so
/// those keys are absent from a run that could not take the reading, the
/// way `promptEvalCountMin` already is. This exists to separate the two
/// explanations left open by the cross-host runs, where three models with
/// windows long enough to hold the filler discarded it anyway.
///
/// ```sh
/// fvm dart run tool/model_probes/context_fill_probe.dart \
///   --model qwen3.5:9b --fill-tokens 28000 \
///   --json tool/model_probes/context_fill_results/m5-16gb-ollama0333-fill28000/qwen3.5_9b/context_fill_probe.json
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';

// Relative: these live outside lib/, beside this file.
import 'probe_results.dart';
import 'probe_support.dart';
import 'shape_cases.dart';

/// Characters of filler text per token, an average English-text heuristic
/// used only to size the generated block — not a claim about any model's
/// tokenizer. See the file doc comment for why this does not need to be
/// exact.
const fillerCharsPerToken = 4.0;

/// Tokens of headroom [defaultNumCtxFor] adds on top of a fill target, so
/// the filler plus the case's own prompt plus the model's reply do not
/// overflow `num_ctx` and get silently truncated — the same failure mode
/// `prefill_cache_probe.dart`'s doc comment warns its own system prompt
/// against.
const defaultFillMargin = 4096;

/// Deterministic, meaningless filler sized to approximate [targetTokens]
/// via [charsPerToken].
///
/// Indexed nonsense entries rather than prose, mirroring
/// `prefill_cache_probe.dart`'s `_systemPrompt` generator, so the filler can
/// never read as real conversational content or bias a model toward the
/// card schema it is being tested against. A non-positive target produces
/// no filler at all, matching a probe run that wants the unfilled baseline.
String buildFillerText(
  int targetTokens, {
  double charsPerToken = fillerCharsPerToken,
}) {
  if (targetTokens <= 0) return '';
  final targetChars = (targetTokens * charsPerToken).round();
  final buffer = StringBuffer();
  var i = 0;
  while (buffer.length < targetChars) {
    buffer.write('filler-term$i means concept${i * 7 % 991}. ');
    i++;
  }
  return buffer.toString();
}

/// Estimated token count of [text] via [charsPerToken] -- the same estimate
/// [buildFillerText] sizes itself by, applied in reverse to real text such
/// as the card system prompt, so its cost can be budgeted into `num_ctx`
/// instead of silently eating into a window sized for the filler alone.
int estimateTokenCount(
  String text, {
  double charsPerToken = fillerCharsPerToken,
}) => text.isEmpty ? 0 : (text.length / charsPerToken).ceil();

/// Characters per token implied by a sample of [sampleChars] characters
/// that Ollama reported costing [promptEvalCount] tokens.
///
/// Returns null when the reading cannot be a ratio (an absent, zero or
/// negative count, or an empty sample), so a failed calibration falls back
/// to [fillerCharsPerToken] rather than sizing a filler from `Infinity`.
///
/// The count includes a few tokens of chat-template overhead the sample
/// text did not contain, which biases the ratio slightly low and makes the
/// filler built from it land slightly under target. That is the safe
/// direction: undershooting the fill target cannot overflow `num_ctx`,
/// while overshooting is exactly the failure this replaces.
double? charsPerTokenFrom({
  required int sampleChars,
  required int? promptEvalCount,
}) {
  if (promptEvalCount == null || promptEvalCount <= 0) return null;
  if (sampleChars <= 0) return null;
  return sampleChars / promptEvalCount;
}

/// Characters of filler sent to measure a model's own chars-per-token.
///
/// Large enough that the chat template's fixed overhead is a rounding
/// error, small enough to fit [calibrationNumCtx] even on the densest
/// tokenizer measured (2.74 chars/token, so ~3,650 tokens here).
const calibrationSampleChars = 10000;

/// `num_ctx` for the calibration call. Fixed and small: the real run's
/// window cannot be computed until the calibration result is in, and a
/// small window keeps this load cheap on a 25 GB model.
const calibrationNumCtx = 8192;

/// Measures [model]'s chars-per-token, or null if the reading fails.
///
/// Sends a filler sample as a bare user prompt with no system prompt, so
/// the count reflects the filler text rather than assets that vary. Best
/// effort: a failure returns null and the caller keeps
/// [fillerCharsPerToken].
Future<({double? charsPerToken, String label})> calibrateCharsPerToken({
  required HttpClient client,
  required String url,
  required String model,
  Duration timeout = defaultProbeTimeout,
}) async {
  final sample = buildFillerText(
    (calibrationSampleChars / fillerCharsPerToken).round(),
  );
  final outcome = await probeOnce(
    client: client,
    url: url,
    model: model,
    systemPrompt: calibrationSystemPrompt,
    userPrompt: sample,
    options: {'temperature': 0.0, 'num_ctx': calibrationNumCtx},
    timeout: timeout,
  );
  final ratio = charsPerTokenFrom(
    sampleChars: sample.length,
    promptEvalCount: outcome.promptEvalCount,
  );
  return (charsPerToken: ratio, label: outcome.label);
}

/// System prompt for the calibration call.
///
/// Not empty: the point of this call is a token count, and a one-line
/// instruction that keeps the reply short costs a handful of tokens while
/// avoiding a model rambling for the full timeout on nonsense input. Its
/// own tokens are included in the count, which biases the derived ratio
/// low and so undersizes the filler, the safe direction.
const calibrationSystemPrompt = 'Reply with the single word: ok';

/// `num_ctx` for a run targeting [fillTokens] of filler on top of a system
/// prompt estimated at [systemPromptTokens], leaving [margin] tokens of
/// headroom for the case prompt and the model's reply.
///
/// [systemPromptTokens] defaults to zero only for callers that already
/// folded it into [fillTokens] or genuinely send no system prompt --
/// omitting it for a real run reproduces the bug this guards against: a
/// ~15KB, ~4800-token system prompt went unbudgeted, so `num_ctx` was
/// already short of what the request needed before the filler even
/// mattered. See ModelBehavior.md's context-fill section.
int defaultNumCtxFor(
  int fillTokens, {
  int systemPromptTokens = 0,
  int margin = defaultFillMargin,
}) => fillTokens + systemPromptTokens + margin;

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption(
      'fill-tokens',
      help:
          'Target token count for the generated filler history. Required — '
          'there is no sensible default for "large".',
    )
    ..addOption(
      'num-ctx',
      help:
          'Ollama context window. Defaults to --fill-tokens plus the card '
          "system prompt's own estimated token cost plus "
          '$defaultFillMargin tokens of headroom.',
    )
    ..addFlag(
      'calibrate',
      defaultsTo: true,
      help:
          "Measure this model's own chars-per-token before sizing the "
          'filler. --no-calibrate uses the fixed '
          '$fillerCharsPerToken estimate, which overflows num_ctx on any '
          'tokenizer denser than the llama family.',
    )
    ..addOption('model')
    ..addOption('url')
    ..addOption('samples')
    ..addOption('json')
    ..addOption('timeout')
    ..addFlag('help', abbr: 'h', negatable: false);
  final parsed = parser.parse(argv);
  if (parsed['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }
  final fillTokensRaw = parsed['fill-tokens'] as String?;
  if (fillTokensRaw == null) {
    stderr.writeln('context_fill_probe: --fill-tokens is required.');
    exitCode = 2;
    return;
  }
  final fillTokens = int.parse(fillTokensRaw);
  final systemPrompt = loadCardSystemPrompt();

  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples', 'json', 'timeout'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);

  // Calibrate before sizing anything. fillerCharsPerToken is a single
  // constant, and a filler sized by it overflows num_ctx on any tokenizer
  // denser than the llama family's ~4.30 chars/token -- the defect that
  // produced, and then retracted, a finding about models discarding
  // history they had room for.
  final calibrationClient = HttpClient()
    ..idleTimeout = const Duration(minutes: 10);
  double? measuredCharsPerToken;
  if (parsed['calibrate'] as bool) {
    stdout.writeln('calibrating ${args.model} chars-per-token...');
    await evictModel(args.url, args.model);
    final calibration = await calibrateCharsPerToken(
      client: calibrationClient,
      url: args.url,
      model: args.model,
      timeout: args.timeout,
    );
    measuredCharsPerToken = calibration.charsPerToken;
    stdout.writeln(
      measuredCharsPerToken == null
          ? 'calibration failed (${calibration.label}); falling back to '
                '$fillerCharsPerToken'
          : 'measured ${measuredCharsPerToken.toStringAsFixed(2)} '
                'chars/token (assumed $fillerCharsPerToken)',
    );
  }
  calibrationClient.close(force: true);
  final charsPerToken = measuredCharsPerToken ?? fillerCharsPerToken;

  final systemPromptTokens = estimateTokenCount(
    systemPrompt,
    charsPerToken: charsPerToken,
  );
  final defaultNumCtx = defaultNumCtxFor(
    fillTokens,
    systemPromptTokens: systemPromptTokens,
  );
  final numCtx = int.parse(parsed['num-ctx'] as String? ?? '$defaultNumCtx');

  final filler = buildFillerText(fillTokens, charsPerToken: charsPerToken);
  // A resident runner does not reliably pick up a new num_ctx from a later
  // request -- measured directly: raising num_ctx from 32096 to 45000
  // against an already-loaded qwen2.5-coder:7b left prompt_eval_count
  // unchanged. Forcing an unload first guarantees this run's first call is
  // the one that decides the runner's context size, rather than whatever a
  // previous invocation happened to load it with.
  stdout
    ..writeln(
      'context_fill_probe: model=${args.model} fill-tokens=$fillTokens '
      'chars-per-token=${charsPerToken.toStringAsFixed(2)}'
      '${measuredCharsPerToken == null ? " (assumed)" : " (measured)"} '
      'system-prompt-tokens=$systemPromptTokens num-ctx=$numCtx '
      'filler-chars=${filler.length}',
    )
    ..writeln('evicting any resident runner for a clean load...');
  await evictModel(args.url, args.model);

  final client = HttpClient()..idleTimeout = const Duration(minutes: 10);
  final calls = <ProbeCall>[];
  final promptEvalCounts = <int>[];
  var passCount = 0;
  // Read once, after the first case has loaded the runner: /api/ps lists
  // nothing before then, and the runner's context does not change mid-run,
  // so polling per call would add 25 round trips for one number.
  RunnerStatus? runnerStatus;

  for (final c in shapeCases) {
    for (var sample = 0; sample < args.samples; sample++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: c.prompt,
        history: [filler, 'Understood.'],
        options: {'temperature': 0.0, 'num_ctx': numCtx},
        timeout: args.timeout,
      );
      runnerStatus ??= await readRunnerStatus(args.url, args.model);
      final result = judgeShape(c, outcome);
      if (result.pass) passCount++;
      final count = outcome.promptEvalCount;
      if (count != null) promptEvalCounts.add(count);
      calls.add(
        ProbeCall(
          caseId: c.id,
          sample: sample,
          pass: result.pass,
          label: count == null
              ? result.describe()
              : '${result.describe()} tokens=$count',
          ms: outcome.ms,
        ),
      );
      stdout.writeln(
        '${result.pass ? "PASS" : "FAIL"}  ${c.id.padRight(13)} '
        '${outcome.ms.toString().padLeft(6)}ms  '
        'tokens=${count ?? '-'}  ${result.describe()}',
      );
    }
  }
  client.close(force: true);

  final allocated = runnerStatus?.contextLength;
  stdout
    ..writeln('== shapes $passCount/${calls.length} ==')
    ..writeln(
      allocated == null
          ? '== runner context: not reported by /api/ps =='
          : '== runner context: $allocated allocated against $numCtx '
                'requested${allocated < numCtx ? " (CLAMPED)" : ""} ==',
    );

  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'context_fill_probe',
      model: args.model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      notes:
          'Filler sized via fillerCharsPerToken=$fillerCharsPerToken; see '
          "each call's tokens=… for the actual prompt_eval_count. "
          'runnerContextLength is what /api/ps reported the runner '
          'allocated, against numCtx as requested.',
      summary: {
        'pass': passCount,
        'total': calls.length,
        'fillTokensTarget': fillTokens,
        'systemPromptTokensEstimate': systemPromptTokens,
        'charsPerTokenUsed': charsPerToken,
        'charsPerTokenMeasured': measuredCharsPerToken != null,
        'numCtx': numCtx,
        if (allocated != null) ...{
          'runnerContextLength': allocated,
          'runnerContextClamped': allocated < numCtx,
        },
        if (runnerStatus?.sizeVram != null)
          'runnerSizeVram': runnerStatus!.sizeVram,
        if (promptEvalCounts.isNotEmpty) ...{
          'promptEvalCountMin': promptEvalCounts.reduce(
            (a, b) => a < b ? a : b,
          ),
          'promptEvalCountMax': promptEvalCounts.reduce(
            (a, b) => a > b ? a : b,
          ),
        },
      },
      calls: calls,
    );
  }
}
