import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';

///
/// https://adaptivecards.microsoft.com/?topic=Chart.HorizontalBar
/// https://adaptivecards.microsoft.com/?topic=Chart.VerticalBar
/// https://adaptivecards.microsoft.com/?topic=Chart.HorizontalBar.Stacked
/// https://adaptivecards.microsoft.com/?topic=Chart.VerticalBar.Grouped
///
/// https://adaptivecards.microsoft.com/?topic=BarChartDataValue
/// https://adaptivecards.microsoft.com/?topic=VerticalBarChartDataValue
/// https://adaptivecards.microsoft.com/?topic=HorizontalBarChartDataValue
///
enum BarChartType {
  vertical,
  verticalGrouped,
  horizontal,
  horizontalStacked,
}

class AdaptiveBarChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveBarChart({
    required this.adaptiveMap,
    required this.type,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;
  @override
  late final String id;

  final BarChartType type;

  @override
  AdaptiveBarChartState createState() => AdaptiveBarChartState();
}

class AdaptiveBarChartState extends State<AdaptiveBarChart>
    with AdaptiveElementMixin {
  late List<BarChartGroupData> barGroups;
  late List<String> xLabels;
  late double maxY;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseData();
  }

  void _parseData() {
    final data = adaptiveMap['data'];
    barGroups = [];
    xLabels = [];
    maxY = 10; // Default safety
    if (data is! List) return;
    maxY = 0;

    final bool isStacked =
        widget.type == BarChartType.horizontalStacked ||
        (widget.type == BarChartType.verticalGrouped &&
            adaptiveMap['stacked'] == true);
    final bool isGrouped =
        widget.type == BarChartType.verticalGrouped &&
        (!adaptiveMap.containsKey('stacked') ||
            adaptiveMap['stacked'] == null ||
            adaptiveMap['stacked'] == false);

    debugPrint('isStacked: $isStacked, isGrouped: $isGrouped');

    if (isStacked || isGrouped) {
      // Data is a list of series
      final Map<String, List<Map<String, dynamic>>> pivotData = {};
      final List<Color> defaultColors = styleResolver.resolveChartPalette();

      int seriesIndex = 0;
      for (final series in data) {
        // Chart.VerticalBar.Grouped uses `data.values`
        // Chart.HorizontalBar.Grouped uses `data.data`
        final List<dynamic>? points =
            series['data'] as List<dynamic>? ??
            series['values'] as List<dynamic>?;
        if (points == null) continue;

        final Color defaultSeriesColor =
            defaultColors[seriesIndex % defaultColors.length];

        for (final point in points) {
          final String x =
              (point['legend'] ?? point['x'])?.toString() ?? 'Unknown';
          if (!pivotData.containsKey(x)) {
            pivotData[x] = [];
          }
          pivotData[x]!.add({
            'y': point['value'] ?? point['y'] ?? 0,
            'color': point['color'] ?? series['color'],
            'fallbackColor': defaultSeriesColor,
          });
        }
        seriesIndex++;
      }

      int xIndex = 0;
      pivotData.forEach((key, items) {
        xLabels.add(key);
        final List<BarChartRodData> rods = [];

        if (isStacked) {
          final List<BarChartRodStackItem> stackItems = [];
          double runningSum = 0;
          for (final item in items) {
            final double val = (item['y'] as num).toDouble();
            final String? colorStr = item['color'] as String?;
            final Color fallback = item['fallbackColor'] as Color;
            final Color color = styleResolver.resolveChartColor(
              colorStr,
              fallback: fallback,
            );

            stackItems.add(
              BarChartRodStackItem(runningSum, runningSum + val, color),
            );
            runningSum += val;
          }
          final double currentYSum = runningSum;
          if (currentYSum > maxY) maxY = currentYSum;

          rods.add(
            BarChartRodData(
              toY: currentYSum,
              rodStackItems: stackItems,
              width: 16,
              color: Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
          );
        } else {
          // isGrouped
          for (final item in items) {
            final double val = (item['y'] as num).toDouble();
            if (val > maxY) maxY = val;
            final String? colorStr = item['color'] as String?;
            final Color fallback = item['fallbackColor'] as Color;
            final Color color = styleResolver.resolveChartColor(
              colorStr,
              fallback: fallback,
            );

            rods.add(
              BarChartRodData(
                toY: val,
                color: color,
                width: 16,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }
        }

        barGroups.add(
          BarChartGroupData(
            x: xIndex,
            barRods: rods,
            barsSpace: 4,
          ),
        );
        xIndex++;
      });
    } else {
      // Standard simple format
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
        xLabels.add(key);
        final List<BarChartRodData> rods = [];

        for (final item in items) {
          final double val = (item['y'] as num? ?? 0).toDouble();
          if (val > maxY) maxY = val;
          final String? colorStr = item['color'] as String?;
          final Color color = styleResolver.resolveChartColor(colorStr);

          rods.add(
            BarChartRodData(
              toY: val,
              color: color,
              width: 16, // TODO(username): make configurable
              borderRadius: BorderRadius.circular(2),
            ),
          );
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
    }

    // Safety
    if (maxY == 0) maxY = 10;
    maxY *= 1.2; // padding
  }

  @override
  Widget build(BuildContext context) {
    final bool isHorizontal =
        widget.type == BarChartType.horizontal ||
        widget.type == BarChartType.horizontalStacked;

    final sideTitles = SideTitles(
      showTitles: true,
      reservedSize: 32,
      getTitlesWidget: (val, meta) {
        final int index = val.toInt();
        final String text = (index >= 0 && index < xLabels.length)
            ? xLabels[index]
            : '';
        return SideTitleWidget(
          meta: meta,
          child: Text(
            text,
            style: const TextStyle(fontSize: 10),
          ),
        );
      },
    );
    final axisTitles = AxisTitles(sideTitles: sideTitles);

    final Widget chart = SeparatorElement(
      adaptiveMap: adaptiveMap,
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
            rotationQuarterTurns: isHorizontal ? 1 : 0,
          ),
        ),
      ),
    );

    return chart;
  }
}
