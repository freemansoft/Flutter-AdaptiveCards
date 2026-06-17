import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/chart_chrome.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/chart_overlay_mixin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class AdaptiveBarChart extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
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
class AdaptiveBarChartState extends ConsumerState<AdaptiveBarChart>
    with
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin,
        ChartOverlayMixin {
  /// Parsed bar groups passed to the underlying [BarChart].
  late List<BarChartGroupData> barGroups;

  /// Category labels displayed on the chart axis.
  late List<String> xLabels;

  /// Upper bound of the value axis after padding.
  late double maxY;

  /// Per-group display values for `showBarValues`.
  late List<String> barValueLabels;

  String? _chartTitle;
  String? _xAxisTitle;
  String? _yAxisTitle;
  bool _showBarValues = false;
  bool _showLegend = false;
  List<ChartLegendEntry> _legendEntries = [];

  @override
  void onResolvedChartChanged() {
    _parseData();
  }

  void _parseData() {
    final map = resolvedChartMap;
    final layout = styleResolver.resolveBarChartLayout();
    final colorSet = map['colorSet']?.toString();
    final palette = styleResolver.resolveChartPalette(colorSet: colorSet);

    _chartTitle = map['title']?.toString();
    _xAxisTitle = map['xAxisTitle']?.toString();
    _yAxisTitle = map['yAxisTitle']?.toString();
    _showBarValues = map['showBarValues'] as bool? ?? false;
    _showLegend = map['showLegend'] as bool? ?? false;
    _legendEntries = [];

    final data = map['data'];
    barGroups = [];
    xLabels = [];
    barValueLabels = [];
    maxY = layout.emptyMaxY;
    if (data is! List) return;
    maxY = 0;

    final bool isStacked =
        widget.type == BarChartType.horizontalStacked ||
        (widget.type == BarChartType.verticalGrouped &&
            map['stacked'] == true);
    final bool isGrouped =
        widget.type == BarChartType.verticalGrouped &&
        (!map.containsKey('stacked') ||
            map['stacked'] == null ||
            map['stacked'] == false);

    if (isStacked || isGrouped) {
      final Map<String, List<Map<String, dynamic>>> pivotData = {};

      int seriesIndex = 0;
      for (final series in data) {
        final List<dynamic>? points =
            series['data'] as List<dynamic>? ??
            series['values'] as List<dynamic>?;
        if (points == null) continue;

        final String seriesLegend =
            series['legend']?.toString() ?? 'Series ${seriesIndex + 1}';
        final Color defaultSeriesColor =
            palette[seriesIndex % palette.length];
        final Color seriesColor = styleResolver.resolveChartColor(
          series['color']?.toString(),
          fallback: defaultSeriesColor,
        );
        if (_showLegend) {
          _legendEntries.add(
            ChartLegendEntry(label: seriesLegend, color: seriesColor),
          );
        }

        for (final point in points) {
          final String x =
              (point['legend'] ?? point['x'])?.toString() ?? 'Unknown';
          if (!pivotData.containsKey(x)) {
            pivotData[x] = [];
          }
          pivotData[x]!.add({
            'y': point['value'] ?? point['y'] ?? 0,
            'color': point['color'] ?? series['color'],
            'fallbackColor': seriesColor,
          });
        }
        seriesIndex++;
      }

      int xIndex = 0;
      pivotData.forEach((key, items) {
        xLabels.add(key);
        final List<BarChartRodData> rods = [];
        double groupDisplayValue = 0;

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
          groupDisplayValue = runningSum;
          if (runningSum > maxY) maxY = runningSum;

          rods.add(
            BarChartRodData(
              toY: runningSum,
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
            groupDisplayValue = val;
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

        barValueLabels.add(groupDisplayValue.toStringAsFixed(0));
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
        groupedData.putIfAbsent(x, () => []).add(item);
      }

      int xIndex = 0;
      groupedData.forEach((key, items) {
        xLabels.add(key);
        final List<BarChartRodData> rods = [];
        double groupMax = 0;

        for (final item in items) {
          final double val = (item['y'] as num? ?? 0).toDouble();
          if (val > maxY) maxY = val;
          if (val > groupMax) groupMax = val;
          final String? colorStr = item['color']?.toString();
          final Color fallback = palette[rods.length % palette.length];
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

        barValueLabels.add(groupMax.toStringAsFixed(0));
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

  SideTitles _categorySideTitles(BarChartLayout layout) {
    return SideTitles(
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
  }

  @override
  Widget build(BuildContext context) {
    listenForChartOverlayChanges();
    final layout = styleResolver.resolveBarChartLayout();
    final bool isHorizontal =
        widget.type == BarChartType.horizontal ||
        widget.type == BarChartType.horizontalStacked;

    final categoryAxis = _categorySideTitles(layout);
    const valueAxis = SideTitles(
      showTitles: true,
      reservedSize: 28,
    );

    final topValueAxis = SideTitles(
      showTitles: _showBarValues,
      reservedSize: _showBarValues ? 20 : 0,
      getTitlesWidget: (val, meta) {
        final index = val.toInt();
        if (index < 0 || index >= barValueLabels.length) {
          return const SizedBox.shrink();
        }
        return SideTitleWidget(
          meta: meta,
          child: Text(
            barValueLabels[index],
            style: TextStyle(fontSize: layout.categoryLabelFontSize),
          ),
        );
      },
    );

    Widget axisName(String? name) {
      if (name == null || name.isEmpty) return const SizedBox.shrink();
      return Text(name, style: Theme.of(context).textTheme.labelSmall);
    }

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: ChartChrome(
        title: _chartTitle,
        legendEntries: _showLegend ? _legendEntries : const [],
        chart: SizedBox(
          height: layout.height,
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              maxY: maxY,
              alignment: _toFlChartAlignment(layout.alignment),
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  sideTitles: topValueAxis,
                ),
                bottomTitles: AxisTitles(
                  sideTitles: isHorizontal ? valueAxis : categoryAxis,
                  axisNameWidget: isHorizontal
                      ? axisName(_yAxisTitle)
                      : axisName(_xAxisTitle),
                  axisNameSize: 24,
                ),
                leftTitles: AxisTitles(
                  sideTitles: isHorizontal ? categoryAxis : valueAxis,
                  axisNameWidget: isHorizontal
                      ? axisName(_xAxisTitle)
                      : axisName(_yAxisTitle),
                  axisNameSize: 24,
                ),
              ),
              rotationQuarterTurns: isHorizontal ? 1 : 0,
            ),
          ),
        ),
      ),
    ),
    );
  }
}
