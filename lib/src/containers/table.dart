///
/// https://adaptivecards.io/explorer/ColumnSet.html
///
/// This is a placeholder implementation that only shows an empty table
/// Has no error handling
///
/// Reasonable test schema is https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/FlightUpdateTable.json
///
import 'dart:developer' as developer;
import 'package:format/format.dart';
import 'package:flutter/material.dart';

import '../base.dart';

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

    assert(() {
      developer.log(
          format("Table: columns: {} rows: {}", columns.length, rows.length));
      return true;
    }());
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
    //developer.log(format("Row: num:{} - {})", rowNum, row.toString()),
    //  name: this.runtimeType.toString());

    // All the table cell markup in this row [cell, cell, cell]
    List<Map<String, dynamic>> rowTableCells =
        List<Map<String, dynamic>>.from(row["cells"]);
    //developer.log(format("rowTableCells: row:{} length:{} - {} ", rowNum,
    //    rowTableCells.length, rowTableCells.toString()),
    //      name: this.runtimeType.toString());

    // The row markup contains a [TableCells[items]]
    List<List<dynamic>> rowCellItems =
        List<List<dynamic>>.generate(rowTableCells.length, (rowNum) {
      return rowTableCells[rowNum]["items"];
    });
    // developer.log(format("rowCellItems: row:{} length:{} - {}", rowNum,
    //    rowCellItems.length, rowCellItems.toString()),
    //      name: this.runtimeType.toString());

    List<TableCell> tableCells =
        List<TableCell>.generate(rowCellItems.length, (col) {
      List<Map<String, dynamic>> oneCellItems =
          List<Map<String, dynamic>>.from(rowCellItems[col]);
      // TableCell(Widget([Widget])) A TableCell contains a Widget that contains an arbitrary number of widgets
      // developer.log(
      //     format("oneCellItems: row:{} col:{} widgets in cell:{} - {}", rowNum,
      //         col, oneCellItems.length, oneCellItems.toString()),
      //     name: this.runtimeType.toString());
      return TableCell(
          child: Scrollbar(
              child: Wrap(
                  children:
                      List<Widget>.generate(oneCellItems.length, (widgetIndex) {
        developer.log(
            format("onCellItems for index {} : {}", widgetIndex,
                oneCellItems[widgetIndex]),
            name: this.runtimeType.toString());
        return widgetState.cardRegistry.getElement(oneCellItems[widgetIndex]);
      }))));
    });

    // developer.log(format("cell children: {}", tableCellChildren));
    // return TableRow(children: [tableCellChildren],
    //    name: this.runtimeType.toString());
    return TableRow(children: tableCells);
  }
}
