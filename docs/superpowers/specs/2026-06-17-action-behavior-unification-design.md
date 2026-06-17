# Action Behavior Unification — Design Spec

**Date:** 2026-06-17
**Status:** Approved

---

## Context

Two inconsistencies have accumulated across the action layer and test suite:

1. `Action.Popover` handles taps inline (via `AdaptiveActionPopoverState.onTapped()`) instead of delegating to a `GenericAction` resolved from `ActionTypeRegistry`. Every other action — Submit, Execute, OpenUrl, ToggleVisibility, ResetInputs — follows the registry pattern, which makes the action overridable by host apps. Popover's current structure also omits `AdaptiveActionMixin`, leaving it without a recognized action mixin at all.

2. Test files find action buttons inconsistently: some use `find.text('Label')` as the primary locator, others use `generateAdaptiveWidgetKey()` wrapped in a descendant finder. State access (`RawAdaptiveCardState`) and HTTP mocking vary similarly across files.

The goal is to align Popover with the registry pattern and standardize test locators, state access, and HTTP mocking so every action test follows the same idioms.

---

## Part 1 — Source: Popover registry pattern

### 1.1 Add `GenericPopoverAction` to `generic_action.dart`

Add one new abstract class at the bottom of the file, following the same shape as `GenericActionToggleVisibility`:

```dart
/// Handler contract for `Action.Popover` taps.
abstract class GenericPopoverAction extends GenericAction {
  const GenericPopoverAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}
```

### 1.2 Add `DefaultPopoverAction` to `default_actions.dart`

Move the dialog-show logic out of `AdaptiveActionPopoverState.onTapped()` into a new `DefaultPopoverAction` implementation. The handler can access `hostConfigs` via `rawAdaptiveCardState.widget.hostConfigs` — the same pattern `DefaultOpenUrlDialogAction` already uses:

```dart
class DefaultPopoverAction extends GenericPopoverAction {
  const DefaultPopoverAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    final card = adaptiveMap['card'] as Map<String, dynamic>?;
    if (card == null) return;

    unawaited(showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: SingleChildScrollView(
            child: AdaptivePopoverContainer(
              child: RawAdaptiveCard.fromMap(
                map: card,
                hostConfigs: rawAdaptiveCardState.widget.hostConfigs,
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
```

`AdaptivePopoverContainer` stays in `popover.dart` — it is a UI marker widget, not part of the action handler.

### 1.3 Register `Action.Popover` in `DefaultActionTypeRegistry`

In `action_type_registry.dart`, add a `'Action.Popover'` case returning `const DefaultPopoverAction()`. The existing `'Action.Popup'` case (separate, unsupported) stays unchanged.

### 1.4 Refactor `AdaptiveActionPopoverState` to follow Submit/Execute pattern

Apply the same structure as `AdaptiveActionSubmitState`:

- Mix in `AdaptiveActionMixin` (in addition to the existing `AdaptiveElementMixin` and `ProviderScopeMixin`).
- Add `late GenericPopoverAction action;` field.
- Resolve the action in `didChangeDependencies()`: `action = actionTypeRegistry.getActionForType(map: adaptiveMap)! as GenericPopoverAction;`
- Remove the `onTapped()` method and the `popupParentResolver` field.
- In `build()`, pass `action.tap(context: context, rawAdaptiveCardState: rawRootCardWidgetState, adaptiveMap: adaptiveMap)` as `IconButtonAction.onTapped`.
- Remove the `ReferenceResolver` import from `popover.dart`.

---

## Part 2 — Tests: standardize locators, state access, and HTTP mocking

### 2.1 Button finding: key-first where an explicit `id` exists, label otherwise

`generateAdaptiveWidgetKey` calls `loadId()`, which falls back to `UUIDGenerator` when no `id` field is present. Because those UUIDs are generated at widget-build time, they are non-deterministic from a test's perspective, making key-based lookup impossible for id-less actions.

**Rule:**
- **Action map has an explicit `id`:** locate by key first, then find `ElevatedButton` as a descendant. Optionally cross-validate with `find.text()` to confirm identity.
- **Action map has no `id`:** use `find.text('Label')` as the sole locator.

