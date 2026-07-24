# Overlay Gaps Remediation — Design

**Date:** 2026-06-13
**Status:** **Complete** (all phases including Phase 9 shipped as of 2026-06-16)
**Packages:** `flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, `widgetbook` (demos)
**Plan:** [`2026-06-13-overlay-gaps-remediation.plan.md`](../plans/2026-06-13-overlay-gaps-remediation.plan.md)
**Verification (2026-06-16):** `flutter_adaptive_cards_fs` 434 passed; `flutter_adaptive_charts_fs` 13 passed (`--exclude-tags=golden`)

## Summary

Re-verified the Riverpod **baseline + overlay** model ([`docs/reactive-riverpod.md`](../../reactive-riverpod.md)) against every registered input, element, action, and chart type. Several types either lacked reactive listeners for overlay-backed fields, or were mis-registered (notably `Input.Rating`). This design closed those gaps **one independent phase per gap**, each shippable with tests and (where applicable) a Widgetbook overlay demo.

**Outcome:** All phases shipped (including Phase 9 `iconUrl`). Chart overlays use `ElementOverlayExtension` + `extensionPayloads` in `flutter_adaptive_charts_fs` (not first-class `chartData` fields on core `ElementOverlay`). Phase 10 (`OverlayCapabilityRegistry`) was added during implementation for discoverability and debug validation in `applyUpdates`.

## Overlay pattern (reference)

| Layer                                                | Responsibility                                                                                                           |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `ElementOverlay` / `ActionOverlay`                   | Sparse runtime patches on `AdaptiveCardDocumentNotifier`                                                                 |
| `resolvedElementProvider` / `resolvedActionProvider` | Baseline JSON merged with overlays                                                                                       |
| Widget mixins / listeners                            | `AdaptiveInputMixin`, `AdaptiveVisibilityMixin`, `AdaptiveActionStateMixin`, or `container.listen` on resolved providers |

**Not a gap:** Any element with an `id` that uses `AdaptiveVisibilityMixin` already supports `isVisible` / `ToggleVisibility` / `setVisibility`.

## Implementation status (2026-06-16)

| Phase  | Gap                                        | Status     | Deliverables                                                                                      |
| ------ | ------------------------------------------ | ---------- | ------------------------------------------------------------------------------------------------- |
| **1**  | `Input.Toggle` label / required / error UI | ✅ Shipped | `toggle_overlay_test.dart`; `watchResolvedInput()` in `AdaptiveToggle`                            |
| **2**  | `Input.Rating` misrouted to display widget | ✅ Shipped | `AdaptiveRatingInput`, `RatingStars`, registry split; widgetbook demo                             |
| **3**  | `Media` URL overlay unwired                | ✅ Shipped | `sources[0].url` merge; player reinit; `media_overlay_test.dart`                                  |
| **4**  | `Badge` text unwired                       | ✅ Shipped | Resolved `text` listener; `badge_overlay_test.dart`                                               |
| **5**  | `Rating` display value unwired             | ✅ Shipped | Reactive `AdaptiveRating`; widgetbook `rating_overlay_page.dart`                                  |
| **6**  | `RichTextBlock` inlines                    | ✅ Shipped | `setInlines` / `clearInlines`; `rich_text_block_inlines_overlay_test.dart`                        |
| **7**  | `Action.Popover` action overlays           | ✅ Shipped | `popover_overlay_test.dart`; shared action chrome                                                 |
| **8**  | Chart overlays + visibility                | ✅ Shipped | `ChartElementOverlayExtension`, `ChartOverlayMixin`; `chart_overlay_page.dart`                    |
| **10** | Overlay capability registry                | ✅ Shipped | `OverlayCapabilityRegistry`; debug validation in `applyUpdates`                                   |
| **9**  | Action `iconUrl` overlay                   | ✅ Shipped | `ActionOverlay.iconUrl`; `AdaptiveActionStateMixin` listener; `action_icon_url_overlay_test.dart` |

PRs: #24 (Wave 1), #25 (Wave 2); Wave 3 on `feature/wave-3-overlay-gaps-remediation`.

---

## Verified gap matrix (2026-06-13 baseline → 2026-06-16 status)

### Inputs

| Type              | Values                   | Messages (label / error)      | Config (required, etc.)                  | Verdict (2026-06-16)         |
| ----------------- | ------------------------ | ----------------------------- | ---------------------------------------- | ---------------------------- |
| `Input.Text`      | ✅ `inputValue`          | ✅ `watchResolvedInput`       | ✅                                       | Complete                     |
| `Input.Number`    | ✅                       | ✅                            | ✅                                       | Complete                     |
| `Input.Date`      | ✅                       | ✅                            | ✅                                       | Complete (widget tests thin) |
| `Input.Time`      | ✅                       | ✅                            | ✅                                       | Complete (widget tests thin) |
| `Input.ChoiceSet` | ✅                       | ✅                            | ✅ + `choices`                           | Complete                     |
| `Input.Toggle`    | ✅ value                 | ✅ label + error UI (Phase 1) | ✅ `isRequired` via `watchResolvedInput` | **Complete**                 |
| `Input.Rating`    | ✅ `AdaptiveRatingInput` | ✅ label + error UI (Phase 2) | ✅ `isRequired`                          | **Complete**                 |

### Elements (dynamic content beyond visibility)

| Type                           | Overlay fields today            | Widget listens?                          | Verdict (2026-06-16)                         |
| ------------------------------ | ------------------------------- | ---------------------------------------- | -------------------------------------------- |
| `TextBlock`                    | `text`                          | ✅                                       | Complete                                     |
| `FactSet`                      | `facts`                         | ✅                                       | Complete                                     |
| `Image`                        | `url`                           | ✅                                       | Complete                                     |
| `Media`                        | `url` → `sources[0].url` merge  | ✅ player reinit on URL change (Phase 3) | **Complete**                                 |
| `Badge`                        | `text` on `ElementOverlay`      | ✅ resolved listener (Phase 4)           | **Complete**                                 |
| `Rating` (display)             | `inputValue` → `value` at merge | ✅ value / max / color / size (Phase 5)  | **Complete** (`AdaptiveRating` retained)     |
| `RichTextBlock`                | `inlines` full replacement      | ✅ listener rebuilds spans (Phase 6)     | **Complete**                                 |
| All other body/container types | `isVisible` only                | visibility only                          | **No gap** for value/message/config overlays |

### Actions

| Type                                                                                | `isEnabled` / `title` / `tooltip`                      | Verdict (2026-06-16)                                            |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------ | --------------------------------------------------------------- |
| Submit, Execute, OpenUrl, OpenUrlDialog, ResetInputs, ToggleVisibility, InsertImage | ✅ via `IconButtonAction` + `AdaptiveActionStateMixin` | Complete                                                        |
| `Action.ShowCard`                                                                   | ✅ `AdaptiveActionStateMixin`                          | Complete                                                        |
| `Action.Popover`                                                                    | ✅ shared action chrome (Phase 7)                      | **Complete**                                                    |
| All actions                                                                         | `iconUrl`, `mode`, `style`                             | **`iconUrl` complete (Phase 9)**; `mode` / `style` out of scope |

### Charts (`flutter_adaptive_charts_fs`)

| Concern                                                       | Status (2026-06-16)                                                                  |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `isVisible`                                                   | ✅ `AdaptiveVisibilityMixin` on chart widgets (Phase 8)                              |
| `data`, `title`, axis titles, `colorSet`, gauge `value`, etc. | ✅ `ChartElementOverlayExtension` + `ChartOverlayMixin` (Phase 8)                    |
| Widgetbook `chart_knobs_page.dart`                            | Unchanged — HostConfig chrome exploration; overlay demo is `chart_overlay_page.dart` |

## Decisions

| Topic                     | Choice                                                                                                                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AdaptiveRating`          | **Retain** — read-only display element for `type: Rating` (not an input)                                                                                                        |
| `AdaptiveRatingInput`     | **New** — interactive input for `type: Input.Rating` (`AdaptiveInputMixin`, submit, validation, overlays)                                                                       |
| Registry split            | `Rating` → `AdaptiveRating`; `Input.Rating` → `AdaptiveRatingInput` (remove combined branch)                                                                                    |
| Shared star UI            | Extract `rating_stars.dart` (or similar) used by both widgets to avoid duplicating color/size/icon logic                                                                        |
| `Input.Rating` value type | `double` submitted as JSON number; overlay uses existing `inputValue` → `value` merge via `watchResolvedInput` / `onDocumentValueChanged`                                       |
| `Rating` display updates  | Phase 5: `AdaptiveRating` listens to `resolvedElementProvider` for `value` / `max` / `color` / `size`; `applyUpdates({value: …})`                                               |
| `Badge` label updates     | Reuse `ElementOverlay.text` → resolved `"text"` (same field name as Badge JSON)                                                                                                 |
| `Media` URL rotation      | Merge overlay `url` into resolved `sources[0].url` in `resolvedElementProvider`; widget re-initializes player on change                                                         |
| Chart overlays            | **Shipped via** `ElementOverlayExtension` (`ChartElementOverlayExtension`) + `extensionPayloads` — not first-class `chartData` on core `ElementOverlay` (keeps core chart-free) |
| Overlay discoverability   | **Phase 10 (added during implementation):** `OverlayCapabilityRegistry` + `overlayPatchKeys` on extensions; debug assert in `applyUpdates`                                      |
| RichTextBlock             | Add `ElementOverlay.inlines` full replacement (mirror `facts` pattern)                                                                                                          |
| Phase independence        | Each phase has its own tests + docs; no phase depends on a later phase                                                                                                          |

