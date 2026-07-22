// Self-contained pub-score (pana) gate for the Flutter-AdaptiveCards workspace.
//
// Runs pana over each published package listed in tool/pana_floors.yaml and
// compares the granted points against that package's floor. Prints a table and
// exits non-zero when any package is below its floor.
//
// Usage (from the repo root):
//   fvm dart run tool/pana/check_pana.dart                 # enforcing
//   fvm dart run tool/pana/check_pana.dart --report-only   # never fails
//   fvm dart run tool/pana/check_pana.dart --self-test     # verify the parsers
//   fvm dart run tool/pana/check_pana.dart --only flutter_adaptive_cards_fs
//
// Dependency-free on purpose (dart:io + dart:convert) so it runs from the
// workspace root without adding packages to the root pubspec, which is a
// workspace manifest and not a real package.
//
// pana is invoked as `<the dart running this script> pub global run pana`, so it
// always uses the pinned SDK -- fvm's Dart locally, flutter-action's Dart in CI.
// pana derives the Flutter SDK from the Dart SDK path, so no --flutter-sdk or
// --dart-sdk flags are needed.
//
// --no-dartdoc is always passed, so the maximum score is 150, not 160.

import 'dart:convert';
import 'dart:io';

// ignore: unused_element
const String _floorsPath = 'tool/pana_floors.yaml';

void main(List<String> args) {
  if (args.contains('--self-test')) {
    _selfTest();
    return;
  }
  stderr.writeln('not implemented yet');
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

/// Returns [raw] from its first `{` onward, so log noise emitted before the
/// JSON body does not break decoding.
String isolateJson(String raw) {
  final start = raw.indexOf('{');
  if (start <= 0) return raw;
  return raw.substring(start);
}

/// Sums the per-section points of a pana `--json` report.
PanaScore parsePanaJson(String jsonText) {
  final decoded = jsonDecode(isolateJson(jsonText));
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('pana JSON root is not an object');
  }
  final report = decoded['report'];
  if (report is! Map<String, dynamic>) {
    throw const FormatException('pana JSON has no "report" object');
  }
  final sections = report['sections'];
  if (sections is! List) {
    throw const FormatException('pana report has no "sections" list');
  }
  var granted = 0;
  var max = 0;
  final failed = <String>[];
  for (final section in sections) {
    if (section is! Map<String, dynamic>) continue;
    final points = section['grantedPoints'];
    final maxPoints = section['maxPoints'];
    if (points is int) granted += points;
    if (maxPoints is int) max += maxPoints;
    if (section['status'] != 'passed') {
      failed.add('${section['id']} ${points ?? '?'}/${maxPoints ?? '?'}');
    }
  }
  return PanaScore(granted: granted, max: max, failedSections: failed);
}

/// Aggregate pana result for one package.
class PanaScore {
  PanaScore({
    required this.granted,
    required this.max,
    required this.failedSections,
  });

  /// Points pana awarded across all report sections.
  final int granted;

  /// Points available across all report sections (150 with `--no-dartdoc`).
  final int max;

  /// Human-readable `id points/max` for each section that did not pass.
  final List<String> failedSections;
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
flutter_adaptive_cards_fs: 140   # inline comment
flutter_adaptive_template_fs: 140

not-a-pair
''');
  check(floors.length == 2, 'parseFloors keeps two valid pairs');
  check(floors['flutter_adaptive_cards_fs'] == 140, 'parseFloors reads value');
  check(
    floors['flutter_adaptive_template_fs'] == 140,
    'parseFloors strips inline comment',
  );

  check(isolateJson('{"a":1}') == '{"a":1}', 'isolateJson passes clean JSON');
  check(
    isolateJson('MSG : noise\n{"a":1}') == '{"a":1}',
    'isolateJson drops leading log noise',
  );

  const sampleReport = '''
{
  "packageName": "flutter_adaptive_cards_fs",
  "report": {
    "sections": [
      {"id": "convention", "grantedPoints": 30, "maxPoints": 30, "status": "passed"},
      {"id": "documentation", "grantedPoints": 0, "maxPoints": 10, "status": "failed"},
      {"id": "platform", "grantedPoints": 20, "maxPoints": 20, "status": "passed"},
      {"id": "analysis", "grantedPoints": 40, "maxPoints": 50, "status": "partial"},
      {"id": "dependency", "grantedPoints": 40, "maxPoints": 40, "status": "passed"}
    ]
  }
}
''';
  final score = parsePanaJson(sampleReport);
  check(score.granted == 130, 'parsePanaJson sums grantedPoints');
  check(score.max == 150, 'parsePanaJson sums maxPoints');
  check(
    score.failedSections.length == 2,
    'parsePanaJson collects non-passed sections',
  );
  check(
    score.failedSections.first == 'documentation 0/10',
    'parsePanaJson labels a failed section',
  );

  var threw = false;
  try {
    parsePanaJson('{"packageName": "x"}');
  } on FormatException {
    threw = true;
  }
  check(threw, 'parsePanaJson throws FormatException without a report');

  if (failures == 0) {
    stdout.writeln('\nself-test: PASS');
  } else {
    stdout.writeln('\nself-test: FAIL ($failures)');
    exitCode = 1;
  }
}
