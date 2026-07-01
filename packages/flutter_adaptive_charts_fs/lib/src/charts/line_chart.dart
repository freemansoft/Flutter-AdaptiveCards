import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/chart_chrome.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/chart_overlay_mixin.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/chart_x_value.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders Adaptive Card line chart elements using fl_chart.
///
/// Registered in the chart element dispatch table for the
/// `Chart.Line` type. Uses [AdaptiveElementWidgetMixin] for element identity
/// and is wrapped in [SeparatorElement] for card layout and spacing.
///
/// See also: https://adaptivecards.microsoft.com/?topic=Chart.Line
class AdaptiveLineChart extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
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

/// State for [AdaptiveLineChart]; parses JSON data and builds the fl_chart
/// widget.
class AdaptiveLineChartState extends ConsumerState<AdaptiveLineChart>
    with
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin,
        ChartOverlayMixin {
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

  String? _chartTitle;
  String? _xAxisTitle;
  String? _yAxisTitle;
  bool _showLegend = false;
  List<ChartLegendEntry> _legendEntries = [];

  @override
  void onResolvedChartChanged() {
    _parseData();
  }

  void _parseData() {
    final map = resolvedChartMap;
    final layout = styleResolver.resolveLineChartLayout();
    final colorSet = map['colorSet']?.toString();
    final palette = styleResolver.resolveChartPalette(colorSet: colorSet);

    _chartTitle = map['title']?.toString();
    _xAxisTitle = map['xAxisTitle']?.toString();
    _yAxisTitle = map['yAxisTitle']?.toString();
    _showLegend = map['showLegend'] as bool? ?? false;
    _legendEntries = [];

    final data = map['data'];
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
    int seriesCount = 0;

    for (final item in data) {
      final double x = parseChartXValue(item['x']);

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
        final Color fallback = palette[seriesCount % palette.length];
        seriesColors[series] = styleResolver.resolveChartColor(
          colorStr,
          fallback: fallback,
        );
        if (_showLegend) {
          _legendEntries.add(
            ChartLegendEntry(label: series, color: seriesColors[series]!),
          );
        }
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

    final yRange = maxY - minY == 0 ? layout.zeroRangeFallback : maxY - minY;
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

  Widget _axisName(BuildContext context, String? name) {
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    return Text(name, style: Theme.of(context).textTheme.labelSmall);
  }

  SideTitles _axisValueTitles(LineChartLayout layout) {
    return SideTitles(
      showTitles: layout.showTitles,
      reservedSize: 32,
      getTitlesWidget: (val, meta) {
        if (!layout.showTitles) {
          return const SizedBox.shrink();
        }
        final label = val % 1 == 0
            ? val.toInt().toString()
            : val.toStringAsFixed(1);
        return SideTitleWidget(
          meta: meta,
          child: Text(label, style: const TextStyle(fontSize: 10)),
        );
      },
    );
  }

  double _axisNameSize(String? name) =>
      name != null && name.isNotEmpty ? 24 : 0;

  @override
  Widget build(BuildContext context) {
    listenForChartOverlayChanges();
    final layout = styleResolver.resolveLineChartLayout();

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: ChartChrome(
          title: _chartTitle,
          legendEntries: _showLegend ? _legendEntries : const [],
          chart: SizedBox(
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
                  bottomTitles: AxisTitles(
                    sideTitles: _axisValueTitles(layout),
                    axisNameWidget: _axisName(context, _xAxisTitle),
                    axisNameSize: _axisNameSize(_xAxisTitle),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: _axisValueTitles(layout),
                    axisNameWidget: _axisName(context, _yAxisTitle),
                    axisNameSize: _axisNameSize(_yAxisTitle),
                  ),
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
        ),
      ),
    );
  }
}
