# Changelog

## [0.13.0]

- Added an **Action.Http** demo use case (Components → Actions): `HttpActionDemoPage` wires `onHttp` to a SnackBar showing the resolved method/url/body/headers after `{{nameInput.value}}` substitution. New sample `lib/samples/action_http/example1.json`. `Action.Http` is the deprecated/legacy original Adaptive Cards HTTP action model (superseded by `Action.Execute`), still used by Outlook Actionable Messages.

## [0.12.0]

- no changes yet

## [0.11.0]

### Sample app plumbing 0.11.0

- **Shared card registry:** [`widgetbook_card_registry.dart`](lib/widgetbook_card_registry.dart) — `widgetbookCardTypeRegistry` (chart elements) and `widgetbookChartOverlayCardTypeRegistry` (+ overlay extensions for the chart overlay demo). Replaces repeated inline `CardTypeRegistry(addedElements: CardChartsRegistry…)` in generic, network, chart knobs, dependent choice set, and overlay pages.
- **Overlay demo scaffold:** [`overlay_demo_scaffold.dart`](lib/overlay_demo_scaffold.dart) — `OverlayDemoPageState` mixin for asset load, post-frame apply scheduling, document-ready retry (30 attempts), and the common `RawAdaptiveCard` shell. All five `*_overlay_page.dart` demos now use it; per-page knob sync and overlay apply logic stay in each page.

### Overlay demo use cases 0.11.0 (Waves 1–3)

- **Charts → Chart overlay (knob):** **[`ChartOverlayPage`](lib/chart_overlay_page.dart)** with **`lib/samples/charts/chart_overlay_demo.json`** — `setChartData` / `patchChartProperties` via **`RawAdaptiveCardState`** (requires **`CardChartsRegistry.overlayExtensions`**).
- **Rating → Rating input overlay (knob):** **[`RatingInputOverlayPage`](lib/rating_input_overlay_page.dart)** with **`lib/samples/inputs/rating_input_overlay_demo.json`** — `applyUpdates` / `setInputError` on **`Input.Rating`** id `demoRating`.
- **Rating → Rating display overlay (knob):** **[`RatingOverlayPage`](lib/rating_overlay_page.dart)** with **`lib/samples/elements/rating_overlay_demo.json`** — slider drives `applyUpdates` on display **`Rating`** id `stars`.

### Other use cases 0.11.0

- **TextBlock → RichTextBlock demo** with sample **`lib/samples/v1.2/rich_text_block_demo.json`**.
- **AdaptiveCard → Refresh** use case: **[`RefreshDemoPage`](lib/refresh_demo_page.dart)** with sample **`lib/samples/v1.4/refresh_demo.json`** — manual refresh affordance logs **`onRefresh`** to a SnackBar.
- **`pubspec.yaml` assets:** registered **`lib/samples/v1.2/`**, **`lib/samples/v1.4/`**, **`lib/samples/elements/`**, and **`lib/samples/charts/`** (as needed per demo JSON).

## [0.10.0]

- Removed unused **`cupertino_icons`** and **`path`** dependencies from `pubspec.yaml`.
- **Icon (v1.5 hub)** use case with sample **`lib/samples/v1.5/icon_demo.json`**.
- **`Chart.Gauge`** sample: **`lib/samples/v1.6/chart_gauge.json`**.
- **Charts** use cases (Donut, Pie, Bar, Line, Gauge, Knobs demo): **[`ChartKnobsPage`](lib/chart_knobs_page.dart)** — live knobs for `title`, axis titles, `showBarValues`, `showLegend`, `colorSet`, gauge fields, and sample data values; uses per-sample **`chartKnobsPageKeyFor`** GlobalKeys so knob edits do not remount the card host.
- Asset bundle: **`lib/samples/charts/`** for chart knob demo JSON.
- **`appBuilder`:** forwards Widgetbook **Material Theme** addon selection to **`MaterialApp`** `theme` / `darkTheme` / `themeMode` so card use cases respect light/dark mode (pairs with **`ThemeColorFallbacks`** in `flutter_adaptive_cards_fs`).

## [0.9.0]

- Added **Input.ChoiceSet → Value changed action (host cascade)** and **Value changed action (Teams Data.Query)** use cases with shared [`lib/dependent_choice_set_demo_page.dart`](lib/dependent_choice_set_demo_page.dart) — demonstrates Teams dependent-input pattern (`valueChangedAction` reset + host `applyUpdates` for country → city)
- Sample JSON: `lib/samples/inputs/input_choice_set/value_changed_action_dependent_query.json` (Teams-shaped `choices.data` on city field)

## [0.8.0]

- Updated to Dart SDK 3.12 and Flutter 3.44
- Migrated to Swift Package Manager from CocoaPods
- Fixed home pane bottom overflow on short windows: `AdaptiveCardsWidgetbookHome` now uses a `SingleChildScrollView` while keeping content vertically centered when it fits
- Added **TextBlock → Text overlay (knob)** use case (`text_overlay_demo.json`, `TextBlockOverlayPage`) demonstrating host `setText` on a `TextBlock`
- **Knob-driven use cases that must keep state:** Widgetbook 3 keys `UseCaseBuilder` with `ValueKey(state.uri)`, so each knob edit changes the URI and remounts the use-case subtree (full card flicker, spinner, debug chrome). Use a module-level `GlobalKey` on the stable host widget—see `textBlockOverlayPageKey` in `lib/text_block_overlay_page.dart`—and read knobs inside that widget’s `build` so only overlay APIs (e.g. `setText`) run on change. Reuse this pattern for other interactive knobs over `RawAdaptiveCard`

## [0.7.0]

- Version alignment and dependency updates for 0.7.0 release.

## [0.6.0]

- Bumped versions to 0.6.0 for next development cycle
- Updated to Dart SDK 3.11 and Flutter 3.41

## [0.5.0] - 2026-04-19

- Added Widgetbook examples for new chart types
- version numbers were sync'd to 0.5.0

## [0.4.0] - 2026-04-14

- version numbers were sync'd to the flutter_adaptive_charts_fs 0.4.0 version
