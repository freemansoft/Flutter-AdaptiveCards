# Widget Key Generation for Adaptive Elements

All implementers of `AdaptiveElementWidgetMixin` must generate their widget key
deterministically from `adaptiveMap`. The `utils.dart` module provides two
functions for this — one for the outer wrapper widget and one for the inner
content widget.

---

## Two Key Functions

| Function | Key format | Used for |
| --- | --- | --- |
| `generateAdaptiveWidgetKey(Map)` | `ValueKey('${id}_adaptive')` | The outer `StatefulWidget` (the card wrapper) |
| `generateWidgetKey(Map, {String? suffix})` | `ValueKey(id)` or `ValueKey('${id}_suffix')` | The inner input/content widget |

The full key naming convention is documented in
[Using-Flutter-Form-Inputs.md](./Using-Flutter-Form-Inputs.md).

---

## Constructor Pattern

Set the key in the widget constructor's initializer list using
`generateAdaptiveWidgetKey()`. Load the `id` in the constructor body
immediately after `super()`.

### Standard element (non-input)

```dart
class AdaptiveFakeClassName extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveFakeClassName({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveFakeClassNameState createState() => AdaptiveFakeClassNameState();
}
```

### Input element (inner field key)

For the inner input field widget (e.g. a `TextFormField`), use
`generateWidgetKey()` so that the key matches the field's `id` used when
submitting form values:

```dart
// In AdaptiveFakeClassNameState.build():
TextFormField(
  key: generateWidgetKey(adaptiveMap),   // produces ValueKey(id)
  ...
)
```

For sub-widgets within a choice set, pass a suffix:

```dart
// Produces ValueKey('myFieldId_choiceValue')
key: generateWidgetKey(adaptiveMap, suffix: choiceValue)
```

---

## Finding Widgets in Tests

Tests must use the same generator functions — never hard-code the key string.
Both functions require the element's `Map<String, dynamic>` from the card JSON.

```dart
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

// Extract the element map from the card body
final elementMap = map['body'][0] as Map<String, dynamic>;

// Outer StatefulWidget (the _adaptive wrapper)
find.byKey(generateAdaptiveWidgetKey(elementMap))  // → ValueKey('myElementId_adaptive')

// Inner content / input widget
find.byKey(generateWidgetKey(elementMap))           // → ValueKey('myElementId')

// Sub-widget within a choice set (suffix form)
find.byKey(generateWidgetKey(elementMap, suffix: 'Choice 1'))  // → ValueKey('myElementId_Choice 1')
```

> [!IMPORTANT]
> Never write `find.byKey(const ValueKey('someId'))` in tests.
> If the id format ever changes, key-string literals silently break whereas
> `generateWidgetKey()` calls continue to match the live implementation.

---

## Automatic ID Injection

If a JSON map element has a `"type"` property but no `"id"`, the loader
calls `injectIds()` (in `utils.dart`) before building the widget tree to
generate a synthetic UUID-based id. This means `loadId(adaptiveMap)` always
returns a valid string at widget construction time.
