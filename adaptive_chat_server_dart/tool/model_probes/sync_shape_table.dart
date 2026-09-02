/// Regenerates `ModelBehavior.md`'s shape-coverage table from recorded runs.
///
/// That table is fifteen rows of five figures each — seventy-five numbers,
/// every one of which used to be copied out of a terminal by hand. Copying is
/// how the numbers got there, and copying is the one step in this pipeline
/// with no check on it: `check_results.dart` can prove a figure disagrees with
/// the run behind it, but somebody still has to fix it, and fixing seventy-five
/// numbers by hand is the same error-prone step again.
///
/// So this writes the table instead. `check_results.dart` verifies, this
/// generates, and the two agree by construction: after a sync the checker has
/// nothing to report.
///
/// Only the rows it can derive are touched. A model with no recorded shape run
/// keeps whatever the file already says, because deleting a historical
/// measurement nobody has re-taken would lose data rather than correct it.
///
/// ```sh
/// dart run tool/model_probes/sync_shape_table.dart          # show the diff
/// dart run tool/model_probes/sync_shape_table.dart --write  # apply it
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'check_results.dart';
import 'probe_results.dart';

/// One rendered row of the shape-coverage table.
class ShapeRow {
  /// Creates a row.
  const ShapeRow({
    required this.model,
    required this.weights,
    required this.cold,
    required this.warm,
    required this.preSeed,
    required this.cascade,
    required this.eroded,
    this.seedGain = 0,
  });

  /// Model tag, as the table prints it.
  final String model;

  /// Weight column, carried over verbatim — it comes from Ollama, not a probe.
  final String weights;

  /// Cold-start shapes.
  final int cold;

  /// With-history shapes, the figure the file says to read first.
  final int warm;

  /// With-history shapes without the card seed.
  final int preSeed;

  /// Cascade result, already formatted (`3/3`, `n/a`).
  final String cascade;

  /// Shapes the seed is worth: with-history seeded minus with-history unaided.
  ///
  /// Its own column because it answers a question the score cannot — whether a
  /// model earned its number or was carried to it. A host deciding whether to
  /// pass `--seed-card-file` reads this, not the score.
  final int seedGain;

  /// Shapes that pass cold and fail warm, already formatted.
  final String eroded;
}

/// Cases that pass cold-start and fail with history.
///
/// The erosion column: what two prose turns cost a model. Derived rather than
/// recorded so it cannot drift from the calls it summarises.
String erodedFor(ProbeRun run, int total) {
  bool passes(String condition, String id) {
    final samples = run.calls.where(
      (c) => c.condition == condition && c.caseId == id,
    );
    return samples.isNotEmpty && samples.every((c) => c.pass);
  }

  final ids = run.calls.map((c) => c.caseId).toSet().toList()..sort();
  final lost = [
    for (final id in ids)
      if (passes('cold', id) && !passes('warm', id)) id,
  ];
  return lost.isEmpty
      ? 'none'
      : '${lost.map((e) => '`$e`').join(', ')} (${lost.length})';
}

/// Formats the cascade cell from a recorded cascade run.
///
/// `n/a` rather than `0/3` when nothing was exercised: a model whose turn 1
/// produced no card never reached the cascade, and scoring that a cascade
/// failure reports a turn-1 shortcoming twice.
String cascadeCell(ProbeRun? run) {
  if (run == null) return '—';
  // `exercised` is absent from runs recorded before cascade_ab reported it;
  // for those the case count is the best available denominator, and treating
  // a missing key as "nothing exercised" would silently downgrade a real 3/3
  // to n/a.
  final exercised =
      run.summary['exercised'] as int? ?? run.summary['cases'] as int? ?? 0;
  if (exercised == 0) return 'n/a';
  return '${run.summary['passed']}/$exercised';
}

