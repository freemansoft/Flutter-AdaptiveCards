# Responsive layout — `targetWidth` + `Layout.Flow` (design)

**Date:** 2026-06-18
**Status:** ✅ Shipped (commit `533fd1a`, PR #36). Post-implementation follow-ups (W1–W5) below are resolved/rejected or tracked in [Implementation-Status → Low priority "Flow follow-ups"](../../Implementation-Status.md#low-priority); the delivering plan is archived at [`docs/archive/plans/2026-06-18-responsive-layout-targetwidth-flow.md`](../../archive/plans/2026-06-18-responsive-layout-targetwidth-flow.md).
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

---

## Post-implementation review — known weaknesses (added 2026-06-18)

The first slice shipped (commit `533fd1a`, PR #36). A review of the landed code
surfaced the following gaps. They are tracked as follow-up tasks in the
implementation plan (`docs/archive/plans/2026-06-18-responsive-layout-targetwidth-flow.md`,
section "Follow-up tasks: post-implementation review").

### W1 — `IntrinsicWidth` per flow item ⚠️ REVISITED (2026-06-27) — remediation rejected

> **Status: remediation rejected.** The proposed fix below ("remove `IntrinsicWidth`
> because `Wrap` already content-sizes children") rests on a **false premise**. Several
> elements wrap their content in an expanding `Align` (e.g. `TextBlock`,
> `lib/src/cards/elements/text_block.dart`), so inside a `Wrap` they stretch to the full
> row and stop flowing without `IntrinsicWidth`. The 2026-06-27 finish-Flow work therefore
> **keeps `IntrinsicWidth` for content-fit items** and skips it **only when `itemWidth` is
> set** (which uses a `SizedBox` — a perf win on that path and a safe escape for items that
> can't report an intrinsic width). The residual throw risk for a non-intrinsic item used
> *directly* as a content-fit flow child is documented in `AdaptiveFlowLayout`; authors
> give such items an `itemWidth`. See
> [2026-06-27 finish-Layout.Flow design](./2026-06-27-finish-layout-flow-design.md).

`AdaptiveFlowLayout` wraps every item in `IntrinsicWidth`
(`lib/src/responsive/adaptive_flow_layout.dart`). Two problems:

- **It can throw at runtime.** Not every widget supports intrinsic dimensions. A
  flow whose items contain an unbounded-size `Image`, a nested flex / `Expanded`,
  or certain custom render objects throws *"does not support returning intrinsic
  dimensions"*. Current tests only exercise `TextBlock` children, so this is
  unverified and will surface on real cards.
- **It is O(n) extra speculative layout passes**, re-run on every resize across a
  boundary.

`Wrap` already sizes children to content. The `IntrinsicWidth` wrapper should be
removed in the common case, and applied (guarded) only when `minItemWidth` /
`maxItemWidth` are actually present.

### W2 — Width-bucket reactivity ✅ RESOLVED (returned to Riverpod provider)

> **Status: implemented.** The interim `CardWidthScope` `InheritedWidget` was
> removed and the bucket is once again the scoped Riverpod `cardWidthBucketProvider`,
> using the two-scope / hoisted-`child` pattern below (option (b)). `isVisible`,
> `Container`, and the root body now all read the bucket via
> `ref.watch(cardWidthBucketProvider)`, so a single reactive mechanism drives both
> overlays and width. All `test/responsive/` widget tests and the Flow goldens pass
> unchanged (the swap is behavior-preserving). This design doc, the plan's
> architecture table, and `docs/Implementation-Status.md` are accurate again.

**Original problem.** An interim implementation published the bucket via an
`InheritedWidget` (`CardWidthScope`) and removed the provider, so `isVisible` mixed
two reactivity mechanisms (`ref.watch` for overlays + `CardWidthScope.of(context)`
for width) and the docs described a provider that did not exist.

**Why the provider was chosen (option (b) over blessing the InheritedWidget):**
`CLAUDE.md` guidance prefers Riverpod for reactive card state, and a provider
(unlike an `InheritedWidget`) can be read by *other providers / Notifiers* —
relevant if width-derived logic ever moves into a `Notifier` (e.g. width-dependent
validation or action `isEnabled`). The remediation below kept Riverpod **with a
single stable top-level `ProviderScope`** and without rebuilding it on every layout
pass.

#### How to stay on Riverpod with a stable, outer `ProviderScope`

The tension: the width only exists **inside** `LayoutBuilder`, but Riverpod has no
way to change a provider's value via `overrideWithValue` **without rebuilding a
`ProviderScope`** — and a provider's value also cannot be mutated *during* a build
phase (so writing the measured width into a `Notifier` from the `LayoutBuilder`
builder is disallowed; it would require a deferred `addPostFrameCallback` write that
costs an extra frame of lag on every boundary crossing).

The idiomatic resolution is **two scopes**: keep the heavy, stateful providers in
one stable outer `ProviderScope`, and publish the layout-derived bucket through a
**thin nested `ProviderScope` whose `child` is a hoisted, stable reference.**

```dart
// cardWidthBucketProvider stays a plain Provider with a fail-open default.
final cardWidthBucketProvider =
    Provider<WidthBucket>((ref) => WidthBucket.wide);

@override
Widget build(BuildContext context) {
  // ... build `result` as today ...

  // Hoist the entire card subtree into ONE stable widget instance, captured by
  // the closure below. This is the key: it is built once per `build()`, not once
  // per layout pass.
  final Widget cardBody = AdaptiveTappable(
    adaptiveMap: adaptiveMap,
    child: Form(key: formKey, child: result),
  );

  return ProviderScope(
    // OUTER, stable: document state, registries, element-state override.
    // Never rebuilt by layout — only by setState on this element.
    overrides: [
      adaptiveCardElementStateProvider.overrideWithValue(this),
    ],
    child: LayoutBuilder(
      builder: (context, constraints) {
        final bucket = ref
            .read(styleReferenceResolverProvider)
            .resolveWidthBucket(constraints.maxWidth);
        return ProviderScope(
          // INNER, cheap: only the width override. Recreated on each layout pass,
          // but that is a trivial widget allocation.
          overrides: [
            cardWidthBucketProvider.overrideWithValue(bucket),
          ],
          child: cardBody, // STABLE reference → subtree is NOT rebuilt.
        );
      },
    ),
  );
}
```

**Why this avoids rebuilding on every layout pass:**

1. **The subtree is preserved by element reuse.** Each layout pass creates a new
   inner `ProviderScope` *widget*, but it is passed the *same* `cardBody` instance.
   Flutter compares `ProviderScope.child` by identity, sees it unchanged, and does
   **not** rebuild `cardBody` or anything below it. Only a new (cheap) `ProviderScope`
   widget object is allocated; its `State` / `ProviderContainer` persist across passes
   because the `Element` is reused (same type + position).
2. **Riverpod only notifies on a real change.** `overrideWithValue` is backed by a
   value provider that notifies listeners **only when the value differs**. A layout
   pass that does not cross a breakpoint re-supplies the same `bucket` → no
   notification → zero dependent rebuilds. A pass that crosses a breakpoint notifies
   exactly the widgets that `ref.watch(cardWidthBucketProvider)` — the same reactive
   set the `InheritedWidget` rebuilds today.
3. **No deferred write, no frame lag.** Because the value travels through
   `overrideWithValue` (not a `Notifier` mutation), it is applied synchronously
   within the same frame — unlike the `addPostFrameCallback` approach a single
   mutable provider would force.

**Net cost per layout pass:** one `ProviderScope` widget allocation + one override
diff (a no-op unless the bucket changed). The expensive card subtree is never
rebuilt by layout. This matches the `InheritedWidget`'s performance while keeping the
bucket a first-class Riverpod value.

> Trade-off note (for the record): if the bucket never needs to be read outside
> the widget tree, an `InheritedWidget` would have been a legitimately simpler
> equal-performance choice. The provider was chosen anyway to keep one reactive
> mechanism and to leave the door open for non-widget (provider/`Notifier`)
> consumers of the bucket.

### W3 — `selectLayout` precedence among relational matches ✅ RESOLVED (2026-06-27, see finish-layout-flow plan)

> **Status: implemented.** `selectLayout` now prefers the **most specific** relational
> match — the one whose covered width range is narrowest (`relationalSpecificity` in
> `lib/src/responsive/width_bucket.dart`), with array order as a stable tiebreak. See
> [2026-06-27 finish-Layout.Flow design](./2026-06-27-finish-layout-flow-design.md).

`selectLayout` (`lib/src/responsive/layout_selection.dart`) takes the **first**
relational match in array order (`relationalMatch ??= layout`). For
`[{atLeast:narrow}, {atLeast:standard}]` at bucket `wide`, both match and it returns
`atLeast:narrow` — not the *most specific*, contradicting this design's "prefer the
most specific" rule and risking parity drift from other SDKs. Needs a real
specificity tiebreak (e.g. smallest bucket-distance to the current bucket), not
array order.

### W4 — Width measurement edge cases

The bucket derives from the root `LayoutBuilder`'s `constraints.maxWidth`:

- **Unbounded width → always `wide`.** In a horizontal scroll, an unconstrained
  `Row`, or any unbounded-width parent, `maxWidth == infinity` →
  `resolveBucket` returns `wide` silently. Needs an explicit guard/log.
- **Measured on the margin-inclusive outer width.** The `LayoutBuilder` sits outside
  the card's `Container(margin: EdgeInsets.all(8))` + container padding, so the bucket
  reflects ~16px more than the content actually receives; boundary cards can pick the
  wrong bucket.
- **Nested `Action.ShowCard` cards measure independently.** Each `AdaptiveCardElement`
  installs its own measurement, so a show-card's `targetWidth` is evaluated against
  the show-card width, not the host card. Spec says `targetWidth` is relative to "the
  whole card"; the nested-card semantics should be decided and documented.

### W5 — Scope / coverage gaps to keep visible

- **`itemFit` not honored, but `minItemWidth` / `maxItemWidth` *were* added** — this
  design listed all three as deferred, so the shipped scope quietly expanded. Align
  the `AdaptiveFlowLayout` doc and `Implementation-Status.md` with what actually ships.
- **No `layouts` on `ColumnSet` / `Column` / `TableCell`**, no `Layout.AreaGrid`
  (separate spec). ✅ **Update (2026-06-27):** `Layout.Flow` now supported on **`Column`**
  and **`TableCell`**; **`ColumnSet` is *not* in the spec** (it has no `layouts` property),
  so it is intentionally excluded. `Layout.AreaGrid` remains a separate spec.
- **`listView` body path skips `Layout.Flow` entirely** — documented, but a real hole.
