# Table `auto`/`stretch` Widths + Cell `minHeight` Implementation Plan

> **Status: ✅ Complete** — shipped in commit `05560c7` (`d8a2052`). Archived 2026-07-02.
> Checkbox state below is historical and was not ticked at merge time.

---

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render the Adaptive Cards `Table` through Flutter's `Table` widget so `auto` and `stretch` column widths work (cross-row consistent), and apply the parsed-but-ignored cell `minHeight`.

**Architecture:** Replace the per-row `IntrinsicHeight`+`Row` construction in `table.dart` with a single Flutter `Table`. A pure `mapColumnWidth()` helper maps the four Adaptive Cards width modes to `TableColumnWidth` types; `TableCellVerticalAlignment.intrinsicHeight` preserves equal-row-height and per-cell background fill; `TableBorder` replaces manual divider/spacer children.

**Tech Stack:** Dart, Flutter (`Table`/`TableRow`/`TableColumnWidth`), Riverpod, `flutter_test`, FVM (all commands prefixed `fvm`), `very_good_analysis`.

**Spec:** `docs/superpowers/specs/2026-06-29-table-auto-stretch-minheight-design.md` (commit this spec with the first code commit — it is currently uncommitted).

---

## File Structure

- **Create** `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table_column_width.dart` — two pure, widget-free helpers: `mapColumnWidth(Object?)` and `parseCellMinHeightPx(String?)`.
- **Create** `packages/flutter_adaptive_cards_fs/test/containers/table_column_width_test.dart` — unit tests for the two helpers.
- **Modify** `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart` — rewrite `build()` and cell construction to use `Table`.
- **Modify** `packages/flutter_adaptive_cards_fs/test/containers/table_test.dart` — replace the `Expanded.flex` width test; add `auto`/`stretch`/`minHeight`/`backgroundImage`/ragged-row/grid-line tests.
- **Create** `packages/flutter_adaptive_cards_fs/test/samples/table3_widths.json` — sample exercising mixed widths + styled cell + `minHeight`.
- **Modify** `packages/flutter_adaptive_cards_fs/test/golden_sample_test.dart` — add a golden for the new sample.
- **Modify** docs + changelog (Task 8).

> **Commit gate:** This repo requires explicit user confirmation before each `git commit`/`git push`. Each "Commit" step below means *propose* the commit (show `git diff`/`--stat`) and wait for confirmation.

---

