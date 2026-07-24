# Block `height: "stretch"` (design)

**Date:** 2026-06-28
**Status:** Approved (brainstorming) — pending implementation plan
**Package:** `flutter_adaptive_cards_fs`
**Spec basis:** Adaptive Cards `BlockElementHeight` (`auto` | `stretch`), v1.1+
**Related:** companion to [`Layout.AreaGrid` design](./2026-06-28-layout-areagrid-design.md) (AreaGrid cells consume this) and the shipped [responsive `Layout.Flow`](./2026-06-27-finish-layout-flow-design.md). Implemented together via one combined plan.

## Summary

`height` is a common block property: `auto` (size to content, the default) or
`stretch` (fill available space along the parent's main axis). Today only `Image`
reads a height; **`stretch` is unimplemented** everywhere else. This design adds a
general, predictable `height: "stretch"` for the core containers.

The hard truth about Flutter: `stretch` can only mean something when the container
has **slack** to distribute. A content-sized `Column` in a scrollable card has no
extra vertical space, and `Expanded` inside an unbounded `Column` throws. So this
design makes `stretch` real **only in bounded contexts** and **degrades it to
`auto` when unbounded** — which is exactly how other Adaptive Cards renderers
behave (they stretch within bounded regions only).

## Goals / non-goals

**Goals**

- A block element with `height: "stretch"` fills the available main-axis space when
  its container is height-bounded; multiple stretch siblings divide the slack equally.
- Provide a single reusable helper so `Container`, `Column`, and the card root body
  share one stretch implementation, and expose an `isStretchHeight` predicate that
  `Layout.AreaGrid` reuses for in-cell stretch.
- **Zero behavior change** for cards that do not set `height: "stretch"`.

**Non-goals**

- Stretch in **unbounded** vertical contexts (content-sized card body, scroll views):
  explicitly degrades to `auto` (documented limitation).
- Chart elements (`flutter_adaptive_charts_fs`) — deferred.
- `TableCell` _content_ stretch — cells already stretch to the row height via the
  existing `IntrinsicHeight` + `CrossAxisAlignment.stretch`; a stretch child _inside_
  a cell's `Wrap` is out of scope (noted as a limitation).
- `width` stretch (a separate concern; ColumnSet/Column width modes already exist).

## Behavior / contract

- **Bounded context (finite `maxHeight`)** — AreaGrid cells, `ColumnSet` columns
  (inside `IntrinsicHeight`), and any container nested in a stretched/bounded
  ancestor: a `height: "stretch"` child expands to fill the remaining main-axis
  space. Multiple stretch children share it equally (`Expanded(flex: 1)` each);
  non-stretch children keep their natural size.
- **Unbounded context (infinite `maxHeight`)** — the typical content-sized card
  body and scroll views: `stretch` has nothing to fill and renders as `auto`. A
  standalone `Container` with only `minHeight` under an unbounded parent stays
  content-sized (its `minHeight` is still honored; the child just isn't expanded).
- **Default / absent / unknown `height`** → `auto` (current behavior, unchanged).

## Architecture

| Piece                                        | Location                                                      | Role                                                                                                                                                                                                                                                               |
| -------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `isStretchHeight(Map)` + `BlockHeight` parse | `lib/src/utils/block_height.dart` (new)                       | **Pure** predicate: is an element's resolved `height` == `"stretch"`? (case-insensitive; tolerant of absent/garbage → `false`). Reused by AreaGrid.                                                                                                                |
| `buildStretchableColumn(...)`                | `lib/src/cards/stretchable_column.dart` (new)                 | Wraps the children in a `LayoutBuilder`; when `constraints.maxHeight.isFinite` **and** at least one child is stretch, returns a `Column` with stretch children wrapped in `Expanded` and the others as-is; otherwise a plain `Column` with the caller's alignment. |
| Container / Column / root stack sites        | `container.dart`, `column.dart`, `adaptive_card_element.dart` | Their `buildLayoutChildren` `stackBuilder` calls `buildStretchableColumn(childMaps, children, …)` instead of a raw `Column`.                                                                                                                                       |

`buildStretchableColumn` signature (illustrative):

```dart
Widget buildStretchableColumn({
  required List<Map<String, dynamic>> childMaps, // index-aligned with children
  required List<Widget> children,
  required MainAxisAlignment mainAxisAlignment,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  MainAxisSize mainAxisSize = MainAxisSize.max,
});
```

The `childMaps` (raw item JSON, index-aligned with the built `children`) are the
same list `Layout.AreaGrid` needs, so the container build sites thread one parallel
list that serves both features.

### Data flow

```
container stack site (Container/Column/root)
   → buildLayoutChildren(..., childMaps, stackBuilder)
       stackBuilder(children) = buildStretchableColumn(childMaps, children, …)
           → LayoutBuilder: maxHeight finite?
                yes + has stretch child → Column with Expanded(stretch) | child(others)
                no                      → plain Column (stretch == auto)
```

## Error handling / edge cases

- **All children stretch, bounded height** → they divide the space equally.
- **Stretch child, unbounded height** → rendered as `auto`; never wraps `Expanded`
  in an unbounded `Column` (the `maxHeight.isFinite` guard prevents the throw).
- **`minHeight` + unbounded parent** → `minHeight` still applied by the container;
  child not expanded (documented).
- **Malformed `height`** → treated as `auto`.

## Testing

- **Pure unit** (`test/utils/block_height_test.dart`): `isStretchHeight` for
  `"stretch"`, `"Stretch"`, `"auto"`, absent, and non-string values.
- **Widget** (`test/.../stretchable_column_test.dart`): in a bounded box, a single
  stretch child fills height and two stretch children split it; in an unbounded box,
  a stretch child stays content-sized and **no** `Expanded` is in the tree (no throw).
- **Widget (integration):** a `Container` with `minHeight` inside a bounded parent
  stretches a child to the min height; a `ColumnSet` with a `stretch` child in one
  column fills the equal-height row band.
- **Verification:** `fvm flutter analyze` clean; `fvm flutter test
--exclude-tags=golden` green in `flutter_adaptive_cards_fs`.

## Documentation impact

- README **Common properties** `height` row → `auto` ✅ and `stretch` ✅ (bounded
  contexts; degrades to `auto` when unbounded); note charts + in-cell `TableCell`
  content deferred.
- `docs/Implementation-Status.md`: move **Block `height: stretch`** out of the
  high-priority list into Recently completed (shared entry with AreaGrid).
- `flutter_adaptive_cards_fs/CHANGELOG.md`: `## [0.13.0]` Added bullet.
