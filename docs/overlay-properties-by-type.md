# Overlay properties by element type

**Status**: ✅ Current | **Category**: Reference

Host-facing index: which runtime patch keys affect which JSON `"type"` values. Architecture, merge rules, reset, and notifier APIs: [`reactive-riverpod.md`](reactive-riverpod.md). Input-focused flow: [`form-inputs.md`](form-inputs.md).

## How to read this

1. Target the element or action **`id`** from card JSON.
2. Patch via `RawAdaptiveCardState.applyUpdates`, `applyUpdatesFromMap`, or a typed helper (below).
3. **Effective** keys are those the widget reads from `resolvedElementProvider(id)` or `resolvedActionProvider(id)`. The notifier may merge other keys onto the resolved map; if the type is not listed here, the UI will not change.

Patch keys in `applyUpdatesFromMap` match `AdaptiveElementUpdate` / server `applyPatches` payloads (`value`, not internal `inputValue`).

## Patch key glossary

| Patch key (`applyUpdatesFromMap`)    | Resolved JSON key          | Notes                                         |
| ------------------------------------ | -------------------------- | --------------------------------------------- |
| `isVisible`                          | `isVisible`                | Any element with an `id`                      |
| `value`                              | `value`                    | Inputs; display `Rating`                      |
| `label`, `placeholder`, `isRequired` | same                       | Inputs                                        |
| `errorMessage`, `isInvalid`          | same                       | Inputs                                        |
| `choices`                            | `choices`                  | `Input.ChoiceSet` (full replace)              |
| `queryCount`, `querySkip`            | merged into `choices.data` | ChoiceSet typeahead session                   |
| `querySearchText`                    | _(overlay only)_           | Not in resolved JSON                          |
| `text`                               | `text`                     | `TextBlock`, `Badge`                          |
| `url`                                | `url`                      | `Image`, `Media` (`Media` → `sources[0].url`) |
| `facts`                              | `facts`                    | `FactSet` (full replace)                      |
| `inlines`                            | `inlines`                  | `RichTextBlock`                               |
| `data` / `chartProperties`           | `data` + chrome keys       | `Chart.*` with charts extension registered    |
| `isEnabled`, `title`, `tooltip`      | same                       | `Action.*` (`ActionOverlay`)                  |

Clear flags: `clearValue`, `clearError`, `clearChoices`, `clearText`, `clearFacts`, `clearInlines`, `clearLabel`, `clearPlaceholder`, `clearIsRequired`, `clearUrl`, `clearExtensions` (extension ids).

Implementation: [`ElementOverlay`](../packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart), [`AdaptiveElementUpdate`](../packages/flutter_adaptive_cards_fs/lib/src/models/adaptive_card_update.dart). **Programmatic lookup:** [`OverlayCapabilityRegistry`](../packages/flutter_adaptive_cards_fs/lib/src/riverpod/overlay_capability_registry.dart) (`CardTypeRegistry.overlayCapabilities`).

## By JSON `type`

Shared input keys (**all `Input.*`** except where noted): `isVisible`, `value`, `label`, `placeholder`, `isRequired`, `errorMessage`, `isInvalid`. Factory reset clears value, choices (if any), validation, `isRequired`, `label`, `placeholder`; preserves `isVisible` and ChoiceSet typeahead session. See [reset semantics](reactive-riverpod.md#reset-semantics).

| JSON `type`                                                                                                      | Additional or type-specific keys                                                                                                                                          | Typed helpers                                                                                      | Contract test                                                               |
| ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **`Input.Text`**, **`Input.Number`**, **`Input.Date`**, **`Input.Time`**, **`Input.Toggle`**, **`Input.Rating`** | —                                                                                                                                                                         | `setInputError`, `initInput`                                                                       | `test/inputs/{text,number,date,time,toggle,rating_input}_overlay_test.dart` |
| **`Input.ChoiceSet`**                                                                                            | `choices`; `queryCount`, `querySkip`, `querySearchText`                                                                                                                   | `loadInput`, `setChoices`, `appendChoices`                                                         | `test/inputs/choice_set_overlay_test.dart`                                  |
| **`TextBlock`**, **`Badge`**                                                                                     | `text`                                                                                                                                                                    | `setText`, `clearText`                                                                             | `test/elements/text_block_overlay_test.dart`, `badge_overlay_test.dart`     |
| **`FactSet`**                                                                                                    | `facts`                                                                                                                                                                   | `setFacts`, `clearFacts`                                                                           | `test/containers/fact_set_overlay_test.dart`                                |
| **`RichTextBlock`**                                                                                              | `inlines`                                                                                                                                                                 | `setInlines`, `clearInlines`                                                                       | `test/elements/rich_text_block_inlines_overlay_test.dart`                   |
| **`Image`**, **`Media`**                                                                                         | `url`                                                                                                                                                                     | `applyUpdates`                                                                                     | `test/elements/image_overlay_test.dart`, `media_overlay_test.dart`          |
| **`Rating`** (display)                                                                                           | `value`                                                                                                                                                                   | `applyUpdates`                                                                                     | `test/elements/rating_overlay_test.dart`                                    |
| **`Chart.*`**                                                                                                    | `data`; `chartProperties`: `title`, `xAxisTitle`, `yAxisTitle`, `showBarValues`, `showLegend`, `colorSet`, `value`, `min`, `max`, `subLabel`, `valueFormat`, `showMinMax` | `setChartData`, `patchChartProperties` ([charts package](../packages/flutter_adaptive_charts_fs/)) | `flutter_adaptive_charts_fs/test/charts/chart_overlay_test.dart`            |
| **`Action.*`**                                                                                                   | `isEnabled`, `title`, `tooltip`                                                                                                                                           | `setActionEnabled`, `setActionsEnabled`                                                            | `test/actions/*_overlay_test.dart`                                          |
| **Any element with `id`**                                                                                        | `isVisible`                                                                                                                                                               | `setIsVisible`, `Action.ToggleVisibility`                                                          | `test/elements/visibility_overlay_test.dart`                                |

**Charts:** requires `CardTypeRegistry(overlayExtensions: CardChartsRegistry.overlayExtensions)` — see [`optional-packages-and-extensions.md`](optional-packages-and-extensions.md).

**Examples (widgetbook sample):** [`widgetbook-overlay-demos.md`](widgetbook-overlay-demos.md).

## Implementers

- **Registry (source of truth in code):** `OverlayCapabilityRegistry` via `CardTypeRegistry.overlayCapabilities`; debug validation in `applyUpdates` (assert)
- Notifier merge: `test/riverpod/adaptive_card_document_notifier_test.dart`
- Registry unit tests: `test/riverpod/overlay_capability_registry_test.dart`
- Adding a field: update registry + notifier test + widget test; update this table

## Backlog (not yet wired)

| Target            | Property                  | Notes                                  |
| ----------------- | ------------------------- | -------------------------------------- |
| `Action.*`        | `iconUrl`                 | Baseline only today                    |
| `Input.ChoiceSet` | `choices.data.parameters` | Distinct from typeahead session fields |
