import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';

/// Renders Adaptive Card line chart elements using fl_chart.
///
/// Registered in the chart element dispatch table for the
/// `Chart.Line` type. Uses [AdaptiveElementWidgetMixin] for element identity
/// and is wrapped in [SeparatorElement] for card layout and spacing.
///
/// See also: https://adaptivecards.microsoft.com/?topic=Chart.Line
class AdaptiveLineChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a line chart element from [adaptiveMap].
  AdaptiveLineChart({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveLineChartState createState() => AdaptiveLineChartState();
}

/// State for [AdaptiveLineChart]; parses JSON data and builds the fl_chart widget.
class AdaptiveLineChartState extends State<AdaptiveLineChart>
    with AdaptiveElementMixin, ProviderScopeMixin {
  /// Parsed line series passed to the underlying [LineChart].
  late List<LineChartBarData> lineBarsData;

  /// Lower bound of the value axis after padding.
  late double minY;

  /// Upper bound of the value axis after padding.
  late double maxY;

  /// Lower bound of the horizontal axis.
  late double minX;

  /// Upper bound of the horizontal axis.
  late double maxX;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseData();
  }

  void _parseData() {
    final layout = styleResolver.resolveLineChartLayout();
    final data = adaptiveMap['data'];
    lineBarsData = [];

    minY = layout.emptyMinY;
    maxY = layout.emptyMaxY;
    minX = layout.emptyMinX;
    maxX = layout.emptyMaxX;

    if (data is! List || data.isEmpty) return;

    minY = double.infinity;
    maxY = double.negativeInfinity;
    minX = double.infinity;
    maxX = double.negativeInfinity;

    final Map<String, List<FlSpot>> seriesSpots = {};
    final Map<String, Color> seriesColors = {};
    final List<Color> defaultPalette = styleResolver.resolveChartPalette();
    int seriesCount = 0;

    for (final item in data) {
      final dynamic rawX = item['x'] ?? 0;
      final double x = (rawX is num) ? rawX.toDouble() : 0.0;

      final dynamic rawY = item['y'] ?? item['value'] ?? 0;
      final double y = (rawY is num) ? rawY.toDouble() : 0.0;

      final String series = item['series']?.toString() ?? 'Default';
      final String? colorStr = item['color']?.toString();

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      if (!seriesSpots.containsKey(series)) {
        seriesSpots[series] = [];
        final Color fallback =
            defaultPalette[seriesCount % defaultPalette.length];
        seriesColors[series] = styleResolver.resolveChartColor(
          colorStr,
          fallback: fallback,
        );
        seriesCount++;
      }
      seriesSpots[series]!.add(FlSpot(x, y));
    }

    if (minX == double.infinity) minX = layout.emptyMinX;
    if (maxX == double.negativeInfinity) maxX = layout.emptyMaxX;
    if (minY == double.infinity) minY = layout.emptyMinY;
    if (maxY == double.negativeInfinity) maxY = layout.emptyMaxY;

    if (maxX == minX) maxX += layout.degenerateRangeBump;
    if (maxY == minY) maxY += layout.degenerateRangeBump;

    double yRange = maxY - minY;
    if (yRange == 0) yRange = layout.zeroRangeFallback;
    maxY += yRange * layout.yAxisPaddingFactor;
    minY -= yRange * layout.yAxisPaddingFactor;

    seriesSpots.forEach((series, spots) {
      spots.sort((a, b) => a.x.compareTo(b.x));

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: layout.isCurved,
          color: seriesColors[series],
          barWidth: layout.barWidth,
          isStrokeCapRound: layout.isStrokeCapRound,
          dotData: FlDotData(show: layout.showDots),
          belowBarData: BarAreaData(show: layout.showAreaBelow),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = styleResolver.resolveLineChartLayout();

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: SizedBox(
        height: layout.height,
        child: LineChart(
          LineChartData(
            lineBarsData: lineBarsData,
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            titlesData: FlTitlesData(
              show: layout.showTitles,
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: layout.showRightTitles),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: layout.showTopTitles),
              ),
            ),
            gridData: FlGridData(show: layout.showGrid),
            borderData: FlBorderData(
              show: layout.showBorder,
              border: Border.all(
                color: layout.borderColor,
                width: layout.borderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
