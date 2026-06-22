# Overlay Gaps — Parallel Agent Dispatch

Copy-paste each block into a **`Task`** tool call (`subagent_type: generalPurpose`). Launch all tasks in a **wave** in a **single message** (multiple Task calls) so they run concurrently.

**Plan:** [`2026-06-13-overlay-gaps-remediation.plan.md`](./2026-06-13-overlay-gaps-remediation.plan.md)
**Spec:** [`2026-06-13-overlay-gaps-remediation-design.md`](../specs/2026-06-13-overlay-gaps-remediation-design.md)
**Repo:** `/Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards`

**Status (2026-06-16):** Waves 1–4 complete. All phases (1–10) shipped.

**Rules for every agent:**

- Prefix all `flutter` / `dart` with `fvm`
- Do **not** commit unless the parent session asks
- Do **not** touch files outside your **MAY MODIFY** list
- Run your phase verification command and paste exit code + pass/fail in the return summary
- Read `AGENTS.md` and the phase section in the plan before coding

---

## Wave 1 — launch 4 agents together

Wait for all four to finish before Wave 2.

### Task W1-A — Phase 1: Input.Toggle overlays

```
description: Phase 1 Toggle overlay metadata
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 1 only from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (section "Phase 1 — Input.Toggle overlay metadata").

Goal: AdaptiveToggle must use watchResolvedInput() for label, isRequired, and error UI (match Input.Text patterns).

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 1)
- packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/toggle.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart (reference)
- packages/flutter_adaptive_cards_fs/test/inputs/input_error_overlay_test.dart (reference)

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/toggle.dart
- packages/flutter_adaptive_cards_fs/test/inputs/toggle_overlay_test.dart (create)

DO NOT TOUCH:
- packages/flutter_adaptive_cards_fs/lib/src/registry.dart
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/*
- Any rating, badge, media, popover, chart, or rich text files
- docs/reactive-riverpod.md (parent will merge doc updates)

Steps:
1. Write failing test in toggle_overlay_test.dart per plan
2. Update toggle.dart build(): listenForResolvedValueChanges(), watchResolvedInput(), loadLabel, loadErrorMessage, checkRequired via setLocalValidationError
3. Run: cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/toggle_overlay_test.dart

Return: files changed, test command output (exit code), any blockers.
```

---

### Task W1-B — Phase 2: AdaptiveRatingInput + RatingStars

```
description: Phase 2 AdaptiveRatingInput registry
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 2 only from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (section "Phase 2 — AdaptiveRatingInput (input) + retain AdaptiveRating (display)").

Goal: New AdaptiveRatingInput for Input.Rating; keep AdaptiveRating for Rating display; split registry; extract shared RatingStars widget. Do NOT add overlay listeners to AdaptiveRating (that is Phase 5).

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 2)
- docs/superpowers/specs/2026-06-13-overlay-gaps-remediation-design.md
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rating.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart (input mixin reference)
- .agents/skills/adaptive-cards-element-registry/SKILL.md (input pattern)
- widgetbook/lib/fact_set_overlay_page.dart (overlay page reference for Task 2.2 step 6)

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/rating.dart (create)
- packages/flutter_adaptive_cards_fs/lib/src/widgets/rating_stars.dart (create)
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rating.dart (refactor to use RatingStars only; keep read-only behavior)
- packages/flutter_adaptive_cards_fs/lib/src/registry.dart
- packages/flutter_adaptive_cards_fs/test/inputs/rating_input_test.dart (create)
- packages/flutter_adaptive_cards_fs/test/samples/v1.6/rating_input.json (create)
- widgetbook/lib/rating_input_overlay_page.dart (create)
- widgetbook/lib/samples/inputs/rating_input_overlay_demo.json (create)
- widgetbook/lib/adaptive_cards_use_cases.dart
- docs/widgetbook-overlay-demos.md (add registry row for rating input page)
- packages/flutter_adaptive_cards_fs/lib/src/additional.dart (only if export needed)

DO NOT TOUCH:
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/*
- packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/toggle.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/badge.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/media.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/actions/popover.dart
- test/elements/rating_value_overlay_test.dart (Phase 5)
- Golden files unless star layout visibly changed — if changed, note in summary for parent to re-run goldens

Registry split:
- Input.Rating → AdaptiveRatingInput
- Rating → AdaptiveRating
Remove combined case branch.

Verification:
1. cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/rating_input_test.dart
2. cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_v1_6_test.dart --name "Golden Rating" (must still pass)

Return: files changed, both test outputs, whether goldens needed update, widgetbook use case name added.
```

