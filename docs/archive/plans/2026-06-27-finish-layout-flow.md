# Finish `Layout.Flow` Implementation Plan

> **Status: ✅ Complete** — shipped in PR #53. Archived 2026-07-02.
> Checkbox state below is historical and was not ticked at merge time.

---

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete `Layout.Flow` support — add `itemWidth` + `itemFit` parsing, extend `layouts`/`Layout.Flow` to `Column` and `TableCell`, refine the `IntrinsicWidth` wrapper (W1: keep for content-fit, skip for `itemWidth`), give `selectLayout` a specificity tiebreak (W3), guard unbounded width, and keep the golden/test sample in sync with the widgetbook demo.

**Architecture:** Reuse the existing width-bucket infrastructure (`cardWidthBucketProvider`, `selectLayout`, `AdaptiveFlowLayout`). Extract a single `buildLayoutChildren` helper and route `Container`, root body, `Column`, and `TableCell` through it so all four share one Flow-vs-stack code path. `itemFit: "Fill"` is out of scope (needs custom row-packing); it falls back to `"Fit"` with a one-time log. `ColumnSet` is not supported by the spec and is excluded.

**Tech Stack:** Flutter, Dart, Riverpod (v3), `package:test` / `flutter_test`, FVM, widgetbook.

**Spec:** [`docs/superpowers/specs/2026-06-27-finish-layout-flow-design.md`](../specs/2026-06-27-finish-layout-flow-design.md)

> **Git gate (project rule):** Every `git commit` in this plan requires showing the diff and getting explicit user confirmation first (per `AGENTS.md`). The commit steps below are the intended commit points; do not run them unattended.

> **Working directory:** Unless stated otherwise, run all `fvm` commands from `packages/flutter_adaptive_cards_fs/`. Always prefix `flutter`/`dart` with `fvm`.

---

## File Structure

**Modify (core library):**
- `packages/flutter_adaptive_cards_fs/lib/src/responsive/width_bucket.dart` — add `relationalSpecificity()`.
- `packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_selection.dart` — nearest-relational tiebreak (W3).
- `packages/flutter_adaptive_cards_fs/lib/src/responsive/adaptive_flow_layout.dart` — refine `IntrinsicWidth` (W1: keep for content-fit, skip for `itemWidth`), add `itemWidth` + `itemFit`.
- `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/container.dart` — use shared helper.
- `packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart` — use shared helper in `_AdaptiveCardBody`; unbounded-width guard.
- `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/column.dart` — Flow support.
- `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart` — Flow support in `buildCellContent`.
- `packages/flutter_adaptive_cards_fs/lib/src/models/table_cell.dart` — parse `layouts`.
- `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_widths_config.dart` — infinite-width guard in `resolveBucket`.

**Create (core library):**
- `packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_children.dart` — `buildLayoutChildren()`.
- `packages/flutter_adaptive_cards_fs/test/samples/responsive/flow_column.json` — golden/widget sample.

**Modify/Create (tests):**
- `packages/flutter_adaptive_cards_fs/test/responsive/layout_selection_test.dart`
- `packages/flutter_adaptive_cards_fs/test/responsive/adaptive_flow_layout_test.dart`
- `packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart`
- `packages/flutter_adaptive_cards_fs/test/responsive/host_widths_config_test.dart`
- `packages/flutter_adaptive_cards_fs/test/responsive/layout_children_test.dart` (new)
- `packages/flutter_adaptive_cards_fs/test/golden_responsive_flow_test.dart`

**Modify/Create (widgetbook + docs):**
- `widgetbook/lib/samples/responsive/flow_column.json` (identical copy)
- `widgetbook/lib/responsive_flow_page.dart` — sample-picker knob
- `packages/flutter_adaptive_cards_fs/README.md`, `docs/Implementation-Status.md`, `docs/superpowers/specs/2026-06-18-responsive-layout-targetwidth-flow-design.md`, `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

---

## Task 1: `selectLayout` specificity tiebreak (W3)

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/responsive/width_bucket.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_selection.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/layout_selection_test.dart`

- [ ] **Step 1: Write the failing tests**

Add these tests inside the `group('selectLayout', ...)` block in `test/responsive/layout_selection_test.dart`:

```dart
    test('nearest relational match wins (atLeast) at wide', () {
      final layouts = [
        {'type': 'Layout.Stack', 'targetWidth': 'atLeast:narrow'},
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
      ];
      // At wide, atLeast:standard (covers 2) beats atLeast:narrow (covers 3).
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
    });

    test('nearest relational match wins regardless of array order', () {
      final layouts = [
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
        {'type': 'Layout.Stack', 'targetWidth': 'atLeast:narrow'},
      ];
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
    });

    test('nearest relational match wins (atMost) at veryNarrow', () {
      final layouts = [
        {'type': 'Layout.Stack', 'targetWidth': 'atMost:wide'},
        {'type': 'Layout.Flow', 'targetWidth': 'atMost:narrow'},
      ];
      // At veryNarrow, atMost:narrow (covers 2) beats atMost:wide (covers 4).
      expect(
        selectLayout(layouts, WidthBucket.veryNarrow)?['type'],
        'Layout.Flow',
      );
    });

    test('equal-specificity relational matches keep array order', () {
      final layouts = [
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:narrow'},
        {'type': 'Layout.Stack', 'targetWidth': 'atMost:standard'},
      ];
      // At standard both cover 3 buckets (equal specificity); first wins.
      expect(selectLayout(layouts, WidthBucket.standard)?['type'], 'Layout.Flow');
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/responsive/layout_selection_test.dart`
Expected: the new `nearest relational` tests FAIL (current code returns the first relational match in array order).

