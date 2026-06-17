# Overlay Gaps Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close verified overlay gaps so hosts can change **values**, **messages**, and **configuration** at runtime via `applyUpdates` / document notifier APIs — one independent phase per gap, including a new **`AdaptiveRatingInput`** for `Input.Rating` while **retaining** read-only **`AdaptiveRating`** for display `Rating` elements.

**Architecture:** Extend existing `ElementOverlay` / `ActionOverlay` + `resolved*Provider` merge (no baseline mutation). Wire widgets with the same patterns as `AdaptiveTextBlock`, `AdaptiveFactSet`, `AdaptiveImage`, and `AdaptiveInputMixin`. Chart overlay merge lives in **`flutter_adaptive_charts_fs`** via `ElementOverlayExtension` + `CardTypeRegistry.overlayExtensions` — core exposes generic `extensionPayloads` hooks only.

**Tech Stack:** Dart 3.12+, Flutter (FVM), Riverpod 3.x, `flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, Widgetbook, `very_good_analysis`.

**Spec:** [`docs/superpowers/specs/2026-06-13-overlay-gaps-remediation-design.md`](../specs/2026-06-13-overlay-gaps-remediation-design.md)

**Parallel dispatch:** [`2026-06-13-overlay-gaps-parallel-dispatch.md`](./2026-06-13-overlay-gaps-parallel-dispatch.md) — copy-paste `Task` prompts per wave.

## Status (2026-06-16)

| Phase   | Status     | Notes                                                                                             |
| ------- | ---------- | ------------------------------------------------------------------------------------------------- |
| 1–8, 10 | ✅ Shipped | PRs #24 (Wave 1), #25 (Wave 2); Wave 3 on `feature/wave-3-overlay-gaps-remediation`               |
| 9       | ✅ Shipped | `ActionOverlay.iconUrl`; `AdaptiveActionStateMixin` listener; `action_icon_url_overlay_test.dart` |

**Verification (Wave 3):** `flutter_adaptive_cards_fs` 434 passed; `flutter_adaptive_charts_fs` 13 passed (`--exclude-tags=golden`).

**Checkbox reconciliation (audit 2026-06-17):** All step-level TDD checkboxes below were ticked to match the shipped status above (PRs #24/#25/#26/#29). No open work remains in this plan.

---

## Phase map

| Phase  | Gap                                        | Package(s)    | Delivers                                                      |
| ------ | ------------------------------------------ | ------------- | ------------------------------------------------------------- |
| **1**  | `Input.Toggle` label / required / error UI | core          | Reactive toggle metadata                                      |
| **2**  | `Input.Rating` not a real input            | core          | `AdaptiveRatingInput` + registry split; keep `AdaptiveRating` |
| **3**  | `Media` URL overlay unwired                | core          | Signed-URL rotation + player reinit                           |
| **4**  | `Badge` text unwired                       | core          | `setText` on Badge id                                         |
| **5**  | `Rating` display value unwired             | core          | Reactive `AdaptiveRating` for `applyUpdates({value})`         |
| **6**  | `RichTextBlock` inlines                    | core          | `setInlines` / `clearInlines`                                 |
| **7**  | `Action.Popover` action overlays           | core          | `isEnabled` / title / tooltip                                 |
| **8**  | Chart overlays + visibility                | charts + core | Data/title/config patches + overlay demo                      |
| **10** | Overlay capability registry                | core          | `OverlayCapabilityRegistry` + extension patch keys + docs     |
| **9**  | Action `iconUrl` (backlog)                 | core          | Optional follow-up                                            |

Phases **1–8** and **10** are required for “gaps closed” + discoverability. Phase **9** is optional backlog from the dynamic-property-updates spec.

---

## Shared file map (all phases)

| File                                                                                       | Phases  |
| ------------------------------------------------------------------------------------------ | ------- |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart`          | 6, 8    |
| `packages/flutter_adaptive_cards_fs/lib/src/models/adaptive_card_update.dart`              | 6, 8    |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart` | 6, 8    |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`                       | 3, 6, 8 |
| `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`                | 6, 8    |
| `docs/reactive-riverpod.md`                                                                | all     |
| `docs/Implementation-Status.md`                                                            | all     |
| `.agents/skills/widgetbook-overlay-demos/SKILL.md` + `docs/widgetbook-overlay-demos.md`    | 2, 5, 8 |

