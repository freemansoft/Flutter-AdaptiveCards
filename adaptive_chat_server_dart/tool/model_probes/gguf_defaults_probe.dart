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
/// **Design.** Two arms against the same model, prompt, and fixed `--seed`,
/// differing only in whether the candidate-set parameters are sent:
///
///   - `unpinned` sends what the shipped probes send today — `temperature`
///     and `seed`, nothing else. Under 0.33.3 the unsent knobs are free to
///     take the Modelfile's values.
///   - `pinned-historical` adds [historicalDefaults] explicitly: the
///     effective sampling a pre-0.33.3 server would have applied regardless
///     of what the Modelfile declares.
///
/// A fixed seed removes sampling noise, so a difference between arms at a
/// sampled temperature is attributable to the parameters. **Always run the
/// `--temperature 0` control alongside the sampled run.** Greedy decoding
/// takes the argmax and cannot be moved by `top_k`/`top_p`/`presence_penalty`,
/// so the two arms *must* agree there; if they don't, something other than
/// sampling differs between them and a sampled-temperature disagreement
/// cannot be attributed to the parameters either.
///
/// **Reading a result.** Compare the `hash` suffix this probe appends to
/// each call's `label` between `unpinned` and `pinned-historical` at the same
/// sample index — that comparison is unaffected by a timeout-triggered
/// runner reload, because the seed and the parameters determine the output
/// regardless of whether the runner was reloaded first. `ms` either side of
/// a timeout is not comparable for the same reason `probeOnce` evicts on
/// timeout in the first place.
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
/// `pinned-historical` arm.
const historicalDefaults = <String, dynamic>{
  'top_k': 40,
  'top_p': 0.9,
  'presence_penalty': 0,
};

/// Fixed default seed, so a bare run removes sampling noise without the
/// caller having to pick one.
const defaultGgufProbeSeed = 42;

/// The single prompt both arms send. Long enough, and open-ended enough, for
/// `presence_penalty` to plausibly move the reply if it is actually applied.
const ggufProbeUserPrompt =
    'Show me a table of the 4 largest planets with diameter and moons.';

/// Builds the `options` map for one arm.
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

/// The two arms this probe compares, `unpinned` first.
const ggufProbeArms = <String, bool>{
  'unpinned': false,
  'pinned-historical': true,
};

ArgParser _buildParser() => ArgParser()
  ..addOption(
    'temperature',
    defaultsTo: '0.6',
    help:
        'Sampling temperature both arms run at. Pass 0 for the greedy '
        'control -- greedy decoding ignores the candidate-set parameters, '
        'so the arms must agree there or something other than sampling '
        'differs between them.',
  )
  ..addOption(
    'seed',
    defaultsTo: '$defaultGgufProbeSeed',
    help:
        'Fixed seed sent by both arms, so a difference is attributable to '
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
  for (final arm in ggufProbeArms.entries) {
    final outcomes = <ProbeOutcome>[];
    for (var i = 0; i < args.samples; i++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: ggufProbeUserPrompt,
        options: armOptions(
          temperature: temperature,
          seed: seed,
          pinnedHistorical: arm.value,
        ),
        timeout: args.timeout,
      );
      outcomes.add(outcome);
      stdout.writeln(
        '${arm.key.padRight(18)} #$i  hash=${outcome.hash}  ${outcome.ms}ms  '
        '${outcome.chars}c  ${outcome.label}',
      );
    }
    byArm[arm.key] = outcomes;
  }
  client.close(force: true);

  final unpinned = byArm['unpinned']!;
  final pinned = byArm['pinned-historical']!;
  var diffs = 0;
  for (var i = 0; i < args.samples; i++) {
    final same = unpinned[i].hash == pinned[i].hash;
    if (!same) diffs++;
    stdout.writeln(
      'sample $i: unpinned=${unpinned[i].hash} '
      'pinned-historical=${pinned[i].hash}  ${same ? 'SAME' : 'DIFFERS'}',
    );
  }
  final verdict = diffs == 0 ? 'no-difference-observed' : 'output-moved';
  stdout.writeln(
    '\n$diffs of ${args.samples} sample(s) differ between arms at '
    't=$temperature seed=$seed  (verdict: $verdict)',
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
        'sampleDiffs': diffs,
        'verdict': verdict,
      },
      calls: calls,
      notes:
          'Two arms at fixed seed $seed: `unpinned` sends only temperature '
          'and seed (what the shipped probes send today); '
          '`pinned-historical` adds $historicalDefaults explicitly -- the '
          'candidate-set defaults a pre-0.33.3 server applied regardless of '
          "a model's Modelfile. sampleDiffs counts how many of the samples "
          'differ between arms by reply hash at this temperature. Run '
          'alongside a --temperature 0 control: greedy decoding ignores '
          'these parameters, so the arms must agree there or the '
          'sampled-temperature result is not attributable to them.',
    );
  }
}
