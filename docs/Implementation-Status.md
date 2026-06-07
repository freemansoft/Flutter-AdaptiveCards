# Implementation Status Matrix

This document tracks the implementation status of Adaptive Cards elements, containers, inputs, and actions against the Microsoft Adaptive Cards v1.6 specification.

**Legend**:

- ✅ **Complete**: Fully implemented and tested
- ⚠️ **Partial**: Implemented but incomplete or using workarounds
- ❌ **Missing**: Not implemented
- 📝 **Planned**: Documented or planned for future implementation

---

## Card Elements

| Element       | Microsoft Spec                                               | Implementation | Tests      | Documentation                                          | Notes                       |
| ------------- | ------------------------------------------------------------ | -------------- | ---------- | ------------------------------------------------------ | --------------------------- |
| TextBlock     | [spec](https://adaptivecards.io/explorer/TextBlock.html)     | ✅ Complete    | ✅ Yes     | -                                                      | Core element                |
| Image         | [spec](https://adaptivecards.io/explorer/Image.html)         | ✅ Complete    | ✅ Yes     | [Encoded-Image-Support.md](./Encoded-Image-Support.md) | Supports base64             |
| Media         | [spec](https://adaptivecards.io/explorer/Media.html)         | ⚠️ Partial     | ⚠️ Limited | -                                                      | Poster attribute has issues |
| MediaSource   | [spec](https://adaptivecards.io/explorer/MediaSource.html)   | ✅ Complete    | ✅ Yes     | -                                                      | Typed `MediaSource` model |
| RichTextBlock | [spec](https://adaptivecards.io/explorer/RichTextBlock.html) | ❌ Missing     | ❌ No      | -                                                      | Required since AC spec v1.2 |
| TextRun       | [spec](https://adaptivecards.io/explorer/TextRun.html)       | ❌ Missing     | ❌ No      | -                                                      | Required since AC spec v1.2 |
| ActionSet     | [spec](https://adaptivecards.io/explorer/ActionSet.html)     | ✅ Complete    | ⚠️ Limited | -                                                      | -                           |

---

## Containers

| Container | Microsoft Spec                                           | Implementation | Tests      | Documentation                                                                          | Notes                                                                |
| --------- | -------------------------------------------------------- | -------------- | ---------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Container | [spec](https://adaptivecards.io/explorer/Container.html) | ✅ Complete    | ✅ Yes     | -                                                                                      | Core container                                                       |
| ColumnSet | [spec](https://adaptivecards.io/explorer/ColumnSet.html) | ⚠️ Partial     | ⚠️ Limited | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | Height bug noted                                                     |
| Column    | [spec](https://adaptivecards.io/explorer/Column.html)    | ⚠️ Partial     | ⚠️ Limited | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | Height bug noted                                                     |
| FactSet   | [spec](https://adaptivecards.io/explorer/FactSet.html)   | ✅ Complete    | ✅ Yes     | -                                                                                      | -                                                                    |
| Fact      | [spec](https://adaptivecards.io/explorer/Fact.html)      | ✅ Complete    | ✅ Yes     | -                                                                                      | Typed `Fact` model |
| ImageSet  | [spec](https://adaptivecards.io/explorer/ImageSet.html)  | ✅ Complete    | ⚠️ Limited | -                                                                                      | -                                                                    |
| Table     | [spec](https://adaptivecards.io/explorer/Table.html)     | ⚠️ Partial     | ⚠️ Basic   | -                                                                                      | Minimal implementation, missing attributes                           |
| TableCell | [spec](https://adaptivecards.io/explorer/TableCell.html) | ⚠️ Inline      | ✅ Yes     | -                                                                                      | Implemented inline in Table; selectAction fully supported and tested |
| TableRow  | [spec](https://adaptivecards.io/explorer/TableRow.html)  | ⚠️ Partial     | ❌ No      | -                                                                                      | Part of Table implementation                                         |

---

## Inputs

| Input           | Microsoft Spec                                                 | Implementation | Tests  | Documentation                      | Notes                                                                                                                                                                         |
| --------------- | -------------------------------------------------------------- | -------------- | ------ | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Input.Text      | [spec](https://adaptivecards.io/explorer/Input.Text.html)      | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Flutter Form-based                                                                                                                                                            |
| Input.Number    | [spec](https://adaptivecards.io/explorer/Input.Number.html)    | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Flutter Form-based                                                                                                                                                            |
| Input.Date      | [spec](https://adaptivecards.io/explorer/Input.Date.html)      | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Material/Cupertino pickers                                                                                                                                                    |
| Input.Time      | [spec](https://adaptivecards.io/explorer/Input.Time.html)      | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Material/Cupertino pickers                                                                                                                                                    |
| Input.Toggle    | [spec](https://adaptivecards.io/explorer/Input.Toggle.html)    | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Flutter Form-based                                                                                                                                                            |
| Input.ChoiceSet | [spec](https://adaptivecards.io/explorer/Input.ChoiceSet.html) | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Compact, multiselect, filtered (search/list **titles**; submit **values**); `choices.data` / `Data.Query`; **`associatedInputs` not applied** — see [Known Gaps](#known-gaps) |
| Input.Choice    | [spec](https://adaptivecards.io/explorer/Input.Choice.html)    | ✅ Complete    | ✅ Yes | -                                  | Typed `Choice` model; overlay uses `List<Choice>` |

> [!NOTE]
> All standard input implementations (`Input.Text`, `Input.Number`, `Input.Date`, `Input.Time`, `Input.Toggle`, `Input.ChoiceSet`) fully implement `appendInput()`, `initInput()`, `checkRequired()`, and `resetInput()` methods. These elements have been verified to use the mixin-inherited `value` property exclusively, without directly accessing `adaptiveMap['value']` after initialization. **`Action.ResetInputs`** and host **`resetInput(id)`** / **`resetAllInputs()`** factory-reset input overlays (including `label`, `placeholder`, `isRequired`) to baseline — see [Reset semantics](./reactive-riverpod.md#reset-semantics) and [form-inputs.md](./form-inputs.md#reset-behavior-resetallinputs--resetinput).

---

## Actions

| Action                  | Microsoft Spec                                                                                                            | Implementation | Tests  | Documentation                                        | Notes                                                                         |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------- | ------ | ---------------------------------------------------- | ----------------------------------------------------------------------------- |
| Action.Execute          | [spec](https://adaptivecards.io/explorer/Action.Execute.html)                                                             | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | **`verb`** and **`id`** via **`ExecuteActionInvoke`** on `onExecute`; merged `data` + inputs. **`associatedInputs`** not implemented — see [Known Gaps](#known-gaps). |
| Action.OpenUrl          | [spec](https://adaptivecards.io/explorer/Action.OpenUrl.html)                                                             | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                                                     |
| Action.ShowCard         | [spec](https://adaptivecards.io/explorer/Action.ShowCard.html)                                                            | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                                                     |
| Action.Submit           | [spec](https://adaptivecards.io/explorer/Action.Submit.html)                                                              | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | **`id`** as **`actionId`** via **`SubmitActionInvoke`** on `onSubmit`; merged `data` + inputs. **`associatedInputs`** not implemented — see [Known Gaps](#known-gaps). |
| Action.ToggleVisibility | [spec](https://adaptivecards.io/explorer/Action.ToggleVisibility.html)                                                    | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                                                     |
| Action.OpenUrlDialog    | [Teams ext](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-actions)         | ✅ Complete    | ❌ No  | [actions-architecture.md](./actions-architecture.md) | **Teams extension** (schema v1.5+) — launches modal/task module dialog        |
| Action.ResetInputs      | [Bot Framework ext](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-actions) | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | **`targetInputIds`**, **`valueChangedAction`**; Teams/Bot Framework extension |
| Action.InsertImage      | Host-specific ext                                                                                                         | ✅ Complete    | ❌ No  | -                                                    | **Host extension** (Word/PowerPoint, v1.5+) — inserts image into host canvas  |
| Action.Popover          | -                                                                                                                         | ✅ Complete    | ❌ No  | -                                                    | **Project-specific** — no known spec source; popover overlay                  |

---

## HostConfig

| Config Component       | Microsoft Spec                                                                          | Implementation | Tests  | Documentation                            | Notes              |
| ---------------------- | --------------------------------------------------------------------------------------- | -------------- | ------ | ---------------------------------------- | ------------------ |
| HostConfig (root)      | [schema](https://github.com/microsoft/AdaptiveCards/blob/main/schemas/host-config.json) | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | Main config object |
| AdaptiveCardConfig     | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| ActionsConfig          | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| ContainerStylesConfig  | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| ContainerStyleConfig   | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| ForegroundColorsConfig | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| FontColorConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| FontSizesConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| FontWeightsConfig      | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| FactSetConfig          | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| ImageSetConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| ImageSizesConfig       | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| InputsConfig           | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| LabelConfig            | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| ErrorMessageConfig     | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| MediaConfig            | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| SeparatorConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| ShowCardConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| SpacingsConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |
| TextStylesConfig       | schema                                                                                  | ✅ Complete    | ✅ Yes | [adaptive-style.md](./adaptive-style.md) | -                  |

**Total HostConfig Classes**: All HostConfig classes have been extracted to individual files (per `lib/src/hostconfig/`).

---

## Templating (flutter_adaptive_template_fs package)

| Feature              | Microsoft Spec                                                                                                           | Implementation | Tests  | Documentation                                                | Notes                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------- | ------ | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| Template Expansion   | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/)                                                     | ✅ Complete    | ✅ Yes | [adaptive-template-design.md](./adaptive-template-design.md) | `Evaluator` in `flutter_adaptive_template_fs`                                                   |
| `$data` Scoping      | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)                                             | ✅ Complete    | ✅ Yes | [adaptive-template-design.md](./adaptive-template-design.md) | `_dataStack` in `Evaluator`                                                                     |
| `$root` Reference    | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)                                             | ✅ Complete    | ✅ Yes | [adaptive-template-design.md](./adaptive-template-design.md) | Scoped via `_scopeStack`                                                                        |
| `$index` in Arrays   | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)                                             | ✅ Complete    | ✅ Yes | [adaptive-template-design.md](./adaptive-template-design.md) | Available during array repetition                                                               |
| Array Binding        | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)                                             | ✅ Complete    | ✅ Yes | [adaptive-template-design.md](./adaptive-template-design.md) | `$data` pointing to array triggers repeater                                                     |
| `$when` Conditional  | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)                                             | ✅ Complete    | ✅ Yes | [adaptive-template-design.md](./adaptive-template-design.md) | `null`/`false` → element excluded                                                               |
| `json()` Function    | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)                                             | ✅ Complete    | ✅ Yes | [adaptive-template-design.md](./adaptive-template-design.md) | Parses embedded JSON strings                                                                    |
| `if()` Expressions   | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)                                             | ✅ Complete    | ✅ Yes | [adaptive-template-design.md](./adaptive-template-design.md) | Conditional value selection                                                                     |
| Adaptive Expressions | [spec](https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions) | ⚠️ Partial     | ✅ Yes | -                                                            | Operators, string, math, logic implemented; Date/Time and advanced collection functions missing |

---

## Common Properties

| Property              | Microsoft Spec  | Implementation | Documentation                                                                          | Notes                                                                                                                                                                   |
| --------------------- | --------------- | -------------- | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                  | All elements    | ✅ Complete    | [AdaptiveWidget-Key-Generation.md](./AdaptiveWidget-Key-Generation.md)                 | Used for key generation                                                                                                                                                 |
| `isVisible`           | All elements    | ✅ Complete    | [Implementing-IsVisible.md](./Implementing-IsVisible.md)                               | Visibility widget wrapper                                                                                                                                               |
| `separator`           | Most elements   | ✅ Complete    | -                                                                                      | Visual separators                                                                                                                                                       |
| `spacing`             | Most elements   | ✅ Complete    | -                                                                                      | Layout spacing                                                                                                                                                          |
| `height`              | Elements        | ⚠️ Partial     | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | Known issues                                                                                                                                                            |
| `style`               | Containers/Text | ✅ Complete    | [Style-Design.md](./Style-Design.md)                                                   | HostConfig-based                                                                                                                                                        |
| `fallback` (elements) | All elements    | ✅ Complete    | -                                                                                      | Handled in `CardTypeRegistry`                                                                                                                                           |
| `fallback` (actions)  | All actions     | ❌ Missing     | -                                                                                      | `_getActionWidget` ends in `assert(false)`; no fallback check                                                                                                           |
| `requires`            | All elements    | ❌ Missing     | -                                                                                      | Version requirement validation not implemented                                                                                                                          |
| `selectAction`        | Some elements   | ✅ Complete    | -                                                                                      | Confirmed on Container, Column, ColumnSet, Image, and TableCell.                                                                                                        |
| `backgroundImage`     | Card/Container  | ✅ Complete    | [backgroundImage.md](./backgroundImage.md)                                             | Parsed via mixin for Container, Column, ColumnSet, TableCell; fully tested (both string and object forms), including empty aspect-ratio sizing and `minHeight` support. |

---

## Known Gaps

The following spec compliance gaps are known across the codebase:

- **`requires`**: Version requirement validation is not implemented.
- **Action Fallback**: `_getActionWidget` ends in `assert(false)` with no fallback check.
- **Dark Mode**: Some specific color invert issues or missing HostConfig support.
- **Version Gating**: Missing support to skip rendering elements with a higher version requirement.
- **`RichTextBlock` & `TextRun`**: Missing elements required since AC spec v1.2.
- **`Data.Query.associatedInputs`**: Parsed on `choices.data` but not merged into host `onChange` / `DataQuery` (Teams dependent-input sibling values). Widgetbook demonstrates the workaround — [form-inputs.md § Dependent ChoiceSet](./form-inputs.md#dependent-choiceset-country--city).
- **`Action.Submit.associatedInputs`** / **`Action.Execute.associatedInputs`**: All inputs on the card are always collected and merged into invoke `data`; per-action `associatedInputs` (`auto` / `none`) is not implemented.

---

## Custom/Extended Elements

These are implemented but not part of the standard Microsoft specification.
All are registered in `CardTypeRegistry` (`lib/src/registry.dart`).

| Element           | JSON Type String   | Implementation | Tests      | Documentation | Notes                                              |
| ----------------- | ------------------ | -------------- | ---------- | ------------- | -------------------------------------------------- |
| Badge             | `Badge`            | ✅ Complete    | ⚠️ Limited | -             | Custom element; has HostConfig `BadgeStylesConfig` |
| Carousel          | `Carousel`         | ✅ Complete    | ⚠️ Limited | -             | Custom element; child pages use `CarouselPage`     |
| CarouselPage      | `CarouselPage`     | ✅ Complete    | ⚠️ Limited | -             | Child element of `Carousel`                        |
| Accordion         | `Accordion`        | ✅ Complete    | ⚠️ Limited | -             | Custom collapsible element                         |
| ProgressBar       | `ProgressBar`      | ✅ Complete    | ⚠️ Limited | -             | Custom element                                     |
| ProgressRing      | `ProgressRing`     | ✅ Complete    | ⚠️ Limited | -             | Custom element                                     |
| Rating            | `Rating`           | ✅ Complete    | ⚠️ Limited | -             | Custom element; also registered as `Input.Rating`  |
| CodeBlock         | `CodeBlock`        | ✅ Complete    | ⚠️ Limited | -             | Custom code display element                        |
| CompoundButton    | `CompoundButton`   | ✅ Complete    | ⚠️ Limited | -             | Custom button with icon + text                     |
| TabSet            | `TabSet`           | ✅ Complete    | ⚠️ Limited | -             | Custom tab container                               |
| Charts (multiple) | _(via Charts pkg)_ | ✅ Complete    | ⚠️ Limited | -             | Custom elements in `flutter_adaptive_charts_fs`    |

---

## Priority Recommendations

### High Priority

1. **Fix ColumnSet Height Bug**: Verify and fix inconsistent Column heights ([doc](./Column-ColumnSet-Fill-Vertical-Height.md))

### Medium Priority

1. **Complete Table Implementation**: Add column sizing, grid styles, etc.

### Low Priority

1. **Media Poster Fix**: Resolve poster attribute display issue
2. **Test Coverage**: Expand test coverage for partial implementations
3. **Documentation**: Add implementation links to all doc files
4. **Add RichTextBlock & TextRun**: Design docs first, then implement
5. **Implement `fallback` for Actions**: `_getActionWidget` currently ends in `assert(false)` with no fallback processing
6. **Implement `requires` property validation**: Skip elements that declare version requirements the renderer cannot meet

---

## Verification Commands

```bash
# Count implemented HostConfig entities
ls -1 packages/flutter_adaptive_cards_fs/lib/src/hostconfig/*.dart | wc -l

# Count HostConfig tests
ls -1 packages/flutter_adaptive_cards_fs/test/hostconfig/*_test.dart | wc -l

# Count input types
ls -1 packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/*.dart | wc -l

# Count input tests
ls -1 packages/flutter_adaptive_cards_fs/test/inputs/*_test.dart | wc -l

# Run non-golden tests
cd packages/flutter_adaptive_cards_fs
flutter test --exclude-tags=golden

# Note: Golden tests are platform-specific and stored in subdirectories (e.g., gold_files/linux/)
```

---

_Last Updated: 2026-05-19_
_Based on v1.6.0 of Microsoft Adaptive Cards specification_