### Task 1: Pure column-width + minHeight helpers

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table_column_width.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/containers/table_column_width_test.dart`

- [ ] **Step 1: Write the failing test**

Create `packages/flutter_adaptive_cards_fs/test/containers/table_column_width_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/containers/table_column_width.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // NOTE: TableColumnWidth subclasses do NOT override `==`, so assert on the
  // runtime type and the public `value` field rather than instance equality.
  Matcher isFlex(double value) =>
      isA<FlexColumnWidth>().having((w) => w.value, 'value', value);

  group('mapColumnWidth', () {
    test('"auto" maps to IntrinsicColumnWidth', () {
      expect(mapColumnWidth('auto'), isA<IntrinsicColumnWidth>());
    });

    test('"AUTO" is case-insensitive', () {
      expect(mapColumnWidth('AUTO'), isA<IntrinsicColumnWidth>());
    });

    test('"stretch" maps to flex 1', () {
      expect(mapColumnWidth('stretch'), isFlex(1.0));
    });

    test('positive number maps to flex weight', () {
      expect(mapColumnWidth(3), isFlex(3.0));
      expect(mapColumnWidth(2.5), isFlex(2.5));
    });

    test('zero or negative number falls back to flex 1', () {
      expect(mapColumnWidth(0), isFlex(1.0));
      expect(mapColumnWidth(-4), isFlex(1.0));
    });

    test('"Npx" maps to FixedColumnWidth', () {
      expect(
        mapColumnWidth('50px'),
        isA<FixedColumnWidth>().having((w) => w.value, 'value', 50.0),
      );
    });

    test('unparseable px falls back to flex 1', () {
      expect(mapColumnWidth('abcpx'), isFlex(1.0));
    });

    test('null and unknown strings fall back to flex 1', () {
      expect(mapColumnWidth(null), isFlex(1.0));
      expect(mapColumnWidth('weird'), isFlex(1.0));
    });
  });

  group('parseCellMinHeightPx', () {
    test('parses "80px"', () {
      expect(parseCellMinHeightPx('80px'), 80.0);
    });

    test('parses a bare number string', () {
      expect(parseCellMinHeightPx('120'), 120.0);
    });

    test('returns null for null, empty, or non-positive', () {
      expect(parseCellMinHeightPx(null), isNull);
      expect(parseCellMinHeightPx('abc'), isNull);
      expect(parseCellMinHeightPx('0px'), isNull);
      expect(parseCellMinHeightPx('-5px'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_column_width_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../table_column_width.dart'`.

- [ ] **Step 3: Write minimal implementation**

Create `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table_column_width.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Maps an Adaptive Cards `Table` column `width` to a Flutter [TableColumnWidth].
///
/// Callers pass the raw `width` JSON value (a number or string). `"auto"` sizes
/// the column to its content; `"stretch"`, a missing value, or anything
/// unrecognized fills the remaining space (flex 1); a positive number is a flex
/// weight; `"Npx"` is a fixed pixel width. Keeping this pure (no widgets) lets
/// the width-mode branching be unit-tested without pumping a table.
TableColumnWidth mapColumnWidth(Object? width) {
  if (width is num) {
    return width > 0 ? FlexColumnWidth(width.toDouble()) : const FlexColumnWidth();
  }
  if (width is String) {
    final value = width.trim().toLowerCase();
    if (value == 'auto') return const IntrinsicColumnWidth();
    if (value == 'stretch') return const FlexColumnWidth();
    if (value.endsWith('px')) {
      final px = double.tryParse(value.substring(0, value.length - 2));
      if (px != null && px > 0) return FixedColumnWidth(px);
    }
  }
  return const FlexColumnWidth();
}

/// Parses an Adaptive Cards cell `minHeight` (e.g. `"80px"`) to a pixel value.
///
/// Returns null when the value is absent, unparseable, or non-positive so callers
/// can skip applying a constraint entirely.
double? parseCellMinHeightPx(String? minHeight) {
  if (minHeight == null) return null;
  final value = minHeight.trim().toLowerCase();
  final raw = value.endsWith('px')
      ? value.substring(0, value.length - 2)
      : value;
  final px = double.tryParse(raw);
  if (px == null || px <= 0) return null;
  return px;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_column_width_test.dart`
Expected: PASS (all cases).

- [ ] **Step 5: Analyze**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter analyze lib/src/cards/containers/table_column_width.dart test/containers/table_column_width_test.dart`
Expected: No issues.

- [ ] **Step 6: Commit** (propose, then wait for confirmation — include the spec file)

```bash
git add docs/superpowers/specs/2026-06-29-table-auto-stretch-minheight-design.md \
        packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table_column_width.dart \
        packages/flutter_adaptive_cards_fs/test/containers/table_column_width_test.dart
git commit -m "feat(table): add pure column-width + minHeight parse helpers"
```

---

### Task 2: Render the table through Flutter's `Table` widget

This is the core rewrite. It preserves every existing cell behavior (background color/image, header styling, `selectAction`, vertical/horizontal alignment, responsive `layouts`) while switching width handling to `Table`.

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart`
- Modify: `packages/flutter_adaptive_cards_fs/test/containers/table_test.dart`

- [ ] **Step 1: Replace the implementation-coupled width test with a `columnWidths` test**

In `test/containers/table_test.dart`, find the test that asserts `Expanded` flex via `columnKey` (the block ending around lines 300–306, asserting `tester.widget<Expanded>(...).flex`). Replace that whole `testWidgets(...)` block with:

```dart
    testWidgets('maps column widths onto Table.columnWidths', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 1},
              {'width': 2},
              {'width': 'auto'},
              {'width': '40px'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'a'}]},
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'b'}]},
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'c'}]},
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'd'}]},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Column Widths Test'),
      );
      await tester.pumpAndSettle();

      // TableColumnWidth subclasses don't override `==`; assert type + value.
      final table = tester.widget<Table>(find.byType(Table));
      expect(
        table.columnWidths![0],
        isA<FlexColumnWidth>().having((w) => w.value, 'value', 1.0),
      );
      expect(
        table.columnWidths![1],
        isA<FlexColumnWidth>().having((w) => w.value, 'value', 2.0),
      );
      expect(table.columnWidths![2], isA<IntrinsicColumnWidth>());
      expect(
        table.columnWidths![3],
        isA<FixedColumnWidth>().having((w) => w.value, 'value', 40.0),
      );
    });
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_test.dart -n "maps column widths"`
Expected: FAIL — no `Table` widget found (current code uses `Row`/`Expanded`).

- [ ] **Step 3: Rewrite `table.dart`**

Replace the entire contents of `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart` with:

```dart
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/containers/table_column_width.dart';
import 'package:flutter_adaptive_cards_fs/src/models/table_cell.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Table.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/table
///
/// Reasonable test schema is https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/FlightUpdateTable.json
///
/// Renders a `Table` with `auto`/`stretch`/numeric/pixel column widths, grid
/// lines, and optional header row styling from `firstRowAsHeader`. Column widths
/// are resolved across all rows by a single Flutter [Table], so `auto` columns
/// size to their widest content consistently.
class AdaptiveTable extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a `Table` from [adaptiveMap].
  AdaptiveTable({
    required this.adaptiveMap,
    required this.supportMarkdown,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  /// Whether nested text elements may render markdown.
  final bool supportMarkdown;

  @override
  AdaptiveTableState createState() => AdaptiveTableState();

  /// Widget key for a table column at index [col]. Retained for backward
  /// compatibility; the Flutter [Table] owns column sizing, so this key is no
  /// longer attached to a per-column widget.
  static ValueKey<String> columnKey(String tableKey, int col) =>
      ValueKey('${tableKey}_col_$col');

  /// Widget key for the cell at [rowIndex], [col].
  static ValueKey<String> cellKey(String tableKey, int rowIndex, int col) =>
      ValueKey('${tableKey}_${rowIndex}_$col');

  /// Local key for the row at [rowIndex] (set on the [TableRow]).
  static ValueKey<String> rowKey(String tableKey, int rowIndex) =>
      ValueKey('${tableKey}_row_$rowIndex');

  /// Widget key for the [Table] that wraps all rows.
  static ValueKey<String> tableColumnKey(String tableKey) =>
      ValueKey('${tableKey}_column');
}

/// State for [AdaptiveTable].
class AdaptiveTableState extends ConsumerState<AdaptiveTable>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Column width definitions from `columns`.
  late List<Map<String, dynamic>> columns;

  /// Table row payloads from `rows`.
  late List<Map<String, dynamic>> rows;

  /// Whether grid lines are drawn between cells (`showGridLines`).
  late bool showGridLines;

  /// Grid line color style token from `gridStyle`.
  late String gridStyle;

  /// Whether the first row uses header styling (`firstRowAsHeader`).
  late bool firstRowAsHeader;

  /// Default vertical cell alignment from `verticalCellContentAlignment`.
  late String? verticalCellAlignment;

  @override
  void initState() {
    super.initState();
    columns = List<Map<String, dynamic>>.from(adaptiveMap['columns'] ?? []);
    rows = List<Map<String, dynamic>>.from(adaptiveMap['rows'] ?? []);
    showGridLines = adaptiveMap['showGridLines'] as bool? ?? true;
    gridStyle = adaptiveMap['gridStyle'] as String? ?? 'default';
    firstRowAsHeader = adaptiveMap['firstRowAsHeader'] as bool? ?? true;
    verticalCellAlignment =
        adaptiveMap['verticalCellContentAlignment'] as String?;

    assert(() {
      developer.log(
        'Table: columns: ${columns.length} rows: ${rows.length}',
        name: runtimeType.toString(),
      );
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    final String tableKey = (widget.key! as ValueKey<String>).value;
    final resolver = styleResolver;
    final Color borderColor = resolver.resolveGridStyleColor(gridStyle);
    final double spacing = resolver.resolveSpacing('default');
    final int columnCount = _columnCount();

    final Map<int, TableColumnWidth> columnWidths = {
      for (int i = 0; i < columnCount; i++)
        i: mapColumnWidth(i < columns.length ? columns[i]['width'] : null),
    };

    final List<TableRow> tableRows = [
      for (int i = 0; i < rows.length; i++)
        _buildTableRow(
          rows[i],
          resolver,
          isHeaderRow: firstRowAsHeader && i == 0,
          isLastRow: i == rows.length - 1,
          rowIndex: i,
          tableKey: tableKey,
          columnCount: columnCount,
          spacing: spacing,
        ),
    ];

    final Widget tableContent = Table(
      key: AdaptiveTable.tableColumnKey(tableKey),
      columnWidths: columnWidths,
      defaultColumnWidth: const FlexColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
      border: showGridLines ? TableBorder.all(color: borderColor) : null,
      children: tableRows,
    );

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: tableContent,
      ),
    );
  }

  /// Number of columns: the larger of the `columns` definition length and the
  /// widest row, so ragged rows can be padded to a uniform child count.
  int _columnCount() {
    int maxCells = 0;
    for (final row in rows) {
      final cells = row['cells'] as List<dynamic>?;
      if (cells != null && cells.length > maxCells) maxCells = cells.length;
    }
    return columns.length > maxCells ? columns.length : maxCells;
  }

  /// Builds one [TableRow] with exactly [columnCount] children, padding ragged
  /// rows with empty cells.
  TableRow _buildTableRow(
    Map<String, dynamic> row,
    ReferenceResolver resolver, {
    required bool isHeaderRow,
    required bool isLastRow,
    required int rowIndex,
    required String tableKey,
    required int columnCount,
    required double spacing,
  }) {
    final List<TableCellModel> rowTableCells =
        ((row['cells'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
                const <Map<String, dynamic>>[])
            .map(TableCellModel.fromJson)
            .toList();
    final rowStyle = row['style'] as String?;

    final List<Widget> cells = [
      for (int col = 0; col < columnCount; col++)
        if (col >= rowTableCells.length)
          const SizedBox.shrink()
        else
          _buildCell(
            rowTableCells[col],
            resolver,
            rowStyle: rowStyle,
            isHeaderRow: isHeaderRow,
            isLastColumn: col == columnCount - 1,
            isLastRow: isLastRow,
            rowIndex: rowIndex,
            col: col,
            tableKey: tableKey,
            spacing: spacing,
          ),
    ];

    return TableRow(
      key: AdaptiveTable.rowKey(tableKey, rowIndex),
      children: cells,
    );
  }

  /// Builds a single cell: background decoration (fills the row height via
  /// `intrinsicHeight`), optional `minHeight`, content alignment, header styling,
  /// `selectAction`, and gutter padding when grid lines are disabled.
  Widget _buildCell(
    TableCellModel cellModel,
    ReferenceResolver resolver, {
    required String? rowStyle,
    required bool isHeaderRow,
    required bool isLastColumn,
    required bool isLastRow,
    required int rowIndex,
    required int col,
    required String tableKey,
    required double spacing,
  }) {
    final effectiveStyle = cellModel.style ?? rowStyle;
    final backgroundColor =
        resolver.resolveContainerBackgroundColor(style: effectiveStyle);

    final verticalAlign =
        cellModel.verticalContentAlignment ?? verticalCellAlignment;
    final vMainAxis =
        resolver.resolveVerticalMainAxisContentAlginment(verticalAlign);
    final horizontalAlign = cellModel.horizontalContentAlignment ??
        adaptiveMap['horizontalCellContentAlignment'] as String?;
    final hMainAxis =
        resolver.resolveHorizontalMainAxisAlignment(horizontalAlign);

    double x = -1; // left
    if (hMainAxis == MainAxisAlignment.center) x = 0.0;
    if (hMainAxis == MainAxisAlignment.end) x = 1.0;
    double y = -1; // top
    if (vMainAxis == MainAxisAlignment.center) y = 0.0;
    if (vMainAxis == MainAxisAlignment.end) y = 1.0;

    Widget content = Align(
      alignment: Alignment(x, y),
      child: buildCellContent(
        oneCellItems: List<Map<String, dynamic>>.from(cellModel.items),
        isHeaderRow: isHeaderRow,
        cellModel: cellModel,
      ),
    );

    final double? minHeight = parseCellMinHeightPx(cellModel.minHeight);
    if (minHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: content,
      );
    }

    Widget cell = Container(
      key: AdaptiveTable.cellKey(tableKey, rowIndex, col),
      decoration: isHeaderRow
          ? getHeaderCellDecoration(
              cellModel.toJson(),
              backgroundColor: backgroundColor,
            )
          : getDecorationFromMap(
              cellModel.toJson(),
              backgroundColor: backgroundColor,
            ),
      child: content,
    );

    if (cellModel.selectAction != null) {
      cell = AdaptiveTappable(adaptiveMap: cellModel.toJson(), child: cell);
    }

    // When grid lines are off, a Table cannot hold spacer children, so create
    // the gutter with padding outside the decorated cell (keeps the gap
    // uncolored, matching the old SizedBox spacers).
    if (!showGridLines && (!isLastColumn || !isLastRow)) {
      cell = Padding(
        padding: EdgeInsets.only(
          right: isLastColumn ? 0 : spacing,
          bottom: isLastRow ? 0 : spacing,
        ),
        child: cell,
      );
    }

    return cell;
  }

  /// Build decoration for header cells.
  BoxDecoration getHeaderCellDecoration(
    Map<String, dynamic> cellJson, {
    Color? backgroundColor,
  }) {
    return getDecorationFromMap(cellJson, backgroundColor: backgroundColor);
  }

  /// Build cell content (responsive `layouts`, scrollbar, header text style).
  Widget buildCellContent({
    required List<Map<String, dynamic>> oneCellItems,
    required bool isHeaderRow,
    required TableCellModel cellModel,
  }) {
    final cellWidgets = List<Widget>.generate(oneCellItems.length, (
      widgetIndex,
    ) {
      developer.log(
        'onCellItems for index $widgetIndex : ${oneCellItems[widgetIndex]}',
        name: runtimeType.toString(),
      );
      return cardTypeRegistry.getElement(
        map: oneCellItems[widgetIndex],
      );
    });

    Widget content = Scrollbar(
      child: buildLayoutChildren(
        layouts: cellModel.layouts,
        bucket: ref.watch(cardWidthBucketProvider),
        styleResolver: styleResolver,
        children: cellWidgets,
        childMaps: oneCellItems,
        stackBuilder: (children) => Wrap(children: children),
      ),
    );

    if (isHeaderRow) {
      final appearance = styleResolver.resolveTextBlockStyle(
        styleName: 'columnHeader',
      );
      content = DefaultTextStyle(
        style: TextStyle(
          fontWeight: styleResolver.resolveFontWeight(appearance.weight),
          fontSize: styleResolver.resolveFontSize(
            context: context,
            sizeString: appearance.size,
          ),
          fontFamily: styleResolver.resolveFontType(
            context,
            appearance.fontType,
          ),
          color: styleResolver.resolveContainerForegroundColor(
            style: appearance.color,
            isSubtle: appearance.isSubtle,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
```

- [ ] **Step 4: Run the new width test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_test.dart -n "maps column widths"`
Expected: PASS.

- [ ] **Step 5: Run the full table test file (catch regressions in existing tests)**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_test.dart test/containers/table_visibility_overlay_test.dart`
Expected: PASS. If a pre-existing test used `find.byKey(AdaptiveTable.rowKey(...))` and now fails (a `TableRow` is not a findable element — see lines ~197), update that single assertion to locate a cell instead, e.g. replace `find.byKey(AdaptiveTable.rowKey(tableKey, 0))` with `find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0))` and assert on the cell. Do not change unrelated assertions.

- [ ] **Step 6: Analyze**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter analyze lib/src/cards/containers/table.dart`
Expected: No issues.

- [ ] **Step 7: Commit** (propose, then wait)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/containers/table.dart \
        packages/flutter_adaptive_cards_fs/test/containers/table_test.dart
git commit -m "feat(table): render via Flutter Table for auto/stretch column widths"
```

---

### Task 3: Behavior tests for `auto` (cross-row) and `stretch`

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/test/containers/table_test.dart`

- [ ] **Step 1: Add the failing/behavioral tests**

Inside the `group('AdaptiveTable', () { … })` block in `test/containers/table_test.dart`, add:

```dart
    testWidgets('auto column has the same width across rows', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'auto'},
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'X'}]},
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'short'}]},
                ],
              },
              {
                'type': 'TableRow',
                'cells': [
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'a much longer label'}]},
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'short'}]},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Auto Width Test'),
      );
      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final col0Row0 = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0)),
      );
      final col0Row1 = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 1, 0)),
      );
      // Auto column is sized to the widest cell content across all rows.
      expect(col0Row0.width, col0Row1.width);
    });

    testWidgets('stretch column consumes width beyond the auto column',
        (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'auto'},
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'A'}]},
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'B'}]},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Stretch Width Test'),
      );
      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final autoCell = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0)),
      );
      final stretchCell = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 1)),
      );
      // The single-character "auto" column is far narrower than the stretch one.
      expect(stretchCell.width, greaterThan(autoCell.width));
    });
