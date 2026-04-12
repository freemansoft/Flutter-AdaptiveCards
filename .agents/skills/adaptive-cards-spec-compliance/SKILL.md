---
name: adaptive-cards-spec-compliance
description: >
  Advisor skill for implementing the Adaptive Cards and Templating specifications.
  Provides spec references, cross-SDK behavior notes (JavaScript, Android, iOS, .NET),
  element/action coverage guidance, and templating language rules.
  Use this before implementing or reviewing any new element, action, template feature,
  or HostConfig behavior to ensure parity with the official specification and other SDKs.
---

# Adaptive Cards Spec Compliance Advisor

## Your Role

When this skill is loaded, act as a spec-aware advisor. For any feature being
implemented or reviewed:

1. **Identify the canonical spec page** or schema entry for the element/property.
2. **Note the expected behavior** per the spec and flag any deviations.
3. **Reference the JavaScript SDK as the primary cross-platform reference**
   implementation (it is the most complete open-source reference).
4. **Flag unimplemented features** and known gaps in this Flutter library.
5. **Consult the templating spec** for any work in `flutter_adaptive_template_fs`.

---

## Reference Sites and SDKs (from README.md)

### Official Spec & Explorer

| Resource | URL |
|---|---|
| Adaptive Cards overview (Microsoft Learn) | https://learn.microsoft.com/en-us/adaptive-cards/ |
| Interactive schema explorer | https://adaptivecards.io/explorer/ |
| Card schema reference | https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/card-schema |
| Text features | https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/text-features |
| Card templates (deprecated URL, use templating language below) | https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/card-templates |
| Templating language | https://learn.microsoft.com/en-us/adaptive-cards/templating/language |
| Adaptive Expressions spec | https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions |

### Platform SDKs

| Platform | Docs | Distribution |
|---|---|---|
| **JavaScript** (primary reference) | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/javascript/getting-started | `npm install adaptivecards` |
| JavaScript extensibility | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/javascript/extensibility | — |
| JavaScript actions | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/javascript/actions | — |
| Android | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/android/getting-started | Maven: `io.adaptivecards:adaptivecards-android` |
| iOS | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/ios/getting-started | CocoaPod |
| .NET WPF | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/net-wpf/getting-started | NuGet |
| .NET Image (PNG render) | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/net-image/getting-started | NuGet |
| UWP | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/uwp/getting-started | — |
| React Native (community) | https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/react-native/getting-started | — |
| Templating SDKs | https://learn.microsoft.com/en-us/adaptive-cards/templating/sdk | JS: `npm install adaptivecards-templating` |
| Designer (React) | https://learn.microsoft.com/en-us/adaptive-cards/sdk/designer | — |

> **Rule:** When a behavior is unclear or disputed, use the **JavaScript SDK**
> as the ground truth for spec-compliant behavior. Its source is at
> https://github.com/microsoft/AdaptiveCards/tree/main/source/nodejs.

---

## Element Coverage Checklist

Use this as the canonical list when implementing or auditing element support.
Cross-check each item against `lib/src/registry.dart` in `flutter_adaptive_cards_fs`.

### Body Elements

