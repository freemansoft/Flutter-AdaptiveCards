# Widgetbook host-overlay demo pages (sample program)

> **Example (widgetbook sample):** [`widgetbook/`](../widgetbook/) is a demonstration app, not a published package. This doc covers demo plumbing only. Library overlay APIs are in [`reactive-riverpod.md`](reactive-riverpod.md) and package tests. See [`documentation-scope.md`](documentation-scope.md).

Interactive Widgetbook use cases that call **`RawAdaptiveCardState`** document overlay APIs (`setText`, `setFacts`, `clearFacts`, …) from knob-driven demo pages. Static JSON-only use cases do not need this pattern.

**Related skill:** [`.agents/skills/adaptive-cards-widgetbook-overlay-demos/SKILL.md`](../.agents/skills/adaptive-cards-widgetbook-overlay-demos/SKILL.md)

## Why a stable page `GlobalKey` is required

Widgetbook 3 keys the use-case builder with `ValueKey(state.uri)`. Knob edits change the URI and **remount** the use-case subtree (card flicker, spinner, lost document overlays). See [`widgetbook/CHANGELOG.md`](../widgetbook/CHANGELOG.md) (0.8.0).

**Fix:** module-level `GlobalKey` on the **page** widget (`TextBlockOverlayPage`, `FactSetOverlayPage`, …). Register the use case with that key:

```dart
return TextBlockOverlayPage(key: textBlockOverlayPageKey);
```

Read knobs inside the page’s `build()` so overlay APIs run in the stable subtree.

## Shared widgetbook modules

| Module                                                                             | Purpose                                                                                                  |
| ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| [`widgetbook_card_registry.dart`](../widgetbook/lib/widgetbook_card_registry.dart) | `widgetbookCardTypeRegistry` (default) and `widgetbookChartOverlayCardTypeRegistry` (chart overlay demo) |
| [`overlay_demo_scaffold.dart`](../widgetbook/lib/overlay_demo_scaffold.dart)       | `OverlayDemoPageState` mixin — asset load, post-frame apply queue, retry, card shell                     |

Non-overlay widgetbook pages that need chart elements should also use `widgetbookCardTypeRegistry` from the registry module.

## Shared implementation checklist

Every `widgetbook/lib/*_overlay_page.dart` should satisfy:

| Check                     | Requirement                                                                                                                                                      |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Page `GlobalKey`          | Exported `final …PageKey = GlobalKey<State<…Page>>()`; use case passes `key:`                                                                                    |
| Scaffold mixin            | `with OverlayDemoPageState<…>` — see [`overlay_demo_scaffold.dart`](../widgetbook/lib/overlay_demo_scaffold.dart)                                                |
| Registry                  | `widgetbookCardTypeRegistry` or `widgetbookChartOverlayCardTypeRegistry` from [`widgetbook_card_registry.dart`](../widgetbook/lib/widgetbook_card_registry.dart) |
| Knobs before early return | Read all knobs at top of `build()` before `buildOverlayCard` loading return                                                                                      |
| Asset load                | `loadOverlayCardAsset(path, {injectIds})` in `initState` (text_block sets `injectIds: true`)                                                                     |
| Apply queue               | Page `_queue…` → `scheduleOverlayApply(_flushPendingOverlay)` → `runWhenCardReady`                                                                               |
| Dedup                     | `_lastApplied…` — skip notifier call when value unchanged                                                                                                        |
| Debug                     | `showDebugJson: true` via `buildOverlayCard` (chart overlay: `wrapScrollView: false` only)                                                                       |
| Use case                  | `@widgetbook.UseCase` in `adaptive_cards_use_cases.dart`; regenerate `main.directories.g.dart`                                                                   |
| Imports                   | Prefer public `package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart`; `injectIds` lives in the scaffold                                              |

### Apply lifecycle strategies

Choose based on knob cost and Widgetbook rebuild frequency:

| Strategy             | When to use                                                     | Pattern                                                                  | Current pages                  |
| -------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------ | ------------------------------ |
| **Per-build queue**  | Cheap overlay writes (string `setText`); dedup handles rebuilds | Call `_queue…(knobValue)` on every `build()`                             | `text_block_overlay_page.dart` |
| **Change-only sync** | Heavier APIs (`setFacts` / `clearFacts`, multi-preset dropdown) | `_sync…Knob(value)` — record first build; queue only on value **change** | `fact_set_overlay_page.dart`   |

Document the chosen strategy in the page file or registry row when adding a new demo.

## Overlay demo registry

Add a row when introducing a new `*_overlay_page.dart`. Page-specific spec/plan links live here—not in generic review agents.

