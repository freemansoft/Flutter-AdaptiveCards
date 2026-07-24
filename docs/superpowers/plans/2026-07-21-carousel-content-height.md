# Carousel Content-Sized Height Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the carousel's hardcoded `SizedBox(height: 400)` with the Adaptive Cards height model (`height` auto/stretch, `heightInPixels`) and, for the default `auto` case, size the carousel to its tallest page.

**Architecture:** A pure `resolveCarouselHeight` function decides the page-container height from the parsed properties, the parent constraints, and a measured tallest-page height. A transient off-stage measurement layer (an `Offstage` column of the pages, each wrapped in a `_MeasureSize` `RenderProxyBox`) reports natural page heights; once all pages are measured the layer is dropped and the visible `PageView` is sized to the max. `PageView` is retained for swipe + slide animation.

**Tech Stack:** Flutter (Material), `flutter_riverpod`, `package:flutter_test`, FVM-pinned SDK.

Design spec: `docs/superpowers/specs/2026-07-21-carousel-content-height-design.md`.

## Global Constraints

- Prefix every `flutter`/`dart` command with `fvm`.
- Analysis: `very_good_analysis` — `prefer_single_quotes`, `always_use_package_imports` (no relative imports in `lib/`), no `print`.
- Run tests with `--exclude-tags=golden`.
- Do **not** add HostConfig fields (none needed) and do **not** add new hardcoded user-visible strings to the package.
- Add a `## [Unreleased]` bullet to `packages/flutter_adaptive_cards_fs/CHANGELOG.md` for any `packages/flutter_adaptive_cards_fs/` change.
- Orientation is independent of `heightInPixels` (do not port the JS `validateOrientationProperties` gate).
- Work happens on branch `feat/carousel-content-height` (already created; spec already committed). All commands run from `packages/flutter_adaptive_cards_fs/` unless stated.

---

## File Structure

- `lib/src/cards/elements/carousel.dart` — MODIFY. Add `resolveCarouselHeight` (top-level), `_MeasureSize` + `_MeasureSizeRenderObject` (private), height-parsing fields, measurement state, and the new `build()` layout. This file already owns both `AdaptiveCarousel` and `AdaptiveCarouselPage`; no split needed.
- `test/elements/carousel_height_test.dart` — CREATE. Unit tests for `resolveCarouselHeight`; widget tests for `heightInPixels`, tallest-page sizing, content-sizing, and vertical-auto.
- `test/elements/carousel_behavior_test.dart` — MODIFY (only if the full run shows a regression; see Task 3).
- `CHANGELOG.md` — MODIFY. Unreleased bullet.
- Docs sync — grep `docs/` and `README.md` for carousel-height wording (Task 3).

---

### Task 1: Pure height-resolution function

**Files:**

- Modify: `lib/src/cards/elements/carousel.dart` (add one top-level function near the bottom of the file, after `AdaptiveCarouselPageState`).
- Test: `test/elements/carousel_height_test.dart` (create).

**Interfaces:**

- Produces: `double resolveCarouselHeight({required double? heightInPixels, required bool isStretch, required double maxAvailableHeight, required double? measuredMaxHeight, required double fallback})` — precedence: explicit `heightInPixels` → `stretch` with a finite parent height → measured tallest page → pre-measurement `fallback`.

- [ ] **Step 1: Write the failing test**

Create `test/elements/carousel_height_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/cards/elements/carousel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveCarouselHeight', () {
    test('explicit heightInPixels wins over everything else', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: 100,
          isStretch: true,
          maxAvailableHeight: 800,
          measuredMaxHeight: 250,
          fallback: 400,
        ),
        100,
      );
    });

    test('stretch fills a finite parent height', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: null,
          isStretch: true,
          maxAvailableHeight: 800,
          measuredMaxHeight: 250,
          fallback: 400,
        ),
        800,
      );
    });

    test('stretch under an unbounded parent falls back to measured max', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: null,
          isStretch: true,
          maxAvailableHeight: double.infinity,
          measuredMaxHeight: 250,
          fallback: 400,
        ),
        250,
      );
    });

    test('auto uses the measured tallest page when available', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: null,
          isStretch: false,
          maxAvailableHeight: 800,
          measuredMaxHeight: 250,
          fallback: 400,
        ),
        250,
      );
    });

    test('auto uses the fallback before any measurement', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: null,
          isStretch: false,
          maxAvailableHeight: 800,
          measuredMaxHeight: null,
          fallback: 400,
        ),
        400,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/elements/carousel_height_test.dart --exclude-tags=golden`
Expected: FAIL — `resolveCarouselHeight` is not defined (compile error).

- [ ] **Step 3: Write minimal implementation**

Add to the bottom of `lib/src/cards/elements/carousel.dart`:

