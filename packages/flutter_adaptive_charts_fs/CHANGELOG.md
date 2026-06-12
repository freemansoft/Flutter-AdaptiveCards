# Changelog

## [0.11.0]

- no changes yet

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
