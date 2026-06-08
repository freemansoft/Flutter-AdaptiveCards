import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';

/// Layout variants supported by [AdaptiveBarChart] for Adaptive Card bar chart types.
///
/// See also:
/// * https://adaptivecards.microsoft.com/?topic=Chart.HorizontalBar
/// * https://adaptivecards.microsoft.com/?topic=Chart.VerticalBar
/// * https://adaptivecards.microsoft.com/?topic=Chart.HorizontalBar.Stacked
/// * https://adaptivecards.microsoft.com/?topic=Chart.VerticalBar.Grouped
enum BarChartType {
  /// Vertical bar chart (`Chart.VerticalBar`).
  vertical,

  /// Grouped vertical bar chart (`Chart.VerticalBar.Grouped`).
  verticalGrouped,

  /// Horizontal bar chart (`Chart.HorizontalBar`).
  horizontal,

  /// Stacked horizontal bar chart (`Chart.HorizontalBar.Stacked`).
  horizontalStacked,
}

BarChartAlignment _toFlChartAlignment(BarChartAlignmentToken token) {
  switch (token) {
    case BarChartAlignmentToken.spaceBetween:
      return BarChartAlignment.spaceBetween;
    case BarChartAlignmentToken.spaceEvenly:
      return BarChartAlignment.spaceEvenly;
    case BarChartAlignmentToken.start:
      return BarChartAlignment.start;
    case BarChartAlignmentToken.end:
      return BarChartAlignment.end;
    case BarChartAlignmentToken.spaceAround:
      return BarChartAlignment.spaceAround;
  }
}

/// Renders Adaptive Card bar chart elements using fl_chart.
///
/// Registered in the chart element dispatch table for types such as
/// `Chart.VerticalBar`, `Chart.HorizontalBar`, and grouped or stacked variants.
/// Uses [AdaptiveElementWidgetMixin] for element identity and is wrapped in
/// [SeparatorElement] for card layout and spacing.
class AdaptiveBarChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a bar chart element from [adaptiveMap] with the given [type].
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

  /// The bar chart layout variant derived from the card element's `type`.
  final BarChartType type;

  @override
  AdaptiveBarChartState createState() => AdaptiveBarChartState();
}

/// State for [AdaptiveBarChart]; parses JSON data and builds the fl_chart widget.
class AdaptiveBarChartState extends State<AdaptiveBarChart>
    with AdaptiveElementMixin, ProviderScopeMixin {
  /// Parsed bar groups passed to the underlying [BarChart].
  late List<BarChartGroupData> barGroups;

  /// Category labels displayed on the chart axis.
  late List<String> xLabels;

  /// Upper bound of the value axis after padding.
  late double maxY;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseData();
  }

  void _parseData() {
    final layout = styleResolver.resolveBarChartLayout();
    final data = adaptiveMap['data'];
    barGroups = [];
    xLabels = [];
    maxY = layout.emptyMaxY;
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
      final Map<String, List<Map<String, dynamic>>> pivotData = {};
      final List<Color> defaultColors = styleResolver.resolveChartPalette();

      int seriesIndex = 0;
      for (final series in data) {
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
              width: layout.barWidth,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                layout.stackedBarBorderRadius,
              ),
            ),
          );
        } else {
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
                width: layout.barWidth,
                borderRadius: BorderRadius.circular(layout.barBorderRadius),
              ),
            );
          }
        }

        barGroups.add(
          BarChartGroupData(
            x: xIndex,
            barRods: rods,
            barsSpace: layout.barsSpace,
          ),
        );
        xIndex++;
      });
    } else {
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
              width: layout.barWidth,
              borderRadius: BorderRadius.circular(layout.barBorderRadius),
            ),
          );
        }

        barGroups.add(
          BarChartGroupData(
            x: xIndex,
            barRods: rods,
            barsSpace: layout.barsSpace,
          ),
        );
        xIndex++;
      });
    }

    if (maxY == 0) maxY = layout.emptyMaxY;
    maxY *= layout.maxYPaddingFactor;
  }

  @override
  Widget build(BuildContext context) {
    final layout = styleResolver.resolveBarChartLayout();
    final bool isHorizontal =
        widget.type == BarChartType.horizontal ||
        widget.type == BarChartType.horizontalStacked;

    final sideTitles = SideTitles(
      showTitles: layout.showCategoryTitles,
      reservedSize: layout.categoryAxisReservedSize,
      getTitlesWidget: (val, meta) {
        final int index = val.toInt();
        final String text = (index >= 0 && index < xLabels.length)
            ? xLabels[index]
            : '';
        return SideTitleWidget(
          meta: meta,
          child: Text(
            text,
            style: TextStyle(fontSize: layout.categoryLabelFontSize),
          ),
        );
      },
    );
    final axisTitles = AxisTitles(sideTitles: sideTitles);

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: SizedBox(
        height: layout.height,
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            maxY: maxY,
            alignment: _toFlChartAlignment(layout.alignment),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: axisTitles,
            ),
            rotationQuarterTurns: isHorizontal ? 1 : 0,
          ),
        ),
      ),
    );
  }
}
