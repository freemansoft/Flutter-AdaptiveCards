# Complete the Table: `auto`/`stretch` column widths + cell `minHeight`

_Date: 2026-06-29_
_Status: Draft for review_
_Package: `flutter_adaptive_cards_fs`_

## 1. Summary

The `Table` element renders today via per-row `IntrinsicHeight` + `Row` widgets, wrapping
each cell in `Expanded` (numeric/relative weight) or `SizedBox` (pixel) widths. This works
for numeric and `px` widths but **cannot** support `auto` (content-sized, consistent across
rows) or `stretch`, because each row lays out independently and column widths that depend on
content require cross-row measurement.

This effort re-renders the table through Flutter's built-in **`Table`** widget, which sizes
each column across all rows in a single layout pass, and adds the cell `minHeight` constraint.

### In scope

- Column `width`: `auto` (content-sized, cross-row consistent), `stretch` (fills remaining
  space), preserving existing numeric (relative weight) and `Npx` (fixed) behavior.
- Cell `minHeight` — parsed today (`TableCellModel.minHeight`) but never applied.
- A regression **test** for cell `backgroundImage`, which already renders (see §6).

### Out of scope

- **`bleed`** (cell background extending into table padding) — deferred to its own effort.
- **Cell `rtl`** — explicitly deferred (maintainer decision); `TableCellModel.rtl` stays
  parsed-but-unrendered.
- **Cell `separator`/`spacing`** — **dropped.** Not valid `TableCell` schema properties
  (the v1.5 `TableCell` schema defines `items`, `selectAction`, `style`,
  `verticalContentAlignment`, `bleed`, `backgroundImage`, `minHeight`, `rtl`). No sample
  exercises them; the `spacing` values in `test/samples/table1.json` are on TextBlocks
  *inside* cells, already handled by `SeparatorElement`.

## 2. Current state

`packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart`

- `build()` builds a `Column` of row widgets, optionally wrapped in a `Container` with
  `Border.all` when `showGridLines`.
- `generateTableRows` inserts `Divider` (grid lines on) or `SizedBox` (grid lines off)
  between rows.
- `generateTableRowWidgets` builds each row as `IntrinsicHeight(Row(crossAxisAlignment:
  stretch, …))`, inserting `VerticalDivider`/`SizedBox` between cells, and wraps each cell in:
  - `Expanded(flex: N)` when `width` is a number,
  - `SizedBox(width: px)` when `width` is `"Npx"`,
  - `Expanded()` (flex 1) otherwise — **this is the bug**: `"auto"` and `"stretch"` both
    collapse to flex-1, so `auto` is silently wrong and `stretch` is indistinguishable from a
    weight-1 column.
- Cell content: decorated `Container` (background color via `resolveContainerBackgroundColor`,
  background image via `getDecorationFromMap`) → `Align` (H+V alignment) → `Scrollbar` →
  `buildLayoutChildren` (responsive `layouts`). Header rows add a `DefaultTextStyle`.
  `selectAction` wraps the cell in `AdaptiveTappable`.

Models are already complete: `TableColumnDefinition.width` (`dynamic`) and
`TableCellModel.minHeight` (`String?`) / `backgroundImage` (`dynamic`) are parsed.

## 3. Approach

**Chosen: render through Flutter's `Table` widget.** Flutter `Table` computes column widths
across all rows in one pass — exactly what `auto` requires — and maps all four Adaptive Cards
width modes onto its `TableColumnWidth` types. It also replaces the manual divider/spacer
bookkeeping with `TableBorder`, and *reduces* the amount of custom layout code.

| AC `width`        | `TableColumnWidth`        |
| ----------------- | ------------------------- |
| `"auto"`          | `IntrinsicColumnWidth()`  |
| `"stretch"`       | `FlexColumnWidth(1)`      |
| number `N` (`>0`) | `FlexColumnWidth(N)`      |
| `"Npx"`           | `FixedColumnWidth(N)`     |
| absent / unknown  | `FlexColumnWidth(1)`      |

### Resolved risk — per-cell backgrounds and equal-row height

The current code fills each cell's background to the full row height via `IntrinsicHeight` +
`CrossAxisAlignment.stretch`. Flutter `Table` offers `TableCellVerticalAlignment`:

- `fill` — sized to row height, **but does not contribute to it**; a row whose cells are *all*
  `fill` collapses to **zero height** (`flutter/.../rendering/table.dart:353`). Unusable here.
