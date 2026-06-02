# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

## [0.8.0]

### Added 0.8.0

### Changed 0.8.0

- **Scoped dependency injection** now uses nested **`InheritedReferenceResolver`** widgets instead of Riverpod:
  - Outer scope (from `RawAdaptiveCard`): `resolver` (includes `cardTypeRegistry` / `actionTypeRegistry`), `rawAdaptiveCardState` — read via `InheritedReferenceResolver.rawCardScopeOf(context)`.
  - Inner scope (from each `AdaptiveCardElement`): `adaptiveCardElementState` — read via `InheritedReferenceResolver.elementScopeOf(context)`.
- **`ProviderScopeMixin`** unchanged by name; implementations now read the inherited scopes above (no `ref`, `ConsumerWidget`, or app-level `ProviderScope` required).
- Host-facing callbacks remain on **`InheritedAdaptiveCardHandlers`**.
- See [`doc/replace-riverpod.md`](../../doc/replace-riverpod.md) for the migration map from former provider names.

- Updated to Dart SDK 3.12 and Flutter 3.44
- Regenerated golden test images for Flutter 3.44 rendering changes
- Refactored `HostConfig` classes by extracting bundled classes (e.g. from `miscellaneous_configs.dart` and `font_config.dart`) into dedicated individual files under `lib/src/hostconfig/` to improve maintainability.
- Updated `AdaptiveColumn`, `AdaptiveContainer`, and internal utilities to strictly use `ReferenceResolver` as a facade for accessing HostConfig values (e.g. `resolveSpacing()`), removing direct dependencies on underlying config objects like `SpacingsConfig`.
- Created `doc/Architecture-Overview.md` to document system architecture, package structure, internal state management, and extensibility points.
- Consolidated documentation around known gaps and priority issues into `doc/Implementation-Status.md`.
- **`ReferenceResolver`** no longer carries `cardTypeRegistry` or `actionTypeRegistry`. It is a HostConfig/theme facade only. Element and action factories are provided via Riverpod `cardTypeRegistryProvider` and `actionTypeRegistryProvider` (see [`doc/reactive-riverpod.md`](../../doc/reactive-riverpod.md)).
- **`Input.ChoiceSet`** reads effective choices from `resolvedElementProvider` instead of local-only state.
- **`RawAdaptiveCardState.loadInput`** and **`initInput`** delegate to the document notifier (no element-tree walk).
- **`initData`** seeds input overlays via `seedInputValues` post-frame.
- **`resetAllInputs`** clears dynamic `choices` overlays in addition to input values.
- **`ElementOverlay.choices`** — runtime overlay for `Input.ChoiceSet` dynamic option lists; merged via `resolvedElementProvider`.
- Document notifier APIs: `setChoices`, `appendChoices`, `seedInputValues`, `setDataQuerySession`.
- **`DataQuery.count` / `DataQuery.skip`** — spec fields for typeahead pagination.

## [0.7.0]

- Added `selectAction` support to `TableCell` (`AdaptiveTable`), wrapped via `AdaptiveTappable` to enable action handlers when cells are tapped.
- Added full `selectAction` support and tap testing validation on `AdaptiveCardElement`, `AdaptiveContainer`, `AdaptiveColumn`, and `AdaptiveImage` (fixed tap hit-tests using base64 URI elements)..
- change landscape / portrait breakpoint handling for AdaptiveCardElement
- `parseTextString` now accepts an optional `locale` parameter for correct date/time localization.
- `AdaptiveTextBlock` now passes the current `Localizations.maybeLocaleOf(context)` to `parseTextString` for region-aware date/time macro expansion.
- Insured `AdaptiveElementMixin` properly unregisters widgets on `dispose`.
- Fixed `minHeight` parameter parsing and constraint application on `AdaptiveColumn` and `AdaptiveContainer` elements (supporting raw pixel and integer formats).
- Fixed background image aspect-ratio sizing on `AdaptiveColumn` and `AdaptiveContainer` elements when they only contain a `backgroundImage` and have `minHeight` or pixel `width` constraints set, ensuring the other dimension scales dynamically to preserve original image proportions.
- Tests for `Data.Query` ChoiceSet flows: `loadInput` refresh after mount and from
  `onChange`, `setDataQuerySession` merge into resolved `choices.data`, and
  `initData` with `choices.data` (`choice_set_data_query_test.dart`,
  `init_data_overlay_test.dart`, `adaptive_card_document_notifier_test.dart`).

## [0.6.0]

- Bumped versions to 0.6.0 for next development cycle
- Updated to Dart SDK 3.11 and Flutter 3.41
- Removed `uuid` package dependency and replaced it with Flutter's native `UniqueKey()` for widget key generation.
- Removed unused `tinycolor2` package dependency to reduce library footprint.
- Renamed `AdaptiveCardsRoot` to `AdaptiveCardsCanvas`
- Inject `id` attributes into the JSON tree in the `AdaptiveCardsCanvas` so that all objects have ids when not provided. Note that this changes the provided JSON. You can see this in the adaptive_explorer app in the merged tab.
- Fixed `resetInputs()` to correctly clear and revert underlying UI state (text controllers, selectors, etc.) across all `Input` element types.
- Fixed `Input.Time` validation logic which previously rejected valid times. Improved the displayed error message format.
- Fixed Cupertino Time Picker overlay dismissal to pop the modal itself instead of the root navigator.

