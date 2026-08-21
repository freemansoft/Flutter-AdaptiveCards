import 'dart:io';

import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/check_results.dart';
import '../tool/model_probes/probe_results.dart';

/// A shape run where [cold] and [warm] cases pass out of 25.
ProbeRun shapeRun({
  required String model,
  required String variant,
  required int cold,
  required int warm,
  Map<String, String> assets = const {'card_system_prompt.txt': 'aaaaaaaaaaaa'},
}) => ProbeRun(
  probe: 'shape_ab',
  model: model,
  variant: variant,
  measuredAt: '2026-08-20',
  samples: 2,
  assets: assets,
  summary: {'cases': 25, 'coldStart': cold, 'withHistory': warm},
  calls: [
    for (var i = 0; i < 25; i++)
      ProbeCall(
        caseId: 'c$i',
        sample: 0,
        pass: i < cold,
        label: 'card[1]',
        condition: 'cold',
      ),
    for (var i = 0; i < 25; i++)
      ProbeCall(
        caseId: 'c$i',
        sample: 0,
        pass: i < warm,
        label: 'card[1]',
        condition: 'warm',
      ),
  ],
);

String tableWith({
  required int cold,
  required int warm,
  required int preSeed,
}) =>
    '''
| Model | Weights | Cold-start | With history | Warm, pre-seed | Cascade | Eroded |
| --- | --- | --- | --- | --- | --- | --- |
| `m:1` | 1.0 GB | **$cold/25** | $warm/25 | $preSeed/25 | 3/3 | none |
''';

const currentAssets = {'card_system_prompt.txt': 'aaaaaaaaaaaa'};