- `intrinsicHeight` — *"sized to be the same height as the tallest cell in the row"*
  (`table.dart:356`) **and** contributes to row height. This reproduces the current
  `IntrinsicHeight`+stretch behavior exactly.

**Decision:** use `defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight`. Each
cell's decorated `Container` fills the full row height (backgrounds fill); an **inner `Align`**
positions content for vertical (`top`/`center`/`bottom`) and horizontal alignment — unchanged
from today.

### Rejected alternatives

- **Custom `RenderObject`** (mirroring `RenderAdaptiveAreaGrid` / `RenderStretchColumn`):
  maximum control but reimplements what `Table` already does correctly, with a far larger
  bug/test surface. Reserve only if `Table` constraints bite.
- **Two-pass measurement keeping per-row `Row`s:** smallest diff, but measuring each `auto`
  column's widest content across rows without a real table layout is fragile (wrapping text,
  two-phase builds) — a worse reimplementation of `Table`.

## 4. Detailed design

### 4.1 Column-width mapping (isolated, unit-testable)

Extract a pure top-level function so the branch logic is testable without a widget pump:

```dart
/// Maps an Adaptive Cards Table column `width` to a Flutter [TableColumnWidth].
/// `"auto"` → intrinsic (content) width; `"stretch"` / absent / unrecognized →
/// flex-1; a positive number → flex weight; `"Npx"` → fixed pixels.
TableColumnWidth mapColumnWidth(Object? width) { … }
```

Rules (string match case-insensitive, trimmed):

