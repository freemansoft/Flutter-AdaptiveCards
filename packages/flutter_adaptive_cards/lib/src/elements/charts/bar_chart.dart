import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

///
/// https://adaptivecards.microsoft.com/?topic=Chart.HorizontalBar
/// https://adaptivecards.microsoft.com/?topic=Chart.VerticalBar
///
/// https://adaptivecards.microsoft.com/?topic=BarChartDataValue
/// https://adaptivecards.microsoft.com/?topic=VerticalBarChartDataValue///
/// https://adaptivecards.microsoft.com/?topic=HorizontalBarChartDataValue
///
enum BarChartType {
  vertical,
  horizontal,
  stacked, // Vertical Stacked
  grouped, // Vertical Grouped
  horizontalStacked,
  // horizontalGrouped - implies grouped ?
}

class AdaptiveBarChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveBarChart({
    required this.adaptiveMap,
    required this.type,
    required this.widgetState,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;
  @override
  final RawAdaptiveCardState widgetState;
  @override
  late final String id;

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
    final data = adaptiveMap['data'];
    barGroups = [];
    maxY = 10; // Default safety
    if (data is! List) return;
    maxY = 0;

    // We need to group data by X coordinate (category)
    final Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (final item in data) {
      final String x = item['x']?.toString() ?? 'Unknown';
      if (!groupedData.containsKey(x)) {
        groupedData[x] = [];
      }
      groupedData[x]!.add(item);
    }

    int xIndex = 0;
    groupedData.forEach((key, items) {
      final List<BarChartRodData> rods = [];
      double currentYSum = 0;

      // For Stacked, we need to handle "fromY" and "toY" or just stack logicaly?
      // fl_chart supports rodStackItems? No, it supports `BarChartRodData` having `rodStackItems`.
      // If Stacked, we create ONE rod per group, with multiple rodStackItems.

      final bool isStacked =
          widget.type == BarChartType.stacked ||
          widget.type == BarChartType.horizontalStacked;

      if (isStacked) {
        final List<BarChartRodStackItem> stackItems = [];
        double runningSum = 0;
        for (final item in items) {
          final double val = (item['y'] as num? ?? 0).toDouble();
          final String? colorStr = item['color'] as String?;
          final Color color = _parseColor(colorStr) ?? Colors.blue; // rotation?

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
        for (final item in items) {
          final double val = (item['y'] as num? ?? 0).toDouble();
          if (val > maxY) maxY = val;
          final String? colorStr = item['color'] as String?;
          final Color color = _parseColor(colorStr) ?? Colors.blue;

          rods.add(
            BarChartRodData(
              toY: val,
              color: color,
              width: 16, // TODO(username): make configurable
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

  // TODO(username): Add support for AdaptiveCards named colors
  // https://adaptivecards.microsoft.com/?topic=VerticalBarChartDataValue
  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    // Basic hex parsing
    final myColorStr = colorStr.replaceAll('#', '');
    if (myColorStr.length == 6) {
      return Color(int.parse('FF$myColorStr', radix: 16));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isHorizontal =
        widget.type == BarChartType.horizontal ||
        widget.type == BarChartType.horizontalStacked;

    final sideTitles = SideTitles(
      showTitles: true,
      getTitlesWidget: (val, meta) {
        return Text(
          val.isFinite ? val.toInt().toString() : '',
          style: const TextStyle(fontSize: 10),
        );
      },
    );
    final axisTitles = AxisTitles(sideTitles: sideTitles);

    final Widget chart = SeparatorElement(
      adaptiveMap: adaptiveMap,
      widgetState: widgetState,
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: axisTitles,
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

  // TODO(username): Implement Rotation wrapper for Horizontal Bar Chart if fl_chart doesn't support it natively yet.
  // Or use `LineChart` for vertical only?
}
