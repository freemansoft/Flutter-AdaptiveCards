# Create reliable widget keys so that widgets bind to the same state objects

All of the implementers of `AdaptiveElementWidgetMixin` should calculate and set their widget key to a value based on the passed in adaptiveMap. The utils.dart `genrateWidgetKey(Map)` should be used to generate the key.

The key should be set in the widget constructor

## Changes

For each AdaptiveElementWidget class located in `packages/flutter_adaptive_cards_plus/lib/src`

- Change the constructor to remove the passed in `key` and replace it with a key generated using `generateWidgetKey()`.

## Example

This is the standard constructor example for changes to an example class `AdaptiveFakeClassName`

```dart
  AdaptiveFakeClassName({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
  }) {
    id = loadId(adaptiveMap);
  }
```

Replace the AdaptiveFakeClassName it with

```dart
  AdaptiveFakeClassName({
    required this.adaptiveMap,
    required this.widgetState,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }
```