---

# Phase 1 — `Input.Toggle` overlay metadata

**Gap:** `AdaptiveToggle` uses `AdaptiveInputMixin` for value but renders static `title` from baseline and never calls `watchResolvedInput()` for `label`, `isRequired`, or `errorMessage`.

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/toggle.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/inputs/toggle_overlay_test.dart` (new)

### Task 1.1: Widget test for label / isRequired / error overlays

- [x] **Step 1: Write failing test**

```dart
// test/inputs/toggle_overlay_test.dart
testWidgets('applyUpdates patches label isRequired and errorMessage', (tester) async {
  final map = {
    'type': 'AdaptiveCard',
    'body': [
      {
        'type': 'Input.Toggle',
        'id': 'agree',
        'title': 'Baseline title',
        'value': 'false',
        'valueOn': 'true',
        'valueOff': 'false',
      },
    ],
  };
  await tester.pumpWidget(getTestWidgetFromMap(map: map, title: 'toggle overlay'));
  await tester.pumpAndSettle();

  tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard)).applyUpdates(
    elements: const [
      AdaptiveElementUpdate(
        id: 'agree',
        label: 'I agree to terms',
        isRequired: true,
        errorMessage: 'Required',
        isInvalid: true,
      ),
    ],
  );
  await tester.pump();

  expect(find.text('I agree to terms'), findsOneWidget);
  expect(find.text('Baseline title'), findsNothing);
  // Error UI: match pattern from input_error_overlay_test (loadErrorMessage / isInvalid)
});
```

- [x] **Step 2: Run test — expect FAIL**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/toggle_overlay_test.dart`

- [x] **Step 3: Update `toggle.dart` `build()`**

At top of `build()`:

```dart
listenForResolvedValueChanges();
final input = watchResolvedInput();
```

Replace `Text(title)` with:

```dart
loadLabel(
  context: context,
  label: input.label ?? title,
  isRequired: input.isRequired,
),
```

Add error message row using `loadErrorMessage(..., showError: input.isInvalid)` (same as `text.dart`).

Implement `checkRequired()` to call `setLocalValidationError()` when `readResolvedInput().isRequired` and value is `valueOff`.

- [x] **Step 4: Run test — expect PASS**

- [x] **Step 5: Update `docs/reactive-riverpod.md` overlay test table — mark Toggle covered**

---

# Phase 2 — `AdaptiveRatingInput` (input) + retain `AdaptiveRating` (display)

**Gap:** `Input.Rating` routes to read-only `AdaptiveRating`, which has no input contract. Display `Rating` remains valid but shares the wrong widget today.

**Decision:** **Two widgets:**

- **`AdaptiveRating`** — keep in `cards/elements/rating.dart`; read-only stars for `type: Rating`
- **`AdaptiveRatingInput`** — new in `cards/inputs/rating.dart`; interactive input for `type: Input.Rating`

