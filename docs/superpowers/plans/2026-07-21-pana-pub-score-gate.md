# pana Pub-Score Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Score the four published packages with `pana` (the pub.dev scoring tool) on every PR via a report-only ratchet gate, and make the same check runnable from VS Code with one command.

**Architecture:** Mirror the existing coverage gate exactly. A dependency-free Dart script (`tool/pana/check_pana.dart`) shells out to `pana --json --no-dartdoc` once per published package, sums `report.sections[].grantedPoints`, and compares each total against a per-package floor in `tool/pana_floors.yaml`. It prints a table and honours `--report-only`, just like `tool/coverage/check_coverage.dart`. A new `pana` job in `.github/workflows/validate.yaml` runs it on PRs; `.vscode/tasks.json` exposes it locally.

**Tech Stack:** Dart (`dart:io` + `dart:convert`, no packages), `pana` 0.23.14 activated via `dart pub global activate`, GitHub Actions (`subosito/flutter-action@v2`), VS Code tasks.

## Background: the constraint that shapes this plan

All four packages measured directly with pana 0.23.14 on 2026-07-21. Every
number below is observed, not estimated:

| Package                          | Score (`--no-dartdoc`, max 150) | Gap                                     |
| -------------------------------- | ------------------------------- | --------------------------------------- |
| `flutter_adaptive_cards_fs`      | 140                             | −10 no `example/`                       |
| `flutter_adaptive_template_fs`   | 140                             | −10 no `example/`                       |
| `flutter_adaptive_charts_fs`     | 40                              | dependency resolution fails — see below |
| `flutter_adaptive_cards_host_fs` | 40                              | dependency resolution fails — see below |

`flutter_adaptive_cards_fs` measured **130** on the first pass, losing 10
static-analysis points to a single unformatted file
(`lib/src/cards/adaptive_card_element.dart`, one needlessly-wrapped line). That
was fixed before this plan was finalized, which is why the table reads 140.
Two things about that are worth carrying forward, because they will recur:

- **`fvm flutter analyze` does not catch it.** Formatting is not a lint, so the
  workspace can be analyze-clean and still drop 10 pana points. Nothing in CI
  caught it either, which is why **Task 6** adds a dedicated `dart-format` job.
- **pana only inspects `lib/`.** Three drifted files under `test/` cost nothing.
  Do not infer from a passing pana score that the package is `dart format`-clean
  — that is the other half of why Task 6 checks `packages/` and `tool/` whole.

**pana resolves each package as if it were already published.** It copies the
package to a temp directory, ignores the pub workspace, and strips
`pubspec_overrides.yaml` (the override workaround was tested and does not work).
So `flutter_adaptive_charts_fs` and `flutter_adaptive_cards_host_fs`, which both
declare `flutter_adaptive_cards_fs: ^0.15.0`, fail version solving for the whole
development cycle because 0.15.0 is not on pub.dev yet:

```text
Because flutter_adaptive_cards_host_fs depends on flutter_adaptive_cards_fs ^0.15.0
which doesn't match any versions, version solving failed.
```

This is pana being correct, not a bug to fix. Those two packages are only
meaningfully scoreable **after** the core package is published at the matching
version. The plan handles this by giving them low ratchet floors (40) plus a
comment, so the gate still catches a regression below today's baseline without
turning permanently red, and by adding a release-time step to the
`adaptive-cards-release-engineer` skill.

## Global Constraints

- Prefix every local `flutter`/`dart` command with `fvm`. CI uses bare `flutter`/`dart` (matching `.github/workflows/test.yml`).
- `tool/pana/check_pana.dart` must be **dependency-free** — `dart:io` and `dart:convert` only. The root `pubspec.yaml` is a workspace manifest (`name: _`) and must not gain dependencies.
- pana is invoked as `Platform.resolvedExecutable pub global run pana`, so it always uses the same SDK running the script. Do **not** pass `--flutter-sdk` / `--dart-sdk`; pana derives the Flutter SDK from the Dart SDK path, which is correct under both fvm and `subosito/flutter-action`.
- Always pass `--no-dartdoc`. Per the design decision, dartdoc coverage (10 of 160 points) is never scored in CI; the effective maximum is **150**.
- `flutter_adaptive_cards_test_support` is `publish_to: none` and must **not** be scored, same as its omission from `tool/coverage_floors.yaml`.
- The script must never be pointed at the repo root. Bare `pana` in the root scores the `_` workspace manifest and reports a meaningless 135/160.
- No file under `packages/<name>/` changes in this plan, so **no package `CHANGELOG.md` entry is required** by the AGENTS.md changelog rule.
- `docs/pub-score-pana.md` is inside the Prettier-checked scope (`docs/**/*.md`); `docs/superpowers/**` is not. Run `npm run format:md` after writing it.
- Work happens on branch `feat/pana-pub-score-gate`. All commands run from the repo root unless stated.