- [ ] **Step 3: Add `relationalSpecificity` to `width_bucket.dart`**

Append this function to `lib/src/responsive/width_bucket.dart` (after `isExactBucketMatch`). Specificity is the number of buckets the relational covers (fewer = more specific), which beats a raw bucket-distance metric: it never lets a broad `atMost:wide` outrank a targeted `atLeast:standard`:

```dart
/// Specificity of a relational [targetWidth], as the number of width buckets it
/// covers (fewer buckets = more specific).
///
/// `'atLeast:<b>'` covers `<b>` through the widest bucket; `'atMost:<b>'` covers
/// the narrowest bucket through `<b>`. Returns `null` for non-relational, null,
/// or unparseable values (including an unknown operator). Layout selection
/// prefers the most specific (smallest) relational match.
int? relationalSpecificity(String? targetWidth) {
  if (targetWidth == null) return null;
  final raw = targetWidth.trim();
  if (!raw.contains(':')) return null;
  final parts = raw.split(':');
  if (parts.length != 2) return null;
  final op = parts[0].trim().toLowerCase();
  final target = _parseBucket(parts[1]);
  if (target == null) return null;
  switch (op) {
    case 'atleast':
      return WidthBucket.values.length - target.index;
    case 'atmost':
      return target.index + 1;
    default:
      return null;
  }
}
```

- [ ] **Step 4: Rewrite `selectLayout` to use the distance**

Replace the entire body of `selectLayout` in `lib/src/responsive/layout_selection.dart` with:

```dart
Map<String, dynamic>? selectLayout(
  List<dynamic>? layouts,
  WidthBucket bucket,
) {
  if (layouts == null || layouts.isEmpty) return null;

  Map<String, dynamic>? relationalMatch;
  int? relationalBestSpecificity;
  Map<String, dynamic>? defaultMatch;

  for (final raw in layouts) {
    if (raw is! Map) continue;
    final layout = Map<String, dynamic>.from(raw);
    final targetWidth = layout['targetWidth'] as String?;
    if (!targetWidthMatches(targetWidth, bucket)) continue;

    if (isExactBucketMatch(targetWidth, bucket)) {
      return layout;
    }
    if (targetWidth == null || targetWidth.trim().isEmpty) {
      defaultMatch ??= layout;
    } else {
      final specificity = relationalSpecificity(targetWidth);
      if (specificity != null &&
          (relationalBestSpecificity == null ||
              specificity < relationalBestSpecificity)) {
        relationalBestSpecificity = specificity;
        relationalMatch = layout;
      }
    }
  }

  return relationalMatch ?? defaultMatch;
}
```