Extract shared star rendering into `packages/flutter_adaptive_cards_fs/lib/src/widgets/rating_stars.dart` (or `utils/rating_stars.dart`) so both widgets stay DRY.

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/rating.dart`
- Create: `packages/flutter_adaptive_cards_fs/lib/src/widgets/rating_stars.dart` (shared)
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rating.dart` (use shared stars helper; no overlay work in this phase)
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/registry.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/inputs/rating_input_test.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/samples/v1.6/rating_input.json`
- Create: `widgetbook/lib/rating_input_overlay_page.dart`
- Create: `widgetbook/lib/samples/inputs/rating_input_overlay_demo.json`
- Modify: `widgetbook/lib/adaptive_cards_use_cases.dart`
- Modify: `docs/widgetbook-overlay-demos.md` registry

### Task 2.1: Shared star helper

- [x] **Step 1: Extract `RatingStars` widget** from current `AdaptiveRating` build logic (color, size, filled/empty icons, optional half-star display for read-only fractional values)

- [x] **Step 2: Refactor `AdaptiveRating`** to use `RatingStars` — behavior unchanged; existing golden `Golden Rating` must still pass

### Task 2.2: `AdaptiveRatingInput` widget

- [x] **Step 1: Write failing widget test — submit collects rating value**

```dart
testWidgets('Input.Rating submits double value', (tester) async {
  // card with Input.Rating id rating, Action.Submit
  // tap 4th star, tap Submit, assert onSubmit payload contains rating: 4
});
```

- [x] **Step 2: Implement `AdaptiveRatingInput`**

`ConsumerStatefulWidget` with mixins: `AdaptiveInputMixin`, `AdaptiveElementMixin`, `AdaptiveVisibilityMixin`, `ProviderScopeMixin`.

Properties from Teams spec:

- `max` (default 5), `value` (double), `allowHalfSteps`, `color` (`neutral`/`marigold`), `size` (`small`/`medium`/`large`)
- `label`, `isRequired`, `errorMessage` via `watchResolvedInput()`

Behavior:

- Tappable stars (via `RatingStars` with `onRatingChanged`) → `setDocumentInputValue(double)` → `notifyUserInputValueChanged`
- `appendInput`: `map[id] = currentValue` (number)
- `initInput` / `onDocumentValueChanged`: sync selection from resolved `value`
- `checkRequired`: fail when `isRequired` and value is 0 or unset
- `resetInput`: delegate to mixin + `setState`
- `loadLabel` + `loadErrorMessage` like other inputs

- [x] **Step 3: Split registry**

```dart
case 'Input.Rating':
  return AdaptiveRatingInput(adaptiveMap: map);
case 'Rating':
  return AdaptiveRating(adaptiveMap: map);
```

Remove combined `case 'Rating': case 'Input.Rating':` branch.

- [x] **Step 4: Input-only overlay tests**

```dart
testWidgets('applyUpdates value and label update Input.Rating', (tester) async { ... });
testWidgets('setInputError shows on Input.Rating', (tester) async { ... });
testWidgets('resetInput restores baseline value', (tester) async { ... });
```

- [x] **Step 5: Notifier test** — `collectInputValues()` includes `Input.Rating` id with double value

- [x] **Step 6: Widgetbook `rating_input_overlay_page.dart`**

Follow `fact_set_overlay_page.dart` change-only lifecycle:

- Target id: `demoRating` (`Input.Rating`)
- Knobs: value (0–5), label, `isRequired`, show error → `applyUpdates` / `setInputError`
- Register in `adaptive_cards_use_cases.dart` + `docs/widgetbook-overlay-demos.md`

- [x] **Step 7: Docs** — `Implementation-Status.md`: `Input.Rating` row; note `Rating` display unchanged widget type

---

# Phase 3 — `Media` reactive URL overlay

**Gap:** `setUrl` merges `url` on resolved element, but `AdaptiveMedia` reads `sources[0].url` from baseline in `initState` only.

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/media.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/elements/media_url_overlay_test.dart`

### Task 3.1: Merge overlay URL into `sources`

- [x] **Step 1: Notifier test extension**

In `adaptive_card_document_notifier_test.dart`:

```dart
test('setUrl on Media merges into sources[0].url', () {
  // baseline Media with sources[{url: 'https://old.example/v.mp4'}]
  // setUrl('media1', 'https://new.example/v.mp4')
  // resolved['sources'][0]['url'] == new
});
```