---

### Task W1-C — Phase 4: Badge text overlay

```
description: Phase 4 Badge text overlay
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 4 only from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (section "Phase 4 — Badge reactive text").

Goal: AdaptiveBadge listens to resolvedElementProvider(id) and updates when setText / applyUpdates patches text overlay.

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 4)
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/badge.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/text_block.dart (listener pattern)
- packages/flutter_adaptive_cards_fs/test/elements/text_block_text_overlay_test.dart (reference)

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/badge.dart
- packages/flutter_adaptive_cards_fs/test/elements/badge_text_overlay_test.dart (create)

DO NOT TOUCH:
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/*
- Any other element, input, action, chart files
- docs/reactive-riverpod.md

Verification:
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/elements/badge_text_overlay_test.dart

Return: files changed, test output, brief note on listener approach used.
```

---

### Task W1-D — Phase 7: Action.Popover overlays

```
description: Phase 7 Popover action overlays
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 7 only from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (section "Phase 7 — Action.Popover action overlays").

Goal: Action.Popover supports isEnabled, title, tooltip via AdaptiveActionStateMixin or IconButtonAction (same as other actions).

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 7)
- packages/flutter_adaptive_cards_fs/lib/src/cards/actions/popover.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/actions/icon_button.dart
- packages/flutter_adaptive_cards_fs/test/actions/action_title_tooltip_overlay_test.dart
- packages/flutter_adaptive_cards_fs/test/actions/action_enabled_overlay_test.dart

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/cards/actions/popover.dart
- packages/flutter_adaptive_cards_fs/test/actions/popover_action_overlay_test.dart (create)

DO NOT TOUCH:
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/*
- Other action files unless required for import only
- Registry, inputs, elements

Verification:
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/actions/popover_action_overlay_test.dart

Return: files changed, test output, whether dialog still opens when enabled and blocked when disabled.
```

---

## Wave 2 — launch 2 agents together (after Wave 1 completes)

**Gate:** Do not start **W2-B** until **W1-B (Phase 2)** has merged or landed — it owns `elements/rating.dart` refactor.

**W2-A (Phase 3)** can start as soon as Wave 1 completes (no dependency on Phase 2).

### Task W2-A — Phase 3: Media URL overlay

```
description: Phase 3 Media URL overlay
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 3 only from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (section "Phase 3 — Media reactive URL overlay").

Goal: setUrl overlay merges into Media sources[0].url in resolvedElementProvider; AdaptiveMedia listens and re-inits player on URL change.

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 3)
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/media.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/image.dart (listener pattern)
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart (Media merge only)
- packages/flutter_adaptive_cards_fs/test/elements/image_url_overlay_test.dart

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart (ONLY the resolvedElementProvider merge block for Media url → sources)
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/media.dart
- packages/flutter_adaptive_cards_fs/test/elements/media_url_overlay_test.dart (create)
- packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart (add one Media setUrl test only)

DO NOT TOUCH:
- adaptive_card_document.dart, adaptive_card_update.dart (no new overlay fields)
- adaptive_card_document_notifier.dart except if absolutely required (prefer providers-only merge)
- rich_text_block, chart files
- Phases 6/8 overlay fields (inlines, chartData)

Verification:
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/elements/media_url_overlay_test.dart test/riverpod/adaptive_card_document_notifier_test.dart --name "setUrl on Media"

Return: files changed, test output, note any player dispose/reinit edge cases.
```

---

### Task W2-B — Phase 5: AdaptiveRating display value overlay

