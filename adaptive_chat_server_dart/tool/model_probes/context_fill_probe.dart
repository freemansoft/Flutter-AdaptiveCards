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
/// **The filler is sized by a fixed heuristic, not a live calibration
/// call.** [fillerCharsPerToken] is a documented estimate for English text;
/// it is not a claim about any specific model's tokenizer, and it does not
/// need to be exact, because every recorded call carries Ollama's own
/// `prompt_eval_count` — the number that actually matters — rather than
/// trusting the estimate. `--fill-tokens` names the target; the achieved
/// count travels with each call.
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
/// ```sh
/// fvm dart run tool/model_probes/context_fill_probe.dart \
///   --model qwen3.5:9b --fill-tokens 28000 \
///   --json tool/model_probes/context_fill_results/m5-16gb-ollama0331-fill28000/qwen3.5_9b/context_fill_probe.json
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
  final systemPromptTokens = estimateTokenCount(systemPrompt);
  final defaultNumCtx = defaultNumCtxFor(
    fillTokens,
    systemPromptTokens: systemPromptTokens,
  );
  final numCtx = int.parse(
    parsed['num-ctx'] as String? ?? '$defaultNumCtx',
  );

  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples', 'json', 'timeout'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);

  final filler = buildFillerText(fillTokens);
  // A resident runner does not reliably pick up a new num_ctx from a later
  // request -- measured directly: raising num_ctx from 32096 to 45000
  // against an already-loaded qwen2.5-coder:7b left prompt_eval_count
  // unchanged. Forcing an unload first guarantees this run's first call is
  // the one that decides the runner's context size, rather than whatever a
  // previous invocation happened to load it with.
  stdout
    ..writeln(
      'context_fill_probe: model=${args.model} fill-tokens=$fillTokens '
      'system-prompt-tokens=$systemPromptTokens num-ctx=$numCtx '
      'filler-chars=${filler.length}',
    )
    ..writeln('evicting any resident runner for a clean load...');
  await evictModel(args.url, args.model);

  final client = HttpClient()..idleTimeout = const Duration(minutes: 10);
  final calls = <ProbeCall>[];
  final promptEvalCounts = <int>[];
  var passCount = 0;

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

  stdout.writeln('== shapes $passCount/${calls.length} ==');

  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'context_fill_probe',
      model: args.model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      notes:
          'Filler sized via fillerCharsPerToken=$fillerCharsPerToken; see '
          "each call's tokens=… for the actual prompt_eval_count.",
      summary: {
        'pass': passCount,
        'total': calls.length,
        'fillTokensTarget': fillTokens,
        'systemPromptTokensEstimate': systemPromptTokens,
        'numCtx': numCtx,
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
