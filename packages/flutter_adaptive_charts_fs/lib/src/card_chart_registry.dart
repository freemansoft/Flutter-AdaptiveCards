import 'package:flutter/material.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/bar_chart.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/gauge_chart.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/line_chart.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/pie_donut_chart.dart';

/// Builds an Adaptive Card element widget from its JSON [map].
typedef ElementCreator = Widget Function(Map<String, dynamic> map);

/// Registry of chart element type strings to widget builders for the card renderer.
///
/// Merge [additionalChartElements] into the host app's element dispatch table
/// (via `addElements`) so `Chart.*` types render with [AdaptivePieChart],
/// [AdaptiveLineChart], and [AdaptiveBarChart].
class CardChartsRegistry {
  /// Maps Adaptive Card chart type strings (for example `Chart.Line`) to
  /// [ElementCreator] builders registered with the card renderer.
  static Map<String, ElementCreator> additionalChartElements = {
    'Chart.Donut': (map) => AdaptivePieChart(
      adaptiveMap: map,
      isDonut: true,
    ),
    'Chart.Pie': (map) => AdaptivePieChart(
      adaptiveMap: map,
      isDonut: false,
    ),
    'Chart.Gauge': (map) => AdaptiveGaugeChart(adaptiveMap: map),

    'Chart.Line': (map) => AdaptiveLineChart(adaptiveMap: map),

    'Chart.VerticalBar': (map) => AdaptiveBarChart(
      adaptiveMap: map,
      type: BarChartType.vertical,
    ),
    'Chart.HorizontalBar': (map) => AdaptiveBarChart(
      adaptiveMap: map,
      type: BarChartType.horizontal,
    ),
    'Chart.HorizontalBar.Stacked': (map) => AdaptiveBarChart(
      adaptiveMap: map,
      type: BarChartType.horizontalStacked,
    ),
    'Chart.VerticalBar.Grouped': (map) => AdaptiveBarChart(
      adaptiveMap: map,
      type: BarChartType.verticalGrouped,
    ),
  };
}
