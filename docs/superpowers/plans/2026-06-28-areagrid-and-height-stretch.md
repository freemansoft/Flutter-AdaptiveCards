# `Layout.AreaGrid` + block `height: stretch` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement general block `height: "stretch"` for core containers, then `Layout.AreaGrid` + `grid.area` (named-area responsive grid) on top of it.

**Architecture:** `height: stretch` becomes real only in height-bounded contexts (via `Expanded` under a finite-`maxHeight` `LayoutBuilder`) and degrades to `auto` when unbounded. `Layout.AreaGrid` is a bespoke `RenderBox` (no new core dependency) that resolves `%`/`px`/implied columns, sizes rows (with span + stretch), and places children by their `grid.area`; it plugs into the existing `selectLayout` + `cardWidthBucketProvider` selection used by `Layout.Flow`. Both features share an `isStretchHeight` predicate and a `childMaps` (raw item JSON) list threaded through `buildLayoutChildren`.

**Tech Stack:** Flutter, Dart, Riverpod, `package:test`/`flutter_test`, FVM, widgetbook.

**Specs:** [`height: stretch`](../specs/2026-06-28-block-height-stretch-design.md) · [`Layout.AreaGrid`](../specs/2026-06-28-layout-areagrid-design.md)

> **Git gate (project rule):** Every `git commit` here requires showing the diff and explicit user confirmation first (per `AGENTS.md`). Commit steps are the intended commit points; do not run them unattended.

> **Working directory:** Run all `fvm` commands from `packages/flutter_adaptive_cards_fs/` unless stated. Always prefix `flutter`/`dart` with `fvm`. `cd` within the repo is allowed.

---

## File Structure

**Phase 1 — `height: stretch`**
- Create `lib/src/utils/block_height.dart` — `isStretchHeight(Map)` predicate.
- Create `lib/src/cards/stretchable_column.dart` — `buildStretchableColumn(...)`.
- Modify `container.dart`, `column.dart`, `adaptive_card_element.dart` — stack sites call `buildStretchableColumn` and thread `childMaps`.
- Tests: `test/utils/block_height_test.dart`, `test/cards/stretchable_column_test.dart`, additions to `test/responsive/responsive_widget_test.dart`.

**Phase 2 — `Layout.AreaGrid`**
- Create `lib/src/responsive/area_grid_model.dart` — `GridAreaModel`, `AreaGridTrack`, `AreaGridLayout` parse.
- Create `lib/src/responsive/area_grid_solver.dart` — pure column-width + grid-dimension functions.
- Create `lib/src/responsive/adaptive_area_grid.dart` — `AdaptiveAreaGrid` widget + `RenderAdaptiveAreaGrid`.
- Modify `lib/src/responsive/layout_children.dart` — add `childMaps`, dispatch `Layout.AreaGrid`.
- Modify `container.dart`, `column.dart`, `adaptive_card_element.dart`, `table.dart` — pass `childMaps`.
- Tests: `test/responsive/area_grid_model_test.dart`, `area_grid_solver_test.dart`, `area_grid_widget_test.dart`; golden additions in `test/golden_responsive_flow_test.dart` (or a new `golden_area_grid_test.dart`); sample `test/samples/responsive/area_grid.json` + widgetbook copy.

---

# PHASE 1 — Block `height: "stretch"`

## Task 1: `isStretchHeight` predicate

**Files:**
- Create: `lib/src/utils/block_height.dart`
- Test: `test/utils/block_height_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_adaptive_cards_fs/src/utils/block_height.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isStretchHeight', () {
    test('true only for "stretch" (case-insensitive)', () {
      expect(isStretchHeight({'height': 'stretch'}), isTrue);
      expect(isStretchHeight({'height': 'Stretch'}), isTrue);
    });
    test('false for auto/absent/non-string', () {
      expect(isStretchHeight({'height': 'auto'}), isFalse);
      expect(isStretchHeight({}), isFalse);
      expect(isStretchHeight({'height': 42}), isFalse);
      expect(isStretchHeight({'height': null}), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm flutter test test/utils/block_height_test.dart`
Expected: FAIL — `block_height.dart` / `isStretchHeight` does not exist.

- [ ] **Step 3: Implement**

Create `lib/src/utils/block_height.dart`:

```dart
/// Whether an element's `height` property requests `"stretch"` (fill available
/// main-axis space) rather than the `"auto"` default.
///
/// Case-insensitive; tolerant of absent or non-string values (returns `false`).
/// Shared by the stretchable-column layout and `Layout.AreaGrid` in-cell stretch.
bool isStretchHeight(Map<String, dynamic> map) {
  final height = map['height'];
  return height is String && height.trim().toLowerCase() == 'stretch';
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `fvm flutter test test/utils/block_height_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/utils/block_height.dart \
  packages/flutter_adaptive_cards_fs/test/utils/block_height_test.dart