/// Builds the rows derivable from [results], keyed by model.
Map<String, ShapeRow> derivedRows(
  List<ProbeRun> results,
  Map<String, CarriedCells> carried, {
  Map<String, (int, int, int, int)> published = const {},
}) {
  ProbeRun? pick(String model, String probe, String? variant) {
    for (final r in results) {
      if (r.model == model && r.probe == probe && r.variant == variant) {
        return r;
      }
    }
    return null;
  }

  final rows = <String, ShapeRow>{};
  final models = results
      .where((r) => r.probe == 'shape_ab' && r.variant == 'seeded')
      .map((r) => r.model)
      .toSet();
  for (final model in models) {
    final seeded = pick(model, 'shape_ab', 'seeded')!;
    final unaided = pick(model, 'shape_ab', 'unaided');
    final total = seeded.calls.map((c) => c.caseId).toSet().length;
    // A partial `--only` run is a legitimate thing to record but cannot
    // stand in for a full sweep, so it is not allowed to rewrite a row.
    if (total < 25) continue;
    final cascadeRun = pick(model, 'cascade_ab', null);
    rows[model] = ShapeRow(
      model: model,
      weights: carried[model]?.weights ?? '—',
      cold: shapesFor(seeded, 'cold'),
      warm: shapesFor(seeded, 'warm'),
      // A seeded run can land before its unaided pair — mid-sweep, or
      // because only one was re-taken. Blanking the published pre-seed
      // figure in that window would delete a real measurement to say
      // nothing, so it is carried until a run replaces it.
      preSeed: unaided != null
          ? shapesFor(unaided, 'warm')
          : (published[model]?.$3 ?? -1),
      // No recorded cascade run yet is not the same as a cascade that
      // failed, so the published cell stands until one exists.
      cascade: cascadeRun == null
          ? (carried[model]?.cascade ?? '—')
          : cascadeCell(cascadeRun),
      eroded: erodedFor(seeded, total),
      seedGain: unaided == null
          ? 0
          : shapesFor(seeded, 'warm') - shapesFor(unaided, 'warm'),
    );
  }
  return rows;
}

/// The seed column: what `--seed-card-file` is worth to this model.
///
/// Bucketed rather than printed raw, because the decision it informs is
/// binary — pass the flag or don't — with the number beside it for anyone who
/// doubts the verdict.
String seedCell(ShapeRow r) {
  if (r.preSeed < 0) return '—';
  final n = r.seedGain;
  if (n >= 5) return '**needs it** (+$n)';
  if (n >= 2) return 'helps (+$n)';
  if (n >= 0) return 'no effect (${n > 0 ? '+' : ''}$n)';
  return '_hurts_ ($n)';
}

/// Renders the table body, best-first by with-history coverage.
///
/// Bolding marks the leaders in each numeric column, which is the convention
/// the hand-written table already used; deriving it keeps a stale bold from
/// outliving the number that earned it.
String renderTable(List<ShapeRow> rows) {
  final sorted = [...rows]
    ..sort((a, b) {
      final byWarm = b.warm.compareTo(a.warm);
      if (byWarm != 0) return byWarm;
      final byCold = b.cold.compareTo(a.cold);
      if (byCold != 0) return byCold;
      return b.preSeed.compareTo(a.preSeed);
    });
  final bestCold = sorted.map((r) => r.cold).reduce((a, b) => a > b ? a : b);
  final bestWarm = sorted.map((r) => r.warm).reduce((a, b) => a > b ? a : b);
  final bestPre = sorted.map((r) => r.preSeed).reduce((a, b) => a > b ? a : b);
  String cell(int v, int best) =>
      v < 0 ? '—' : (v == best ? '**$v/25**' : '$v/25');

  final buffer = StringBuffer()
    ..writeln(
      '| Model | Weights | Cold-start | With history | Warm, pre-seed | '
      'Seed | Cascade | Eroded by history |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final r in sorted) {
    buffer.writeln(
      '| `${r.model}` | ${r.weights} | ${cell(r.cold, bestCold)} | '
      '${cell(r.warm, bestWarm)} | ${cell(r.preSeed, bestPre)} | '
      '${seedCell(r)} | ${r.cascade} | ${r.eroded} |',
    );
  }
  return buffer.toString();
}

