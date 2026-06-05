---
name: TextBlock text overlay
overview: Add an `ElementOverlay.text` field merged into `resolvedElementProvider`, wire `AdaptiveTextBlock` to reactively display replaced content, and document prioritized overlay candidates for inputs vs actions (deferred). No changes to `Input.Text` or other input widgets.
todos:
  - id: overlay-text-model
    content: Add ElementOverlay.text + clearText; merge in resolvedElementProvider
    status: completed
  - id: notifier-set-text
    content: setText/clearText on notifier; RawAdaptiveCardState delegates; resetAllInputs unchanged for TextBlock
    status: completed
  - id: text-block-listener
    content: "AdaptiveTextBlock: subscribe to resolvedElementProvider for text only (no input changes)"
    status: completed
  - id: tests-text-overlay
    content: Notifier + text_block_text_overlay_test.dart; run test/riverpod + test/elements
    status: completed
  - id: docs-text-overlay
    content: Update reactive-riverpod.md, CHANGELOG, testing skill
    status: completed
isProject: false
---

# TextBlock text overlay + overlay backlog

## Clarification (user intent)

- **In scope:** Runtime replacement of **`TextBlock`** content (`"text"` in card JSON) via document overlays.
- **Out of scope:** `Input.Text` / text-field behavior — existing `inputValue` → `"value"` remains the only input text overlay.

## Current gap

[`AdaptiveTextBlock`](packages/flutter_adaptive_cards_fs/lib/src/cards/elements/text_block.dart) reads **`adaptiveMap['text']`** once per `didChangeDependencies` (lines 61–65). It already uses [`AdaptiveVisibilityMixin`](packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart) for `isVisible` overlays, but **does not** watch `resolvedElementProvider(id)`.

[`ElementOverlay`](packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart) has no field for body text. [`resolvedElementProvider`](packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart) does not merge a `text` patch.

```mermaid
flowchart LR
  host[Host setText] --> notifier[AdaptiveCardDocumentNotifier]
  notifier --> overlay[ElementOverlay.text]
  overlay --> resolved[resolvedElementProvider id]
  resolved --> textBlock[AdaptiveTextBlock listener]
  textBlock --> ui[Text / MarkdownBody]
```

---

## Phase 1 — Model and merge (TextBlock text replacement)

### 1.1 Extend `ElementOverlay`

Add optional **`text`** (`String?`) — merged into resolved `"text"` (AC property name).

- `copyWith` + **`clearText`** flag (same pattern as `clearErrorMessage`).
- Document: applies to elements that expose a `text` property; first consumer is **`TextBlock`**.

### 1.2 `resolvedElementProvider`

In [`providers.dart`](packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart):

```dart
if (overlay?.text != null) merged['text'] = overlay!.text;
```

### 1.3 Notifier APIs — [`adaptive_card_document_notifier.dart`](packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart)

| API | Behavior |
|-----|----------|
| `setText(String id, String text)` | Sets overlay `text` |
| `clearText(String id)` | Clears overlay `text` |

**`resetAllInputs()`:** unchanged — only strips overlays on **`Input.*`** ids; **TextBlock text overlays persist** across reset (same as visibility / action overlays).

**`collectInputValues()`:** unchanged.

### 1.4 Host helper — [`flutter_raw_adaptive_card.dart`](packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart)

- `setText(String id, String text)` → `setText` on notifier
- `clearText(String id)` → `clearText` on notifier

(Same delegation pattern as `setInputError` / `setActionEnabled`.)

---

## Phase 2 — Widget: `AdaptiveTextBlock` only

Refactor [`text_block.dart`](packages/flutter_adaptive_cards_fs/lib/src/cards/elements/text_block.dart):

1. Add a **`ProviderSubscription`** on `resolvedElementProvider(id)` (mirror `AdaptiveVisibilityMixin` / `AdaptiveInputMixin`).
2. On resolved map change, recompute display string from **`next?['text']`** (not stale `adaptiveMap`):
   - `parseTextString(..., locale: ...)`
   - `DateTimeUtils.formatText(...)` (keep existing formatting behavior)