## Open work items

### Required for “gaps closed”

None — all phases (1–10) are complete and verified.

### Optional / follow-up (hygiene only)

| Item                                                        | Priority  | Notes                                                                                                           |
| ----------------------------------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------- |
| **Badge widgetbook overlay demo**                           | Optional  | Plan marked `badge_overlay_page.dart` optional; not shipped. `badge_overlay_test.dart` covers behavior.         |
| **Input.Date / Input.Time validation overlay widget tests** | Hygiene   | Notifier/initData tests exist; element-registry skill lists validation overlay widget tests as a remaining gap. |
| **Action overlay chrome tests**                             | Hygiene   | `Action.ResetInputs`, `Action.OpenUrlDialog`, `Action.InsertImage` — listed in element-registry skill gaps.     |
| **Rebuild survival with input value overlay**               | Hygiene   | Visibility and TextBlock covered; input-value rebuild test not yet added.                                       |
| **`chart_knobs_page.dart` JSON clone**                      | By design | Remains for HostConfig exploration; overlay API demo is `chart_overlay_page.dart`.                              |

### Out of scope (unchanged)

- Dynamic overlays for layout-only properties (`targetWidth`, `grid.area`, `bleed`, block `height: stretch`)
- `ProgressBar` / `ProgressRing` / `Icon` runtime property patches (visibility only unless product requests)
- `choices.data.parameters` overlay (existing backlog in dynamic-property-updates spec)
- Replacing `chart_knobs_page` JSON-clone approach is **in scope for Phase 8** only for the dedicated overlay demo page; existing knob pages may remain for HostConfig chrome exploration

## References

- [`docs/reactive-riverpod.md`](../../reactive-riverpod.md)
- [`docs/superpowers/specs/2026-06-03-dynamic-property-updates-design.md`](2026-06-03-dynamic-property-updates-design.md)
- [Teams `Input.Rating`](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format#inputrating)
- [FactSet facts overlay plan](../plans/2026-06-06-factset-facts-overlay.plan.md) — template for reactive listeners
