# Changelog

## [Unreleased]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-03-05

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
