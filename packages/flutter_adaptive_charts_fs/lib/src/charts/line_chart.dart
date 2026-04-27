import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';

///
/// https://adaptivecards.microsoft.com/?topic=Chart.Line
///
class AdaptiveLineChart extends StatefulWidget with AdaptiveElementWidgetMixin {
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

class AdaptiveLineChartState extends State<AdaptiveLineChart>
    with AdaptiveElementMixin, ProviderScopeMixin {
  late List<LineChartBarData> lineBarsData;
  late double minY;
  late double maxY;
  late double minX;
  late double maxX;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseData();
  }

  void _parseData() {
    final data = adaptiveMap['data'];
    lineBarsData = [];

    // Auto-scale defaults
    minY = 0;
    maxY = 10;
    minX = 0;
    maxX = 10;

    if (data is! List || data.isEmpty) return;

    // Reset for actual data
    minY = double.infinity;
    maxY = double.negativeInfinity;
    minX = double.infinity;
    maxX = double.negativeInfinity;

    final Map<String, List<FlSpot>> seriesSpots = {};
    final Map<String, Color> seriesColors = {};
    final List<Color> defaultPalette = styleResolver.resolveChartPalette();
    int seriesCount = 0;

    for (final item in data) {
      // Assuming numeric X for LineChart for now.
      // If x is a string, it will be handled as 0 due to toDouble() fallback?
      // Actually toDouble() on a string will throw.
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

    if (minX == double.infinity) minX = 0;
    if (maxX == double.negativeInfinity) maxX = 10;
    if (minY == double.infinity) minY = 0;
    if (maxY == double.negativeInfinity) maxY = 10;

    // Ensure range > 0
    if (maxX == minX) maxX += 1;
    if (maxY == minY) maxY += 1;

    // Padding
    double yRange = maxY - minY;
    if (yRange == 0) yRange = 10;
    maxY += yRange * 0.1;
    minY -= yRange * 0.1;

    seriesSpots.forEach((series, spots) {
      // Sort spots by x
      spots.sort((a, b) => a.x.compareTo(b.x));

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: seriesColors[series],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            lineBarsData: lineBarsData,
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            titlesData: const FlTitlesData(
              show: true,
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