3. Keep styling reads (`size`, `weight`, `wrap`, etc.) in `didChangeDependencies` from **`adaptiveMap`** unless a later task overlays those too.
4. **`initState`:** seed `text` from baseline `adaptiveMap['text']` for first frame before listener fires.

**Do not modify** [`text.dart`](packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart) or `AdaptiveInputMixin`.

---

## Phase 3 — Tests

Follow [`.agents/skills/adaptive-cards-testing/SKILL.md`](.agents/skills/adaptive-cards-testing/SKILL.md).

### Notifier — extend [`adaptive_card_document_notifier_test.dart`](packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart)

- Fixture with natural-id `TextBlock` in `body`.
- `setText` → `resolvedElementProvider(id)?['text']` equals overlay.
- `clearText` → falls back to baseline.
- `resetAllInputs` → TextBlock `text` overlay **unchanged**.

### Widget — new [`test/elements/text_block_text_overlay_test.dart`](packages/flutter_adaptive_cards_fs/test/elements/text_block_text_overlay_test.dart)

- Pump card with `TextBlock` + baseline `text`.
- `container.read(...notifier).setText(id, 'Replaced')` + `pump` → `find.text('Replaced')`.
- `clearText` + `pump` → baseline text returns.
- Optional: `RawAdaptiveCardState.setText` delegate smoke test (pattern from [`input_error_overlay_test.dart`](packages/flutter_adaptive_cards_fs/test/inputs/input_error_overlay_test.dart)).

### Regression

- Existing [`is_visible_test.dart`](packages/flutter_adaptive_cards_fs/test/elements/is_visible_test.dart) unchanged behavior.

Run: `fvm flutter test test/riverpod/ test/elements/` + `fvm flutter analyze` in `packages/flutter_adaptive_cards_fs`.

---

## Phase 4 — Docs and changelog

- [`doc/reactive-riverpod.md`](doc/reactive-riverpod.md): add `text` to overlay table, notifier/host APIs, note TextBlock consumer.
- [`packages/flutter_adaptive_cards_fs/CHANGELOG.md`](packages/flutter_adaptive_cards_fs/CHANGELOG.md) `[Unreleased]`.
- Testing skill: reference new test file.

**Optional (not required for this task):** widgetbook sample under `text_block/` + Actions-adjacent catalog entry — only if you want explorer parity with `action_is_enabled`.

---

## Overlay backlog (inventory — no implementation in this task)

### Already implemented

| Target | Overlay / provider |
|--------|-------------------|
| Any element with `id` | `isVisible` → `resolvedElementProvider` |
| `Input.*` | `inputValue`, `errorMessage`, `isInvalid`, `choices`, query session fields |
| `Action.*` | `isEnabled` → `resolvedActionProvider` |

### Recommended future overlays (prioritized)

**Body / display elements**

| Property | Element(s) | Host use case | Priority |
|----------|------------|---------------|----------|
| **`text`** | **`TextBlock`** | Dynamic status, i18n, templating refresh | **This task** |
| `url` | `Image`, `Media` | Signed URL rotation | Medium |
| `text` | `Badge` (extension) | Dynamic badge label | Low (reuse same overlay field + listener if needed) |

**Inputs — defer (per user)**

| Property | Notes |
|----------|--------|
| `placeholder`, `label` | Hint/label changes without value change |
| `isRequired` | Conditional validation |
| `choices.data.parameters` | Typeahead (prior plan deferral) |

**Actions — defer**

| Property | Notes |
|----------|--------|
| `title` | Button label updates (`AdaptiveActionMixin` reads `adaptiveMap` today) |
| `tooltip`, `iconUrl` | UX tweaks at runtime |
| `mode`, `style` | AC 1.5+; lower demand |

**Session-only (stay overlay-only, not merged)**

- `querySearchText` (existing ChoiceSet typeahead pattern)

---

## Implementation order

1. `ElementOverlay.text` + merge + notifier + host API
2. `AdaptiveTextBlock` resolved listener
3. Unit + widget tests
4. Docs / changelog / analyze