```
description: Phase 5 Rating display overlays
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 5 only from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (section "Phase 5 — AdaptiveRating display dynamic value").

PREREQUISITE: Phase 2 (AdaptiveRating + RatingStars refactor) must already be in the branch. If elements/rating.dart still has inline star logic without RatingStars, stop and report blocker.

Goal: Read-only AdaptiveRating listens to resolvedElementProvider(id) for value, max, color, size; applyUpdates({value}) updates star UI.

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 5)
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rating.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/text_block.dart (listener pattern)

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rating.dart (add listener only; do not change Input.Rating or registry)
- packages/flutter_adaptive_cards_fs/test/elements/rating_value_overlay_test.dart (create)
- widgetbook/lib/rating_overlay_page.dart (optional)
- widgetbook/lib/samples/elements/rating_overlay_demo.json (optional)
- widgetbook/lib/adaptive_cards_use_cases.dart (only if overlay page added)
- docs/widgetbook-overlay-demos.md (only if overlay page added)

DO NOT TOUCH:
- packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/rating.dart
- packages/flutter_adaptive_cards_fs/lib/src/registry.dart
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/*
- packages/flutter_adaptive_cards_fs/lib/src/widgets/rating_stars.dart (unless tiny API tweak required — prefer not)

Verification:
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/elements/rating_value_overlay_test.dart

Return: files changed, test output, whether widgetbook demo was added.
```

---

## Wave 3A — one agent, serial (core overlay model)

Run **alone** before Wave 3B. Combines Phase 6 + Phase 8 **core** overlay fields so Phases 6 and 8 widgets do not fight over the same files.

### Task W3A — Core overlay: inlines + chart fields

```
description: Core overlay inlines and chart fields
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement the CORE overlay model changes for Phase 6 AND Phase 8 from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md — notifier, merge, host APIs only. Do NOT modify RichTextBlock or chart widget files yet.

Goal: Add ElementOverlay.inlines, chartData, chartProperties (+ clear flags); merge in resolvedElementProvider; notifier setters; AdaptiveElementUpdate fields; RawAdaptiveCardState host delegates.

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 6 Task 6.1 steps 1-3, Phase 8 Task 8.1)
- packages/flutter_adaptive_cards_fs/lib/src/containers/fact_set.dart + fact overlay (mirror pattern)
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart
- packages/flutter_adaptive_cards_fs/lib/src/models/adaptive_card_update.dart
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart
- packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart
- packages/flutter_adaptive_cards_fs/lib/src/models/text_run.dart (inlinesToJsonList helpers if needed)
- packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart (add inlines + chart merge tests)

DO NOT TOUCH:
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rich_text_block.dart
- packages/flutter_adaptive_charts_fs/**
- Widget files from earlier phases

chartProperties whitelist when merging: title, xAxisTitle, yAxisTitle, showBarValues, showLegend, colorSet, value, min, max, subLabel, valueFormat, showMinMax

Verification:
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart

Return: list of new public APIs (setInlines, setChartData, patchChartProperties, etc.), test output, any applyUpdatesFromMap key names documented in summary.
```

---

## Wave 3B — launch 2 agents together (after W3A completes) ✅

**Status (2026-06-15):** Shipped on `feature/wave-3-overlay-gaps-remediation` (commit `d08c46d`).

| Task                              | Verification                                                                                        | Result   |
| --------------------------------- | --------------------------------------------------------------------------------------------------- | -------- |
| W3B-A RichTextBlock inlines       | `fvm flutter test test/elements/rich_text_block_inlines_overlay_test.dart`                          | 2 passed |
| W3B-B Chart overlays + visibility | `fvm flutter test test/charts/chart_overlay_test.dart test/charts/chart_overlay_notifier_test.dart` | 6 passed |

### Task W3B-A — Phase 6 widget: RichTextBlock inlines

```
description: Phase 6 RichTextBlock widget
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 6 widget half only — AdaptiveRichTextBlock reactive inlines. Assume W3A core overlay (inlines on ElementOverlay, merge, setInlines API) is already merged.

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 6, steps 4-5)
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rich_text_block.dart
- packages/flutter_adaptive_cards_fs/lib/src/cards/containers/fact_set.dart (listener pattern)

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rich_text_block.dart
- packages/flutter_adaptive_cards_fs/test/elements/rich_text_block_inlines_overlay_test.dart (create)

DO NOT TOUCH:
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/* (unless build fails due to missing symbols — then report blocker)
- packages/flutter_adaptive_charts_fs/**

Verification:
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/elements/rich_text_block_inlines_overlay_test.dart

Return: files changed, test output.
```

---

### Task W3B-B — Phase 8 widgets: Chart overlays + visibility

