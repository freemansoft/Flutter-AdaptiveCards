/// Measures whether Ollama 0.33.3 "honor GGUF model defined default
/// parameters" moves a model's sampled output.
///
/// `ModelBehavior.md` carried this as a suspicion: the shipped probes pin
/// `temperature`, `think`, and `num_ctx` but never send `top_k` / `top_p` /
/// `presence_penalty`, so if 0.33.3 now lets the unset knobs fall through to
/// a Modelfile's declared defaults, every figure sampled at `t=0.2`/`0.6`
/// before that upgrade may not be comparable to one sampled after it. This
/// probe turns that suspicion into a yes/no for one model.
///
/// **Design.** Four arms against the same model, prompt, and fixed `--seed`,
/// differing only in which candidate-set parameters are sent:
///
///   - `unpinned` sends what the shipped probes send today — `temperature`
///     and `seed`, nothing else. Under 0.33.3 the unsent knobs are free to
///     take the Modelfile's values.
///   - `pinned-historical` adds [historicalDefaults] explicitly: the
///     effective sampling a pre-0.33.3 server would have applied regardless
///     of what the Modelfile declares.
///   - `topk-topp-only` and `presence-penalty-only` split
///     [historicalDefaults] in two, to isolate *which* of them accounts for
///     a divergence from `unpinned`. This is the part that matters at
///     `--temperature 0`: `top_k`/`top_p` only constrain the sampling step,
///     which greedy decoding never reaches, so they cannot move a greedy
///     reply. `presence_penalty` adjusts logits *before* the argmax is
///     taken, so it can. If a `t=0` divergence between `unpinned` and
///     `pinned-historical` traces to `presence-penalty-only` and not to
///     `topk-topp-only`, that is direct, re-runnable evidence for which
///     parameter is doing it — not a claim resting on an ad hoc script.
///
/// A fixed seed removes sampling noise, so a difference between arms at a
/// sampled temperature is attributable to the parameters. **Run the
/// `--temperature 0` control alongside the sampled run.** If `unpinned` and
/// `pinned-historical` disagree there, use `topk-topp-only` and
/// `presence-penalty-only` from the same run to see which one moved before
/// trusting the sampled-temperature result — a `t=0` disagreement means
/// something is moving greedy output, and this probe's job is to show which
/// arm, not to explain it away.
///
/// **Reading a result.** Compare the `hash` suffix this probe appends to
/// each call's `label` across arms at the same sample index — that
/// comparison is unaffected by a timeout-triggered runner reload, because
/// the seed and the parameters determine the output regardless of whether
/// the runner was reloaded first. `ms` either side of a timeout is not
/// comparable for the same reason `probeOnce` evicts on timeout in the
/// first place.
///
/// This is a one-off diagnostic for one model, not one of the seven sweep
/// probes `check_results.dart` expects of every launched model — it is not
/// added to `expectedProbes`.
///
/// ```sh
/// fvm dart run tool/model_probes/gguf_defaults_probe.dart \
///   --model qwen3.5:9b --temperature 0.6 --samples 3
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';

// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_results.dart';
import 'probe_support.dart';

/// The candidate-set defaults a pre-0.33.3 Ollama server applied regardless
/// of what a model's Modelfile declared. Sending these explicitly is the
/// `pinned-historical` arm; sent separately, they are the two isolation
/// arms (see [isolationArmOptions]).
const historicalDefaults = <String, dynamic>{
  'top_k': 40,
  'top_p': 0.9,
  'presence_penalty': 0,
};

/// The `top_k`/`top_p` half of [historicalDefaults] — the pair that only
/// constrains the sampling step, so it should be inert under greedy
/// (`t=0`) decoding.
const _topKTopPDefaults = <String, dynamic>{'top_k': 40, 'top_p': 0.9};

/// The `presence_penalty` half of [historicalDefaults] — a logit-level
/// adjustment applied before the argmax, so it can move even a greedy
/// (`t=0`) reply.
const _presencePenaltyDefault = <String, dynamic>{'presence_penalty': 0};

