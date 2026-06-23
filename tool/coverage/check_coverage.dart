// Self-contained line-coverage gate for the Flutter-AdaptiveCards workspace.
//
// Reads per-package floors from tool/coverage_floors.yaml and compares each
// package's measured line coverage (from packages/<name>/coverage/lcov.info)
// against its floor. Prints a table and exits non-zero when any package is
// below its floor or is missing its lcov report.
//
// Usage (from the repo root):
//   dart run tool/coverage/check_coverage.dart              # enforcing
//   dart run tool/coverage/check_coverage.dart --report-only # never fails
//   dart run tool/coverage/check_coverage.dart --self-test   # verify the parsers
//
// Dependency-free on purpose (pure dart:io) so it runs from the workspace root
// without adding packages to the root pubspec. The floors file is a flat
// `name: <int>` map; see tool/coverage_floors.yaml.

import 'dart:io';

const String _floorsPath = 'tool/coverage_floors.yaml';

void main(List<String> args) {
  if (args.contains('--self-test')) {
    _selfTest();
    return;
  }
  final reportOnly = args.contains('--report-only');

  final floorsFile = File(_floorsPath);
  if (!floorsFile.existsSync()) {
    stderr.writeln('Floors file not found: $_floorsPath (run from repo root).');
    exitCode = 1;
    return;
  }

  final floors = parseFloors(floorsFile.readAsStringSync());
  if (floors.isEmpty) {
    stderr.writeln('No floors defined in $_floorsPath.');
    exitCode = 1;
    return;
  }

  final rows = <_Row>[];
  for (final entry in floors.entries) {
    final lcovPath = 'packages/${entry.key}/coverage/lcov.info';
    final lcov = File(lcovPath);
    if (!lcov.existsSync()) {
      rows.add(_Row(entry.key, null, 0, 0, entry.value,
          missingReason: 'missing $lcovPath'));
      continue;
    }
    final stats = lineCoverage(lcov.readAsStringSync());
    rows.add(_Row(entry.key, stats.percent, stats.hit, stats.found,
        entry.value));
  }

  _printTable(rows);

  final failures = rows.where((r) => !r.passes).toList();
  if (failures.isEmpty) {
    stdout.writeln('\nCoverage gate: PASS');
    return;
  }

  for (final r in failures) {
    stdout.writeln(
        'Coverage gate: ${r.package} ${r.missingReason ?? 'below floor '
            '(${r.percent!.toStringAsFixed(1)}% < ${r.floor}%)'}');
  }
  if (reportOnly) {
    stdout.writeln('\nCoverage gate: REPORT-ONLY (not failing the build)');
    return;
  }
  stdout.writeln('\nCoverage gate: FAIL');
  exitCode = 1;
}

/// Parses a flat `name: <int>` map. Lines that are blank or start with `#`
/// (after trimming) are ignored. Inline `#` comments are stripped.
Map<String, int> parseFloors(String content) {
  final result = <String, int>{};
  for (final raw in content.split('\n')) {
    var line = raw;
    final hash = line.indexOf('#');
    if (hash >= 0) line = line.substring(0, hash);
    line = line.trim();
    if (line.isEmpty) continue;
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final key = line.substring(0, colon).trim();
    final value = int.tryParse(line.substring(colon + 1).trim());
    if (key.isEmpty || value == null) continue;
    result[key] = value;
  }
  return result;
}

/// Sums `LF:` (lines found) and `LH:` (lines hit) records across an lcov report.
LineStats lineCoverage(String lcov) {
  var found = 0;
  var hit = 0;
  for (final raw in lcov.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('LF:')) {
      found += int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      hit += int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }
  final percent = found == 0 ? 100.0 : hit / found * 100;
  return LineStats(found: found, hit: hit, percent: percent);
}

/// Line-coverage totals for a single lcov report.
class LineStats {
  LineStats({required this.found, required this.hit, required this.percent});

  final int found;
  final int hit;
  final double percent;
}

class _Row {
  _Row(this.package, this.percent, this.hit, this.found, this.floor,
      {this.missingReason});

  final String package;
  final double? percent;
  final int hit;
  final int found;
  final int floor;
  final String? missingReason;

  bool get passes => missingReason == null && percent! >= floor;
}

void _printTable(List<_Row> rows) {
  final nameWidth = rows
      .map((r) => r.package.length)
      .fold<int>('Package'.length, (a, b) => a > b ? a : b);
  String pad(String s, int w) => s.padRight(w);

  stdout.writeln('${pad('Package', nameWidth)}  '
      '${'Cov%'.padLeft(6)}  ${'Hit/Found'.padLeft(12)}  '
      '${'Floor'.padLeft(5)}  Status');
  for (final r in rows) {
    final cov = r.percent == null ? '  n/a' : r.percent!.toStringAsFixed(1);
    final hitFound = r.missingReason ?? '${r.hit}/${r.found}';
    final status = r.passes ? 'PASS' : 'FAIL';
    stdout.writeln('${pad(r.package, nameWidth)}  '
        '${cov.padLeft(6)}  ${hitFound.padLeft(12)}  '
        '${'${r.floor}%'.padLeft(5)}  $status');
  }
}

// ---------------------------------------------------------------------------
// Built-in verification (dependency-free; runs without the test package).
// ---------------------------------------------------------------------------

void _selfTest() {
  var failures = 0;
  void check(bool ok, String label) {
    if (ok) {
      stdout.writeln('ok   - $label');
    } else {
      stdout.writeln('FAIL - $label');
      failures++;
    }
  }

  final floors = parseFloors('''
# comment line
flutter_adaptive_cards_fs: 85   # inline comment
flutter_adaptive_charts_fs: 71

not-a-pair
''');
  check(floors.length == 2, 'parseFloors keeps two valid pairs');
  check(floors['flutter_adaptive_cards_fs'] == 85, 'parseFloors reads value');
  check(floors['flutter_adaptive_charts_fs'] == 71, 'parseFloors strips inline comment');

  final stats = lineCoverage('''
SF:lib/a.dart
LF:10
LH:8
end_of_record
SF:lib/b.dart
LF:10
LH:2
end_of_record
''');
  check(stats.found == 20 && stats.hit == 10, 'lineCoverage sums LF/LH');
  check((stats.percent - 50.0).abs() < 1e-9, 'lineCoverage computes percent');

  final empty = lineCoverage('SF:lib/a.dart\nend_of_record\n');
  check(empty.percent == 100.0, 'lineCoverage treats zero lines as 100%');

  if (failures == 0) {
    stdout.writeln('\nself-test: PASS');
  } else {
    stdout.writeln('\nself-test: FAIL ($failures)');
    exitCode = 1;
  }
}
