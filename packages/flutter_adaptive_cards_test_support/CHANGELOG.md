# Changelog

All notable changes to this **unpublished** workspace test package are documented here.

## [Unreleased]

### Changed

- **`getTestWidgetFromMap` / `getTestWidgetFromPath`** accept an optional `onHttp` callback so tests can wire the deprecated/legacy `Action.Http` (`HttpActionInvoke`) handler on `InheritedAdaptiveCardHandlers`.
- **`MyTestHttpOverrides`** accepts an optional `urlResponder` parameter — a `({List<int> bytes, String contentType}) Function(Uri url)?` factory. When provided, it is called for every request and can return a custom response; returning `null` falls back to the default PNG/SVG image stub. Allows tests to simulate JSON card payloads (e.g., for `Action.OpenUrlDialog`) without declaring a bespoke `HttpOverrides` subclass.
- Restored Roboto and RobotoMono italic faces (10 `.ttf` files) to `assets/fonts/Roboto/` for golden tests that use italic styles.
- Roboto golden-test fonts moved to `assets/fonts/Roboto/` and loaded from the test_support package directory (removed cwd-relative `File` loading and `fontsRoot` parameter).

## [0.10.0]

### Added

- Initial **`flutter_adaptive_cards_test_support`** package for shared monorepo widget/golden test infrastructure:
  - **`http_overrides.dart`** — Fake HTTP client and transparent PNG fixture bytes (replaces mockito-based mocks in charts tests when consumers migrate).
  - **`test_widget_helpers.dart`** — `getTestWidgetFromMap`, `getTestWidgetFromPath`, `getTestWidgetFromString` with optional `CardTypeRegistry`, `listView`, and `scrollable` scaffold options.
  - **`golden_helpers.dart`** — `configureTestView`, `getGoldenPath`, `getV16SampleForGoldenTest`, `getSampleForGoldenTest`.
  - **`flutter_test_config.dart`** — `adaptiveCardsTestExecutable` and `loadAdaptiveCardsTestFonts`.
- **README** documenting usage from `flutter_adaptive_cards_fs` and extension packages (e.g. charts via registry wrapper).
- **`getTestWidgetFromMap`** / **`getTestWidgetFromPath`:** optional **`onRefresh`** handler, **`currentUserId`**, and **`supportMarkdown`** for root-card refresh and plain TextBlock tests.
