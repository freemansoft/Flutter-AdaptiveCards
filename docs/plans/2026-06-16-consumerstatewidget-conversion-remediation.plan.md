# Plan: Complete ConsumerStatefulWidget Conversion

**Branch:** `refactor/replace-containerOf-listen-with-consumer-stateful-widget`  
**Date:** 2026-06-16  
**Status:** Complete

## Background

`AdaptiveVisibilityMixin` and `AdaptiveActionStateMixin` were updated from
`on State<T>` to `on ConsumerState<T>` so they can call `ref.watch()` directly.
This cascades: every widget that mixes in `AdaptiveVisibilityMixin` must now
extend `ConsumerStatefulWidget`/`ConsumerState` instead of `StatefulWidget`/`State`.

Additionally `bar_chart.dart` was converted but is missing the `flutter_riverpod`
import, causing the compiler to interpret `ConsumerStatefulWidget` as unknown
and emit a cascade of false errors.

---

## Scope of Changes

### A. Fix `bar_chart.dart` missing import

**File:** `packages/flutter_adaptive_charts_fs/lib/src/charts/bar_chart.dart`  
**Change:** Add `import 'package:flutter_riverpod/flutter_riverpod.dart';`  
**Status:** [ ] todo

### B. Convert container widgets (5 files)

Each: `StatefulWidget` → `ConsumerStatefulWidget`, `State<T>` → `ConsumerState<T>`,
add `import 'package:flutter_riverpod/flutter_riverpod.dart';`

| File                                       | Status   |
| ------------------------------------------ | -------- |
| `lib/src/cards/containers/column.dart`     | [x] done |
| `lib/src/cards/containers/column_set.dart` | [x] done |
| `lib/src/cards/containers/container.dart`  | [x] done |
| `lib/src/cards/containers/image_set.dart`  | [x] done |
| `lib/src/cards/containers/table.dart`      | [x] done |

### C. Convert element widgets (9 files)

Same three-line change per file.

| File                                          | Status   |
| --------------------------------------------- | -------- |
| `lib/src/cards/elements/accordion.dart`       | [x] done |
| `lib/src/cards/elements/action_set.dart`      | [x] done |
| `lib/src/cards/elements/carousel.dart`        | [x] done |
| `lib/src/cards/elements/code_block.dart`      | [x] done |
| `lib/src/cards/elements/compound_button.dart` | [x] done |
| `lib/src/cards/elements/icon.dart`            | [x] done |
| `lib/src/cards/elements/progress_bar.dart`    | [x] done |
| `lib/src/cards/elements/progress_ring.dart`   | [x] done |
| `lib/src/cards/elements/tab_set.dart`         | [x] done |

### D. Convert remaining chart widgets (3 files)

`StatefulWidget` → `ConsumerStatefulWidget`, `State<T>` → `ConsumerState<T>`,
add `import 'package:flutter_riverpod/flutter_riverpod.dart';`,
add `listenForChartOverlayChanges();` at top of `build()`.

| File                                                                      | Status   |
| ------------------------------------------------------------------------- | -------- |
| `packages/flutter_adaptive_charts_fs/lib/src/charts/line_chart.dart`      | [x] done |
| `packages/flutter_adaptive_charts_fs/lib/src/charts/pie_donut_chart.dart` | [x] done |
| `packages/flutter_adaptive_charts_fs/lib/src/charts/gauge_chart.dart`     | [x] done |

### E. Cleanup & fixes

| Task                                                                                                                                            | Status   |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `fact_set.dart` — remove unused `import 'package:flutter/foundation.dart';`                                                                     | [x] done |
| `test/elements/image_overlay_test.dart` — remove `url` field access (field removed from `AdaptiveImageState`; provider assertion is sufficient) | [x] done |

### F. Changelogs

