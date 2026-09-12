import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_results.dart';
import '../tool/model_probes/sync_shape_table.dart';

// sync_shape_table.dart replaces the hand-copied step in filling in
// ModelBehavior.md's shape-coverage table — seventy-five figures that used
// to be typed out of a terminal, with no check on the copying (see that
// file's doc comment; check_results_test.dart is what catches a copy that
// went wrong). This file is NOT that kind of data checker: every case below
// builds its own synthetic ProbeRun/markdown fixtures and asserts against
// the pure derivation/formatting functions (erodedFor, cascadeCell,
// derivedRows, seedCell, renderTable, carriedFromMarkdown, replaceTable) —
// it never reads a real results-*/ JSON file or the real ModelBehavior.md.
// It is a genuine behavioral unit test suite, guarding that a table rewrite
// can never turn a real measurement into an em dash or a stale figure, and
// that the derived columns (cascade, eroded, seed) stay honest about what a
// partial or missing run actually proves.

ProbeRun shapeRun({
  required String model,
  required String variant,
  required Map<String, bool> cold,
  required Map<String, bool> warm,
}) => ProbeRun(
  probe: 'shape_ab',
  model: model,
  variant: variant,
  measuredAt: '2026-08-20',
  samples: 1,
  assets: const {'card_system_prompt.txt': 'aaaaaaaaaaaa'},
  calls: [
    for (final e in cold.entries)
      ProbeCall(
        caseId: e.key,
        sample: 0,
        pass: e.value,
        label: 'card[1]',
        condition: 'cold',
      ),
    for (final e in warm.entries)
      ProbeCall(
        caseId: e.key,
        sample: 0,
        pass: e.value,
        label: 'card[1]',
        condition: 'warm',
      ),
  ],
);