```dart
/// Resolves the pixel height for the carousel's page container.
///
/// Precedence: an explicit `heightInPixels` wins; otherwise a `stretch` height
/// fills the parent when it supplies a finite height; otherwise the measured
/// tallest page is used; before any measurement the [fallback] applies.
double resolveCarouselHeight({
  required double? heightInPixels,
  required bool isStretch,
  required double maxAvailableHeight,
  required double? measuredMaxHeight,
  required double fallback,
}) {
  if (heightInPixels != null) return heightInPixels;
  if (isStretch && maxAvailableHeight.isFinite) return maxAvailableHeight;
  return measuredMaxHeight ?? fallback;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/elements/carousel_height_test.dart --exclude-tags=golden`
Expected: PASS (5 tests).

- [ ] **Step 5: Analyze**

Run: `fvm flutter analyze lib/src/cards/elements/carousel.dart test/elements/carousel_height_test.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/elements/carousel.dart \
        packages/flutter_adaptive_cards_fs/test/elements/carousel_height_test.dart
git commit -m "feat(carousel): add resolveCarouselHeight height-precedence helper"
```

---

### Task 2: Parse height model, measure pages, size the carousel

**Files:**

- Modify: `lib/src/cards/elements/carousel.dart` (fields + `initState` parsing; add `_MeasureSize`/`_MeasureSizeRenderObject`; rewrite `AdaptiveCarouselState.build`).
- Test: `test/elements/carousel_height_test.dart` (append widget tests).

**Interfaces:**

- Consumes: `resolveCarouselHeight(...)` from Task 1.
- Produces: carousel renders its `PageView` inside a `SizedBox` whose height is `resolveCarouselHeight(...)`; `heightInPixels` and `height` are parsed from the element JSON; orientation stays independent of `heightInPixels`.

- [ ] **Step 1: Write the failing widget tests**

Append to `test/elements/carousel_height_test.dart` (add the imports shown at the top of the new block):

```dart
// add these imports at the top of the file, alongside the existing ones:
// import 'package:flutter/material.dart';
// import '../utils/test_utils.dart';

Map<String, dynamic> _carouselCard({
  required List<Map<String, dynamic>> pages,
  String? heightProp,
  String? heightInPixels,
  String? orientation,
}) => <String, dynamic>{
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'Carousel',
      'id': 'car1',
      'height': ?heightProp,
      'heightInPixels': ?heightInPixels,
      'orientation': ?orientation,
      'pages': pages,
    },
  ],
};

Map<String, dynamic> _page(String id, int lines) => <String, dynamic>{
  'type': 'CarouselPage',
  'id': id,
  'items': <Map<String, dynamic>>[
    for (int i = 0; i < lines; i++)
      <String, dynamic>{'type': 'TextBlock', 'text': 'line $i of $id'},
  ],
};

double _carouselHeight(WidgetTester tester) =>
    tester.getSize(find.byType(PageView)).height;

void main() {
  // ... keep the existing resolveCarouselHeight group above ...

  group('carousel widget height', () {
    testWidgets('heightInPixels sets an exact fixed height', (tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: _carouselCard(
            heightInPixels: '100px',
            pages: <Map<String, dynamic>>[_page('a', 1), _page('b', 8)],
          ),
          title: 'fixed px',
        ),
      );
      await tester.pumpAndSettle();

      expect(_carouselHeight(tester), 100);
    });

    testWidgets('auto height equals the tallest page and is order-independent',
        (tester) async {
      final short = _page('short', 1);
      final tall = _page('tall', 8);

      Future<double> heightFor(List<Map<String, dynamic>> pages) async {
        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: _carouselCard(pages: pages),
            title: 'auto',
          ),
        );
        await tester.pumpAndSettle();
        return _carouselHeight(tester);
      }

      final hShort = await heightFor(<Map<String, dynamic>>[short]);
      final hTall = await heightFor(<Map<String, dynamic>>[tall]);
      final hShortTall = await heightFor(<Map<String, dynamic>>[short, tall]);
      final hTallShort = await heightFor(<Map<String, dynamic>>[tall, short]);

      expect(hTall, greaterThan(hShort)); // pages really differ
      final expectedMax = hTall > hShort ? hTall : hShort;
      expect(hShortTall, closeTo(expectedMax, 0.5)); // == tallest page
      expect(hTallShort, closeTo(hShortTall, 0.5)); // order-independent
      expect(hShortTall, lessThan(400)); // content-sized, not the old fixed 400
    });

    testWidgets('vertical auto carousel renders a non-zero content height',
        (tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: _carouselCard(
            orientation: 'vertical',
            pages: <Map<String, dynamic>>[_page('a', 2), _page('b', 5)],
          ),
          title: 'vertical auto',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<PageView>(find.byType(PageView)).scrollDirection,
        Axis.vertical,
      );
      expect(_carouselHeight(tester), greaterThan(0));
    });
  });
}
```

