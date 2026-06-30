# Implementation Status Matrix

This is the **index** of implementation status across the Flutter-AdaptiveCards packages, measured against the Microsoft Adaptive Cards v1.6 specification. The detailed per-component tables **and their legend and known-gaps** now live in each **package README** (so they publish to pub.dev); this page links to them and carries the project-level **Priority Recommendations** roadmap and **Recently completed** history.

> [!IMPORTANT]
> When a component's implementation/tests/notes status **or its known gaps** change, update the **owning package's README** (e.g. [`packages/flutter_adaptive_cards_fs/README.md` → Implementation status](../packages/flutter_adaptive_cards_fs/README.md#implementation-status), which has its own legend + `### Known gaps`) — **not** this index. Only edit this page for the project-level roadmap, history, or pointers.

**Optional packages:** Charts and templating are **not** in the core library — see [optional-packages-and-extensions.md](./optional-packages-and-extensions.md).

**June 2026 feature plan (complete):** Workstreams **A–G** in [2026-06-08-refresh-icon-charts-text-features.plan.md](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md). **Backend invoke (complete):** [backend-host-integration.md](./backend-host-integration.md).

**Reference sites**:

- [Adaptive Cards documentation hub](https://adaptivecards.microsoft.com/) (responsive layout, Icon, Charts, and other v1.6+ features)
- [Schema explorer (learn.microsoft.com)](https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/adaptive-card) — current canonical per-element reference (the package READMEs' **Schema Explorer** columns link here)
- [Schema explorer (legacy adaptivecards.io)](https://adaptivecards.io/explorer/) — older site the **Microsoft Spec** columns still link to
- [Teams charts reference](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/charts-in-adaptive-cards)

---

## Core component status (`flutter_adaptive_cards_fs`)

The per-element tables for core **Card Elements, Containers, Root `AdaptiveCard` properties, Inputs, Actions, HostConfig, Common properties, and Custom/Extended elements** now live in the package README so they publish to pub.dev:

➡️ **[`flutter_adaptive_cards_fs` README → Implementation status](../packages/flutter_adaptive_cards_fs/README.md#implementation-status)**

Other packages: [charts](../packages/flutter_adaptive_charts_fs/README.md#implementation-status) · [templating](../packages/flutter_adaptive_template_fs/README.md#feature-coverage) · [backend host](../packages/flutter_adaptive_cards_host_fs/README.md#implementation-status).

---

## Charts (`flutter_adaptive_charts_fs` package)

Charts are implemented in a **separate opt-in package** ([optional-packages-and-extensions.md](./optional-packages-and-extensions.md)) so hosts that do not render charts avoid the **fl_chart** dependency. `Chart.*` elements are **partial** (data + chrome rendering; `Chart.Gauge` complete); responsive `targetWidth` / `grid.area` and block `height: stretch` remain unimplemented.

**Per-chart status and the full property-gap table now live with the package:** [`flutter_adaptive_charts_fs` README → Implementation status](../packages/flutter_adaptive_charts_fs/README.md#implementation-status).

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

Templating lives in a **separate opt-in package**. Core binding (`${...}`, `$data`/`$root`/`$index`, array repeat, `$when`, `json()`/`if()`) is **complete**; Adaptive Expressions are **partial** (`select`/`where` need lazy lambda evaluation).

**The full per-feature table now lives with the package:** [`flutter_adaptive_template_fs` README → Feature coverage](../packages/flutter_adaptive_template_fs/README.md#feature-coverage).

---

## Priority Recommendations

> [!NOTE]
> **Prioritization updated 2026-06-28.** Responsive `Layout.Flow`, **`Layout.AreaGrid`**, and block **`height: "stretch"`** have all shipped (Container, root, Column, TableCell). Responsive layout is now **feature-complete except `Layout.Flow` `itemFit: "Fill"`** (see Low priority). Two items remain **deprioritized by maintainer decision** — see **Deferred** below: `requires` + action `fallback` + version gating, and all `rtl` rendering.

### High priority — standard cards

_None currently — the prior top priorities (`Layout.AreaGrid` + `grid.area` and block `height: "stretch"`) shipped 2026-06-28; see **Recently completed**._

### Medium priority

1. **Complete `Table`**: `auto`/`stretch` column widths and `bleed`. (Cell `rtl` rendering → **Deferred**.)
2. **AdaptiveCard root features**: `fallbackText`, `minHeight`, root `verticalContentAlignment` (`refresh` ✅, `selectAction` ✅ — see [plan workstream B](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md#workstream-b--refresh-property-v14)). (Root `rtl` → **Deferred**.)
3. **Media poster fix**: Resolve poster attribute display issue.

### Low priority

1. **Test coverage**: Expand tests for partial implementations (charts, Media, Table).
2. **Documentation**: Add `Custom-Extensions.md` index (see [docs/README.md](./README.md#missingrecommended-documentation)).
3. **`CaptionSource`**: Render parsed caption tracks (VTT) on the Media video surface.
4. **`bleed`**: Container full-bleed layouts.
5. **Adaptive Expressions**: `select`/`where` collection functions in templating (require lazy lambda evaluation; other collection and date functions are now implemented).
6. **`Icon` catalog long tail**: The Fluent name catalog now maps ~210 names (`lib/src/utils/fluent_icon_map.dart`); expand further for uncommon hub icon names that still fall back to `help_outline`.
7. **Flow follow-ups** (deferred from the [2026-06-27 finish-Flow work](./superpowers/specs/2026-06-27-finish-layout-flow-design.md)): `itemFit: "Fill"` (needs a custom row-packing layout), Flow on the `listView` body path, and the W4 width-measurement remainder (margin-inclusive measurement; nested `Action.ShowCard` width).

### Deferred (by maintainer decision, 2026-06-27)

These are **not** being scheduled now despite their value; revisit after the responsive layout work (AreaGrid) lands.

1. **`requires` + action `fallback` + version gating**: Graceful degradation for mixed-schema hosts (unknown actions still `assert(false)`; `requires` capability checks and `fallbackText` unimplemented). High value for production Teams/Bot hosts — explicitly deferred, not dropped.
2. **`rtl` rendering**: cell-level `rtl` (Table — parsed in `TableCellModel` but not applied) and root/element `rtl`. Low priority for current consumers.

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

### Fluent icon catalog expansion (2026-06-28)

- The `Icon` element's Fluent name catalog grew from the original ~68 mappings to **~210** (`packages/flutter_adaptive_cards_fs/lib/src/utils/fluent_icon_map.dart`), so far fewer hub icon names fall back to `help_outline`. Remaining long-tail coverage is now a **Low priority** follow-up rather than a Medium gap (PR #54).

### Load icon font in golden tests (2026-06-28)

- Golden tests now load **all bundled fonts** from `FontManifest.json` (most importantly **MaterialIcons**) via a new `loadBundledTestFonts()` in `flutter_adaptive_cards_test_support`, run from `adaptiveCardsTestExecutable`'s `setUpAll` alongside the Roboto loader. Icon-bearing goldens (`v1_5_icon_demo`, `v1_6_icon_catalog`, `v1_6_accordion`, `v1_6_rating`, `sample1*`, `sample2*`, `sample5*`) now render real glyphs instead of missing-glyph tofu boxes, so they can catch wrong glyphs and `help_outline` fallbacks — not just layout.
- macOS baselines regenerated; Linux CI baselines refresh on the next build. Charts goldens were unaffected (byte-identical — no icon glyphs).

### Layout.AreaGrid + block height: stretch (2026-06-28)

Plan: [2026-06-28-areagrid-and-height-stretch.md](./superpowers/plans/2026-06-28-areagrid-and-height-stretch.md) — designs: [block height: stretch](./superpowers/specs/2026-06-28-block-height-stretch-design.md), [Layout.AreaGrid](./superpowers/specs/2026-06-28-layout-areagrid-design.md).

- **`Layout.AreaGrid` + `grid.area`** via a bespoke `RenderAdaptiveAreaGrid` (no new core dependency): percent/px/implied columns, `columnSpan`/`rowSpan`, `columnSpacing`/`rowSpacing`, `targetWidth`-selected grids, and fail-open fallback for unplaced/unknown-area elements (rendered below the grid, logged). Reuses `selectLayout` + `cardWidthBucketProvider`; threaded into Container/Column/TableCell/root via `buildLayoutChildren(childMaps:)`.
- **Block `height: "stretch"`** on Container/Column/root body in bounded contexts (degrades to `auto` when unbounded), via `buildStretchableColumn` + shared `isStretchHeight`. Backed by a custom intrinsics-aware `RenderStretchColumn` (not a `LayoutBuilder`), so stretch works inside `IntrinsicHeight` (ColumnSet columns, Table rows); AreaGrid cells consume the same predicate.
- **Deviation from plan (approved):** the height:stretch mechanism uses a custom `RenderObject` instead of a `LayoutBuilder`, which throws inside `IntrinsicHeight`.
- Responsive layout is now feature-complete except `Layout.Flow` `itemFit: "Fill"`.

### Finish Layout.Flow (2026-06-27)

Plan: [2026-06-27-finish-layout-flow.md](./superpowers/plans/2026-06-27-finish-layout-flow.md) — design: [2026-06-27-finish-layout-flow-design.md](./superpowers/specs/2026-06-27-finish-layout-flow-design.md).

- `Layout.Flow` extended to **Column** and **TableCell** (Container + root already shipped); shared `buildLayoutChildren` helper.
- `itemWidth` + `itemFit` parsing (`Fit` honored; `Fill` deferred, falls back to `Fit` with a log).
- `itemWidth` items skip `IntrinsicWidth` (fixed `SizedBox`); content-fit items keep it (W1's "remove it" was rejected — its premise was wrong; `Wrap` does not content-size elements that wrap content in an expanding `Align`, e.g. `TextBlock`). `selectLayout` prefers the most-specific relational match (W3); unbounded card width logs and defaults to `wide` (W4 partial).
- **Spec correction:** `ColumnSet` has no `layouts` property — earlier "Flow on ColumnSet" wording was wrong.

### Action behavior unification (2026-06-17)

Plan: [2026-06-17-action-behavior-unification.plan.md](./plans/2026-06-17-action-behavior-unification.plan.md) — design spec: [2026-06-17-action-behavior-unification-design.md](./superpowers/specs/2026-06-17-action-behavior-unification-design.md).

- **`Action.Popover`** refactored from inline tap handler to `GenericPopoverAction` / `DefaultPopoverAction` registry pattern — consistent with Submit, Execute, OpenUrl, ToggleVisibility, and ResetInputs.
- **`AdaptivePopoverContainer`** extracted to `popover_container.dart` to resolve circular import; re-exported from `popover.dart` for backward compatibility.
- **`MyTestHttpOverrides`** extended with optional `urlResponder` factory in `flutter_adaptive_cards_test_support`; `open_url_dialog_test.dart` migrated off bespoke `MockHttpOverrides`.
- Test `RawAdaptiveCardState` access normalized to `_cardState(WidgetTester)` helper across overlay test files.

**Verification (2026-06-17):** `fvm flutter analyze` clean; **466** core tests passed, 2 skipped, 0 failed.

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

_Last Updated: 2026-06-29_
_Based on v1.6.0 of Microsoft Adaptive Cards specification_
