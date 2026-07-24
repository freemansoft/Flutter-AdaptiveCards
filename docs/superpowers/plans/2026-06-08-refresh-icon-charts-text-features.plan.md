# Refresh, Icon, Charts, Gauge, and Text Features — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Adaptive Card `refresh`, the hub `Icon` element, chart chrome and color parity (excluding responsive layout), a real `Chart.Gauge` in `flutter_adaptive_charts_fs`, and standard text features (`RichTextBlock`/`TextRun` plus targeted `TextBlock` fixes), with Widgetbook demos for interactive chart attributes.

**Implementation status (validated 2026-06-09):** all workstreams merged to `main` (PRs #19–#20; workstream G on `feat/workstream-g-text-features`).

| Workstream | Status      | Notes                                                                        |
| ---------- | ----------- | ---------------------------------------------------------------------------- |
| A          | ✅ Complete | Doc + cross-links                                                            |
| B          | ✅ Complete | `RefreshConfig`, `onRefresh`, manual affordance, auto-expire, `userIds` gate |
| C          | ✅ Complete | ~68 Fluent names; golden `test/golden_icon_test.dart`                        |
| D          | ✅ Complete | Chart colors merged in `chart_colors_config.dart`; gauge golden added        |
| E          | ✅ Complete | `ChartOverlayPage` + codegen                                                 |
| F          | ✅ Complete | Gauge via `CustomPainter`; golden in `golden_v1_6_test.dart`                 |
| G          | ✅ Complete | `RichTextBlock`/`TextRun`, TextBlock plain-path fixes, Widgetbook demo       |

**Verification (2026-06-09):** `fvm flutter analyze` — no issues. Core tests **400 passed** (~2 skipped). Charts tests 7 passed. Gauge widget tests 6 passed. Golden: icon + RichTextBlock (`v1_5_icon_demo.png`, `v1_2_rich_text_block_demo.png`) + charts gauge (`v1_6_gauge.png`) pass on macOS; Linux goldens via CI.

**Architecture:** Core features (`refresh`, `Icon`, text) live in `flutter_adaptive_cards_fs`. All chart types — including **gauge** — stay in **`flutter_adaptive_charts_fs`**. Bar, line, pie, and donut continue to use **fl_chart**; gauge uses **`CustomPainter`** in the same package (fl_chart has no suitable gauge API). Hosts still opt in via `CardChartsRegistry.additionalChartElements` — see [optional-packages-and-extensions.md](../../optional-packages-and-extensions.md). Widgetbook overlay pages follow `fact_set_overlay_page.dart` / `text_block_overlay_page.dart` patterns.

**Out of scope:** `targetWidth`, `grid.area`, `Layout.AreaGrid` (responsive layout deferred).

**Tech Stack:** Dart 3.12+, Flutter (FVM), Riverpod 3.x, fl_chart (charts pkg only), Widgetbook knobs, `very_good_analysis`.

**Spec references:**

- [Refresh](https://adaptivecards.io/explorer/Refresh.html)
- [Icon (Teams)](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format)
- [Charts in Adaptive Cards](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/charts-in-adaptive-cards)
- [RichTextBlock](https://adaptivecards.io/explorer/RichTextBlock.html) / [TextRun](https://adaptivecards.io/explorer/TextRun.html)
- [Text features](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/text-features)

---

## Workstream map

| ID  | Workstream                                  | Package(s)                                    | Depends on               |
| --- | ------------------------------------------- | --------------------------------------------- | ------------------------ |
| A   | Optional-packages documentation (complete)  | docs                                          | —                        |
| B   | `refresh` on root `AdaptiveCard` (complete) | `flutter_adaptive_cards_fs`                   | —                        |
| C   | `Icon` element (complete)                   | `flutter_adaptive_cards_fs`                   | —                        |
| D   | Chart chrome + `colorSet` (complete)        | `flutter_adaptive_charts_fs`, core HostConfig | —                        |
| E   | Widgetbook chart knobs page (complete)      | `widgetbook`                                  | D                        |
| F   | `Chart.Gauge` (CustomPainter, complete)     | `flutter_adaptive_charts_fs`                  | D (ChartChrome optional) |
| G   | Text features (complete)                    | `flutter_adaptive_cards_fs`                   | —                        |

Recommended execution order: **A → B, C, G (parallel) → D → E → F**.

---

## Workstream A — Documentation (complete)

- [x] Create [optional-packages-and-extensions.md](../../optional-packages-and-extensions.md)
- [x] Link from [Architecture-Overview.md](../../Architecture-Overview.md), [README.md](../../README.md), [Implementation-Status.md](../../Implementation-Status.md)

---

## Workstream B — `refresh` property (v1.4+)

> **✅ Complete** — merged via PR #20 (`feat/refresh-workstream-b`).

### Design

Parse root `refresh` on the top-level `AdaptiveCard` JSON:

```json
{
  "type": "AdaptiveCard",
  "version": "1.4",
  "refresh": {
    "action": { "type": "Action.Execute", "verb": "refreshCard", "data": {} },
    "userIds": ["user-1"],
    "expires": "2026-06-08T12:00:00Z"
  },
  "body": [ ... ]
}
```

**Host responsibilities:**

| Trigger                   | Flutter behavior                                                                  |
| ------------------------- | --------------------------------------------------------------------------------- |
| Manual refresh affordance | Optional refresh icon/button on card chrome when `refresh.action` is present      |
| `expires` in the past     | Auto-fire refresh once after first frame (configurable)                           |
| `userIds`                 | Only auto-fire when host supplies current user id via new optional callback param |

**Callback:** Add `onRefresh` on `AdaptiveCardsCanvas` / `InheritedAdaptiveCardHandlers` that receives `RefreshActionInvoke` (wraps the nested `Action.Execute` map + merged inputs). Host replaces card JSON when refresh completes — use existing baseline replacement on `RawAdaptiveCard` map update.

Do **not** implement bot round-trip inside the library; fire the execute payload and let the host fetch new JSON.

### Task B1: Model + invoke type

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/models/refresh_config.dart`
- Create: `packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart` (add `RefreshActionInvoke`)
- Test: `packages/flutter_adaptive_cards_fs/test/models/refresh_config_test.dart`

- [x] **Step 1: Write failing test**

```dart
test('RefreshConfig.fromJson parses action, userIds, expires', () {
  final config = RefreshConfig.fromJson({
    'action': {'type': 'Action.Execute', 'verb': 'refreshCard'},
    'userIds': ['a'],
    'expires': '2026-06-08T12:00:00Z',
  });
  expect(config.action['verb'], 'refreshCard');
  expect(config.userIds, ['a']);
  expect(config.expires, isNotNull);
});
```

- [x] **Step 2: Run test** — expect FAIL

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/models/refresh_config_test.dart`

- [x] **Step 3: Implement `RefreshConfig`** with `fromJson`, nullable fields, ISO-8601 `expires` as `DateTime?`

- [x] **Step 4: Add `RefreshActionInvoke`** mirroring `ExecuteActionInvoke` fields

- [x] **Step 5: Run test** — expect PASS

- [x] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/refresh_config.dart \
        packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart \
        packages/flutter_adaptive_cards_fs/test/models/refresh_config_test.dart
git commit -m "feat: add RefreshConfig model and RefreshActionInvoke"
```

### Task B2: Wire refresh on root card

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/refresh/refresh_action_test.dart`

- [x] **Step 1: Parse `refresh` in `AdaptiveCardElementState.initState`** when `adaptiveMap['refresh']` present; store `RefreshConfig?`

- [x] **Step 2: Add `_RefreshAffordance` widget** — small `IconButton` (refresh icon) in card header row when `refresh.action != null`; on tap call `_triggerRefresh(manual: true)`

- [x] **Step 3: Implement `_triggerRefresh`** — build `RefreshActionInvoke` from refresh action map + `collectInputValues()`; invoke `InheritedAdaptiveCardHandlers.onRefresh` if non-null, else fall back to `onExecute`

- [x] **Step 4: Auto-expire** — in `didChangeDependencies`, if `expires != null && DateTime.now().isAfter(expires!)`, schedule one-shot refresh (guard with `_refreshFired` flag)

- [x] **Step 5: Add optional `currentUserId` on `AdaptiveCardsCanvas`** — skip auto refresh when `userIds` non-empty and id not in list

- [x] **Step 6: Widget test** — pump card with refresh JSON; tap affordance; verify callback receives invoke with correct `verb`

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/refresh/refresh_action_test.dart`

- [x] **Step 7: Update [actions-architecture.md](../actions-architecture.md)** with refresh callback contract

- [x] **Step 8: Commit**

### Task B3: Sample + Widgetbook

**Files:**

- Create: `widgetbook/lib/samples/v1.4/refresh_demo.json`
- Modify: `widgetbook/lib/adaptive_cards_use_cases.dart`

- [x] Add use case under **AdaptiveCard** category showing manual refresh button and logging `onRefresh` to a `SnackBar`

---

## Workstream C — `Icon` element

### Design

Implement hub `Icon` element per [Teams format docs](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format):

| Property       | Implementation                                                                                                     |
| -------------- | ------------------------------------------------------------------------------------------------------------------ |
| `name`         | Map to Material / Fluent-style icon via static lookup table (start with common names: `Calendar`, `AccessTime`, …) |
| `size`         | Map tokens to logical pixels (HostConfig or fixed table)                                                           |
| `color`        | `Default`, `Dark`, `Light`, `Accent`, `Good`, `Warning`, `Attention` → `ReferenceResolver`                         |
| `style`        | `Filled` vs `Regular` → `Icons.*` vs `Icons.*_outlined` where available                                            |
| `selectAction` | Reuse `AdaptiveTappable` pattern from `Image` / `TableCell`                                                        |

**Phase 1:** Built-in name → `IconData` map (~50 common Fluent names). Unknown names → `AdaptiveUnknown` or fallback.

**Phase 2 (follow-up):** `iconUrl: "icon:Name,filled"` on actions (out of this plan unless time permits).

### Task C1: Element widget

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/icon.dart`
- Create: `packages/flutter_adaptive_cards_fs/lib/src/utils/fluent_icon_map.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/registry.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/elements/icon_test.dart`

- [x] **Step 1: Failing widget test** — pump JSON `{ "type": "Icon", "name": "Calendar", "size": "Medium", "color": "Accent" }`; expect `Icon` widget

- [x] **Step 2: Implement `AdaptiveIcon`** following [adaptive-cards-element-registry](../../.agents/skills/adaptive-cards-element-registry/SKILL.md) (`AdaptiveBadge` reference)

- [x] **Step 3: Register `case 'Icon':` in `_getBaseElement`**

- [x] **Step 4: Golden test** (optional tag) — `test/golden_icon_test.dart` + sample `test/samples/v1.5/icon_demo.json` → `gold_files/macos/v1_5_icon_demo.png`

- [x] **Step 5: Widgetbook sample** — `widgetbook/lib/samples/v1.5/icon_demo.json` + use case

- [x] **Step 6: Update [Implementation-Status.md](../../Implementation-Status.md)** — Icon → ⚠️ Partial (~68 Fluent names; unknown → `help_outline`)

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/elements/icon_test.dart --exclude-tags=golden`

---

## Workstream D — Chart improvements (no responsive layout)

### Scope (from [Implementation-Status.md](../Implementation-Status.md))

| Feature                             | Action                                                                    |
| ----------------------------------- | ------------------------------------------------------------------------- |
| `title`, `xAxisTitle`, `yAxisTitle` | Render with `Text` above chart / axis labels via fl_chart `titlesData`    |
| `showBarValues`                     | Bar chart value labels on rods                                            |
| `showLegend`                        | Pie/donut/line multi-series legend row below chart                        |
| `colorSet`                          | Resolve named palettes (`categorical`, `diverging`, `sequential`) in core |
| Semantic `color` tokens             | Extend `resolveChartColor()` for Teams token set                          |

**Explicitly excluded:** `targetWidth`, `grid.area`, `height: stretch`.

### Task D1: Chart color tokens + colorSet

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/chart_color_sets.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/reference_resolver.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/chart_colors_config.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/hostconfig/chart_color_sets_test.dart`

- [x] **Step 1: Define `ChartColorSet` enum** — `categorical`, `diverging`, `sequential`, `defaultPalette` (`ChartColorSetName` in `chart_color_sets.dart`)

- [x] **Step 2: Add default token → color maps** aligned with [Teams charts color reference](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/charts-in-adaptive-cards)

- [x] **Step 3: Add `resolveChartPalette({String? colorSet})`** — when element JSON has `"colorSet": "diverging"`, use that palette before `defaultPalette`

- [x] **Step 4: Extend `resolveChartColor()`** for tokens like `categoricalBlue`, `sequential3`, etc.

- [x] **Step 5: Tests** for palette selection and token resolution

_Note: palette logic lives in `chart_color_sets.dart`; `chart_colors_config.dart` unchanged (HostConfig `defaultPalette` still read in resolver)._

### Task D2: Shared chart chrome widget

**Files:**

- Create: `packages/flutter_adaptive_charts_fs/lib/src/charts/chart_chrome.dart`
- Modify: `line_chart.dart`, `bar_chart.dart`, `pie_donut_chart.dart`

- [x] **Step 1: Create `ChartChrome` column wrapper**

```dart
/// Title, chart body, optional legend.
class ChartChrome extends StatelessWidget {
  const ChartChrome({
    required this.title,
    required this.chart,
    this.legendEntries = const [],
    super.key,
  });
  // ...
}
```

- [x] **Step 2: Parse `title` from `adaptiveMap` in each chart state `_parseData`**

- [x] **Step 3: Wire axis titles** — bar/line use fl_chart `AxisTitles` with `xAxisTitle` / `yAxisTitle`

- [x] **Step 4: `showBarValues`** — `BarChartRodData` labels when `adaptiveMap['showBarValues'] == true`

- [x] **Step 5: `showLegend`** — build legend from series `legend` fields when true (default false for pie)

- [x] **Step 6: Update golden tests** — gauge golden added (`v1_6_gauge.png` in charts `golden_v1_6_test.dart`); existing bar/line/pie goldens unchanged; full `--tags=golden` suite not re-run for chrome layout shifts

Run:

```bash
cd packages/flutter_adaptive_charts_fs
fvm flutter test --exclude-tags=golden
fvm flutter test --tags=golden
```

### Task D3: Keep `Chart.Gauge` in chart registry

**Files:**

- Modify: `packages/flutter_adaptive_charts_fs/lib/src/card_chart_registry.dart`
- Modify: `packages/flutter_adaptive_charts_fs/README.md`

- [x] Replace the donut stub mapping with `AdaptiveGaugeChart` (implemented in Workstream F)

- [x] Update README: gauge is a first-class chart type in this package; rendered via `CustomPainter`, not fl_chart

---

## Workstream E — Widgetbook chart knobs

### Design

New **`ChartOverlayPage`** (like [fact_set_overlay_page.dart](../../widgetbook/lib/fact_set_overlay_page.dart)):

- Loads a minimal bar (or line) chart JSON with stable element `id`
- **Knobs:**
  - `title` (string)
  - `xAxisTitle` / `yAxisTitle` (string)
  - `showBarValues` (boolean)
  - `showLegend` (boolean) — line/grouped bar
  - `sampleValue` (double slider) — mutates first data point via in-memory map rebuild (not overlay API)
- Rebuilds card by cloning base map and patching chart element properties each frame (same pattern as knob-driven JSON demos)

### Task E1: Chart overlay page

**Files:**

- Create: `widgetbook/lib/chart_overlay_page.dart`
- Create: `widgetbook/lib/samples/charts/chart_knobs_demo.json`
- Modify: `widgetbook/lib/adaptive_cards_use_cases.dart`
- Modify: `widgetbook/lib/main.dart` (if manual directory registration needed)

- [x] **Step 1: Create base JSON** with one `Chart.VerticalBar` id `demoChart`

- [x] **Step 2: Implement page** with `GlobalKey<RawAdaptiveCardState>`, merge chart registry, knob listeners

- [x] **Step 3: Register use case** under **Charts → Interactive knobs**

- [x] **Step 4: Run widgetbook codegen**

Run: `cd widgetbook && fvm dart run build_runner build --delete-conflicting-outputs`

- [x] **Step 5: Manual smoke** — page uses `chartOverlayPageKey` GlobalKey pattern (same as TextBlock overlay); knobs patch cloned JSON

---

## Workstream F — `Chart.Gauge` (in `flutter_adaptive_charts_fs`)

### Rationale

[charts README](../packages/flutter_adaptive_charts_fs/README.md) notes fl_chart has no suitable gauge API. The current registry maps `Chart.Gauge` to a **donut stub**. Workstream F replaces that with a real gauge widget in the **same package**:

- Hosts already merge one registry (`CardChartsRegistry.additionalChartElements`); no second package or merge step
- Gauge shares `ChartChrome`, color resolution, and HostConfig layout patterns from Workstream D
- **fl_chart** remains a dependency of the charts package for bar/line/pie; gauge code lives alongside those files but does not import fl_chart

### Task F1: AdaptiveGaugeChart + registry

**Files:**

- Create: `packages/flutter_adaptive_charts_fs/lib/src/charts/gauge_chart.dart`
- Create: `packages/flutter_adaptive_charts_fs/lib/src/charts/gauge_painter.dart`
- Modify: `packages/flutter_adaptive_charts_fs/lib/src/card_chart_registry.dart`
- Modify: `packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_fs.dart` (export if needed)
- Test: `packages/flutter_adaptive_charts_fs/test/charts/gauge_chart_test.dart`

**Gauge spec properties to implement:**

- `value`, `min`, `max`, `segments[]`, `title`, `subLabel`
- `showLegend`, `showMinMax`, `valueFormat` (`Percentage` | `Fraction`)
- Reuse `ChartChrome` from Workstream D for title / legend when applicable _(gauge uses inline `_GaugeChrome` with equivalent layout; `colorSet` wired on gauge segments)_

- [x] **Step 1: Widget test** — segments render; value arc sweep matches `value` between `min` and `max`

- [x] **Step 2: Implement `GaugePainter`** — segment arcs; value indicator (arc or needle)

- [x] **Step 3: Implement `AdaptiveGaugeChart`** — `AdaptiveElementWidgetMixin` + `ProviderScopeMixin`; parse JSON; wrap with `SeparatorElement`

- [x] **Step 4: Update registry** — `'Chart.Gauge': (map) => AdaptiveGaugeChart(adaptiveMap: map)` (remove donut stub)

- [x] **Step 5: Optional HostConfig** — superseded by the completed `2026-06-08-charts-layout-config.plan.md` (`ChartsLayoutConfig`): gauge layout is config-driven via `resolveDonutLayout` reuse rather than a dedicated `chartsLayout.gauge` section. No further work. _(audit 2026-06-17)_

Run:

```bash
cd packages/flutter_adaptive_charts_fs
fvm flutter test test/charts/gauge_chart_test.dart --exclude-tags=golden
```

### Task F2: Widgetbook + samples

**Files:**

- Create: `widgetbook/lib/samples/v1.6/chart_gauge.json`
- Modify: `widgetbook/lib/adaptive_cards_use_cases.dart`

- [x] Add **Charts → Gauge** use case (same `GenericPage` + merged registry pattern as other chart samples)

- [x] Update [Implementation-Status.md](../../Implementation-Status.md) — `Chart.Gauge` ⚠️ → ✅ when complete

- [x] Update charts README — remove “Not Implemented” for gauge; document CustomPainter approach

- [x] **Golden test** — `test/golden_v1_6_test.dart` **Gauge Chart** case; sample `test/samples/v1.6/chart_gauge.json` → `gold_files/macos/v1_6_gauge.png`

---

## Workstream G — Text features

> **✅ Complete** — workstream G merged on `feat/workstream-g-text-features` (pending PR to `main`).

### Scope

Two tracks (both required for this plan):

1. **`RichTextBlock` + `TextRun`** — missing standard elements since v1.2
2. **`TextBlock` fixes** — document and fix highest-impact gaps from [text features spec](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/text-features)

### Task G1: Design spec (short)

**Files:**

- Create: `docs/superpowers/specs/2026-06-08-rich-text-and-text-features-design.md`

- [x] Document rendering approach: `RichTextBlock` → `Text.rich` with `TextSpan` children; each `TextRun` applies weight, color, italic, strikethrough, underline, `highlight`, `fontType`, `size`, `selectAction` on tap
- [x] Document `TextBlock` scope: keep markdown path; fix `maxLines` when markdown disabled; support `subtle`, `maxLines`, `wrap` parity (already mostly present)
- [x] Explicit non-goals: full HTML markdown, every Teams-only macro

### Task G2: TextRun + RichTextBlock

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/models/text_run.dart`
- Create: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rich_text_block.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/registry.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/elements/rich_text_block_test.dart`

- [x] **Step 1: `TextRunModel.fromJson`** — map spec fields

- [x] **Step 2: `AdaptiveRichTextBlock`** — parse `inlines` array; build `TextSpan` tree; wire `selectAction` per run via `TapGestureRecognizer`

- [x] **Step 3: Register in `CardTypeRegistry`**

- [x] **Step 4: Widget tests** — bold run, colored run, tap on run with `Action.OpenUrl`

- [x] **Step 5: Golden test** — basic mixed-style paragraph

### Task G3: TextBlock improvements

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/text_block.dart`
- Test: extend `packages/flutter_adaptive_cards_fs/test/elements/text_block_test.dart`

- [x] When `supportMarkdown == false`, honor `maxLines` on plain `Text`
- [x] Add test for `weight`, `color`, `isSubtle` without markdown
- [x] Document remaining markdown limitations in [Implementation-Status.md](../Implementation-Status.md)

### Task G4: Widgetbook

- [x] Sample JSON: `widgetbook/lib/samples/v1.2/rich_text_block_demo.json`
- [x] Use case next to existing TextBlock overlay page

---

## Final verification

- [x] **Repo analyze**

```bash
fvm flutter analyze
```

Expected: No issues found — **passed 2026-06-09**

- [x] **Core tests**

```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden
```

**400 passed** (~2 skipped), 2026-06-09 (includes `rich_text_block_test.dart`, `text_block_test.dart`)

- [x] **Charts tests**

```bash
cd packages/flutter_adaptive_charts_fs
fvm flutter test --exclude-tags=golden
```

**7 passed**, 2026-06-09

- [x] **Gauge tests** (after Workstream F)

```bash
cd packages/flutter_adaptive_charts_fs
fvm flutter test test/charts/gauge_chart_test.dart
```

**6 passed**, 2026-06-09

- [x] **Update [Implementation-Status.md](../../Implementation-Status.md)** for Icon, chart properties, gauge, refresh, and RichTextBlock/TextRun

- [x] **Icon golden** — `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_icon_test.dart --tags=golden`

- [x] **RichTextBlock golden** — `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_rich_text_block_test.dart --tags=golden`

- [x] **Gauge golden** — `cd packages/flutter_adaptive_charts_fs && fvm flutter test test/golden_v1_6_test.dart --name "Gauge Chart" --tags=golden`

- [x] **Full chart golden suite** (`fvm flutter test --tags=golden` in charts package) — **8 passed** on macOS 2026-06-09; Linux baselines via CI

---

## File map (summary)

| Area                  | Primary files                                                                      |
| --------------------- | ---------------------------------------------------------------------------------- |
| Optional packages doc | `docs/optional-packages-and-extensions.md`                                         |
| Refresh               | `models/refresh_config.dart`, `adaptive_card_element.dart`, `action_handler.dart`  |
| Icon                  | `cards/elements/icon.dart`, `utils/fluent_icon_map.dart`, `registry.dart`          |
| Chart colors          | `hostconfig/chart_color_sets.dart`, `reference_resolver.dart`                      |
| Chart chrome          | `flutter_adaptive_charts_fs/lib/src/charts/chart_chrome.dart`                      |
| Widgetbook charts     | `widgetbook/lib/chart_overlay_page.dart`                                           |
| Gauge                 | `flutter_adaptive_charts_fs/lib/src/charts/gauge_chart.dart`, `gauge_painter.dart` |
| Rich text             | `cards/elements/rich_text_block.dart`, `models/text_run.dart`                      |

---

Changelog: _Plan created: 2026-06-08_
