import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_results.dart';
import '../tool/model_probes/sync_shape_table.dart';

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
    test('names cases that pass cold and fail warm', () {
      final run = shapeRun(
        model: 'm:1',
        variant: 'seeded',
        cold: const {'table': true, 'facts': true, 'gauge': false},
        warm: const {'table': false, 'facts': true, 'gauge': false},
      );
      expect(erodedFor(run, 3), '`table` (1)');
    });

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

    test('is n/a when turn 1 never produced a card', () {
      expect(
        cascade(const {
          'cases': 3,
          'exercised': 0,
          'passed': 0,
        }).let(cascadeCell),
        'n/a',
      );
    });

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

    test('is derived, so it cannot disagree with the columns beside it', () {
      final rows = derivedRows(
        [
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
        ],
        const {},
      );
      final r = rows['m:1']!;
      expect(r.warm - r.preSeed, r.seedGain);
      expect(seedCell(r), '**needs it** (+8)');
    });
  });

  group('rendering', () {
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
