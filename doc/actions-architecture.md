# Actions Architecture & Flow 🔧

## Overview ✅

This document describes how the Adaptive Cards action system is organized and how an action flows from parsing to execution. The design separates abstract **Generic** action interfaces from concrete **Default** implementations so you can plug in custom behavior easily.

---

## Key Concepts 💡

- **Generic action interfaces** (e.g., `GenericSubmitAction`, `GenericExecuteAction`, `GenericActionOpenUrl`) live in `lib/src/actions/generic_action.dart` and define the public contract (the `tap()` signature).
- **Default implementations** (e.g., `DefaultSubmitAction`, `DefaultExecuteAction`) live in `lib/src/actions/default_actions.dart` and provide the package-provided behavior.
- **ActionTypeRegistry** (`lib/src/actions/action_type_registry.dart`) maps the parsed `Map<String, dynamic>` (the action map) to an appropriate `GenericAction` instance.
- **Runtime invocation**: Action widgets invoke `action.tap(...)` at tap time, passing the current `adaptiveMap` so Default implementations remain stateless and reusable.

---

## Typical Flow (high level) ▶️

1. JSON parsing: card JSON is parsed; actions are represented as `Map<String, dynamic>` with a `type` field like `"Action.Submit"`.
2. Registry lookup: `ActionTypeRegistry.getActionForType(map: parsedMap)` selects a `GenericAction` instance.
3. Widget wiring: the element/action widget stores the `GenericAction` reference and uses it to handle user interaction.
4. Tap-time execution: when the user taps, the widget calls `action.tap(context: ..., rawAdaptiveCardState: ..., adaptiveMap: parsedMap)`.
5. Response: the `tap()` implementation performs validation, handler delegation (via `InheritedAdaptiveCardHandlers`), or other effects (e.g., `rawAdaptiveCardState.toggleVisibility`).

---

## Design Rationale 🔍

- Keeping `Generic*` as abstract interfaces lets consumers implement custom actions without depending on concrete names.
- Making `Default*` actions stateless (no stored `adaptiveMap`) allows them to be `const` and reused, and forces data to be passed at call time so behavior is deterministic.
- The `DefaultActionTypeRegistry` is the default bridge that returns `Default*` instances; users can provide their own `ActionTypeRegistry` to return custom implementations.

---

## How to implement a custom action ✍️

1. Implement the abstract `Generic*` interface you need:

```dart
class MySubmitAction implements GenericSubmitAction {
  const MySubmitAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    // custom behavior
  }
}
```

2. Provide a custom `ActionTypeRegistry` that returns instances of your custom action when appropriate.
3. Register your `ActionTypeRegistry` in the place the app uses (e.g., via provider or by passing to the card builder API).

---

## Action.OpenUrlDialog Behavior 🌐

`Action.OpenUrlDialog` is a specific action type that displays content from a URL within a dialog.

### Core Logic

1.  **Fetch Content**: When triggered, the action performs an HTTP GET request to the specified `url`.
2.  **Content Negotiation**:
    - It checks the `Content-Type` header of the response.
    - It attempts to parse the response body as JSON.
3.  **Display Strategy**:
    - **JSON Content**: If the response is valid Adaptive Card JSON (typically `application/json`), the card is rendered directly within the dialog.
    - **Web Content (Fallback)**: If the response is NOT JSON (e.g., standard HTML web page) or parsing fails:
      - The action **automatically launches the system default browser** to the target URL using `url_launcher`.
      - The dialog closes automatically to provide a seamless transition.
    - **Error Handling**: Network errors or other failures may display an error message in the dialog or trigger the fallback mechanism depending on the failure type.

---

## Tests & Migration Notes ⚠️

- Existing consumers should continue to rely on `Generic*` types; concrete `Default*` classes are only used by the default registry.
- Non-golden tests run with: `flutter test --exclude-tags=golden` (golden tests are tagged as `['golden']`).
- If you previously relied on passing `adaptiveMap` into action constructors, migrate to calling `tap(..., adaptiveMap: ...)` instead.

---

## Files of interest 🔎

- `lib/src/actions/generic_action.dart` — abstract `Generic*` interfaces
- `lib/src/actions/default_actions.dart` — concrete `Default*` implementations
- `lib/src/actions/action_type_registry.dart` — default registry mapping action types to implementations
- `lib/src/elements/actions/*` — action widgets and call sites

---

## Quick Tips ✨

- Prefer implementing a `Generic*` interface over subclassing a `Default*` class unless you need to reuse internal Default logic.
- Keep action implementations side-effect aware and idempotent when possible to simplify testing.

---

If you'd like, I can add example unit tests that cover each `Default*` behavior and a short migration note in `CHANGELOG.md`.