```

- [ ] **Step 2: Run the new tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_test.dart -n "auto column|stretch column"`
Expected: PASS (the `Table` rewrite from Task 2 already provides this behavior).

- [ ] **Step 3: Commit** (propose, then wait)

```bash
git add packages/flutter_adaptive_cards_fs/test/containers/table_test.dart
git commit -m "test(table): assert auto cross-row sizing and stretch fill"
```

---

### Task 4: Apply cell `minHeight`

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/test/containers/table_test.dart`
- (Implementation already present from Task 2 — this task verifies it via a behavior test.)

- [ ] **Step 1: Add the failing test**

Add inside the `group('AdaptiveTable', () { … })`:

```dart
    testWidgets('cell minHeight raises the row height', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'minHeight': '120px',
                    'items': [{'type': 'TextBlock', 'text': 'tall'}],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'MinHeight Test'),
      );
      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final cell = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0)),
      );
      expect(cell.height, greaterThanOrEqualTo(120.0));
    });
```

- [ ] **Step 2: Run the test**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_test.dart -n "minHeight"`
Expected: PASS (Task 2 wraps content in `ConstrainedBox(minHeight:)`). If it FAILS, confirm `parseCellMinHeightPx` is invoked in `_buildCell` and that `intrinsicHeight` is the `defaultVerticalAlignment`.