/// Fixed default seed, so a bare run removes sampling noise without the
/// caller having to pick one.
const defaultGgufProbeSeed = 42;

/// The single prompt every arm sends. Long enough, and open-ended enough,
/// for `presence_penalty` to plausibly move the reply if it is actually
/// applied.
const ggufProbeUserPrompt =
    'Show me a table of the 4 largest planets with diameter and moons.';

/// Builds the `options` map for the `unpinned` / `pinned-historical` arms.
///
/// [pinnedHistorical] selects `pinned-historical`: [historicalDefaults] sent
/// on top of [temperature] and [seed]. `false` is `unpinned`: exactly what
/// the shipped probes already send, so any divergence from
/// `pinned-historical` is attributable to 0.33.3 filling the gap from the
/// Modelfile rather than to a probe-only convention.
Map<String, dynamic> armOptions({
  required double temperature,
  required int seed,
  required bool pinnedHistorical,
}) => {
  'temperature': temperature,
  'seed': seed,
  if (pinnedHistorical) ...historicalDefaults,
};

/// Builds the `options` map for the two isolation arms.
///
/// [topKTopP] selects `topk-topp-only` ([_topKTopPDefaults] alone);
/// otherwise this is `presence-penalty-only` ([_presencePenaltyDefault]
/// alone). Comparing each against the `unpinned` arm's hash at the same
/// sample index is what turns "the arms disagreed at `t=0`" into "this
/// specific parameter is why".
Map<String, dynamic> isolationArmOptions({
  required double temperature,
  required int seed,
  required bool topKTopP,
}) => {
  'temperature': temperature,
  'seed': seed,
  ...topKTopP ? _topKTopPDefaults : _presencePenaltyDefault,
};

/// Every arm this probe runs, in output order. `unpinned` first because
/// every comparison in the write-up reads relative to it.
const ggufProbeArmNames = <String>[
  'unpinned',
  'topk-topp-only',
  'presence-penalty-only',
  'pinned-historical',
];

/// Dispatches [ggufProbeArmNames] to the option-builder for that arm.
Map<String, dynamic> optionsForArm(
  String arm, {
  required double temperature,
  required int seed,
}) => switch (arm) {
  'unpinned' => armOptions(
    temperature: temperature,
    seed: seed,
    pinnedHistorical: false,
  ),
  'pinned-historical' => armOptions(
    temperature: temperature,
    seed: seed,
    pinnedHistorical: true,
  ),
  'topk-topp-only' => isolationArmOptions(
    temperature: temperature,
    seed: seed,
    topKTopP: true,
  ),
  'presence-penalty-only' => isolationArmOptions(
    temperature: temperature,
    seed: seed,
    topKTopP: false,
  ),
  _ => throw ArgumentError('gguf_defaults_probe: unknown arm "$arm"'),
};

ArgParser _buildParser() => ArgParser()
  ..addOption(
    'temperature',
    defaultsTo: '0.6',
    help:
        'Sampling temperature every arm runs at. Pass 0 for the greedy '
        'control -- greedy decoding ignores top_k/top_p, so those two arms '
        'must agree with unpinned there; presence_penalty is not shielded '
        'the same way, since it adjusts logits before the argmax.',
  )
  ..addOption(
    'seed',
    defaultsTo: '$defaultGgufProbeSeed',
    help:
        'Fixed seed sent by every arm, so a difference is attributable to '
        'the parameters rather than to sampling noise.',
  )
  ..addOption('model')
  ..addOption('url')
  ..addOption('samples')
  ..addOption(
    'json',
    help: 'Write the run to this JSON file, as the other probes do.',
  )
  ..addOption('timeout')
  ..addFlag('help', abbr: 'h', negatable: false);

