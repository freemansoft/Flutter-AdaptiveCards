---
name: adaptive-cards-spec-compliance
description: >
  Use before implementing or reviewing any new element, action, template
  feature, or HostConfig behavior, to check parity with the official spec and
  other SDKs. Provides Adaptive Cards + Templating spec references and cross-SDK
  behavior notes (JavaScript, Android, iOS, .NET).
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

| Resource                                                       | URL                                                                                                                |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Adaptive Cards overview (Microsoft Learn)                      | <https://learn.microsoft.com/en-us/adaptive-cards/>                                                                |
| Interactive schema explorer                                    | <https://adaptivecards.io/explorer/>                                                                               |
| Card schema reference                                          | <https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/card-schema>                                     |
| Text features                                                  | <https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/text-features>                                   |
| Card templates (deprecated URL, use templating language below) | <https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/card-templates>                                  |
| Templating language                                            | <https://learn.microsoft.com/en-us/adaptive-cards/templating/language>                                             |
| Adaptive Expressions spec                                      | <https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions> |

### Platform SDKs

| Platform                           | Docs                                                                                                | Distribution                                    |
| ---------------------------------- | --------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| **JavaScript** (primary reference) | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/javascript/getting-started>   | `npm install adaptivecards`                     |
| JavaScript extensibility           | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/javascript/extensibility>     | —                                               |
| JavaScript actions                 | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/javascript/actions>           | —                                               |
| Android                            | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/android/getting-started>      | Maven: `io.adaptivecards:adaptivecards-android` |
| iOS                                | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/ios/getting-started>          | CocoaPod                                        |
| .NET WPF                           | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/net-wpf/getting-started>      | NuGet                                           |
| .NET Image (PNG render)            | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/net-image/getting-started>    | NuGet                                           |
| UWP                                | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/uwp/getting-started>          | —                                               |
| React Native (community)           | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/react-native/getting-started> | —                                               |
| Templating SDKs                    | <https://learn.microsoft.com/en-us/adaptive-cards/templating/sdk>                                   | JS: `npm install adaptivecards-templating`      |
| Designer (React)                   | <https://learn.microsoft.com/en-us/adaptive-cards/sdk/designer>                                     | —                                               |

> **Rule:** When a behavior is unclear or disputed, use the **JavaScript SDK**
> as the ground truth for spec-compliant behavior. Its source is at
> <https://github.com/microsoft/AdaptiveCards/tree/main/source/nodejs>.

---

## Element Coverage Checklist

This is a **spec-URL quick reference** — the set of AC types and where each is
documented — for auditing whether a type exists in the spec and jumping to its
page. It is **not** the source of truth for what this library implements.

