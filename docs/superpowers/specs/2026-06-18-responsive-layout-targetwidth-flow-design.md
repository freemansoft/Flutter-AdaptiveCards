# Responsive layout — `targetWidth` + `Layout.Flow` (design)

**Date:** 2026-06-18
**Status:** Approved (brainstorming) — pending implementation plan
**Package:** `flutter_adaptive_cards_fs`
**Spec basis:** Adaptive Cards v1.6 responsive layout ([documentation hub](https://adaptivecards.microsoft.com/))

## Summary

Adaptive Cards v1.6 lets a card adapt to the width it is rendered at. This design
implements the first, highest-value slice of that capability:

1. **`targetWidth`** — a width-bucket-conditional visibility property on **every**
   element (`veryNarrow` / `narrow` / `standard` / `wide`, plus relational
   `atLeast:` / `atMost:` forms).
2. **`Layout.Flow`** — a per-width container layout that wraps items side-by-side
   instead of stacking them, on **`Container`** and the **card root body**.

Both are built on shared **width-bucket foundation** infrastructure: a single
`LayoutBuilder` near the card root publishes the current width bucket as a scoped
Riverpod provider that elements and layouts read.

### Explicitly out of scope (deferred to follow-up specs)

- **`Layout.AreaGrid` + `grid.area`** — named-area grid placement. Heaviest piece;
  reshapes container rendering. Separate spec.
- **`Layout.Flow` advanced properties** — `itemFit` (fit/fill), `minItemWidth`,
  `maxItemWidth`. Items take natural size in this pass.
- **`layouts` on `ColumnSet` / `Column` / `TableCell`** — these keep their current
  rendering. Only `Container` and the root body gain `layouts`.

These deferrals keep the implementation plan tight and reviewable. `AreaGrid` is
the single most complex part of v1.6 responsive layout and warrants its own design.

## Goals / non-goals

**Goals**
- Authors can show/hide any element by card width via `targetWidth`.
- Authors can make a `Container` (or root body) reflow from a vertical stack to a
  wrapping layout at chosen widths via `Layout.Flow`.
- Hosts can tune the width breakpoints via HostConfig; spec defaults apply otherwise.
- **Zero behavior change for existing cards** — the feature is purely additive.

**Non-goals**
- `AreaGrid`, advanced Flow sizing, and non-`Container` `layouts` hosts (deferred).
- Changing how width is measured for any purpose other than responsive layout.

## Behavior

### `targetWidth` (all elements)

- Per the AC spec, `targetWidth` is evaluated against the **whole card's** rendered
  width — not the width of the element's immediate container.
- Supported forms:
  - Bare bucket: `"veryNarrow"`, `"narrow"`, `"standard"`, `"wide"` — matches only
    that bucket.
  - Relational: `"atLeast:<bucket>"`, `"atMost:<bucket>"` — matches that bucket and
    all wider / narrower buckets respectively.
- **Effective visibility = `isVisible` AND `matchesTargetWidth`.** These are
  independent gates. A runtime visibility overlay (`setVisibility(true)`) does **not**
  override a `targetWidth` miss, and vice-versa.
- **Absent `targetWidth`** → always matches (no change for existing cards).
- **Malformed / unknown `targetWidth`** (typo, bad case, unknown token) → **fail-open**
  (treated as "always matches") and logged via `dart:developer` `log`. Rationale: a
  typo must never make content silently vanish; the worst case is an element showing
  when it should not, which is debuggable.

### `Layout.Flow` (Container + card root body)

- A `Container` (and the root `AdaptiveCard` body) may carry a `layouts` array. Each
  entry is a layout object with a `targetWidth` and a layout `type`.
- **Layout selection** for the current bucket:
  - Choose the layout whose `targetWidth` matches the current bucket; if several
    match, prefer the most specific (exact bucket over relational).
  - If none match (or `layouts` is absent), fall back to the implicit
    **`Layout.Stack`** — i.e. today's vertical-stack rendering.
- **`Layout.Stack`** — current behavior; the always-available default.
- **`Layout.Flow`** — items wrap like inline content: as many side-by-side as fit,
  then a new row. Backed by a Flutter `Wrap`. Supported properties this pass:
  - `columnSpacing` / `rowSpacing` — gaps between items (resolved through HostConfig
    spacing tokens, consistent with existing spacing handling).
  - `horizontalItemsAlignment` — `left` / `center` / `right` (`Wrap.alignment`).
  - `verticalItemsAlignment` — `top` / `center` / `bottom` (`Wrap.crossAxisAlignment`).
- **Interaction with `targetWidth`**: items hidden by `targetWidth` are simply absent
  from the flow; remaining items wrap normally with no leftover gaps.

### Width buckets

- Default breakpoints (overridable via HostConfig `hostWidthBreakpoints`):
  - `veryNarrow`: width `< 165px`
  - `narrow`: `165px ≤ width < 350px`
  - `standard`: `350px ≤ width < 768px`
  - `wide`: `≥ 768px`
- These mirror Microsoft's documented defaults. Exact values to be confirmed against
  the host-config schema during implementation; if the published defaults differ, the
  schema wins and this doc is updated.
- **Resize behavior**: when the card is resized across a boundary, the root
  `LayoutBuilder` recomputes the bucket, the provider value changes, and only widgets
  that `ref.watch` it rebuild — the same reactive path `isVisible` already uses.

## Architecture (Approach 1: width-bucket provider + mixin gate)

All changes in `packages/flutter_adaptive_cards_fs`.

| Piece | Location | Role |
| --- | --- | --- |
| `WidthBucket` enum + `targetWidthMatches()` | `lib/src/responsive/width_bucket.dart` (new) | Bucket enum; **pure** matcher for bare + `atLeast:` / `atMost:` forms (fail-open) |
| `selectLayout(layouts, bucket)` | `lib/src/responsive/layout_selection.dart` (new) | **Pure**: pick best `Layout.*` for a bucket; default `Layout.Stack` |
| `AdaptiveFlowLayout` | `lib/src/responsive/adaptive_flow_layout.dart` (new) | `Wrap`-based renderer for `Layout.Flow` (spacing + alignment) |
| `HostWidthsConfig` | `lib/src/hostconfig/host_widths_config.dart` (new) | Parses `hostWidthBreakpoints`; spec defaults when absent |
| `ReferenceResolver.resolveWidthBucket(double)` | `lib/src/reference_resolver.dart` | Maps pixel width → `WidthBucket` using the config |
| `cardWidthBucketProvider` | `lib/src/riverpod/providers.dart` | Scoped `Provider<WidthBucket>`, overridden by the root `LayoutBuilder` |
| `AdaptiveResponsiveMixin` | `lib/src/adaptive_mixins.dart` | `ref.watch`es the bucket; exposes `matchesTargetWidth` |
| Root body `LayoutBuilder` | `lib/src/cards/adaptive_card_element.dart` (and/or `flutter_raw_adaptive_card.dart`) | Sole width measurement; overrides the bucket provider for the subtree; selects root-body layout |
| Container layout selection | `lib/src/cards/containers/container.dart` | Calls `selectLayout`; renders stack or `AdaptiveFlowLayout` |

**Why Approach 1:** consistent with the established Riverpod + mixin + HostConfig
idioms; `targetWidth` rides the same reactive path as `isVisible`; the two
logic-heavy bits (`width_bucket.dart`, `layout_selection.dart`) are pure and unit
-testable without pumping widgets. (Rejected: a registry-level wrapper around every
element — touches the hot build path for all elements and fights `const`; and
per-container `LayoutBuilder` — semantically wrong since `targetWidth` is relative
to the **card** width.)

### Data flow

```
card render width (root LayoutBuilder.constraints.maxWidth)
   → ReferenceResolver.resolveWidthBucket(width)         [uses HostWidthsConfig]
   → override cardWidthBucketProvider for the subtree
   → elements: AdaptiveResponsiveMixin.ref.watch(bucket) → matchesTargetWidth
        → effective visibility = isVisible && matchesTargetWidth
   → Container / root body: selectLayout(layouts, bucket)
        → Layout.Stack (today's Column) | AdaptiveFlowLayout (Wrap)
```

## Error handling / edge cases

- **Malformed `targetWidth`** → fail-open + `dart:developer` log (see Behavior).
- **Unknown layout `type`** in `layouts` → ignored during selection; falls through to
  `Layout.Stack`.
- **Empty / absent `layouts`** → `Layout.Stack` (current behavior).
- **All items hidden by `targetWidth`** → empty stack/flow renders nothing extra; no
  spurious separators or gaps.
- **Resize across boundary** → reactive rebuild via provider; no manual invalidation.

## Testing

- **Pure unit tests** (`test/responsive/`):
  - width → bucket mapping at and around each default boundary, and with a custom
    HostConfig override.
  - `targetWidthMatches`: every bare bucket, `atLeast:`/`atMost:` across all buckets,
    absent value, and the fail-open malformed case.
  - `selectLayout`: exact match wins over relational; no-match → `Layout.Stack`;
    unknown type ignored.
- **Widget tests**: pump a card at a narrow and a wide width; assert (a) a
  `targetWidth` element shows/hides, (b) a `Layout.Flow` container stacks vs. wraps,
  (c) a `setVisibility(true)` overlay does not override a `targetWidth` miss.
- **Golden tests** (tagged `golden`): one narrow + one wide snapshot of a Flow card
  to lock the visual reflow (mirrors the charts / text-features verification pattern).
- **Verification**: `fvm flutter analyze` clean; `fvm flutter test
  --exclude-tags=golden` green in `flutter_adaptive_cards_fs`.

## Documentation impact

- `docs/Implementation-Status.md`: move `targetWidth` and `Layout.Flow` from
  ❌ Missing to ✅ / ⚠️; note `AreaGrid` + advanced Flow still deferred.
- New short authoring section (where `targetWidth` / `Layout.Flow` live, examples).
- `flutter_adaptive_cards_fs/CHANGELOG.md`: `## [Unreleased]` bullet.

## Open items to confirm during planning

- Exact default breakpoint pixel values vs. the published host-config schema (schema
  wins).
- Whether the root-body `LayoutBuilder` lives in `adaptive_card_element.dart` or
  `flutter_raw_adaptive_card.dart` (whichever owns the outermost body constraints).