(The strict `<` keeps array order on ties.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `fvm flutter test test/responsive/layout_selection_test.dart`
Expected: PASS (all old + new tests).

- [ ] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/width_bucket.dart \
  packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_selection.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/layout_selection_test.dart
git commit -m "fix(responsive): selectLayout prefers nearest relational match (W3)"
```

---

## Task 2: `AdaptiveFlowLayout` — refine `IntrinsicWidth` (W1), add `itemWidth` + `itemFit`

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/responsive/adaptive_flow_layout.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/adaptive_flow_layout_test.dart`

- [ ] **Step 1: Update the existing min-width test and add new tests**

In `test/responsive/adaptive_flow_layout_test.dart`:

(a) In the existing `'clamps item width to minItemWidth'` test, after the `expect(constraints.minWidth, 200);` line add:

```dart
    // Content-fit items (min/max, no itemWidth) keep IntrinsicWidth so they
    // shrink to content instead of filling the row.
    expect(
      find.descendant(
        of: find.byType(AdaptiveFlowLayout),
        matching: find.byType(IntrinsicWidth),
      ),
      findsOneWidget,
    );
```

(b) Add these new tests to `main()`:

```dart
  testWidgets('no sizing → each item is content-fit via IntrinsicWidth',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow'},
            styleResolver: resolver,
            children: const [Text('a'), Text('b')],
          ),
        ),
      ),
    );

    // Both items are wrapped in IntrinsicWidth (content-fit), with no clamps.
    expect(find.byType(IntrinsicWidth), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(AdaptiveFlowLayout),
        matching: find.byType(ConstrainedBox),
      ),
      findsNothing,
    );
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets('itemWidth gives each item a fixed-width SizedBox',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow', 'itemWidth': '120px'},
            styleResolver: resolver,
            children: const [Text('x')],
          ),
        ),
      ),
    );

    final sized = tester.widget<SizedBox>(
      find
          .ancestor(of: find.text('x'), matching: find.byType(SizedBox))
          .first,
    );
    expect(sized.width, 120);
  });

  testWidgets('itemFit "Fill" does not throw and renders as Fit',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow', 'itemFit': 'Fill'},
            styleResolver: resolver,
            children: const [Text('a'), Text('b')],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets('itemWidth is the safe escape for items without intrinsic width',
      (tester) async {
    // A nested Wrap has no intrinsic-width support, so the content-fit path
    // (IntrinsicWidth) cannot size it. Setting itemWidth switches to a SizedBox
    // (no IntrinsicWidth), which sizes such items without throwing.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow', 'itemWidth': '100px'},
            styleResolver: resolver,
            children: const [
              Wrap(children: [Text('nested')]),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(IntrinsicWidth), findsNothing);
    expect(find.text('nested'), findsOneWidget);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/responsive/adaptive_flow_layout_test.dart`
Expected: the new `itemWidth` and `itemFit` tests FAIL (current code has no `itemWidth`/`itemFit` handling).

- [ ] **Step 3: Rewrite `adaptive_flow_layout.dart`**

Replace the whole file `lib/src/responsive/adaptive_flow_layout.dart` with:

```dart
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';

/// Tracks `itemFit: "Fill"` warnings so each layout config logs at most once.
final Set<String> _loggedFillWarnings = <String>{};

/// Renders a container's items as a wrapping `Layout.Flow` arrangement.
///
/// Items flow left-to-right and wrap to new rows as width allows, instead of
/// stacking vertically. `columnSpacing` / `rowSpacing` resolve through the same
/// HostConfig spacing tokens as other elements; `horizontalItemsAlignment` and
/// `verticalItemsAlignment` map to [Wrap] alignment.
///
/// Item width follows the spec: `itemWidth` fixes each item's width; otherwise
/// `minItemWidth` / `maxItemWidth` clamp the content-fit width; with none set,
/// items take their natural size. `itemFit: "Fill"` (grow items to fill a row)
/// is not yet supported and is rendered as `"Fit"`.
///
/// Content-fit items are wrapped in [IntrinsicWidth] because several Adaptive
/// Card elements (e.g. `TextBlock`, which wraps its text in an expanding
/// [Align]) would otherwise stretch to the full row width inside a [Wrap] and
/// fail to flow. The trade-off: a content-fit item whose widget subtree can't
/// report an intrinsic width (a nested `Layout.Flow`/[Wrap] or a
/// [LayoutBuilder]-based element placed *directly* as a flow item) will throw;
/// give such an item an explicit `itemWidth` (which uses a [SizedBox] and skips
/// [IntrinsicWidth]) to size it safely.
class AdaptiveFlowLayout extends StatelessWidget {
  /// Creates a flow layout from a parsed `Layout.Flow` [layoutMap].
  const AdaptiveFlowLayout({
    required this.layoutMap,
    required this.styleResolver,
    required this.children,
    super.key,
  });

  /// The selected `Layout.Flow` object from the container's `layouts` array.
  final Map<String, dynamic> layoutMap;

  /// Resolver used to map spacing tokens to pixel gaps.
  final ReferenceResolver styleResolver;

  /// The container's item widgets to arrange.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final itemWidth = _toPixels(layoutMap['itemWidth']);
    final minItemWidth = _toPixels(layoutMap['minItemWidth']);
    final maxItemWidth = _toPixels(layoutMap['maxItemWidth']);
    _warnUnsupportedItemFit();
    return Wrap(
      spacing: styleResolver.resolveSpacing(
        layoutMap['columnSpacing'] as String?,
      ),
      runSpacing: styleResolver.resolveSpacing(
        layoutMap['rowSpacing'] as String?,
      ),
      alignment: _wrapAlignment(
        layoutMap['horizontalItemsAlignment'] as String?,
      ),
      crossAxisAlignment: _wrapCrossAlignment(
        layoutMap['verticalItemsAlignment'] as String?,
      ),
      children: [
        for (final child in children)
          _sizedItem(child, itemWidth, minItemWidth, maxItemWidth),
      ],
    );
  }

  /// Applies the spec item-sizing rules.
  ///
  /// `itemWidth` (fixed) takes precedence and uses a [SizedBox] — no
  /// [IntrinsicWidth], so it also safely sizes items that can't report intrinsic
  /// dimensions. Otherwise the item is content-fit: wrapped in [IntrinsicWidth]
  /// so it shrinks to its natural width instead of filling the row (several
  /// elements — e.g. `TextBlock`, which wraps its text in an expanding [Align] —
  /// would otherwise stretch to the full [Wrap] width and stop flowing), and
  /// clamped by [ConstrainedBox] when `min`/`maxItemWidth` are present.
  Widget _sizedItem(
    Widget child,
    double? itemWidth,
    double? minWidth,
    double? maxWidth,
  ) {
    if (itemWidth != null) {
      if (minWidth != null || maxWidth != null) {
        developer.log(
          'Layout.Flow itemWidth is set; ignoring minItemWidth/maxItemWidth',
          name: 'responsive.adaptive_flow_layout',
        );
      }
      return SizedBox(width: itemWidth, child: child);
    }
    final content = IntrinsicWidth(child: child);
    if (minWidth == null && maxWidth == null) return content;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0.0,
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: content,
    );
  }

  /// `itemFit: "Fill"` needs a custom row-packing layout (not expressible with
  /// [Wrap]); log once and fall back to the content-fit ("Fit") behavior.
  void _warnUnsupportedItemFit() {
    final itemFit = (layoutMap['itemFit'] as String?)?.trim().toLowerCase();
    if (itemFit == 'fill') {
      final key = layoutMap.toString();
      if (_loggedFillWarnings.add(key)) {
        developer.log(
          'Layout.Flow itemFit "Fill" is not supported; rendering as "Fit"',
          name: 'responsive.adaptive_flow_layout',
        );
      }
    }
  }

  /// Parses a spec `"<number>px"` string or a bare number to logical pixels;
  /// returns `null` for absent or malformed values.
  double? _toPixels(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      final body = trimmed.toLowerCase().endsWith('px')
          ? trimmed.substring(0, trimmed.length - 2).trim()
          : trimmed;
      return double.tryParse(body);
    }
    return null;
  }

  WrapAlignment _wrapAlignment(String? value) {
    switch (value) {
      case 'center':
        return WrapAlignment.center;
      case 'right':
        return WrapAlignment.end;
      default:
        return WrapAlignment.start;
    }
  }

  WrapCrossAlignment _wrapCrossAlignment(String? value) {
    switch (value) {
      case 'center':
        return WrapCrossAlignment.center;
      case 'bottom':
        return WrapCrossAlignment.end;
      default:
        return WrapCrossAlignment.start;
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `fvm flutter test test/responsive/adaptive_flow_layout_test.dart`
Expected: PASS (old + new tests).

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/adaptive_flow_layout.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/adaptive_flow_layout_test.dart
git commit -m "feat(responsive): Layout.Flow itemWidth + itemFit; keep IntrinsicWidth for content-fit (W1)"
```

---

## Task 3: Shared `buildLayoutChildren` helper; refactor Container + root body

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_children.dart`
- Create test: `packages/flutter_adaptive_cards_fs/test/responsive/layout_children_test.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/container.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart`

- [ ] **Step 1: Write the failing test**

Create `test/responsive/layout_children_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resolver = ReferenceResolver(
    hostConfigs: HostConfigs(),
    colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
  );

  Widget stackBuilder(List<Widget> children) => Column(children: children);

  testWidgets('returns AdaptiveFlowLayout when a Layout.Flow matches',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildLayoutChildren(
            layouts: const [
              {'type': 'Layout.Flow', 'targetWidth': 'atLeast:narrow'},
            ],
            bucket: WidthBucket.wide,
            styleResolver: resolver,
            children: const [Text('a')],
            stackBuilder: stackBuilder,
          ),
        ),
      ),
    );

    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
  });

  testWidgets('delegates to stackBuilder when no layout applies',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildLayoutChildren(
            layouts: null,
            bucket: WidthBucket.wide,
            styleResolver: resolver,
            children: const [Text('a')],
            stackBuilder: stackBuilder,
          ),
        ),
      ),
    );

    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.byType(Column), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/responsive/layout_children_test.dart`
Expected: FAIL — `layout_children.dart` / `buildLayoutChildren` does not exist (compile error).

- [ ] **Step 3: Create the helper**

Create `lib/src/responsive/layout_children.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// Lays out a container's [children] for the current width [bucket].
///
/// Chooses the best entry from [layouts] (see [selectLayout]). When the choice
/// is `Layout.Flow`, returns an [AdaptiveFlowLayout]; otherwise delegates to
/// [stackBuilder] (the caller's own stack widget — a `Column`, `Wrap`, etc.),
/// so non-Flow rendering is identical to before this helper existed. Callers
/// pass `ref.watch(cardWidthBucketProvider)` as [bucket] to reflow on resize.
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

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/responsive/layout_children_test.dart`
Expected: PASS.

- [ ] **Step 5: Refactor `container.dart` onto the helper**

In `lib/src/cards/containers/container.dart`, replace the `else` branch in `build` (the block currently computing `selected` / `useFlow` / `itemsLayout`, lines ~95-119) with:

```dart
    } else {
      final Widget itemsLayout = buildLayoutChildren(
        layouts: adaptiveMap['layouts'] as List<dynamic>?,
        bucket: ref.watch(cardWidthBucketProvider),
        styleResolver: styleResolver,
        children: children,
        stackBuilder: (items) => Column(
          mainAxisAlignment: verticalContentAlignment,
          children: items.toList(),
        ),
      );
      containerChild = Padding(
        padding: EdgeInsets.symmetric(
          vertical: spacing,
          horizontal: spacing,
        ),
        child: itemsLayout,
      );
    }
