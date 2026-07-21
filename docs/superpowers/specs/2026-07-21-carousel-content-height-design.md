# Carousel content-sized height — design

- **Date:** 2026-07-21
- **Package:** `flutter_adaptive_cards_fs`
- **Element:** `Carousel` / `CarouselPage`
- **Status:** approved (brainstorming), pending implementation plan

## Problem

`AdaptiveCarousel.build` wraps its `PageView` in a hardcoded
`SizedBox(height: 400)` (`packages/flutter_adaptive_cards_fs/lib/src/cards/elements/carousel.dart`).
The value is arbitrary — the inline comment flags it as temporary — and it exists
only because Flutter's `PageView` requires a bounded cross-axis constraint and
cannot size itself to its children. As a result every carousel renders 400px tall
regardless of page content: short pages have large empty gaps and tall pages clip.

The goal is for the carousel to size its height to the carousel pages instead of a
fixed constant, while honoring the height model the Adaptive Cards spec actually
defines for this element.

## Spec findings (ground truth)

Verified against the v1.6 sample JSON and the **shared C++ object model**
(`source/shared/cpp/ObjectModel/Carousel.cpp`) — the model Android, iOS, UWP, and
.NET all compile against — with the JavaScript SDK
(`source/nodejs/adaptivecards/src/carousel.ts`) consulted only as this repo's
designated tiebreaker for disputed *semantics*. The height model lives on the
**Carousel** element; **CarouselPage has no height property** (there is no
`minHeight` anywhere in the Carousel/CarouselPage schema — the originally-suspected
`carouselPage minHeight` does not exist).

| JSON property | Meaning |
| --- | --- |
| `heightInPixels` (e.g. `"100px"`) | Explicit fixed pixel height for the page container. |
| `height: "stretch"` | Standard block-element stretch — container fills its parent. |
| `height: "auto"` / absent | Default. Size the carousel to the pages (see decision 1). |
| `orientation: "vertical"` | Vertical paging. **Independent of `heightInPixels`** — see the "JS reference vs. portable spec" note below. |

### JS reference vs. portable spec (why we do not follow JS here)

`carousel.ts` couples orientation to height: `validateOrientationProperties`
forces horizontal unless `heightInPixels` is set. **This coupling does not exist in
the shared C++ model** — `Carousel.cpp` parses `orientation` and `heightInPixels`
independently. The gate is a JavaScript-renderer quirk: Swiper.js cannot do
vertical paging without a fixed CSS height. It is not a spec rule, so this design
**does not** adopt it. Orientation is treated as an independent property. (A
vertical Flutter `PageView` still needs *some* bounded height, but our
measured-max height already provides that — no author-supplied `heightInPixels`
required.)

Likewise, the JS SDK's `auto` behavior (Swiper `autoHeight` + `ResizeObserver`
sizing to the **active** page, animated) is a portability reference only; decision
1 intentionally diverges from it.

Also confirmed from the `Carousel.ForbiddenElements` / `Carousel.ForbiddenActions`
samples: **inputs (`Input.*`) and `Media` are forbidden inside CarouselPages**, and
interactive actions (`Action.ShowCard`, `Action.ToggleVisibility`) are not honored
there. Carousel page content is therefore effectively static display content
(TextBlock, Image, Container, ColumnSet, RichTextBlock, …). This makes it safe to
**build a page twice** — once invisibly to measure it, once to display it — with no
risk of double-registering input/document state.

## Decisions

1. **`auto` semantics: tallest page (max), not active-page.** For the default
   `auto` case the carousel height is the **maximum** measured page height; every
   page is laid out at that height. This deviates from the JS SDK's active-page
   `autoHeight` (height follows the current page and animates on swipe) in favor of
   a stable height that never jumps between pages and never clips. Chosen
   deliberately for visual stability and deterministic testability.
2. **Full height model in scope.** Parse and honor `height` (`auto` / `stretch`)
   and `heightInPixels` — not just the `auto` case.
3. **Orientation is independent of height.** Per the shared C++ model, `vertical`
   is honored on its own; we do **not** import the JS `heightInPixels` gate. A
   vertical carousel derives its bounded height from the same resolution order as
   horizontal (measured max, or `heightInPixels` when set).

## Design

### Height parsing (in `initState`)

- `heightInPixels`: parse a `"<n>px"` string (tolerate a bare number) to a
  `double? heightInPixels`.
