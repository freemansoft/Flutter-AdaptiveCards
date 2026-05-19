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
| MediaSource   | [spec](https://adaptivecards.io/explorer/MediaSource.html)   | ⚠️ Map         | ❌ No      | -                                                      | Implemented as map in Media |
| RichTextBlock | [spec](https://adaptivecards.io/explorer/RichTextBlock.html) | ❌ Missing     | ❌ No      | -                                                      | Required since AC spec v1.2 |
| TextRun       | [spec](https://adaptivecards.io/explorer/TextRun.html)       | ❌ Missing     | ❌ No      | -                                                      | Required since AC spec v1.2 |
| ActionSet     | [spec](https://adaptivecards.io/explorer/ActionSet.html)     | ✅ Complete    | ⚠️ Limited | -                                                      | -                           |

---

## Containers

| Container | Microsoft Spec                                           | Implementation | Tests      | Documentation                                                                          | Notes                                      |
| --------- | -------------------------------------------------------- | -------------- | ---------- | -------------------------------------------------------------------------------------- | ------------------------------------------ |
| Container | [spec](https://adaptivecards.io/explorer/Container.html) | ✅ Complete    | ✅ Yes     | -                                                                                      | Core container                             |
| ColumnSet | [spec](https://adaptivecards.io/explorer/ColumnSet.html) | ⚠️ Partial     | ⚠️ Limited | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | Height bug noted                           |
| Column    | [spec](https://adaptivecards.io/explorer/Column.html)    | ⚠️ Partial     | ⚠️ Limited | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | Height bug noted                           |
| FactSet   | [spec](https://adaptivecards.io/explorer/FactSet.html)   | ✅ Complete    | ✅ Yes     | -                                                                                      | -                                          |
| Fact      | [spec](https://adaptivecards.io/explorer/Fact.html)      | ⚠️ Map         | ❌ No      | -                                                                                      | Implemented as map in FactSet              |
| ImageSet  | [spec](https://adaptivecards.io/explorer/ImageSet.html)  | ✅ Complete    | ⚠️ Limited | -                                                                                      | -                                          |
| Table     | [spec](https://adaptivecards.io/explorer/Table.html)     | ⚠️ Partial     | ⚠️ Basic   | -                                                                                      | Minimal implementation, missing attributes |
| TableCell | [spec](https://adaptivecards.io/explorer/TableCell.html) | ⚠️ Inline      | ❌ No      | -                                                                                      | Implemented inline in Table                |
| TableRow  | [spec](https://adaptivecards.io/explorer/TableRow.html)  | ⚠️ Partial     | ❌ No      | -                                                                                      | Part of Table implementation               |

---

## Inputs

| Input           | Microsoft Spec                                                 | Implementation | Tests  | Documentation                                                  | Notes                           |
| --------------- | -------------------------------------------------------------- | -------------- | ------ | -------------------------------------------------------------- | ------------------------------- |
| Input.Text      | [spec](https://adaptivecards.io/explorer/Input.Text.html)      | ✅ Complete    | ✅ Yes | [Using-Flutter-Form-Inputs.md](./Using-Flutter-Form-Inputs.md) | Flutter Form-based              |
| Input.Number    | [spec](https://adaptivecards.io/explorer/Input.Number.html)    | ✅ Complete    | ✅ Yes | [Using-Flutter-Form-Inputs.md](./Using-Flutter-Form-Inputs.md) | Flutter Form-based              |
| Input.Date      | [spec](https://adaptivecards.io/explorer/Input.Date.html)      | ✅ Complete    | ✅ Yes | [Using-Flutter-Form-Inputs.md](./Using-Flutter-Form-Inputs.md) | Material/Cupertino pickers      |
| Input.Time      | [spec](https://adaptivecards.io/explorer/Input.Time.html)      | ✅ Complete    | ✅ Yes | [Using-Flutter-Form-Inputs.md](./Using-Flutter-Form-Inputs.md) | Material/Cupertino pickers      |
| Input.Toggle    | [spec](https://adaptivecards.io/explorer/Input.Toggle.html)    | ✅ Complete    | ✅ Yes | [Using-Flutter-Form-Inputs.md](./Using-Flutter-Form-Inputs.md) | Flutter Form-based              |
| Input.ChoiceSet | [spec](https://adaptivecards.io/explorer/Input.ChoiceSet.html) | ✅ Complete    | ✅ Yes | [Using-Flutter-Form-Inputs.md](./Using-Flutter-Form-Inputs.md) | Compact & multiselect           |
| Input.Choice    | [spec](https://adaptivecards.io/explorer/Input.Choice.html)    | ⚠️ Map         | ❌ No  | -                                                              | Implemented as map in ChoiceSet |

> [!NOTE]
> All standard input implementations (`Input.Text`, `Input.Number`, `Input.Date`, `Input.Time`, `Input.Toggle`, `Input.ChoiceSet`) fully implement `appendInput()`, `initInput()`, `checkRequired()`, and `resetInput()` methods. These elements have been verified to use the mixin-inherited `value` property exclusively, without directly accessing `adaptiveMap['value']` after initialization.

---

## Actions

| Action                  | Microsoft Spec                                                         | Implementation | Tests  | Documentation                                        | Notes                                       |
| ----------------------- | ---------------------------------------------------------------------- | -------------- | ------ | ---------------------------------------------------- | ------------------------------------------- |
| Action.Execute          | [spec](https://adaptivecards.io/explorer/Action.Execute.html)          | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                   |
| Action.OpenUrl          | [spec](https://adaptivecards.io/explorer/Action.OpenUrl.html)          | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                   |
| Action.ShowCard         | [spec](https://adaptivecards.io/explorer/Action.ShowCard.html)         | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                   |
| Action.Submit           | [spec](https://adaptivecards.io/explorer/Action.Submit.html)           | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                   |
| Action.ToggleVisibility | [spec](https://adaptivecards.io/explorer/Action.ToggleVisibility.html) | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                   |
| Action.OpenUrlDialog    | [Teams ext](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-actions) | ✅ Complete | ❌ No | [actions-architecture.md](./actions-architecture.md) | **Teams extension** (schema v1.5+) — launches modal/task module dialog |
| Action.ResetInputs      | [Bot Framework ext](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-actions) | ✅ Complete | ❌ No | - | **Teams/Bot Framework extension** — resets input fields; used with `valueChangedAction` |
| Action.InsertImage      | Host-specific ext                                                      | ✅ Complete    | ❌ No  | -                                                    | **Host extension** (Word/PowerPoint, v1.5+) — inserts image into host canvas |
| Action.Popover          | -                                                                      | ✅ Complete    | ❌ No  | -                                                    | **Project-specific** — no known spec source; popover overlay |

---

## HostConfig

| Config Component       | Microsoft Spec                                                                          | Implementation | Tests  | Documentation                        | Notes              |
| ---------------------- | --------------------------------------------------------------------------------------- | -------------- | ------ | ------------------------------------ | ------------------ |
| HostConfig (root)      | [schema](https://github.com/microsoft/AdaptiveCards/blob/main/schemas/host-config.json) | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | Main config object |
| AdaptiveCardConfig     | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| ActionsConfig          | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| ContainerStylesConfig  | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| ContainerStyleConfig   | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| ForegroundColorsConfig | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| FontColorConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| FontSizesConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| FontWeightsConfig      | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| FactSetConfig          | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| ImageSetConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| ImageSizesConfig       | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| InputsConfig           | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| LabelConfig            | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| ErrorMessageConfig     | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| MediaConfig            | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| SeparatorConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| ShowCardConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| SpacingsConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |
| TextStylesConfig       | schema                                                                                  | ✅ Complete    | ✅ Yes | [Style-Design.md](./Style-Design.md) | -                  |

**Total HostConfig Classes**: 19 entities implemented (per `lib/src/hostconfig/`)

---

## Templating (flutter_adaptive_template_fs package)

| Feature             | Microsoft Spec                                                               | Implementation | Tests   | Documentation                                        | Notes                                        |
| ------------------- | ---------------------------------------------------------------------------- | -------------- | ------- | ---------------------------------------------------- | -------------------------------------------- |
| Template Expansion  | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/)         | ✅ Complete    | ✅ Yes  | [JSON-Template-Design.md](./JSON-Template-Design.md) | `Evaluator` in `flutter_adaptive_template_fs` |
| `$data` Scoping     | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) | ✅ Complete    | ✅ Yes  | [JSON-Template-Design.md](./JSON-Template-Design.md) | `_dataStack` in `Evaluator`                  |
| `$root` Reference   | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) | ✅ Complete    | ✅ Yes  | [JSON-Template-Design.md](./JSON-Template-Design.md) | Scoped via `_scopeStack`                     |
| `$index` in Arrays  | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) | ✅ Complete    | ✅ Yes  | [JSON-Template-Design.md](./JSON-Template-Design.md) | Available during array repetition            |
| Array Binding       | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) | ✅ Complete    | ✅ Yes  | [JSON-Template-Design.md](./JSON-Template-Design.md) | `$data` pointing to array triggers repeater  |
| `$when` Conditional | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) | ✅ Complete    | ✅ Yes  | [JSON-Template-Design.md](./JSON-Template-Design.md) | `null`/`false` → element excluded            |
| `json()` Function   | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) | ✅ Complete    | ✅ Yes  | [JSON-Template-Design.md](./JSON-Template-Design.md) | Parses embedded JSON strings                 |
| `if()` Expressions  | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) | ✅ Complete    | ✅ Yes  | [JSON-Template-Design.md](./JSON-Template-Design.md) | Conditional value selection                  |
| Adaptive Expressions | [spec](https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions) | ⚠️ Partial | ✅ Yes | - | Operators, string, math, logic implemented; Date/Time and advanced collection functions missing |

---

## Common Properties

| Property          | Microsoft Spec  | Implementation        | Documentation                                                                          | Notes                     |
| ----------------- | --------------- | --------------------- | -------------------------------------------------------------------------------------- | ------------------------- |
| `id`              | All elements    | ✅ Complete           | [AdaptiveWidget-Key-Generation.md](./AdaptiveWidget-Key-Generation.md)                 | Used for key generation   |
| `isVisible`       | All elements    | ✅ Complete           | [Implementing-IsVisible.md](./Implementing-IsVisible.md)                               | Visibility widget wrapper |
| `separator`       | Most elements   | ✅ Complete           | -                                                                                      | Visual separators         |
| `spacing`         | Most elements   | ✅ Complete           | -                                                                                      | Layout spacing            |
| `height`          | Elements        | ⚠️ Partial            | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | Known issues              |
| `style`           | Containers/Text | ✅ Complete           | [Style-Design.md](./Style-Design.md)                                                   | HostConfig-based          |
| `fallback` (elements) | All elements | ✅ Complete          | -                                                                                      | Handled in `CardTypeRegistry` |
| `fallback` (actions)  | All actions  | ❌ Missing            | -                                                                                      | `_getActionWidget` ends in `assert(false)`; no fallback check |
| `requires`        | All elements    | ❌ Missing            | -                                                                                      | Version requirement validation not implemented |
| `selectAction`    | Some elements   | ✅ Complete           | -                                                                                      | Confirmed on Container, Column, ColumnSet, Image, and TableCell. |
| `backgroundImage` | Card/Container  | ⚠️ Partial            | [backgroundImage.md](./backgroundImage.md)                                             | Parsed via mixin for Container, Column, ColumnSet, TableCell; root card uses Stack, bypassing repeat/alignment parameters; alignment properties missing. |

---

## Custom/Extended Elements

These are implemented but not part of the standard Microsoft specification.
All are registered in `CardTypeRegistry` (`lib/src/registry.dart`).

| Element           | JSON Type String  | Implementation | Tests      | Documentation | Notes                                          |
| ----------------- | ----------------- | -------------- | ---------- | ------------- | ---------------------------------------------- |
| Badge             | `Badge`           | ✅ Complete    | ⚠️ Limited | -             | Custom element; has HostConfig `BadgeStylesConfig` |
| Carousel          | `Carousel`        | ✅ Complete    | ⚠️ Limited | -             | Custom element; child pages use `CarouselPage` |
| CarouselPage      | `CarouselPage`    | ✅ Complete    | ⚠️ Limited | -             | Child element of `Carousel`                    |
| Accordion         | `Accordion`       | ✅ Complete    | ⚠️ Limited | -             | Custom collapsible element                     |
| ProgressBar       | `ProgressBar`     | ✅ Complete    | ⚠️ Limited | -             | Custom element                                 |
| ProgressRing      | `ProgressRing`    | ✅ Complete    | ⚠️ Limited | -             | Custom element                                 |
| Rating            | `Rating`          | ✅ Complete    | ⚠️ Limited | -             | Custom element; also registered as `Input.Rating` |
| CodeBlock         | `CodeBlock`       | ✅ Complete    | ⚠️ Limited | -             | Custom code display element                    |
| CompoundButton    | `CompoundButton`  | ✅ Complete    | ⚠️ Limited | -             | Custom button with icon + text                 |
| TabSet            | `TabSet`          | ✅ Complete    | ⚠️ Limited | -             | Custom tab container                           |
| Charts (multiple) | _(via Charts pkg)_ | ✅ Complete   | ⚠️ Limited | -             | Custom elements in `flutter_adaptive_charts_fs` |

---

## Priority Recommendations

### High Priority

1. **Fix ColumnSet Height Bug**: Verify and fix inconsistent Column heights ([doc](./Column-ColumnSet-Fill-Vertical-Height.md))
2. **Verify backgroundImage**: Confirm both string and object forms work ([doc](./backgroundImage.md))
3. **Implement `fallback` for Actions**: `_getActionWidget` currently ends in `assert(false)` with no fallback processing
4. **Implement `requires` property validation**: Skip elements that declare version requirements the renderer cannot meet
5. **Verify `selectAction` on Image and TableCell**: Confirm or fix coverage to close the ⚠️ Partial gap

### Medium Priority

1. **Convert Maps to Classes**:
   - `MediaSource` → proper class
   - `Fact` → proper class
   - `Input.Choice` → proper class
   - `TableCell` → proper class

2. **Complete Table Implementation**: Add column sizing, grid styles, etc.

3. **Add RichTextBlock & TextRun**: Design docs first, then implement

### Low Priority

1. **Media Poster Fix**: Resolve poster attribute display issue
2. **Test Coverage**: Expand test coverage for partial implementations
3. **Documentation**: Add implementation links to all doc files

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