```

Then fix imports at the top of `container.dart`: remove the now-unused
`adaptive_flow_layout.dart` and `layout_selection.dart` imports and add:

```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
```

(Keep the `providers.dart` import — `cardWidthBucketProvider` still used.)

- [ ] **Step 6: Refactor the root body (`_AdaptiveCardBody`) onto the helper**

In `lib/src/cards/adaptive_card_element.dart`, replace the body of
`_AdaptiveCardBody.build` with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return buildLayoutChildren(
      layouts: layouts,
      bucket: ref.watch(cardWidthBucketProvider),
      styleResolver: styleResolver,
      children: bodyItems,
      stackBuilder: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }
```

Add the import near the other responsive imports in `adaptive_card_element.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
```

Leave the existing `selectLayout` / `AdaptiveFlowLayout` imports if still used elsewhere in the file; if `fvm flutter analyze` reports them unused after this change, remove them.

- [ ] **Step 7: Run the responsive widget tests to verify no behavior change**

Run: `fvm flutter test test/responsive/`
Expected: PASS (Container + root Flow behavior unchanged; `flow_column.json` tests are added in Task 4).

- [ ] **Step 8: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_children.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/layout_children_test.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/containers/container.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart
git commit -m "refactor(responsive): extract buildLayoutChildren; route Container + root through it"
```

---

## Task 4: `Layout.Flow` on `Column`

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/test/samples/responsive/flow_column.json`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/column.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart`

- [ ] **Step 1: Create the sample card**

Create `test/samples/responsive/flow_column.json`:

```json
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "body": [
    {
      "type": "ColumnSet",
      "columns": [
        {
          "type": "Column",
          "width": "stretch",
          "layouts": [
            {
              "type": "Layout.Flow",
              "targetWidth": "atLeast:standard",
              "columnSpacing": "small",
              "rowSpacing": "small",
              "itemWidth": "80px"
            }
          ],
          "items": [
            { "type": "TextBlock", "text": "One" },
            { "type": "TextBlock", "text": "Two" },
            { "type": "TextBlock", "text": "Three" }
          ]
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Write the failing tests**

In `test/responsive/responsive_widget_test.dart`, add a loader line near the others (after `rootFlowCard`):

```dart
  final flowColumnCard = _loadCard('responsive/flow_column.json');
```

and add these tests in `main()`:

```dart
  testWidgets('Column uses Flow when wide', (tester) async {
    await _pumpCardAtWidth(tester, flowColumnCard, 1000);
    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });

  testWidgets('Column stays a stack when narrow', (tester) async {
    await _pumpCardAtWidth(tester, flowColumnCard, 150);
    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: `Column uses Flow when wide` FAILS — `Column` does not yet honor `layouts` (no `AdaptiveFlowLayout`).

- [ ] **Step 4: Add Flow support to `column.dart`**

In `lib/src/cards/containers/column.dart`, replace the `else` branch that builds `containerChild` (lines ~140-150) with:

```dart
    } else {
      containerChild = ChildStyler(
        adaptiveMap: adaptiveMap,
        child: buildLayoutChildren(
          layouts: adaptiveMap['layouts'] as List<dynamic>?,
          bucket: ref.watch(cardWidthBucketProvider),
          styleResolver: styleResolver,
          children: [...items.map((it) => it)],
          stackBuilder: (children) => Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: horizontalAlignment,
            mainAxisAlignment: verticalAlignment,
            children: children,
          ),
        ),
      );
    }
```

Add these imports to `column.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
```

(`ref` is available — `AdaptiveColumnState` is a `ConsumerState`.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/containers/column.dart \
  packages/flutter_adaptive_cards_fs/test/samples/responsive/flow_column.json \
  packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart
git commit -m "feat(responsive): Layout.Flow support on Column"
```

---

## Task 5: `Layout.Flow` on `TableCell`

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/table_cell.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart`

- [ ] **Step 1: Write the failing tests**

In `test/responsive/responsive_widget_test.dart`, add a helper builder and two tests. First add this card-builder function above `main()`:

```dart
Map<String, dynamic> _tableFlowCard() => {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Table',
          'columns': [
            {'width': 1},
          ],
          'rows': [
            {
              'type': 'TableRow',
              'cells': [
                {
                  'type': 'TableCell',
                  'layouts': [
                    {
                      'type': 'Layout.Flow',
                      'targetWidth': 'atLeast:standard',
                    },
                  ],
                  'items': [
                    {'type': 'TextBlock', 'text': 'CellOne'},
                    {'type': 'TextBlock', 'text': 'CellTwo'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    };
```

Then add these tests in `main()`:

```dart
  testWidgets('TableCell uses Flow when wide', (tester) async {
    await _pumpCardAtWidth(tester, _tableFlowCard(), 1000);
    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
    expect(find.text('CellOne'), findsOneWidget);
  });

  testWidgets('TableCell stays non-Flow when narrow', (tester) async {
    await _pumpCardAtWidth(tester, _tableFlowCard(), 150);
    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.text('CellOne'), findsOneWidget);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: `TableCell uses Flow when wide` FAILS — cells don't honor `layouts`.

- [ ] **Step 3: Add `layouts` to `TableCellModel`**

In `lib/src/models/table_cell.dart`:

(a) Add a constructor parameter in the `TableCellModel({...})` constructor (near `this.rtl,`):

```dart
    this.layouts,
```

(b) In `TableCellModel.fromJson`, add (near `rtl: json['rtl'] as bool?,`):

```dart
      layouts: json['layouts'] as List<dynamic>?,
```

(c) Add the field (near the `rtl` field declaration):

```dart
  /// Optional responsive `layouts` array (e.g. `Layout.Flow`) for this cell.
  final List<dynamic>? layouts;
```

- [ ] **Step 4: Use the helper in `buildCellContent`**

In `lib/src/cards/containers/table.dart`, `buildCellContent` currently builds:

```dart
    Widget content = Scrollbar(
      child: Wrap(children: cellWidgets),
    );
```

Replace that with:

```dart
    Widget content = Scrollbar(
      child: buildLayoutChildren(
        layouts: cellModel.layouts,
        bucket: ref.watch(cardWidthBucketProvider),
        styleResolver: styleResolver,
        children: cellWidgets,
        stackBuilder: (children) => Wrap(children: children),
      ),
    );
```

The `buildCellContent` signature already receives `required TableCellModel cellModel`, so `cellModel.layouts` is available; `ref` is available (`AdaptiveTableState` is a `ConsumerState`, and `buildCellContent` runs inside the `build` call chain).

Add the imports to `table.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
```

(If `providers.dart` is already imported, skip the duplicate.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the existing table tests to confirm no regression**

Run: `fvm flutter test test/ -name table` (or `fvm flutter test test/containers/` if that is where table tests live)
Expected: PASS — non-Flow cells still render via `Wrap`.

- [ ] **Step 7: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/table_cell.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart
git commit -m "feat(responsive): Layout.Flow support on TableCell"
```

---

## Task 6: Unbounded-width guard (W4, partial)

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_widths_config.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/host_widths_config_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/responsive/host_widths_config_test.dart` (inside the existing `main()`):

```dart
  test('resolveBucket returns wide for non-finite (unbounded) width', () {
    expect(HostWidthsConfig.resolveBucket(null, double.infinity),
        WidthBucket.wide);
    expect(HostWidthsConfig.resolveBucket(null, double.nan), WidthBucket.wide);
  });
```

If `WidthBucket` is not imported in that test file, add:

```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
```

- [ ] **Step 2: Run test to verify it fails or check current behavior**

Run: `fvm flutter test test/responsive/host_widths_config_test.dart`
Expected: the NaN case FAILS (NaN comparisons are false, so it would fall through to the narrowest bucket). The infinity case may already pass.

- [ ] **Step 3: Add the guard in `resolveBucket`**

In `lib/src/hostconfig/host_widths_config.dart`, at the very top of the static
`resolveBucket(...)` method body, add:

```dart
    if (!width.isFinite) {
      developer.log(
        'Card width is unbounded ($width); defaulting to WidthBucket.wide',
        name: 'responsive.host_widths_config',
      );
      return WidthBucket.wide;
    }
```

Ensure the file imports `dart:developer`:

```dart
import 'dart:developer' as developer;
```

(If `width_bucket.dart` / `WidthBucket` is not already imported in this file, add that import too.)

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/responsive/host_widths_config_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_widths_config.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/host_widths_config_test.dart
git commit -m "fix(responsive): default unbounded card width to wide bucket with log (W4)"
```

---

## Task 7: Golden test + widgetbook sample sync

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/test/golden_responsive_flow_test.dart`
- Create: `widgetbook/lib/samples/responsive/flow_column.json` (identical to the test copy)
- Modify: `widgetbook/lib/responsive_flow_page.dart`

- [ ] **Step 1: Add golden test cases**

In `test/golden_responsive_flow_test.dart`, add two tests in `main()`:

```dart
  testWidgets('Layout.Flow column golden — narrow (stacks)', (tester) async {
    configureTestView(size: const Size(150, 1200));
    const ValueKey key = ValueKey('paint');

    await tester.pumpWidget(
      getSampleForGoldenTest(key, 'responsive/flow_column'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('responsive_flow_column_narrow.png')),
    );
  }, tags: ['golden']);

  testWidgets('Layout.Flow column golden — wide (wraps)', (tester) async {
    configureTestView(size: const Size(1000, 1200));
    const ValueKey key = ValueKey('paint');

    await tester.pumpWidget(
      getSampleForGoldenTest(key, 'responsive/flow_column'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('responsive_flow_column_wide.png')),
    );
  }, tags: ['golden']);
```

- [ ] **Step 2: Generate the golden baselines**

Run (on the golden reference platform — see existing `gold_files/<os>/`):
`fvm flutter test --update-goldens --tags=golden test/golden_responsive_flow_test.dart`
Expected: creates `gold_files/<os>/responsive_flow_column_narrow.png` and `responsive_flow_column_wide.png`.

- [ ] **Step 3: Run the golden test to verify it passes**

Run: `fvm flutter test --tags=golden test/golden_responsive_flow_test.dart`
Expected: PASS.

- [ ] **Step 4: Copy the sample into widgetbook**

Create `widgetbook/lib/samples/responsive/flow_column.json` with **byte-identical**
content to `packages/flutter_adaptive_cards_fs/test/samples/responsive/flow_column.json`
(from Task 4, Step 1).

- [ ] **Step 5: Add a sample-picker knob to `ResponsiveFlowPage`**

Replace the body of `widgetbook/lib/responsive_flow_page.dart` `build` so the
hardcoded `_assetPath` becomes a knob. Replace the class with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

/// Widgetbook demo for responsive layout (`targetWidth` / `Layout.Flow`).
///
/// Renders the same responsive sample cards the golden and widget tests use,
/// inside a width-constrained box whose width is driven by a knob. Dragging the
/// width across the breakpoints flips the card's width bucket, so containers
/// reflow between a vertical stack (narrow) and a wrapping flow (wide). A second
/// knob picks which responsive sample to render.
class ResponsiveFlowPage extends StatelessWidget {
  const ResponsiveFlowPage({super.key});

  static const _samples = <String, String>{
    'Container flow': 'lib/samples/responsive/flow_container.json',
    'Column flow (itemWidth)': 'lib/samples/responsive/flow_column.json',
  };

  @override
  Widget build(BuildContext context) {
    final width = context.knobs.double.slider(
      label: 'Card width (px)',
      initialValue: 900,
      min: 100,
      max: 1000,
      divisions: 90,
    );
    final sampleLabel = context.knobs.list<String>(
      label: 'Sample',
      options: _samples.keys.toList(),
      initialOption: _samples.keys.first,
    );
    final assetPath = _samples[sampleLabel]!;

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Width: ${width.round()} px — bucket: ${_bucketLabel(width)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              AdaptiveCardsCanvas.asset(
                assetPath: assetPath,
                cardTypeRegistry: widgetbookCardTypeRegistry,
                hostConfigs: HostConfigs(),
                showDebugJson: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mirrors the Adaptive Cards spec-default breakpoints used by the library.
  String _bucketLabel(double width) {
    if (width < 165) return 'veryNarrow';
    if (width < 350) return 'narrow';
    if (width < 768) return 'standard';
    return 'wide';
  }
}
```

- [ ] **Step 6: Confirm the new asset is bundled (widgetbook pubspec)**

Check `widgetbook/pubspec.yaml` `flutter: assets:` includes `lib/samples/responsive/`
(the existing `flow_container.json` is already served, so the directory/glob should
already be listed). If it lists files individually, add `lib/samples/responsive/flow_column.json`.

Run: `cd ../../widgetbook && fvm flutter analyze`
Expected: no errors. Return to the package dir afterward: `cd ../packages/flutter_adaptive_cards_fs`.

- [ ] **Step 7: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/test/golden_responsive_flow_test.dart \
  packages/flutter_adaptive_cards_fs/test/gold_files \
  widgetbook/lib/samples/responsive/flow_column.json \
  widgetbook/lib/responsive_flow_page.dart \
  widgetbook/pubspec.yaml
git commit -m "test(responsive): flow_column golden + widgetbook sample-picker sync"
```

---

## Task 8: Documentation + changelog

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/README.md`
- Modify: `docs/Implementation-Status.md`
- Modify: `docs/superpowers/specs/2026-06-18-responsive-layout-targetwidth-flow-design.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [ ] **Step 1: Update the package README implementation status**

In `packages/flutter_adaptive_cards_fs/README.md`, in the **Common Properties**
table, update the `layouts` (`Layout.Flow`) row's Notes to:

```
`Layout.Flow` wrapping on `Container`, card root body, **`Column`, and `TableCell`** (spacing, item alignment, `itemWidth`, `min`/`maxItemWidth`); `itemFit: "Fit"` honored, **`itemFit: "Fill"` not yet supported**. `Layout.Stack` default. **`ColumnSet` has no `layouts` property in the spec.** `Layout.AreaGrid`/`grid.area` deferred.
```

Also update the **Known gaps** "Responsive layout" row to:

```
`targetWidth` ✅; `Layout.Flow` ✅ (Container, root, Column, TableCell); `itemFit: Fill`, `Layout.AreaGrid` / `grid.area` deferred (ColumnSet not in spec)
```

- [ ] **Step 2: Correct the roadmap in `docs/Implementation-Status.md`**

In `docs/Implementation-Status.md`:

(a) Under **High priority — standard cards**, change item 1 to:

```
1. **Responsive layout**: `targetWidth` ✅ and `Layout.Flow` ✅ (Container, root body, Column, TableCell) shipped; remaining: `Layout.AreaGrid` / `grid.area`, and Flow `itemFit: "Fill"`. (`ColumnSet` has no `layouts` property in the spec.)
```

(b) In the **Recently completed** section, add an entry:

```
### Finish Layout.Flow (2026-06-27)

Plan: [2026-06-27-finish-layout-flow.md](./superpowers/plans/2026-06-27-finish-layout-flow.md) — design: [2026-06-27-finish-layout-flow-design.md](./superpowers/specs/2026-06-27-finish-layout-flow-design.md).

- `Layout.Flow` extended to **Column** and **TableCell** (Container + root already shipped); shared `buildLayoutChildren` helper.
- `itemWidth` + `itemFit` parsing (`Fit` honored; `Fill` deferred, falls back to `Fit` with a log).
- `itemWidth` items skip `IntrinsicWidth` (fixed `SizedBox`); content-fit items keep it (W1's "remove it" was rejected — see note). `selectLayout` now prefers the most-specific relational match (W3); unbounded card width logs and defaults to `wide` (W4 partial).
- **Spec correction:** `ColumnSet` has no `layouts` property — earlier "Flow on ColumnSet" wording was wrong.
```

- [ ] **Step 3: Update W1/W3 status in the June-18 design doc**

In `docs/superpowers/specs/2026-06-18-responsive-layout-targetwidth-flow-design.md`,
under the post-implementation review: prefix the **W3** heading with
`✅ RESOLVED (2026-06-27, see finish-layout-flow plan)`. For **W1**, prefix the heading
with `⚠️ REVISITED (2026-06-27) — remediation rejected` and add a one-line note that its
premise was wrong (`Wrap` does not content-size elements that wrap content in an expanding
`Align`, e.g. `TextBlock`), so `IntrinsicWidth` is **kept** for content-fit and skipped
only when `itemWidth` is set. Add a one-line note under **W5** that `Column`/`TableCell`
Flow shipped and that `ColumnSet` is not in the spec.

- [ ] **Step 4: Add the changelog entry**

In `packages/flutter_adaptive_cards_fs/CHANGELOG.md`, under `## [Unreleased]`
(create the section if missing), add:

```
- Extend `Layout.Flow` to `Column` and `TableCell`; add `itemWidth` and `itemFit`
  parsing (`Fit` rendered; `Fill` not yet supported). `itemWidth` items use a fixed
  `SizedBox` (skipping `IntrinsicWidth`); `selectLayout` prefers the most-specific
  relational `layouts` match; unbounded card width defaults to the `wide` bucket.
```

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/README.md \
  docs/Implementation-Status.md \
  docs/superpowers/specs/2026-06-18-responsive-layout-targetwidth-flow-design.md \
  packages/flutter_adaptive_cards_fs/CHANGELOG.md
git commit -m "docs(responsive): record finished Layout.Flow; correct ColumnSet scope"
```

---

## Final Task: Full verification

- [ ] **Step 1: Static analysis (repo root)**

Run: `cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && fvm flutter analyze`
Expected: No issues (no unused imports left from the refactors).

- [ ] **Step 2: Core library tests (non-golden)**

Run:
```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden
```
Expected: all pass, 0 failures.

- [ ] **Step 3: Golden tests**

Run: `fvm flutter test --tags=golden test/golden_responsive_flow_test.dart`
Expected: PASS (baselines from Task 7 match).

- [ ] **Step 4: Coverage gate**

Run from repo root:
```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden --coverage && cd ../..
fvm dart run tool/coverage/check_coverage.dart
```
Expected: coverage floor met (do not lower floors; add tests if short).

- [ ] **Step 5: Widgetbook analyze**

Run: `cd widgetbook && fvm flutter analyze && cd ..`
Expected: No issues.

- [ ] **Step 6: Invoke `verification-before-completion`**

Paste the exit codes and pass/fail counts from Steps 1–5 before claiming completion. Do not report the plan complete until the full suite passes.

---

## Self-Review notes (author)

- **Spec coverage:** itemWidth/itemFit (Task 2), Column (Task 4), TableCell (Task 5), shared helper (Task 3), W1 (Task 2), W3 (Task 1), width guard (Task 6), golden + widgetbook sync + ColumnSet correction (Tasks 7–8). `Fill`/`ColumnSet`/`AreaGrid` explicitly deferred per spec.
- **Type consistency:** `buildLayoutChildren({layouts, bucket, styleResolver, children, stackBuilder})` is defined in Task 3 and called identically in Tasks 3–5; `relationalSpecificity(String?)` defined and used in Task 1; `_toPixels` / `_sizedItem` defined and used within Task 2.
- **Open item from the spec** (TableCell reads `layouts` via `TableCellModel` vs. raw map) resolved here in favor of adding `TableCellModel.layouts` (Task 5).
