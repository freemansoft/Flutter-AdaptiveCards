import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';

class AdaptiveLineChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveLineChart({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveLineChartState createState() => AdaptiveLineChartState();
}

class AdaptiveLineChartState extends State<AdaptiveLineChart>
    with AdaptiveElementMixin {
  late List<LineChartBarData> lineBarsData;
  late double minY;
  late double maxY;
  late double minX;
  late double maxX;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    var data = widget.adaptiveMap['data'];
    lineBarsData = [];

    // Auto-scale
    minY = double.infinity;
    maxY = double.negativeInfinity;
    minX = double.infinity;
    maxX = double.negativeInfinity;

    if (data is! List) return;

    // Assuming data is flattened points with series info?
    // Or data is list of series?
    // Let's assume generic "points" structure: [{x: 0, y: 10, series: "A"}, {x: 1, y: 12, series: "A"}]

    Map<String, List<FlSpot>> seriesSpots = {};
    Map<String, Color> seriesColors = {};

    for (var item in data) {
      // x must be numeric for LineChart usually, or we index it?
      // If x is categorical string, mapping needed.
      // Assuming numeric X for LineChart for now.
      double x = (item['x'] ?? 0).toDouble();
      double y = (item['y'] ?? item['value'] ?? 0).toDouble();
      String series = item['series'] ?? 'Default';
      String? colorStr = item['color'];

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      if (!seriesSpots.containsKey(series)) {
        seriesSpots[series] = [];
        if (colorStr != null) {
          Color? c = _parseColor(colorStr);
          if (c != null) seriesColors[series] = c;
        }
      }
      seriesSpots[series]!.add(FlSpot(x, y));
    }

    if (minX == double.infinity) minX = 0;
    if (maxX == double.negativeInfinity) maxX = 10;
    if (minY == double.infinity) minY = 0;
    if (maxY == double.negativeInfinity) maxY = 10;

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
          color: seriesColors[series] ?? Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    });
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    colorStr = colorStr.replaceAll('#', '');
    if (colorStr.length == 6) {
      return Color(int.parse('FF$colorStr', radix: 16));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            lineBarsData: lineBarsData,
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true),
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
