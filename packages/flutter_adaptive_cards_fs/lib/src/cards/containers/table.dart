import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
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
///
/// Reasonable test schema is https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/FlightUpdateTable.json
///
/// Renders a `Table` with column widths, grid lines, and optional header row
/// styling from `firstRowAsHeader`.
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

  /// Widget key for a table column at index [col].
  static ValueKey<String> columnKey(String tableKey, int col) =>
      ValueKey('${tableKey}_col_$col');

  /// Widget key for the cell at [rowIndex], [col].
  static ValueKey<String> cellKey(String tableKey, int rowIndex, int col) =>
      ValueKey('${tableKey}_${rowIndex}_$col');

  /// Widget key for the row at [rowIndex].
  static ValueKey<String> rowKey(String tableKey, int rowIndex) =>
      ValueKey('${tableKey}_row_$rowIndex');

  /// Widget key for the outer column that wraps all table rows.
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

    // Should all be Table Rows
    rows = List<Map<String, dynamic>>.from(adaptiveMap['rows'] ?? []);

    // Parse new properties
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
    Widget tableContent = Column(
      key: AdaptiveTable.tableColumnKey(tableKey),
      children: generateTableRows(rows, resolver, tableKey),
    );

    if (showGridLines) {
      final Color borderColor = resolver.resolveGridStyleColor(gridStyle);
      tableContent = Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
        ),
        child: tableContent,
      );
    }

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: tableContent,
      ),
    );
  }

  ///
  /// Generates all the Table rows for the table
  ///
  List<Widget> generateTableRows(
    List<Map<String, dynamic>> rows,
    ReferenceResolver resolver,
    String tableKey,
  ) {
    final List<Widget> rowWidgets = [];
    final Color borderColor = resolver.resolveGridStyleColor(gridStyle);
    final double spacing = resolver.resolveSpacing('default');

    for (int i = 0; i < rows.length; i++) {
      final isHeaderRow = firstRowAsHeader && i == 0;
      rowWidgets.add(
        generateTableRowWidgets(
          rows[i],
          resolver,
          isHeaderRow: isHeaderRow,
          rowIndex: i,
          tableKey: tableKey,
        ),
      );

      // Add separator if showing grid lines and not the last row
      if (i < rows.length - 1) {
        if (showGridLines) {
          rowWidgets.add(Divider(height: 1, thickness: 1, color: borderColor));
        } else {
          rowWidgets.add(SizedBox(height: spacing));
        }
      }
    }

    return rowWidgets;
  }

  ///
  /// Generates a Row for the Table
  ///
  Widget generateTableRowWidgets(
    Map<String, dynamic> row,
    ReferenceResolver resolver, {
    bool isHeaderRow = false,
    required int rowIndex,
    required String tableKey,
  }) {
    final List<Map<String, dynamic>> rowCellItems =
        (row['cells'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .toList() ??
        [];

    final List<TableCellModel> rowTableCells = rowCellItems
        .map(TableCellModel.fromJson)
        .toList();

    final rowStyle = row['style'] as String?;
    final Color borderColor = resolver.resolveGridStyleColor(gridStyle);
    final double spacing = resolver.resolveSpacing('default');

    final List<Widget> cellWidgets = [];

    // Ensure we don't exceed defined columns or handle mismatch gracefully?
    // Table asserts equal columns. We can just loop available cells.
    // Ideally we match columns definition length.
    final int cellCount = rowCellItems.length;

    for (int col = 0; col < cellCount; col++) {
      final List<Map<String, dynamic>> oneCellItems =
          List<Map<String, dynamic>>.from(
            rowTableCells[col].items,
          );

      final cellModel = rowTableCells[col];

      // Resolve background color
      final effectiveStyle = cellModel.style ?? rowStyle;
      final backgroundColor = resolver.resolveContainerBackgroundColor(
        style: effectiveStyle,
      );

      // Resolve vertical alignment
      final verticalAlign =
          cellModel.verticalContentAlignment ?? verticalCellAlignment;
      final vMainAxis = resolver.resolveVerticalMainAxisContentAlginment(
        verticalAlign,
      );

      // Resolve horizontal alignment
      final horizontalAlign =
          cellModel.horizontalContentAlignment ??
          adaptiveMap['horizontalCellContentAlignment'] as String?;
      final hMainAxis = resolver.resolveHorizontalMainAxisAlignment(
        horizontalAlign,
      );

      // Convert MainAxisAlignment to Alignment
      double x = -1; // left
      if (hMainAxis == MainAxisAlignment.center) x = 0.0;
      if (hMainAxis == MainAxisAlignment.end) x = 1.0;

      double y = -1; // top
      if (vMainAxis == MainAxisAlignment.center) y = 0.0;
      if (vMainAxis == MainAxisAlignment.end) y = 1.0;

      final containerAlignment = Alignment(x, y);

      Widget cellContent = Container(
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
        child: Align(
          alignment: containerAlignment,
          child: buildCellContent(
            oneCellItems: oneCellItems,
            isHeaderRow: isHeaderRow,
            cellModel: cellModel,
          ),
        ),
      );

      if (cellModel.selectAction != null) {
        cellContent = AdaptiveTappable(
          adaptiveMap: cellModel.toJson(),
          child: cellContent,
        );
      }

      // Determine column width
      // Default to flex 1 if columns def is missing or shorter
      Widget wrappedCell;
      if (col < columns.length) {
        final columnDef = columns[col];
        final dynamic width = columnDef['width'];

        if (width is num) {
          wrappedCell = Expanded(
            key: AdaptiveTable.columnKey(tableKey, col),
            flex: width.toInt(),
            child: cellContent,
          );
        } else if (width is String && width.endsWith('px')) {
          final pixels = double.tryParse(width.replaceAll('px', ''));
          if (pixels != null) {
            wrappedCell = SizedBox(
              key: AdaptiveTable.columnKey(tableKey, col),
              width: pixels,
              child: cellContent,
            );
          } else {
            wrappedCell = Expanded(
              key: AdaptiveTable.columnKey(tableKey, col),
              child: cellContent,
            );
          }
        } else {
          wrappedCell = Expanded(
            key: AdaptiveTable.columnKey(tableKey, col),
            child: cellContent,
          );
        }
      } else {
        wrappedCell = Expanded(
          key: AdaptiveTable.columnKey(tableKey, col),
          child: cellContent,
        );
      }

      cellWidgets.add(wrappedCell);

      // Add separator
      if (col < cellCount - 1) {
        if (showGridLines) {
          cellWidgets.add(
            VerticalDivider(width: 1, thickness: 1, color: borderColor),
          );
        } else {
          cellWidgets.add(SizedBox(width: spacing));
        }
      }
    }

    return IntrinsicHeight(
      child: Row(
        key: AdaptiveTable.rowKey(tableKey, rowIndex),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cellWidgets,
      ),
    );
  }

  /// Build decoration for header cells
  BoxDecoration getHeaderCellDecoration(
    Map<String, dynamic> cellJson, {
    Color? backgroundColor,
  }) {
    // Use base decoration and optionally enhance for headers
    final baseDecoration = getDecorationFromMap(
      cellJson,
      backgroundColor: backgroundColor,
    );
    // Header cells could have special background/border if needed
    return baseDecoration;
  }

  /// Build cell content with alignment support
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
        stackBuilder: (children) => Wrap(children: children),
      ),
    );

    // Horizontal alignment is now handled by parent Align widget

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
