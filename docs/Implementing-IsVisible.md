# Hiding Adaptive elements based on the `isVisible` flag

This document provides guidance when implementing hide/show or visible yes/no behavior.

## Current implementation (Riverpod overlays)

Visibility is driven by the document overlay model, not by mutating JSON or walking the widget tree:

- Baseline `"isVisible"` comes from the adaptive map at load time.
- Runtime changes (e.g. `Action.ToggleVisibility`) call `AdaptiveCardDocumentNotifier.setVisibility` / `toggleVisibility`, which write `ElementOverlay.isVisible`.
- `AdaptiveVisibilityMixin` listens to `resolvedElementProvider(id)` and rebuilds when the **merged** `isVisible` changes.

Other element overlays (e.g. **TextBlock** `text` via `setText`) use the same provider; see [`reactive-riverpod.md`](reactive-riverpod.md).

See [`doc/reactive-riverpod.md`](reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map).

### Widget implementation

- Elements with `AdaptiveVisibilityMixin` wrap content in a `Visibility` widget using the merged `isVisible` from `resolvedElementProvider(id)`.
- Baseline JSON may omit `isVisible` (defaults to visible) or set `"isVisible": false`.
- Host code can call `RawAdaptiveCardState.setIsVisible` or use `Action.ToggleVisibility`; both update the document notifier (`setVisibility` / `toggleVisibility`).

### Baseline `isVisible` values

| `adaptiveMap['isVisible']` | Effective visible |
| --- | --- |
| `true` / omitted / null | Visible |
| `false` | Hidden |

### Tests

Coverage lives in [`test/elements/is_visible_test.dart`](../packages/flutter_adaptive_cards_fs/test/elements/is_visible_test.dart):

- JSON `isVisible` on elements
- `RawAdaptiveCardState.setIsVisible` and notifier `toggleVisibility`
- `Action.ToggleVisibility`
- Visibility overlay survives `RawAdaptiveCard.rebuild()`

See [Overlay test coverage](reactive-riverpod.md#overlay-test-coverage).
