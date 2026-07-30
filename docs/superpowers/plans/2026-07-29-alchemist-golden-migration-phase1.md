# Alchemist Golden Migration — Phase 1 (Pilot) Implementation Plan

> [!CAUTION]
>
> **OBSOLETE — NEVER EXECUTED. DO NOT IMPLEMENT THIS PLAN.**
>
> The Alchemist migration was **rejected on 2026-07-29**, the same day this plan was
> written, before any task was dispatched. No task below was started; no `alchemist`
> dependency was added; no baseline was regenerated. Zero of the 55 steps ran.
>
> **Reason, in one line:** Alchemist's only real advantage — a single
> platform-agnostic baseline set — is produced solely by replacing text with colored
> rectangles and the Ahem font, which destroys the typography and icon-glyph signal
> these goldens exist to verify. With real text it writes per-platform baselines,
> exactly like the setup we already have, so the migration bought nothing while
> costing all 49 baselines.
>
> Full rationale:
> [`docs/superpowers/specs/2026-07-29-alchemist-golden-migration-design.md`](../specs/2026-07-29-alchemist-golden-migration-design.md#decision-why-we-are-not-doing-this)
>
> **Direction taken instead:** local helpers over the built-in `matchesGoldenFile` — a
> thin `adaptiveGoldenTest()` wrapper preserving the existing `MaterialApp` tree so
> baselines stay byte-identical, plus an optional labeled scenario-grid widget. No
> tolerance comparator: fine visual detail is the point, so comparison stays exact.
>
> Retained only as a record of what was evaluated and why it was dropped. Two details
> in Task 5 are still worth doing independently of any migration: removing the stale
> `golden_toolkit` line at `packages/flutter_adaptive_cards_fs/README.md:725`, and
> deleting the stray Linux-only baseline
> `test/gold_files/linux/v1_6_compound_button copy.png`.
>
> **For agentic workers:** this plan is obsolete — do not execute it. The
> subagent-driven-development and executing-plans skills must not be invoked against
> it. Steps retain `- [ ]` syntax only because the document is preserved verbatim
> below; every box is and remains unchecked.

**Goal:** Wire the `alchemist` package into the shared test bootstrap with real-text goldens on every host, and migrate `golden_icon_test.dart` (2 goldens) as the pilot that gates the rest of the migration.

**Architecture:** `alchemist` becomes a dependency of `flutter_adaptive_cards_test_support` and is re-exported from its barrel, so consuming packages inherit it through the existing `test/utils/test_utils.dart` funnel without pubspec changes of their own. An `AlchemistConfig` is installed in `adaptiveCardsTestExecutable()` via `runWithConfig`, with the CI (obscured-text) variant disabled outright and a `filePathResolver` that reproduces the existing `gold_files/<os>/` layout. A new `buildCardScenario()` helper returns a bare card for Alchemist to wrap, alongside the existing `MaterialApp`-based helpers which stay for un-migrated tests.

**Tech Stack:** Flutter 3.44.0 via FVM, Dart ^3.12.0, `alchemist` ^0.14.0, `flutter_test`, `very_good_analysis` ^10.3.0

## Global Constraints

- Every `flutter` and `dart` command MUST be prefixed with `fvm`.
- **Real text is mandatory.** `CiGoldensConfig(enabled: false)` — Alchemist's obscured-text mode erases the bold/italic/font-size signal these goldens exist to verify. Never enable it.
- `diffThreshold` stays at its default `0.0` in this phase. The migration changes the mechanism only, not the comparison tolerance.
- Baseline paths MUST remain `gold_files/<os>/<name>.png` with `<os>` lowercased (`macos`, `linux`). No renames, no directory restructuring.
- `goldenTest()`'s `tags` parameter already defaults to `const ['golden']` — do not override it. CI routing depends on this tag.
- `fileName` passed to `goldenTest()` MUST NOT include the `.png` extension (asserted inside `goldenTest`).
- Packages under `packages/` must not gain new hardcoded user-visible strings. Test-only code is exempt, but do not add `semanticsLabel:` strings to library code.
- Whenever any file under `packages/<name>/` changes, add a bullet to that package's `CHANGELOG.md` `## [Unreleased]` section.
- **Git gate (`AGENTS.md`):** never run `git commit` or `git push` without showing the diff, summarizing it, and receiving explicit user confirmation. Every commit step below requires this.
- Do not add Windows to the `platforms` set — there is no Windows CI runner.
- Do not modify `golden_sample_test.dart` or any other golden test in this phase.

## File Structure

**Create:**

- `packages/flutter_adaptive_cards_test_support/lib/src/golden_theme.dart` — pins the `ThemeData` migrated goldens render under. Single responsibility: theme identity.
- `packages/flutter_adaptive_cards_test_support/lib/src/golden_config.dart` — builds the `AlchemistConfig` (variant enablement, platforms, path resolver). Single responsibility: Alchemist configuration.
- `packages/flutter_adaptive_cards_test_support/lib/src/card_scenario.dart` — `buildCardScenario()`, the bare-card builder for Alchemist scenarios.
- `packages/flutter_adaptive_cards_fs/test/golden_config_test.dart` — asserts the Alchemist config's policy decisions.
- `packages/flutter_adaptive_cards_fs/test/card_scenario_test.dart` — unit tests for `buildCardScenario()`.

Both new test files live in **`flutter_adaptive_cards_fs`**, not in test-support. Test-support has no `test/` directory and `.github/workflows/test.yml` has no step for it, so tests placed there would never run in CI. The cards package is already covered by both CI passes and is where the sample JSON fixtures live, so `samplesDirectory` resolves at its default.

**Modify:**

- `packages/flutter_adaptive_cards_test_support/pubspec.yaml` — add `alchemist` dependency.
- `packages/flutter_adaptive_cards_test_support/lib/flutter_adaptive_cards_test_support.dart` — export the three new files, re-export `package:alchemist/alchemist.dart`.
- `packages/flutter_adaptive_cards_test_support/lib/src/flutter_test_config.dart` — wrap `testMain` in `AlchemistConfig.runWithConfig`.
- `packages/flutter_adaptive_cards_fs/test/golden_icon_test.dart` — convert both goldens to `goldenTest()`.
- `packages/flutter_adaptive_cards_fs/README.md:725` — remove the stale `golden_toolkit` line.
- `packages/flutter_adaptive_cards_fs/test/gold_files/README.md` — document both mechanisms.
- `CHANGELOG.md` in `flutter_adaptive_cards_test_support` and `flutter_adaptive_cards_fs`.

**Regenerate:**

- `packages/flutter_adaptive_cards_fs/test/gold_files/macos/v1_5_icon_demo.png`
- `packages/flutter_adaptive_cards_fs/test/gold_files/macos/v1_6_icon_catalog.png`
- the two matching `linux/` files, seeded from CI artifacts (Task 6)

**Delete:**

- `packages/flutter_adaptive_cards_fs/test/gold_files/linux/v1_6_compound_button copy.png` — stray duplicate present only on Linux.

---

### Task 1: Add the `alchemist` dependency and prove it does not disturb existing goldens

`alchemist` declares its own Roboto font family in its pubspec (`assets/fonts/Roboto/`, weights 100–900). Your `loadBundledTestFonts()` reads `FontManifest.json` and strips `packages/<name>/` prefixes, so if Alchemist's Roboto reaches the test bundle it would register family `Roboto` a second time and could change text rendering in **all 41** existing cards goldens. This task exists to surface that collision before any test is rewritten.

**Files:**

- Modify: `packages/flutter_adaptive_cards_test_support/pubspec.yaml`

**Interfaces:**

- Consumes: nothing (first task)
- Produces: `package:alchemist/alchemist.dart` resolvable from `flutter_adaptive_cards_test_support`

- [ ] **Step 1: Capture the current golden baseline state**

Run from the repo root:

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test --tags=golden -r expanded
```

Expected: all golden tests PASS. Record the passing count — this is the number Step 4 must reproduce. If anything fails **before** you change a thing, stop and report; the working tree is not a valid starting point.

- [ ] **Step 2: Add the dependency**

In `packages/flutter_adaptive_cards_test_support/pubspec.yaml`, add `alchemist` to `dependencies` in alphabetical order (it goes first, before `flutter`):

```yaml
dependencies:
  alchemist: ^0.14.0
  flutter:
    sdk: flutter
  flutter_adaptive_cards_fs:
    path: ../flutter_adaptive_cards_fs
  flutter_test:
    sdk: flutter
  package_config: ^2.2.0
```

`alchemist` 0.14.0 requires `sdk: '>=3.8.0 <4.0.0'` and `flutter: '>=3.32.0'`; this repo is Dart `^3.12.0` on Flutter 3.44.0, so it is compatible. It is a regular `dependency` (not `dev_dependency`) because this package's whole purpose is to be a test-support library — its consumers need the symbols it re-exports.

- [ ] **Step 3: Resolve**

Run from the repo root (workspace resolution is repo-wide):

```bash
fvm flutter pub get
```

Expected: resolves cleanly, reporting `alchemist 0.14.0` plus transitive `equatable`. If pub reports a version conflict, stop and report it rather than loosening any other constraint.

- [ ] **Step 4: Verify existing goldens are unaffected**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test --tags=golden -r expanded
```

Expected: PASS, with the **same count** as Step 1.

If goldens now fail on text rendering, Alchemist's bundled Roboto has leaked into the test bundle. Diagnose before proceeding by dumping the manifest — add this temporary test and run it:

```dart
// packages/flutter_adaptive_cards_fs/test/tmp_font_manifest_test.dart
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dump font manifest', (tester) async {
    log(await rootBundle.loadString('FontManifest.json'));
  });
}
```

If `packages/alchemist/...` entries appear, exclude that family in `loadBundledTestFonts()` by skipping families whose raw name starts with `packages/alchemist/`, then re-run. Delete the temporary test either way.

- [ ] **Step 5: Also verify the charts package**

```bash
cd packages/flutter_adaptive_charts_fs && fvm flutter test --tags=golden -r expanded
```

Expected: PASS, all 8 goldens.

- [ ] **Step 6: Analyze**

```bash
fvm flutter analyze
```

Expected: no new issues.

- [ ] **Step 7: Commit**

Per the `AGENTS.md` git gate, show the diff, summarize it, and wait for explicit user confirmation. Only then:

```bash
git add packages/flutter_adaptive_cards_test_support/pubspec.yaml pubspec.lock
git commit -m "chore(test-support): add alchemist dependency"
```

---

### Task 2: Pin the golden theme and install the Alchemist config

**Files:**

- Create: `packages/flutter_adaptive_cards_test_support/lib/src/golden_theme.dart`
- Create: `packages/flutter_adaptive_cards_test_support/lib/src/golden_config.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/golden_config_test.dart`
- Modify: `packages/flutter_adaptive_cards_test_support/lib/src/flutter_test_config.dart`
- Modify: `packages/flutter_adaptive_cards_test_support/lib/flutter_adaptive_cards_test_support.dart`

**Interfaces:**

- Consumes: `package:alchemist/alchemist.dart` (Task 1)
- Produces:

  - `ThemeData get adaptiveCardsGoldenTheme`
  - `AlchemistConfig buildAdaptiveCardsAlchemistConfig()`
  - `adaptiveCardsTestExecutable(FutureOr<void> Function() testMain)` — unchanged signature, now Alchemist-aware
  - the barrel re-exports every `alchemist` symbol (`goldenTest`, `GoldenTestGroup`, `GoldenTestScenario`, `AlchemistConfig`, `HostPlatform`, …)

- [ ] **Step 1: Write the failing test**

Create `packages/flutter_adaptive_cards_fs/test/golden_config_test.dart`. Note it imports through `utils/test_utils.dart` rather than `package:alchemist/alchemist.dart` directly — the cards package does not declare `alchemist` itself, so a direct import would trip the `depend_on_referenced_packages` lint. The barrel re-export added in Step 5 is the supported path.

```dart
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  group('buildAdaptiveCardsAlchemistConfig', () {
    test('disables the obscured-text CI variant', () {
      final config = buildAdaptiveCardsAlchemistConfig();

      expect(config.ciGoldensConfig.enabled, isFalse);
    });

    test('renders real text in platform goldens', () {
      final config = buildAdaptiveCardsAlchemistConfig();

      expect(config.platformGoldensConfig.obscureText, isFalse);
    });

    test('runs platform goldens on macOS and Linux', () {
      final config = buildAdaptiveCardsAlchemistConfig();

      expect(
        config.platformGoldensConfig.platforms,
        equals({HostPlatform.macOS, HostPlatform.linux}),
      );
    });

    test('resolves goldens into the existing lowercased gold_files layout',
        () async {
      final config = buildAdaptiveCardsAlchemistConfig();

      final macPath = await config.platformGoldensConfig.filePathResolver(
        'v1_5_icon_demo',
        HostPlatform.macOS.operatingSystem,
      );
      final linuxPath = await config.platformGoldensConfig.filePathResolver(
        'v1_5_icon_demo',
        HostPlatform.linux.operatingSystem,
      );

      expect(macPath, equals('gold_files/macos/v1_5_icon_demo.png'));
      expect(linuxPath, equals('gold_files/linux/v1_5_icon_demo.png'));
    });

    test('keeps the default zero diff threshold', () {
      final config = buildAdaptiveCardsAlchemistConfig();

      expect(config.platformGoldensConfig.diffThreshold, equals(0.0));
    });
  });
}
```

The lowercasing assertion matters: `HostPlatform.macOS.operatingSystem` returns `'macOS'` and `.linux` returns `'Linux'`, but the on-disk directories are `macos` and `linux`.

- [ ] **Step 2: Run it to verify it fails**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_config_test.dart
```

Expected: FAIL — compile error, `buildAdaptiveCardsAlchemistConfig` is undefined.

- [ ] **Step 3: Create the golden theme**

Create `packages/flutter_adaptive_cards_test_support/lib/src/golden_theme.dart`:

```dart
import 'package:flutter/material.dart';

/// The [ThemeData] every Alchemist golden renders under.
///
/// Alchemist deliberately does not pump a [MaterialApp], so migrated goldens do
/// not inherit the theme the `MaterialApp`-based helpers supply. Pinning it here
/// keeps typography stable: without it, goldens would silently re-baseline
/// whenever Flutter changes its default theme, producing diffs that have nothing
/// to do with this library's rendering.
///
/// This matches what a bare `MaterialApp()` resolves to, which is what the
/// pre-migration baselines were captured under.
ThemeData get adaptiveCardsGoldenTheme => ThemeData.light();
```

- [ ] **Step 4: Create the Alchemist config**

Create `packages/flutter_adaptive_cards_test_support/lib/src/golden_config.dart`:

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter_adaptive_cards_test_support/src/golden_theme.dart';

/// Builds the Alchemist configuration shared by every Adaptive Cards package.
///
/// Callers do not normally invoke this directly — [adaptiveCardsTestExecutable]
/// installs it for the whole test file. It is public so tests can assert on the
/// policy decisions encoded here.
AlchemistConfig buildAdaptiveCardsAlchemistConfig() {
  return AlchemistConfig(
    theme: adaptiveCardsGoldenTheme,
    // Styling IS the thing under test: bold, italic, and font size must render
    // as real glyphs. Alchemist's CI variant replaces text with colored blocks
    // to make goldens platform-agnostic, which would erase exactly the signal
    // these goldens exist to capture. Platform goldens therefore run on every
    // host, including CI, and the CI variant is disabled outright.
    ciGoldensConfig: const CiGoldensConfig(enabled: false),
    platformGoldensConfig: PlatformGoldensConfig(
      platforms: const {HostPlatform.macOS, HostPlatform.linux},
      // `operatingSystem` yields 'macOS'/'Linux'; the committed directories are
      // lowercase, and this preserves the pre-Alchemist layout so no baseline
      // needs moving or renaming.
      filePathResolver: (fileName, environmentName) =>
          'gold_files/${environmentName.toLowerCase()}/$fileName.png',
    ),
  );
}
```

- [ ] **Step 5: Export both from the barrel**

Replace the export block in `packages/flutter_adaptive_cards_test_support/lib/flutter_adaptive_cards_test_support.dart`:

```dart
/// Shared Flutter test utilities for Adaptive Cards
/// packages (fonts, HTTP stubs, widget/golden helpers).
library;

// Re-exported so consuming packages get `goldenTest`, `GoldenTestGroup`, and
// `GoldenTestScenario` through the existing `test/utils/test_utils.dart` funnel
// without each package declaring its own alchemist dependency.
export 'package:alchemist/alchemist.dart';

export 'package:flutter_adaptive_cards_test_support/src/flutter_test_config.dart';
export 'package:flutter_adaptive_cards_test_support/src/golden_config.dart';
export 'package:flutter_adaptive_cards_test_support/src/golden_helpers.dart';
export 'package:flutter_adaptive_cards_test_support/src/golden_theme.dart';
export 'package:flutter_adaptive_cards_test_support/src/http_overrides.dart';
export 'package:flutter_adaptive_cards_test_support/src/test_widget_helpers.dart';
```

- [ ] **Step 6: Run the test to verify it passes**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_config_test.dart
```

Expected: PASS, 5 tests.

- [ ] **Step 7: Install the config in the shared bootstrap**

In `packages/flutter_adaptive_cards_test_support/lib/src/flutter_test_config.dart`, add the import:

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter_adaptive_cards_test_support/src/golden_config.dart';
```

then replace `adaptiveCardsTestExecutable` at the bottom of the file:

```dart
/// Shared Flutter test bootstrap for Adaptive Cards packages.
///
/// Loads fonts, stubs network access, and installs the Alchemist configuration
/// for the whole test file. Tests that still use raw `matchesGoldenFile` are
/// unaffected — the Alchemist config is only consulted by `goldenTest()`.
Future<void> adaptiveCardsTestExecutable(
  FutureOr<void> Function() testMain,
) async {
  setUpAll(() async {
    HttpOverrides.global = MyTestHttpOverrides();
    await loadAdaptiveCardsTestFonts();
    await loadBundledTestFonts();
  });

  // `runWithConfig` is a `runZoned` with zone values, and `goldenTest()` reads
  // `AlchemistConfig.current()` from that zone — so `testMain` must be invoked
  // inside it. The `async` closure keeps the generic bound to `Future<void>`
  // rather than `FutureOr<void>`, which would not be assignable to this
  // function's return type.
  await AlchemistConfig.runWithConfig(
    config: buildAdaptiveCardsAlchemistConfig(),
    run: () async => testMain(),
  );
}
```

- [ ] **Step 8: Verify the full existing suite is untouched**

This is the critical regression gate: the config is now installed globally for every test file in both packages, so all pre-existing goldens must still pass byte-identically.

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test --tags=golden -r expanded
cd ../flutter_adaptive_charts_fs && fvm flutter test --tags=golden -r expanded
cd ../flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden
cd ../flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden
cd ../flutter_adaptive_cards_host_fs && fvm flutter test
cd ../flutter_adaptive_template_fs && fvm flutter test
```

Expected: all PASS. Golden counts must match Task 1 Step 1.

- [ ] **Step 9: Analyze**

```bash
fvm flutter analyze
```

Expected: no new issues. `always_use_package_imports` and `prefer_single_quotes` are enforced — the code above complies.

- [ ] **Step 10: Commit**

Show the diff, summarize, wait for explicit user confirmation, then:

```bash
git add packages/flutter_adaptive_cards_test_support/lib \
        packages/flutter_adaptive_cards_fs/test/golden_config_test.dart
git commit -m "feat(test-support): install alchemist config with real-text goldens"
```

---

### Task 3: Add the bare-card scenario builder

**Files:**

- Create: `packages/flutter_adaptive_cards_test_support/lib/src/card_scenario.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/card_scenario_test.dart`
- Modify: `packages/flutter_adaptive_cards_test_support/lib/flutter_adaptive_cards_test_support.dart`

**Interfaces:**

- Consumes: `adaptiveCardsGoldenTheme` is not needed here — Alchemist applies the theme itself.
- Produces:

```dart
Widget buildCardScenario({
  required String path,
  HostConfigs? hostConfigs,
  CardTypeRegistry cardTypeRegistry = const CardTypeRegistry(),
  Map? initData,
  bool supportMarkdown = true,
  String samplesDirectory = 'test/samples',
})
```

- [ ] **Step 1: Write the failing test**

Create `packages/flutter_adaptive_cards_fs/test/card_scenario_test.dart`. Living in the cards package means `samplesDirectory` resolves at its default `test/samples`, where the fixtures already are.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  group('buildCardScenario', () {
    testWidgets('returns a bare card with no MaterialApp or Scaffold', (
      tester,
    ) async {
      final scenario = buildCardScenario(path: 'v1.5/icon_demo.json');

      // Alchemist supplies theming and containment; a nested MaterialApp would
      // distort the golden and duplicate per scenario inside a grid.
      expect(scenario, isNot(isA<MaterialApp>()));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: scenario)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveCardsCanvas), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('accepts a path with no .json extension', (tester) async {
      final scenario = buildCardScenario(path: 'v1.5/icon_demo');

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: scenario)));
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveCardsCanvas), findsOneWidget);
    });
  });
}
```

Before running, confirm both fixtures exist:

```bash
ls packages/flutter_adaptive_cards_fs/test/samples/v1.5/icon_demo.json \
   packages/flutter_adaptive_cards_fs/test/samples/v1.6/icon_catalog.json
```

Both are already referenced by the current `golden_icon_test.dart`, so they should be present. `buildCardScenario` resolves paths relative to the current working directory, which `flutter test` sets to the package root.

- [ ] **Step 2: Run it to verify it fails**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/card_scenario_test.dart
```

Expected: FAIL — `buildCardScenario` is undefined.

- [ ] **Step 3: Implement the builder**

Create `packages/flutter_adaptive_cards_test_support/lib/src/card_scenario.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Builds a bare [AdaptiveCardsCanvas] for an Alchemist golden scenario.
///
/// Use this instead of [getTestWidgetFromPath] inside `goldenTest()`: Alchemist
/// supplies the theme, the surrounding container, and image capture itself, so
/// the `MaterialApp` + `Scaffold` + `AppBar` + `RepaintBoundary` wrappers that
/// helper adds would both distort the captured image and repeat once per
/// scenario in a multi-scenario grid.
///
/// [path] is relative to [samplesDirectory] and may omit the `.json` extension.
Widget buildCardScenario({
  required String path,
  HostConfigs? hostConfigs,
  CardTypeRegistry cardTypeRegistry = const CardTypeRegistry(),
  Map? initData,
  bool supportMarkdown = true,
  String samplesDirectory = 'test/samples',
}) {
  final String resolved = path.endsWith('.json') ? path : '$path.json';
  final File file = File('$samplesDirectory/$resolved');
  final Map<String, dynamic> map =
      json.decode(file.readAsStringSync()) as Map<String, dynamic>;

  return AdaptiveCardsCanvas.map(
    content: map,
    cardTypeRegistry: cardTypeRegistry,
    // Debug JSON panes do not appear in production, so keep them out of goldens.
    showDebugJson: false,
    initData: initData,
    supportMarkdown: supportMarkdown,
    hostConfigs: hostConfigs ?? HostConfigs(),
  );
}
```

- [ ] **Step 4: Export it**

Add to the barrel in `packages/flutter_adaptive_cards_test_support/lib/flutter_adaptive_cards_test_support.dart`, keeping exports alphabetical:

```dart
export 'package:flutter_adaptive_cards_test_support/src/card_scenario.dart';
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/card_scenario_test.dart
```

Expected: PASS, 2 tests.

- [ ] **Step 6: Analyze**

```bash
fvm flutter analyze
```

Expected: no new issues.

- [ ] **Step 7: Commit**

Show the diff, summarize, wait for explicit user confirmation, then:

```bash
git add packages/flutter_adaptive_cards_test_support/lib \
        packages/flutter_adaptive_cards_fs/test/card_scenario_test.dart
git commit -m "feat(test-support): add buildCardScenario for alchemist goldens"
```

---

### Task 4: Migrate `golden_icon_test.dart` and regenerate macOS baselines

This is the pilot. It was chosen because it has zero interaction and exercises **both** font paths — Roboto text and `MaterialIcons` glyphs — which is precisely the fidelity risk the whole migration turns on.

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/test/golden_icon_test.dart`
- Regenerate: `packages/flutter_adaptive_cards_fs/test/gold_files/macos/v1_5_icon_demo.png`
- Regenerate: `packages/flutter_adaptive_cards_fs/test/gold_files/macos/v1_6_icon_catalog.png`

**Interfaces:**

- Consumes: `buildCardScenario()` (Task 3), `goldenTest` / `GoldenTestGroup` / `GoldenTestScenario` re-exported via `utils/test_utils.dart` (Task 2)
- Produces: nothing consumed by later tasks

- [ ] **Step 1: Rewrite the test**

Replace the entire contents of `packages/flutter_adaptive_cards_fs/test/golden_icon_test.dart`:

```dart
import 'package:flutter/material.dart';

import 'utils/test_utils.dart';

void main() {
  // `tags` defaults to const ['golden'] inside goldenTest(), which is what CI's
  // --tags=golden pass selects, so it is deliberately not passed here.
  //
  // `fileName` must omit the .png extension — goldenTest() asserts on that, and
  // the configured filePathResolver appends it along with the platform folder.
  goldenTest(
    'Golden Icon',
    fileName: 'v1_5_icon_demo',
    constraints: const BoxConstraints.tightFor(width: 500, height: 700),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'icon demo',
          child: buildCardScenario(path: 'v1.5/icon_demo'),
        ),
      ],
    ),
  );

  goldenTest(
    'Icon catalog golden — expanded names',
    fileName: 'v1_6_icon_catalog',
    constraints: const BoxConstraints.tightFor(width: 420, height: 120),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'icon catalog',
          child: buildCardScenario(path: 'v1.6/icon_catalog'),
        ),
      ],
    ),
  );
}
```

The `constraints` replace the old `configureTestView(size: ...)` calls — `Size(500, 700)` and `Size(420, 120)` respectively. The trailing `await tester.pump(const Duration(milliseconds: 100))` in the original is vestigial and drops out; `goldenTest`'s default `pumpBeforeTest` is `onlyPumpAndSettle`, which subsumes the old `pumpAndSettle`.

- [ ] **Step 2: Run it to verify it fails against the old baselines**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_icon_test.dart --tags=golden -r expanded
```

Expected: FAIL on pixel comparison for both goldens. This failure is **correct and expected** — the old baselines were captured inside a `MaterialApp` + `Scaffold` + `AppBar`, and Alchemist renders without them. A PASS here would mean the new code path never ran; investigate before continuing.

- [ ] **Step 3: Inspect the failure images before trusting them**

```bash
ls packages/flutter_adaptive_cards_fs/test/failures/
```

Open the `*_testImage.png` files and confirm, by eye:

- text renders as **real glyphs** — not colored rectangles (would mean `obscureText` leaked on) and not empty tofu boxes (would mean fonts did not load)
- icons render as **real glyphs**, not tofu boxes — this is the `MaterialIcons` path
- bold, italic, and font-size differences are visibly distinct
- the `AppBar` is absent and the card is the whole image

If text is blocked or tofu, stop — do not regenerate baselines. A blocked-text image means `ciGoldensConfig` is somehow enabled; tofu means font loading did not survive into Alchemist's pump. Report either finding rather than baking it into a baseline.

- [ ] **Step 4: Regenerate the macOS baselines**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_icon_test.dart --tags=golden --update-goldens
```

Expected: PASS. Confirm the two files were rewritten in place, at unchanged paths:

```bash
git status --short packages/flutter_adaptive_cards_fs/test/gold_files/
```

Expected: exactly two modified files, `macos/v1_5_icon_demo.png` and `macos/v1_6_icon_catalog.png`. **No new or renamed files.** If new paths appeared, the `filePathResolver` is wrong — fix Task 2 rather than committing the new layout.

- [ ] **Step 5: Re-run without updating to confirm determinism**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_icon_test.dart --tags=golden -r expanded
```

Expected: PASS, 2 tests.

- [ ] **Step 6: Confirm the rest of the suite still passes**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test --tags=golden -r expanded
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden
```

Expected: both PASS. The golden count must equal Task 1 Step 1 — the two migrated goldens still run, just through a different mechanism.

- [ ] **Step 7: Analyze**

```bash
fvm flutter analyze
```

Expected: no new issues. The rewritten test no longer imports `flutter_test` directly or uses `configureTestView` / `getGoldenPath` / `getSampleForGoldenTest`; confirm no unused-import warning appears.

- [ ] **Step 8: Commit**

Show the diff, summarize, wait for explicit user confirmation, then:

```bash
git add packages/flutter_adaptive_cards_fs/test/golden_icon_test.dart \
        packages/flutter_adaptive_cards_fs/test/gold_files/macos
git commit -m "test(cards): migrate golden_icon_test to alchemist"
```

---

### Task 5: Documentation, changelogs, and stray-file cleanup

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/README.md:725`
- Modify: `packages/flutter_adaptive_cards_fs/test/gold_files/README.md`
- Modify: `packages/flutter_adaptive_cards_test_support/CHANGELOG.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`
- Delete: `packages/flutter_adaptive_cards_fs/test/gold_files/linux/v1_6_compound_button copy.png`

**Interfaces:**

- Consumes: the working migration from Task 4
- Produces: nothing consumed by later tasks

- [ ] **Step 1: Remove the stale golden_toolkit line**

`golden_toolkit` is not a dependency of this repo and has not been for some time — it was dropped around commit `dcb412a`. The only surviving trace is prose. Delete this bullet from `packages/flutter_adaptive_cards_fs/README.md` (line 725):

```markdown
- Golden toolkit fonts loaded but it will show black bars for text inside of text fields instead of text if font isn't loaded <https://pub.dev/packages/golden_toolkit>
```

Check whether the surrounding list still reads correctly after removal, and confirm nothing else references it:

```bash
grep -rn "golden_toolkit" --include="*.md" packages/ docs/
```

Expected: no output.

- [ ] **Step 2: Delete the stray baseline**

This file exists only under `linux/` and is an accidental duplicate — Linux carries 42 baselines against macOS's 41, and macOS's 41 matches the cards package's 41 golden assertions exactly.

```bash
git rm "packages/flutter_adaptive_cards_fs/test/gold_files/linux/v1_6_compound_button copy.png"
```

Then confirm parity:

```bash
cd packages/flutter_adaptive_cards_fs/test/gold_files && diff <(cd linux && ls *.png) <(cd macos && ls *.png)
```

Expected: no output.

- [ ] **Step 3: Document both golden mechanisms**

Add this section to `packages/flutter_adaptive_cards_fs/test/gold_files/README.md`, after the intro and before "Creating new golden images":

```markdown
## Two golden mechanisms (migration in progress)

Golden tests are being migrated to [`alchemist`](https://pub.dev/packages/alchemist).
Both mechanisms are live and both write to `test/gold_files/<os>/`, so the layout
and the CI workflow below are identical for either.

- **Alchemist** (`goldenTest(...)`) — static, single-frame goldens. Config lives in
  `flutter_adaptive_cards_test_support`; use `buildCardScenario()` for the widget.
  Alchemist's obscured-text CI mode is **disabled** because this library's goldens
  verify real typography, so real text renders on every host including CI.
- **Raw `matchesGoldenFile`** — interaction sequences that capture several frames
  from one pumped widget (`configureTestView()` + `getGoldenPath()`). Alchemist
  captures one image per test and cannot express these; they migrate in a later
  phase.

When adding a golden: if it is a single static frame, use Alchemist. If it needs to
tap and re-capture, use the raw mechanism.

Note that `goldenTest()` takes `fileName` **without** the `.png` extension — the
configured `filePathResolver` adds the extension and the platform directory.
```

- [ ] **Step 4: Add changelog entries**

To the `## [Unreleased]` section of `packages/flutter_adaptive_cards_test_support/CHANGELOG.md`:

```markdown
- Added `alchemist` golden-testing support: `buildAdaptiveCardsAlchemistConfig()`,
  `adaptiveCardsGoldenTheme`, and `buildCardScenario()`. Alchemist's obscured-text
  CI variant is disabled so goldens render real text on every host; the existing
  `gold_files/<os>/` baseline layout is preserved.
```

To the `## [Unreleased]` section of `packages/flutter_adaptive_cards_fs/CHANGELOG.md`:

```markdown
- Migrated `golden_icon_test.dart` to `alchemist` and regenerated its baselines.
- Removed a stale `golden_toolkit` reference from the README and a duplicate
  Linux golden baseline.
```

If either file has no `## [Unreleased]` section, add one at the top below the title, matching the format of the most recent released section.

- [ ] **Step 5: Format the markdown**

```bash
npx prettier --write "packages/**/*.md"
```

- [ ] **Step 6: Verify nothing broke**

```bash
fvm flutter analyze
cd packages/flutter_adaptive_cards_fs && fvm flutter test --tags=golden -r expanded
```

Expected: analyze clean; goldens PASS. The golden count is now one lower than Task 1 Step 1 only if the deleted PNG had a test — it did not, so the count is unchanged.

- [ ] **Step 7: Commit**

Show the diff, summarize, wait for explicit user confirmation, then:

```bash
git add packages/flutter_adaptive_cards_fs/README.md \
        packages/flutter_adaptive_cards_fs/test/gold_files \
        packages/flutter_adaptive_cards_fs/CHANGELOG.md \
        packages/flutter_adaptive_cards_test_support/CHANGELOG.md
git commit -m "docs: document alchemist golden workflow, drop stale references"
```

---

### Task 6: Seed Linux baselines from CI and evaluate the phase gate

CI has no macOS runner, so Linux baselines must come from a CI run. Until they exist, CI fails on pixel comparison for the two migrated goldens — this is the documented workflow in `gold_files/README.md`, not a defect.

**Files:**

- Regenerate: `packages/flutter_adaptive_cards_fs/test/gold_files/linux/v1_5_icon_demo.png`
- Regenerate: `packages/flutter_adaptive_cards_fs/test/gold_files/linux/v1_6_icon_catalog.png`

**Interfaces:**

- Consumes: everything from Tasks 1–5
- Produces: the go/no-go decision for Phase 2

- [ ] **Step 1: Push the branch and open a PR**

Per the `AGENTS.md` git gate, confirm with the user before pushing. The `test.yml` workflow runs on `pull_request`.

- [ ] **Step 2: Let the golden job fail and collect the artifact**

The "Run adaptive_cards golden tests" step will fail on the two migrated goldens. Download the `adaptive_cards_golden_test_failures` artifact from the failed run (retention 7 days).

- [ ] **Step 3: Inspect the Linux images before trusting them**

Apply the same visual checks as Task 4 Step 3 — real glyphs for both text and icons, no colored blocks, no tofu. Linux font rasterization differs from macOS, so the images will not be byte-identical to the macOS baselines; that is expected. What matters is that they are _correct renderings_.

- [ ] **Step 4: Install the Linux baselines**

Rename each `<name>_testImage.png` to `<name>.png` and copy into `linux/`:

```bash
cp v1_5_icon_demo_testImage.png \
   packages/flutter_adaptive_cards_fs/test/gold_files/linux/v1_5_icon_demo.png
cp v1_6_icon_catalog_testImage.png \
   packages/flutter_adaptive_cards_fs/test/gold_files/linux/v1_6_icon_catalog.png
```

- [ ] **Step 5: Commit and confirm CI is green**

Show the diff, summarize, wait for explicit user confirmation, then:

```bash
git add packages/flutter_adaptive_cards_fs/test/gold_files/linux
git commit -m "test(cards): seed linux baselines for alchemist icon goldens"
```

Push and confirm the full `test.yml` workflow passes: both golden passes, all four coverage passes, and the coverage gate.

- [ ] **Step 6: Evaluate the phase gate**

Phase 2 is gated on this pilot. Record findings against each criterion from the spec:

- [ ] both goldens render real text and real icon glyphs — no tofu, no colored blocks
- [ ] macOS baselines regenerated at unchanged paths under `gold_files/macos/`
- [ ] the `golden` tag still routes them into the golden CI pass and out of the coverage pass
- [ ] Linux baselines landed via one CI artifact round-trip and CI is green
- [ ] `adaptiveCardsGoldenTheme` produced typography consistent with the pre-migration look, or the difference was understood and accepted
- [ ] Alchemist's bundled Roboto did **not** leak into the test bundle (Task 1 Step 4), or the exclusion applied there works

Report the outcome and these two findings, which the Phase 2 plan needs as input:

1. **Theme fidelity** — how much the pinned `ThemeData.light()` differed from the `MaterialApp`-rendered original. If it differed materially, Phase 2 should refine `adaptiveCardsGoldenTheme` before converting 33 more goldens.
2. **Ancestry needs** — whether Alchemist's non-`MaterialApp` bootstrap sufficed. Cards that open dialogs, show-cards, or overlays may need `pumpWidget` to supply `Navigator`/`Overlay`, which changes the Phase 2 task shape.

---

## Final Task: Full verification

Per the `AGENTS.md` plan completion gate, run the full suite — not just targeted tests — and paste output with exit codes and pass/fail counts before claiming completion. Invoke **`superpowers:verification-before-completion`**.

- [ ] **Step 1: Analyze the whole repo**

```bash
fvm flutter analyze
```

- [ ] **Step 2: Run every package suite**

```bash
cd packages/flutter_adaptive_cards_fs   && fvm flutter test --tags=golden -r expanded
cd packages/flutter_adaptive_cards_fs   && fvm flutter test --coverage --exclude-tags=golden
cd packages/flutter_adaptive_charts_fs  && fvm flutter test --tags=golden -r expanded
cd packages/flutter_adaptive_charts_fs  && fvm flutter test --coverage --exclude-tags=golden
cd packages/flutter_adaptive_cards_host_fs && fvm flutter test --coverage --exclude-tags=golden
cd packages/flutter_adaptive_template_fs   && fvm flutter test --coverage --exclude-tags=golden
cd adaptive_explorer && fvm flutter test
```

- [ ] **Step 3: Coverage gate**

```bash
fvm dart run tool/coverage/check_coverage.dart
```

Expected: no package below its floor in `tool/coverage_floors.yaml`. Do not lower a floor to pass — add tests. Migration should be roughly coverage-neutral since golden tests are excluded from measurement.

- [ ] **Step 4: Confirm CI is green** on the PR, then report the phase-gate outcome from Task 6 Step 6.

Do **not** invoke `superpowers:finishing-a-development-branch` or report "plan complete" until every command above passes.

---

## Phases 2 and 3

Deliberately **not** planned here. Phase 2 (33 static goldens, including splitting `golden_sample_test.dart` into static and `golden_sample_interaction_test.dart`) and Phase 3 (14 interaction-sequence goldens, then retiring `configureTestView()` / `getGoldenPath()`) get their own plans written **after** the Task 6 gate.

This is not deferral for its own sake: the Phase 2 task code depends on two things only the pilot can reveal — whether `adaptiveCardsGoldenTheme` reproduces the original typography, and whether Alchemist's bootstrap supplies enough widget ancestry for cards that use dialogs and overlays. Writing those tasks now would mean guessing at both.

See `docs/superpowers/specs/2026-07-29-alchemist-golden-migration-design.md` for the full phase breakdown and the per-test classification of all 49 goldens.