- [x] **Step 2: Update `resolvedElementProvider` merge**

After baseline merge, when `overlay?.url != null` and element type is `Media`:

- Clone `sources` list; set first entry `url` to overlay value (create single source if empty)

- [x] **Step 3: `AdaptiveMedia` listener**

Mirror `AdaptiveImage`:

- `container.listen(resolvedElementProvider(id), ...)`
- On `sources` URL change: dispose old controllers, call `initializePlayer()` with new URL

- [x] **Step 4: Widget test** — `setUrl` triggers rebuild with new source URL string in state

- [x] **Step 5: Document** in `reactive-riverpod.md` — Media listens like Image

---

# Phase 4 — `Badge` reactive `text`

**Gap:** `ElementOverlay.text` merges to `"text"` but `AdaptiveBadge` reads baseline once.

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/badge.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/elements/badge_text_overlay_test.dart`
- Optional: `widgetbook/lib/badge_overlay_page.dart` (string knob → `setText`)

### Task 4.1: Listener on resolved `text`

- [x] **Step 1: Failing widget test** — `setText('badge1', 'Updated')` updates visible label

- [x] **Step 2: Copy `AdaptiveTextBlock` listener pattern** — `container.listen(resolvedElementProvider(id), ...)` updates `text` state field

- [x] **Step 3: Pass** + update overlay backlog in `reactive-riverpod.md` (Badge row → implemented)

---

# Phase 5 — `AdaptiveRating` display dynamic `value`

**Gap:** Read-only `AdaptiveRating` reads `value` / `max` / `color` / `size` from baseline in `initState` only. `applyUpdates({value: …})` merges via `inputValue` → `value` but the display widget does not listen.

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rating.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/elements/rating_value_overlay_test.dart`
- Optional: `widgetbook/lib/rating_overlay_page.dart` — slider knob → `applyUpdates` on display `Rating` id

### Task 5.1: Resolved value listener on `AdaptiveRating`

- [x] **Step 1: Test** — display `Rating` id `stars`, `applyUpdates(elements: [AdaptiveElementUpdate(id: 'stars', value: 4.5)])`, expect updated star fill count

- [x] **Step 2: Add listener** in `didChangeDependencies` — `container.listen(resolvedElementProvider(id), …)` updates `value`, `max`, `color`, `size`; `setState` when changed

- [x] **Step 3: Docs** — `reactive-riverpod.md`: display `Rating` accepts `value` patches via bulk API

---

# Phase 6 — `RichTextBlock` inlines overlay

**Gap:** No runtime replacement for `inlines` array (unlike `TextBlock.text` / `FactSet.facts`).

**Files:**

- Modify: `adaptive_card_document.dart`, `adaptive_card_update.dart`, `adaptive_card_document_notifier.dart`, `providers.dart`, `flutter_raw_adaptive_card.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/text_run.dart` — add `inlinesToJsonList` / `inlinesFromJsonList` if missing
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rich_text_block.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/elements/rich_text_block_inlines_overlay_test.dart`

### Task 6.1: `ElementOverlay.inlines`

- [x] **Step 1: Model + merge** — `List<Map<String, dynamic>>? inlines` on overlay; `clearInlines`; merge in `resolvedElementProvider`

- [x] **Step 2: Notifier** — `setInlines(id, inlines)`, `clearInlines(id)`; wire `applyUpdates` / `AdaptiveElementUpdate.inlines` / `clearInlines`

- [x] **Step 3: Host API** — `RawAdaptiveCardState.setInlines` / `clearInlines`

- [x] **Step 4: `AdaptiveRichTextBlock`** — listener rebuilds `_inlineSpans` from resolved `inlines`

- [x] **Step 5: Tests** — notifier + widget (replace `TextRun` text via new inlines list)

---

# Phase 7 — `Action.Popover` action overlays

**Gap:** Custom `ElevatedButton` uses `AdaptiveActionMixin` (baseline only). No `isEnabled` / dynamic title.

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/actions/popover.dart`

