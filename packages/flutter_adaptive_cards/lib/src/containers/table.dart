import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:format/format.dart';

///
/// https://adaptivecards.io/explorer/ColumnSet.html
///
/// This is a placeholder implementation that only shows an empty table
/// Has no error handling
///
/// Reasonable test schema is https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/FlightUpdateTable.json
///
class AdaptiveTable extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTable({
    required this.adaptiveMap,
    required this.widgetState,
    required this.supportMarkdown,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  late final String id;

  final bool supportMarkdown;

  @override
  AdaptiveTableState createState() => AdaptiveTableState();
}

class AdaptiveTableState extends State<AdaptiveTable>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late List<Map<String, dynamic>> columns;
  late List<Map<String, dynamic>> rows;

  @override
  void initState() {
    super.initState();
    columns = List<Map<String, dynamic>>.from(adaptiveMap['columns'] ?? []);

    // Should all be Table Rows
    rows = List<Map<String, dynamic>>.from(adaptiveMap['rows'] ?? []);

    assert(() {
      developer.log(
        format('Table: columns: {} rows: {}', columns.length, rows.length),
        name: runtimeType.toString(),
      );
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        widgetState: widgetState,
        child: Table(
          border: TableBorder.all(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          defaultColumnWidth: const FlexColumnWidth(),
          // column width should be picked up from the columns["width"]
          // columnWidths: const <int, TableColumnWidth>{
          //   1: FlexColumnWidth(),
          //   2: FlexColumnWidth(),
          //   3: FlexColumnWidth(),
          // },
          children: generateTableRows(rows),
        ),
      ),
    );
  }

  MainAxisAlignment loadHorizontalAlignment() {
    final String horizontalAlignment =
        adaptiveMap['horizontalCellContentAlignment']
            ?.toString()
            .toLowerCase() ??
        'left';

    switch (horizontalAlignment) {
      case 'left':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'right':
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
    }
  }

  ///
  /// Generates all the Table rows for the table [TableRow[TableCell[Widget]]]
  ///
  List<TableRow> generateTableRows(List<Map<String, dynamic>> rows) {
    final allRows = List<TableRow>.generate(rows.length, (rowNum) {
      return generateTableRowWidgets(rows[rowNum]);
    });
    // this code should assert that all rows have the same number of columns
    assert(() {
      final firstRow = allRows.first;
      final expectedColumnCount = firstRow.children.length;

      for (int i = 0; i < allRows.length; i++) {
        final row = allRows[i];
        assert(
          row.children.length == expectedColumnCount,
          'Row $i has ${row.children.length} columns, expected $expectedColumnCount',
        );
      }
      return true;
    }());

    return allRows;
  }

  ///
  /// Generates a TableRow for the Table TableRow[TableCell[Widget]]
  ///
  TableRow generateTableRowWidgets(Map<String, dynamic> row) {
    //developer.log(format("Row: num:{} - {})", rowNum, row.toString()),
    //  name: runtimeType.toString());

    // All the table cell markup in this row [cell, cell, cell]
    final List<Map<String, dynamic>> rowTableCells =
        List<Map<String, dynamic>>.from(
          row['cells'],
        );
    //developer.log(format("rowTableCells: row:{} length:{} - {} ", rowNum,
    //    rowTableCells.length, rowTableCells.toString()),
    //      name: runtimeType.toString());

    // The row markup contains a [TableCells[items]]
    final List<List<dynamic>> rowCellItems = List<List<dynamic>>.generate(
      rowTableCells.length,
      (rowNum) {
        // some of the samples have empty rows
        return rowTableCells[rowNum]['items'] as List<dynamic>? ?? [];
      },
    );
    // developer.log(format("rowCellItems: row:{} length:{} - {}", rowNum,
    //    rowCellItems.length, rowCellItems.toString()),
    //      name: runtimeType.toString());

    final List<TableCell>
    tableCells = List<TableCell>.generate(rowCellItems.length, (
      col,
    ) {
      final List<Map<String, dynamic>> oneCellItems =
          List<Map<String, dynamic>>.from(
            rowCellItems[col],
          );
      // developer.log(
      //     format("oneCellItems: row:{} col:{} widgets in cell:{} - {}", rowNum,
      //         col, oneCellItems.length, oneCellItems.toString()),
      //     name: this.runtimeType.toString());
      return TableCell(
        child: Container(
          decoration: getDecorationFromMap(rowTableCells[col]),
          child: Scrollbar(
            child: Wrap(
              children: List<Widget>.generate(oneCellItems.length, (
                widgetIndex,
              ) {
                developer.log(
                  format(
                    'onCellItems for index {} : {}',
                    widgetIndex,
                    oneCellItems[widgetIndex],
                  ),
                  name: runtimeType.toString(),
                );
                return widgetState.cardTypeRegistry.getElement(
                  map: oneCellItems[widgetIndex],
                  widgetState: widgetState,
                );
              }),
            ),
          ),
        ),
      );
    });

    // developer.log(format("cell children: {}", tableCellChildren));
    // return TableRow(children: [tableCellChildren],
    //    name: runtimeType.toString());
    return TableRow(children: tableCells);
  }
}