- `height`: read `"auto"` (default) vs `"stretch"` into an enum/flag.
- Orientation: set `scrollAxis = Axis.vertical` when `orientation == "vertical"`,
  else `Axis.horizontal` — **independent of `heightInPixels`** (matches today's
  behavior; the vertical PageView's required bounded height comes from
  `effectiveHeight`, not from an author-supplied pixel value).

### Measuring the tallest page

`PageView` forces every child to the viewport height, so natural page heights
cannot be measured *inside* it. A hidden measurement layer sits above the
`PageView` inside the existing `Column`:

```
LayoutBuilder (viewport width w)
└─ Column(mainAxisSize: min)
   ├─ Offstage(offstage: true)                 // laid out, never painted, ~0 visible height
   │   └─ Column[
   │        for each page:
   │          SizedBox(width: w,               // same width the PageView will use → identical wrapping
   │            child: _MeasureSize(onChange:   // reports laid-out Size
   │              child: <page widget>))
   │      ]
   ├─ SizedBox(height: effectiveHeight,        // effectiveHeight = max of measured page heights
   │     child: PageView.builder(...))         // unchanged interaction + slide animation
   └─ <controls, unchanged>
```

- `_MeasureSize`: a small private `SingleChildRenderObjectWidget` backed by a
  `RenderProxyBox` subclass. In `performLayout` it calls `super.performLayout()`,
  reads `child.size`, and when the size changed schedules the `onChange(size)`
  callback via `WidgetsBinding.instance.addPostFrameCallback` (never call
  `setState` during layout). Kept private to `carousel.dart` (single consumer;
  YAGNI on a shared util).
- The carousel state tracks measured heights (e.g. `Map<int, double>` keyed by page
  index) and recomputes `max` when any changes.
- **Width matters:** measurement pages are constrained to the `LayoutBuilder`
  width `w`. Without this, loose-width measurement would let text wrap differently
  than in the full-width `PageView`, producing wrong heights.
- **First frame:** before measurements arrive, `effectiveHeight` uses a fallback
  constant (keep `400`) so the first frame is not collapsed; the post-frame
  callback then triggers `setState` and the correct height on the next frame.
  `pumpAndSettle` resolves this in tests.
- `IndexedStack` (auto-sizes to the largest child, single build) was rejected: it
  provides no swipe gesture or slide animation, which the carousel requires.

### `effectiveHeight` resolution order

1. `heightInPixels != null` → the fixed pixel value.
2. `height == stretch` **and** the parent supplies bounded height
   (`LayoutBuilder` `constraints.maxHeight.isFinite`) → fill the available height.
3. otherwise (`auto`, or `stretch` under an unbounded/scrolling parent) → measured
   max page height.
4. before any measurement → fallback constant `400`.

## Spec-correctness fallout

Because we treat orientation as independent (decision 3), the existing
`carousel_behavior_test.dart` assertion that `orientation: "vertical"` alone yields
`Axis.vertical` **remains correct** and is kept. What changes: a vertical carousel
must now derive a bounded height from `effectiveHeight` (measured max) rather than
the hardcoded 400 — add a case asserting a vertical carousel with no
`heightInPixels` still renders (non-zero, content-derived height).

## Testing (TDD; run with `--exclude-tags=golden`)

- `heightInPixels: "100px"` → the `SizedBox` wrapping the `PageView` has
  `height == 100`.
- Two pages, one short and one tall → the carousel box height equals the taller
  page's natural height; order-independent (swapping the two pages yields the same
  height); the shorter page is not clipped.
- `height: "stretch"` inside a bounded-height parent fills that height; inside an
  unbounded (scrolling) parent falls back to the measured max.
- Orientation: `vertical` → `Axis.vertical` **regardless of `heightInPixels`**;
  a vertical carousel with no `heightInPixels` renders at a non-zero,
  content-derived (measured-max) height.

## Housekeeping / gates

- **No HostConfig change** — the spec defines no carousel height default in
  HostConfig, so there is nothing to add or flag as non-standard.
- Add a `## [Unreleased]` bullet to
  `packages/flutter_adaptive_cards_fs/CHANGELOG.md`.
- Docs-sync gate: this changes an element's public contract (Carousel now honors
  `height` / `heightInPixels`). Grep `docs/` and the package README
  implementation-status / known-gaps for carousel-height wording and update in the
  same change.
- Branch off the freshly-updated `main` before implementation; user reviews all
  changes before any commit.

## Out of scope

- Enforcing the forbidden-elements / forbidden-actions rules inside CarouselPage
  (a separate spec-compliance gap).
- Active-page animated `autoHeight` (JS SDK behavior) — superseded by the
  tallest-page decision above.
