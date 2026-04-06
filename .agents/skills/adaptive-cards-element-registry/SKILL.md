---
name: adaptive-cards-element-registry
description: >
  How to implement, register, and test a new Adaptive Card element type
  in this project. Covers the StatefulWidget + mixin pattern, CardTypeRegistry
  registration, and extension API. Use this before adding any new card element.
---

# Adaptive Card Element Registry Skill

## Overview

All Adaptive Card elements are Flutter `StatefulWidget`s that follow a strict
compositional mixin pattern. New elements are registered in `CardTypeRegistry`
so the JSON parser can instantiate them by `"type"` string.

---

## Architecture: Two Registries

### `CardTypeRegistry` — Elements & Containers

Located in `lib/src/registry.dart`. Maps JSON `"type"` strings to element
widgets via two mechanisms:

| Method                                   | Purpose                                 |
| ---------------------------------------- | --------------------------------------- |
| `_getBaseElement()` / `_getBaseAction()` | Built-in elements (switch/case)         |
| `addedElements: {}` constructor param    | Custom/override elements from host apps |
| `addedActions: {}` constructor param     | Custom/override actions from host apps  |
| `removedElements: []` constructor param  | Suppress specific element types         |

### `ActionTypeRegistry` — Action Handlers

Located in `lib/src/action/action_type_registry.dart`. Maps JSON action
`"type"` strings (e.g., `"Action.Submit"`) to handler logic.

There are two complementary sides of the action handling pipeline in this architecture:

1. **`GenericActions` (The "Sender / Processor")**
   `GenericActions` (e.g., `GenericSubmitAction`, `GenericExecuteAction`) define **how an Adaptive Card Action element behaves** when a user interacts with it (e.g., tapping a button).
   - **Role:** They encapsulate the internal state logic and payload construction for a specific action type. For example, when an `Action.Submit` is tapped, its `GenericAction` traverses the Flutter widget tree, finds all input fields, validates them, and bundles their values into a `data` map.
   - **Responsibility:** Form validation, input gathering, state manipulation, and preparing the payload. They are tightly coupled to the Adaptive Card elements.

2. **`InheritedAdaptiveCardHandlers` (The "Receiver / Listener")**
   `InheritedAdaptiveCardHandlers` is an `InheritedWidget` that defines **what the host application does** once an action has been processed and a payload is ready.
   - **Role:** It acts as an integration point. It allows developers consuming the package to provide application-specific callbacks (`onSubmit`, `onExecute`, `onOpenUrl`, etc.).
   - **Responsibility:** Executing host application business logic (e.g., making an API call, navigating), completely separated from the internal Adaptive Card UI logic.

**How They Work Together:** When a user taps an action button, the `tap()` method on the corresponding `GenericAction` runs, collecting and validating inputs. Once the payload is ready, the `GenericAction` looks up the `InheritedAdaptiveCardHandlers` from the build context and invokes the application-provided callback (like `onSubmit(data)`), delegating the final execution to the host app.

---

## Implementing a New Built-In Element

Use `AdaptiveBadge` (`lib/src/cards/elements/badge.dart`) as the canonical reference
implementation. The pattern for all non-input elements:

### Step 1: Create the Widget File

**File location:** `lib/src/cards/elements/my_element.dart`
(or `lib/src/cards/containers/`, `lib/src/cards/inputs/` as appropriate)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// Implements the MyElement Adaptive Card element type.
class AdaptiveMyElement extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveMyElement({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);  // load id before super() via initializer
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveMyElementState createState() => AdaptiveMyElementState();
}

class AdaptiveMyElementState extends State<AdaptiveMyElement>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {

  // Declare fields parsed from adaptiveMap
  late String text;

  @override
  void initState() {
    super.initState();
    // Parse JSON properties here — all strings are nullable from JSON
    text = adaptiveMap['text'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,  // from AdaptiveVisibilityMixin
      child: SeparatorElement(  // handles spacing/separator JSON properties
        adaptiveMap: adaptiveMap,
        child: Text(text),
      ),
    );
  }
}
```

### Step 2: Register in `CardTypeRegistry`

**File:** `lib/src/registry.dart` — add to the import block and the switch:

```dart
// 1. Add import at the top
import 'package:flutter_adaptive_cards_fs/src/cards/elements/my_element.dart';

// 2. Add a case in _getBaseElement():
case 'MyElement':
  return AdaptiveMyElement(adaptiveMap: map);