git commit -m "feat(layout): add isStretchHeight predicate"
```

---

## Task 2: `buildStretchableColumn`

**Files:**
- Create: `lib/src/cards/stretchable_column.dart`
- Test: `test/cards/stretchable_column_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/stretchable_column.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({required double? maxHeight, required List<Widget> child}) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight ?? double.infinity,
              maxWidth: 300,
            ),
            child: child.single,
          ),
        ),
      ),
    );
  }

  testWidgets('bounded height: single stretch child fills height',
      (tester) async {
    await tester.pumpWidget(
      host(
        maxHeight: 600,
        child: [
          buildStretchableColumn(
            childMaps: const [
              {'type': 'X', 'height': 'stretch'},
            ],
            children: const [SizedBox(key: Key('s'), height: 10)],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
        ],
      ),
    );
    // Expanded forces the child to the full 600.
    expect(tester.getSize(find.byKey(const Key('s'))).height, 600);
    expect(find.byType(Expanded), findsOneWidget);
  });

  testWidgets('bounded height: two stretch children split the height',
      (tester) async {
    await tester.pumpWidget(
      host(
        maxHeight: 600,
        child: [
          buildStretchableColumn(
            childMaps: const [
              {'type': 'X', 'height': 'stretch'},
              {'type': 'Y', 'height': 'stretch'},
            ],
            children: const [
              SizedBox(key: Key('a'), height: 10),
              SizedBox(key: Key('b'), height: 10),
            ],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
        ],
      ),
    );
    expect(tester.getSize(find.byKey(const Key('a'))).height, 300);
    expect(tester.getSize(find.byKey(const Key('b'))).height, 300);
  });

  testWidgets('unbounded height: stretch degrades to auto, no Expanded',
      (tester) async {
    await tester.pumpWidget(
      host(
        maxHeight: null,
        child: [
          buildStretchableColumn(
            childMaps: const [
              {'type': 'X', 'height': 'stretch'},
            ],
            children: const [SizedBox(key: Key('s'), height: 10)],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Expanded), findsNothing);
    expect(tester.getSize(find.byKey(const Key('s'))).height, 10);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm flutter test test/cards/stretchable_column_test.dart`
Expected: FAIL — `stretchable_column.dart` does not exist.

- [ ] **Step 3: Implement**

Create `lib/src/cards/stretchable_column.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/block_height.dart';

/// Builds a vertical stack where children whose JSON requests
/// `height: "stretch"` fill the available main-axis space — but only when the
/// stack is height-bounded.
///
/// [childMaps] is the raw element JSON, index-aligned with [children]. When the
/// incoming `maxHeight` is finite and at least one child is a stretch child,
/// stretch children are wrapped in [Expanded] (sharing the slack equally) and the
/// rest keep their natural size. When the height is unbounded (the common
/// content-sized card body), `stretch` has nothing to fill, so a plain [Column]
/// is returned (stretch degrades to `auto`) — this also avoids the
/// "Expanded in an unbounded Column throws" trap.
Widget buildStretchableColumn({
  required List<Map<String, dynamic>> childMaps,
  required List<Widget> children,
  required MainAxisAlignment mainAxisAlignment,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  MainAxisSize mainAxisSize = MainAxisSize.max,
}) {
  final stretchFlags = [
    for (var i = 0; i < children.length; i++)
      i < childMaps.length && isStretchHeight(childMaps[i]),
  ];
  final hasStretch = stretchFlags.contains(true);

  Column plain() => Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );

  if (!hasStretch) return plain();

  return LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.maxHeight.isFinite) return plain();
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: [
          for (var i = 0; i < children.length; i++)
            if (stretchFlags[i])
              Expanded(child: children[i])
            else
              children[i],
        ],
      );
    },
  );
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `fvm flutter test test/cards/stretchable_column_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/stretchable_column.dart \
  packages/flutter_adaptive_cards_fs/test/cards/stretchable_column_test.dart
git commit -m "feat(layout): buildStretchableColumn (height:stretch in bounded contexts)"
```

---

## Task 3: Wire `height: stretch` into Container, Column, and the card root body

**Files:**
- Modify: `lib/src/cards/containers/container.dart`
- Modify: `lib/src/cards/containers/column.dart`
- Modify: `lib/src/cards/adaptive_card_element.dart`
- Test: `test/responsive/responsive_widget_test.dart`

Each site already builds its children from item JSON; we add a parallel
`childMaps` list (index-aligned) and route the stack through
`buildStretchableColumn`.

- [ ] **Step 1: Write the failing test**

Add to `test/responsive/responsive_widget_test.dart` a builder above `main()`:

```dart
Map<String, dynamic> _stretchContainerCard() => {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Container',
          'minHeight': '300px',
          'items': [
            {'type': 'TextBlock', 'text': 'top'},
            {
              'type': 'Container',
              'height': 'stretch',
              'items': [{'type': 'TextBlock', 'text': 'filler'}],
            },
          ],
        },
      ],
    };
```

and a test in `main()`:

```dart
  testWidgets('height:stretch child fills a minHeight container', (tester) async {
    // Bounded surface so the outer Container's minHeight provides slack.
    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _stretchContainerCard(), title: 'stretch'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Expanded), findsWidgets);
    expect(find.text('filler'), findsOneWidget);
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm flutter test test/responsive/responsive_widget_test.dart -p vm --plain-name "height:stretch child fills"`
Expected: FAIL — no `Expanded` (stretch not wired yet).

- [ ] **Step 3: Container — thread `childMaps` + stretchable stack**

In `lib/src/cards/containers/container.dart`:

(a) Add a field next to `late List<Widget> children;`:

```dart
  /// Raw item JSON, index-aligned with [children] (for stretch + AreaGrid).
  late List<Map<String, dynamic>> childMaps;
```

(b) In `didChangeDependencies`, where `children` is built, set `childMaps` from the
same source:

```dart
    if (adaptiveMap['items'] != null) {
      childMaps = List<Map<String, dynamic>>.from(adaptiveMap['items']);
      children = childMaps
          .map((child) => cardTypeRegistry.getElement(map: child))
          .toList();
    } else {
      childMaps = [];
      children = [];
    }
```

(c) In `build`, change the `stackBuilder` to use `buildStretchableColumn`:

```dart
        stackBuilder: (items) => buildStretchableColumn(
          childMaps: childMaps,
          children: items,
          mainAxisAlignment: verticalContentAlignment,
        ),
```

(d) Add import:

```dart
import 'package:flutter_adaptive_cards_fs/src/cards/stretchable_column.dart';
```

- [ ] **Step 4: Column — same treatment**

In `lib/src/cards/containers/column.dart`:

(a) Add a field next to `late List<Widget> items;`:

```dart
  /// Raw item JSON, index-aligned with [items].
  late List<Map<String, dynamic>> itemMaps;
```

(b) In `didChangeDependencies`, build `itemMaps` alongside `items`:

```dart
    itemMaps = adaptiveMap['items'] != null
        ? List<Map<String, dynamic>>.from(adaptiveMap['items'])
        : <Map<String, dynamic>>[];
    items = itemMaps
        .map((child) => cardTypeRegistry.getElement(map: child, parentMode: mode))
        .toList();
```

(c) In `build`, change the `stackBuilder` to:

```dart
          stackBuilder: (children) => buildStretchableColumn(
            childMaps: itemMaps,
            children: children,
            mainAxisAlignment: verticalAlignment,
            crossAxisAlignment: horizontalAlignment,
            mainAxisSize: MainAxisSize.max,
          ),
```

(d) Add import:

```dart
import 'package:flutter_adaptive_cards_fs/src/cards/stretchable_column.dart';
```

- [ ] **Step 5: Card root body — same treatment**

In `lib/src/cards/adaptive_card_element.dart`:

(a) The state builds `bodyChildren` from `adaptiveMap['body']`. Add a field next to
`late List<Widget> bodyChildren;`:

```dart
  /// Raw body JSON, index-aligned with [bodyChildren].
  late List<Map<String, dynamic>> bodyMaps;
```

and set it in `didChangeDependencies` where `bodyChildren` is built:

```dart
    bodyMaps = List<Map<String, dynamic>>.from(adaptiveMap['body']);
    bodyChildren = bodyMaps
        .map((map) => cardTypeRegistry.getElement(map: map))
        .toList();
```

(b) `_AdaptiveCardBody` builds the body stack. Give it the maps: add a field
`final List<Map<String, dynamic>> childMaps;` to `_AdaptiveCardBody`, pass it at the
construction site (`bodyLayout = _AdaptiveCardBody(bodyItems: bodyItems, childMaps: bodyMaps, layouts: ..., styleResolver: ...)`), and change its `stackBuilder` to:

```dart
      stackBuilder: (items) => buildStretchableColumn(
        childMaps: childMaps,
        children: items,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
```

> NOTE: `bodyItems` must stay index-aligned with `bodyMaps`. If the body construction
> filters or reorders items, build `childMaps` with the *same* transformation so
> indices line up. (As of this writing `bodyItems` is `bodyChildren` mapped 1:1.)

(c) Add import:

```dart
import 'package:flutter_adaptive_cards_fs/src/cards/stretchable_column.dart';
```

- [ ] **Step 6: Run the new test + full responsive/container suites**

Run: `fvm flutter test test/responsive/ test/cards/`
Expected: PASS, including `height:stretch child fills a minHeight container`.

- [ ] **Step 7: Analyze**

Run: `fvm flutter analyze lib/src/cards/ test/responsive/ test/cards/`
Expected: No issues.

- [ ] **Step 8: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/containers/container.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/containers/column.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart
git commit -m "feat(layout): height:stretch on Container/Column/root body"
```

---

# PHASE 2 — `Layout.AreaGrid`

## Task 4: AreaGrid model parse

**Files:**
- Create: `lib/src/responsive/area_grid_model.dart`
- Test: `test/responsive/area_grid_model_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses areas with defaults', () {
    final layout = AreaGridLayout.fromMap(const {
      'type': 'Layout.AreaGrid',
      'columns': [20, '40px', 40],
      'areas': [
        {'name': 'a', 'columnSpan': 2},
        {'name': 'b', 'column': 3, 'row': 2, 'rowSpan': 2},
      ],
    });
    expect(layout.columns.length, 3);
    expect(layout.columns[0].isPercent, isTrue);
    expect(layout.columns[0].value, 20);
    expect(layout.columns[1].isPercent, isFalse); // px
    expect(layout.columns[1].value, 40);
    final a = layout.areas[0];
    expect(a.name, 'a');
    expect(a.column, 1); // default
    expect(a.columnSpan, 2);
    expect(a.row, 1); // default
    expect(a.rowSpan, 1); // default
    final b = layout.areas[1];
    expect(b.column, 3);
    expect(b.row, 2);
    expect(b.rowSpan, 2);
  });

  test('tolerates missing/garbage fields', () {
    final layout = AreaGridLayout.fromMap(const {'type': 'Layout.AreaGrid'});
    expect(layout.columns, isEmpty);
    expect(layout.areas, isEmpty);
    final clamped = AreaGridLayout.fromMap(const {
      'areas': [
        {'name': 'x', 'column': 0, 'columnSpan': 0, 'row': -1, 'rowSpan': 0},
      ],
    });
    final x = clamped.areas.single;
    expect(x.column, 1); // clamped to >= 1
    expect(x.columnSpan, 1);
    expect(x.row, 1);
    expect(x.rowSpan, 1);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm flutter test test/responsive/area_grid_model_test.dart`
Expected: FAIL — model does not exist.

- [ ] **Step 3: Implement**

Create `lib/src/responsive/area_grid_model.dart`:

```dart
/// A single column track of a `Layout.AreaGrid`: either a percentage of the
/// available width (`isPercent == true`) or a fixed pixel width.
class AreaGridTrack {
  const AreaGridTrack({required this.value, required this.isPercent});

  /// The numeric width (percent points when [isPercent], else logical pixels).
  final double value;

  /// Whether [value] is a percentage of available width (vs. fixed pixels).
  final bool isPercent;

  /// Parses one `columns` entry: a number → percent; a `"<n>px"` string → pixels.
  /// Unparseable entries default to an equal-share percent of 0 (treated as
  /// implied by the solver).
  static AreaGridTrack? fromJson(Object? raw) {
    if (raw is num) return AreaGridTrack(value: raw.toDouble(), isPercent: true);
    if (raw is String) {
      final t = raw.trim();
      final body = t.toLowerCase().endsWith('px')
          ? t.substring(0, t.length - 2).trim()
          : t;
      final n = double.tryParse(body);
      if (n == null) return null;
      return AreaGridTrack(value: n, isPercent: !t.toLowerCase().endsWith('px'));
    }
    return null;
  }
}

/// A named placement region in a `Layout.AreaGrid`. Indices are 1-based.
class GridAreaModel {
  const GridAreaModel({
    required this.name,
    required this.column,
    required this.columnSpan,
    required this.row,
    required this.rowSpan,
  });

  /// Area name; matched against an element's `grid.area`.
  final String name;

  /// 1-based start column / row and their spans (each clamped to >= 1).
  final int column;
  final int columnSpan;
  final int row;
  final int rowSpan;

  static int _posInt(Object? v, int fallback) {
    final n = v is num ? v.toInt() : fallback;
    return n < 1 ? 1 : n;
  }

  /// Parses one `areas` entry, applying spec defaults (column/row 1, spans 1)
  /// and clamping non-positive values to 1.
  factory GridAreaModel.fromJson(Map<String, dynamic> json) => GridAreaModel(
        name: (json['name'] as String?) ?? '',
        column: _posInt(json['column'], 1),
        columnSpan: _posInt(json['columnSpan'], 1),
        row: _posInt(json['row'], 1),
        rowSpan: _posInt(json['rowSpan'], 1),
      );
}

/// Parsed `Layout.AreaGrid` object (tracks, named areas, spacing tokens).
class AreaGridLayout {
  const AreaGridLayout({
    required this.columns,
    required this.areas,
    required this.columnSpacing,
    required this.rowSpacing,
  });

  /// Declared column tracks (may be fewer than the grid's total columns).
  final List<AreaGridTrack> columns;

  /// Named areas elements are placed into via `grid.area`.
  final List<GridAreaModel> areas;

  /// Spacing tokens (HostConfig spacing names; resolved to pixels by the widget).
  final String? columnSpacing;
  final String? rowSpacing;

  /// Parses a selected `Layout.AreaGrid` map. Unparseable `columns` entries are
  /// dropped (the solver treats the shortfall as implied equal-share columns).
  factory AreaGridLayout.fromMap(Map<String, dynamic> map) {
    final cols = <AreaGridTrack>[];
    for (final c in (map['columns'] as List<dynamic>? ?? const [])) {
      final t = AreaGridTrack.fromJson(c);
      if (t != null) cols.add(t);
    }
    final areas = <GridAreaModel>[];
    for (final a in (map['areas'] as List<dynamic>? ?? const [])) {
      if (a is Map) {
        areas.add(GridAreaModel.fromJson(Map<String, dynamic>.from(a)));
      }
    }
    return AreaGridLayout(
      columns: cols,
      areas: areas,
      columnSpacing: map['columnSpacing'] as String?,
      rowSpacing: map['rowSpacing'] as String?,
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `fvm flutter test test/responsive/area_grid_model_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/area_grid_model.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/area_grid_model_test.dart
git commit -m "feat(areagrid): parse Layout.AreaGrid model"
```

---

## Task 5: AreaGrid solver (pure column widths + grid dimensions)

**Files:**
- Create: `lib/src/responsive/area_grid_solver.dart`
- Test: `test/responsive/area_grid_solver_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grid dimensions from areas (max index + span)', () {
    final areas = [
      const GridAreaModel(name: 'a', column: 1, columnSpan: 2, row: 1, rowSpan: 1),
      const GridAreaModel(name: 'b', column: 3, columnSpan: 1, row: 2, rowSpan: 2),
    ];
    expect(gridColumnCount(declaredColumns: 0, areas: areas), 3);
    expect(gridRowCount(areas), 3); // row 2 + rowSpan 2 - 1
  });

  test('column widths: percent of available, px fixed, implied split remainder', () {
    final cols = [
      const AreaGridTrack(value: 50, isPercent: true), // 50% of 200 = 100
      const AreaGridTrack(value: 40, isPercent: false), // 40px
    ];
    // colCount 3 → one implied column gets the remainder.
    final widths = resolveColumnWidths(
      columns: cols,
      colCount: 3,
      availableWidth: 200,
    );
    expect(widths, [100, 40, 60]); // 200 - 100 - 40 = 60 for the implied col
  });

  test('all implied columns split equally', () {
    final widths = resolveColumnWidths(
      columns: const [],
      colCount: 4,
      availableWidth: 200,
    );
    expect(widths, [50, 50, 50, 50]);
  });

  test('negative remainder clamps implied columns to 0', () {
    final widths = resolveColumnWidths(
      columns: const [AreaGridTrack(value: 300, isPercent: false)],
      colCount: 2,
      availableWidth: 200,
    );
    expect(widths, [300, 0]);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm flutter test test/responsive/area_grid_solver_test.dart`
Expected: FAIL — solver does not exist.

- [ ] **Step 3: Implement**

Create `lib/src/responsive/area_grid_solver.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';

/// Total column count: the larger of the declared columns and the furthest
/// column reached by any area (`column + columnSpan - 1`).
int gridColumnCount({
  required int declaredColumns,
  required List<GridAreaModel> areas,
}) {
  var maxCol = declaredColumns;
  for (final a in areas) {
    maxCol = math.max(maxCol, a.column + a.columnSpan - 1);
  }
  return math.max(maxCol, 1);
}

/// Total row count: the furthest row reached by any area (`row + rowSpan - 1`).
int gridRowCount(List<GridAreaModel> areas) {
  var maxRow = 1;
  for (final a in areas) {
    maxRow = math.max(maxRow, a.row + a.rowSpan - 1);
  }
  return maxRow;
}

/// Resolves per-column pixel widths for [colCount] columns across
/// [availableWidth] (the content width already net of column spacing).
///
/// Declared `px` tracks take their fixed width; declared `%` tracks take that
/// percentage of [availableWidth]; any remaining (implied) columns split the
/// leftover space equally. Widths are clamped to >= 0.
List<double> resolveColumnWidths({
  required List<AreaGridTrack> columns,
  required int colCount,
  required double availableWidth,
}) {
  final widths = List<double>.filled(colCount, 0);
  var used = 0.0;
  for (var i = 0; i < colCount; i++) {
    if (i < columns.length) {
      final t = columns[i];
      final w = t.isPercent ? availableWidth * (t.value / 100.0) : t.value;
      widths[i] = math.max(0, w);
      used += widths[i];
    }
  }
  final impliedCount = colCount - columns.length;
  if (impliedCount > 0) {
    final each = math.max(0, (availableWidth - used) / impliedCount);
    for (var i = columns.length; i < colCount; i++) {
      widths[i] = each;
    }
  }
  return widths;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `fvm flutter test test/responsive/area_grid_solver_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/area_grid_solver.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/area_grid_solver_test.dart
git commit -m "feat(areagrid): pure column-width + grid-dimension solver"
```

---

## Task 6: `AdaptiveAreaGrid` widget + `RenderAdaptiveAreaGrid`

**Files:**
- Create: `lib/src/responsive/adaptive_area_grid.dart`
- Test: `test/responsive/area_grid_widget_test.dart`

This task builds the renderer. The widget partitions children into *placed* (valid
`grid.area`) and *unplaced* (missing/unknown), renders placed children through the
custom `RenderBox`, and appends unplaced children in a `Column` below (logged).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_area_grid.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resolver = ReferenceResolver(
    hostConfigs: HostConfigs(),
    colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
  );

  Widget host(Widget child, {double width = 400}) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      );

  AreaGridLayout twoColLayout() => AreaGridLayout.fromMap(const {
        'type': 'Layout.AreaGrid',
        'columns': [50, 50],
        'areas': [
          {'name': 'left', 'column': 1},
          {'name': 'right', 'column': 2},
        ],
      });

  testWidgets('places children side-by-side by grid.area', (tester) async {
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: twoColLayout(),
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'left'},
          {'grid.area': 'right'},
        ],
        children: const [
          SizedBox(key: Key('l'), height: 30),
          SizedBox(key: Key('r'), height: 50),
        ],
      ),
    ));
    final l = tester.getTopLeft(find.byKey(const Key('l')));
    final r = tester.getTopLeft(find.byKey(const Key('r')));
    expect(l.dy, r.dy); // same row
    expect(r.dx, greaterThan(l.dx)); // right is to the right
    expect(tester.getSize(find.byKey(const Key('l'))).width, 200); // 50% of 400
  });

  testWidgets('height:stretch child fills its row band', (tester) async {
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: twoColLayout(),
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'left', 'height': 'stretch'},
          {'grid.area': 'right'},
        ],
        children: const [
          SizedBox(key: Key('l'), height: 10),
          SizedBox(key: Key('r'), height: 80),
        ],
      ),
    ));
    // The stretch cell grows to the row height set by the taller sibling (80).
    expect(tester.getSize(find.byKey(const Key('l'))).height, 80);
  });

  testWidgets('unplaced/unknown grid.area renders in fallback stack',
      (tester) async {
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: twoColLayout(),
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'left'},
          {'grid.area': 'nope'}, // unknown
          {}, // no grid.area
        ],
        children: const [
          SizedBox(key: Key('l'), height: 10),
          Text('orphan1'),
          Text('orphan2'),
        ],
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('orphan1'), findsOneWidget);
    expect(find.text('orphan2'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm flutter test test/responsive/area_grid_widget_test.dart`
Expected: FAIL — `adaptive_area_grid.dart` does not exist.

- [ ] **Step 3: Implement**

Create `lib/src/responsive/adaptive_area_grid.dart`:

```dart
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_solver.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/block_height.dart';

/// Placement + stretch flag for one placed grid child (1-based indices).
class AreaGridPlacement {
  const AreaGridPlacement({
    required this.column,
    required this.columnSpan,
    required this.row,
    required this.rowSpan,
    required this.stretch,
  });
  final int column;
  final int columnSpan;
  final int row;
  final int rowSpan;
  final bool stretch;
}

/// Renders a container's children as a `Layout.AreaGrid`.
///
/// Children whose `grid.area` matches a named area are placed (and spanned) by a
/// custom [RenderAdaptiveAreaGrid]; children with a missing or unknown
/// `grid.area` are not dropped — they render in a fallback [Column] below the grid
/// (and are logged), mirroring the fail-open `targetWidth` philosophy.
class AdaptiveAreaGrid extends StatelessWidget {
  const AdaptiveAreaGrid({
    required this.layout,
    required this.styleResolver,
    required this.childMaps,
    required this.children,
    super.key,
  });

  final AreaGridLayout layout;
  final ReferenceResolver styleResolver;

  /// Raw item JSON, index-aligned with [children].
  final List<Map<String, dynamic>> childMaps;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final areasByName = {for (final a in layout.areas) a.name: a};
    final colCount = gridColumnCount(
      declaredColumns: layout.columns.length,
      areas: layout.areas,
    );
    final rowCount = gridRowCount(layout.areas);

    final placed = <Widget>[];
    final placements = <AreaGridPlacement>[];
    final unplaced = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      final map = i < childMaps.length ? childMaps[i] : const <String, dynamic>{};
      final areaName = map['grid.area'] as String?;
      final area = areaName == null ? null : areasByName[areaName];
      if (area == null) {
        if (areaName != null) {
          developer.log(
            'grid.area "$areaName" matches no area; rendering below the grid',
            name: 'responsive.area_grid',
          );
        }
        unplaced.add(children[i]);
        continue;
      }
      placed.add(children[i]);
      placements.add(
        AreaGridPlacement(
          column: area.column,
          columnSpan: area.columnSpan,
          row: area.row,
          rowSpan: area.rowSpan,
          stretch: isStretchHeight(map),
        ),
      );
    }

    final grid = placed.isEmpty
        ? const SizedBox.shrink()
        : _AreaGridRenderWidget(
            columns: layout.columns,
            colCount: colCount,
            rowCount: rowCount,
            columnSpacing: styleResolver.resolveSpacing(layout.columnSpacing),
            rowSpacing: styleResolver.resolveSpacing(layout.rowSpacing),
            placements: placements,
            children: placed,
          );

    if (unplaced.isEmpty) return grid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [grid, ...unplaced],
    );
  }
}

class _AreaGridParentData extends ContainerBoxParentData<RenderBox> {
  AreaGridPlacement? placement;
}

class _AreaGridRenderWidget extends MultiChildRenderObjectWidget {
  const _AreaGridRenderWidget({
    required this.columns,
    required this.colCount,
    required this.rowCount,
    required this.columnSpacing,
    required this.rowSpacing,
    required this.placements,
    required super.children,
  });

  final List<AreaGridTrack> columns;
  final int colCount;
  final int rowCount;
  final double columnSpacing;
  final double rowSpacing;
  final List<AreaGridPlacement> placements;

  @override
  RenderAdaptiveAreaGrid createRenderObject(BuildContext context) =>
      RenderAdaptiveAreaGrid(
        columns: columns,
        colCount: colCount,
        rowCount: rowCount,
        columnSpacing: columnSpacing,
        rowSpacing: rowSpacing,
        placements: placements,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAdaptiveAreaGrid renderObject,
  ) {
    renderObject
      ..columns = columns
      ..colCount = colCount
      ..rowCount = rowCount
      ..columnSpacing = columnSpacing
      ..rowSpacing = rowSpacing
      ..placements = placements;
  }
}

/// Custom grid layout: resolves column widths, sizes rows (content + spans),
/// fills `height:stretch` cells to their row band, and positions each child.
class RenderAdaptiveAreaGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AreaGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AreaGridParentData> {
  RenderAdaptiveAreaGrid({
    required List<AreaGridTrack> columns,
    required int colCount,
    required int rowCount,
    required double columnSpacing,
    required double rowSpacing,
    required List<AreaGridPlacement> placements,
  })  : _columns = columns,
        _colCount = colCount,
        _rowCount = rowCount,
        _columnSpacing = columnSpacing,
        _rowSpacing = rowSpacing,
        _placements = placements;

  List<AreaGridTrack> _columns;
  set columns(List<AreaGridTrack> v) {
    _columns = v;
    markNeedsLayout();
  }

  int _colCount;
  set colCount(int v) {
    if (_colCount != v) {
      _colCount = v;
      markNeedsLayout();
    }
  }

  int _rowCount;
  set rowCount(int v) {
    if (_rowCount != v) {
      _rowCount = v;
      markNeedsLayout();
    }
  }

  double _columnSpacing;
  set columnSpacing(double v) {
    if (_columnSpacing != v) {
      _columnSpacing = v;
      markNeedsLayout();
    }
  }

  double _rowSpacing;
  set rowSpacing(double v) {
    if (_rowSpacing != v) {
      _rowSpacing = v;
      markNeedsLayout();
    }
  }

  List<AreaGridPlacement> _placements;
  set placements(List<AreaGridPlacement> v) {
    _placements = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _AreaGridParentData) {
      child.parentData = _AreaGridParentData();
    }
  }

  /// Assigns placements to children by order and returns each child's parentData.
  void _assignPlacements() {
    var i = 0;
    var child = firstChild;
    while (child != null) {
      final pd = child.parentData! as _AreaGridParentData;
      pd.placement = i < _placements.length ? _placements[i] : null;
      child = pd.nextSibling;
      i++;
    }
  }

  @override
  void performLayout() {
    _assignPlacements();
    final maxWidth = constraints.maxWidth;
    final availableWidth =
        maxWidth - _columnSpacing * (_colCount - 1).clamp(0, _colCount);
    final colWidths = resolveColumnWidths(
      columns: _columns,
      colCount: _colCount,
      availableWidth: availableWidth.isFinite ? availableWidth : 0,
    );

    double cellWidth(AreaGridPlacement p) {
      var w = 0.0;
      for (var c = p.column - 1;
          c < p.column - 1 + p.columnSpan && c < colWidths.length;
          c++) {
        w += colWidths[c];
      }
      w += _columnSpacing * (p.columnSpan - 1);
      return w;
    }

    // Pass 1: measure non-stretch children; seed single-row heights.
    final rowHeights = List<double>.filled(_rowCount, 0);
    final childList = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      childList.add(child);
      child = (child.parentData! as _AreaGridParentData).nextSibling;
    }

    for (final c in childList) {
      final pd = c.parentData! as _AreaGridParentData;
      final p = pd.placement;
      if (p == null) continue;
      if (p.stretch) continue; // deferred to pass 2
      c.layout(
        BoxConstraints(maxWidth: cellWidth(p), maxHeight: double.infinity)
            .tighten(width: cellWidth(p)),
        parentUsesSize: true,
      );
      if (p.rowSpan == 1) {
        final r = p.row - 1;
        if (r >= 0 && r < _rowCount) {
          rowHeights[r] = rowHeights[r] > c.size.height
              ? rowHeights[r]
              : c.size.height;
        }
      }
    }

    // Pass 1b: grow rows so multi-row non-stretch children fit.
    for (final c in childList) {
      final pd = c.parentData! as _AreaGridParentData;
      final p = pd.placement;
      if (p == null || p.stretch || p.rowSpan == 1) continue;
      var spanned = _rowSpacing * (p.rowSpan - 1);
      for (var r = p.row - 1; r < p.row - 1 + p.rowSpan && r < _rowCount; r++) {
        spanned += rowHeights[r];
      }
      final deficit = c.size.height - spanned;
      if (deficit > 0) {
        final add = deficit / p.rowSpan;
        for (var r = p.row - 1; r < p.row - 1 + p.rowSpan && r < _rowCount; r++) {
          rowHeights[r] += add;
        }
      }
    }

    // Row y-offsets.
    final rowOffsets = List<double>.filled(_rowCount, 0);
    var y = 0.0;
    for (var r = 0; r < _rowCount; r++) {
      rowOffsets[r] = y;
      y += rowHeights[r] + (r < _rowCount - 1 ? _rowSpacing : 0);
    }
    final totalHeight = y;

    // Column x-offsets.
    final colOffsets = List<double>.filled(_colCount, 0);
    var x = 0.0;
    for (var c = 0; c < _colCount; c++) {
      colOffsets[c] = x;
      x += colWidths[c] + (c < _colCount - 1 ? _columnSpacing : 0);
    }

    double cellHeight(AreaGridPlacement p) {
      var h = _rowSpacing * (p.rowSpan - 1);
      for (var r = p.row - 1; r < p.row - 1 + p.rowSpan && r < _rowCount; r++) {
        h += rowHeights[r];
      }
      return h;
    }

    // Pass 2: lay out stretch children to full cell height; position everyone.
    for (final c in childList) {
      final pd = c.parentData! as _AreaGridParentData;
      final p = pd.placement;
      if (p == null) {
        pd.offset = Offset.zero;
        c.layout(const BoxConstraints.tightFor(width: 0, height: 0));
        continue;
      }
      if (p.stretch) {
        c.layout(
          BoxConstraints.tightFor(width: cellWidth(p), height: cellHeight(p)),
        );
      }
      final colIdx = (p.column - 1).clamp(0, _colCount - 1);
      final rowIdx = (p.row - 1).clamp(0, _rowCount - 1);
      pd.offset = Offset(colOffsets[colIdx], rowOffsets[rowIdx]);
    }

    size = constraints.constrain(Size(maxWidth, totalHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `fvm flutter test test/responsive/area_grid_widget_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Analyze**

Run: `fvm flutter analyze lib/src/responsive/adaptive_area_grid.dart test/responsive/area_grid_widget_test.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/adaptive_area_grid.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/area_grid_widget_test.dart
git commit -m "feat(areagrid): RenderAdaptiveAreaGrid + AdaptiveAreaGrid widget"
```

---

## Task 7: Dispatch AreaGrid from `buildLayoutChildren` and wire build sites

**Files:**
- Modify: `lib/src/responsive/layout_children.dart`
- Modify: `container.dart`, `column.dart`, `adaptive_card_element.dart`, `table.dart`
- Test: `test/responsive/responsive_widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/responsive/responsive_widget_test.dart`:

```dart
Map<String, dynamic> _areaGridCard() => {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'layouts': [
        {
          'type': 'Layout.AreaGrid',
          'targetWidth': 'atLeast:standard',
          'columns': [50, 50],
          'areas': [
            {'name': 'l', 'column': 1},
            {'name': 'r', 'column': 2},
          ],
        },
      ],
      'body': [
        {'type': 'TextBlock', 'text': 'L', 'grid.area': 'l'},
        {'type': 'TextBlock', 'text': 'R', 'grid.area': 'r'},
      ],
    };
```

```dart
  testWidgets('root body uses AreaGrid when wide', (tester) async {
    await _pumpCardAtWidth(tester, _areaGridCard(), 1000);
    expect(find.byType(AdaptiveAreaGrid), findsOneWidget);
    final l = tester.getTopLeft(find.text('L'));
    final r = tester.getTopLeft(find.text('R'));
    expect(l.dy, r.dy);
    expect(r.dx, greaterThan(l.dx));
  });

  testWidgets('root body stacks (no AreaGrid) when narrow', (tester) async {
    await _pumpCardAtWidth(tester, _areaGridCard(), 150);
    expect(find.byType(AdaptiveAreaGrid), findsNothing);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
  });
```

Add the import to the test file if missing:
```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_area_grid.dart';
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm flutter test test/responsive/responsive_widget_test.dart --plain-name "AreaGrid"`
Expected: FAIL — AreaGrid not dispatched.

- [ ] **Step 3: Extend `buildLayoutChildren`**

Replace `lib/src/responsive/layout_children.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_area_grid.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// Lays out a container's [children] for the current width [bucket].
///
/// Chooses the best entry from [layouts] (see [selectLayout]): `Layout.Flow` →
/// [AdaptiveFlowLayout]; `Layout.AreaGrid` → [AdaptiveAreaGrid] (needs
/// [childMaps] — the raw item JSON, index-aligned with [children] — to read each
/// child's `grid.area`); otherwise delegates to [stackBuilder] (the caller's own
/// stack), so non-layout rendering is unchanged. Callers pass
/// `ref.watch(cardWidthBucketProvider)` as [bucket] to reflow on resize.
Widget buildLayoutChildren({
  required List<dynamic>? layouts,
  required WidthBucket bucket,
  required ReferenceResolver styleResolver,
  required List<Widget> children,
  required Widget Function(List<Widget> children) stackBuilder,
  List<Map<String, dynamic>> childMaps = const [],
}) {
  final selected = selectLayout(layouts, bucket);
  if (selected != null) {
    if (selected['type'] == 'Layout.Flow') {
      return AdaptiveFlowLayout(
        layoutMap: selected,
        styleResolver: styleResolver,
        children: children,
      );
    }
    if (selected['type'] == 'Layout.AreaGrid') {
      return AdaptiveAreaGrid(
        layout: AreaGridLayout.fromMap(selected),
        styleResolver: styleResolver,
        childMaps: childMaps,
        children: children,
      );
    }
  }
  return stackBuilder(children);
}
```

- [ ] **Step 4: Pass `childMaps` at each build site**

- `container.dart`: add `childMaps: childMaps,` to the `buildLayoutChildren(...)` call.
- `column.dart`: add `childMaps: itemMaps,`.
- `adaptive_card_element.dart` (`_AdaptiveCardBody.build`): add `childMaps: childMaps,`.
- `table.dart` (`buildCellContent`): build a maps list aligned with `cellWidgets` and pass it. The cell items are `oneCellItems` (a `List<Map<String, dynamic>>`); pass `childMaps: oneCellItems,` to the `buildLayoutChildren(...)` call.

(These are additive named-arg additions; the default `const []` keeps any untouched caller working.)

- [ ] **Step 5: Run the test + full responsive suite**

Run: `fvm flutter test test/responsive/`
Expected: PASS, including the AreaGrid root-body tests.

- [ ] **Step 6: Analyze**

Run: `fvm flutter analyze lib/src/ test/responsive/`
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_children.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/containers/container.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/containers/column.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart \
  packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart \
  packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart
git commit -m "feat(areagrid): dispatch Layout.AreaGrid via buildLayoutChildren; thread childMaps"
```

---

## Task 8: Sample card, golden test, widgetbook

**Files:**
- Create: `test/samples/responsive/area_grid.json`
- Create: `test/golden_area_grid_test.dart`
- Create: `widgetbook/lib/samples/responsive/area_grid.json` (identical copy)
- Modify: `widgetbook/lib/responsive_flow_page.dart`

- [ ] **Step 1: Create the sample card**

Create `test/samples/responsive/area_grid.json` (image-left / text-right at standard+,
stacks below; mirrors the MS sample):

```json
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "layouts": [
    {
      "type": "Layout.AreaGrid",
      "targetWidth": "atLeast:standard",
      "columns": [40, 60],
      "areas": [
        { "name": "image", "column": 1 },
        { "name": "text", "column": 2 }
      ]
    }
  ],
  "body": [
    { "type": "TextBlock", "text": "IMAGE", "grid.area": "image" },
    { "type": "TextBlock", "text": "Title and description text", "wrap": true, "grid.area": "text" }
  ]
}
```

- [ ] **Step 2: Create the golden test**

Create `test/golden_area_grid_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('Layout.AreaGrid golden — narrow (stacks)', (tester) async {
    configureTestView(size: const Size(160, 1200));
    const ValueKey key = ValueKey('paint');
    await tester.pumpWidget(getSampleForGoldenTest(key, 'responsive/area_grid'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('area_grid_narrow.png')),
    );
  }, tags: ['golden']);

  testWidgets('Layout.AreaGrid golden — wide (grid)', (tester) async {
    configureTestView(size: const Size(1000, 1200));
    const ValueKey key = ValueKey('paint');
    await tester.pumpWidget(getSampleForGoldenTest(key, 'responsive/area_grid'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('area_grid_wide.png')),
    );
  }, tags: ['golden']);
}
```

- [ ] **Step 3: Generate macOS baselines + verify**

Run: `fvm flutter test --update-goldens --tags=golden test/golden_area_grid_test.dart`
then `fvm flutter test --tags=golden test/golden_area_grid_test.dart`
Expected: creates `gold_files/macos/area_grid_{narrow,wide}.png`; second run PASS.

> Linux baselines must be regenerated on a Linux runner before merge (this repo keeps
> both `macos/` and `linux/` golden dirs). Copy the macOS files into `gold_files/linux/`
> as placeholders if you want the files present meanwhile.

- [ ] **Step 4: Widgetbook copy + picker entry**

- Create `widgetbook/lib/samples/responsive/area_grid.json` identical to the test copy.
- In `widgetbook/lib/responsive_flow_page.dart`, add to the `_samples` map:

```dart
    'AreaGrid (image + text)': 'lib/samples/responsive/area_grid.json',
```

- [ ] **Step 5: Verify widgetbook analyzes**

Run: `cd ../../widgetbook && fvm flutter analyze && cd ../packages/flutter_adaptive_cards_fs`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/test/samples/responsive/area_grid.json \
  packages/flutter_adaptive_cards_fs/test/golden_area_grid_test.dart \
  packages/flutter_adaptive_cards_fs/test/gold_files \
  widgetbook/lib/samples/responsive/area_grid.json \
  widgetbook/lib/responsive_flow_page.dart
git commit -m "test(areagrid): sample + golden + widgetbook picker entry"
```

---

## Task 9: Documentation + changelog

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/README.md`
- Modify: `docs/Implementation-Status.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [ ] **Step 1: README — Common properties**

In `packages/flutter_adaptive_cards_fs/README.md`:
- Update the `height` row (Common Properties) Notes to: `auto` ✅; `stretch` ✅ in **bounded contexts** (AreaGrid cells, ColumnSet columns, minHeight containers) — degrades to `auto` when the parent is unbounded; charts + in-cell `TableCell` content deferred.
- Update the `grid.area` row from ❌ Missing to ✅ Complete with note: placement via `Layout.AreaGrid`; unplaced/unknown areas render below the grid (logged).
- Update the `layouts` (`Layout.Flow`) row label/notes to also list **`Layout.AreaGrid`** ✅ (percent/px/implied columns, `columnSpan`/`rowSpan`, `targetWidth`-selected grids).

- [ ] **Step 2: Implementation-Status — move items to Recently completed**

In `docs/Implementation-Status.md`:
- Remove `Layout.AreaGrid` and block `height: stretch` from **High priority** (they were #1/#2). Leave a note that responsive layout is now feature-complete except `itemFit: "Fill"`.
- Add a **Recently completed** entry:

```
### Layout.AreaGrid + block height: stretch (2026-06-28)

Plans: [2026-06-28-areagrid-and-height-stretch.md](./superpowers/plans/2026-06-28-areagrid-and-height-stretch.md) — designs: [height: stretch](./superpowers/specs/2026-06-28-block-height-stretch-design.md), [Layout.AreaGrid](./superpowers/specs/2026-06-28-layout-areagrid-design.md).

- **`Layout.AreaGrid` + `grid.area`** via a bespoke `RenderAdaptiveAreaGrid` (no new core dependency): percent/px/implied columns, `columnSpan`/`rowSpan`, `targetWidth`-selected grids, fail-open fallback for unplaced elements. Reuses `selectLayout` + `cardWidthBucketProvider`.
- **Block `height: "stretch"`** on Container/Column/root body (bounded contexts; degrades to `auto` when unbounded) via `buildStretchableColumn` + shared `isStretchHeight`; AreaGrid cells consume it.
- Responsive layout is now feature-complete except `Layout.Flow` `itemFit: "Fill"`.
```

- [ ] **Step 3: CHANGELOG**

In `packages/flutter_adaptive_cards_fs/CHANGELOG.md`, under `### Added 0.13.0`, add:

```
- **`Layout.AreaGrid` + `grid.area`** — named-area responsive grids on Container/Column/TableCell/root via a custom `RenderAdaptiveAreaGrid` (no new dependency): `%`/`px`/implied columns, `columnSpan`/`rowSpan`, `columnSpacing`/`rowSpacing`, and multiple `targetWidth`-selected grids. Elements place via `grid.area`; unplaced/unknown areas render below the grid (logged). See `docs/superpowers/specs/2026-06-28-layout-areagrid-design.md`.
- **Block `height: "stretch"`** now honored on `Container`, `Column`, and the card root body in height-bounded contexts (AreaGrid cells, ColumnSet columns, minHeight containers); degrades to `auto` when the parent is unbounded. Charts and in-cell `TableCell` content deferred.
```

- [ ] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/README.md docs/Implementation-Status.md \
  packages/flutter_adaptive_cards_fs/CHANGELOG.md
git commit -m "docs(areagrid): record AreaGrid + height:stretch; update roadmap"
```

---

## Final Task: Full verification

- [ ] **Step 1: Analyze (repo root)**

Run: `cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && fvm flutter analyze`
Expected: No issues.

- [ ] **Step 2: Core non-golden tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`
Expected: all pass.

- [ ] **Step 3: Golden tests**

Run: `fvm flutter test --tags=golden`
Expected: PASS (macOS baselines present; linux regenerated on a Linux runner before merge).

- [ ] **Step 4: Coverage gate**

Run from repo root:
```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden --coverage && cd ../..
fvm dart run tool/coverage/check_coverage.dart
```
Expected: coverage floor met (add tests if short — do not lower floors).

- [ ] **Step 5: Widgetbook analyze**

Run: `cd widgetbook && fvm flutter analyze && cd ..`
Expected: No issues.

- [ ] **Step 6: Invoke `verification-before-completion`**

Paste exit codes + pass/fail counts before claiming completion. Do not report complete until the full suite passes.

---

## Self-Review notes (author)

- **Spec coverage (height:stretch):** predicate (Task 1), bounded/unbounded mechanism (Task 2), Container/Column/root wiring (Task 3), AreaGrid in-cell consumption (Task 6). TableCell-content stretch + charts deferred (per spec).
- **Spec coverage (AreaGrid):** model parse (Task 4), column/dimension solver (Task 5), RenderObject + placement + fallback + in-cell stretch (Task 6), selection + childMaps threading (Task 7), golden + sample + widgetbook (Task 8), docs (Task 9). Full v1.6 set (%+px+implied columns, columnSpan/rowSpan, targetWidth-selected grids, spacing, grid.area) covered.
- **Type consistency:** `isStretchHeight(Map)` (T1) used in T2/T6; `buildStretchableColumn({childMaps, children, mainAxisAlignment, crossAxisAlignment, mainAxisSize})` (T2) called identically in T3; `AreaGridLayout.fromMap` / `AreaGridTrack` / `GridAreaModel` (T4) used by solver (T5) and widget (T6/T7); `resolveColumnWidths` / `gridColumnCount` / `gridRowCount` (T5) used in T6; `AdaptiveAreaGrid({layout, styleResolver, childMaps, children})` (T6) constructed in T7; `buildLayoutChildren(..., childMaps)` (T7) called from all four build sites.
- **Known limitation (documented):** `RenderAdaptiveAreaGrid` implements `performLayout` (content-height, bounded width). It does not implement intrinsic-height, so an AreaGrid nested *directly* inside an `IntrinsicHeight` ancestor (uncommon) may misbehave; revisit if a real card needs it. Unbounded incoming width falls back to `Layout.Stack` selection upstream is not automatic — if width is non-finite the solver yields 0-width columns; acceptable because cards are width-bounded in practice (noted in the AreaGrid spec's open items).
```
