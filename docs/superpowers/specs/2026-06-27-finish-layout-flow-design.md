# Finish `Layout.Flow` — `itemFit`/`itemWidth`, Column + TableCell, W1/W3 (design)

**Date:** 2026-06-27
**Status:** Approved (brainstorming) — pending implementation plan
**Package:** `flutter_adaptive_cards_fs` (+ `widgetbook` sample sync)
**Spec basis:** Adaptive Cards v1.6 responsive layout — [container layouts](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/container-layouts), [documentation hub](https://adaptivecards.microsoft.com/?topic=responsive-layout)
**Builds on:** [2026-06-18 responsive layout (`targetWidth` + `Layout.Flow`) design](./2026-06-18-responsive-layout-targetwidth-flow-design.md) and its post-implementation review (W1–W5)

## Summary

The first responsive-layout slice shipped `targetWidth` (all elements) and
`Layout.Flow` on **`Container`** and the **card root body** (PR #36). This change
finishes the `Layout.Flow` story to the extent the spec allows without a custom
row-packing render object:

1. **Flow sizing properties** — add **`itemWidth`** (fixed px) and parse
   **`itemFit`**; honor `itemFit: "Fit"` (the existing content-fit behavior).
2. **Extend `layouts` / `Layout.Flow`** to **`Column`** and **`TableCell`**
   (Container + root already shipped).
3. **Correctness fixes coupled to the wider Flow surface** — refine the per-item
   `IntrinsicWidth` wrapper (**W1**): keep it for content-fit items (it is required —
   see below) but skip it for fixed `itemWidth`; give `selectLayout` a real specificity
   tiebreak (**W3**); add an unbounded-width guard at the root measurement.
4. **Keep the golden/test sample card and the widgetbook demo in sync** — one new
   `flow_column.json` sample drives the new golden test, the widget tests, and the
   widgetbook `ResponsiveFlowPage`.

### Spec correction (important)

The June-18 design and `Implementation-Status.md` described the remaining work as
"Flow on **ColumnSet**/Column/TableCell". That is wrong against the spec. Per the
Microsoft container-layouts documentation:

> "Containers such as `Container`, `Column`, `TableCell`, or an Adaptive Card itself
> support three different types of layouts."

`layouts` is supported on **`Container`, `Column`, `TableCell`, and the `AdaptiveCard`
root** — **not on `ColumnSet`** (the ColumnSet schema has no `layouts` property; it is
its own row primitive that predates the generic layout system). This design therefore
targets **`Column`** and **`TableCell`**, and corrects the roadmap wording.

### Explicitly out of scope (documented as remaining gaps)

- **`itemFit: "Fill"`** — items in a row grow to evenly fill remaining horizontal
  space. Flutter's `Wrap` cannot stretch items to fill a row, so `Fill` needs a custom
  row-packing layout (`LayoutBuilder` + manual row breaking, or a custom
  `RenderObject`). Deferred by decision; `Fill` falls back to `Fit` with a one-time log.
- **`ColumnSet` layouts** — not in the spec (see above).
- **`Layout.AreaGrid` + `grid.area`** — separate spec; already deferred.
- **W4** (margin-inclusive width measurement; nested `Action.ShowCard` width semantics)
  and **W5** (the `listView` body path skipping Flow) — except the cheap
  unbounded-width guard, which is folded in here.

## Goals / non-goals

**Goals**

- Authors can reflow a `Column` or `TableCell` from a vertical stack to a wrapping
  `Layout.Flow` at chosen card widths, with the same `layouts` + `targetWidth`
  selection used by `Container` and the root body today.
- `Layout.Flow` honors `itemWidth` (fixed px) and `itemFit: "Fit"`; `minItemWidth` /
  `maxItemWidth` continue to work; `itemFit: "Fill"` degrades gracefully.
- Content-fit flow items size to their natural width (via `IntrinsicWidth`), which is
  required so elements like `TextBlock` (whose content sits in an expanding `Align`) flow
  instead of each filling the row. `itemWidth` items skip `IntrinsicWidth` (fixed
  `SizedBox`), giving a perf win and a safe path for items without an intrinsic width.
- The flow sample card stays a single source of truth shared by the golden test,
  widget tests, and the widgetbook demo.
- **Zero behavior change** for cards that do not declare `layouts` — purely additive.

**Non-goals**

- `itemFit: "Fill"`, `ColumnSet` layouts, `AreaGrid`/`grid.area`, and the remaining
  W4/W5 robustness items (deferred; see Scope).
- Changing the width-bucket measurement mechanism (kept as the existing scoped
  `cardWidthBucketProvider`).

## Background — current state

| Piece                | Location                                                   | Current behavior                                                                                                                               |
| -------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `AdaptiveFlowLayout` | `lib/src/responsive/adaptive_flow_layout.dart`             | `Wrap`; spacing + alignment; **wraps every item in `IntrinsicWidth`** (W1); honors `minItemWidth`/`maxItemWidth`; **no `itemWidth`/`itemFit`** |
| `selectLayout`       | `lib/src/responsive/layout_selection.dart`                 | Picks exact-bucket > **first** relational > default; **first relational wins, not most specific** (W3)                                         |
| Container Flow       | `lib/src/cards/containers/container.dart`                  | Inline `selectLayout` + `AdaptiveFlowLayout`-vs-`Column` branch                                                                                |
| Root body Flow       | `lib/src/cards/adaptive_card_element.dart` (`_BodyLayout`) | Inline `selectLayout` + `AdaptiveFlowLayout`-vs-`Column` branch                                                                                |
| `Column`             | `lib/src/cards/containers/column.dart`                     | Renders items in a `Column` (stack); **no `layouts`**                                                                                          |
| `TableCell`          | `lib/src/cards/containers/table.dart` (`buildCellContent`) | Renders items in a `Wrap`; **no `layouts`**                                                                                                    |

The `cardWidthBucketProvider` (scoped, fail-open `wide`) and `targetWidth` evaluation
are unchanged by this design.

## Behavior

### `Layout.Flow` sizing (spec property set)

Per the spec, a `Layout.Flow` object supports: `columnSpacing`, `rowSpacing`,
`horizontalItemsAlignment`, `verticalItemsAlignment`, `itemFit` (`Fit` default /
`Fill`), `itemWidth`, `minItemWidth`, `maxItemWidth`, `targetWidth`. Mutual-exclusion
rules from the spec:

- `itemWidth` **must not** be combined with `minItemWidth` / `maxItemWidth`.
- `maxItemWidth` **should not** be combined with `itemFit: "Fill"`.

Item sizing after this change (W1 + `itemWidth`):

| JSON                                                  | Rendered wrapper for each item                                          |
| ----------------------------------------------------- | ----------------------------------------------------------------------- |
| `itemWidth: "<n>px"`                                  | `SizedBox(width: n)` — **no `IntrinsicWidth`**                          |
| `minItemWidth` and/or `maxItemWidth` (no `itemWidth`) | `IntrinsicWidth` inside `ConstrainedBox(minWidth, maxWidth)`            |
| none of the above                                     | `IntrinsicWidth(child)` (shrinks to content so items flow side-by-side) |

`itemFit`:

- `"Fit"` (default) → current content-fit behavior (each item takes its natural width,
  clamped by the wrapper above).
- `"Fill"` → **not implemented**; logged once via `dart:developer` `log` and treated as
  `"Fit"`. Documented as the one remaining Flow gap.

`px` parsing accepts the spec `"<number>px"` string form as well as a bare number
(matches the lenient parsing already used for `minItemWidth`/`maxItemWidth`).

### `Layout.Flow` on `Column` and `TableCell`

- `Column` and `TableCell` may carry a `layouts` array, selected by the current width
  bucket exactly as `Container`/root do (`selectLayout` + the `cardWidthBucketProvider`).
- When the selected layout is `Layout.Flow`, items render via `AdaptiveFlowLayout`;
  otherwise they keep their **current** rendering:
  - `Column` → today's `Column` (stack).
  - `TableCell` → today's `Wrap`. (The cell's existing default is intentionally
    preserved to avoid golden churn; Flow is only applied when explicitly selected.)
- `targetWidth`-hidden items are absent from the flow; remaining items wrap with no
  leftover gaps (unchanged from the existing Flow behavior).

### `selectLayout` specificity (W3)

Among **relational** (`atLeast:` / `atMost:`) matches for the current bucket, choose the
**most specific** one — the relational whose covered width range is **narrowest** (covers
the fewest buckets). Bucket order: `veryNarrow < narrow < standard < wide`; `atLeast:b`
covers `b`…`wide`, `atMost:b` covers `veryNarrow`…`b`.

- Example: at bucket `wide`, `[{atLeast:narrow}, {atLeast:standard}]` → `atLeast:standard`
  (covers 2 buckets) wins over `atLeast:narrow` (covers 3). Previously the first in array
  order (`atLeast:narrow`) won — contradicting the "prefer most specific" rule and
  risking parity drift from other SDKs.
- Precedence overall: exact-bucket `targetWidth` > most-specific relational match >
  layout with no `targetWidth` (applies to all widths) > none (→ `Layout.Stack`).
- Ties between two relational entries with equal-size ranges keep array order (stable).

### Unbounded-width guard (W4, partial)

When the root `LayoutBuilder` measures `constraints.maxWidth == double.infinity`
(horizontal scroll, unconstrained `Row`, etc.), log once via `dart:developer` and resolve
to `WidthBucket.wide` (today's silent fallback made explicit and debuggable). The
remaining W4 items (margin-inclusive measurement, nested show-card semantics) stay
deferred.

## Architecture — shared flow helper

`Container` and the root body each carry an inline `selectLayout` + Flow-vs-stack branch.
Adding `Column` and `TableCell` would make four copies. Extract one helper and route all
four sites through it.

| Piece                                               | Location                                                                    | Role                                                                                                                     |
| --------------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `buildLayoutChildren(...)`                          | `lib/src/responsive/layout_children.dart` (new)                             | Calls `selectLayout`; returns `AdaptiveFlowLayout` for `Layout.Flow`, else delegates to a caller-supplied `stackBuilder` |
| `AdaptiveFlowLayout` sizing + `itemFit`/`itemWidth` | `lib/src/responsive/adaptive_flow_layout.dart`                              | W1 fix + new sizing/`itemFit` parsing                                                                                    |
| `selectLayout` specificity                          | `lib/src/responsive/layout_selection.dart`                                  | W3 nearest-relational tiebreak                                                                                           |
| Root width guard                                    | `lib/src/cards/adaptive_card_element.dart` (root `LayoutBuilder`)           | Unbounded-width log + `wide`                                                                                             |
| Container / root / Column / TableCell wiring        | `container.dart`, `adaptive_card_element.dart`, `column.dart`, `table.dart` | Replace inline branches / add new wiring via `buildLayoutChildren`                                                       |

```dart
// lib/src/responsive/layout_children.dart (new)
/// Chooses the container's layout for [bucket] and builds its children:
/// `Layout.Flow` → [AdaptiveFlowLayout]; otherwise [stackBuilder] (the caller's
/// own Column/Wrap), so non-Flow rendering is byte-for-byte unchanged.
Widget buildLayoutChildren({
  required List<dynamic>? layouts,
  required WidthBucket bucket,
  required ReferenceResolver styleResolver,
  required List<Widget> children,
  required Widget Function(List<Widget> children) stackBuilder,
}) {
  final selected = selectLayout(layouts, bucket);
  if (selected != null && selected['type'] == 'Layout.Flow') {
    return AdaptiveFlowLayout(
      layoutMap: selected,
      styleResolver: styleResolver,
      children: children,
    );
  }
  return stackBuilder(children);
}
```

Each call site reads `ref.watch(cardWidthBucketProvider)` (already available in these
`Consumer`/`ConsumerState` widgets) and passes its existing stack widget as
`stackBuilder`, so behavior is identical when no Flow layout is selected.

**Why this approach:** consistent with the established `selectLayout` +
`AdaptiveFlowLayout` + `cardWidthBucketProvider` idioms; one code path replaces four
divergent copies (less drift); the logic-heavy bits (`selectLayout`, item sizing) stay
pure/cheaply unit-testable. (Rejected: leaving the branch inline and copy-pasting into
`Column`/`TableCell` — duplication the June-18 review already flagged as a maintenance
risk as the Flow surface grows.)

### Data flow (unchanged from June-18, now reaching more containers)

```
root LayoutBuilder.constraints.maxWidth  (∞ → log + wide)
   → ReferenceResolver.resolveWidthBucket(width)
   → override cardWidthBucketProvider for the subtree
   → Container / root / Column / TableCell:
        buildLayoutChildren(layouts, bucket, …)
          → selectLayout (exact > nearest relational > default)
          → Layout.Stack (caller's Column/Wrap) | AdaptiveFlowLayout (Wrap)
                → per-item: SizedBox(itemWidth) | IntrinsicWidth+ConstrainedBox(min/max) | IntrinsicWidth
```

## Error handling / edge cases

- **`itemFit: "Fill"`** → log once, render as `"Fit"`.
- **`itemWidth` + `min`/`maxItemWidth` together** (spec-invalid) → `itemWidth` wins;
  log once.
- **Malformed sizing values** (non-numeric, bad `px`) → treated as absent (lenient,
  matches existing parsing).
- **Unknown layout `type`** → ignored in selection; falls through to stack
  (unchanged).
- **Unbounded card width** → log once + `wide`.
- **`TableCell` default** → unchanged `Wrap` when no Flow layout selected (no golden
  churn).
- **Resize across a breakpoint** → reactive rebuild via `cardWidthBucketProvider`
  (unchanged).

## Testing

- **Pure unit** (`test/responsive/`):
  - `selectLayout` W3: most-specific relational wins (`atLeast:standard` covers 2 vs
    `atLeast:narrow` 3 at `wide`); `atMost:` symmetry; exact > relational; equal-specificity
    keeps array order; no-match → stack.
  - `AdaptiveFlowLayout` sizing: `itemWidth` → fixed-width `SizedBox` (no `IntrinsicWidth`);
    `min`/`max` → `IntrinsicWidth` inside `ConstrainedBox`; no-sizing → `IntrinsicWidth`;
    `itemFit: "Fill"` parses and falls back without throwing.
- **Widget** (`test/responsive/`):
  - `Column` with `Layout.Flow` wraps (uses `AdaptiveFlowLayout`) when wide and stacks
    when narrow; a non-Flow `Column` renders unchanged (no `AdaptiveFlowLayout`).
  - `TableCell` with `Layout.Flow` uses `AdaptiveFlowLayout` when wide; a non-Flow cell
    keeps its `Wrap` rendering.
  - **W1**: a content-fit Flow of `TextBlock`s flows side-by-side (does not stack); a
    non-intrinsic item (nested `Wrap`) given an `itemWidth` renders without throwing
    "does not support returning intrinsic dimensions".
  - `setVisibility`/`targetWidth` interaction unchanged.
- **Golden** (tagged `golden`): one narrow + one wide snapshot of `flow_column.json`
  (a `Column` with `Layout.Flow` + `itemWidth`), mirroring the existing
  `golden_responsive_flow_test.dart` pattern.
- **Verification**: `fvm flutter analyze` clean; `fvm flutter test --exclude-tags=golden`
  green in `flutter_adaptive_cards_fs`. Regenerate goldens on the golden platform.

## Sample card + widgetbook sync

The flow sample card is the single source of truth shared by tests and the demo, copied
across the two packages (the established pattern — `flutter_adaptive_cards_fs` test assets
and `widgetbook` lib assets cannot share a file).

- **New sample**: `flow_column.json` — a `Column` carrying `Layout.Flow` with `itemWidth`
  (and a `targetWidth` so it reflows). Placed at
  `packages/flutter_adaptive_cards_fs/test/samples/responsive/flow_column.json`
  (consumed by the new golden + widget tests).
- **Widgetbook copy**: identical file at
  `widgetbook/lib/samples/responsive/flow_column.json`. The two copies **must be kept
  identical**.
- **`ResponsiveFlowPage`** (`widgetbook/lib/responsive_flow_page.dart`): replace the
  hardcoded `_assetPath` with a sample-picker knob (`context.knobs.list`) listing the
  responsive samples (`flow_container.json`, `flow_root.json`, `flow_column.json`),
  keeping the existing width slider. New responsive samples then drop in without new
  pages. Tagged **Example (widgetbook sample)** per `AGENTS.md`.

## Documentation impact

- **`packages/flutter_adaptive_cards_fs/README.md`** (Implementation status): `layouts`
  / `Layout.Flow` row → Container + root **and Column + TableCell** ✅; note `itemWidth`
  - `itemFit: Fit` shipped, `itemFit: Fill` deferred; **`ColumnSet` marked
    not-applicable (spec has no `layouts` on ColumnSet)**.
- **`docs/Implementation-Status.md`** (roadmap/Known gaps): correct the "Flow on
  ColumnSet/Column/TableCell" wording → "Flow on Column/TableCell shipped; ColumnSet not
  in spec; `itemFit: Fill` + `AreaGrid` deferred".
- **`docs/superpowers/specs/2026-06-18-responsive-layout-targetwidth-flow-design.md`**:
  mark **W3 resolved**; for **W1**, record that its "remove `IntrinsicWidth`" remediation
  was **rejected** (the premise was wrong — `Wrap` does not content-size elements that use
  an expanding `Align`); `IntrinsicWidth` is kept for content-fit and skipped only for
  `itemWidth`. Note `Column`/`TableCell` Flow shipped and the ColumnSet correction.
- **`flutter_adaptive_cards_fs/CHANGELOG.md`**: `## [Unreleased]` bullet.
- Architecture-doc sync gate: no new providers/scopes or HostConfig sections are added
  (the new helper is a pure builder), so no `docs/reactive-riverpod.md` /
  `Architecture-Overview.md` changes are required — confirm during review.

## Open items to confirm during planning

- Exact `flow_column.json` content (item count, `itemWidth` value, `targetWidth`) so the
  narrow/wide goldens clearly show the stack↔wrap reflow.
- Whether `TableCell` reads `layouts` from the cell JSON via the existing
  `TableCellModel` or directly from the cell map in `buildCellContent` (pick whichever
  keeps `table.dart` cohesive).
- Whether the `ResponsiveFlowPage` sample-picker should also expose `itemFit` /
  `itemWidth` as knobs, or keep those fixed in the sample JSON (lean: fixed in JSON).
