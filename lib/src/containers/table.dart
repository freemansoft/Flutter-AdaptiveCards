///
/// https://adaptivecards.io/explorer/ColumnSet.html
///
/// This is a placeholder implementation that only shows an empty table
/// Has no error handling
import 'package:flutter/material.dart';

import '../base.dart';
import '../utils.dart';

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
  late List<TableRow> tableRows;
  late MainAxisAlignment horizontalAlignment;

  @override
  void initState() {
    super.initState();
    columns = List<Map<String, dynamic>>.from(adaptiveMap["columns"] ?? []);
    // left this in for debugging
    rows = List<Map<String, dynamic>>.from(adaptiveMap["rows"] ?? []);

    tableRows = List<TableRow>.filled(
        rows.length,
        TableRow(
            children: List<Widget>.filled(
                columns.length, Text("Tables not implemented"))));

    horizontalAlignment = loadHorizontalAlignment();
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor =
        getBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
      resolver: resolver,
      adaptiveMap: adaptiveMap,
      approximateDarkThemeColors: widgetState.widget.approximateDarkThemeColors,
      brightness: Theme.of(context).brightness,
    );

    return Table(
      border: TableBorder.all(),
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(64),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableRows,
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
}