Future<void> main(List<String> argv) async {
  final parser = _buildParser();
  final parsed = parser.parse(argv);
  if (parsed['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }
  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples', 'json', 'timeout'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ]);
  final temperature = double.parse(parsed['temperature'] as String);
  final seed = int.parse(parsed['seed'] as String);

  final systemPrompt = loadCardSystemPrompt();
  final client = HttpClient()..idleTimeout = const Duration(minutes: 10);

  final byArm = <String, List<ProbeOutcome>>{};
  for (final arm in ggufProbeArmNames) {
    final outcomes = <ProbeOutcome>[];
    for (var i = 0; i < args.samples; i++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: ggufProbeUserPrompt,
        options: optionsForArm(arm, temperature: temperature, seed: seed),
        timeout: args.timeout,
      );
      outcomes.add(outcome);
      stdout.writeln(
        '${arm.padRight(22)} #$i  hash=${outcome.hash}  ${outcome.ms}ms  '
        '${outcome.chars}c  ${outcome.label}',
      );
    }
    byArm[arm] = outcomes;
  }
  client.close(force: true);

  /// How many of [args.samples] disagree with `unpinned` at the same sample
  /// index, for [arm].
  int diffsVsUnpinned(String arm) {
    final unpinned = byArm['unpinned']!;
    final other = byArm[arm]!;
    var diffs = 0;
    for (var i = 0; i < args.samples; i++) {
      if (unpinned[i].hash != other[i].hash) diffs++;
    }
    return diffs;
  }

  stdout.writeln();
  for (var i = 0; i < args.samples; i++) {
    stdout.writeln(
      'sample $i: ${[
        for (final arm in ggufProbeArmNames) '$arm=${byArm[arm]![i].hash}',
      ].join('  ')}',
    );
  }

  final sampleDiffs = diffsVsUnpinned('pinned-historical');
  final topKTopPDiffs = diffsVsUnpinned('topk-topp-only');
  final presencePenaltyDiffs = diffsVsUnpinned('presence-penalty-only');
  final verdict = sampleDiffs == 0 ? 'no-difference-observed' : 'output-moved';
  stdout.writeln(
    '\n$sampleDiffs of ${args.samples} sample(s) differ, unpinned vs '
    'pinned-historical, at t=$temperature seed=$seed  (verdict: $verdict)\n'
    'isolation vs unpinned: topk-topp-only differs in $topKTopPDiffs/'
    '${args.samples}, presence-penalty-only differs in '
    '$presencePenaltyDiffs/${args.samples}',
  );

  if (args.json != null) {
    final calls = [
      for (final arm in byArm.entries)
        for (final (i, outcome) in arm.value.indexed)
          ProbeCall(
            caseId: 'planets-table',
            sample: i,
            pass: outcome.ok,
            label: '${outcome.label} hash=${outcome.hash}',
            setting: arm.key,
            ms: outcome.ms,
          ),
    ];
    writeProbeRun(
      path: args.json!,
      probe: 'gguf_defaults_probe',
      model: args.model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      temperature: temperature,
      summary: {
        'seed': seed,
        'sampleDiffs': sampleDiffs,
        'topKTopPDiffsVsUnpinned': topKTopPDiffs,
        'presencePenaltyDiffsVsUnpinned': presencePenaltyDiffs,
        'verdict': verdict,
      },
      calls: calls,
      notes:
          'Four arms at fixed seed $seed: `unpinned` sends only temperature '
          'and seed (what the shipped probes send today); '
          '`pinned-historical` adds $historicalDefaults explicitly -- the '
          'candidate-set defaults a pre-0.33.3 server applied regardless of '
          "a model's Modelfile. `topk-topp-only` and `presence-penalty-only` "
          'each send one half of that set, to isolate which one accounts '
          'for a divergence from `unpinned` -- the *DiffsVsUnpinned summary '
          'fields count how many of the samples differ from `unpinned` by '
          'reply hash, per arm, at this temperature. At t=0, top_k/top_p '
          'constrain only the sampling step greedy decoding skips, so '
          '`topk-topp-only` is expected to match `unpinned`; '
          '`presence_penalty` adjusts logits before the argmax, so '
          '`presence-penalty-only` is not shielded the same way. Whether '
          "Ollama is actually pulling presence_penalty from this model's "
          'Modelfile, as the 0.33.3 changelog entry implies, is not shown '
          'by this comparison and was not confirmed from server logs -- '
          'this measures the effect, not the mechanism.',
    );
  }
}