```
description: Phase 8 chart overlay widgets
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 8 widget/package half from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Tasks 8.2, 8.3). Assume W3A core overlay (chartData, chartProperties merge + host APIs) is already merged.

Goal: Chart widgets use AdaptiveVisibilityMixin + listen to resolvedElementProvider; re-parse from resolved map; chart overlay tests; chart_overlay_page Widgetbook demo.

READ FIRST:
- docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (Phase 8)
- .agents/skills/widgetbook-overlay-demos/SKILL.md
- widgetbook/lib/fact_set_overlay_page.dart
- packages/flutter_adaptive_charts_fs/lib/src/charts/bar_chart.dart
- packages/flutter_adaptive_charts_fs/lib/src/charts/line_chart.dart
- packages/flutter_adaptive_charts_fs/lib/src/charts/pie_donut_chart.dart
- packages/flutter_adaptive_charts_fs/lib/src/charts/gauge_chart.dart

MAY MODIFY:
- packages/flutter_adaptive_charts_fs/lib/src/charts/chart_overlay_mixin.dart (create)
- packages/flutter_adaptive_charts_fs/lib/src/charts/*.dart (all chart state classes)
- packages/flutter_adaptive_charts_fs/test/charts/chart_overlay_test.dart (create)
- widgetbook/lib/chart_overlay_page.dart (create)
- widgetbook/lib/samples/charts/chart_overlay_demo.json (create)
- widgetbook/lib/adaptive_cards_use_cases.dart
- docs/widgetbook-overlay-demos.md

DO NOT TOUCH:
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/* (W3A owns core)
- packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rich_text_block.dart (W3B-A)

Verification:
cd packages/flutter_adaptive_charts_fs && fvm flutter test test/charts/chart_overlay_test.dart

Return: files changed, test output, widgetbook use case path, chart types wired.
```

---

## Wave 4 — optional backlog

### Task W4 — Phase 9: Action iconUrl overlay (backlog)

```
description: Phase 9 action iconUrl overlay
```

**Prompt:**

```
Full Repository Path: /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards

Implement Phase 9 only from docs/superpowers/plans/2026-06-13-overlay-gaps-remediation.plan.md (optional backlog).

Goal: ActionOverlay.iconUrl + merge in resolvedActionProvider; IconButtonAction or AdaptiveActionStateMixin listens for iconUrl changes.

MAY MODIFY:
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart (ActionOverlay)
- packages/flutter_adaptive_cards_fs/lib/src/models/adaptive_card_update.dart (AdaptiveActionUpdate)
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart
- packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart (resolvedActionProvider)
- packages/flutter_adaptive_cards_fs/lib/src/cards/actions/icon_button.dart
- packages/flutter_adaptive_cards_fs/test/actions/action_icon_url_overlay_test.dart (create)

DO NOT TOUCH: chart, rich text, rating phases unless needed.

Verification:
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/actions/action_icon_url_overlay_test.dart

Return: files changed, test output.
```

---

## Parent coordinator — after each wave

Run merge/integration locally (one agent or human):

```bash
# After Wave 1
cd packages/flutter_adaptive_cards_fs
fvm flutter test test/inputs/toggle_overlay_test.dart test/inputs/rating_input_test.dart test/elements/badge_text_overlay_test.dart test/actions/popover_action_overlay_test.dart

# After Wave 2
fvm flutter test test/elements/media_url_overlay_test.dart test/elements/rating_value_overlay_test.dart

# After Wave 3B
fvm flutter test test/elements/rich_text_block_inlines_overlay_test.dart
cd ../flutter_adaptive_charts_fs && fvm flutter test test/charts/chart_overlay_test.dart

# Final (plan gate)
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm flutter analyze
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden
cd ../flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden
```

Update once after all waves:

- `docs/overlay-properties-by-type.md`
- `docs/reactive-riverpod.md`
- `.agents/skills/adaptive-cards-element-registry/SKILL.md`

Mark completed checkboxes in `2026-06-13-overlay-gaps-remediation.plan.md`.

---

## Quick reference

| Wave | Parallel? | Task IDs     | Phases             |
| ---- | --------- | ------------ | ------------------ |
| 1    | Yes ×4    | W1-A … W1-D  | 1, 2, 4, 7         |
| 2    | Yes ×2    | W2-A, W2-B   | 3, 5 (5 after 2)   |
| 3A   | No        | W3A          | 6+8 core           |
| 3B   | Yes ×2    | W3B-A, W3B-B | 6 widget, 8 widget |
| 4    | Optional  | W4           | 9                  |
