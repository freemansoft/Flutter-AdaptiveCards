# Plan: Action Behavior Unification

**Spec:** `docs/superpowers/specs/2026-06-17-action-behavior-unification-design.md`
**Status:** Completed 2026-06-17

## Context

Two inconsistencies had accumulated:

1. `Action.Popover` handled taps inline (`AdaptiveActionPopoverState.onTapped()`) instead of delegating to a `GenericAction` resolved from `ActionTypeRegistry`. All other actions — Submit, Execute, OpenUrl, ToggleVisibility, ResetInputs — follow the registry pattern, which makes the action overridable by host apps. Popover's state also omitted `AdaptiveActionMixin`.

2. Test files accessed `RawAdaptiveCardState` inconsistently (some inline, some via a `_cardState()` helper) and `open_url_dialog_test.dart` declared its own bespoke `MockHttpOverrides` instead of using the shared `MyTestHttpOverrides` from `flutter_adaptive_cards_test_support`.

---

## Part 1 — Source: Popover registry pattern

### Step 1 — Extract `AdaptivePopoverContainer` ✅

Moved `AdaptivePopoverContainer` from `popover.dart` to a new file
`lib/src/cards/actions/popover_container.dart` to avoid a circular dependency
(`default_actions.dart` → `popover.dart` → `adaptive_mixins.dart` →
`action_type_registry.dart` → `default_actions.dart`).
`popover.dart` re-exports `AdaptivePopoverContainer` for backward compatibility.

### Step 2 — Add `GenericPopoverAction` to `generic_action.dart` ✅

Added abstract class `GenericPopoverAction extends GenericAction` with the standard
`tap(context, rawAdaptiveCardState, adaptiveMap)` signature.

### Step 3 — Add `DefaultPopoverAction` to `default_actions.dart` ✅

Implements `GenericPopoverAction`. Dialog-show logic moved from
`AdaptiveActionPopoverState.onTapped()`. Uses
`rawAdaptiveCardState.widget.hostConfigs` for the nested card's HostConfig
(same pattern as `DefaultOpenUrlDialogAction`). Wraps card in `AdaptivePopoverContainer`.

### Step 4 — Register in `DefaultActionTypeRegistry` ✅

Added `case 'Action.Popover': return const DefaultPopoverAction();` in
`action_type_registry.dart`. The separate `'Action.Popup'` (unsupported) case is unchanged.

### Step 5 — Refactor `AdaptiveActionPopoverState` (`popover.dart`) ✅

- Added `AdaptiveActionMixin` to state mixins.
- Added `late GenericPopoverAction action;` field.
- Resolved in `didChangeDependencies()` via `actionTypeRegistry.getActionForType(map: adaptiveMap)! as GenericPopoverAction`.
- Removed `onTapped()` method, `card` field, and `popupParentResolver` field.
- `build()` delegates `IconButtonAction.onTapped` to `action.tap(...)`.
- Removed unused `ReferenceResolver` and `flutter_raw_adaptive_card` imports.

---

## Part 2 — Tests: standardize state access and HTTP mocking

### Step 6 — Normalize `RawAdaptiveCardState` access ✅

Added `_cardState(WidgetTester tester)` helper to `execute_overlay_test.dart`,
`open_url_overlay_test.dart`, and `show_card_overlay_test.dart`. Replaced one
remaining inline `tester.state<RawAdaptiveCardState>(...)` call in
`submit_overlay_test.dart` with the existing helper.

### Step 7 — Extend `MyTestHttpOverrides` ✅

Added optional `urlResponder` parameter to `MyTestHttpOverrides` in
`flutter_adaptive_cards_test_support/lib/src/http_overrides.dart`:
`({List<int> bytes, String contentType}) Function(Uri url)?`
Wired through `_TestImageHttpClient` → `_TestImageHttpClientRequest` →
`_TestImageHttpClientResponse`. Default PNG/SVG behavior unchanged when `null`.

### Step 8 — Update `open_url_dialog_test.dart` ✅

Replaced bespoke `MockHttpOverrides` (and all associated mock classes) with
`MyTestHttpOverrides(urlResponder: _urlResponder)`. Button finding retained as
`find.text()` (see note below).

---

## As-Built Notes

**Button finding — key-first only where an explicit `id` exists:**
The original plan called for key-first button finding (`generateAdaptiveWidgetKey`)
across all action invoke tests. During implementation it was discovered that
`generateAdaptiveWidgetKey` calls `loadId()`, which falls back to `UUIDGenerator`
for maps without an `id` field. Because those UUIDs are generated at widget-build time
they are non-deterministic from a test perspective.

**Final rule (reflected in spec §2.1):**

- Action map **has an explicit `id`**: find by key (`generateAdaptiveWidgetKey`), optionally cross-validated with `find.text()`.
- Action map **has no `id`**: use `find.text('Label')` as the sole locator.

Invoke tests (`submit_action_invoke_test.dart`, `execute_verb_test.dart`,
`open_url_action_invoke_test.dart`, `open_url_dialog_action_invoke_test.dart`,
`open_url_dialog_test.dart`) retain `find.text()` since their action fixtures
typically omit the `id` field to test that null-id path.
Overlay tests (which always supply explicit ids) already use key-first and were unchanged.

---

## Files Modified

| Package                               | File                                                   |
| ------------------------------------- | ------------------------------------------------------ |
| `flutter_adaptive_cards_fs`           | `lib/src/action/generic_action.dart`                   |
| `flutter_adaptive_cards_fs`           | `lib/src/action/default_actions.dart`                  |
| `flutter_adaptive_cards_fs`           | `lib/src/action/action_type_registry.dart`             |
| `flutter_adaptive_cards_fs`           | `lib/src/cards/actions/popover.dart`                   |
| `flutter_adaptive_cards_fs`           | `lib/src/cards/actions/popover_container.dart` _(new)_ |
| `flutter_adaptive_cards_fs`           | `test/actions/execute_overlay_test.dart`               |
| `flutter_adaptive_cards_fs`           | `test/actions/open_url_overlay_test.dart`              |
| `flutter_adaptive_cards_fs`           | `test/actions/show_card_overlay_test.dart`             |
| `flutter_adaptive_cards_fs`           | `test/actions/submit_overlay_test.dart`                |
| `flutter_adaptive_cards_fs`           | `test/elements/actions/open_url_dialog_test.dart`      |
| `flutter_adaptive_cards_fs`           | `CHANGELOG.md`                                         |
| `flutter_adaptive_cards_test_support` | `lib/src/http_overrides.dart`                          |
| `flutter_adaptive_cards_test_support` | `CHANGELOG.md`                                         |
| root                                  | `AGENTS.md` _(added always-on CHANGELOG rule)_         |

---

## Verification

```bash
fvm flutter analyze          # No issues found

cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden   # 466 passed, 2 skipped, 0 failed
```
