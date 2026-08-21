/// Checks recorded probe results without running a model.
///
/// The CI server cannot run Ollama, so nothing in `tool/model_probes/` can be
/// a CI gate directly. What CI *can* do is police the artifacts a hand-run
/// probe left behind, and that turns out to cover the three ways a number in
/// [`ModelBehavior.md`](../../ModelBehavior.md) goes wrong without anyone
/// noticing:
///
/// 1. **Drift.** Every figure in that file was hand-copied out of a probe's
///    console output. A typo, or an edit that updates one table and not the
///    other, is invisible. Checked by re-deriving the tables from the results.
/// 2. **Staleness.** The file opens by saying every result was measured with
///    `assets/card_system_prompt.txt` — but not with *which version*, and that
///    prompt has been edited repeatedly. Each edit silently turns every
///    recorded number into a historical one. Checked against the digests each
///    run stored.
/// 3. **Gaps.** `gpt-oss:20b` sat in `launch.json` as a top-three model with
///    its `format` support never measured, and nobody knew until someone
///    asked a question that happened to need it. Checked by listing the
///    probes a launched model has no result for.
///
/// Run it with no arguments from the package root.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'probe_results.dart';

/// Probes a model in `launch.json` is expected to have been through.
///
/// Deliberately not every script here: `prompt_ab.dart` compares prompts
/// rather than models, and `dump_reply.dart` is a debugging aid, so neither
/// produces a per-model result worth demanding.
const expectedProbes = {
  'shape_ab-seeded',
  'shape_ab-unaided',
  'cascade_ab',
  'temperature_stress',
  'temperature_matrix',
  'json_format_probe',
};

/// One thing wrong, and whether it should fail the build.
class Finding {
  /// Creates a finding.
  const Finding({required this.fatal, required this.message});

  /// Whether this fails CI rather than merely printing.
  final bool fatal;

  /// Human-readable description.
  final String message;
}

/// Model tags `launch.json` currently launches.
///
/// Read rather than hardcoded for the same reason `ModelBehavior.md` tells
/// readers to re-derive the list: the set is expected to change, and a copy
/// of it goes stale silently.
List<String> launchedModels(String launchJsonPath) {
  final file = File(launchJsonPath);
  if (!file.existsSync()) return const [];
  // JSON with Comments — strip line comments before parsing. Block comments
  // are not used in this file and are deliberately not handled, so a future
  // one fails loudly here rather than being silently mis-parsed.
  final stripped = file
      .readAsLinesSync()
      .map((l) => l.trimLeft().startsWith('//') ? '' : l)
      .join('\n');
  final root = jsonDecode(stripped) as Map<String, dynamic>;
  final models = <String>{};
  for (final config in (root['configurations'] as List? ?? const [])) {
    final args = (config as Map<String, dynamic>)['args'] as List? ?? const [];
    for (var i = 0; i < args.length - 1; i++) {
      if (args[i] == '--ollama-model') models.add(args[i + 1] as String);
    }
  }
  return models.toList()..sort();
}

/// Rows of the shape-coverage table in `ModelBehavior.md`, by model tag.
///
/// Returns `(coldStart, withHistory, warmPreSeed, total)`. Rows whose figures
/// are not all plain `n/25` are skipped rather than guessed at.
Map<String, (int, int, int, int)> shapeTableRows(String markdown) {
  final rows = <String, (int, int, int, int)>{};
  final cell = RegExp(r'^\*{0,2}(\d+)/(\d+)\*{0,2}$');
  for (final line in markdown.split('\n')) {
    if (!line.startsWith('| `')) continue;
    final cells = line.split('|').map((c) => c.trim()).toList();
    if (cells.length < 7) continue;
    final model = cells[1].replaceAll('`', '');
    final parsed = [
      for (final i in [3, 4, 5]) cell.firstMatch(cells[i]),
    ];
    if (parsed.any((m) => m == null)) continue;
    rows[model] = (
      int.parse(parsed[0]!.group(1)!),
      int.parse(parsed[1]!.group(1)!),
      int.parse(parsed[2]!.group(1)!),
      int.parse(parsed[0]!.group(2)!),
    );
  }
  return rows;
}

/// `probe` plus its variant, the way a result file is named.
String runLabel(ProbeRun run) =>
    '${run.probe}${run.variant == null ? '' : '-${run.variant}'}';

/// How many distinct cases a run actually exercised.
///
/// A `--only` run is a legitimate thing to record — re-checking one shape
/// without paying for the other twenty-four is exactly what that flag is for
/// — but its score is not the table's score, and comparing the two would fail
/// the build for someone doing the right thing. Runs that did not cover the
/// full set are reported and skipped rather than compared.
int distinctCases(ProbeRun run) =>
    run.calls.map((c) => c.caseId).toSet().length;

/// Recomputes a shape run's per-condition score from its own calls.
///
/// A case counts as passing only when every sample of it passed, which is
/// what the probe prints and what the tables quote.
int shapesFor(ProbeRun run, String condition) {
  final byCase = <String, bool>{};
  for (final c in run.calls.where((c) => c.condition == condition)) {
    byCase[c.caseId] = (byCase[c.caseId] ?? true) && c.pass;
  }
  return byCase.values.where((v) => v).length;
}

