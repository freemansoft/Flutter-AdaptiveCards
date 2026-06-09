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

| Mixin                        | Applied to         | Provides                                                                                                                                                                                                                                    |
| ---------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AdaptiveElementWidgetMixin` | `StatefulWidget`   | `adaptiveMap`, `id` abstract getters                                                                                                                                                                                                        |
| `ProviderScopeMixin<T>`      | `State<T>`         | `cardTypeRegistry`, `actionTypeRegistry`, `styleResolver`, `rawRootCardWidgetState`, `adaptiveCardElementState`                                                                                                                             |
| `AdaptiveElementMixin<T>`    | `State<T>`         | `id`, `style`, `adaptiveMap` (combine with `ProviderScopeMixin` for registries/resolver)                                                                                                                                                    |
| `AdaptiveVisibilityMixin<T>` | `State<T>`         | `isVisible`, `setIsVisible()` — listens to `resolvedElementProvider(id)` for merged `"isVisible"`                                                                                                                                           |
| `AdaptiveActionMixin<T>`     | `State<T>`         | `title`, `tooltip` — for action widgets                                                                                                                                                                                                     |
| `AdaptiveInputMixin<T>`      | `ConsumerState<T>` | `watchResolvedInput()` / `readResolvedInput()`, `setDocumentInputValue()`, `setLocalValidationError()` / `clearLocalValidationError()`, `listenForResolvedValueChanges()`; `appendInput()`, `resetInput()`, etc. No cached overlay mirrors. |

**Typical element (non-input):**

```dart
with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin
```

**Typical input element** (`ConsumerStatefulWidget` / `ConsumerState`):

```dart
with AdaptiveElementMixin, AdaptiveVisibilityMixin, AdaptiveInputMixin, ProviderScopeMixin
```

In `build()`: `listenForResolvedValueChanges(); final input = watchResolvedInput();` — use `input.label`, `input.isRequired`, etc. Imperative paths (`checkRequired`, `resetInput` overrides): `readResolvedInput()`.

**Typical action widget:**

```dart
with AdaptiveElementMixin, AdaptiveActionMixin, ProviderScopeMixin
```

---

## Runtime state: baseline + overlays

Card JSON is deep-copied into a **baseline** at render time. Runtime changes (input values, visibility, TextBlock text, validation, ChoiceSet choices) are stored in sparse **`overlaysById`** entries — the host map is never mutated. Action `isEnabled` uses **`actionOverlaysById`** + `resolvedActionProvider(id)`.

| Phase                         | Source                                                              |
| ----------------------------- | ------------------------------------------------------------------- |
| Initial UI                    | `resolvedElementProvider(id)` (baseline until overlays are written) |
| User edits / ToggleVisibility | `AdaptiveCardDocumentNotifier` → `overlaysById[id]`                 |
| What inputs read in build     | `watchResolvedInput()` — merged baseline + overlay                  |

**Inputs:** call `setDocumentInputValue(value)` when the user changes the field; implement `onDocumentValueChanged` to sync controllers when resolved value changes (reset, initData). Use `watchResolvedInput()` in `build()` for label / placeholder / validation / required — do **not** cache overlay fields on the mixin. Do **not** call `setState` from `initInput` — write the overlay and let `ref.watch` / `ref.listen` rebuild (see [`docs/reactive-riverpod.md`](../../../docs/reactive-riverpod.md#why-initinput-does-not-call-setstate-on-the-card)).

**ChoiceSet:** subscribe to resolved `choices` (see `AdaptiveChoiceSet`); host-driven updates use `setChoices` / `appendChoices` or `RawAdaptiveCardState.loadInput`.

**Visibility:** call `setIsVisible(visible: …)` or rely on `Action.ToggleVisibility`; `AdaptiveVisibilityMixin` listens to resolved `isVisible`.

**TextBlock:** host-driven copy changes use `setText` / `clearText` on the document notifier (or `RawAdaptiveCardState`); `AdaptiveTextBlock` listens to resolved `text` — do not mutate `adaptiveMap['text']` in place.

**Validation (inputs):** All validation display uses resolved **`isInvalid`** / **`errorMessage`**. Host code: `setInputError` / `clearInputError`. Form validators and `checkRequired`: **`setLocalValidationError()`** / **`clearLocalValidationError()`** on `AdaptiveInputMixin`. **`Input.Text`** supports baseline **`regex`** (validated in the Form validator and on Submit via `validateInputs()`). User edits (`setInputValue`) and factory reset clear validation overlays.

**Actions (`isEnabled`):** `setActionEnabled` + `AdaptiveActionStateMixin` / `resolvedActionProvider` — not `ElementOverlay`.

**Submit / reset:** `collectInputValues()` and `resetAllInputs()` / `resetInput(id)` on the document notifier — do not walk the widget tree. Factory reset clears input overlays including **`label`**, **`placeholder`**, and **`isRequired`** (resolved → baseline); preserves input `isVisible` and typeahead session fields. See [`docs/reactive-riverpod.md`](../../../docs/reactive-riverpod.md#reset-semantics).

Full detail: [`doc/reactive-riverpod.md`](../../doc/reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map).

---

## Overlay test coverage

### Verdict

| Layer                                                               | Confidence                                                                                                                                                                                             |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Notifier + `resolvedElementProvider` / `resolvedActionProvider`** | High — [`adaptive_card_document_notifier_test.dart`](../../packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart) covers most `AdaptiveCardDocumentNotifier` APIs |
| **Widget / host API per element or action type**                    | Partial — representative paths only; not every `Input.*` or `Action.*` has overlay-specific widget tests                                                                                               |

**Enough** to guard the overlay model and primary host integration paths. **Not enough** to claim exhaustive per-type validation without adding tests listed under [Gaps](#gaps).

Overlay fields are defined in [`adaptive_card_document.dart`](../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart). Merge logic lives in [`providers.dart`](../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart).

### Element overlays

| Field                        | Notifier tests | Widget / integration                                                                                                                                                     | Gap                                                           |
| ---------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------- |
| `isVisible`                  | Yes            | [`is_visible_test.dart`](../../packages/flutter_adaptive_cards_fs/test/elements/is_visible_test.dart)                                                                    | —                                                             |
| `inputValue`                 | Yes            | [`init_data_overlay_test.dart`](../../packages/flutter_adaptive_cards_fs/test/inputs/init_data_overlay_test.dart) (Text, Toggle, ChoiceSet)                              | Number, Date, Time, Rating — no overlay-specific widget tests |
| `choices` / append           | Yes            | [`choice_set_overlay_test.dart`](../../packages/flutter_adaptive_cards_fs/test/inputs/choice_set_overlay_test.dart)                                                      | —                                                             |
| `queryCount` / `querySkip`   | Yes            | [`choice_set_data_query_test.dart`](../../packages/flutter_adaptive_cards_fs/test/inputs/choice_set_data_query_test.dart)                                                | `querySearchText` — notifier only                             |
| `errorMessage` / `isInvalid` | Yes            | [`input_error_overlay_test.dart`](../../packages/flutter_adaptive_cards_fs/test/inputs/input_error_overlay_test.dart) — Input.Text, Input.Number; host `clearInputError` | Date, Time, Rating                                            |
| `text`                       | Yes            | [`text_block_text_overlay_test.dart`](../../packages/flutter_adaptive_cards_fs/test/elements/text_block_text_overlay_test.dart) — **TextBlock only**                     | Only element type using `text` overlay                        |

### Action overlays

| API                        | Notifier | Widget                                                                                                                                                                                                                                                                             | Gap                                       |
| -------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `setActionEnabled`         | Yes      | Submit: [`action_enabled_overlay_test.dart`](../../packages/flutter_adaptive_cards_fs/test/actions/action_enabled_overlay_test.dart); ShowCard: [`show_card_enabled_overlay_test.dart`](../../packages/flutter_adaptive_cards_fs/test/actions/show_card_enabled_overlay_test.dart) | OpenUrl, Execute, other action types      |
| `setActionsEnabled` (bulk) | Yes      | —                                                                                                                                                                                                                                                                                  | Widget test not required (notifier merge) |

Reactive wiring:

- **Elements:** `AdaptiveVisibilityMixin`, `AdaptiveInputMixin`, `AdaptiveTextBlock` → `resolvedElementProvider`
- **Actions:** `AdaptiveActionStateMixin` on [`icon_button.dart`](../../packages/flutter_adaptive_cards_fs/lib/src/cards/actions/icon_button.dart); [`show_card.dart`](../../packages/flutter_adaptive_cards_fs/lib/src/cards/actions/show_card.dart) watches `resolvedActionProvider` directly

### Cross-cutting

| Concern                                                                | Status                                                                          |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `resetAllInputs` preserves visibility, action overlays, TextBlock text | Notifier + ChoiceSet widget                                                     |
| `collectInputValues`                                                   | Notifier only                                                                   |
| Host APIs (`setText`, `setInputError`, `setActionEnabled`)             | Partial delegate tests in overlay test files                                    |
| Rebuild does not wipe overlays                                         | TextBlock + visibility widget tests; cached `_baselineMap` in `RawAdaptiveCard` |

### Gaps

Optional follow-up if tightening regressions:

1. Validation overlay widget tests for **Input.Date**, **Input.Time**, **Input.Rating**
2. `setActionEnabled` on action types beyond Submit / ShowCard (OpenUrl, Execute, …)
3. Rebuild survival with **input value** overlay (visibility and TextBlock covered)

### How to add tests for a new overlay field

1. **Notifier first** — extend [`adaptive_card_document_notifier_test.dart`](../../packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart): `ProviderContainer` + `baselineMapProvider.overrideWithValue`, assert `overlaysById` and `resolvedElementProvider` / `resolvedActionProvider`.
2. **Widget test** — sample JSON under `test/samples/`, `getTestWidgetFromMap` / `getTestWidgetFromPath`, key-first finders per [`adaptive-cards-testing`](../adaptive-cards-testing/SKILL.md).
3. **Host API** — if exposed on `RawAdaptiveCardState`, add a delegate test mirroring `setText` / `setInputError` patterns.

Full test file catalog: [`adaptive-cards-testing` skill — Reactive document tests](../adaptive-cards-testing/SKILL.md#reactive-document-tests-overlays-submit-reset).

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
// In element State with ProviderScopeMixin:
final resolver = styleResolver;

final Color foreground = resolver.resolveContainerForegroundColor(
  style: style ?? 'default',
  isSubtle: false,
);
final double fontSize = resolver.resolveFontSize(
  context: context,
  sizeString: adaptiveMap['size']?.toString() ?? 'default',
);
// ...
```

> **Note:** Shared services (registries, resolver, card state) come from
> `ProviderScopeMixin`, which reads card-scoped Riverpod providers installed by
> `RawAdaptiveCard` / `AdaptiveCardElement`. See
> [`doc/reactive-riverpod.md`](../../doc/reactive-riverpod.md).

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

AdaptiveCardsCanvas.asset(
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

If the element reads runtime state via `resolvedElementProvider` (visibility, input value, validation, `text`, etc.), add **notifier unit tests** and at least one **focused widget test** for that overlay field. Do not assume other element types are covered — see [Overlay test coverage](#overlay-test-coverage).

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

5. **Optional Widgetbook demo:** add JSON under `widgetbook/lib/samples/`, register **new directories** in [`widgetbook/pubspec.yaml`](../../../widgetbook/pubspec.yaml) (`flutter: assets:`), add a `@widgetbook.UseCase`, and run `fvm dart run build_runner build` in `widgetbook/`. See [`widgetbook/README.md`](../../../widgetbook/README.md).
