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
| RichTextBlock | [spec](https://adaptivecards.io/explorer/RichTextBlock.html) | ❌ Missing     | ❌ No      | -                                                      | Noted in README defects     |
| TextRun       | [spec](https://adaptivecards.io/explorer/TextRun.html)       | ❌ Missing     | ❌ No      | -                                                      | Noted in README defects     |
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

---

## Actions

| Action                  | Microsoft Spec                                                         | Implementation | Tests  | Documentation                                        | Notes                             |
| ----------------------- | ---------------------------------------------------------------------- | -------------- | ------ | ---------------------------------------------------- | --------------------------------- |
| Action.Execute          | [spec](https://adaptivecards.io/explorer/Action.Execute.html)          | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern         |
| Action.OpenUrl          | [spec](https://adaptivecards.io/explorer/Action.OpenUrl.html)          | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern         |
| Action.ShowCard         | [spec](https://adaptivecards.io/explorer/Action.ShowCard.html)         | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern         |
| Action.Submit           | [spec](https://adaptivecards.io/explorer/Action.Submit.html)           | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern         |
| Action.ToggleVisibility | [spec](https://adaptivecards.io/explorer/Action.ToggleVisibility.html) | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern         |
| Action.OpenUrlDialog    | -                                                                      | ⚠️ Incorrect   | ❌ No  | -                                                    | Should fetch URL & show in dialog |

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

## Templating (flutter_adaptive_template package)

| Feature             | Microsoft Spec                                                               | Implementation | Tests      | Documentation                                        | Notes            |
| ------------------- | ---------------------------------------------------------------------------- | -------------- | ---------- | ---------------------------------------------------- | ---------------- |
| Template Expansion  | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/)         | 📝 Designed    | ⚠️ Unknown | [JSON-Template-Design.md](./JSON-Template-Design.md) | Separate package |
| `$data` Scoping     | [spec](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) | 📝 Designed    | ⚠️ Unknown | [JSON-Template-Design.md](./JSON-Template-Design.md) | -                |
| `$root` Reference   | spec                                                                         | 📝 Designed    | ⚠️ Unknown | [JSON-Template-Design.md](./JSON-Template-Design.md) | -                |
| `$index` in Arrays  | spec                                                                         | 📝 Designed    | ⚠️ Unknown | [JSON-Template-Design.md](./JSON-Template-Design.md) | -                |
| Array Binding       | spec                                                                         | 📝 Designed    | ⚠️ Unknown | [JSON-Template-Design.md](./JSON-Template-Design.md) | -                |
| `$when` Conditional | spec                                                                         | 📝 Designed    | ⚠️ Unknown | [JSON-Template-Design.md](./JSON-Template-Design.md) | -                |
| `json()` Function   | spec                                                                         | 📝 Designed    | ⚠️ Unknown | [JSON-Template-Design.md](./JSON-Template-Design.md) | -                |
| `if()` Expressions  | spec                                                                         | 📝 Designed    | ⚠️ Unknown | [JSON-Template-Design.md](./JSON-Template-Design.md) | -                |

**Note**: Templating implementation status needs verification in `packages/flutter_adaptive_template/`

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
| `fallback`        | All elements    | ⚠️ Unknown            | -                                                                                      | Error handling            |
| `requires`        | All elements    | ⚠️ Unknown            | -                                                                                      | Version requirements      |
| `selectAction`    | Some elements   | ✅ Complete           | -                                                                                      | Tap handling              |
| `backgroundImage` | Card/Container  | ⚠️ Needs Verification | [backgroundImage.md](./backgroundImage.md)                                             | String & object forms     |

---

## Custom/Extended Elements

These are implemented but not part of the standard Microsoft specification:

| Element           | Implementation | Tests      | Documentation | Notes           |
| ----------------- | -------------- | ---------- | ------------- | --------------- |
| Badge             | ✅ Complete    | ⚠️ Limited | -             | Custom element  |
| Carousel          | ✅ Complete    | ⚠️ Limited | -             | Custom element  |
| ProgressBar       | ✅ Complete    | ⚠️ Limited | -             | Custom element  |
| ProgressRing      | ✅ Complete    | ⚠️ Limited | -             | Custom element  |
| TabSet            | ✅ Complete    | ⚠️ Limited | -             | Custom element  |
| Charts (multiple) | ✅ Complete    | ⚠️ Limited | -             | Custom elements |

---

## Priority Recommendations

### High Priority

1. **Fix ColumnSet Height Bug**: Verify and fix inconsistent Column heights ([doc](./Column-ColumnSet-Fill-Vertical-Height.md))
2. **Verify backgroundImage**: Confirm both string and object forms work ([doc](./backgroundImage.md))
3. **Fix Action.OpenUrlDialog**: Implement correct fetch-and-show behavior
4. **Verify Template Package**: Check implementation status of `flutter_adaptive_template`

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
ls -1 packages/flutter_adaptive_cards_plus/lib/src/hostconfig/*.dart | wc -l

# Count HostConfig tests
ls -1 packages/flutter_adaptive_cards_plus/test/hostconfig/*_test.dart | wc -l

# Count input types
ls -1 packages/flutter_adaptive_cards_plus/lib/src/inputs/*.dart | wc -l

# Count input tests
ls -1 packages/flutter_adaptive_cards_plus/test/inputs/*_test.dart | wc -l

# Run non-golden tests
cd packages/flutter_adaptive_cards_plus
flutter test --exclude-tags=golden
```

---

_Last Updated: 2026-02-13_
_Based on v1.6.0 of Microsoft Adaptive Cards specification_