- [ ] **Step 3: Commit** (propose, then wait)

```bash
git add packages/flutter_adaptive_cards_fs/test/containers/table_test.dart
git commit -m "test(table): cell minHeight raises row height"
```

---

### Task 5: Regression test for cell `backgroundImage`

`backgroundImage` already renders via `getDecorationFromMap` — this locks it in.

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/test/containers/table_test.dart`

- [ ] **Step 1: Add the test**

Add inside the `group('AdaptiveTable', () { … })`:

```dart
    testWidgets('cell backgroundImage renders a DecorationImage',
        (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'backgroundImage': 'https://example.com/bg.png',
                    'items': [{'type': 'TextBlock', 'text': 'bg'}],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Cell Background Image Test'),
      );
      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final container = tester.widget<Container>(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0)),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.image, isNotNull);
    });
```

- [ ] **Step 2: Run the test**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_test.dart -n "backgroundImage"`
Expected: PASS. (If image network loading interferes, the assertion only checks `decoration.image != null`, which is built synchronously from the map — no network needed.)

- [ ] **Step 3: Commit** (propose, then wait)

```bash
git add packages/flutter_adaptive_cards_fs/test/containers/table_test.dart
git commit -m "test(table): regression-test cell backgroundImage decoration"
```

---

### Task 6: Ragged rows + grid-line on/off

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/test/containers/table_test.dart`

- [ ] **Step 1: Add the tests**

Add inside the `group('AdaptiveTable', () { … })`:

```dart
    testWidgets('ragged rows (fewer cells than columns) render without error',
        (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'stretch'},
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'one'}]},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Ragged Rows Test'),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('one'), findsOneWidget);
    });

    testWidgets('showGridLines true draws a TableBorder', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'showGridLines': true,
            'columns': [{'width': 'stretch'}],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {'type': 'TableCell', 'items': [{'type': 'TextBlock', 'text': 'g'}]},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Grid Lines Test'),
      );
      await tester.pumpAndSettle();

      final table = tester.widget<Table>(find.byType(Table));
      expect(table.border, isNotNull);
    });
