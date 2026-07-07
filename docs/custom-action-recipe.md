---
doc_type: how-to
---

# Implement a custom action

Recipe for plugging a custom action behavior into the renderer. This assumes you know the
action dispatch model — for how actions flow from JSON to execution and why the `Generic*` /
`Default*` split exists, see [`actions-architecture.md`](actions-architecture.md).

## Steps

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
