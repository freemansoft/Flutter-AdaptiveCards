---
name: adaptive-cards-element-registry
description: >
  Use before adding a new Adaptive Card element type — implementing its widget,
  registering it, or testing it. Covers the StatefulWidget + mixin pattern,
  CardTypeRegistry registration, the extension API, and optional packages
  (charts).
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

| Method                                    | Purpose                                    |
| ----------------------------------------- | ------------------------------------------ |
| `_getBaseElement()` / `_getBaseAction()`  | Built-in elements (switch/case)            |
| `addedElements: {}` constructor param     | Custom/override elements from host apps    |
| `overlayExtensions: []` constructor param | Optional overlay merge hooks (e.g. charts) |
| `addedActions: {}` constructor param      | Custom/override actions from host apps     |
| `removedElements: []` constructor param   | Suppress specific element types            |

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

Full detail: [`overlay-properties-by-type.md`](../../../docs/overlay-properties-by-type.md), [`reactive-riverpod.md`](../../../docs/reactive-riverpod.md).

---

## Overlay test coverage

Host-facing **patch keys by JSON `type`**: [`docs/overlay-properties-by-type.md`](../../../docs/overlay-properties-by-type.md). **Programmatic lookup:** `CardTypeRegistry.overlayCapabilities` ([`overlay_capability_registry.dart`](../../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/overlay_capability_registry.dart)).

### Verdict

| Layer                                                               | Confidence                                                                                                                                                                                             |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Notifier + `resolvedElementProvider` / `resolvedActionProvider`** | High — [`adaptive_card_document_notifier_test.dart`](../../../packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart) covers most `AdaptiveCardDocumentNotifier` APIs |
| **Widget / host API per element or action type**                    | Partial — representative paths only; not every `Input.*` or `Action.*` has overlay-specific widget tests                                                                                               |

Overlay fields: [`adaptive_card_document.dart`](../../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart). Merge: [`providers.dart`](../../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart).

### Field-level notifier coverage

| Field                                  | Notifier | Example widget test                                               |
| -------------------------------------- | -------- | ----------------------------------------------------------------- |
| `isVisible`                            | Yes      | `visibility_overlay_test.dart`                                    |
| `inputValue`                           | Yes      | `text_overlay_test.dart`, …                                       |
| `choices` / query session              | Yes      | `choice_set_overlay_test.dart`, `choice_set_data_query_test.dart` |
| `errorMessage` / `isInvalid`           | Yes      | `text_overlay_test.dart`, …                                       |
| `text`, `url`, `facts`, `inlines`      | Yes      | See [by-type index](../../../docs/overlay-properties-by-type.md)     |
| Chart extension payload                | Yes      | `chart_overlay_test.dart` (charts package)                        |
| Action `isEnabled`, `title`, `tooltip` | Yes      | `submit_overlay_test.dart`, …                                     |

Reactive wiring:

- **Elements:** `AdaptiveVisibilityMixin`, `AdaptiveInputMixin`, `AdaptiveTextBlock` → `resolvedElementProvider`
- **Actions:** `AdaptiveActionStateMixin` on [`icon_button.dart`](../../../packages/flutter_adaptive_cards_fs/lib/src/cards/actions/icon_button.dart); [`show_card.dart`](../../../packages/flutter_adaptive_cards_fs/lib/src/cards/actions/show_card.dart) watches `resolvedActionProvider` directly

### Cross-cutting

| Concern                                                                | Status                                                                          |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `resetAllInputs` preserves visibility, action overlays, TextBlock text | Notifier + ChoiceSet widget                                                     |
| `collectInputValues`                                                   | Notifier only                                                                   |
| Host APIs (`setText`, `setInputError`, `setActionEnabled`)             | Partial delegate tests in overlay test files                                    |
| Rebuild does not wipe overlays                                         | TextBlock + visibility widget tests; cached `_baselineMap` in `RawAdaptiveCard` |

### Gaps

Optional follow-up if tightening regressions:

1. Validation overlay widget tests for **Input.Date**, **Input.Time**
2. `Action.ResetInputs`, `Action.OpenUrlDialog`, `Action.InsertImage` overlay chrome
3. Rebuild survival with **input value** overlay (visibility and TextBlock covered)

### How to add tests for a new overlay field

1. **Notifier first** — extend [`adaptive_card_document_notifier_test.dart`](../../../packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart): `ProviderContainer` + `baselineMapProvider.overrideWithValue`, assert `overlaysById` and `resolvedElementProvider` / `resolvedActionProvider`.
2. **Widget test** — sample JSON under `test/samples/`, `getTestWidgetFromMap` / `getTestWidgetFromPath`, key-first finders per [`adaptive-cards-testing`](../adaptive-cards-testing/SKILL.md).
3. **Host API** — if exposed on `RawAdaptiveCardState`, add a delegate test mirroring `setText` / `setInputError` patterns.
4. **Docs** — update [`docs/overlay-properties-by-type.md`](../../../docs/overlay-properties-by-type.md) and [`overlay_capability_registry.dart`](../../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/overlay_capability_registry.dart).

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
> [`reactive-riverpod.md`](../../../docs/reactive-riverpod.md).

---

## Optional extension packages (charts)

Chart elements and chart runtime overlays belong in **`flutter_adaptive_charts_fs`**, not in the core library.

### Core boundary (`flutter_adaptive_cards_fs`)

- **Avoid** chart-specific classes, imports, overlay fields, and merge logic in core (`chartData`, `ChartProperties`, `fl_chart`, etc.).
- **Use** generic extension hooks:
  - `CardTypeRegistry.addedElements` — register optional element widgets by JSON `"type"`
  - `CardTypeRegistry.overlayExtensions` — register `ElementOverlayExtension` implementations
  - `ElementOverlay.extensionPayloads` — opaque per-extension overlay storage
  - `RawAdaptiveCardState.patchExtensionOverlay(...)` — host/runtime patches for extensions

### Charts package (`flutter_adaptive_charts_fs`)

- Register widgets: `CardChartsRegistry.additionalChartElements`
- Register overlay behavior: `CardChartsRegistry.overlayExtensions` (e.g. `ChartElementOverlayExtension`)
- Chart overlay host helpers live on extensions in the charts package (e.g. `ChartOverlayHost` on `RawAdaptiveCardState`), not in core.

```dart
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';

final registry = CardTypeRegistry(
  addedElements: CardChartsRegistry.additionalChartElements,
  overlayExtensions: CardChartsRegistry.overlayExtensions,
);
```

When adding overlay coverage for chart elements, put tests under `packages/flutter_adaptive_charts_fs/test/` and pass a registry that includes **both** `additionalChartElements` and `overlayExtensions`.

See [`docs/optional-packages-and-extensions.md`](../../../docs/optional-packages-and-extensions.md).

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

3. **Add a golden test** (see `adaptive-cards-testing` skill).

4. **Run tests** from the package directory:

   ```bash
   cd packages/flutter_adaptive_cards_fs
   fvm flutter test
   ```

5. **Optional Widgetbook demo:** add JSON under `widgetbook/lib/samples/`, register **new directories** in [`widgetbook/pubspec.yaml`](../../../widgetbook/pubspec.yaml) (`flutter: assets:`), add a `@widgetbook.UseCase`, and run `fvm dart run build_runner build` in `widgetbook/`. See [`widgetbook/README.md`](../../../widgetbook/README.md).