## [0.5.0]

- version numbers were sync'd to 0.5.0
- Added `ChartColorsConfig` to `HostConfig` to allow custom color palettes for charts.
- Added `ReferenceResolver` with `resolveChartPalette` and `resolveChartColor` methods.
- migrated more hard coded styles to the resolver
- Abstracted `ProviderScope` getter functions into a new `ProviderScopeMixin` away from `AdaptiveElementMixin`.

## [0.4.0] - 2026-04-14

- version numbers were sync'd to the flutter_adaptive_charts_fs 0.4.0

## [0.3.0] - 2026-04-12

- First version to be published on pub.dev out of the freemansoft repo
- Added the adaptive_explorer app
- Set versions on all projects to 0.3.0
- renamed package `flutter_adaptive_cards` to `flutter_adaptive_cards_plus` to avoid pub.dev name collision
- add data query support
- Renamed AdaptiveCard to AdaptiveCardsRoot
- Input field widgets now use the input id as their `ValueKey` (e.g. `ValueKey('myInputId')`)
- Parent/adaptive card keys for inputs use the suffix `_adaptive` (e.g. `ValueKey('${id}_adaptive')`)
- Selector item keys use the format `${id}_${itemKey}` (e.g. `ValueKey('myChoiceSet_Choice 1')`)
- `RawAdaptiveCard.searchList` now accepts an optional `inputId` which is propagated to the choice-filter modal so the modal search field can be keyed and tested.
- Tests and examples were updated to reflect the new keys (non-golden tests updated, new `text_input_test.dart` added).
- **Behavior change:** Non-input adaptive widgets now use `generateAdaptiveWidgetKey()` for their widget keys instead of `generateWidgetKey()`. Update any tests or consumers that relied on the old keys.
- Consumers should update any tests or code that relied on the old `<id>_input` keys to the new naming scheme.
- change name to `flutter_adaptive_cards_fs` to avoid conflict on pub.dev with package published 12/2025
- Added dynamic dark mode support to `RawAdaptiveCard` by listening to `Theme.of(context).brightness`.
- Enabled `verticalContentAlignment` on `AdaptiveContainer`.
- Fixed action `resolveOrientation` to use `ActionsConfig` values from HostConfig.
- Added basic `"fallback": "drop"` support for elements that fail to map or are unknown.
- Added `resolveInputForegroundColor` to `ReferenceResolver` and updated `ChoiceSet` dropdown to use it for better theme-aware coloring.
- Added `{{DATE(timestamp, FORMAT)}}` and `{{TIME(timestamp)}}` macro replacements in `TextBlock` and `FactSet` elements using a new `DateTimeUtils` utility.
- Added `intl` dependency for robust date parsing and localization approximations.
- **Golden Image Reorganization:** Restructured golden images into platform-specific subdirectories (`test/gold_files/linux/`, `test/gold_files/macos/`, etc.).
- **Dynamic Golden Resolution:** Added `getGoldenPath` helper in `test_utils.dart` to automatically select the appropriate golden directory based on the host platform.

## [0.2.1](https://github.com/freemansoft/Flutter-AdaptiveCards/compare/0.20...0.2.1) 2025-09-23

- Converted provider to riverpod 3 9/2025
- Updated libraries major-versions 9/2025
- Ipdated for flutter 3.24 9/2025
- Tested with ios 26 simulator and macos 26.0 9/2025
- Pointed at https microsoft images which causes CORS issue in web example app 9/2025
- Updated to the current Flutter
- Migrating all style into the Resolver so that all AdaptiveCard text styles are mapped there. Future create themeing for this
- Enabling workflow - or at least thinking about it
- Added Accordion, Badge, Carosel, CodeBlock, ProgressBar, ProgressRing, PieChart, BarChart
- Added `fvm` for flutter version management - currently 3.38.5
- BackgroundImage support for Container. Fixed support for fillMode
- Migrated to widgetbook 1.0.0 and deleted example app. This lost the lab and lab_web utilities
- Added hostconfig objects and integrated them and fallback hostconfig into the AdaptiveCard widgets.
- Addeed SVG support for images - but not background images
- Added Inline in-memory image support - png
- All elements have repeatable id values if not specified in the json (hashcode(adaptiveMap))
- Changed action path again (simplified)
- Put provider back in for raw and adaptive card element
- Added keys for the Adaptive cards
- Added calcuated and specified ids
- Added keys to the input fields in the input adaptive cards and atual input widgets for testing
- Migrated the hostconfig from InheritedReferenceResolver to riverpod provider_scope
- Selection applied via AdaptiveTappable to AdaptiveCard Element and Containers
- Add tooltips to actions
- Migrate from flutter_markdown to flutter_markdown_plus as `flutter_markdown` is deprecated
- Add template and data json merge support - Adaptive Cards 1.3
- Updated table support suing LLM

## [0.2.0](https://github.com/freemansoft/Flutter-AdaptiveCards/compare/0.1.2...0.2.0) - 2023-??-??

This is a placeholder until someone figures out how to do the release numbers and do releases.
Mostly because I didn't want this to overlay the 2020 Neohelden version.

### Merged 0.2.0

### Commits 0.2.0
