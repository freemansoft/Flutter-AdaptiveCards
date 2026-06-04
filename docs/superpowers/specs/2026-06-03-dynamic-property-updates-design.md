# Dynamic Adaptive Card Property Updates

**Date:** 2026-06-03
**Status:** Approved for implementation
**Package:** `flutter_adaptive_cards_fs`

## Summary

Hosts update rendered cards at runtime via sparse **overlays** on the Riverpod document notifier — not by mutating baseline JSON. This spec adds a unified **`applyUpdates`** bulk API on top of existing per-property methods, integrates **`initData` / `initInput`**, and extends overlays for **`isRequired`** and **`url`**.

## Decisions

| Topic             | Choice                                                           |
| ----------------- | ---------------------------------------------------------------- |
| Update model      | Partial overlay patches only                                     |
| Handler API       | Keep imperative callbacks; bulk helper on `RawAdaptiveCardState` |
| Full card replace | Out of scope                                                     |

## Property tiers

### Tier 1 (bulk API wraps existing overlays)

`value`, `errorMessage`, `isInvalid`, `isVisible`, `choices`, `text`, `isEnabled` (actions)

### Tier 2 (new overlays)

`isRequired` (inputs), `url` (`Image`, `Media`)

### Tier 3 (implemented)

`label`, `placeholder` (inputs), action `title`/`tooltip` — via `ElementOverlay` / `ActionOverlay`, `applyUpdates`, and reactive listeners on `AdaptiveInputMixin` / `AdaptiveActionStateMixin`.

### Tier 3 backlog

`choices.data.parameters`, action `iconUrl`/`mode`/`style`

## Core API

- `AdaptiveElementUpdate` / `AdaptiveActionUpdate` — typed patches
- `AdaptiveCardDocumentNotifier.applyUpdates` — single revision bump
- `RawAdaptiveCardState.applyUpdates` / `applyUpdatesFromMap` — host helpers
- `seedInputValues` — value-only facade over `applyUpdates`

## initData / initInput

- Scalar `initData` entries → `{value: scalar}` patches
- Map `initData` entries → full per-id patch maps via `applyUpdatesFromMap`
- `initInput(map)` unchanged for value-only late binding

## Event patterns

See [`doc/reactive-riverpod.md`](../../doc/reactive-riverpod.md) and [`doc/form-inputs.md`](../../doc/form-inputs.md) for validation, cascade ChoiceSet, and load-time examples.

## Testing

Notifier bulk merge, host delegate, initData composition, cascade, `isRequired`, image `url`, submit resolved `isRequired` — see plan test matrix.