> **Implementation / tests / per-component gaps are owned by the package READMEs**,
> not this skill (see the "Architecture documentation sync gate" in `AGENTS.md`).
> Read status there, and update it there:
>
> - Core elements, containers, inputs, actions, HostConfig →
>   [`packages/flutter_adaptive_cards_fs/README.md` § Implementation status](../../../packages/flutter_adaptive_cards_fs/README.md#implementation-status)
> - Charts → [`packages/flutter_adaptive_charts_fs/README.md`](../../../packages/flutter_adaptive_charts_fs/README.md#implementation-status)
> - Templating → [`packages/flutter_adaptive_template_fs/README.md`](../../../packages/flutter_adaptive_template_fs/README.md#feature-coverage)
> - Cross-cutting roadmap / history → [`docs/Implementation-Status.md`](../../../docs/Implementation-Status.md)
>
> When auditing, cross-check the live registry (`lib/src/registry.dart`) against
> the spec, then reconcile the README table — do not restate status here.

### Body Elements

| AC Type            | Spec Page                                                        |
| ------------------ | ---------------------------------------------------------------- |
| `AdaptiveCard`     | [explorer](https://adaptivecards.io/explorer/AdaptiveCard.html)  |
| `TextBlock`        | [explorer](https://adaptivecards.io/explorer/TextBlock.html)     |
| `RichTextBlock`    | [explorer](https://adaptivecards.io/explorer/RichTextBlock.html) |
| `TextRun`          | [explorer](https://adaptivecards.io/explorer/TextRun.html)       |
| `Image`            | [explorer](https://adaptivecards.io/explorer/Image.html)         |
| `ImageSet`         | [explorer](https://adaptivecards.io/explorer/ImageSet.html)      |
| `Media`            | [explorer](https://adaptivecards.io/explorer/Media.html)         |
| `Container`        | [explorer](https://adaptivecards.io/explorer/Container.html)     |
| `ColumnSet`        | [explorer](https://adaptivecards.io/explorer/ColumnSet.html)     |
| `Column`           | [explorer](https://adaptivecards.io/explorer/Column.html)        |
| `FactSet`          | [explorer](https://adaptivecards.io/explorer/FactSet.html)       |
| `Fact`             | [explorer](https://adaptivecards.io/explorer/Fact.html)          |
| `ActionSet`        | [explorer](https://adaptivecards.io/explorer/ActionSet.html)     |
| `Table` (v1.5)     | [explorer](https://adaptivecards.io/explorer/Table.html)         |
| `TableRow` (v1.5)  | [explorer](https://adaptivecards.io/explorer/TableRow.html)      |
| `TableCell` (v1.5) | [explorer](https://adaptivecards.io/explorer/TableCell.html)     |

### Badge Element (project extension)

`Badge` is a project-specific extension beyond the standard AC spec. It is
registered in `CardTypeRegistry` and uses `BadgeStylesConfig` from HostConfig.

### Input Elements

| AC Type           | Spec Page                                                          |
| ----------------- | ------------------------------------------------------------------ |
| `Input.Text`      | [explorer](https://adaptivecards.io/explorer/Input.Text.html)      |
| `Input.Number`    | [explorer](https://adaptivecards.io/explorer/Input.Number.html)    |
| `Input.Date`      | [explorer](https://adaptivecards.io/explorer/Input.Date.html)      |
| `Input.Time`      | [explorer](https://adaptivecards.io/explorer/Input.Time.html)      |
| `Input.Toggle`    | [explorer](https://adaptivecards.io/explorer/Input.Toggle.html)    |
| `Input.ChoiceSet` | [explorer](https://adaptivecards.io/explorer/Input.ChoiceSet.html) |

### Action Types

The **JS Class** column is the cross-SDK reference implementation to consult when
behavior is disputed — that reference role is this skill's job, unlike status.

| AC Type                   | Spec Page                                                                  | JS Class                 |
| ------------------------- | -------------------------------------------------------------------------- | ------------------------ |
| `Action.OpenUrl`          | [explorer](https://adaptivecards.io/explorer/Action.OpenUrl.html)          | `OpenUrlAction`          |
| `Action.Submit`           | [explorer](https://adaptivecards.io/explorer/Action.Submit.html)           | `SubmitAction`           |
| `Action.ShowCard`         | [explorer](https://adaptivecards.io/explorer/Action.ShowCard.html)         | `ShowCardAction`         |
| `Action.ToggleVisibility` | [explorer](https://adaptivecards.io/explorer/Action.ToggleVisibility.html) | `ToggleVisibilityAction` |
| `Action.Execute` (v1.4)   | [explorer](https://adaptivecards.io/explorer/Action.Execute.html)          | —                        |

---

## Spec Compliance Rules

These describe what the **spec requires** — the contract to implement against.
For whether this library currently satisfies each rule, read the README
**[Known gaps](../../../packages/flutter_adaptive_cards_fs/README.md#known-gaps)**
(the owner of that status); don't rely on a status verdict restated here.

### Unknown / Unsupported Types

The spec requires that **unknown element types be silently ignored** (not crash),
with the `fallback` property rendered instead if present. In this library unknown
types return `AdaptiveUnknown` (an error display) from
`CardTypeRegistry._getBaseElement()` unless a `fallback` resolves first.

### `requires` Property

The `requires` property lets a card declare minimum SDK feature requirements; a
conformant host skips rendering elements whose `requires` are not met, falling
back to `fallbackText`. Confirm current support in the README Known gaps
(**`requires` + version gating**) before relying on it.

### Fallback Property

Every element and action can declare a `fallback` — either `"drop"` (render
nothing) or a replacement element/action object resolved recursively. Element and
action fallback are at **different** levels of completeness in this library, so
verify `fallback` behavior against the README (**Action `fallback`** row) when
implementing any new element or action type.

### versioning

Cards declare `"version": "1.x"`. The spec expects a renderer to gracefully
degrade for cards declaring a higher version than it supports. Whether
per-element version-gating is enforced is tracked in the README Known gaps
(**`requires` + version gating**).

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

| Syntax                                           | Purpose                                            |
| ------------------------------------------------ | -------------------------------------------------- |
| `"${name}"`                                      | Property binding (exact match returns typed value) |
| `"${person.name}"`                               | Nested property access (dot notation)              |
| `"${items[0]}"`                                  | Array indexer or computed property access          |
| `"Hello ${name}!"`                               | String interpolation (always returns string)       |
| `"$data": "${items}"`                            | Binds current context to `items` array             |
| `"$data": "${items}"` on array → repeats element | Array repeater pattern                             |
| `"$when": "${price > 30}"`                       | Conditional element inclusion                      |
| `"$root"`                                        | Reference to root data context                     |
| `"$index"`                                       | Zero-based index within current array repetition   |

### Supported Operators (Adaptive Expressions)

| Category       | Operators                        |
| -------------- | -------------------------------- |
| **Logical**    | `&&`, `\|\|`, `!`                |
| **Comparison** | `==`, `!=`, `<`, `<=`, `>`, `>=` |
| **Arithmetic** | `+`, `-`, `*`, `/`, `%`, `^`     |

### Supported Functions

| Category       | Functions                                                                                                |
| -------------- | -------------------------------------------------------------------------------------------------------- |
| **Logic**      | `if(cond, t, f)`                                                                                         |
| **Parsing**    | `json(string)`                                                                                           |
| **String**     | `concat()`, `toUpper()`, `toLower()`, `trim()`, `substring(str, start, [len])`, `replace(str, old, new)` |
| **Math**       | `min()`, `max()`, `round()`, `floor()`, `ceil()`                                                         |
| **Collection** | `length()`, `empty()`                                                                                    |

### Flutter Template Library (`flutter_adaptive_template_fs`)

Location: `packages/flutter_adaptive_template_fs/lib/src/`

| File             | Purpose                                                  |
| ---------------- | -------------------------------------------------------- |
| `evaluator.dart` | Core template expansion engine — traverses the JSON tree |
| `resolver.dart`  | Property path resolution (e.g. `"person.name"` → value)  |
| `template.dart`  | Public `Template` class wrapping `Evaluator`             |

**Key implementation details:**

- `Evaluator` maintains a `_dataStack` and `_scopeStack` for nested `$data` contexts
- **Expression Parsing:** Uses a recursive-descent `ExpressionParser` that produces an Abstract Syntax Tree (`AstNode`).
- **AST Evaluation:** `Evaluator._evaluateAst` handles literals, identifiers, member access, operations, and function calls.
- `$data` pointing to an array triggers the repeater: the element produces
  a `List<Map>` instead of a single `Map`, which `_expandList` flattens
- `$when` is evaluated as a boolean; `null` or `false` → element is excluded (`null` returned)
- **Gap:** While a robust subset of **Adaptive Expressions** is implemented, the full Azure Bot Service library (100+ functions) is not exhaustive. `formatDateTime` is implemented; missing are the other date functions (`utcNow`, `addDays`, `formatEpoch`, `getFutureTime`) and advanced collection manipulation (`select`, `where`, `join`, `first`, `last`).
  Spec URL: <https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions>

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

### Date and Time Formatting

- **Text Macros (`{{DATE}}`, `{{TIME}}`)**: Implementations across TextBlock and FactSet use standard Dart `intl` formatters as a close approximation to the Adaptive Cards specification for C#-style time formatting. Localization accuracy and format strings might slightly differ from the Microsoft SDK reference.
- **Adaptive Expressions (`formatDateTime`)**: The `formatDateTime` function approximation relies on standard Dart date strings and may not yield strict parity with all custom C# `ToString()` format sequences available in the .NET SDK.

---

## Known Gaps

The catalog of what this library does **not** yet implement is owned by the
package READMEs, so it stays in one place and cannot drift against a second copy:

- Core elements/inputs/actions/HostConfig and cross-cutting gaps (`requires` +
  version gating, action `fallback`, `Table` completeness, text features, …) →
  [`flutter_adaptive_cards_fs` README § Known gaps](../../../packages/flutter_adaptive_cards_fs/README.md#known-gaps).
- Templating / Adaptive Expressions coverage (which functions are implemented) →
  [`flutter_adaptive_template_fs` README](../../../packages/flutter_adaptive_template_fs/README.md#feature-coverage)
  and the **`adaptive-cards-templating`** skill.
- Project-level roadmap and history →
  [`docs/Implementation-Status.md`](../../../docs/Implementation-Status.md).

When a gap here touches your feature, cite the README row in your plan rather than
copying its text — this skill's job is the spec contract, not the gap ledger.

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

6. **Check the README [Known gaps](../../../packages/flutter_adaptive_cards_fs/README.md#known-gaps)** — if the feature
   touches a gap area, cite that row explicitly in your implementation plan.

7. **For templating features**, verify against the
   [Templating Language spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)
   and check that `Evaluator` handles the relevant syntax.