void main() {
  group('erosion', () {
    // The regression this column exists to name: a shape a model gets right
    // cold and abandons once prose has accumulated in history ("warm-start
    // prose drift" in ModelBehavior.md). erodedFor must say which case was
    // lost, not just how many.
    test('names cases that pass cold and fail warm', () {
      final run = shapeRun(
        model: 'm:1',
        variant: 'seeded',
        cold: const {'table': true, 'facts': true, 'gauge': false},
        warm: const {'table': false, 'facts': true, 'gauge': false},
      );
      expect(erodedFor(run, 3), '`table` (1)');
    });

    // A model with identical cold and warm sets must not register as having
    // eroded anything, even though the column exists to spot exactly this
    // kind of pass/fail flip.
    test('is none when nothing is lost', () {
      final run = shapeRun(
        model: 'm:1',
        variant: 'seeded',
        cold: const {'table': true},
        warm: const {'table': true},
      );
      expect(erodedFor(run, 1), 'none');
    });

    test('does not count a case that failed cold as eroded', () {
      // Never produced under either condition is a permanent miss, not
      // something history took away.
      final run = shapeRun(
        model: 'm:1',
        variant: 'seeded',
        cold: const {'carousel': false},
        warm: const {'carousel': false},
      );
      expect(erodedFor(run, 1), 'none');
    });
  });

  group('cascade cell', () {
    ProbeRun cascade(Map<String, dynamic> summary) => ProbeRun(
      probe: 'cascade_ab',
      model: 'm:1',
      measuredAt: '2026-08-20',
      samples: 1,
      assets: const {},
      summary: summary,
      calls: const [
        ProbeCall(caseId: 'states', sample: 0, pass: true, label: 'multi'),
      ],
    );

    // cascadeCell's ordinary path: a complete run reports passed/exercised,
    // not the raw case count — the fallback and n/a tests below cover why
    // that denominator can differ from `cases`.
    test('reports passed over exercised', () {
      expect(
        cascade(const {'exercised': 3, 'passed': 3}).let(cascadeCell),
        '3/3',
      );
    });

    test('falls back to cases when exercised was not recorded', () {
      // Runs predating the `exercised` key must not be downgraded to n/a.
      expect(cascade(const {'cases': 3, 'passed': 3}).let(cascadeCell), '3/3');
    });

    // A turn-1 miss never reaches the cascade at all; scoring it 0/N here
    // would count the same shape failure twice — once in coverage, once in
    // cascade.
    test('is n/a when turn 1 never produced a card', () {
      expect(
        cascade(const {'cases': 3, 'exercised': 0, 'passed': 0})
            .let(cascadeCell),
        'n/a',
      );
    });

    // Distinguishes "never measured" from "measured and failed"; collapsing
    // the two would make an un-run model look like it scored zero.
    test('is an em dash when no run exists at all', () {
      expect(cascadeCell(null), '—');
    });
  });

  group('carried cells', () {
    const table = '''
| Model | Weights | Cold-start | With history | Warm, pre-seed | Seed | Cascade | Eroded by history |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `m:1` | 4.4 GB | 21/25 | 19/25 | 18/25 | helps (+1) | 3/3 | `carousel`, `table` (2) |
''';

    // Weights, and cascade/eroded until a fresh run lands, are never
    // derivable from a probe run at all; carriedFromMarkdown is how a
    // rewrite keeps them instead of losing them to the columns this tool can
    // actually compute.
    test('preserves what no probe can supply', () {
      final carried = carriedFromMarkdown(table);
      expect(carried['m:1']!.weights, '4.4 GB');
      expect(carried['m:1']!.cascade, '3/3');
      expect(carried['m:1']!.eroded, '`carousel`, `table` (2)');
    });

    test('a row with no recorded run keeps its published cells', () {
      // Rewriting a table must never turn a real measurement into an em dash.
      final out = replaceTable(
        table,
        renderTable([
          ShapeRow(
            model: 'm:1',
            weights: carriedFromMarkdown(table)['m:1']!.weights,
            cold: 21,
            warm: 19,
            preSeed: 18,
            cascade: carriedFromMarkdown(table)['m:1']!.cascade,
            eroded: carriedFromMarkdown(table)['m:1']!.eroded,
          ),
        ]),
      );
      expect(out, contains('3/3'));
      expect(out, contains('`carousel`, `table` (2)'));
      expect(out, contains('4.4 GB'));
    });
  });

  group('a seeded run without its unaided pair', () {
    test('keeps the published pre-seed figure instead of blanking it', () {
      // Mid-sweep the seeded run lands first. Rewriting the row then must not
      // delete a pre-seed measurement somebody took, to replace it with an em
      // dash that says nothing.
      final rows = derivedRows(
        [
          ProbeRun(
            probe: 'shape_ab',
            model: 'm:1',
            variant: 'seeded',
            measuredAt: '2026-08-20',
            samples: 1,
            assets: const {},
            calls: [
              for (var i = 0; i < 25; i++)
                ProbeCall(
                  caseId: 'c$i',
                  sample: 0,
                  pass: i < 20,
                  label: 'card[1]',
                  condition: 'cold',
                ),
              for (var i = 0; i < 25; i++)
                ProbeCall(
                  caseId: 'c$i',
                  sample: 0,
                  pass: i < 18,
                  label: 'card[1]',
                  condition: 'warm',
                ),
            ],
          ),
        ],
        const {},
        published: const {'m:1': (21, 19, 13, 25)},
      );
      expect(rows['m:1']!.cold, 20);
      expect(rows['m:1']!.warm, 18);
      // Not re-measured, so the published figure stands.
      expect(rows['m:1']!.preSeed, 13);
    });
  });

  group('the seed column', () {
    ShapeRow row(int gain, {int preSeed = 18}) => ShapeRow(
      model: 'm:1',
      weights: '1 GB',
      cold: 20,
      warm: 20,
      preSeed: preSeed,
      cascade: '3/3',
      eroded: 'none',
      seedGain: gain,
    );

    // The verdict text is what a host reads to decide --seed-card-file; the
    // raw number stays beside it so the bucket boundaries stay checkable
    // rather than trusted blindly.
    test('buckets the gain into a verdict, keeping the number', () {
      expect(seedCell(row(10)), '**needs it** (+10)');
      expect(seedCell(row(5)), '**needs it** (+5)');
      expect(seedCell(row(3)), 'helps (+3)');
      expect(seedCell(row(1)), 'no effect (+1)');
      expect(seedCell(row(0)), 'no effect (0)');
      expect(seedCell(row(-2)), '_hurts_ (-2)');
    });

    test('is an em dash when no unaided run exists to compare against', () {
      // A gain of 0 and "never measured" are different claims, and only the
      // pre-seed column can tell them apart.
      expect(seedCell(row(0, preSeed: -1)), '—');
    });

    // Guards against the seed column drifting from the warm/pre-seed columns
    // it is computed from — an independently recorded seedGain could
    // disagree with its own inputs; a derived one structurally cannot.
    test('is derived, so it cannot disagree with the columns beside it', () {
      final rows = derivedRows([
        shapeRun(
          model: 'm:1',
          variant: 'seeded',
          cold: {for (var i = 0; i < 25; i++) 'c$i': i < 20},
          warm: {for (var i = 0; i < 25; i++) 'c$i': i < 20},
        ),
        shapeRun(
          model: 'm:1',
          variant: 'unaided',
          cold: {for (var i = 0; i < 25; i++) 'c$i': i < 12},
          warm: {for (var i = 0; i < 25; i++) 'c$i': i < 12},
        ),
      ], const {});
      final r = rows['m:1']!;
      expect(r.warm - r.preSeed, r.seedGain);
      expect(seedCell(r), '**needs it** (+8)');
    });
  });

  group('rendering', () {
    // The table's own header calls with-history the figure to read first;
    // the sort order must match what the file tells a reader to look at.
    test('sorts by with-history, the figure the file says to read first', () {
      const rows = [
        ShapeRow(
          model: 'low:1',
          weights: '1 GB',
          cold: 25,
          warm: 10,
          preSeed: 1,
          cascade: '3/3',
          eroded: 'none',
        ),
        ShapeRow(
          model: 'high:1',
          weights: '1 GB',
          cold: 1,
          warm: 24,
          preSeed: 1,
          cascade: '3/3',
          eroded: 'none',
        ),
      ];
      final lines = renderTable(rows).trim().split('\n');
      expect(lines[2], contains('high:1'));
      expect(lines[3], contains('low:1'));
    });

    // Bolding is the table's only visual signal for "this model leads here";
    // it must track a re-sort rather than becoming a stale mark on whichever
    // model used to lead.
    test('bolds the leader in each numeric column', () {
      const rows = [
        ShapeRow(
          model: 'a:1',
          weights: '1 GB',
          cold: 24,
          warm: 23,
          preSeed: 20,
          cascade: '3/3',
          eroded: 'none',
        ),
        ShapeRow(
          model: 'b:1',
          weights: '1 GB',
          cold: 20,
          warm: 20,
          preSeed: 22,
          cascade: '3/3',
          eroded: 'none',
        ),
      ];
      final out = renderTable(rows);
      expect(out, contains('**24/25**'));
      expect(out, contains('**23/25**'));
      // The pre-seed leader is the other model, so its cell carries the bold.
      expect(out, contains('**22/25**'));
      expect(out, isNot(contains('**20/25**')));
    });

    // A model that never got an unaided run must not display as having
    // scored zero pre-seed shapes — that reads as a measured failure rather
    // than an absent measurement.
    test('renders a missing pre-seed run as an em dash, not a zero', () {
      const rows = [
        ShapeRow(
          model: 'a:1',
          weights: '1 GB',
          cold: 24,
          warm: 23,
          preSeed: -1,
          cascade: '3/3',
          eroded: 'none',
        ),
      ];
      expect(renderTable(rows), contains(' — |'));
    });
  });
}

/// Small helper so a literal reads left-to-right in the cascade tests.
extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