### Task 7.1: Use shared action chrome

- [x] **Step 1: Test** — copy pattern from `action_title_tooltip_overlay_test.dart` for `Action.Popover` id

- [x] **Step 2: Refactor** — replace inline `ElevatedButton` with `IconButtonAction(adaptiveMap:, onTapped: onTapped)` OR add `AdaptiveActionStateMixin` to popover state and gate `onPressed` with `actionEnabled`

- [x] **Step 3: `setActionEnabled` test** — disabled popover does not open dialog on tap

---

# Phase 8 — Chart overlays + visibility ✅

**Gap:** Chart widgets lacked `AdaptiveVisibilityMixin` and did not listen for data/config changes. Widgetbook used JSON cloning instead of overlay API.

**Delivered:** Generic `ElementOverlayExtension` in core; `ChartElementOverlayExtension` + `ChartOverlayMixin` in charts package; host wiring via `CardChartsRegistry.overlayExtensions`.

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/element_overlay_extension.dart`
- Modify: `registry.dart`, `providers.dart`, `flutter_raw_adaptive_card.dart` (extension hooks only — no chart-specific fields)
- Create: `packages/flutter_adaptive_charts_fs/lib/src/chart_element_overlay_extension.dart`
- Create: `packages/flutter_adaptive_charts_fs/lib/src/charts/chart_overlay_mixin.dart`
- Modify: all chart state classes in `packages/flutter_adaptive_charts_fs/lib/src/charts/*.dart`
- Create: `packages/flutter_adaptive_charts_fs/test/charts/chart_overlay_test.dart`, `chart_overlay_notifier_test.dart`
- Create: `widgetbook/lib/chart_overlay_page.dart`
- Modify: `docs/widgetbook-overlay-demos.md`, skills, `AGENTS.md`

### Task 8.1: Chart overlay extension (not core `chartData` fields)

Core provides `ElementOverlay.extensionPayloads`, `CardOverlayExtensionRegistry`, and `patchExtensionOverlay`. Charts package implements `ChartElementOverlayExtension` (`id: 'charts'`) with chart data/properties merge and `ChartOverlayHost` helpers on `RawAdaptiveCardState`.

### Task 8.2: Chart widget mixin

- [x] Create `chart_overlay_mixin.dart` — listens to `resolvedElementProvider(id)`, reparses from resolved map

- [x] Add `AdaptiveVisibilityMixin` to bar, line, pie/donut, and gauge chart widgets

- [x] Refactor parsers to read from `resolvedElementProvider(id) ?? adaptiveMap`

### Task 8.3: Tests + Widgetbook

- [x] Notifier tests for chart data + properties merge (`chart_overlay_notifier_test.dart`)
- [x] Widget test: patch `data` first point → bar height changes
- [x] Widget test: `setVisibility` hides chart
- [x] `chart_overlay_page.dart`: bar chart id `demoChart`, knobs call overlay API via `RawAdaptiveCardState` (change-only dedup)

---

---

# Phase 10 — Overlay capability registry ✅

**Gap:** Hosts had no programmatic way to discover valid overlay fields per JSON `type`; docs and code could drift.

**Delivered:** Shared registry aligned with [`docs/overlay-properties-by-type.md`](../../overlay-properties-by-type.md).

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/overlay_capability_registry.dart`
- Modify: `element_overlay_extension.dart` (`overlayPatchKeys`)
- Modify: `registry.dart` (`CardTypeRegistry.overlayCapabilities`)
- Modify: `adaptive_card_document_notifier.dart` (debug assert in `applyUpdates`)
- Modify: `packages/flutter_adaptive_charts_fs/.../chart_element_overlay_extension.dart` (`overlayPatchKeys`)
- Create: `test/riverpod/overlay_capability_registry_test.dart`
- Modify: `docs/overlay-properties-by-type.md`

### Task 10.1: Core registry

- [x] **`ElementOverlayField` / `ActionOverlayField` enums** — patch-key aligned identifiers
- [x] **`OverlayCapabilityRegistry`** — `elementFieldsFor`, `actionFieldsFor`, `validateElementUpdate`, `validateActionUpdate`
- [x] **`CardTypeRegistry.overlayCapabilities`** — scoped to registered `overlayExtensions`
- [x] **Debug validation** — `applyUpdates` asserts unsupported fields (does not block release builds)

### Task 10.2: Extensions + tests

- [x] **`ElementOverlayExtension.overlayPatchKeys`** — charts extension whitelists `data` / `chartProperties` keys
- [x] **Unit tests** — input vs display types, chart extension registration, invalid patch keys

---

# Phase 9 — Action `iconUrl` overlay ✅

**Gap:** `IconButtonAction` reads `iconUrl` from baseline in `initState` only.

**Delivered:** `ActionOverlay.iconUrl` + merge in `resolvedActionProvider`; `AdaptiveActionStateMixin` listener; `action_icon_url_overlay_test.dart`.

**Files:**

- `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart` (ActionOverlay)
- `packages/flutter_adaptive_cards_fs/lib/src/models/adaptive_card_update.dart` (AdaptiveActionUpdate)
- `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`
- `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart`
- `packages/flutter_adaptive_cards_fs/lib/src/riverpod/overlay_capability_registry.dart`
- `packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart`
- `packages/flutter_adaptive_cards_fs/lib/src/cards/actions/icon_button.dart`
- `packages/flutter_adaptive_cards_fs/test/actions/action_icon_url_overlay_test.dart`
- `docs/overlay-properties-by-type.md`

---

## Final verification (required after all phases) ✅

Run from repo root and affected packages:

```bash
fvm flutter analyze

cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden

cd ../flutter_adaptive_charts_fs
fvm flutter test --exclude-tags=golden
```

**Result (2026-06-15):** core 423 passed; charts 13 passed.

**Per-phase minimum** (run when that phase completes):

| Phase | Command                                                                                    |
| ----- | ------------------------------------------------------------------------------------------ |
| 1     | `fvm flutter test test/inputs/toggle_overlay_test.dart`                                    |
| 2     | `fvm flutter test test/inputs/rating_input_test.dart`                                      |
| 3     | `fvm flutter test test/elements/media_url_overlay_test.dart`                               |
| 4     | `fvm flutter test test/elements/badge_text_overlay_test.dart`                              |
| 5     | `fvm flutter test test/elements/rating_value_overlay_test.dart`                            |
| 6     | `fvm flutter test test/elements/rich_text_block_inlines_overlay_test.dart`                 |
| 7     | `fvm flutter test test/actions/popover_action_overlay_test.dart`                           |
| 8     | `cd ../flutter_adaptive_charts_fs && fvm flutter test test/charts/chart_overlay_test.dart` |
| 10    | `fvm flutter test test/riverpod/overlay_capability_registry_test.dart`                     |

Update after completion:

- `docs/reactive-riverpod.md` — “Already implemented” + remove resolved gaps
- `docs/Implementation-Status.md` — overlay notes per type
- `.agents/skills/adaptive-cards-element-registry/SKILL.md` — overlay coverage table

---

## Execution order recommendation

```
Phase 1 (Toggle) → Phase 2 (AdaptiveRatingInput + keep AdaptiveRating) → Phase 3 (Media) → Phase 4 (Badge)
→ Phase 5 (AdaptiveRating display overlays) → Phase 6 (RichTextBlock) → Phase 7 (Popover) → Phase 8 (Charts)
```

Phase 2 adds the input widget and registry split; Phase 5 wires display-only overlays on the retained `AdaptiveRating`. Phase 8 is the largest cross-package change.
