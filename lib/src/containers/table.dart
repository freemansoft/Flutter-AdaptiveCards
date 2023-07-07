///
/// https://adaptivecards.io/explorer/ColumnSet.html
///
/// This is a placeholder implementation that only shows an empty table
/// Has no error handling
///
/// Reasonable test schema is https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/FlightUpdateTable.json
///
import 'dart:developer';
import 'package:format/format.dart';
import 'package:flutter/material.dart';

import '../base.dart';
import '../utils.dart';
import 'container.dart';

class AdaptiveTable extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTable(
      {super.key, required this.adaptiveMap, required this.supportMarkdown});

  final Map<String, dynamic> adaptiveMap;
  final bool supportMarkdown;

  @override
  _AdaptiveTableState createState() => _AdaptiveTableState();
}

class _AdaptiveTableState extends State<AdaptiveTable>
    with AdaptiveElementMixin {
  late List<Map<String, dynamic>> columns;
  late List<Map<String, dynamic>> rows;

  @override
  void initState() {
    super.initState();
    columns = List<Map<String, dynamic>>.from(adaptiveMap["columns"] ?? []);

    // Should all be Table Rows
    rows = List<Map<String, dynamic>>.from(adaptiveMap["rows"] ?? []);

    // print(format("Table: columns: {} rows: {}", columns.length, rows.length));
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      defaultColumnWidth: FlexColumnWidth(),
      // column width should be picked up from the columns["width"]
      // columnWidths: const <int, TableColumnWidth>{
      //   1: FlexColumnWidth(),
      //   2: FlexColumnWidth(),
      //   3: FlexColumnWidth(),
      // },
      children: generateTableRows(rows),
    );
  }

  MainAxisAlignment loadHorizontalAlignment() {
    String horizontalAlignment =
        adaptiveMap["horizontalCellContentAlignment"]?.toLowerCase() ?? "left";

    switch (horizontalAlignment) {
      case "left":
        return MainAxisAlignment.start;
      case "center":
        return MainAxisAlignment.center;
      case "right":
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
    }
  }

  ///
  /// Generates all the Table rows for the table [TableRow[TableCell[Widget]]]
  ///
  List<TableRow> generateTableRows(List<Map<String, dynamic>> rows) {
    return List<TableRow>.generate(rows.length, (rowNum) {
      return generateTableRowWidgets(rows[rowNum]);
    });
  }

  ///
  /// Generates a TableRow for the Table TableRow[TableCell[Widget]]
  ///
  TableRow generateTableRowWidgets(Map<String, dynamic> row) {
    //print(format("Row: num:{} - {})", rowNum, row.toString()));

    // All the table cell markup in this row [cell, cell, cell]
    List<Map<String, dynamic>> rowTableCells =
        List<Map<String, dynamic>>.from(row["cells"]);
    //print(format("rowTableCells: row:{} length:{} - {} ", rowNum,
    //    rowTableCells.length, rowTableCells.toString()));

    // The row markup contains a [TableCells[items]]
    List<List<dynamic>> rowCellItems =
        List<List<dynamic>>.generate(rowTableCells.length, (rowNum) {
      return rowTableCells[rowNum]["items"];
    });
    // print(format("rowCellItems: row:{} length:{} - {}", rowNum,
    //    rowCellItems.length, rowCellItems.toString()));

    List<TableCell> tableCells =
        List<TableCell>.generate(rowCellItems.length, (col) {
      List<Map<String, dynamic>> oneCellItems =
          List<Map<String, dynamic>>.from(rowCellItems[col]);
      // TableCell(Widget([Widget])) A TableCell contains a Widget that contains an arbitrary number of widgets
      // print(format("oneCellItems: row:{} col:{} widgets in cell:{} - {}",
      //     rowNum, col, oneCellItems.length, oneCellItems.toString()));
      return TableCell(
          child: Scrollbar(
              child: Wrap(
                  children:
                      List<Widget>.generate(oneCellItems.length, (widgetIndex) {
        //print(oneCellItems[widgetIndex]);
        return widgetState.cardRegistry.getElement(oneCellItems[widgetIndex]);
      }))));
    });

    // print(format("cell children: {}", tableCellChildren));
    // return TableRow(children: [tableCellChildren]);
    return TableRow(children: tableCells);
  }
}