> Note: `'height': ?heightProp` uses the collection-if-null map spread already used in `carousel_behavior_test.dart`; keys with a null value are omitted.

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/elements/carousel_height_test.dart --exclude-tags=golden`
Expected: FAIL — the widget tests fail because height is still the hardcoded 400 (e.g. `heightInPixels` expects 100 but gets 400; `hShortTall` is 400 not `< 400`).

- [ ] **Step 3: Add measurement widget + state + parsing**

In `lib/src/cards/elements/carousel.dart`:

3a. Ensure the imports include (add if missing):

```dart
import 'package:flutter/rendering.dart';
```

3b. Add fields to `AdaptiveCarouselState` (near the other fields):

```dart
  /// Fixed pixel height from `heightInPixels` (e.g. `"100px"`); null when unset.
  double? heightInPixels;

  /// Whether `height` is `stretch` (fill parent) rather than the default auto.
  bool isStretchHeight = false;

  /// Fallback height used before the pages have been measured.
  static const double _fallbackHeight = 400;

  /// Measured natural height of each page, keyed by page index.
  final Map<int, double> _pageHeights = <int, double>{};
```

3c. In `initState`, replace the orientation block's surroundings so parsing is added (keep the existing `scrollAxis` line unchanged — orientation stays independent):

```dart
    heightInPixels = _parsePixelHeight(adaptiveMap['heightInPixels']);
    isStretchHeight =
        adaptiveMap['height']?.toString().toLowerCase() == 'stretch';
```

Add these methods to `AdaptiveCarouselState`:

```dart
  double? _parsePixelHeight(Object? raw) {
    if (raw == null) return null;
    final String cleaned =
        raw.toString().toLowerCase().replaceAll('px', '').trim();
    return double.tryParse(cleaned);
  }

  double? _measuredMaxHeight() {
    if (_pageHeights.length < pages.length) return null;
    return _pageHeights.values
        .fold<double>(0, (double m, double h) => h > m ? h : m);
  }

  void _recordPageHeight(int index, double height) {
    if (!mounted) return;
    if (_pageHeights[index] == height) return;
    setState(() => _pageHeights[index] = height);
  }
```

3d. Add the private measurement widget at the bottom of the file (after `resolveCarouselHeight`):

```dart
typedef _SizeCallback = void Function(Size size);