| File                                                                                   | Status   |
| -------------------------------------------------------------------------------------- | -------- |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md` — document widget conversions        | [x] done |
| `packages/flutter_adaptive_charts_fs/CHANGELOG.md` — document chart widget conversions | [x] done |

### G. Visibility overlay tests for converted widgets (13 files, 28 tests)

All 14 structural/container widgets converted in B–C had no overlay tests.
Tests written in `packages/flutter_adaptive_cards_fs/test/`:

| Test file                                                    | Widget                                | Approach                        | Status   |
| ------------------------------------------------------------ | ------------------------------------- | ------------------------------- | -------- |
| `test/containers/column_visibility_overlay_test.dart`        | `AdaptiveColumn`, `AdaptiveColumnSet` | `find.text`                     | [x] done |
| `test/containers/container_visibility_overlay_test.dart`     | `AdaptiveContainer`                   | `find.text`                     | [x] done |
| `test/containers/image_set_visibility_overlay_test.dart`     | `AdaptiveImageSet`                    | `Visibility.visible` (`.first`) | [x] done |
| `test/containers/table_visibility_overlay_test.dart`         | `AdaptiveTable`                       | `find.text`                     | [x] done |
| `test/elements/accordion_visibility_overlay_test.dart`       | `AdaptiveAccordion`                   | `find.text`                     | [x] done |
| `test/elements/action_set_visibility_overlay_test.dart`      | `ActionSet`                           | `Visibility.visible` (`.first`) | [x] done |
| `test/elements/carousel_visibility_overlay_test.dart`        | `AdaptiveCarousel`                    | `Visibility.visible` (`.first`) | [x] done |
| `test/elements/code_block_visibility_overlay_test.dart`      | `AdaptiveCodeBlock`                   | `Visibility.visible` (`.first`) | [x] done |
| `test/elements/compound_button_visibility_overlay_test.dart` | `AdaptiveCompoundButton`              | `find.text`                     | [x] done |
| `test/elements/icon_visibility_overlay_test.dart`            | `AdaptiveIcon`                        | `Visibility.visible` (`.first`) | [x] done |
| `test/elements/progress_bar_visibility_overlay_test.dart`    | `AdaptiveProgressBar`                 | `Visibility.visible` (`.first`) | [x] done |
| `test/elements/progress_ring_visibility_overlay_test.dart`   | `AdaptiveProgressRing`                | `Visibility.visible` (`.first`) | [x] done |
| `test/elements/tab_set_visibility_overlay_test.dart`         | `AdaptiveTabSet`                      | `find.text`                     | [x] done |

Each file has two tests: static `isVisible: false` in JSON, and dynamic `setVisibility()` toggle.
The `.first` approach is required on widgets whose subtree contains other `AdaptiveVisibilityMixin`
widgets (images inside ImageSet, TextBlocks inside Carousel), each of which also emits a `Visibility`.

### H. Verification

| Task                                                                      | Status   |
| ------------------------------------------------------------------------- | -------- |
| `fvm flutter analyze` — zero errors                                       | [x] done |
| `fvm flutter test` in `flutter_adaptive_cards_fs` — 485 passed, 2 skipped | [x] done |
| `fvm flutter test` in `flutter_adaptive_charts_fs`                        | [x] done |
| `grep -rn "containerOf"` confirms only expected usages remain             | [x] done |

---

## Changelog entries (draft)

**`packages/flutter_adaptive_cards_fs/CHANGELOG.md`**

```
## [Unreleased]

### Changed
- Container and element widgets (`AdaptiveColumn`, `AdaptiveColumnSet`,
  `AdaptiveContainer`, `AdaptiveImageSet`, `AdaptiveTable`, `AdaptiveAccordion`,
  `ActionSet`, `AdaptiveCarousel`, `AdaptiveCodeBlock`, `AdaptiveCompoundButton`,
  `AdaptiveIcon`, `AdaptiveProgressBar`, `AdaptiveProgressRing`, `AdaptiveTabSet`)
  converted from `StatefulWidget`/`State` to `ConsumerStatefulWidget`/`ConsumerState`
  so they satisfy the `AdaptiveVisibilityMixin` constraint (now requires `ConsumerState`).
  Internal change; no public API surface changes.
```

**`packages/flutter_adaptive_charts_fs/CHANGELOG.md`**

```
## [Unreleased]

### Changed
- `AdaptiveLineChart`, `AdaptivePieChart`, `AdaptiveGaugeChart` converted from
  `StatefulWidget`/`State` to `ConsumerStatefulWidget`/`ConsumerState` to satisfy
  `ChartOverlayMixin` and `AdaptiveVisibilityMixin` constraints.
  Internal change; no public API surface changes.
```

---

## Expected `containerOf` survivors after completion

```
flutter_raw_adaptive_card.dart   — intentional public API
default_actions.dart             — non-widget action callbacks (Group B)
reset_inputs_executor.dart       — non-widget action callback (Group B)
additional.dart                  — stable styleReferenceResolverProvider reads (Group C, deferred)
utils/utils.dart                 — same (Group C, deferred)
```
