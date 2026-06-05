# Changelog

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