---

## File Structure

- `tool/pana_floors.yaml` — CREATE. Flat `package_name: <int points>` ratchet map. Same format and parser as `tool/coverage_floors.yaml`, so one parser serves both.
- `tool/pana/check_pana.dart` — CREATE. The whole gate: floors parsing, pana invocation, JSON summing, table printing, exit code, and a `--self-test` mode. Single file on purpose — it mirrors `tool/coverage/check_coverage.dart`, which is also self-contained and self-testing.
- `.github/workflows/validate.yaml` — MODIFY, twice. Task 3 adds the `pana` job alongside the existing `markdown-format` job; Task 6 adds an independent `dart-format` job, because nothing in the repo currently enforces Dart formatting.
- `.vscode/tasks.json` — MODIFY. Add an activation task and two run tasks.
- `.vscode/extensions.json` — MODIFY. Add the Dart/Flutter extension recommendations.
- `scripts/setup-workspace.sh` / `scripts/setup-workspace.ps1` — MODIFY. Activate pana as part of workspace bootstrap.
- `docs/pub-score-pana.md` — CREATE. The reference page, sibling to `docs/testing-coverage.md`.
- `.claude/skills/adaptive-cards-release-engineer/SKILL.md` — MODIFY. Add the "re-score charts/host after core publishes" step.

Testing note: this script has no `package:test` harness available at the
workspace root (the root is not a real package). `tool/coverage/check_coverage.dart`
solves this with a built-in `--self-test` that exercises its pure functions with
hand-written inputs. This plan follows the identical pattern — the `--self-test`
is the test suite, and it runs in CI.

---

### Task 1: Floors file and pure parsers, verified by `--self-test`

**Files:**

- Create: `tool/pana_floors.yaml`
- Create: `tool/pana/check_pana.dart`
- Test: the `--self-test` mode inside `tool/pana/check_pana.dart`

**Interfaces:**

- Produces: `Map<String, int> parseFloors(String content)` — parses a flat `name: <int>` map, ignoring blank lines, `#` comment lines, and inline `#` comments.
- Produces: `String isolateJson(String raw)` — returns the substring starting at the first `{`, so stray log lines before the JSON body do not break decoding.
- Produces: `PanaScore parsePanaJson(String jsonText)` — sums `report.sections[].grantedPoints` / `.maxPoints` and collects the ids of non-`passed` sections. Throws `FormatException` on a malformed report.
- Produces: `class PanaScore { final int granted; final int max; final List<String> failedSections; }`

- [ ] **Step 1: Create the floors file**

Create `tool/pana_floors.yaml`:

```yaml
# Per-package minimum pana points, enforced by tool/pana/check_pana.dart.
#
# Ratchet floors: each value is a lower bound the CI pub-score gate will not let a
# package drop below. Raise a floor (in its own commit) after you land a change that
# lifts a package's score -- never lower one to make a red build pass.
#
# Format: a flat `package_name: <int points>` map. Comments start with '#'.
#
# Values are measured with `--no-dartdoc`, so the maximum is 150, not pana's usual
# 160 -- the 10 dartdoc-coverage points are never scored in CI. See docs/pub-score-pana.md.
#
# flutter_adaptive_cards_test_support is intentionally omitted: it is publish_to: none.
#
# flutter_adaptive_charts_fs and flutter_adaptive_cards_host_fs have LOW floors on
# purpose. pana resolves every package as if already published, so their dependency
# on `flutter_adaptive_cards_fs: ^<unreleased version>` fails version solving for the
# whole development cycle and costs them 110 points. Their score only becomes
# meaningful right after the core package is published at the matching version --
# see docs/pub-score-pana.md and the adaptive-cards-release-engineer skill.

flutter_adaptive_cards_fs: 140
flutter_adaptive_template_fs: 140
flutter_adaptive_charts_fs: 40
flutter_adaptive_cards_host_fs: 40
```

- [ ] **Step 2: Write the failing self-test**

Create `tool/pana/check_pana.dart` with the self-test and stub declarations only —
the pure functions come in Step 4, so this compiles-and-fails first:

```dart
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
  throw UnimplementedError();
}

/// Returns [raw] from its first `{` onward, so log noise emitted before the
/// JSON body does not break decoding.
String isolateJson(String raw) {
  throw UnimplementedError();
}

/// Sums the per-section points of a pana `--json` report.
PanaScore parsePanaJson(String jsonText) {
  throw UnimplementedError();
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
```

- [ ] **Step 3: Run the self-test to verify it fails**

```bash
fvm dart run tool/pana/check_pana.dart --self-test
```

Expected: an unhandled `UnimplementedError` thrown from `parseFloors`, non-zero exit.

- [ ] **Step 4: Implement the three pure functions**

Replace the three `throw UnimplementedError();` bodies in `tool/pana/check_pana.dart`:

```dart
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
```

- [ ] **Step 5: Run the self-test to verify it passes**

```bash
fvm dart run tool/pana/check_pana.dart --self-test
```

Expected: ten `ok   - ...` lines followed by `self-test: PASS`, exit 0.

- [ ] **Step 6: Format and analyze**

```bash
fvm dart format tool/pana/check_pana.dart
fvm flutter analyze
```

Expected: `dart format` reports the file formatted (or unchanged); `flutter analyze` reports `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add tool/pana_floors.yaml tool/pana/check_pana.dart
git commit -m "feat(tool): add pana pub-score gate parsers and floors file"
```

---

### Task 2: Run pana per package and gate on the floors

**Files:**

- Modify: `tool/pana/check_pana.dart` (replace the `main` stub; add the runner and table printer)
- Test: `--self-test` (unchanged, must still pass) plus a real end-to-end run

**Interfaces:**

- Consumes: `parseFloors`, `parsePanaJson`, `PanaScore` from Task 1.
- Produces: CLI contract — `--report-only` never sets a non-zero exit code; `--self-test` runs the parser checks and exits; `--only <package>` scores just one package; no flags means enforcing.

- [ ] **Step 1: Replace `main` and add the runner**

In `tool/pana/check_pana.dart`, replace the whole `void main(List<String> args) { ... }`
stub with the following, and add the two helpers plus the `_Row` class immediately
after it (before the `parseFloors` declaration):

```dart
Future<void> main(List<String> args) async {
  if (args.contains('--self-test')) {
    _selfTest();
    return;
  }
  final reportOnly = args.contains('--report-only');

  final onlyIndex = args.indexOf('--only');
  final only = onlyIndex >= 0 && onlyIndex + 1 < args.length
      ? args[onlyIndex + 1]
      : null;

  final floorsFile = File(_floorsPath);
  if (!floorsFile.existsSync()) {
    stderr.writeln('Floors file not found: $_floorsPath (run from repo root).');
    exitCode = 1;
    return;
  }

  var floors = parseFloors(floorsFile.readAsStringSync());
  if (only != null) {
    floors = {
      for (final e in floors.entries)
        if (e.key == only) e.key: e.value,
    };
    if (floors.isEmpty) {
      stderr.writeln('Unknown package "$only". Known: '
          '${parseFloors(floorsFile.readAsStringSync()).keys.join(', ')}');
      exitCode = 1;
      return;
    }
  }
  if (floors.isEmpty) {
    stderr.writeln('No floors defined in $_floorsPath.');
    exitCode = 1;
    return;
  }

  final rows = <_Row>[];
  for (final entry in floors.entries) {
    final dir = 'packages/${entry.key}';
    if (!Directory(dir).existsSync()) {
      rows.add(_Row(entry.key, null, entry.value,
          missingReason: 'missing $dir'));
      continue;
    }
    stdout.writeln('Running pana on $dir ...');
    final result = await _runPana(dir);
    final stdoutText = result.stdout as String;
    if (stdoutText.trim().isEmpty) {
      final stderrText = (result.stderr as String).trim();
      final hint = stderrText.contains('No active package pana')
          ? 'pana not activated - run: dart pub global activate pana'
          : 'pana produced no JSON (exit ${result.exitCode})';
      rows.add(_Row(entry.key, null, entry.value, missingReason: hint));
      continue;
    }
    try {
      rows.add(_Row(entry.key, parsePanaJson(stdoutText), entry.value));
    } on FormatException catch (e) {
      rows.add(_Row(entry.key, null, entry.value,
          missingReason: 'unparseable pana JSON: ${e.message}'));
    }
  }

  _printTable(rows);

  for (final r in rows) {
    final failed = r.score?.failedSections ?? const <String>[];
    if (failed.isNotEmpty) {
      stdout.writeln('  ${r.package}: lost points in ${failed.join(', ')}');
    }
  }

  final failures = rows.where((r) => !r.passes).toList();
  if (failures.isEmpty) {
    stdout.writeln('\nPub-score gate: PASS');
    return;
  }

  for (final r in failures) {
    stdout.writeln('Pub-score gate: ${r.package} '
        '${r.missingReason ?? 'below floor '
            '(${r.score!.granted} < ${r.floor})'}');
  }
  if (reportOnly) {
    stdout.writeln('\nPub-score gate: REPORT-ONLY (not failing the build)');
    return;
  }
  stdout.writeln('\nPub-score gate: FAIL');
  exitCode = 1;
}

/// Runs pana on [packageDir] with the same Dart SDK that runs this script.
///
/// `--no-dartdoc` keeps the run fast; it drops the 10 dartdoc-coverage points,
/// so the maximum becomes 150.
Future<ProcessResult> _runPana(String packageDir) {
  return Process.run(
    Platform.resolvedExecutable,
    ['pub', 'global', 'run', 'pana', '--json', '--no-dartdoc', packageDir],
  );
}

class _Row {
  _Row(this.package, this.score, this.floor, {this.missingReason});

  final String package;
  final PanaScore? score;
  final int floor;
  final String? missingReason;

  bool get passes => missingReason == null && score!.granted >= floor;
}

void _printTable(List<_Row> rows) {
  final nameWidth = rows
      .map((r) => r.package.length)
      .fold<int>('Package'.length, (a, b) => a > b ? a : b);
  String pad(String s, int w) => s.padRight(w);

  stdout.writeln('\n${pad('Package', nameWidth)}  '
      '${'Points'.padLeft(6)}  ${'Max'.padLeft(5)}  '
      '${'Floor'.padLeft(5)}  Status');
  for (final r in rows) {
    final points = r.score == null ? 'n/a' : '${r.score!.granted}';
    final max = r.score == null ? 'n/a' : '${r.score!.max}';
    final status = r.passes ? 'PASS' : 'FAIL';
    stdout.writeln('${pad(r.package, nameWidth)}  '
        '${points.padLeft(6)}  ${max.padLeft(5)}  '
        '${'${r.floor}'.padLeft(5)}  $status');
    if (r.missingReason != null) {
      stdout.writeln('${pad('', nameWidth)}  ${r.missingReason}');
    }
  }
}
```

- [ ] **Step 2: Re-run the self-test**

```bash
fvm dart run tool/pana/check_pana.dart --self-test
```

Expected: `self-test: PASS`, exit 0. (Adding `main` logic must not break the parsers.)

- [ ] **Step 3: Verify the "pana not activated" path**

```bash
fvm dart pub global deactivate pana 2>/dev/null || true
fvm dart run tool/pana/check_pana.dart --only flutter_adaptive_template_fs --report-only
```

Expected: the table shows `n/a` points with the hint
`pana not activated - run: dart pub global activate pana`, and the run ends with
`Pub-score gate: REPORT-ONLY (not failing the build)`, exit 0.

- [ ] **Step 4: Activate pana and run one package for real**

```bash
fvm dart pub global activate pana 0.23.14
fvm dart run tool/pana/check_pana.dart --only flutter_adaptive_template_fs
```

Expected: roughly 1–2 minutes, then a table row
`flutter_adaptive_template_fs  140  150  140  PASS`, a `lost points in documentation 0/10`
line, and `Pub-score gate: PASS`, exit 0.

- [ ] **Step 5: Run the full set**

```bash
fvm dart run tool/pana/check_pana.dart --report-only
```

Expected: roughly 5–8 minutes; four rows, each exactly at its floor and `PASS`:

```text
flutter_adaptive_cards_fs        140    150    140  PASS
flutter_adaptive_template_fs     140    150    140  PASS
flutter_adaptive_charts_fs        40    150     40  PASS
flutter_adaptive_cards_host_fs    40    150     40  PASS
```

All four floors are measured values, so **no reconciliation is needed** — do not
adjust a floor to make this run green. If a package comes in below its floor,
that is a real regression to report, not a number to lower. If one comes in
_above_ its floor, that is a genuine improvement: raise the floor in its own
commit so the gain is locked in.

- [ ] **Step 6: Verify the enforcing path fails on a floor breach**

```bash
sed -i '' 's/^flutter_adaptive_template_fs: .*/flutter_adaptive_template_fs: 150/' tool/pana_floors.yaml
fvm dart run tool/pana/check_pana.dart --only flutter_adaptive_template_fs; echo "exit=$?"
git checkout tool/pana_floors.yaml
```

Expected: `flutter_adaptive_template_fs 140 150 150 FAIL`, then
`Pub-score gate: FAIL` and `exit=1`. The `git checkout` restores the real floor.

- [ ] **Step 7: Format, analyze, commit**

```bash
fvm dart format tool/pana/check_pana.dart
fvm flutter analyze
git add tool/pana/check_pana.dart tool/pana_floors.yaml
git commit -m "feat(tool): run pana per package and gate on ratchet floors"
```

Expected: `No issues found!` from analyze before committing.

---

### Task 3: CI job in the validate workflow

**Files:**

- Modify: `.github/workflows/validate.yaml` (append a second job after `markdown-format`)

**Interfaces:**

- Consumes: `tool/pana/check_pana.dart` and `tool/pana_floors.yaml` from Tasks 1–2.
- Produces: a `pana` job named "Pub score (pana)" on the same `push: [main]` + `pull_request` triggers the workflow already declares.

- [ ] **Step 1: Update the workflow header comment**

In `.github/workflows/validate.yaml`, replace the first line:

```yaml
# Validates that the published Markdown docs are Prettier-formatted.
```

with:

```yaml
# Repo-wide validation checks that are not the test suite:
#   - markdown-format: the published Markdown docs are Prettier-formatted.
#   - pana: the four published packages meet their pub.dev score floors.
```

- [ ] **Step 2: Append the pana job**

Add to the end of `.github/workflows/validate.yaml`, at the same indentation as
the existing `markdown-format:` job key:

```yaml
pana:
  name: Pub score (pana)
  runs-on: ubuntu-24.04
  timeout-minutes: 25

  steps:
    - name: Checkout repository
      uses: actions/checkout@v6

    - uses: subosito/flutter-action@v2
      with:
        channel: "stable"
        flutter-version: 3.44.0 # should sync with fvm version
        cache: true

    - run: flutter pub get

    # Pinned so the score is reproducible. Bump deliberately, in its own
    # commit, and re-measure tool/pana_floors.yaml when you do -- a new pana
    # release can change how points are awarded.
    - name: Activate pana
      run: dart pub global activate pana 0.23.14

    - name: Verify the gate's own parsers
      run: dart run tool/pana/check_pana.dart --self-test

    # Report-only for now (prints the table, never fails the build) while the
    # CI plumbing is validated -- same rollout the coverage gate used. Drop
    # --report-only to make it enforcing. See docs/pub-score-pana.md.
    - name: Pub-score gate (report-only)
      run: dart run tool/pana/check_pana.dart --report-only
```

- [ ] **Step 3: Verify the workflow parses**

```bash
python3 -c "import yaml,sys; d=yaml.safe_load(open('.github/workflows/validate.yaml')); print(sorted(d['jobs'].keys()))"
```

Expected: `['markdown-format', 'pana']`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/validate.yaml
git commit -m "ci: add report-only pana pub-score job to validate workflow"
```

- [ ] **Step 5: Confirm the job runs green on the PR**

Push the branch and open a PR, then watch the run. Expected: the "Pub score (pana)"
job succeeds, its log contains the four-row table, and it ends with
`Pub-score gate: REPORT-ONLY (not failing the build)`. If the job cannot find
pana, confirm `dart pub global activate pana 0.23.14` ran before the gate step.

---

### Task 4: VS Code integration

**Files:**

- Modify: `.vscode/tasks.json`
- Modify: `.vscode/extensions.json`
- Modify: `scripts/setup-workspace.sh`
- Modify: `scripts/setup-workspace.ps1`

**Interfaces:**

- Consumes: `tool/pana/check_pana.dart` `--report-only` and `--only <package>` from Task 2.
- Produces: three VS Code tasks — `Setup pana`, `pana: all packages`, `pana: one package`.

Note: there is no pana VS Code extension, and the Dart-Code extension does not
integrate pana. "Available in VS Code" therefore means a bootstrap step plus
Run Task entries.

- [ ] **Step 1: Add the tasks**

In `.vscode/tasks.json`, add these three entries to the `tasks` array, after the
existing `Setup Adaptive Chat Server venv` entry:

```json
    {
      "label": "Setup pana",
      "detail": "Activates the pinned pana CLI used by the pub-score gate.",
      "type": "shell",
      "command": "fvm dart pub global activate pana 0.23.14",
      "presentation": {
        "reveal": "silent",
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "pana: all packages",
      "detail": "Scores all four published packages and prints the table (never fails).",
      "type": "shell",
      "command": "fvm dart run tool/pana/check_pana.dart --report-only",
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      },
      "problemMatcher": []
    },
    {
      "label": "pana: one package",
      "detail": "Scores a single published package.",
      "type": "shell",
      "command": "fvm dart run tool/pana/check_pana.dart --only ${input:panaPackage}",
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      },
      "problemMatcher": []
    }
