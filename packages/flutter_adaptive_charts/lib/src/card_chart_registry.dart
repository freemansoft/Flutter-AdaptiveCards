import 'package:flutter/material.dart';
import 'package:flutter_adaptive_charts/src/charts/bar_chart.dart';
import 'package:flutter_adaptive_charts/src/charts/line_chart.dart';
import 'package:flutter_adaptive_charts/src/charts/pie_donut_chart.dart';

typedef ElementCreator = Widget Function(Map<String, dynamic> map);

///
/// Passed in as add elements when we want to add charts to the dispatch table
///

class CardChartsRegistry {
  static Map<String, ElementCreator> additionalChartElements = {
    'Chart.Donut': (map) => AdaptivePieChart(
      adaptiveMap: map,
      isDonut: true,
    ),
    'Chart.Pie': (map) => AdaptivePieChart(
      adaptiveMap: map,
      isDonut: false,
    ),
    'Chart.Gauge':
        // Implementing Gauge as Donut for now (or Pie)
        (map) => AdaptivePieChart(
          adaptiveMap: map,
          isDonut: true,
        ),

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
      type: BarChartType.grouped,
    ),
  };
}