| AC Type | Spec Page | Status Notes |
|---|---|---|
| `AdaptiveCard` | [explorer](https://adaptivecards.io/explorer/AdaptiveCard.html) | Root element — implemented |
| `TextBlock` | [explorer](https://adaptivecards.io/explorer/TextBlock.html) | Implemented; text features (markdown subset) may be incomplete |
| `RichTextBlock` | [explorer](https://adaptivecards.io/explorer/RichTextBlock.html) | Check inline text run support |
| `TextRun` | [explorer](https://adaptivecards.io/explorer/TextRun.html) | Used inside `RichTextBlock` |
| `Image` | [explorer](https://adaptivecards.io/explorer/Image.html) | Implemented; check `selectAction` support |
| `ImageSet` | [explorer](https://adaptivecards.io/explorer/ImageSet.html) | Implemented |
| `Media` | [explorer](https://adaptivecards.io/explorer/Media.html) | Video — Windows noted as unsupported in README |
| `Container` | [explorer](https://adaptivecards.io/explorer/Container.html) | Implemented; verify `bleed`, `minHeight` |
| `ColumnSet` | [explorer](https://adaptivecards.io/explorer/ColumnSet.html) | Implemented |
| `Column` | [explorer](https://adaptivecards.io/explorer/Column.html) | Implemented |
| `FactSet` | [explorer](https://adaptivecards.io/explorer/FactSet.html) | Implemented |
| `Fact` | [explorer](https://adaptivecards.io/explorer/Fact.html) | Used inside `FactSet` |
| `ActionSet` | [explorer](https://adaptivecards.io/explorer/ActionSet.html) | Implemented |
| `Table` (v1.5) | [explorer](https://adaptivecards.io/explorer/Table.html) | Check implementation status |
| `TableRow` (v1.5) | [explorer](https://adaptivecards.io/explorer/TableRow.html) | Paired with `Table` |
| `TableCell` (v1.5) | [explorer](https://adaptivecards.io/explorer/TableCell.html) | Paired with `Table` |

### Badge Element (project extension)

`Badge` is a project-specific extension beyond the standard AC spec. It is
registered in `CardTypeRegistry` and uses `BadgeStylesConfig` from HostConfig.

### Input Elements

| AC Type | Spec Page | Status Notes |
|---|---|---|
| `Input.Text` | [explorer](https://adaptivecards.io/explorer/Input.Text.html) | Implemented |
| `Input.Number` | [explorer](https://adaptivecards.io/explorer/Input.Number.html) | Implemented |
| `Input.Date` | [explorer](https://adaptivecards.io/explorer/Input.Date.html) | Implemented; platform picker varies |
| `Input.Time` | [explorer](https://adaptivecards.io/explorer/Input.Time.html) | Implemented; platform picker varies |
| `Input.Toggle` | [explorer](https://adaptivecards.io/explorer/Input.Toggle.html) | Implemented |
| `Input.ChoiceSet` | [explorer](https://adaptivecards.io/explorer/Input.ChoiceSet.html) | Implemented; data query supported |

### Action Types

| AC Type | Spec Page | JS Class | Status Notes |
|---|---|---|---|
| `Action.OpenUrl` | [explorer](https://adaptivecards.io/explorer/Action.OpenUrl.html) | `OpenUrlAction` | Implemented |
| `Action.Submit` | [explorer](https://adaptivecards.io/explorer/Action.Submit.html) | `SubmitAction` | Implemented |
| `Action.ShowCard` | [explorer](https://adaptivecards.io/explorer/Action.ShowCard.html) | `ShowCardAction` | Implemented |
| `Action.ToggleVisibility` | [explorer](https://adaptivecards.io/explorer/Action.ToggleVisibility.html) | `ToggleVisibilityAction` | Implemented |
| `Action.Execute` (v1.4) | [explorer](https://adaptivecards.io/explorer/Action.Execute.html) | — | Check implementation status |

---

## Spec Compliance Rules

### Unknown / Unsupported Types

The spec requires that **unknown element types be silently ignored** (not crash),
with the `fallback` property rendered instead if present. In this library:
- Unknown types return `AdaptiveUnknown` (an error display) from `CardTypeRegistry._getBaseElement()` unless a `fallback` is provided.
- **Implemented:** The `fallback` property is processed in `CardTypeRegistry` for unknown or unsupported element types.

### `requires` Property

The `requires` property allows a card to declare minimum SDK feature requirements.
The host SDK should skip rendering elements whose `requires` are not met.
This is **not currently validated** in the Flutter library — it is a known gap.

### Fallback Property

Every element and action can declare a `fallback` property. In this library:
- **Elements:** Fully supported. If an element type is unknown or registration fails, the renderer checks `fallback`:
    - `"drop"` — element is silently dropped (rendered as `SizedBox.shrink()`)
    - Another element object — that element is rendered instead (recursive lookup)
- **Actions:** **Not currently implemented**. Fallback properties on actions are ignored; unknown actions will trigger an assertion or return `AdaptiveUnknown`.

Verify `fallback` behavior when implementing any new element type.

### versioning

Cards declare `"version": "1.x"`. The renderer should gracefully degrade for
cards that declare a higher version than the renderer supports. Currently the
library does not enforce version-gating on individual elements.

---

## Cross-SDK Behavioral Notes

### JavaScript SDK (primary reference)

Actions are handled via a callback pattern:
```javascript
adaptiveCard.onExecuteAction = (action) => {
  if (action instanceof SubmitAction) { ... }
};
```

**Flutter equivalent:** The `onChange` callback on `RawAdaptiveCard.fromMap` and
the `onExecuteAction` handler wired through `RawAdaptiveCardState.changeValue()`.

Custom elements in JS extend `AC.CardElement` and implement `internalRender()`.
**Flutter equivalent:** `StatefulWidget` + `AdaptiveElementMixin` + `build()`.

Custom elements in JS are registered with:
```javascript
AC.GlobalRegistry.elements.register(MyType.JsonTypeName, MyType);
```
**Flutter equivalent:** `CardTypeRegistry` registration — either globally in the
registry constructor's switch, or via the consumer-facing extension API.

### Android SDK

Android uses a `CardRendererRegistration` to register renderers. The pattern is
nearly identical to the Flutter `CardTypeRegistry` approach.

### iOS SDK

iOS uses an `ACRRegistration` object for custom element renderers.

### .NET WPF SDK

.NET uses `AdaptiveCardRenderer` and `AdaptiveCardSchemaVersion` version gating.
This is the most strict about `requires` enforcement.

---

## Templating Specification

### Language Syntax

The Adaptive Cards Templating Language uses `${...}` for expressions (note:
the old `{...}` syntax is deprecated as of May 2020):

| Syntax | Purpose |
|---|---|
| `"${name}"` | Property binding (exact match returns typed value) |
| `"${person.name}"` | Nested property access (dot notation) |
| `"${items[0]}"` | Array indexer or computed property access |
| `"Hello ${name}!"` | String interpolation (always returns string) |
| `"$data": "${items}"` | Binds current context to `items` array |
| `"$data": "${items}"` on array → repeats element | Array repeater pattern |
| `"$when": "${price > 30}"` | Conditional element inclusion |
| `"$root"` | Reference to root data context |
| `"$index"` | Zero-based index within current array repetition |

### Supported Operators (Adaptive Expressions)

| Category | Operators |
|---|---|
| **Logical** | `&&`, `||`, `!` |
| **Comparison** | `==`, `!=`, `<`, `<=`, `>`, `>=` |
| **Arithmetic** | `+`, `-`, `*`, `/`, `%`, `^` |

### Supported Functions

| Category | Functions |
|---|---|
| **Logic** | `if(cond, t, f)` |
| **Parsing** | `json(string)` |
| **String** | `concat()`, `toUpper()`, `toLower()`, `trim()`, `substring(str, start, [len])`, `replace(str, old, new)` |
| **Math** | `min()`, `max()`, `round()`, `floor()`, `ceil()` |
| **Collection** | `length()`, `empty()` |

### Flutter Template Library (`flutter_adaptive_template_fs`)

Location: `packages/flutter_adaptive_template_fs/lib/src/`

| File | Purpose |
|---|---|
| `evaluator.dart` | Core template expansion engine — traverses the JSON tree |
| `resolver.dart` | Property path resolution (e.g. `"person.name"` → value) |
| `template.dart` | Public `Template` class wrapping `Evaluator` |

**Key implementation details:**

- `Evaluator` maintains a `_dataStack` and `_scopeStack` for nested `$data` contexts
- **Expression Parsing:** Uses a recursive-descent `ExpressionParser` that produces an Abstract Syntax Tree (`AstNode`).
- **AST Evaluation:** `Evaluator._evaluateAst` handles literals, identifiers, member access, operations, and function calls.
- `$data` pointing to an array triggers the repeater: the element produces
  a `List<Map>` instead of a single `Map`, which `_expandList` flattens
- `$when` is evaluated as a boolean; `null` or `false` → element is excluded (`null` returned)
- **Gap:** While a robust subset of **Adaptive Expressions** is implemented, the full Azure Bot Service library (100+ functions) is not exhaustive. Missing: Date/Time functions, advanced collection manipulation (`select`, `where`).
  Spec URL: https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions

### Template SDK Parity (JS reference)

```javascript
// JS template usage
const template = new ACData.Template(templatePayload);
const cardPayload = template.expand({ $root: { name: "Matt Hidinger" } });
```

**Flutter equivalent:**
```dart
final evaluator = Evaluator({'name': 'Matt Hidinger'});
final result = evaluator.expand(templatePayload);  // returns JSON string
```

Note the difference: JS wraps data in `{ $root: ... }`; Flutter's `Evaluator`
takes the root data map directly and automatically scopes it as `$root`.

---

## Known Gaps (as of this documentation)

| Area | Gap | Spec Reference |
|---|---|---|
| `requires` property | Not validated — elements are not gated on SDK capability declarations | All elements |
| Dark mode | `HostConfigs.current` always returns light config | HostConfig |
| Adaptive Expressions | Robust subset implemented (operators, string, math, logic); Date/Time and advanced collection functions missing | [Expressions spec](https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions) |
| Text features | Markdown subset / rich text features may be incomplete | [Text features](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/text-features) |
| `Action.Execute` | Verify implementation status against v1.4 spec | [explorer](https://adaptivecards.io/explorer/Action.Execute.html) |
| `Table`/`TableRow`/`TableCell` | Verify v1.5 table support | [explorer](https://adaptivecards.io/explorer/Table.html) |
| `fallback` (actions) | Verify and implement fallback handling for unknown Action types | All actions |
| Version gating | Cards declaring `"version": "1.x"` are not version-checked | `AdaptiveCard` root |

---

## Workflow: Checking Spec Compliance for a Feature

When asked to implement or audit a feature:

1. **Look up the element's spec page:**
   `https://adaptivecards.io/explorer/<TypeName>.html`

2. **Check the JSON Schema** for required vs. optional properties and their types.

3. **Compare with the JS SDK source** if behavior is ambiguous:
   `https://github.com/microsoft/AdaptiveCards/tree/main/source/nodejs`

4. **Check this library's `registry.dart`** to see if the type is registered.

5. **Check `fallback_configs.dart`** to confirm sensible defaults are in place.

6. **Verify the Known Gaps list above** — if the feature touches a gap area,
   note it explicitly in your implementation plan.

7. **For templating features**, verify against the
   [Templating Language spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)
   and check that `Evaluator` handles the relevant syntax.