```

- [ ] **Step 2: Run the tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/table_test.dart -n "ragged rows|TableBorder"`
Expected: PASS.

- [ ] **Step 3: Run the whole container test directory**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/`
Expected: PASS.

- [ ] **Step 4: Commit** (propose, then wait)

```bash
git add packages/flutter_adaptive_cards_fs/test/containers/table_test.dart
git commit -m "test(table): ragged rows and grid-line border coverage"
```

---

### Task 7: Golden sample for mixed widths + styled cell + minHeight

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/test/samples/table3_widths.json`
- Modify: `packages/flutter_adaptive_cards_fs/test/golden_sample_test.dart`

- [ ] **Step 1: Create the sample JSON**

Create `packages/flutter_adaptive_cards_fs/test/samples/table3_widths.json`:

```json
{
  "type": "AdaptiveCard",
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "version": "1.5",
  "body": [
    {
      "type": "Table",
      "gridStyle": "accent",
      "firstRowAsHeader": true,
      "columns": [
        { "width": "auto" },
        { "width": "stretch" },
        { "width": "60px" },
        { "width": 2 }
      ],
      "rows": [
        {
          "type": "TableRow",
          "cells": [
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "Code" } ] },
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "Description" } ] },
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "Qty" } ] },
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "Notes" } ] }
          ]
        },
        {
          "type": "TableRow",
          "cells": [
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "A1" } ] },
            { "type": "TableCell", "style": "good", "minHeight": "80px", "items": [ { "type": "TextBlock", "text": "A reasonably long description that wraps", "wrap": true } ] },
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "3" } ] },
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "ok" } ] }
          ]
        },
        {
          "type": "TableRow",
          "cells": [
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "B22" } ] },
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "Short", "wrap": true } ] },
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "10" } ] },
            { "type": "TableCell", "items": [ { "type": "TextBlock", "text": "n/a" } ] }
          ]
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Add the golden test**

In `packages/flutter_adaptive_cards_fs/test/golden_sample_test.dart`, after the existing `table2` golden test (around line 247–255), add a new `testWidgets` block following the same pattern as the `table2` test:

```dart
  testWidgets('Golden Table 3 widths', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'table3_widths');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('table3_widths-base.png')),
    );
  });
