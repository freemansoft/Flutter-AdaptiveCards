# Changelog

## [0.6.0]

- Bumped versions to 0.6.0 for next development cycle

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