```

Then add a sibling `inputs` array to the top-level object, after the `tasks` array:

```json
  "inputs": [
    {
      "id": "panaPackage",
      "type": "pickString",
      "description": "Which published package should pana score?",
      "options": [
        "flutter_adaptive_cards_fs",
        "flutter_adaptive_template_fs",
        "flutter_adaptive_charts_fs",
        "flutter_adaptive_cards_host_fs"
      ],
      "default": "flutter_adaptive_cards_fs"
    }
  ]
```

The picker deliberately lists only the four published packages — it is the guard
against pointing pana at the repo root or at `flutter_adaptive_cards_test_support`.

- [ ] **Step 2: Verify the tasks file is valid JSON**

```bash
python3 -c "import json; d=json.load(open('.vscode/tasks.json')); print([t['label'] for t in d['tasks']]); print(d['inputs'][0]['options'])"
```

Expected: the five task labels including the three new ones, then the four package names.

- [ ] **Step 3: Recommend the Dart and Flutter extensions**

Replace the contents of `.vscode/extensions.json` with:

```json
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "Dart-Code.dart-code",
    "Dart-Code.flutter"
  ]
}
```

- [ ] **Step 4: Activate pana during workspace bootstrap**

Append to `scripts/setup-workspace.sh`:

```sh
echo "setup-workspace: activating pana (pub-score gate)"
fvm dart pub global activate pana 0.23.14
```

Then make the same addition to `scripts/setup-workspace.ps1`, matching that
file's existing style. Read the file first and mirror its echo/error idiom
rather than pasting shell syntax into it.

- [ ] **Step 5: Verify the shell script still runs**

```bash
sh scripts/setup-workspace.sh
```

Expected: the existing fvm install output, then
`setup-workspace: activating pana (pub-score gate)` and pana activating (or
reporting it is already activated at 0.23.14), exit 0.

- [ ] **Step 6: Run the task from VS Code**

Open the Command Palette, run **Tasks: Run Task** → **pana: one package** →
`flutter_adaptive_template_fs`. Expected: a dedicated terminal showing the table
row `flutter_adaptive_template_fs 140 150 140 PASS`.

- [ ] **Step 7: Commit**

```bash
git add .vscode/tasks.json .vscode/extensions.json scripts/setup-workspace.sh scripts/setup-workspace.ps1
git commit -m "chore(vscode): add pana tasks, package picker, and bootstrap activation"
```

---

### Task 5: Documentation and the release-time step

**Files:**

- Create: `docs/pub-score-pana.md`
- Modify: `.claude/skills/adaptive-cards-release-engineer/SKILL.md`

**Interfaces:**

- Consumes: everything from Tasks 1–4.
- Produces: the canonical reference page the floors file, the workflow comments, and the release skill all point at.

- [ ] **Step 1: Write the reference page**

Create `docs/pub-score-pana.md`:

````markdown
# Pub score gate (pana)

CI scores each **published** package with [`pana`](https://pub.dev/packages/pana),
the same tool pub.dev uses, and enforces a **ratchet floor** per package so the
score cannot silently regress. This page documents how the gate works, why two
packages have deliberately low floors, and how to update it.

## How the score is measured (CI == local)

```bash
fvm dart pub global activate pana 0.23.14
fvm dart run tool/pana/check_pana.dart --report-only
```

`tool/pana/check_pana.dart` runs `pana --json --no-dartdoc` once per package
listed in `tool/pana_floors.yaml`, sums `report.sections[].grantedPoints`, and
compares the total against that package's floor.

Two properties keep CI and local identical:

- **`--no-dartdoc` is always passed.** It drops pana's 10 dartdoc-coverage
  points, so the **maximum is 150, not 160**. Dartdoc is by far the slowest part
  of a pana run; skipping it keeps a four-package sweep near 5–8 minutes.
- **pana runs under the script's own Dart SDK.** The script spawns
  `Platform.resolvedExecutable pub global run pana`, so it uses fvm's pinned
  Dart locally and flutter-action's Dart in CI. pana derives the Flutter SDK
  from the Dart SDK path — never pass `--flutter-sdk` or `--dart-sdk`.

pana's version is pinned (0.23.14) in the workflow and the setup scripts. Bump it
deliberately, in its own commit, and re-measure the floors — a new pana release
can change how points are awarded.

## Formatting is worth 10 points, and `flutter analyze` will not tell you

pana folds `dart format` compliance into its 50-point static-analysis section:
**one** unformatted file under `lib/` zeroes 10 of those points. This is not a
lint, so `fvm flutter analyze` reports `No issues found!` on a package that is
losing the points. This gate is the only check in the repo that catches it.

`flutter_adaptive_cards_fs` scored 130 rather than 140 for exactly this reason —
a single needlessly-wrapped line in `lib/src/cards/adaptive_card_element.dart`.

The reverse also holds: **pana only inspects `lib/`.** Drifted files under
`test/` cost nothing, so a full-marks static-analysis score is not evidence the
package is `dart format`-clean. Before a release, check the whole package:

```bash
fvm dart format --output=none --set-exit-if-changed packages/
```

## Why charts and host score 40

**pana resolves every package as if it were already published.** It copies the
package into a temp directory, ignores the pub workspace, and strips
`pubspec_overrides.yaml`. So `flutter_adaptive_charts_fs` and
`flutter_adaptive_cards_host_fs`, which depend on
`flutter_adaptive_cards_fs: ^<current version>`, fail version solving for the
entire development cycle — the core package at that version is not on pub.dev yet:

```text
Because flutter_adaptive_cards_host_fs depends on flutter_adaptive_cards_fs ^0.15.0
which doesn't match any versions, version solving failed.
```

That failure costs the static-analysis and dependency sections about 110 points.
There is no workaround — `dependency_overrides` do not survive into pana's copy,
which is correct, because pub.dev would score the published archive the same way.

Consequences:

- Their floors in `tool/pana_floors.yaml` are set to the failing-resolution
  baseline (40), not to an aspirational number. The gate still catches a
  regression **below** that baseline.
- **Their real score is only observable right after the core package is
  published** at the matching version. The `adaptive-cards-release-engineer`
  skill has a step for exactly that moment.

## Updating a floor

Raise a floor in its own commit, after landing the change that lifted the score.
**Never lower a floor to make a red build pass** — the point of a ratchet is that
it only moves one way. If a package legitimately drops (for example, a dependency
you do not control stops supporting the latest SDK), say so in the commit message.

## Running it locally

| Goal                          | Command                                                                   |
| ----------------------------- | ------------------------------------------------------------------------- |
| Score everything, never fail  | `fvm dart run tool/pana/check_pana.dart --report-only`                    |
| Score everything, enforcing   | `fvm dart run tool/pana/check_pana.dart`                                  |
| Score one package             | `fvm dart run tool/pana/check_pana.dart --only flutter_adaptive_cards_fs` |
| Verify the gate's own parsers | `fvm dart run tool/pana/check_pana.dart --self-test`                      |

From VS Code, use **Tasks: Run Task** → **pana: all packages** or
**pana: one package**. `Setup pana` activates the pinned CLI;
`scripts/setup-workspace.sh` does it too on a fresh clone.

Never run bare `pana` in the repo root — the root `pubspec.yaml` is a workspace
manifest (`name: _`), and pana will happily score it and report a meaningless
number.

## Current state

The CI job is **report-only** (`--report-only` in
`.github/workflows/validate.yaml`), matching the rollout the coverage gate used.
Drop the flag to make it enforcing once the plumbing has proven itself.

`flutter_adaptive_cards_test_support` is not scored: it is `publish_to: none`.

## Known gaps

- Neither `flutter_adaptive_cards_fs` nor `flutter_adaptive_template_fs` ships an
  `example/` directory, costing each 10 points in pana's documentation section.
  That is real authoring work and is tracked separately from this gate.
- Dartdoc coverage (10 points) is never scored in CI. Check it manually before a
  release by dropping `--no-dartdoc` from a one-off `pana` invocation.

See also: [`docs/testing-coverage.md`](testing-coverage.md), the sibling
line-coverage gate this one is modelled on.
````

- [ ] **Step 2: Format the new doc**

```bash
npm run format:md
npm run check:md
```

Expected: `check:md` reports all matched files use Prettier code style. (`docs/superpowers/**` is Prettier-ignored, so this plan file is untouched.)

- [ ] **Step 3: Add the release-time re-score step**

In `.claude/skills/adaptive-cards-release-engineer/SKILL.md`, insert this note in
**§5 Publishing to pub.dev**, immediately after the line
Repeat for `flutter_adaptive_template_fs`, `flutter_adaptive_charts_fs`, and `flutter_adaptive_cards_host_fs`.
(currently line 129) and before the `## 6. Post-Release Version Bump (Required)`
heading. That is the right anchor because §5 already publishes in dependency
order — core first, then charts and host "after cards is live" — and this note
attaches to that same window:

````markdown
**Re-score charts and host after core publishes.** `flutter_adaptive_charts_fs`
and `flutter_adaptive_cards_host_fs` score 40/150 in CI for the whole
development cycle, because pana resolves them as published packages and their
`flutter_adaptive_cards_fs: ^<version>` constraint has nothing to match yet. The
window right after core lands on pub.dev is the only time their score is real:

```bash
fvm dart run tool/pana/check_pana.dart --only flutter_adaptive_charts_fs
fvm dart run tool/pana/check_pana.dart --only flutter_adaptive_cards_host_fs
```

Fix anything that surfaces **before** publishing those two, then restore their
floors in `tool/pana_floors.yaml` to the low baseline for the next cycle. See
[`docs/pub-score-pana.md`](../../../docs/pub-score-pana.md).
````

- [ ] **Step 4: Verify no stale references**

```bash
git grep -n 'pana' docs/ .github/ .vscode/ tool/ scripts/ .claude/skills/ | grep -v '^docs/superpowers/'
```

Expected: every hit points at `docs/pub-score-pana.md`, `tool/pana_floors.yaml`,
`tool/pana/check_pana.dart`, or the pinned `pana 0.23.14` activation — no
references to files that were not created.

- [ ] **Step 5: Commit**

```bash
git add docs/pub-score-pana.md .claude/skills/adaptive-cards-release-engineer/SKILL.md
git commit -m "docs: document the pana pub-score gate and its release-time step"
```

---

### Task 6: Dart format gate in CI

**Files:**

- Modify: `.github/workflows/validate.yaml` (add a third job)

**Interfaces:**

- Consumes: nothing from earlier tasks — this job is independent of the pana gate and can land or be reverted on its own.
- Produces: a `dart-format` job named "Dart format" on the workflow's existing triggers.

**Why this is separate from the pana gate.** Nothing in this repo currently
enforces Dart formatting: `test.yml` runs tests, `validate.yaml` checks only
Markdown, and `fvm flutter analyze` cannot catch it because formatting is not a
lint. That gap is how `lib/src/cards/adaptive_card_element.dart` reached `main`
unformatted and quietly cost 10 pana points (see the Background section).

The pana gate is a poor substitute for this check: it is report-only at first,
it inspects only `lib/`, it takes 5–8 minutes, and it reports a score rather than
naming the offending file. `dart format --set-exit-if-changed` runs in seconds
over the whole workspace and prints the exact path. Land both — pana measures
publishability, this keeps the tree clean.

- [ ] **Step 1: Reproduce the failure the job must catch**

Introduce drift, confirm the command fails, then restore:

```bash
printf '\n\nvoid _scratch()   {}\n' >> packages/flutter_adaptive_cards_fs/lib/src/utils/utils.dart
fvm dart format --output=none --set-exit-if-changed packages/; echo "exit=$?"
git checkout packages/flutter_adaptive_cards_fs/lib/src/utils/utils.dart
```

Expected: `Changed packages/flutter_adaptive_cards_fs/lib/src/utils/utils.dart`
and `exit=1`. Confirm `fvm flutter analyze` still reports `No issues found!` on
that same drifted tree if you want to see why analyze cannot replace this job.

- [ ] **Step 2: Add the job**

Add to the end of `.github/workflows/validate.yaml`, at the same indentation as
the existing `markdown-format:` and `pana:` job keys:

```yaml
dart-format:
  name: Dart format
  runs-on: ubuntu-24.04
  timeout-minutes: 10

  steps:
    - name: Checkout repository
      uses: actions/checkout@v6

    - uses: subosito/flutter-action@v2
      with:
        channel: "stable"
        flutter-version: 3.44.0 # should sync with fvm version
        cache: true

    # Enforcing from day one, unlike the pana gate: this check is fast,
    # deterministic, and mechanically fixable with `dart format .`. Formatting
    # is not a lint, so `flutter analyze` passes on a drifted tree -- this is
    # the only job that catches it. pana also scores lib/ formatting as part
    # of its static-analysis section, but report-only and 5-8 minutes slower.
    - name: Check Dart formatting
      run: dart format --output=none --set-exit-if-changed packages/ tool/
```

`tool/` is included so `tool/pana/check_pana.dart` from Task 1 stays formatted;
it is outside `packages/` and would otherwise never be checked.

- [ ] **Step 3: Update the workflow header comment**

The header comment written in Task 3 lists two jobs. Replace that block with:

```yaml
# Repo-wide validation checks that are not the test suite:
#   - markdown-format: the published Markdown docs are Prettier-formatted.
#   - pana: the four published packages meet their pub.dev score floors.
#   - dart-format: Dart sources under packages/ and tool/ are dart format-clean.
```

- [ ] **Step 4: Verify the workflow parses and the check passes**

```bash
python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/validate.yaml')); print(sorted(d['jobs'].keys()))"
fvm dart format --output=none --set-exit-if-changed packages/ tool/; echo "exit=$?"
```

Expected: `['dart-format', 'markdown-format', 'pana']`, then `exit=0`.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/validate.yaml
git commit -m "ci: enforce dart format on packages/ and tool/"
```

---

## Final Task: Full verification

Run every check before claiming the plan is complete. Paste the command output —
exit codes and pass/fail counts — per the AGENTS.md plan completion gate, and
invoke **`superpowers:verification-before-completion`**.

- [ ] **Step 1: Analyze the workspace**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Formatting**

```bash
fvm dart format --output=none --set-exit-if-changed packages/ tool/
npm run check:md
```

Expected: both exit 0. This is the same command Task 6's CI job runs.

- [ ] **Step 3: Gate self-test**

```bash
fvm dart run tool/pana/check_pana.dart --self-test
```

Expected: `self-test: PASS`, exit 0.

- [ ] **Step 4: Full pub-score sweep**

```bash
fvm dart run tool/pana/check_pana.dart --report-only
```

Expected: four rows, every package at or above its floor,
`Pub-score gate: REPORT-ONLY (not failing the build)`, exit 0.

- [ ] **Step 5: Main library test suite**

No file under `packages/` changed in this plan, so the suite is a regression
check only:

```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden
```

Expected: all tests pass. Return to the repo root afterwards.

- [ ] **Step 6: Confirm CI is green**

Both jobs in the validate workflow — "Markdown format (Prettier)" and
"Pub score (pana)" — must pass on the PR, along with the existing test workflow.

- [ ] **Step 7: Finish the branch**

Invoke **`superpowers:finishing-a-development-branch`** only after every step
above has passed.
