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
| Model | Weights | Cold-start | With history | Warm, pre-seed | Cascade | Eroded by history |
| --- | --- | --- | --- | --- | --- | --- |
| `m:1` | 4.4 GB | 21/25 | 19/25 | 18/25 | 3/3 | `carousel`, `table` (2) |
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
