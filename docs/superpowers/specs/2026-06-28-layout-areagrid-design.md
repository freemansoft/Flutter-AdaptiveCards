# `Layout.AreaGrid` + `grid.area` (design)

**Date:** 2026-06-28
**Status:** Approved (brainstorming) — pending implementation plan
**Package:** `flutter_adaptive_cards_fs`
**Spec basis:** Adaptive Cards v1.6 responsive layout — [container layouts](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/container-layouts), [documentation hub](https://adaptivecards.microsoft.com/?topic=container-layouts)
**Builds on:** shipped [responsive `Layout.Flow`](./2026-06-27-finish-layout-flow-design.md) (`cardWidthBucketProvider`, `selectLayout`, `layouts` on Container/Column/TableCell/root) and the companion [block `height: stretch`](./2026-06-28-block-height-stretch-design.md). Implemented together via one combined plan.

## Summary

`Layout.AreaGrid` is the last and largest piece of v1.6 responsive layout: it
divides a container into a **named-area grid** and places child elements into areas
via each child's `grid.area` property. Multiple AreaGrid layouts can be attached to
one container and selected by `targetWidth`, so a card reflows between grid shapes
(and the `Layout.Stack` default) as the card width changes.

Flutter has no CSS-grid primitive, so this is implemented as a **bespoke
`RenderBox`** (`RenderAdaptiveAreaGrid`) — chosen over a third-party grid package to
keep the core lean (the same reason `fl_chart` lives in the charts package, not
core). The grid reuses the existing width-bucket selection (`selectLayout` +
`cardWidthBucketProvider`) and the `isStretchHeight` predicate from the
height-stretch design for in-cell stretch.

## Goals / non-goals

**Goals**
- Authors place elements into a named grid via `grid.area`; the grid supports `%`
  and `px` columns, implied (equal-share) columns, `columnSpan`/`rowSpan`, and
  `columnSpacing`/`rowSpacing`.
- Multiple `Layout.AreaGrid` (and `Layout.Flow`/`Stack`) entries select by
  `targetWidth`, reactively on resize — reusing the shipped selection path.
- `grid.area` is honored on any element; `height: "stretch"` fills its area cell.
- **Zero behavior change** for cards without `Layout.AreaGrid`.

**Non-goals**
- `Layout.Flow`/`Stack` (already shipped) and chart stretch (deferred).
- CSS-grid features beyond the AC spec (gap shorthands, line names, `minmax`, etc.).
- Auto-flow of elements with no `grid.area` into empty cells — unplaced elements get
  a defined, simple fallback (below), not full auto-placement.

## Model (parsing)

`Layout.AreaGrid` object:

| Field | Type | Notes |
| --- | --- | --- |
| `type` | `"Layout.AreaGrid"` | |
| `columns` | `List` of `number` (percent) and/or `"<n>px"` strings | explicit track widths; may be shorter than the area grid (see column resolution) |
| `areas` | `List<GridArea>` | named areas |
| `columnSpacing` | spacing token (default `"default"`) | gap between columns |
| `rowSpacing` | spacing token (default `"default"`) | gap between rows |
| `targetWidth` | bucket / `atLeast:`/`atMost:` | already handled by `selectLayout` |

`GridArea`: `{ name: String, column: int = 1, columnSpan: int = 1, row: int = 1, rowSpan: int = 1 }` (indices 1-based). Parsed into a typed `GridAreaModel`.

Child elements carry `grid.area: "<name>"` (a top-level key on the element JSON).

## Architecture

| Piece | Location | Role |
| --- | --- | --- |
| `GridAreaModel` + `AreaGridLayout` parse | `lib/src/responsive/area_grid_model.dart` (new) | **Pure** typed parse of `areas`/`columns`/spacing; tolerant of missing/garbage fields (defaults applied). |
| Column/row resolution | `lib/src/responsive/area_grid_solver.dart` (new) | **Pure** functions: resolve column widths from available width (`px`/`%`/implied-equal, minus spacing); compute the grid dimensions (`rows`, `cols`) from areas. Unit-testable without widgets. |
| `RenderAdaptiveAreaGrid` + `AdaptiveAreaGrid` widget | `lib/src/responsive/adaptive_area_grid.dart` (new) | `MultiChildRenderObjectWidget` + `RenderBox` performing layout: measure non-stretch children, size rows, place spanning children, stretch `height:stretch` children to their full area height. |
| `buildLayoutChildren` extension | `lib/src/responsive/layout_children.dart` | Add an optional `childMaps` param; when the selected layout is `Layout.AreaGrid`, build `AdaptiveAreaGrid(layout, childMaps, children, styleResolver)`. Flow/stack paths ignore `childMaps`. |
| Container build sites | `container.dart`, `column.dart`, `adaptive_card_element.dart`, `table.dart` | Pass `childMaps` (the raw item JSON list, index-aligned with `children`) through `buildLayoutChildren`. |

### Threading `grid.area`

`buildLayoutChildren` currently receives only built `Widget`s, but placement needs
each child's `grid.area` (from JSON). The build sites already hold the item maps, so
they pass a parallel `childMaps` list (index-aligned with `children`).
`AdaptiveAreaGrid` reads `childMaps[i]['grid.area']` and pairs it with `children[i]`.

### The grid layout algorithm (`RenderAdaptiveAreaGrid`)

1. **Columns.** `colCount = max(columns.length, max(area.column + area.columnSpan − 1))`.
   Available width = incoming `maxWidth` − `columnSpacing × (colCount − 1)`. Assign
   `px` tracks their fixed width and `%` tracks their fraction of available width;
   any implied (undeclared) columns split the remainder equally (per the MS spec:
   "they each share an equal portion of the remaining space"). Clamp to ≥ 0.
2. **Rows.** `rowCount = max(area.row + area.rowSpan − 1)`. Lay out each non-stretch
   child with a tight width = sum of its spanned column widths (+ interior column
   spacing) and a loose height; record its natural height. Each row height = max
   over single-row children anchored in that row; then a second pass grows rows so
   every multi-row span fits (distribute deficit across its spanned rows).
3. **Stretch.** A child with `isStretchHeight` is (re)laid out with a tight height =
   its full area height (sum of spanned row heights + interior row spacing).
4. **Place.** Position each placed child at its area's `(x, y)` with size
   `(spanWidth, spanHeight)`. Grid size = (available width incl. spacing) ×
   (Σ row heights + `rowSpacing × (rowCount − 1)`).

### Placement & fallback (fail-open)

- `grid.area` matches a defined area → placed in that area's rect (spanning).
- **No `grid.area`, or an unknown name** → the child is **not** dropped: it is
  collected and rendered in a `Column` **appended below the grid**, and the unknown
  name is logged via `dart:developer`. Rationale: mirrors the `targetWidth`
  fail-open philosophy — author mistakes must never silently vanish content.
- Two areas occupying the same cell → children placed in declaration order (overlap
  is author error; last drawn on top).

### Selection / reactivity

Unchanged from Flow: `selectLayout(layouts, bucket)` already prefers exact-bucket >
most-specific relational > default, and the grid reads `cardWidthBucketProvider`
through `buildLayoutChildren`, so multiple `targetWidth`-scoped AreaGrid layouts
switch on resize with no extra plumbing.

## Error handling / edge cases

- **Empty/garbage `columns`** → all columns implied (equal share).
- **Area references a column/row beyond `columns.length`** → grid grows implied
  columns/rows to fit (per the algorithm's `max(...)`).
- **`columnSpan`/`rowSpan` ≤ 0 or overflowing the grid** → clamped to ≥ 1 and to the
  grid bounds.
- **Unbounded incoming width** (rare) → reuse the width-bucket guard's spirit: log
  and treat `%` columns against a `wide`-equivalent fallback width, or fall back to
  the stack. (Decided in plan; default: fall back to `Layout.Stack` when width is
  non-finite, since `%` columns are undefined without a finite width.)
- **No areas / no placed children** → renders the unplaced-fallback stack (or empty).

## Testing

- **Pure unit** (`test/responsive/area_grid_solver_test.dart`): column-width
  resolution (all `%`; mixed `%`+`px`; implied-equal; spacing subtraction; area
  beyond declared columns); grid dimension computation incl. spans.
- **Widget** (`test/responsive/area_grid_widget_test.dart`): single-area placement;
  `columnSpan`/`rowSpan` sizing; two areas side-by-side; `height:"stretch"` cell
  fills its row band; unplaced/unknown-`grid.area` child appears in the fallback
  stack; `targetWidth` switches grids narrow↔wide.
- **Golden** (tagged `golden`): the MS image-left / text-below sample at a narrow and
  a wide width (mirrors the documented AreaGrid responsive example). macOS baselines
  generated; linux baselines regenerated on a Linux runner before merge.
- **Verification:** `fvm flutter analyze` clean; `fvm flutter test
  --exclude-tags=golden` green; coverage gate PASS.

## Documentation impact

- README **Common properties**: `layouts` row → add `Layout.AreaGrid` ✅ and a new
  `grid.area` row ✅ (was ❌ Missing). Note charts deferred.
- `docs/Implementation-Status.md`: move `Layout.AreaGrid`/`grid.area` from
  high-priority into Recently completed (shared entry with `height: stretch`);
  responsive layout is then feature-complete except `itemFit: "Fill"`.
- New authoring section/example for AreaGrid (columns, areas, `grid.area`,
  `targetWidth`-selected grids).
- `flutter_adaptive_cards_fs/CHANGELOG.md`: `## [0.13.0]` Added bullet.

## Open items to confirm during planning

- Final unbounded-width behavior (fall back to stack vs. assume a wide width) — lean:
  fall back to `Layout.Stack`.
- Whether `columns` `%` values are fractions of the full incoming width or of the
  width net of `px` tracks (spec says "percentage of the available width"; plan pins
  this to net-of-`px`, net-of-spacing and adds a unit test either way).