/// Runs every check and returns what it found.
List<Finding> check({
  required List<ProbeRun> results,
  required List<String> launched,
  required Map<String, String> currentAssets,
  required String markdown,
}) {
  final findings = <Finding>[];

  // 1. Each run must agree with its own calls. A probe whose printed summary
  //    disagrees with the calls it made is the one error a human reading the
  //    console could never catch.
  for (final run in results.where((r) => r.probe == 'shape_ab')) {
    for (final (key, condition) in [
      ('coldStart', 'cold'),
      ('withHistory', 'warm'),
    ]) {
      final claimed = run.summary[key] as int?;
      final actual = shapesFor(run, condition);
      if (claimed != null && claimed != actual) {
        findings.add(
          Finding(
            fatal: true,
            message:
                '${run.model} ${run.variant}: summary.$key says '
                '$claimed but its own calls give $actual',
          ),
        );
      }
    }
  }

  // 2. Recorded results must have been measured against the assets in the
  //    tree. Fatal for a launched model, because that is the set this file
  //    says is worth keeping working; reported for the rest, because
  //    re-running fourteen models on every prompt edit is not a gate anyone
  //    would keep.
  for (final run in results) {
    for (final entry in run.assets.entries) {
      final now = currentAssets[entry.key];
      if (now != null && now != entry.value) {
        final launchedModel = launched.contains(run.model);
        findings.add(
          Finding(
            fatal: launchedModel,
            message:
                '${run.model} ${runLabel(run)}: '
                'measured against ${entry.key} ${entry.value}, tree has $now — '
                're-run the probe, or accept the result as historical',
          ),
        );
      }
    }
  }

  // 3. The published tables must match the recorded runs.
  final rows = shapeTableRows(markdown);
  final seeded = {
    for (final r in results.where(
      (r) => r.probe == 'shape_ab' && r.variant == 'seeded',
    ))
      r.model: r,
  };
  final unaided = {
    for (final r in results.where(
      (r) => r.probe == 'shape_ab' && r.variant == 'unaided',
    ))
      r.model: r,
  };
  for (final model in seeded.keys) {
    final row = rows[model];
    if (row == null) {
      findings.add(
        Finding(
          fatal: true,
          message: '$model has shape results but no row in the table',
        ),
      );
      continue;
    }
    final (cold, warm, preSeed, total) = row;
    final s = seeded[model]!;
    if (distinctCases(s) != total) {
      findings.add(
        Finding(
          fatal: false,
          message:
              '$model: recorded shape run covers ${distinctCases(s)} of '
              '$total cases (a --only run), so the table was not checked '
              'against it',
        ),
      );
      continue;
    }
    if (cold != shapesFor(s, 'cold')) {
      findings.add(
        Finding(
          fatal: true,
          message:
              '$model: table says cold-start $cold/25, results give '
              '${shapesFor(s, 'cold')}/25',
        ),
      );
    }
    if (warm != shapesFor(s, 'warm')) {
      findings.add(
        Finding(
          fatal: true,
          message:
              '$model: table says with-history $warm/25, results give '
              '${shapesFor(s, 'warm')}/25',
        ),
      );
    }
    final u = unaided[model];
    if (u != null &&
        distinctCases(u) == total &&
        preSeed != shapesFor(u, 'warm')) {
      findings.add(
        Finding(
          fatal: true,
          message:
              '$model: table says warm pre-seed $preSeed/25, results give '
              '${shapesFor(u, 'warm')}/25',
        ),
      );
    }
  }

  // 4. Coverage. Not fatal — the matrix is filled in over time, and a gap is
  //    an invitation rather than a defect. It is reported so the gap has to
  //    be looked at rather than discovered by accident.
  for (final model in launched) {
    final have = {
      for (final r in results.where((r) => r.model == model))
        '${r.probe}${r.variant == null ? '' : '-${r.variant}'}',
    };
    final missing = expectedProbes.difference(have).toList()..sort();
    if (missing.isNotEmpty) {
      findings.add(
        Finding(
          fatal: false,
          message:
              '$model is launched by launch.json but has no recorded '
              'result for: ${missing.join(', ')}',
        ),
      );
    }
  }

  return findings;
}

Future<void> main(List<String> argv) async {
  final root = Directory.current.path;
  final results = readAllResults(
    p.join(root, 'tool', 'model_probes', 'results'),
  );
  final launched = launchedModels(p.join(root, '..', '.vscode', 'launch.json'));
  final currentAssets = currentAssetDigests(p.join(root, 'assets'));
  final markdown = File(p.join(root, 'ModelBehavior.md')).readAsStringSync();

  stdout.writeln(
    'check_results: ${results.length} recorded run(s), '
    '${launched.length} model(s) in launch.json',
  );

  final findings = check(
    results: results,
    launched: launched,
    currentAssets: currentAssets,
    markdown: markdown,
  );

  for (final f in findings) {
    stdout.writeln('${f.fatal ? "FAIL" : "note"}  ${f.message}');
  }

  final fatal = findings.where((f) => f.fatal).length;
  if (fatal == 0) {
    stdout.writeln(
      'OK — every recorded run agrees with itself, with the assets in the '
      'tree, and with the tables in ModelBehavior.md.',
    );
    return;
  }
  stdout.writeln('\n$fatal fatal finding(s).');
  exitCode = 1;
}
