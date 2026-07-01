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
class AdaptiveTable extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
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
    final backgroundColor = resolver.resolveContainerBackgroundColor(
      style: effectiveStyle,
    );

    final verticalAlign =
        cellModel.verticalContentAlignment ?? verticalCellAlignment;
    final vMainAxis = resolver.resolveVerticalMainAxisContentAlginment(
      verticalAlign,
    );
    final horizontalAlign =
        cellModel.horizontalContentAlignment ??
        adaptiveMap['horizontalCellContentAlignment'] as String?;
    final hMainAxis = resolver.resolveHorizontalMainAxisAlignment(
      horizontalAlign,
    );

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
      decoration: getDecorationFromMap(
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

  /// Build cell content (responsive `layouts`, scrollbar, header text style).
  Widget buildCellContent({
    required List<Map<String, dynamic>> oneCellItems,
    required bool isHeaderRow,
    required TableCellModel cellModel,
  }) {
    final effectiveItems = isHeaderRow
        ? oneCellItems.map(_applyColumnHeaderStyle).toList()
        : oneCellItems;

    final cellWidgets = List<Widget>.generate(effectiveItems.length, (
      widgetIndex,
    ) {
      assert(() {
        developer.log(
          'onCellItems for index $widgetIndex : ${effectiveItems[widgetIndex]}',
          name: runtimeType.toString(),
        );
        return true;
      }());
      return cardTypeRegistry.getElement(
        map: effectiveItems[widgetIndex],
      );
    });

    return Scrollbar(
      child: buildLayoutChildren(
        layouts: cellModel.layouts,
        bucket: ref.watch(cardWidthBucketProvider),
        styleResolver: styleResolver,
        children: cellWidgets,
        childMaps: effectiveItems,
        stackBuilder: (children) => Wrap(children: children),
      ),
    );
  }

  /// Applies the HostConfig `columnHeader` text style as the default appearance
  /// of a header cell's `TextBlock`, filling only properties the element does
  /// not set for itself.
  ///
  /// `firstRowAsHeader` styling cannot rely on an ambient `DefaultTextStyle`:
  /// `AdaptiveTextBlock` emits an explicit `TextStyle` (including an explicit
  /// `fontWeight`) that overrides inherited defaults. Baking the `columnHeader`
  /// tokens into the element map instead makes header rows render with the
  /// configured weight (bolder by default) while still letting an element's own
  /// `weight`/`size`/`color` win when present.
  Map<String, dynamic> _applyColumnHeaderStyle(Map<String, dynamic> item) {
    if (item['type'] != 'TextBlock') return item;
    final appearance = styleResolver.resolveTextBlockStyle(
      styleName: 'columnHeader',
    );
    return <String, dynamic>{
      if (appearance.weight != null) 'weight': appearance.weight,
      if (appearance.size != null) 'size': appearance.size,
      if (appearance.color != null) 'color': appearance.color,
      if (appearance.fontType != null) 'fontType': appearance.fontType,
      'isSubtle': appearance.isSubtle,
      ...item,
    };
  }
}