```

- [ ] **Step 3: Generate the new baseline and refresh existing table baselines**

The `Table` rewrite changes table rendering, so `table1`/`table2` baselines must be regenerated too.

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/golden_sample_test.dart --update-goldens`
Expected: PASS; new file `test/gold_files/macos/table3_widths-base.png` created and `table1-base.png`/`table2-base.png` updated.

- [ ] **Step 4: Visually inspect the regenerated goldens**

Open `test/gold_files/macos/table1-base.png`, `table2-base.png`, and `table3_widths-base.png`. Confirm columns align across rows, `auto`/`px` columns are sized as expected, the styled `good` cell shows its background filling the row height, and grid lines render. (Linux CI baselines refresh on the next CI run.)

- [ ] **Step 5: Commit** (propose, then wait)

```bash
git add packages/flutter_adaptive_cards_fs/test/samples/table3_widths.json \
        packages/flutter_adaptive_cards_fs/test/golden_sample_test.dart \
        packages/flutter_adaptive_cards_fs/test/gold_files/macos/table1-base.png \
        packages/flutter_adaptive_cards_fs/test/gold_files/macos/table2-base.png \
        packages/flutter_adaptive_cards_fs/test/gold_files/macos/table3_widths-base.png
git commit -m "test(table): golden for mixed column widths + minHeight"
```