/// Cells the published table carries that no recorded run can supply.
///
/// Weights come from Ollama rather than a probe, and a row this tool cannot
/// derive still has real measured Cascade and Eroded values behind it. Both
/// are carried through verbatim: rewriting a row must never turn a
/// measurement somebody took into an em dash.
class CarriedCells {
  /// Creates the carried set.
  const CarriedCells({
    required this.weights,
    required this.cascade,
    required this.eroded,
  });

  /// Weight column.
  final String weights;

  /// Cascade column, as published.
  final String cascade;

  /// Erosion column, as published.
  final String eroded;
}

/// Reads the cells that must survive a rewrite, keyed by model.
Map<String, CarriedCells> carriedFromMarkdown(String markdown) {
  final out = <String, CarriedCells>{};
  for (final line in markdown.split('\n')) {
    if (!line.startsWith('| `')) continue;
    final cells = line.split('|').map((c) => c.trim()).toList();
    if (cells.length < 9) continue;
    if (!cells[2].endsWith('GB')) continue;
    out[cells[1].replaceAll('`', '')] = CarriedCells(
      weights: cells[2],
      cascade: cells[7],
      eroded: cells[8],
    );
  }
  return out;
}

/// Replaces the shape-coverage table in [markdown] with [table].
///
/// Located by its header row rather than by line number, so ordinary edits
/// above or below it do not move the target.
String replaceTable(String markdown, String table) {
  final lines = markdown.split('\n');
  final start = lines.indexWhere(
    (l) => l.startsWith('| Model') && l.contains('Warm, pre-seed'),
  );
  if (start < 0) {
    stderr.writeln('sync_shape_table: shape-coverage table not found');
    exit(2);
  }
  var end = start + 1;
  while (end < lines.length && lines[end].startsWith('|')) {
    end++;
  }
  return [
    ...lines.sublist(0, start),
    ...table.trimRight().split('\n'),
    ...lines.sublist(end),
  ].join('\n');
}

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addFlag('write', negatable: false, help: 'Apply the change in place.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final args = parser.parse(argv);
  if (args['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }

  final root = Directory.current.path;
  final mdPath = p.join(root, 'ModelBehavior.md');
  final markdown = File(mdPath).readAsStringSync();
  final results = readAllResults(
    p.join(root, 'tool', 'model_probes', 'results-m1max-64gb-ollama033'),
  );
  final carried = carriedFromMarkdown(markdown);
  final published = shapeTableRows(markdown);
  final derived = derivedRows(results, carried, published: published);

  if (derived.isEmpty) {
    stdout.writeln('sync_shape_table: no complete shape runs recorded yet');
    return;
  }

  // Rows with no recorded run keep their published figures: a measurement
  // nobody has re-taken is still the best thing known.
  final kept = <ShapeRow>[
    for (final entry in published.entries)
      if (!derived.containsKey(entry.key))
        ShapeRow(
          model: entry.key,
          weights: carried[entry.key]?.weights ?? '—',
          cold: entry.value.$1,
          warm: entry.value.$2,
          preSeed: entry.value.$3,
          cascade: carried[entry.key]?.cascade ?? '—',
          eroded: carried[entry.key]?.eroded ?? '—',
        ),
  ];
  final updated = replaceTable(
    markdown,
    renderTable([...derived.values, ...kept]),
  );

  stdout.writeln(
    'sync_shape_table: ${derived.length} row(s) derived from recorded runs, '
    '${kept.length} kept as published',
  );
  if (updated == markdown) {
    stdout.writeln('already in sync');
    return;
  }
  if (!(args['write'] as bool)) {
    stdout.writeln('would rewrite the table; re-run with --write to apply');
    return;
  }
  File(mdPath).writeAsStringSync(updated);
  stdout.writeln('wrote $mdPath');
}