| Page                                                                                 | GlobalKey                   | Host API                                                         | Target id     | Apply lifecycle                 | Knob(s)                                                                                                                                                       | Asset                                               | Widgetbook use case                        | Spec / plan                                                                                                                                                                                    |
| ------------------------------------------------------------------------------------ | --------------------------- | ---------------------------------------------------------------- | ------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`text_block_overlay_page.dart`](../widgetbook/lib/text_block_overlay_page.dart)     | `textBlockOverlayPageKey`   | `setText`                                                        | `bodyText`    | per-build                       | `knobs.string` — `'Body TextBlock text'`                                                                                                                      | `lib/samples/text_block/text_overlay_demo.json`     | **TextBlock** → Text overlay (knob)        | —                                                                                                                                                                                              |
| [`fact_set_overlay_page.dart`](../widgetbook/lib/fact_set_overlay_page.dart)         | `factSetOverlayPageKey`     | `setFacts` / `clearFacts`                                        | `demoFactSet` | change-only (`_syncPresetKnob`) | `knobs.object.dropdown<FactSetOverlayPreset>` — `'Baseline restores to preset'`; presets: Baseline → `clearFacts`, Colors/Cities/Foods → `setFacts`           | `lib/samples/fact_set/facts_overlay_demo.json`      | **FactSet** → Facts overlay (knob)         | [spec](superpowers/specs/2026-06-06-factset-facts-overlay-design.md#example-widgetbook-sample-factset-overlay-knob), [plan Task 8](superpowers/plans/2026-06-06-factset-facts-overlay.plan.md) |
| [`rating_input_overlay_page.dart`](../widgetbook/lib/rating_input_overlay_page.dart) | `ratingInputOverlayPageKey` | `applyUpdates` / `setInputError` / `clearInputError`             | `demoRating`  | change-only (`_syncKnobs`)      | `knobs.double.slider` — `'Rating value'` (0–5); `knobs.string` — `'Input label'`; `knobs.boolean` — `'Required'`; `knobs.boolean` — `'Show validation error'` | `lib/samples/inputs/rating_input_overlay_demo.json` | **Rating** → Rating input overlay (knob)   | [plan Phase 2](superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md)                                                                                                                  |
| [`rating_overlay_page.dart`](../widgetbook/lib/rating_overlay_page.dart)             | `ratingOverlayPageKey`      | `applyUpdates`                                                   | `stars`       | change-only (`_syncValueKnob`)  | `knobs.double.slider` — `'Rating value'` (0–5)                                                                                                                | `lib/samples/elements/rating_overlay_demo.json`     | **Rating** → Rating display overlay (knob) | [plan Phase 5](superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md)                                                                                                                  |
| [`chart_overlay_page.dart`](../widgetbook/lib/chart_overlay_page.dart)               | `chartOverlayPageKey`       | `setChartData` / `patchChartProperties` / `clearChartProperties` | `demoChart`   | change-only (`_queueOverlay`)   | `knobs.object.dropdown<ChartOverlayTitlePreset>` — `'Chart title preset'`; `knobs.double.slider` — `'Category A bar value'` (0–50)                            | `lib/samples/charts/chart_overlay_demo.json`        | **Charts** → Chart overlay (knob)          | [plan Phase 8](superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md)                                                                                                                  |

### FactSet preset reference

| Knob label | Enum                            | Host action                 | Effective facts           |
| ---------- | ------------------------------- | --------------------------- | ------------------------- |
| Baseline   | `FactSetOverlayPreset.baseline` | `clearFacts('demoFactSet')` | 4 generic facts from JSON |
| Colors     | `…colors`                       | `setFacts(…, _colorsFacts)` | 4 color facts             |
| Cities     | `…cities`                       | `setFacts(…, _citiesFacts)` | 4 city facts              |
| Foods      | `…foods`                        | `setFacts(…, _foodsFacts)`  | 4 food facts              |

## Adding a new overlay demo

1. Create `widgetbook/lib/<element>_overlay_page.dart` following the shared checklist and an existing page as template.
2. Add sample JSON under `widgetbook/lib/samples/` with explicit element **`id`** for overlay targeting.
3. Register asset path in `widgetbook/pubspec.yaml` if under a new folder.
4. Add `@widgetbook.UseCase` in `adaptive_cards_use_cases.dart` with the page `GlobalKey`.
5. **Add a registry row** to this document.
6. If the feature has a design spec, add an **Example (widgetbook sample)** section there and link from the registry.
7. Run `cd widgetbook && fvm dart run build_runner build --delete-conflicting-outputs`.
8. Add package/widget tests for the host API in `flutter_adaptive_cards_fs` (see `adaptive-cards-testing` skill)—the Widgetbook page is manual verification only.

## Related demos (not host overlay APIs)

These reuse the **GlobalKey + knobs-before-early-return** idea but patch cloned JSON instead of document overlays:

| Page                                                               | GlobalKey                         | Behavior                             | Notes                                     |
| ------------------------------------------------------------------ | --------------------------------- | ------------------------------------ | ----------------------------------------- |
| [`chart_knobs_page.dart`](../widgetbook/lib/chart_knobs_page.dart) | `chartKnobsPageKeyFor(assetPath)` | Mutates chart JSON fields from knobs | Per-asset keys; not `*_overlay_page.dart` |

Other interactive pages (`dependent_choice_set_demo_page.dart`, `refresh_demo_page.dart`) use host **callbacks** (`onChange`, `onRefresh`), not overlay notifier APIs—out of scope for this doc.

## Manual verification

1. `cd widgetbook && fvm flutter run` (or `-d macos`).
2. Open the use case from the registry.
3. Confirm baseline renders from JSON without overlay applied (where applicable).
4. Change knob(s)—UI updates without full card remount (no spinner flash on every knob tick).
5. For clear/baseline presets, confirm effective values revert to JSON baseline.

## Library overlay semantics

Document notifier behavior (`setText`, `setFacts`, `ElementOverlay`, resolved merge) lives in [`docs/reactive-riverpod.md`](reactive-riverpod.md)—not duplicated here. Overlay demo pages only prove host APIs work interactively in Widgetbook.