---

### Task 8: Documentation + changelog sync

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`
- Modify: `packages/flutter_adaptive_cards_fs/README.md`
- Modify: `docs/Implementation-Status.md`
- Modify: `.agents/skills/adaptive-cards-spec-compliance/SKILL.md` and `.claude/skills/adaptive-cards-spec-compliance/SKILL.md`

- [ ] **Step 1: Changelog**

In `packages/flutter_adaptive_cards_fs/CHANGELOG.md`, under `## [Unreleased]`, add:

```markdown
- `Table`: support `auto` and `stretch` column widths (rendered via Flutter's `Table` for cross-row-consistent sizing) and apply cell `minHeight`. Numeric/`px` widths and all existing cell behaviors (background color/image, header styling, `selectAction`, alignment, responsive `layouts`) preserved.
```

- [ ] **Step 2: Package README**

In `packages/flutter_adaptive_cards_fs/README.md`, in the **Known gaps** table, change the **Table completeness** row so it no longer lists `auto`/`stretch` widths — leaving only `bleed` and cell `rtl`:

```markdown
| **Table completeness**          | `bleed`, cell `rtl` (`auto`/`stretch` widths ✅, cell `minHeight` ✅)                                                                  | Low — niche table scenarios                                                  |
```

Also update the Table row in the **Implementation status** table (same file) if it flags `auto`/`stretch` as unsupported.