```

### Step 3: Export from the Extension Library (if needed for consumers)

If consumers need to subclass or reference your element, add it to:
`lib/flutter_adaptive_cards_extend.dart`

---

## Mixin Reference

Mixins provide shared behavior. Apply them to the **State** class:

| Mixin                        | Applied to       | Provides                                                                                                  |
| ---------------------------- | ---------------- | --------------------------------------------------------------------------------------------------------- |
| `AdaptiveElementWidgetMixin` | `StatefulWidget` | `adaptiveMap`, `id` abstract getters                                                                      |
| `AdaptiveElementMixin<T>`    | `State<T>`       | `id`, `cardTypeRegistry`, `actionTypeRegistry`, `rawRootCardWidgetState`, `style`, `adaptiveMap`          |
| `AdaptiveVisibilityMixin<T>` | `State<T>`       | `isVisible`, `setIsVisible()` — reads `"isVisible"` JSON prop                                             |
| `AdaptiveActionMixin<T>`     | `State<T>`       | `title`, `tooltip` — for action widgets                                                                   |
| `AdaptiveInputMixin<T>`      | `State<T>`       | `value`, `placeholder`, `errorMessage`, `appendInput()`, `initInput()`, `checkRequired()`, `resetInput()` |

**Typical element (non-input):**

```dart
with AdaptiveElementMixin, AdaptiveVisibilityMixin
```

**Typical input element:**

```dart
with AdaptiveElementMixin, AdaptiveVisibilityMixin, AdaptiveInputMixin
```

**Typical action widget:**

```dart
with AdaptiveElementMixin, AdaptiveActionMixin
```

---

## Key Generation (Widget Keys)

Every element must set its `key` deterministically from `adaptiveMap`. The
`generateAdaptiveWidgetKey` function handles this automatically:

```dart
// In StatefulWidget constructor:
AdaptiveMyElement({required this.adaptiveMap})
    : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
  id = loadId(adaptiveMap);
}
```

This produces:

- Widget key: `ValueKey('${id}_adaptive')`
- Child content key (for inputs): `ValueKey('$id')` or `ValueKey('${id}_suffix')`

Tests use these keys to locate widgets:

```dart
find.byKey(const ValueKey('myElementId_adaptive'))  // outer StatefulWidget
find.byKey(const ValueKey('myElementId'))           // inner content widget
```

---

## Accessing HostConfig (Theme/Style)

From within a State's `build()` method, read the `ReferenceResolver` to apply
theme-aware colors, font sizes, and spacing:

```dart
import 'package:flutter_adaptive_cards_fs/src/riverpod_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@override
Widget build(BuildContext context) {
  final resolver = ProviderScope.containerOf(context)
      .read(styleReferenceResolverProvider);

  final Color foreground = resolver.resolveContainerForegroundColor(
    style: style ?? 'default',
    isSubtle: false,
  );
  final double fontSize = resolver.resolveFontSize(
    context: context,
    sizeString: adaptiveMap['size']?.toString() ?? 'default',
  );
  // ...
}
```

> **Note:** Riverpod is used **internally only** to thread shared state
> (registry, resolver, card state) through the widget tree. Do not use
> `ConsumerWidget` or `ref.watch()` in new elements — use
> `ProviderScope.containerOf(context).read(...)` as shown above.

---

## Custom Elements in Host Apps (Extension API)

Host applications can register custom or override elements without modifying
the library, using `CardTypeRegistry.addedElements`:

```dart
// In the host app:
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs_extend.dart';

final registry = CardTypeRegistry(
  addedElements: {
    'MyCustomElement': (map) => MyCustomWidget(adaptiveMap: map),
    'TextBlock': (map) => MyOverrideTextBlock(adaptiveMap: map), // override
  },
  removedElements: ['Media'],  // disable an element type
);

AdaptiveCardsRoot.asset(
  assetPath: 'assets/my_card.json',
  cardTypeRegistry: registry,
  hostConfigs: HostConfigs(),
);
```

The extension library re-exports the mixins and utilities a custom element
needs:

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs_extend.dart';
// Gives access to: AdaptiveElementWidgetMixin, AdaptiveElementMixin,
//   AdaptiveVisibilityMixin, SeparatorElement, generateAdaptiveWidgetKey,
//   generateWidgetKey, loadId, etc.
```

---

## Testing a New Element

1. **Create a sample JSON** in `packages/flutter_adaptive_cards_fs/test/samples/`:

   ```json
   {
     "type": "AdaptiveCard",
     "version": "1.5",
     "body": [
       {
         "type": "MyElement",
         "id": "myElem1",
         "text": "Hello"
       }
     ]
   }
   ```

2. **Write a widget test** using the standard test helpers:

   ```dart
   import 'utils/test_utils.dart';

   testWidgets('MyElement renders text', (tester) async {
     await tester.pumpWidget(
       getTestWidgetFromPath(path: 'my_element_test.json'),
     );
     await tester.pumpAndSettle();
     expect(find.text('Hello'), findsOneWidget);
   });
   ```

3. **Add a golden test** (see `flutter-adaptive-cards-testing` skill).

4. **Run tests** from the package directory:
   ```bash
   cd packages/flutter_adaptive_cards_fs
   fvm flutter test
   ```