- `num n` → `n > 0 ? FlexColumnWidth(n.toDouble()) : const FlexColumnWidth(1)`.
- `"auto"` → `const IntrinsicColumnWidth()`.
- `"stretch"` → `const FlexColumnWidth(1)`.
- `"<n>px"` with parseable `n` → `FixedColumnWidth(n)`; unparseable → `FlexColumnWidth(1)`.
- `null` / anything else → `const FlexColumnWidth(1)` (the table's default column).

Default-when-omitted is `stretch` (flex-1), matching today's behavior.

### 4.2 Table construction

In `build()` (replacing `generateTableRows` / `generateTableRowWidgets`):

1. `columnCount = max(columns.length, rows.map(cellCount).fold(0, max))`.
2. `columnWidths = { for (i in 0..columnCount-1) i: mapColumnWidth(columns[i]?['width']) }`
   (indices beyond `columns.length` use the default).
3. For each row, build a `TableRow` of exactly `columnCount` `Widget` children; **pad** ragged
   rows with `const SizedBox.shrink()` so all rows match `columnCount` (a `Table` asserts equal
   children counts).
4. `Table(columnWidths: columnWidths, defaultColumnWidth: const FlexColumnWidth(1),
   defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
   border: showGridLines ? TableBorder.all(color: borderColor) : null, children: rows)`.
5. Keep the `Visibility` + `SeparatorElement` wrappers. **Remove** the outer
   `Container(Border.all)` (now drawn by `TableBorder.all`).

### 4.3 Cell widget (per cell, mostly preserved)

Each cell child keeps its current pipeline, minus the `Expanded`/`SizedBox` width wrapper
(the `Table` owns width now) and the divider/spacer siblings (the `TableBorder` owns lines):

```
[selectAction? AdaptiveTappable]
  → Container(decoration: bg color + image)        // fills row height via intrinsicHeight
    → ConstrainedBox(minHeight)                     // §4.5, only when minHeight present
      → Align(H+V alignment)
        → [header? DefaultTextStyle]
          → Scrollbar → buildLayoutChildren(responsive layouts)
```

**Widget keys.** A Flutter `Table` has no per-column wrapper and a `TableRow` is not a
findable element, so the key story changes:

- `tableColumnKey` → on the `Table` widget (still resolves via `find.byKey`).
- `cellKey` → on each cell child `Container` (unique per `row,col`; the **primary** test handle).
- `rowKey` → set on `TableRow.key` for state/diffing, but `find.byKey(rowKey)` no longer
  resolves to an element; row-level assertions migrate to cell-based finders.
- `columnKey` → no per-column widget exists. The **public static helper is retained** (no
  breaking API change) but is no longer attached to a widget; column-width assertions move to
  inspecting `Table.columnWidths` and/or `cellKey` rectangles (§6).

### 4.4 Spacing when `showGridLines: false`

A `Table` cannot hold spacer children. Replace the inter-cell/inter-row `SizedBox` spacers
with **cell padding** using the existing `resolveSpacing('default')` value:

- trailing horizontal padding on every cell except the last column,
- trailing vertical padding on every cell except the last row.

When `showGridLines: true`, `TableBorder.all` draws the 1px lines (outer + inner) and no extra
padding is added — closest to today's divider rendering.

### 4.5 `minHeight`

`TableCellModel.minHeight` is a string (e.g. `"80px"`). Parse to a double (strip a trailing
`px`; ignore unparseable values) and wrap the cell content in
`ConstrainedBox(constraints: BoxConstraints(minHeight: value))`. Because
`intrinsicHeight` sizes every cell to the tallest in the row, a single cell's `minHeight`
raises the whole row's height — the expected Adaptive Cards behavior.

### 4.6 `backgroundImage` — already works

The cell decoration already routes through `getDecorationFromMap(cellModel.toJson(), …)`,
which renders `backgroundImage` via `getDecorationImageFromMap`
(`adaptive_mixins.dart:169‑184`); `cellModel.toJson()` includes `backgroundImage`. **No
rendering change** — add a regression test only (§6).

## 5. Edge cases / error handling

- **Ragged rows** (fewer cells than columns) → padded with empty cells; no crash.
- **More cells than column defs** → extra columns use the default `FlexColumnWidth(1)`.
- **All-`auto` table narrower than available width** → table is content-width (correct; no
  stretch column to fill remainder).
- **`px` totals exceeding available width** → horizontal overflow, same risk as today; not
  introduced here.
- **Zero/negative numeric weight** → treated as `FlexColumnWidth(1)`.
- **Empty `rows`** → empty `Table` (no rows); render nothing meaningful, no crash.
- **`firstRowAsHeader` with an empty first row** → header styling applies to the (empty) row;
  no crash.

## 6. Testing

**Unit** (`test/containers/` or `test/models/`):

- `mapColumnWidth` for every branch: `auto`, `stretch`, `0`/`1`/`3`, `"50px"`, `"bad"`,
  `null`, unknown string → asserts exact `TableColumnWidth` runtime type (and weight/value).

**Widget** (`test/containers/table_test.dart`):

- **Column-width mapping (white-box):** assert `tester.widget<Table>(…).columnWidths` holds the
  expected `TableColumnWidth` types/weights. This **replaces** the existing
  `Expanded.flex`-via-`columnKey` test (lines ~300‑306), which asserts the old per-row
  `Expanded` implementation that no longer exists.
- **`auto` cross-row consistency:** an `auto` column with different content lengths per row
  renders that column at the **same width** in every row (compare `cellKey` rects by column).
- **`stretch` fills remainder:** `auto` + `stretch` columns — the `stretch` column consumes
  the leftover width.
- **numeric weights** distribute proportionally; **`px`** column is fixed.
- **`minHeight`** raises the cell/row height to at least the parsed value.
- **`backgroundImage`** regression: a cell with `backgroundImage` yields a `DecorationImage`.
- **Ragged rows** render without throwing.
- **Grid lines on/off** (presence of `TableBorder`; padding-based gutters when off).

**Golden** (`--tags=golden`):

- Regenerate `table1`/`table2` baselines (macOS locally; Linux CI refreshes).
- Add one new golden exercising `auto` + `stretch` + `px` + numeric in one table, with a
  styled cell (background) and a `minHeight` cell.

## 7. Documentation sync (plan-completion gate)

On completion, update:

- `packages/flutter_adaptive_cards_fs/README.md` → **Implementation status** + **Known gaps**:
  Table row drops `auto`/`stretch` widths and `minHeight`; keeps `bleed` and cell `rtl`.
- `docs/Implementation-Status.md` → Medium-priority item 1: narrow to `bleed` (+ cell `rtl`
  Deferred); add a *Recently completed* entry.
- `.agents/skills/adaptive-cards-spec-compliance/SKILL.md` (and `.claude/skills/…` copy)
  line ~285: Table now `auto`/`stretch` complete; remaining gap is cell `rtl` (+ `bleed`).
- `CHANGELOG.md` (`flutter_adaptive_cards_fs`) `## [Unreleased]` bullet.

## 8. Verification

```bash
# Repo root
fvm flutter analyze

# Main library (non-golden)
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden

# Goldens (after regeneration)
fvm flutter test --tags=golden

# Coverage gate (repo root, after --coverage run)
fvm dart run tool/coverage/check_coverage.dart
```
