# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- `Input.Date` `initData` / `initInput` seeding: controller no longer receives placeholder text; submit and overlay values use `yyyy-MM-dd` per spec. Hosts that relied on ISO-8601 in `onChange` callbacks should expect `yyyy-MM-dd` instead.

## [0.10.0]

### Added 0.10.0

- Public exports for **`Choice`**, **`Fact`**, and **`MediaSource`** from `flutter_adaptive_cards_fs.dart`.
- List parse helpers: `choicesFromJsonList` / `choicesToJsonList`, `factsFromJsonList`, `mediaSourcesFromJsonList`.
- Runtime **`facts`** overlay on `FactSet` elements (`setFacts`, `clearFacts`, `applyUpdates` / `applyUpdatesFromMap`).
- Widgetbook **FactSet → Facts overlay (knob)** demo for interactive overlay testing.

### Changed 0.10.0

- **`ChildStyler`** implements container style and horizontal-alignment inheritance via nested `styleReferenceResolverProvider` overrides.
- **`ReferenceResolver.resolveTextBlockStyle()`**, **`resolveImageIsPerson()`**, and **`resolveEffectiveHorizontalAlignment()`**.
- **`AdaptiveCardBrightnessMode`** (`auto` / `light` / `dark`) on `RawAdaptiveCard` and `AdaptiveCardsCanvas`.
- Style inheritance diagrams in [`docs/adaptive-style.md`](../../docs/adaptive-style.md#style-inheritance-data-flow).
- Tests: `test/style/inheritance_test.dart`.
- **`ElementOverlay.choices`** now stores `List<Choice>` internally; resolved element JSON still exposes `choices` as maps for widget compatibility.
- **`Input.ChoiceSet`** filtered modal uses **`Choice`** instead of internal **`SearchModel`**.
- **`AdaptiveFactSet`** and **`AdaptiveMedia`** parse child lists via shared typed helpers.
- Container **background** uses only each element's own `style`; foreground palette uses **`inheritedContainerStyle`** from ancestors.
- **`TextBlock`** applies HostConfig `TextStylesConfig` for `heading` / `columnHeader`; table header rows use `columnHeader` defaults.
- **`Image`** `person` clipping applies only when `style` is `person` (not other style names).
- Theme brightness changes re-resolve styles via brightness-keyed root `ProviderScope`.

## [0.9.0]

### Added 0.9.0

- Filtered `Input.ChoiceSet` modal lists and typeahead search; choice **titles** drive search while submit, `onChange`, and `Data.Query` use choice **values**.
- Dependent `Input.ChoiceSet` support via `valueChangedAction` and host-driven `applyUpdates` / `Data.Query` cascade.
- **`OpenUrlActionInvoke`**, **`OpenUrlDialogActionInvoke`**, and **`InputChangeInvoke`** public models exported from `flutter_adaptive_cards_fs.dart`.
- Tests: `test/actions/open_url_action_invoke_test.dart`, `test/actions/open_url_dialog_action_invoke_test.dart`.

### Changed 0.9.0

- **`onSubmit`** now receives **`SubmitActionInvoke`** instead of a bare `Map`. Use `invoke.actionId` and `invoke.data` (merged action `data` + input values).
- **`onExecute`** now receives **`ExecuteActionInvoke`** instead of a bare `Map`. Use `invoke.verb`, `invoke.actionId`, and `invoke.data`.
- **`GenericExecuteAction.tap`** no longer takes a separate `verb` argument; read action metadata from `adaptiveMap` in custom implementations (or delegate to `ExecuteActionInvoke.fromActionMap`).
- **`onOpenUrl`** now receives **`OpenUrlActionInvoke`** (`url`, optional `actionId`) instead of a bare `String`.
- **`onOpenUrlDialog`** now receives **`OpenUrlDialogActionInvoke`** (`url`, optional `actionId`) instead of a bare `String`.
- **`onChange`** now receives **`InputChangeInvoke`** (`inputId`, `value`, `dataQuery`, `cardState`) instead of four separate parameters.
- **`AdaptiveCardsCanvas.onChange`** and **`RawAdaptiveCard.onChange`** use the same **`InputChangeInvoke`** type.
- Fixed semantic binding error when dismissing the filtered ChoiceSet modal panel (clear control separated from `InputDecoration.suffix`).

### Removed

- Unused **`onSubmit`**, **`onExecute`**, and **`onOpenUrl`** fields on **`AdaptiveCardsCanvasState`**. Use **`InheritedAdaptiveCardHandlers`** for Submit, Execute, and OpenUrl callbacks.

## [0.8.0]

- Migrated all modifyable state to be reactive using riverpod via overlay on top of adaptive card json: [ElementOverlay and ActionOverlay](lib/src/riverpod/adaptive_card_document.dart)
  - Elements value, error messages, error state, isVisble and many other attributes
  - Actions isEnabled and other attributes
- Implemented regex validation in input field
- Added AI skills flutter and dart provided by flutter and dart teams.
- Added AI superpowers

### Added 0.8.0

- **`AdaptiveElementUpdate`** / **`AdaptiveActionUpdate`** and bulk **`applyUpdates`** / **`applyUpdatesFromMap`** on the document notifier and **`RawAdaptiveCardState`**.
- **`ElementOverlay.isRequired`** and **`ElementOverlay.url`**; **`AdaptiveInputMixin`** listens for resolved `isRequired`; **`AdaptiveImage`** listens for resolved `url`.
- **Tier 3 overlays:** **`label`**, **`placeholder`** on inputs; **`title`**, **`tooltip`** on actions; merged via **`applyUpdates`** / **`applyUpdatesFromMap`**; **`AdaptiveInputMixin`** and **`AdaptiveActionStateMixin`** update UI reactively.
- **`initData`** supports scalar values or per-id patch maps; **`seedInputValues`** delegates to **`applyUpdates`** (single revision).
- Default **Submit** / **Execute** required-field checks use resolved **`isRequired`** (overlay ?? baseline).
- **`Input.Text`** **`regex`** validation (AC 1.3): pattern checked on field blur and on **Submit** / **Execute** via shared **`textInputValueIsValid`**; invalid values set **`isInvalid`** and show **`errorMessage`**.
- Tests: `test/riverpod/apply_updates_test.dart`, `test/inputs/cascade_choice_set_test.dart`, `test/inputs/is_required_overlay_test.dart`, `test/elements/image_url_overlay_test.dart`, `test/actions/submit_required_overlay_test.dart`.
- Tests: `test/inputs/input_text_validation_test.dart`, `test/inputs/input_text_regex_test.dart`, `test/golden_input_text_regex_test.dart` (sample `test/samples/ac-qv-event.json`).
- Design spec: [`docs/superpowers/specs/2026-06-03-dynamic-property-updates-design.md`](../../docs/superpowers/specs/2026-06-03-dynamic-property-updates-design.md).
- **`resetInput(id)`** on the document notifier and **`RawAdaptiveCardState`**; **`AdaptiveInputMixin.resetInput()`** delegates to the notifier.
- Factory reset clears input overlays including **`label`**, **`placeholder`**, and **`isRequired`** (resolved → baseline JSON). See [`docs/reactive-riverpod.md`](../../docs/reactive-riverpod.md#reset-semantics).
- Design spec: [`docs/superpowers/specs/2026-06-03-overlay-reset-semantics-design.md`](../../docs/superpowers/specs/2026-06-03-overlay-reset-semantics-design.md).
- **`Action.ResetInputs`** **`targetInputIds`**: reset only listed input ids; omitted property resets all inputs; empty array resets nothing. Shared executor used by action button tap and input **`valueChangedAction`**.
- **`valueChangedAction`** on **`Input.*`**: when the user changes a field, runs embedded **`Action.ResetInputs`** (e.g. dependent ChoiceSet / country–city). Discrete inputs fire immediately; **`Input.Text`** / **`Input.Number`** fire on focus loss or editing complete, not each keystroke.
- Document notifier **`resetInputs(List<String> ids)`** — batch factory reset in one revision (same overlay rules as **`resetInput(id)`**).
- Sample `test/samples/action_reset_inputs_targeted.json`; tests for targeted reset and **`valueChangedAction`**; Widgetbook **`Actions.Reset (targeted)`** use case.
- Design spec: [`docs/superpowers/specs/2026-06-04-action-resetinputs-targetinputids-design.md`](../../docs/superpowers/specs/2026-06-04-action-resetinputs-targetinputids-design.md).

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
- **`resetAllInputs`** / **`resetInput(id)`** factory-reset input overlays to baseline (value, choices, validation, **`isRequired`**, **`label`**, **`placeholder`**); preserve input `isVisible` and typeahead session fields only.
- **`ElementOverlay.choices`** — runtime overlay for `Input.ChoiceSet` dynamic option lists; merged via `resolvedElementProvider`.
- Document notifier APIs: `setChoices`, `appendChoices`, `seedInputValues`, `setDataQuerySession`.
- **`DataQuery.count` / `DataQuery.skip`** — spec fields for typeahead pagination.
- **`ActionOverlay`** and `actionOverlaysById` on `AdaptiveCardDocument` for AC 1.5 action `isEnabled`.
- **`resolvedActionProvider(id)`** — merged baseline + action overlay map for `Action.*` nodes.
- Document notifier: `setInputError`, `clearInputError`, `setActionEnabled`, `setActionsEnabled`.
- **`ElementOverlay.errorMessage`** and **`ElementOverlay.isInvalid`** merged via `resolvedElementProvider`.
- **`AdaptiveActionStateMixin`** — reactive `isEnabled` for `IconButtonAction` and `Action.ShowCard`.
- Host helpers on **`RawAdaptiveCardState`**: `setInputError`, `clearInputError`, `setActionEnabled`.
- **`ElementOverlay.text`** — runtime replacement of `TextBlock` `"text"`; merged via `resolvedElementProvider`.
- Document notifier: `setText`, `clearText`; **`AdaptiveTextBlock`** listens for resolved `text`.
- Host helpers: **`RawAdaptiveCardState.setText`** / **`clearText`**.
- Tests: `test/elements/text_block_text_overlay_test.dart`.
- Tests: `test/inputs/input_error_overlay_test.dart`, `test/actions/action_enabled_overlay_test.dart`, sample `test/samples/v1.5/action_is_enabled.json`.
- **`resetAllInputs`** clears validation overlays on inputs; preserves `actionOverlaysById`.
- **`setInputValue`** clears host validation overlays when the user edits an input.

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