void main() {
  group('launch.json parsing', () {
    test('reads the models the repo actually launches', () {
      // Not a fixture: the point of this check is that the real file is the
      // source of truth, so a hardcoded copy going stale is the bug.
      final models = launchedModels('../.vscode/launch.json');
      expect(models, isNotEmpty);
      // The compiled-in default must stay launchable by hand, or it ships
      // untested from the one place people start the server manually.
      expect(models, contains(defaultOllamaModel));
      // The set is expected to change, so its size is not asserted — only
      // that the derivation returns each model once. A duplicate would mean
      // two configs disagree about a tag, which is the failure worth
      // catching.
      expect(models.toSet(), hasLength(models.length));
    });

    test('returns empty rather than throwing when the file is absent', () {
      expect(launchedModels('/nonexistent/launch.json'), isEmpty);
    });
  });

  group('shape table parsing', () {
    test('reads bolded and plain cells alike', () {
      final rows = shapeTableRows(tableWith(cold: 24, warm: 23, preSeed: 22));
      expect(rows['m:1'], (24, 23, 22, 25));
    });

    test('skips a row whose figures are not plain scores', () {
      final rows = shapeTableRows(
        '| `m:1` | 1.0 GB | — | n/a | 22/25 | 3/3 | none |',
      );
      expect(rows, isEmpty);
    });
  });

  group('drift', () {
    test('passes when the table matches the recorded runs', () {
      final findings = check(
        results: [
          shapeRun(model: 'm:1', variant: 'seeded', cold: 24, warm: 23),
          shapeRun(model: 'm:1', variant: 'unaided', cold: 23, warm: 22),
        ],
        launched: const [],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 24, warm: 23, preSeed: 22),
      );
      expect(findings.where((f) => f.fatal), isEmpty);
    });

    test('fails when a published figure disagrees with the calls', () {
      final findings = check(
        results: [
          shapeRun(model: 'm:1', variant: 'seeded', cold: 24, warm: 23),
        ],
        launched: const [],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 22, warm: 23, preSeed: 22),
      );
      expect(
        findings.where((f) => f.fatal).map((f) => f.message).join(),
        allOf(contains('table says cold-start 22/25'), contains('give 24/25')),
      );
    });

    test('fails when a run summary disagrees with its own calls', () {
      // The error a human reading the console could never catch.
      final run = shapeRun(model: 'm:1', variant: 'seeded', cold: 24, warm: 23);
      final lying = ProbeRun(
        probe: run.probe,
        model: run.model,
        variant: run.variant,
        measuredAt: run.measuredAt,
        samples: run.samples,
        assets: run.assets,
        summary: const {'cases': 25, 'coldStart': 25, 'withHistory': 23},
        calls: run.calls,
      );
      final findings = check(
        results: [lying],
        launched: const [],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 25, warm: 23, preSeed: 22),
      );
      expect(
        findings.where((f) => f.fatal).map((f) => f.message).join(),
        contains('summary.coldStart says 25 but its own calls give 24'),
      );
    });

    test('fails when a model has results but no published row', () {
      final findings = check(
        results: [
          shapeRun(model: 'ghost:1', variant: 'seeded', cold: 24, warm: 23),
        ],
        launched: const [],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 24, warm: 23, preSeed: 22),
      );
      expect(
        findings.where((f) => f.fatal).map((f) => f.message).join(),
        contains('no row in the table'),
      );
    });
  });

  group('partial runs', () {
    test('a --only run is reported, not compared against the full table', () {
      // Re-checking one shape without paying for the other twenty-four is
      // what --only is for; failing the build for it would punish the right
      // behavior.
      const partial = ProbeRun(
        probe: 'shape_ab',
        model: 'm:1',
        variant: 'seeded',
        measuredAt: '2026-08-20',
        samples: 1,
        assets: currentAssets,
        summary: {'cases': 2, 'coldStart': 1, 'withHistory': 1},
        calls: [
          ProbeCall(
            caseId: 'table',
            sample: 0,
            pass: true,
            label: 'card[1]',
            condition: 'cold',
          ),
          ProbeCall(
            caseId: 'facts',
            sample: 0,
            pass: true,
            label: 'card[1]',
            condition: 'warm',
          ),
        ],
      );
      final findings = check(
        results: [partial],
        launched: const [],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 24, warm: 23, preSeed: 22),
      );
      expect(findings.where((f) => f.fatal), isEmpty);
      expect(
        findings.map((f) => f.message).join(),
        contains('covers 2 of 25 cases'),
      );
    });
  });

  group('staleness', () {
    ProbeRun stale(String model) => shapeRun(
      model: model,
      variant: 'seeded',
      cold: 24,
      warm: 23,
      assets: const {'card_system_prompt.txt': 'ffffffffffff'},
    );

    test('is fatal for a model launch.json launches', () {
      final findings = check(
        results: [stale('m:1')],
        launched: const ['m:1'],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 24, warm: 23, preSeed: 22),
      );
      final fatal = findings.where((f) => f.fatal).map((f) => f.message).join();
      expect(fatal, contains('measured against card_system_prompt.txt'));
      expect(fatal, contains('tree has aaaaaaaaaaaa'));
    });

    test('is only a note for a model nobody launches', () {
      // Re-running fourteen models on every prompt edit is not a gate anyone
      // would keep, so the rest of the matrix reports rather than blocks.
      final findings = check(
        results: [stale('m:1')],
        launched: const [],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 24, warm: 23, preSeed: 22),
      );
      expect(findings.where((f) => f.fatal), isEmpty);
      expect(findings.where((f) => !f.fatal), isNotEmpty);
    });

    test('says nothing when the digests still match', () {
      final findings = check(
        results: [
          shapeRun(model: 'm:1', variant: 'seeded', cold: 24, warm: 23),
        ],
        launched: const ['m:1'],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 24, warm: 23, preSeed: 22),
      );
      expect(
        findings
            .map((f) => f.message)
            .where((m) => m.contains('measured against')),
        isEmpty,
      );
    });
  });

  group('coverage', () {
    test('names the probes a launched model has never been through', () {
      // The gap that let gpt-oss:20b's format support go unmeasured while it
      // held a launch.json slot.
      final findings = check(
        results: [
          shapeRun(model: 'm:1', variant: 'seeded', cold: 24, warm: 23),
        ],
        launched: const ['m:1'],
        currentAssets: currentAssets,
        markdown: tableWith(cold: 24, warm: 23, preSeed: 22),
      );
      final note = findings.firstWhere((f) => !f.fatal).message;
      expect(note, contains('json_format_probe'));
      expect(note, contains('cascade_ab'));
      // It has this one, so it must not be listed as missing.
      expect(note, isNot(contains('shape_ab-seeded')));
    });

    test('does not block the build', () {
      final findings = check(
        results: const [],
        launched: const ['m:1'],
        currentAssets: currentAssets,
        markdown: '',
      );
      expect(findings.where((f) => f.fatal), isEmpty);
    });
  });

  group('the committed results', () {
    test('every recorded run parses and agrees with itself', () {
      // Guards the backfilled files themselves: a hand-written JSON that no
      // probe produced is exactly where a typo would hide.
      final runs = readAllResults('tool/model_probes/results');
      expect(runs, isNotEmpty);
      for (final run in runs) {
        expect(run.model, isNotEmpty, reason: run.probe);
        expect(run.calls, isNotEmpty, reason: run.model);
        expect(run.assets, isNotEmpty, reason: run.model);
        expect(run.machine, isNotNull, reason: run.model);
      }
    });

    test('the checker passes against the real tree', () {
      final findings = check(
        results: readAllResults('tool/model_probes/results'),
        launched: launchedModels('../.vscode/launch.json'),
        currentAssets: currentAssetDigests('assets'),
        markdown: File('ModelBehavior.md').readAsStringSync(),
      );
      expect(
        findings.where((f) => f.fatal).map((f) => f.message).toList(),
        isEmpty,
      );
    });
  });
}
