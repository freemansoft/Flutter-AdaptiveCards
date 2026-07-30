# Alchemist golden test migration — design

> [!IMPORTANT]
>
> **OBSOLETE — REJECTED, NOT IMPLEMENTED (2026-07-29).**
> This design was completed, reviewed, and then **rejected on the same day** before
> any code was written. Nothing here was implemented; no `alchemist` dependency was
> added. It is retained as a decision record so the migration is not re-proposed.
> **Read [Decision: why we are not doing this](#decision-why-we-are-not-doing-this)
> first** — the technical analysis below it remains accurate and useful, but the
> conclusion it builds toward was overturned.

- **Date:** 2026-07-29
- **Packages:** `flutter_adaptive_cards_test_support`, `flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`
- **Proposed dependency:** [`alchemist`](https://pub.dev/packages/alchemist) `^0.14.0` (Betterment, verified publisher) — **never added**
- **Status:** ❌ **rejected / obsolete** — superseded by the local-helpers direction (see below)

## Decision: why we are not doing this

Four findings, accumulated while writing this design and its implementation plan,
removed the entire rationale for the migration. In order of weight:

**1. Alchemist's headline capability is unavailable to us by construction.**

The reason to adopt Alchemist was one platform-agnostic baseline set instead of the
`linux/` + `macos/` pair. But that single-image property is welded to its CI variant,
and the CI variant achieves platform-agnosticism purely by **suppressing real
rendering**:

- `BlockedTextPaintingContext` replaces every text block with a filled rectangle —
  `canvas.drawRect(offset & child.size, paint)` (`blocked_text_image.dart:37-40`). Its
  own doc comment states it exists "to circumvent font rendering inconsistencies"
  (`:58-62`).
- `applyObscuredFontFamily()` forces the text theme to the Ahem font
  (`utilities.dart:116-120`).
- `renderShadows: false` substitutes opaque colors for shadows.

The directory split is likewise hardcoded per variant: `environmentName` returns the
constant `'CI'` for the CI variant (`alchemist_config.dart:507`) but
`HostPlatform.current().operatingSystem` for the platform variant (`:419`).

This library's goldens exist to verify **typography and icon glyphs** — bold, italic,
font size, HostConfig text styling, `MaterialIcons`. Obscured text erases exactly that
signal, so the CI variant is unusable here. And with real text you get the platform
variant, which writes `goldens/<platform>/` — **identical in shape to what we already
maintain by hand.** There is nothing to gain.

**2. Nothing deprecated was forcing a change.** The task originated as "migrate off
the deprecated `golden_toolkit`", but `golden_toolkit` is not a dependency of this
repo and has not been for some time (see
[Correction to the original framing](#correction-to-the-original-framing)). The
built-in `matchesGoldenFile` from `flutter_test` is first-party, fully supported, and
not deprecated — it is how Flutter's own framework tests work.

**3. Alchemist wraps the built-in comparator rather than replacing it.** It calls
`expectLater(a, matchesGoldenFile(b))` (`golden_test_adapter.dart:40`) and temporarily
swaps in an `AlchemistFileComparator extends LocalFileComparator`
(`alchemist_file_comparator.dart:10`, installed at `golden_test_runner.dart:91-94`,
restored at `:150`). Adopting it is a change of steering wheel, not of engine — so its
remaining benefits are ergonomic only, and reproducible locally.

**4. The cost was high and unavoidable.** Alchemist does not pump a `MaterialApp`
(`golden_test_adapter.dart:308-311`), so **all 49 baselines** would have had to be
regenerated, each Linux baseline requiring its own CI artifact round-trip. It would
also have become a load-bearing dependency for visual regression, required two
coexisting mechanisms across three phases, and left every local helper (font loading,
sample loading, the platform directories) still necessary.

### What we are doing instead

Local helpers on top of the built-in comparator: a thin `adaptiveGoldenTest()` wrapper
that removes the repeated `configureTestView` / `pumpWidget` / `pumpAndSettle` /
`expectLater` ceremony, plus an optional labeled multi-scenario grid widget. Because
the wrapper preserves the existing `MaterialApp` + `Scaffold` + `AppBar` +
`RepaintBoundary` tree, refactored tests produce **byte-identical images** — no
re-baselining, no CI round-trips, no new dependency. That property is self-verifying:
refactor, then run the suite without `--update-goldens`.

**A tolerance comparator was explicitly rejected.** Fine visual detail is what these
goldens exist to catch, so comparison stays at the built-in exact match. This also
means `diffThreshold`, listed under
[Incidental wins](#incidental-wins) below, is a non-goal rather than a benefit
foregone.

### Findings worth keeping

Independent of the rejected mechanism, the results below remain useful:

- The per-test classification of all **49 golden assertions** — 35 static, 14 in
  interaction sequences — in [Migration boundary](#migration-boundary).

Two incidental cleanups this investigation surfaced have since been **completed**, so
they are no longer outstanding:

- ✅ The stale `golden_toolkit` line in `packages/flutter_adaptive_cards_fs/README.md`
  has been removed. `golden_toolkit` is absent from the repo and has been for some
  time; that line was the only surviving trace.
- ✅ `linux/v1_6_compound_button copy.png` has been deleted — a byte-identical
  duplicate (matching MD5) present only on Linux. The Linux and macOS baseline sets
  are now at parity, 41 each, matching the cards package's 41 golden assertions
  exactly.

One further discovery, made after this document was written: card reflow is
**constraint-driven, not view-driven** — `cardWidthBucketProvider` is published from a
`LayoutBuilder` inside a nested `ProviderScope` (`adaptive_card_element.dart:428-435`,
`riverpod/providers.dart:55`). So responsive goldens can vary width per scenario with a
`SizedBox` and do not need separate view sizes, which makes them gridable. The
exception is media elements, which read `MediaQuery.of(context).size.width`
(`cards/elements/media.dart:261`).

---

## Problem

> The remainder of this document is the original design, preserved unchanged for the
> record. Its analysis is accurate; its conclusion was overturned by the decision
> above.

Golden tests in this repo are hand-rolled on raw `matchesGoldenFile` plus local
helpers in `flutter_adaptive_cards_test_support`:

- `configureTestView()` — fixes the test view size
- `getGoldenPath()` — prefixes a platform directory (`gold_files/<os>/`)
- `getSampleForGoldenTest()` / `getTestWidgetFromPath()` — build a
  `MaterialApp` + `Scaffold` + `AppBar` + `RepaintBoundary` around the card
- font loading in `flutter_test_config.dart` via `adaptiveCardsTestExecutable()`

Each golden is an individually authored `testWidgets` + `configureTestView` +
`pumpWidget` + `pumpAndSettle` + `expectLater` block. There is no way to express a
matrix of variants as one reviewable image, and the helper layer is bespoke code
this project maintains itself.

The goal is to adopt a maintained golden-testing package (`alchemist`) to reduce
that boilerplate and enable multi-scenario grids.

### Correction to the original framing

The task was raised as "migrate off the deprecated `golden_toolkit`". **`golden_toolkit`
is not a dependency of this repo and has not been for some time.** Verified:

- zero occurrences across all 9 `pubspec.yaml` files
- absent from `pubspec.lock`
- no test file imports it (`golden_sample_test.dart` imports only `dart:convert`,
  `dart:io`, `flutter/material.dart`, `flutter_adaptive_cards_fs`,
  `src/hostconfig/actions_config.dart`, `flutter_test`, `utils/test_utils.dart`)

`git log -S golden_toolkit` shows historical use around commit `dcb412a` ("Use the
default testing font instead of loading our own Roboto font"), after which it was
dropped. The only surviving trace is a prose line at
`packages/flutter_adaptive_cards_fs/README.md:725`, which this work removes.

Consequences: nothing deprecated is blocking, no pubspec entry needs removing, and
the migration is therefore **elective and incremental** rather than forced.

## Hard constraint: real text

Goldens in this repo exist to verify **rendering and styling** — bold, italic, font
size, HostConfig typography, and `MaterialIcons` glyphs. Alchemist's headline
feature is platform-agnostic CI goldens, achieved by obscuring text into colored
rectangles (`obscureText`). **That mode is unusable here**: it would erase exactly
the signal these tests exist to capture.

This is non-negotiable and drives the configuration in the next section.

## Findings (ground truth)

Verified against `alchemist` 0.14.0 source in the pub cache, not documentation.

### Real-text goldens can run in CI

Alchemist has **no CI detection whatsoever** — no `isRunningInCi`, no environment
variable check anywhere in `lib/`. Variant selection is purely config-driven
(`lib/src/alchemist_test_variant.dart:41-50`):

```dart
final runPlatformTest =
    platformConfig.enabled && platformConfig.platforms.contains(_currentPlatform);
final runCiTest = ciConfig.enabled;
return {if (runPlatformTest) platformConfig, if (runCiTest) ciConfig};
```

So `CiGoldensConfig(enabled: false)` plus a `platforms` set containing Linux makes
real-text platform goldens the only variant, on every machine including the CI
runner. `PlatformGoldensConfig.obscureText` already defaults to `false`
(`lib/src/alchemist_config.dart:411`).

### Existing directory layout is preservable

`PlatformGoldensConfig.environmentName` is `HostPlatform.current().operatingSystem`
(`lib/src/alchemist_config.dart:419`), which returns `'macOS'` / `'Linux'`
(`lib/src/host_platform.dart:51,56`). The default resolver lowercases it. A one-line
`filePathResolver` therefore reproduces the current `gold_files/<os>/<name>.png`
layout exactly — **no baseline directory restructuring, no path churn.**

### Alchemist does not use MaterialApp

Alchemist pumps its own bootstrap widget rather than `MaterialApp`, deliberately
(`lib/src/golden_test_adapter.dart:308-311`: "Using `MaterialApp` may introduce
unexpected behavior in tests"). It falls back to `ThemeData.light()` when no theme
is configured.

**Consequence: every migrated golden must be re-baselined.** The current baselines
were captured inside a real `MaterialApp` + `Scaffold` + `AppBar(title: Text(path))`;
migrated images lose the AppBar and render under a different bootstrap. This is
unavoidable and is the dominant cost of the migration.

### Incidental wins

- `stripTextPackages` supersedes the hand-rolled `_deriveFontFamily()` regex in
  `flutter_test_config.dart`, which strips the `packages/<name>/` prefix from
  packaged font families (the `MaterialIcons` tofu-box fix).
- `diffThreshold` (per-config, `0.0 <= t < 1.0`) can absorb Linux↔macOS
  rasterization differences. Today any sub-pixel difference fails CI and forces the
  download-artifact-and-rename workflow in `gold_files/README.md`.
- Font loading stays entirely ours, in `setUpAll` — Alchemist neither provides nor
  interferes with it.

## Migration boundary

Alchemist's `goldenTest()` captures **one image per test**, with `whilePerforming`
for at most a single gesture during capture. The suite divides on that line — not on
file boundaries, but per test.

**Full inventory: 49 golden assertions** (41 in `flutter_adaptive_cards_fs`, 8 in
`flutter_adaptive_charts_fs`).

| File                                               | Goldens | Gestures | Interleaved `expect` | Classification                      |
| -------------------------------------------------- | ------- | -------- | -------------------- | ----------------------------------- |
| `cards/golden_icon_test.dart`                      | 2       | 0        | 0                    | static                              |
| `cards/golden_area_grid_test.dart`                 | 2       | 0        | 0                    | static                              |
| `cards/golden_authentication_signin_test.dart`     | 1       | 0        | 0                    | static                              |
| `cards/golden_container_style_alignment_test.dart` | 1       | 0        | 0                    | static                              |
| `cards/golden_rich_text_block_test.dart`           | 1       | 0        | 0                    | static                              |
| `cards/golden_responsive_flow_test.dart`           | 4       | 0        | 0                    | static                              |
| `charts/golden_v1_6_test.dart`                     | 8       | 0        | 0                    | static                              |
| `cards/golden_input_text_regex_test.dart`          | 1       | 1        | 0                    | pre-capture state                   |
| `cards/golden_v1_6_test.dart`                      | 9       | 1        | 1                    | mixed (8 static, 1 sequence)        |
| `cards/golden_sample_test.dart`                    | 20      | 9        | 9                    | mixed (7 static, 13 in 4 sequences) |

**`golden_sample_test.dart` straddles the boundary**, which is why it is split
rather than migrated wholesale:

| Test                         | Goldens | Taps | Classification                  |
| ---------------------------- | ------- | ---- | ------------------------------- |
| Golden Sample 3              | 1       | 0    | static                          |
| Golden Sample 4              | 1       | 0    | static                          |
| Golden Sample 14             | 1       | 0    | static                          |
| Golden Table 1               | 1       | 0    | static                          |
| Golden Sample Table 2        | 1       | 0    | static                          |
| Golden Table 3 widths        | 1       | 0    | static                          |
| Golden Table Rounded Corners | 1       | 0    | static                          |
| Golden Sample 1              | 3       | 2    | sequence                        |
| Golden Sample 2              | 3       | 2    | sequence                        |
| Golden Sample 2 Vertical     | 3       | 2    | sequence (custom `HostConfigs`) |
| Golden Sample 5              | 4       | 3    | sequence                        |

A **sequence** is a state machine: capture → `expect` → tap → capture → tap →
capture, all from one pumped widget (`golden_sample_test.dart:12-48` is the
clearest example). Alchemist cannot express this in one test; each frame becomes a
separate `goldenTest()` that re-pumps the card and re-drives it to the target state
via `pumpBeforeTest`, and the interleaved `expect()` assertions must be relocated.

Sequences are therefore migrated **last** (phase 3), after the mechanism is proven
on simpler cases. Two mechanisms coexist during phases 1–2; raw `matchesGoldenFile`
is fully retired at the end of phase 3.

## Design

### 1. Configuration

Alchemist config is installed in the shared test bootstrap so all packages inherit
it, alongside the existing font loading:

```dart
Future<void> adaptiveCardsTestExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    HttpOverrides.global = MyTestHttpOverrides();
    await loadAdaptiveCardsTestFonts();   // unchanged — Roboto family
    await loadBundledTestFonts();         // unchanged — MaterialIcons
  });

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: adaptiveCardsGoldenTheme,
      // Styling IS the thing under test: bold, italic, and font size must render
      // as real glyphs. Alchemist's CI variant obscures text into colored blocks,
      // so it is disabled outright and platform goldens run on every host.
      ciGoldensConfig: const CiGoldensConfig(enabled: false),
      platformGoldensConfig: PlatformGoldensConfig(
        platforms: {HostPlatform.macOS, HostPlatform.linux},
        filePathResolver: (fileName, environmentName) =>
            'gold_files/${environmentName.toLowerCase()}/$fileName.png',
      ),
    ),
    run: testMain,
  );
}
```

`AlchemistConfig.runWithConfig` is a `runZoned` with zone values
(`lib/src/alchemist_config.dart:158-163`); because `testMain` is invoked inside that
zone, `goldenTest()` declarations resolve the config correctly.

`diffThreshold` is deliberately **left at its default `0.0`** for phases 1–2, so the
migration changes exactly one variable — the test mechanism — and not the comparison
tolerance. Raising it to absorb Linux↔macOS rasterization noise is evaluated in
phase 3, once there is evidence of how much variance Alchemist-rendered goldens
actually exhibit.

`adaptiveCardsGoldenTheme` is **load-bearing**: it must pin whatever `ThemeData` the
current `MaterialApp`-based helpers resolve to, or migrated goldens drift in
typography for reasons unrelated to library code. It lives in
`flutter_adaptive_cards_test_support` so cards and charts share one definition.

### 2. Scenario builder

Migrated tests need a bare-card builder — no `MaterialApp`, `Scaffold`, `AppBar`,
or `RepaintBoundary`, since Alchemist supplies containment, theming, and capture:

```dart
Widget buildCardScenario({
  required String path,
  HostConfigs? hostConfigs,
  CardTypeRegistry cardTypeRegistry = const CardTypeRegistry(),
  Map? initData,
  bool supportMarkdown = true,
  String samplesDirectory = 'test/samples',
});
```

It shares JSON loading with the existing `getTestWidgetFromPath` but returns only
`AdaptiveCardsCanvas.map(...)`. `AdaptiveCardsCanvas` installs its own
`ProviderScope`, so no additional wrapper is required. `showDebugJson: false` is
retained.

The existing `getTestWidgetFromMap` / `getTestWidgetFromPath` helpers remain — they
still serve non-golden widget tests and the not-yet-migrated sequences.

### 3. Grid consolidation

Applied only where a matrix is the natural unit of review:

- `golden_responsive_flow_test.dart` — narrow/wide × flow/column (4 goldens)
- the four table tests from `golden_sample_test.dart` (`table1`, `table2`,
  `table3_widths`, `table_rounded_corners`)
- `golden_container_style_alignment_test.dart`

Grids reduce baseline count but produce large images; consolidation is a per-case
judgment during implementation, not a blanket rule. Vestigial trailers such as
`await tester.pump(const Duration(seconds: 1))` drop out.

## Phases

### Phase 1 — pilot: `cards/golden_icon_test.dart`

Chosen because it is 2 goldens, zero interaction, and exercises **both** font paths
(Roboto text and `MaterialIcons` glyphs) — precisely the fidelity risk.

Scope: add the `alchemist` dev dependency, `adaptiveCardsGoldenTheme`, the
`AlchemistConfig` bootstrap, `buildCardScenario()`, and convert the two goldens.

Exit criteria:

- both goldens render real text and real icon glyphs — no tofu boxes, no colored blocks
- macOS baselines regenerate at unchanged paths under `gold_files/macos/`
- the `golden` tag still routes them into the golden CI pass and out of the coverage pass
- Linux baselines land via one CI artifact round-trip and CI is green

**Phase 2 is gated on phase 1 passing.**

### Phase 2 — static goldens

All remaining static tests (33 goldens: 35 static total, less the 2 from phase 1):

1. Split `golden_sample_test.dart`: 7 static tests stay in `golden_sample_test.dart`
   and move to Alchemist; the 4 sequences move verbatim into
   `golden_sample_interaction_test.dart`, still on raw `matchesGoldenFile`.
2. Migrate `golden_area_grid_test.dart`, `golden_authentication_signin_test.dart`,
   `golden_container_style_alignment_test.dart`, `golden_rich_text_block_test.dart`,
   `golden_responsive_flow_test.dart`, and `charts/golden_v1_6_test.dart`.
3. Migrate `golden_input_text_regex_test.dart` — its single `enterText` becomes
   pre-capture state via `pumpBeforeTest`.
4. Migrate the 8 static goldens in `cards/golden_v1_6_test.dart`; its one sequence
   moves to a sibling `golden_v1_6_interaction_test.dart`, keeping file provenance
   clear rather than mixing it into the sample interaction file.
5. Apply grid consolidation per section 3.
6. Delete `linux/v1_6_compound_button copy.png` — a stray duplicate present only on
   Linux (Linux has 42 baselines, macOS 41; macOS's 41 matches the 41 cards-package
   golden assertions exactly).

### Phase 3 — interaction sequences

Migrate all 14 sequence goldens — 13 in `golden_sample_interaction_test.dart` plus 1
in `golden_v1_6_interaction_test.dart` — to Alchemist: one `goldenTest()` per frame,
each re-pumping and driving to its state via `pumpBeforeTest` / `whilePerforming`.
Relocate the interleaved `expect()` assertions into dedicated non-golden widget
tests, where they belong and where they count toward coverage.

Then remove the now-dead raw-golden helpers (`configureTestView()`,
`getGoldenPath()`) from `flutter_adaptive_cards_test_support`, and consider whether
`_deriveFontFamily()` is still needed given `stripTextPackages`.

## Verification

Per `AGENTS.md`, each phase runs:

```bash
# Repo root
fvm flutter analyze

# Golden pass (per affected package)
cd packages/flutter_adaptive_cards_fs
fvm flutter test --tags=golden

# Non-golden pass
fvm flutter test --exclude-tags=golden

# Coverage gate (repo root, after --coverage)
fvm dart run tool/coverage/check_coverage.dart
```

Baseline regeneration uses `--update-goldens --tags=golden`, then the Linux
seeding/artifact workflow in `gold_files/README.md`.

Coverage note: golden tests are excluded from the coverage gate, so migration should
be roughly coverage-neutral. Phase 3 moving `expect()` assertions out of golden tests
into non-golden widget tests should _raise_ measured coverage.

## Documentation impact

- `packages/flutter_adaptive_cards_fs/README.md:725` — remove the stale
  `golden_toolkit` line
- `gold_files/README.md` (both packages) — document the Alchemist workflow; during
  phases 1–2 document both mechanisms and which tests use which
- `docs/testing-coverage.md` — only if tagging or the coverage pass changes
- `CHANGELOG.md` `## [Unreleased]` for every package with changed files:
  `flutter_adaptive_cards_test_support`, `flutter_adaptive_cards_fs`,
  `flutter_adaptive_charts_fs`

No canonical architecture docs are affected: no Riverpod provider, mixin contract,
HostConfig section, or element contract changes. The architecture documentation sync
gate does not trigger.

## Non-goals

- Alchemist's CI / obscured-text mode — incompatible with the real-text constraint
- Collapsing to a single platform-agnostic baseline set; `gold_files/<os>/` stays
- Changing any non-golden widget test
- Adding Windows to the `platforms` set (no Windows CI runner exists)
- Restructuring baseline directories or renaming existing golden files

## Risks

| Risk                                                                                                                            | Mitigation                                                                                                                                                                    |
| ------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Theme mismatch shifts typography in migrated goldens for non-library reasons                                                    | Pin `adaptiveCardsGoldenTheme` to the current `MaterialApp`-resolved theme; the phase 1 pilot surfaces this on 2 images rather than 49                                        |
| Alchemist's non-`MaterialApp` bootstrap lacks ancestry some cards need (`Navigator`/`Overlay` for dialogs, show-card, overlays) | Phase 1–2 cover only static cards; phase 3 evaluates per test and may use `pumpWidget` to supply the missing ancestry, or keep specific tests raw                             |
| Linux re-baselining requires a CI artifact round-trip per phase                                                                 | Batch per phase, not per test; evaluate `diffThreshold` to reduce future churn                                                                                                |
| `alchemist` is a small package (160 pub points, ~4-month-old release) becoming load-bearing for visual regression               | Boundary is confined to test-support helpers; raw `matchesGoldenFile` remains available as the escape hatch, and `gold_files/` layout is unchanged so reverting is mechanical |
