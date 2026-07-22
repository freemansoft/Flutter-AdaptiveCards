# Changelog

## [Unreleased]

### Changed

- Make `ChartElementOverlayExtension` / `CardChartsRegistry.overlayExtensions`
  `const` now that `ElementOverlayExtension` has a documented `const`
  constructor.

## [0.15.0]

- no changes yet

## [0.14.0]

### Changed 0.14.0

- **Internal cleanup (no behavior change)** — applied `dart format` across the package (`lib/` + `test/`), fixing formatting drift, and re-wrapped 14 over-long `///` doc comments to satisfy the now-enabled `lines_longer_than_80_chars` lint. No API or runtime changes.

## [0.13.0]

### Changed 0.13.0

- **Docs:** README now carries the package's **Implementation status** (per-chart status + property-gap tables, legend, and a chart **Known gaps** note), moved here from the central `docs/Implementation-Status.md` so it is visible on pub.dev.

### Tests 0.13.0

- Added `Chart.Pie` / `Chart.Donut` widget tests (data parsing, `value`/`y` and `legend`/`title`/`x` fallbacks, legend rendering, empty-data, and donut center space) covering the previously-untested `pie_donut_chart.dart`.

## [0.12.0]

### Fixed 0.12.0

- **`Chart.Line` datetime X axis:** ISO date/datetime `x` values now convert to epoch milliseconds instead of collapsing to 0, so time-series points plot in correct order and spacing.

## [0.11.0]

- **`ChartOverlayMixin` / chart widgets:** `ChartOverlayMixin` converted from `on State<T>` to `on ConsumerState<T>`; `AdaptiveBarChart`, `AdaptiveLineChart`, `AdaptivePieChart`, `AdaptiveGaugeChart` converted from `StatefulWidget`/`State` to `ConsumerStatefulWidget`/`ConsumerState`. Internal refactor; no public API changes.
- Removed duplicate `assets/fonts/` tree; golden tests load Roboto from `flutter_adaptive_cards_test_support`.

- **Chart runtime overlays:** **`ChartElementOverlayExtension`** registered via **`CardChartsRegistry.overlayExtensions`**; extension methods on **`RawAdaptiveCardState`** (`setChartData`, `patchChartProperties`, `clearChartData`, …).
- **`ChartOverlayMixin`** + **`AdaptiveVisibilityMixin`** on bar, line, pie/donut, and gauge chart widgets — reactive `data` and chrome patches via `resolvedElementProvider`.
- **`ElementOverlayExtension.overlayPatchKeys`** whitelists chart host patch keys (`data`, `chartProperties`, …).
- Tests: **`test/charts/chart_overlay_test.dart`**, **`test/charts/chart_overlay_notifier_test.dart`**.

## [0.10.0]

- **`Chart.Gauge`:** **`AdaptiveGaugeChart`** and **`GaugePainter`** (`CustomPainter` semicircular gauge) — `value`, `min` / `max`, `segments`, `valueFormat` (`percentage` / `fraction`), `title`, `subLabel`, `showLegend`, `showMinMax`, and `colorSet`.
- **`ChartChrome`:** shared title and legend wrapper used by bar, line, pie, donut, and gauge chart elements.
- **Chart chrome on existing types:** bar, line, pie, and donut charts now render `title`, `xAxisTitle`, `yAxisTitle`, `showBarValues`, `showLegend`, and `colorSet` from element JSON.
- **`CardChartsRegistry`:** registers **`Chart.Gauge`** (replaces prior donut-only placeholder).
- Tests: gauge widget and painter tests; sample JSON **`test/samples/v1.6/chart_gauge.json`**; golden **`test/golden_v1_6_test.dart`** (`v1_6_gauge.png`).
- README: documents **`colorSet`**, Teams semantic color tokens, and chart chrome properties.
- Test harness re-exports **`flutter_adaptive_cards_test_support`** from **`test/utils/test_utils.dart`** with chart-specific **`getChartTestWidget*`** / **`getChartSampleForGoldenTest`** wrappers and **`chartCardTypeRegistry`**.
- **`flutter_test_config.dart`** delegates to shared **`adaptiveCardsTestExecutable`**.
- Removed unused **`mockito`** dev dependency.
- Regenerated linux and macos golden baselines for theme-derived HostConfig color fallbacks.

## [0.9.0]

- Version alignment with `flutter_adaptive_cards_fs` 0.9.0 (`^0.9.0` dependency).

## [0.8.0]

- Updated to Dart SDK 3.12 and Flutter 3.44

## [0.7.0]

- Version alignment and dependency updates for 0.7.0 release.

## [0.6.0]

- Bumped versions to 0.6.0 for next development cycle
- Updated to Dart SDK 3.11 and Flutter 3.41

## [0.5.0] - 2026-04-19

- Added `Chart.HorizontalBar.Stacked` support
- Added `Chart.VerticalBar.Grouped` support
- Fixed bar chart x-axis rendering to show labels instead of indices
- version numbers were sync'd to 0.5.0
- Standardized color resolution using `ReferenceResolver` and `HostConfig`.
- Added support for custom color palettes and default colors via `HostConfig`.
- All chart types now respect semantic color names ('good', 'warning', 'attention', 'accent').

## [0.4.0] - 2026-04-14

- Added horizontal bar chart sample
- Horizontal bar charts now render correctly

## [0.3.0] - 2026-04-12

- Initial release of the split `flutter_adaptive_charts_fs` package for Flutter Adaptive Cards ecosystem.
- **Golden Image Reorganization:** Restructured golden images into platform-specific subdirectories (`test/gold_files/linux/`, `test/gold_files/macos/`, etc.).
- **Dynamic Golden Resolution:** Added `getGoldenPath` helper in `test_utils.dart` to automatically select the appropriate golden directory based on the host platform.