```dart
// Key-first (action has an explicit id)
final buttonFinder = find.descendant(
  of: find.byKey(generateAdaptiveWidgetKey(actionMap)),
  matching: find.byType(ElevatedButton),
);

// Optional cross-validation when an id is present
final byText = find.ancestor(
  of: find.text('Button Label'),
  matching: find.byType(ElevatedButton),
);
expect(tester.widget(buttonFinder), same(tester.widget(byText)));

// Label-only (action has no id)
await tester.tap(find.text('Button Label'));
```

Files using key-first (action maps have explicit ids):
- `test/actions/popover_overlay_test.dart`
- `test/actions/submit_overlay_test.dart`
- `test/actions/execute_overlay_test.dart`
- `test/actions/open_url_overlay_test.dart`

Files using label-only (action maps have no ids, or ids are test-irrelevant):
- `test/actions/submit_action_invoke_test.dart`
- `test/actions/execute_verb_test.dart`
- `test/actions/open_url_action_invoke_test.dart`
- `test/actions/open_url_dialog_action_invoke_test.dart`
- `test/elements/actions/open_url_dialog_test.dart`

### 2.2 Normalize `RawAdaptiveCardState` access

All tests that need `RawAdaptiveCardState` should use a local helper at the top of each file:

```dart
RawAdaptiveCardState _cardState(WidgetTester tester) =>
    tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
```

This pattern already exists in `popover_overlay_test.dart`. Apply it uniformly — remove any inline `tester.state(find.byType(...))` calls scattered through test bodies.

### 2.3 Extend `MyTestHttpOverrides` to support JSON responses

`open_url_dialog_test.dart` currently declares its own `MockHttpOverrides` that returns a hardcoded JSON card response. Consolidate by making `MyTestHttpOverrides` accept an optional `urlResponder`:

```dart
class MyTestHttpOverrides extends HttpOverrides {
  MyTestHttpOverrides({this.urlResponder});

  /// If provided, called for every request. Return null to fall back to
  /// the default image stub (PNG / SVG by extension).
  final ({List<int> bytes, String contentType}) Function(Uri url)? urlResponder;
  ...
}
```

`open_url_dialog_test.dart` then sets `HttpOverrides.global = MyTestHttpOverrides(urlResponder: ...)` instead of its own class. The default behavior (PNG/SVG by extension) is unchanged for all other tests.

---

## Files to modify

| File | Change |
|------|--------|
| `lib/src/action/generic_action.dart` | Add `GenericPopoverAction` |
| `lib/src/action/default_actions.dart` | Add `DefaultPopoverAction` |
| `lib/src/action/action_type_registry.dart` | Register `Action.Popover` |
| `lib/src/cards/actions/popover.dart` | Refactor state to use registry pattern |
| `packages/flutter_adaptive_cards_test_support/lib/src/http_overrides.dart` | Add `urlResponder` param to `MyTestHttpOverrides` |
| `test/actions/submit_action_invoke_test.dart` | Key-first locator + cross-validation |
| `test/actions/execute_verb_test.dart` | Key-first locator + cross-validation |
| `test/actions/open_url_action_invoke_test.dart` | Key-first locator + cross-validation |
| `test/actions/open_url_dialog_action_invoke_test.dart` | Key-first locator + cross-validation |
| `test/elements/actions/open_url_dialog_test.dart` | Switch to `MyTestHttpOverrides(urlResponder:…)` + key-first locator |

---

## Verification

```bash
# Static analysis — run from repo root
fvm flutter analyze

# Main library suite (no goldens)
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden

# Test support package
cd packages/flutter_adaptive_cards_test_support
fvm flutter test
```

Manually confirm:
- Tapping the Popover button in a rendered card still opens the dialog.
- Disabling a Popover action via `setActionEnabled('id', enabled: false)` greys the button (existing overlay tests cover this).
- `open_url_dialog_test.dart` passes without `MockHttpOverrides`.
