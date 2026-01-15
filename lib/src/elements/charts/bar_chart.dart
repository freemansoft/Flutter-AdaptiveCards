import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';

enum BarChartType {
  vertical,
  horizontal,
  stacked, // Vertical Stacked
  grouped, // Vertical Grouped
  horizontalStacked,
  // horizontalGrouped - implies grouped ?
}

class AdaptiveBarChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveBarChart({super.key, required this.adaptiveMap, required this.type});

  @override
  final Map<String, dynamic> adaptiveMap;
  final BarChartType type;

  @override
  AdaptiveBarChartState createState() => AdaptiveBarChartState();
}

class AdaptiveBarChartState extends State<AdaptiveBarChart>
    with AdaptiveElementMixin {
  late List<BarChartGroupData> barGroups;
  late double maxY;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    // Assumption: data is a list of objects.
    // Each object has `x` (label), `y` (value), `series` (optional, for grouping/stacking), `color`
    var data = widget.adaptiveMap['data'];
    barGroups = [];
    maxY = 0;

    if (data is! List) return;

    // We need to group data by X coordinate (category)
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in data) {
      String x = item['x']?.toString() ?? item['title'] ?? 'Unknown';
      if (!groupedData.containsKey(x)) {
        groupedData[x] = [];
      }
      groupedData[x]!.add(item);
    }

    int xIndex = 0;
    groupedData.forEach((key, items) {
      List<BarChartRodData> rods = [];
      double currentYSum = 0;

      // For Stacked, we need to handle "fromY" and "toY" or just stack logicaly?
      // fl_chart supports rodStackItems? No, it supports `BarChartRodData` having `rodStackItems`.
      // If Stacked, we create ONE rod per group, with multiple rodStackItems.

      bool isStacked =
          widget.type == BarChartType.stacked ||
          widget.type == BarChartType.horizontalStacked;

      if (isStacked) {
        List<BarChartRodStackItem> stackItems = [];
        double runningSum = 0;
        for (var item in items) {
          double val = (item['value'] ?? item['y'] ?? 0).toDouble();
          String? colorStr = item['color'];
          Color color = _parseColor(colorStr) ?? Colors.blue; // rotation?

          stackItems.add(
            BarChartRodStackItem(runningSum, runningSum + val, color),
          );
          runningSum += val;
        }
        currentYSum = runningSum;
        if (currentYSum > maxY) maxY = currentYSum;

        rods.add(
          BarChartRodData(
            toY: currentYSum,
            rodStackItems: stackItems,
            width: 16,
            color: Colors.transparent, // Color is in stack items
            borderRadius: BorderRadius.zero,
          ),
        );
      } else {
        // Grouped (or simple)
        // Multiple rods side by side (if Grouped) or just one rod (simple)
        // If "Grouped", typically multiple series show up as multiple bars for same X.
        for (var item in items) {
          double val = (item['value'] ?? item['y'] ?? 0).toDouble();
          if (val > maxY) maxY = val;
          String? colorStr = item['color'];
          Color color = _parseColor(colorStr) ?? Colors.blue;

          rods.add(
            BarChartRodData(
              toY: val,
              color: color,
              width: 16, // Todo make configurable
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: xIndex,
          barRods: rods,
          barsSpace: 4, // Space between rods in a group
        ),
      );
      xIndex++;
    });

    // Safety
    if (maxY == 0) maxY = 10;
    maxY *= 1.2; // padding
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    // Basic hex parsing
    colorStr = colorStr.replaceAll('#', '');
    if (colorStr.length == 6) {
      return Color(int.parse('FF$colorStr', radix: 16));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    bool isHorizontal =
        widget.type == BarChartType.horizontal ||
        widget.type == BarChartType.horizontalStacked;

    Widget chart = SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    // MVP hack:
                    return Text(
                      val.toInt().toString(),
                      style: TextStyle(fontSize: 10),
                    ); // TODO mapping
                  },
                ),
              ),
            ),
            // For horizontal, rotation is handled by RotatedBox
          ),
        ),
      ),
    );

    if (isHorizontal) {
      return RotatedBox(quarterTurns: 1, child: chart);
    }
    return chart;
  }

  // TODO: Implement Rotation wrapper for Horizontal Bar Chart if fl_chart doesn't support it natively yet.
  // Or use `LineChart` for vertical only?
}
