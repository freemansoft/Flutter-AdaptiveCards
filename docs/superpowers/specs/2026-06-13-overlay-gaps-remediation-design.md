# Overlay Gaps Remediation — Design

**Date:** 2026-06-13
**Status:** Approved for implementation
**Packages:** `flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, `widgetbook` (demos)

## Summary

Re-verified the Riverpod **baseline + overlay** model ([`docs/reactive-riverpod.md`](../../reactive-riverpod.md)) against every registered input, element, action, and chart type. Several types either lack reactive listeners for overlay-backed fields, or are mis-registered (notably `Input.Rating`). This design closes those gaps **one independent phase per gap**, each shippable with tests and (where applicable) a Widgetbook overlay demo.

## Overlay pattern (reference)

| Layer                                                | Responsibility                                                                                                           |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `ElementOverlay` / `ActionOverlay`                   | Sparse runtime patches on `AdaptiveCardDocumentNotifier`                                                                 |
| `resolvedElementProvider` / `resolvedActionProvider` | Baseline JSON merged with overlays                                                                                       |
| Widget mixins / listeners                            | `AdaptiveInputMixin`, `AdaptiveVisibilityMixin`, `AdaptiveActionStateMixin`, or `container.listen` on resolved providers |

**Not a gap:** Any element with an `id` that uses `AdaptiveVisibilityMixin` already supports `isVisible` / `ToggleVisibility` / `setVisibility`.

## Verified gap matrix (2026-06-13)

### Inputs

| Type              | Values                         | Messages (label / error)            | Config (required, etc.)                     | Verdict                      |
| ----------------- | ------------------------------ | ----------------------------------- | ------------------------------------------- | ---------------------------- |
| `Input.Text`      | ✅ `inputValue`                | ✅ `watchResolvedInput`             | ✅                                          | Complete                     |
| `Input.Number`    | ✅                             | ✅                                  | ✅                                          | Complete                     |
| `Input.Date`      | ✅                             | ✅                                  | ✅                                          | Complete (widget tests thin) |
| `Input.Time`      | ✅                             | ✅                                  | ✅                                          | Complete (widget tests thin) |
| `Input.ChoiceSet` | ✅                             | ✅                                  | ✅ + `choices`                              | Complete                     |
| `Input.Toggle`    | ✅ value                       | ❌ uses static `title`, no error UI | ❌ no `watchResolvedInput` for `isRequired` | **Gap — Phase 1**            |
| `Input.Rating`    | ❌ misrouted to display widget | ❌                                  | ❌                                          | **Gap — Phase 2**            |

### Elements (dynamic content beyond visibility)

| Type                           | Overlay fields today              | Widget listens?                             | Verdict                                                                    |
| ------------------------------ | --------------------------------- | ------------------------------------------- | -------------------------------------------------------------------------- |
| `TextBlock`                    | `text`                            | ✅                                          | Complete                                                                   |
| `FactSet`                      | `facts`                           | ✅                                          | Complete                                                                   |
| `Image`                        | `url`                             | ✅                                          | Complete                                                                   |
| `Media`                        | `url` (merged to top-level `url`) | ❌ reads `sources[0]` from `initState` only | **Gap — Phase 3**                                                          |
| `Badge`                        | `text` exists on `ElementOverlay` | ❌ reads baseline in `initState`            | **Gap — Phase 4**                                                          |
| `Rating` (display)             | `inputValue` → `value` at merge   | ❌ reads baseline in `initState`            | **Gap — Phase 5** (`AdaptiveRating` retained)                              |
| `RichTextBlock`                | none for `inlines`                | ❌                                          | **Gap — Phase 6**                                                          |
| All other body/container types | `isVisible` only                  | visibility only                             | **No gap** for value/message/config overlays                               |

### Actions

| Type                                                                                | `isEnabled` / `title` / `tooltip`                      | Verdict               |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------ | --------------------- |
| Submit, Execute, OpenUrl, OpenUrlDialog, ResetInputs, ToggleVisibility, InsertImage | ✅ via `IconButtonAction` + `AdaptiveActionStateMixin` | Complete              |
| `Action.ShowCard`                                                                   | ✅ `AdaptiveActionStateMixin`                          | Complete              |
| `Action.Popover`                                                                    | ❌ `AdaptiveActionMixin` only; custom `ElevatedButton` | **Gap — Phase 7**     |
| All actions                                                                         | `iconUrl`, `mode`, `style`                             | **Backlog — Phase 9** |

### Charts (`flutter_adaptive_charts_fs`)

| Concern                                                       | Status                                                                     |
| ------------------------------------------------------------- | -------------------------------------------------------------------------- | ----------------- |
| `isVisible`                                                   | ❌ no `AdaptiveVisibilityMixin` on chart widgets                           |
| `data`, `title`, axis titles, `colorSet`, gauge `value`, etc. | ❌ parsed once from baseline `adaptiveMap`; no overlay fields or listeners |
| Widgetbook `chart_knobs_page.dart`                            | Rebuilds cloned JSON — **not** overlay API                                 | **Gap — Phase 8** |

## Decisions

| Topic                       | Choice                                                                                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `AdaptiveRating`            | **Retain** — read-only display element for `type: Rating` (not an input)                                                                                           |
| `AdaptiveRatingInput`       | **New** — interactive input for `type: Input.Rating` (`AdaptiveInputMixin`, submit, validation, overlays)                                                          |
| Registry split              | `Rating` → `AdaptiveRating`; `Input.Rating` → `AdaptiveRatingInput` (remove combined branch)                                                                       |
| Shared star UI              | Extract `rating_stars.dart` (or similar) used by both widgets to avoid duplicating color/size/icon logic                                                          |
| `Input.Rating` value type   | `double` submitted as JSON number; overlay uses existing `inputValue` → `value` merge via `watchResolvedInput` / `onDocumentValueChanged`                          |
| `Rating` display updates    | Phase 5: `AdaptiveRating` listens to `resolvedElementProvider` for `value` / `max` / `color` / `size`; `applyUpdates({value: …})`                                  |
| `Badge` label updates       | Reuse `ElementOverlay.text` → resolved `"text"` (same field name as Badge JSON)                                                                                    |
| `Media` URL rotation        | Merge overlay `url` into resolved `sources[0].url` in `resolvedElementProvider`; widget re-initializes player on change                                            |
| Chart overlays              | Add typed `ElementOverlay.chartData` + `chartProperties` shallow patch map for chrome fields; charts listen and re-parse                                           |
| RichTextBlock               | Add `ElementOverlay.inlines` full replacement (mirror `facts` pattern)                                                                                             |
| Phase independence          | Each phase has its own tests + docs; no phase depends on a later phase                                                                                             |

## Out of scope

- Dynamic overlays for layout-only properties (`targetWidth`, `grid.area`, `bleed`, block `height: stretch`)
- `ProgressBar` / `ProgressRing` / `Icon` runtime property patches (visibility only unless product requests)
- `choices.data.parameters` overlay (existing backlog in dynamic-property-updates spec)
- Replacing `chart_knobs_page` JSON-clone approach is **in scope for Phase 8** only for the dedicated overlay demo page; existing knob pages may remain for HostConfig chrome exploration

## References

- [`docs/reactive-riverpod.md`](../../reactive-riverpod.md)
- [`docs/superpowers/specs/2026-06-03-dynamic-property-updates-design.md`](2026-06-03-dynamic-property-updates-design.md)
- [Teams `Input.Rating`](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format#inputrating)
- [FactSet facts overlay plan](../plans/2026-06-06-factset-facts-overlay.plan.md) — template for reactive listeners
