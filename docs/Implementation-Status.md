# Implementation Status Matrix

This document tracks the implementation status of Adaptive Cards elements, containers, inputs, and actions against the Microsoft Adaptive Cards v1.6 specification.

**Optional packages:** Charts and templating are **not** in the core library — see [optional-packages-and-extensions.md](./optional-packages-and-extensions.md).

**June 2026 feature plan (complete):** Workstreams **A–G** in [2026-06-08-refresh-icon-charts-text-features.plan.md](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md). **Backend invoke (complete):** [backend-host-integration.md](./backend-host-integration.md).

**Reference sites**:

- [Adaptive Cards documentation hub](https://adaptivecards.microsoft.com/) (responsive layout, Icon, Charts, and other v1.6+ features)
- [Schema explorer](https://adaptivecards.io/explorer/)
- [Teams charts reference](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/charts-in-adaptive-cards)

**Legend**:

- ✅ **Complete**: Fully implemented and tested
- ⚠️ **Partial**: Implemented but incomplete or using workarounds
- ❌ **Missing**: Not implemented
- 📝 **Planned**: Documented or planned for future implementation

---

## Card Elements

| Element       | Microsoft Spec                                               | Implementation | Tests      | Documentation                                                                                                            | Notes                                                                                                                                       |
| ------------- | ------------------------------------------------------------ | -------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| TextBlock     | [spec](https://adaptivecards.io/explorer/TextBlock.html)     | ⚠️ Partial     | ✅ Yes     | [text features design](./superpowers/specs/2026-06-08-rich-text-and-text-features-design.md)                             | Markdown subset; plain path honors `maxLines`/`color`/`isSubtle`/`weight` when `supportMarkdown` is false; markdown path ignores `maxLines` |
| Image         | [spec](https://adaptivecards.io/explorer/Image.html)         | ✅ Complete    | ✅ Yes     | [Encoded-Image-Support.md](./Encoded-Image-Support.md)                                                                   | Supports base64; `selectAction` supported                                                                                                   |
| Media         | [spec](https://adaptivecards.io/explorer/Media.html)         | ⚠️ Partial     | ⚠️ Limited | -                                                                                                                        | Video via `video_player`; poster attribute has issues; limited on desktop platforms                                                         |
| MediaSource   | [spec](https://adaptivecards.io/explorer/MediaSource.html)   | ✅ Complete    | ✅ Yes     | -                                                                                                                        | Typed `MediaSource` model                                                                                                                   |
| CaptionSource | [spec](https://adaptivecards.io/explorer/CaptionSource.html) | ❌ Missing     | ❌ No      | -                                                                                                                        | Used with `Media`; not registered                                                                                                           |
| RichTextBlock | [spec](https://adaptivecards.io/explorer/RichTextBlock.html) | ✅ Complete    | ✅ Yes     | [text features design](./superpowers/specs/2026-06-08-rich-text-and-text-features-design.md)                             | `Text.rich` + `TextRun` inlines; per-run styling and `selectAction`                                                                         |
| TextRun       | [spec](https://adaptivecards.io/explorer/TextRun.html)       | ✅ Complete    | ✅ Yes     | same                                                                                                                     | Inline only (via `RichTextBlock.inlines`); weight, color, italic, underline, highlight, tap                                                 |
| ActionSet     | [spec](https://adaptivecards.io/explorer/ActionSet.html)     | ✅ Complete    | ⚠️ Limited | -                                                                                                                        | -                                                                                                                                           |
| Icon          | [hub](https://adaptivecards.microsoft.com/)                  | ⚠️ Partial     | ✅ Yes     | [plan workstream C](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md#workstream-c--icon-element) | ~68 Fluent names via Material icons; unknown → `help_outline`; `selectAction` supported                                                     |

---

## Containers

| Container | Microsoft Spec                                           | Implementation | Tests      | Documentation                                                                          | Notes                                                                         |
| --------- | -------------------------------------------------------- | -------------- | ---------- | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Container | [spec](https://adaptivecards.io/explorer/Container.html) | ⚠️ Partial     | ✅ Yes     | -                                                                                      | `minHeight` supported; `bleed` not implemented                                |
| ColumnSet | [spec](https://adaptivecards.io/explorer/ColumnSet.html) | ✅ Complete    | ✅ Yes     | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | Equal column heights fixed (`IntrinsicHeight` + stretch); see doc for history |
| Column    | [spec](https://adaptivecards.io/explorer/Column.html)    | ✅ Complete    | ✅ Yes     | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | Same height fix as ColumnSet                                                  |
| FactSet   | [spec](https://adaptivecards.io/explorer/FactSet.html)   | ✅ Complete    | ✅ Yes     | [reactive-riverpod.md](./reactive-riverpod.md)                                         | Runtime `facts` overlay (`setFacts` / `clearFacts`)                           |
| Fact      | [spec](https://adaptivecards.io/explorer/Fact.html)      | ✅ Complete    | ✅ Yes     | -                                                                                      | Typed `Fact` model                                                            |
| ImageSet  | [spec](https://adaptivecards.io/explorer/ImageSet.html)  | ✅ Complete    | ⚠️ Limited | -                                                                                      | -                                                                             |
| Table     | [spec](https://adaptivecards.io/explorer/Table.html)     | ⚠️ Partial     | ⚠️ Basic   | -                                                                                      | See [Table gaps](#table-gaps) below                                           |
| TableCell | [spec](https://adaptivecards.io/explorer/TableCell.html) | ⚠️ Inline      | ✅ Yes     | -                                                                                      | Implemented inline in Table; `selectAction` supported and tested              |
| TableRow  | [spec](https://adaptivecards.io/explorer/TableRow.html)  | ⚠️ Partial     | ❌ No      | -                                                                                      | Part of Table implementation                                                  |

### Table gaps

Implemented: `columns`, `rows`, `showGridLines`, `gridStyle`, `firstRowAsHeader`, cell alignment, header styling, `selectAction` on cells.

Not implemented or incomplete:

- Column `width` modes `auto` / `stretch` (numeric flex and `px` only)
- Cell-level `rtl` (parsed in `TableCellModel` but not applied in rendering)
- Block `height: stretch` on the table element
- `bleed` on cells or the table

Sample reference: [FlightUpdateTable.json](https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/FlightUpdateTable.json)

---

## Root `AdaptiveCard` Properties

| Property                       | Microsoft Spec                                              | Implementation | Notes                                                                                                                                                |
| ------------------------------ | ----------------------------------------------------------- | -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `body` / `actions` / `version` | [spec](https://adaptivecards.io/explorer/AdaptiveCard.html) | ✅ Complete    | Core rendering via `AdaptiveCardElement`                                                                                                             |
| `backgroundImage`              | spec                                                        | ✅ Complete    | [backgroundImage.md](./backgroundImage.md)                                                                                                           |
| `metadata`                     | spec (v1.6)                                                 | ⚠️ Partial     | `metadata.webUrl` read; full metadata model not implemented                                                                                          |
| `minHeight`                    | spec (v1.2)                                                 | ❌ Missing     | Not applied at card root                                                                                                                             |
| `rtl`                          | spec (v1.5)                                                 | ❌ Missing     | Not applied at card root                                                                                                                             |
| `fallbackText`                 | spec                                                        | ❌ Missing     | Not shown when card version exceeds renderer support                                                                                                 |
| `selectAction`                 | spec (v1.1)                                                 | ❌ Missing     | Card-level tap action not wired                                                                                                                      |
| `verticalContentAlignment`     | spec (v1.1)                                                 | ❌ Missing     | Not applied at card root                                                                                                                             |
| `refresh`                      | spec (v1.4)                                                 | ✅ Complete    | Manual affordance + auto-expire; `onRefresh` / `onExecute` fallback — [actions-architecture.md](./actions-architecture.md#root-card-refresh-payload) |
| `authentication`               | spec (v1.4)                                                 | ❌ Missing     | SSO / OAuth card authentication                                                                                                                      |

---

## Inputs

| Input           | Microsoft Spec                                                 | Implementation | Tests  | Documentation                      | Notes                                                                                                                                                                                         |
| --------------- | -------------------------------------------------------------- | -------------- | ------ | ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Input.Text      | [spec](https://adaptivecards.io/explorer/Input.Text.html)      | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Flutter Form-based; `label` supported (v1.3+)                                                                                                                                                 |
| Input.Number    | [spec](https://adaptivecards.io/explorer/Input.Number.html)    | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Flutter Form-based                                                                                                                                                                            |
| Input.Date      | [spec](https://adaptivecards.io/explorer/Input.Date.html)      | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Material/Cupertino pickers; `initData` / `initInput` seeding fixed (yyyy-MM-dd)                                                                                                               |
| Input.Time      | [spec](https://adaptivecards.io/explorer/Input.Time.html)      | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Material/Cupertino pickers                                                                                                                                                                    |
| Input.Toggle    | [spec](https://adaptivecards.io/explorer/Input.Toggle.html)    | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Flutter Form-based                                                                                                                                                                            |
| Input.ChoiceSet | [spec](https://adaptivecards.io/explorer/Input.ChoiceSet.html) | ✅ Complete    | ✅ Yes | [form-inputs.md](./form-inputs.md) | Compact, multiselect, filtered (search/list **titles**; submit **values**); `choices.data` / `Data.Query`; `associatedInputs` merges sibling values into `DataQuery.parameters` on `onChange` |
| Input.Choice    | [spec](https://adaptivecards.io/explorer/Input.Choice.html)    | ✅ Complete    | ✅ Yes | -                                  | Typed `Choice` model; overlay uses `List<Choice>`                                                                                                                                             |

> [!NOTE]
> All standard input implementations (`Input.Text`, `Input.Number`, `Input.Date`, `Input.Time`, `Input.Toggle`, `Input.ChoiceSet`) fully implement `appendInput()`, `initInput()`, `checkRequired()`, and `resetInput()` methods. These elements have been verified to use the mixin-inherited `value` property exclusively, without directly accessing `adaptiveMap['value']` after initialization. **`Action.ResetInputs`** and host **`resetInput(id)`** / **`resetAllInputs()`** factory-reset input overlays (including `label`, `placeholder`, `isRequired`) to baseline — see [Reset semantics](./reactive-riverpod.md#reset-semantics) and [form-inputs.md](./form-inputs.md#reset-behavior-resetallinputs--resetinput).

---

## Actions

| Action                  | Microsoft Spec                                                                                                            | Implementation | Tests  | Documentation                                        | Notes                                                                                                                                            |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------- | ------ | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Action.Execute          | [spec](https://adaptivecards.io/explorer/Action.Execute.html)                                                             | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | **`verb`** and **`id`** via **`ExecuteActionInvoke`** on `onExecute`; merged `data` + inputs; **`associatedInputs`** `"none"` skips input merge  |
| Action.OpenUrl          | [spec](https://adaptivecards.io/explorer/Action.OpenUrl.html)                                                             | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                                                                                                                        |
| Action.ShowCard         | [spec](https://adaptivecards.io/explorer/Action.ShowCard.html)                                                            | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                                                                                                                        |
| Action.Submit           | [spec](https://adaptivecards.io/explorer/Action.Submit.html)                                                              | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | **`id`** as **`actionId`** via **`SubmitActionInvoke`** on `onSubmit`; merged `data` + inputs; **`associatedInputs`** `"none"` skips input merge |
| Action.ToggleVisibility | [spec](https://adaptivecards.io/explorer/Action.ToggleVisibility.html)                                                    | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | Generic + Default pattern                                                                                                                        |
| Action.OpenUrlDialog    | [Teams ext](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-actions)         | ✅ Complete    | ❌ No  | [actions-architecture.md](./actions-architecture.md) | **Teams extension** (schema v1.5+) — launches modal/task module dialog                                                                           |
| Action.ResetInputs      | [Bot Framework ext](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-actions) | ✅ Complete    | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | **`targetInputIds`**, **`valueChangedAction`**; Teams/Bot Framework extension                                                                    |
| Action.InsertImage      | Host-specific ext                                                                                                         | ✅ Complete    | ❌ No  | -                                                    | **Host extension** (Word/PowerPoint, v1.5+) — inserts image into host canvas                                                                     |
| Action.Popover          | -                                                                                                                         | ✅ Complete    | ❌ No  | -                                                    | **Project-specific** — no known spec source; popover overlay                                                                                     |

---

## Charts (`flutter_adaptive_charts_fs` package)

Charts are implemented in a **separate opt-in package** ([optional-packages-and-extensions.md](./optional-packages-and-extensions.md)) so hosts that do not render charts avoid the **fl_chart** dependency. Host apps must merge `CardChartsRegistry.additionalChartElements` and `CardChartsRegistry.overlayExtensions` into `CardTypeRegistry`. Runtime chart data/config patches use `ChartElementOverlayExtension` (see [reactive-riverpod.md](./reactive-riverpod.md)).

| Chart Type                    | Microsoft Spec                                                                                                                  | Implementation | Tests      | Notes                                                                                                                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Chart.Line`                  | [Teams charts](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/charts-in-adaptive-cards) | ⚠️ Partial     | ⚠️ Limited | Data + axis rendering; `title` / axis titles via [ChartChrome](../packages/flutter_adaptive_charts_fs/lib/src/charts/chart_chrome.dart); datetime `x` values not handled |
| `Chart.Pie`                   | Teams charts                                                                                                                    | ⚠️ Partial     | ⚠️ Limited | Slice rendering; `title` / `showLegend` via ChartChrome                                                                                                                  |
| `Chart.Donut`                 | Teams charts                                                                                                                    | ⚠️ Partial     | ⚠️ Limited | Same as Pie with hole radius + ChartChrome                                                                                                                               |
| `Chart.VerticalBar`           | Teams charts                                                                                                                    | ⚠️ Partial     | ⚠️ Limited | Bars + `title`, axis titles, `showBarValues`, `showLegend`, `colorSet`                                                                                                   |
| `Chart.HorizontalBar`         | Teams charts                                                                                                                    | ⚠️ Partial     | ⚠️ Limited | Same chrome as vertical bar                                                                                                                                              |
| `Chart.VerticalBar.Grouped`   | Teams charts                                                                                                                    | ⚠️ Partial     | ⚠️ Limited | Grouped and stacked (`stacked: true`) modes supported                                                                                                                    |
| `Chart.HorizontalBar.Stacked` | Teams charts                                                                                                                    | ⚠️ Partial     | ⚠️ Limited | Stacked horizontal bars                                                                                                                                                  |
| `Chart.Gauge`                 | Teams charts                                                                                                                    | ✅ Implemented | ✅ Yes     | `CustomPainter` semicircular gauge (`value`, `min`/`max`, `segments`, `valueFormat`, legend)                                                                             |

Microsoft does **not** define a separate `Chart.VerticalBar.Stacked` type; stacked vertical bars use `Chart.VerticalBar.Grouped` with `"stacked": true`.

### Chart property gaps (all chart types)

| Property / area             | Status | Notes                                                                                                                                                                                        |
| --------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `data`                      | ✅     | Parsed and rendered for implemented chart types                                                                                                                                              |
| `color` (per point)         | ⚠️     | Hex + Teams semantic tokens (`good`, `categoricalBlue`, `divergingRed`, …) via [chart_colors_config.dart](../packages/flutter_adaptive_cards_fs/lib/src/hostconfig/chart_colors_config.dart) |
| `colorSet`                  | ✅     | Named palettes (`categorical`, `sequential`, `diverging`) on chart JSON + HostConfig `defaultPalette` fallback                                                                               |
| `title`                     | ✅     | Rendered via ChartChrome on bar, line, pie, donut, and gauge                                                                                                                                 |
| `xAxisTitle` / `yAxisTitle` | ✅     | Bar and line charts (fl_chart axis titles)                                                                                                                                                   |
| `showBarValues`             | ✅     | Vertical and horizontal bar charts                                                                                                                                                           |
| `showLegend`                | ✅     | Pie, donut, gauge segment legend; bar/line when enabled                                                                                                                                      |
| `targetWidth`               | ❌     | Responsive layout not implemented                                                                                                                                                            |
| `grid.area`                 | ❌     | `Layout.AreaGrid` placement not implemented                                                                                                                                                  |
| `height: stretch`           | ❌     | Block height modes not implemented on chart elements                                                                                                                                         |
| HostConfig `chartColors`    | ✅     | `defaultPalette` and `defaultColor`                                                                                                                                                          |
| HostConfig `chartsLayout`   | ✅     | Line, bar, pie, and donut layout chrome — see [charts layout plan](./superpowers/plans/2026-06-08-charts-layout-config.plan.md)                                                              |

---

## HostConfig

| Config Component       | Microsoft Spec                                                                          | Implementation | Tests  | Documentation                                                                     | Notes                                                  |
| ---------------------- | --------------------------------------------------------------------------------------- | -------------- | ------ | --------------------------------------------------------------------------------- | ------------------------------------------------------ |
| HostConfig (root)      | [schema](https://github.com/microsoft/AdaptiveCards/blob/main/schemas/host-config.json) | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | Main config object                                     |
| AdaptiveCardConfig     | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ActionsConfig          | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ContainerStylesConfig  | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ContainerStyleConfig   | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ForegroundColorsConfig | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| FontColorConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| FontSizesConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| FontWeightsConfig      | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| FactSetConfig          | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ImageSetConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ImageSizesConfig       | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| InputsConfig           | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| LabelConfig            | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ErrorMessageConfig     | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| MediaConfig            | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| SeparatorConfig        | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ShowCardConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| SpacingsConfig         | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| TextStylesConfig       | schema                                                                                  | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | -                                                      |
| ChartColorsConfig      | schema (v1.6 / Teams)                                                                   | ✅ Complete    | ✅ Yes | [hostconfig.md](./hostconfig.md)                                                  | `chartColors` section for chart palettes               |
| ChartsLayoutConfig     | project extension                                                                       | ✅ Complete    | ✅ Yes | [charts layout plan](./superpowers/plans/2026-06-08-charts-layout-config.plan.md) | `chartsLayout` section for chart dimensions and chrome |

**Total HostConfig Classes**: All HostConfig classes are in `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/`.

---

## Optional packages

Packages outside **`flutter_adaptive_cards_fs`** that hosts opt into explicitly. See [optional-packages-and-extensions.md](./optional-packages-and-extensions.md).

| Package                          | Purpose                                               | Implementation | Tests      | Documentation                                                     |
| -------------------------------- | ----------------------------------------------------- | -------------- | ---------- | ----------------------------------------------------------------- |
| `flutter_adaptive_template_fs`   | Adaptive Cards templating (`$data`, `$when`, …)       | ✅ Complete    | ✅ Yes     | [adaptive-template-design.md](./adaptive-template-design.md)      |
| `flutter_adaptive_charts_fs`     | `Chart.*` elements (fl_chart + gauge `CustomPainter`) | ⚠️ Partial     | ⚠️ Limited | [charts README](../packages/flutter_adaptive_charts_fs/README.md) |
| `flutter_adaptive_cards_host_fs` | Backend invoke serialize → POST → parse → apply       | ✅ Complete    | ✅ Yes     | [backend-host-integration.md](./backend-host-integration.md)      |

---

## Templating (`flutter_adaptive_template_fs` package)

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
| `isVisible`           | All elements    | ✅ Complete    | [reactive-riverpod.md — Visibility](./reactive-riverpod.md#visibility-isvisible)       | Visibility widget wrapper                                                                                                                                               |
| `separator`           | Most elements   | ✅ Complete    | -                                                                                      | Visual separators                                                                                                                                                       |
| `spacing`             | Most elements   | ✅ Complete    | -                                                                                      | Layout spacing                                                                                                                                                          |
| `height`              | Block elements  | ⚠️ Partial     | [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md) | `auto` common; `stretch` not generally implemented                                                                                                                      |
| `style`               | Containers/Text | ✅ Complete    | [adaptive-style.md](./adaptive-style.md)                                               | HostConfig-based                                                                                                                                                        |
| `fallback` (elements) | All elements    | ✅ Complete    | -                                                                                      | Handled in `CardTypeRegistry` (`drop` or recursive substitute)                                                                                                          |
| `fallback` (actions)  | All actions     | ❌ Missing     | -                                                                                      | `_getActionWidget` ends in `assert(false)`; no fallback check                                                                                                           |
| `requires`            | All elements    | ❌ Missing     | -                                                                                      | Capability gating not implemented; elements always render                                                                                                               |
| `selectAction`        | Some elements   | ✅ Complete    | -                                                                                      | Container, Column, ColumnSet, Image, TableCell                                                                                                                          |
| `backgroundImage`     | Card/Container  | ✅ Complete    | [backgroundImage.md](./backgroundImage.md)                                             | Parsed via mixin for Container, Column, ColumnSet, TableCell; fully tested (both string and object forms), including empty aspect-ratio sizing and `minHeight` support. |
| `bleed`               | Containers      | ❌ Missing     | -                                                                                      | Not implemented on Container, Column, or TableCell                                                                                                                      |
| `rtl`                 | Elements        | ⚠️ Partial     | -                                                                                      | Parsed on `TableCell` model only; not applied in rendering                                                                                                              |
| `targetWidth`         | Elements (v1.6) | ❌ Missing     | -                                                                                      | Responsive layout — [hub docs](https://adaptivecards.microsoft.com/)                                                                                                    |
| `grid.area`           | Elements (v1.6) | ❌ Missing     | -                                                                                      | `Layout.AreaGrid` placement not implemented                                                                                                                             |

---

## Known Gaps

Cross-cutting gaps that affect many card types:

| Area                            | Gap                                                                                                  | Impact                                                           |
| ------------------------------- | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **RichTextBlock / TextRun**     | ✅ Implemented                                                                                       | —                                                                |
| **Responsive layout**           | `targetWidth`, `Layout.AreaGrid`, `grid.area`                                                        | High — modern Teams/Copilot width-adaptive cards                 |
| **`requires` + version gating** | No capability checks; `fallbackText` unused                                                          | Medium–high — mixed-schema production hosts                      |
| **Action `fallback`**           | Unknown actions assert instead of degrading                                                          | Medium — action fallback lists in Teams chart docs               |
| **Icon**                        | Partial Fluent name map (~68 icons)                                                                  | Low–medium — uncommon hub icon names fall back to `help_outline` |
| **Table completeness**          | `auto`/`stretch` widths, cell `rtl`, `bleed`                                                         | Medium — complex table scenarios                                 |
| **TextBlock text features**     | Plain path: ✅ `maxLines`, `color`, `isSubtle`, `weight`; markdown path: subset only (no `maxLines`) | Low — full HTML markdown out of scope                            |
| **Chart.Gauge**                 | ✅ Implemented (`CustomPainter`)                                                                     | —                                                                |
| **Chart chrome**                | ✅ Implemented (`ChartChrome`)                                                                       | —                                                                |
| **Chart `colorSet`**            | ✅ Named semantic palettes                                                                           | —                                                                |
| **AdaptiveCard root**           | `authentication`, `rtl`, `selectAction`, `minHeight` (`refresh` ✅)                                  | Medium — Bot/Teams integration                                   |
| **CaptionSource**               | Not implemented                                                                                      | Low — media captions                                             |
| **`bleed`**                     | Not implemented on containers                                                                        | Low–medium — full-bleed layouts                                  |
| **Block `height: stretch`**     | Not generally implemented                                                                            | Medium — fixed-height card layouts                               |

---

## Custom/Extended Elements

These are implemented but not part of the standard Microsoft schema explorer element list (or are hub extensions beyond the legacy explorer).
Registered in `CardTypeRegistry` (`lib/src/registry.dart`) unless noted.

| Element           | JSON Type String | Implementation | Tests      | Documentation                                                     | Notes                                                                              |
| ----------------- | ---------------- | -------------- | ---------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Badge             | `Badge`          | ✅ Complete    | ⚠️ Limited | -                                                                 | Hub extension; HostConfig `BadgeStylesConfig`                                      |
| Carousel          | `Carousel`       | ✅ Complete    | ⚠️ Limited | -                                                                 | Hub extension; child pages use `CarouselPage`                                      |
| CarouselPage      | `CarouselPage`   | ✅ Complete    | ⚠️ Limited | -                                                                 | Child element of `Carousel`                                                        |
| Accordion         | `Accordion`      | ✅ Complete    | ⚠️ Limited | -                                                                 | Custom collapsible element                                                         |
| ProgressBar       | `ProgressBar`    | ✅ Complete    | ⚠️ Limited | -                                                                 | Custom element                                                                     |
| ProgressRing      | `ProgressRing`   | ✅ Complete    | ⚠️ Limited | -                                                                 | Custom element                                                                     |
| Rating            | `Rating`         | ✅ Complete    | ⚠️ Limited | -                                                                 | Hub extension; also registered as `Input.Rating`                                   |
| CodeBlock         | `CodeBlock`      | ✅ Complete    | ⚠️ Limited | -                                                                 | Hub / Teams extension                                                              |
| CompoundButton    | `CompoundButton` | ✅ Complete    | ⚠️ Limited | -                                                                 | Hub / Teams extension                                                              |
| TabSet            | `TabSet`         | ✅ Complete    | ⚠️ Limited | -                                                                 | Custom tab container                                                               |
| Charts (multiple) | `Chart.*`        | ⚠️ Partial     | ⚠️ Limited | [charts README](../packages/flutter_adaptive_charts_fs/README.md) | Separate package; see [Charts](#charts-flutter_adaptive_charts_fs-package) section |

---

## Priority Recommendations

### High priority — standard cards

1. **Responsive layout**: `targetWidth` and `Layout.AreaGrid` / `grid.area` per [documentation hub](https://adaptivecards.microsoft.com/).
2. **`requires` + action `fallback` + version gating**: Graceful degradation for mixed-schema hosts.

### High priority — charts

1. **Chart datetime axes**: Parse ISO datetime `x` values on line charts.

### Medium priority

1. **Complete `Table`**: `auto`/`stretch` column widths, cell `rtl` rendering, `bleed`.
2. **`Icon` element**: Expand Fluent name catalog beyond ~68 built-in mappings.
3. **Block `height: stretch`**: Apply across containers and chart elements.
4. **AdaptiveCard root features**: `rtl`, `fallbackText`, `selectAction`, `minHeight` (`refresh` ✅ — see [plan workstream B](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md#workstream-b--refresh-property-v14)).
5. **Media poster fix**: Resolve poster attribute display issue.

### Low priority

1. **Test coverage**: Expand tests for partial implementations (charts, Media, Table).
2. **Documentation**: Add `Custom-Extensions.md` index (see [docs/README.md](./README.md#missingrecommended-documentation)).
3. **`CaptionSource`**: Media caption support.
4. **`bleed`**: Container full-bleed layouts.
5. **Adaptive Expressions**: Date/Time and advanced collection functions in templating.

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

# Run non-golden tests (main library)
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden

# Run non-golden tests (charts package)
cd packages/flutter_adaptive_charts_fs
fvm flutter test --exclude-tags=golden

# Note: Golden tests are platform-specific and stored in subdirectories (e.g., gold_files/linux/)
```

---

## Recently completed

### Refresh, Icon, charts, gauge, and text (2026-06-08 plan)

Plan: [2026-06-08-refresh-icon-charts-text-features.plan.md](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md) — all workstreams **A–G** complete.

| Workstream | Delivered                                                                                                                                                                                      |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A**      | [optional-packages-and-extensions.md](./optional-packages-and-extensions.md) + cross-links from Architecture, README, this matrix                                                              |
| **B**      | Root `refresh` — `RefreshConfig`, manual affordance, auto-expire, `userIds` gating, `onRefresh` / `RefreshActionInvoke` (PR #20)                                                               |
| **C**      | Hub **`Icon`** element — ~68 Fluent names, size/color/style tokens, `selectAction`                                                                                                             |
| **D**      | Chart **`colorSet`** + Teams semantic color tokens; **`ChartChrome`** (title, axis titles, bar values, legend)                                                                                 |
| **E**      | Widgetbook **`ChartOverlayPage`** interactive knobs                                                                                                                                            |
| **F**      | **`Chart.Gauge`** via `CustomPainter` in `flutter_adaptive_charts_fs`                                                                                                                          |
| **G**      | **`RichTextBlock`** / **`TextRun`**; TextBlock plain-path `maxLines`/`color`/`isSubtle`; Widgetbook demo — [design spec](./superpowers/specs/2026-06-08-rich-text-and-text-features-design.md) |

**Verification (2026-06-09):** `fvm flutter analyze` clean; **400** core tests (~2 skipped); chart and gauge suites pass; goldens: `v1_5_icon_demo.png`, `v1_2_rich_text_block_demo.png`, `v1_6_gauge.png`.

### Backend host integration (2026-06-07 plan)

Plan: [2026-06-07-backend-host-integration.plan.md](./superpowers/plans/2026-06-07-backend-host-integration.plan.md) — Phase 1 in core (`associatedInputs`); Phase 2 optional **`flutter_adaptive_cards_host_fs`**.

| Phase | Delivered                                                                                           |
| ----- | --------------------------------------------------------------------------------------------------- |
| **1** | `Data.Query` / Submit / Execute **`associatedInputs`** in `flutter_adaptive_cards_fs`               |
| **2** | **`AdaptiveCardBackendHandlers`**, PlainJson + Teams adapters, HTTP client, invoke response effects |

See [backend-host-integration.md](./backend-host-integration.md) and [archived design spec](./archive/specs/2026-06-07-backend-host-integration-design.md).

### Style pipeline (2026-06-06)

- **Container style inheritance** via `ChildStyler` — see [Style inheritance data flow](adaptive-style.md#style-inheritance-data-flow).
- **`TextBlockStyle`** / **`TextStylesConfig`** wired through `resolveTextBlockStyle()`.
- **`ImageStyle`** — `person` vs `default` via `resolveImageIsPerson()`.
- **Horizontal alignment inheritance** from parent containers.
- **`AdaptiveCardBrightnessMode`** host override; auto mode follows `Theme.of(context).brightness`.

### Charts HostConfig (2026-06-08)

- **`ChartsLayoutConfig`** (`chartsLayout`) — line, bar, pie, and donut layout chrome via `ReferenceResolver`.
- Plan: [2026-06-08-charts-layout-config.plan.md](./superpowers/plans/2026-06-08-charts-layout-config.plan.md).

### ColumnSet height (fixed before 2026-02-13)

- **`IntrinsicHeight`** + **`CrossAxisAlignment.stretch`** — see [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md).

### Public API documentation (2026-06-08, updated 2026-06-11)

- **`public_member_api_docs`** — `///` on exported APIs follows the **`dart-public-api-docs`** standard (why/how for callers, not implementation narration). Remediation plan: [`docs/superpowers/plans/2026-06-11-public-api-docs-remediation.plan.md`](./superpowers/plans/2026-06-11-public-api-docs-remediation.plan.md).
- **`flutter_adaptive_cards_fs`** — `public_member_api_docs: error` in `analysis_options.yaml`; `fvm dart analyze lib` is clean for missing public docs (2026-06-11).
- **`flutter_adaptive_charts_fs`** — docs present; lint not yet promoted to error (separate task).

---

_Last Updated: 2026-06-09_
_Based on v1.6.0 of Microsoft Adaptive Cards specification_