/// Reports its child's laid-out [Size] after each layout, off the paint path.
///
/// Used by [AdaptiveCarousel] to measure each page's natural height so the
/// carousel can size itself to the tallest page.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required Widget super.child});

  final _SizeCallback onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderObject(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  _SizeCallback onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onChange(newSize));
  }
}
```

- [ ] **Step 4: Rewrite `AdaptiveCarouselState.build`**

Replace the current `build` method body (the `Visibility(...)` return) with:

```dart
  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return const SizedBox.shrink();

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double? measuredMax = _measuredMaxHeight();
            final double height = resolveCarouselHeight(
              heightInPixels: heightInPixels,
              isStretch: isStretchHeight,
              maxAvailableHeight: constraints.maxHeight,
              measuredMaxHeight: measuredMax,
              fallback: _fallbackHeight,
            );
            final bool needsMeasure = heightInPixels == null &&
                !(isStretchHeight && constraints.maxHeight.isFinite) &&
                measuredMax == null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (needsMeasure) _buildMeasurementLayer(constraints.maxWidth),
                SizedBox(
                  height: height,
                  child: PageView.builder(
                    controller: pageController,
                    scrollDirection: scrollAxis,
                    onPageChanged: _onPageChanged,
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return cardTypeRegistry.getElement(map: pages[index]);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _buildControls(styleResolver),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Off-stage layer that lays out every page at the carousel width so each
  /// page's natural height can be measured; dropped once all pages are known.
  Widget _buildMeasurementLayer(double width) {
    return Offstage(
      child: Column(
        children: [
          for (int i = 0; i < pages.length; i++)
            _MeasureSize(
              onChange: (Size size) => _recordPageHeight(i, size.height),
              child: SizedBox(
                width: width.isFinite ? width : null,
                child: cardTypeRegistry.getElement(map: pages[i]),
              ),
            ),
        ],
      ),
    );
  }
```

- [ ] **Step 5: Run the height tests to verify they pass**

Run: `fvm flutter test test/elements/carousel_height_test.dart --exclude-tags=golden`
Expected: PASS (5 unit + 3 widget = 8 tests).

- [ ] **Step 6: Analyze**

Run: `fvm flutter analyze lib/src/cards/elements/carousel.dart test/elements/carousel_height_test.dart`
Expected: No issues. (If `import 'package:flutter/rendering.dart';` is reported unused because `RenderProxyBox`/`RenderObject` already resolve via `material.dart`, remove it.)

- [ ] **Step 7: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/elements/carousel.dart \
        packages/flutter_adaptive_cards_fs/test/elements/carousel_height_test.dart
git commit -m "feat(carousel): size to tallest page; honor height and heightInPixels"
```

---

### Task 3: Regression check, changelog, docs sync, full verification

**Files:**

- Modify (conditional): `test/elements/carousel_behavior_test.dart`.
- Modify: `CHANGELOG.md`.
- Modify (as grep dictates): docs under `docs/` and `README.md`.

- [ ] **Step 1: Run the full carousel test set**

Run: `fvm flutter test test/elements/carousel_behavior_test.dart test/elements/carousel_page_test.dart test/elements/carousel_visibility_overlay_test.dart --exclude-tags=golden`
Expected: PASS. The transient measurement layer is gone after `pumpAndSettle`, so page-count / `find.text` assertions should hold. If any assertion now double-counts (e.g. `findsOneWidget` → 2), the cause is a test that reads before settle; fix by adding `await tester.pumpAndSettle();` before the assertion, or by scoping the finder with `find.descendant(of: find.byType(PageView), ...)`. Do **not** loosen a correctness assertion to hide a real double-render.

- [ ] **Step 2: Changelog**

Add under `## [Unreleased]` in `packages/flutter_adaptive_cards_fs/CHANGELOG.md`:

```markdown
- **Carousel:** replaced the fixed 400px height with the spec height model — `height` (`auto`/`stretch`) and `heightInPixels` — and, for the default `auto` case, size the carousel to its tallest page. Orientation stays independent of `heightInPixels`.
```

- [ ] **Step 3: Docs sync**

Run: `git grep -niE 'carousel' docs/ packages/flutter_adaptive_cards_fs/README.md`
Review hits for any statement that the carousel is fixed-height or that height is unimplemented (e.g. an Implementation-status/Known-gaps row). Update those to reflect the new behavior. If no such statement exists, no doc edit is required — record that in the commit message.

- [ ] **Step 4: Commit docs + changelog**

```bash
git add packages/flutter_adaptive_cards_fs/CHANGELOG.md
# add any docs/README files touched in Step 3
git commit -m "docs(carousel): changelog + status sync for content-sized height"
```

- [ ] **Step 5: Full verification (see section below)**

---

### Task 4: Regenerate the carousel golden (do NOT commit the image)

The v1.6 carousel golden (`test/gold_files/<platform>/v1_6_carousel.png`) rendered at the old fixed 400px. With content-sizing it now renders at the tallest-page height, so its master image must be regenerated. **The regenerated `.png` is left uncommitted for the user to review before it lands.** Note: `--update-goldens` only rewrites the current platform's master (macOS here); the Linux master is regenerated separately in CI / a Linux container.

**Files:**

- Regenerate (do not commit): `test/gold_files/macos/v1_6_carousel.png` (and, on CI/Linux, `test/gold_files/linux/v1_6_carousel.png`).

- [ ] **Step 1: Regenerate the carousel golden only**

Run (from `packages/flutter_adaptive_cards_fs/`):
`fvm flutter test test/golden_v1_6_test.dart --update-goldens --name 'Golden Carousel'`
Expected: PASS; `git status` shows `test/gold_files/macos/v1_6_carousel.png` modified.

- [ ] **Step 2: Confirm the golden now passes without updating**

Run: `fvm flutter test test/golden_v1_6_test.dart --name 'Golden Carousel'`
Expected: PASS against the regenerated master.

- [ ] **Step 3: Hand the image to the user for review — DO NOT commit**

Show the regenerated `v1_6_carousel.png` to the user. Leave it unstaged/uncommitted. Only the user decides when (and whether) the image is committed. Do not run `git add`/`git commit` on any `*.png`.

---

## Verification (full suite)

Run from `packages/flutter_adaptive_cards_fs/` unless noted. Paste exit codes / pass-fail counts before claiming completion (per `superpowers:verification-before-completion`).

- [ ] Repo-root analyze:

Run (from repo root): `fvm flutter analyze`
Expected: No issues.

- [ ] Main library tests (golden-excluded):

Run: `fvm flutter test --exclude-tags=golden`
Expected: All pass.

- [ ] Coverage gate:

Run: `fvm flutter test --coverage --exclude-tags=golden` then, from repo root, `fvm dart run tool/coverage/check_coverage.dart`
Expected: `carousel.dart` coverage does not drop the package below its floor in `tool/coverage_floors.yaml`. If it does, add tests (do not lower the floor).

- [ ] Only after all of the above pass, invoke `superpowers:finishing-a-development-branch`.