- [ ] **Step 3: Implementation-Status roadmap**

In `docs/Implementation-Status.md`, **Medium priority** item 1, narrow it to the remaining gap:

```markdown
1. **Complete `Table`**: `bleed`. (`auto`/`stretch` column widths ✅ and cell `minHeight` ✅ — 2026-06-29; cell `rtl` rendering → **Deferred**.)
```

And add to **Recently completed**:

```markdown
### Table auto/stretch widths + cell minHeight (2026-06-29)

- `Table` re-rendered through Flutter's `Table` widget: `auto` (content-sized, cross-row consistent), `stretch`, numeric weight, and `Npx` column widths via `mapColumnWidth`; equal-row-height + per-cell background fill via `TableCellVerticalAlignment.intrinsicHeight`; grid lines via `TableBorder`. Cell `minHeight` now applied. Remaining Table gaps: `bleed` and cell `rtl` (deferred).
```

- [ ] **Step 4: Spec-compliance skill (both copies)**

In `.agents/skills/adaptive-cards-spec-compliance/SKILL.md` and `.claude/skills/adaptive-cards-spec-compliance/SKILL.md`, update the `Table`/`TableRow`/`TableCell` row (~line 285) to:

```markdown
| `Table`/`TableRow`/`TableCell` | Partial — `bleed` and cell-level `rtl` rendering missing (`auto`/`stretch` widths and cell `minHeight` implemented) | [explorer](https://adaptivecards.io/explorer/Table.html) |
```

- [ ] **Step 5: Verify docs reference nothing stale**

Run: `git grep -n "auto/stretch column widths" docs packages/flutter_adaptive_cards_fs/README.md .agents .claude`
Expected: no remaining line describes `auto`/`stretch` as missing/unsupported.

- [ ] **Step 6: Commit** (propose, then wait)

```bash
git add packages/flutter_adaptive_cards_fs/CHANGELOG.md \
        packages/flutter_adaptive_cards_fs/README.md \
        docs/Implementation-Status.md \
        .agents/skills/adaptive-cards-spec-compliance/SKILL.md \
        .claude/skills/adaptive-cards-spec-compliance/SKILL.md
git commit -m "docs(table): record auto/stretch + minHeight completion"
```

---

### Final Task: Full verification

- [ ] **Step 1: Analyze the whole repo**

Run (repo root): `fvm flutter analyze`
Expected: No issues.

- [ ] **Step 2: Full non-golden suite (main library)**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`
Expected: All pass (note pass/skip counts).

- [ ] **Step 3: Golden suite**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --tags=golden`
Expected: All pass (table1/table2/table3 baselines match).

- [ ] **Step 4: Coverage gate**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --coverage --exclude-tags=golden`
Then (repo root): `fvm dart run tool/coverage/check_coverage.dart`
Expected: Coverage floor met (the new `table_column_width.dart` is fully covered by Task 1; `table.dart` covered by Tasks 2–6).

- [ ] **Step 5: Invoke `verification-before-completion`** and paste the exit codes / pass-fail counts from Steps 1–4 before claiming completion.
