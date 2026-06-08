import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';

/// Renders Adaptive Card pie and donut chart elements using fl_chart.
///
/// Registered in the chart element dispatch table for the
/// `Chart.Pie`, `Chart.Donut`, and `Chart.Gauge` types. Uses
/// [AdaptiveElementWidgetMixin] for element identity and is wrapped in
/// [SeparatorElement] for card layout and spacing.
///
/// See also:
/// * https://adaptivecards.microsoft.com/?topic=Chart.Pie
/// * https://adaptivecards.microsoft.com/?topic=Chart.Donut
class AdaptivePieChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a pie or donut chart element from [adaptiveMap].
  ///
  /// Set [isDonut] to `true` for donut and gauge-style charts.
  AdaptivePieChart({
    required this.adaptiveMap,
    this.isDonut = false,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  /// Whether to render a donut chart with a hollow center instead of a full pie.
  final bool isDonut;

  @override
  AdaptivePieChartState createState() => AdaptivePieChartState();
}

/// State for [AdaptivePieChart]; parses JSON data and builds the fl_chart widget.
class AdaptivePieChartState extends State<AdaptivePieChart>
    with AdaptiveElementMixin, ProviderScopeMixin {
  /// Parsed pie sections passed to the underlying [PieChart].
  late List<PieChartSectionData> sections;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseData();
  }

  void _parseData() {
    // Expected structure: data: { series: [ { data: [ { x: "Label", y: 10, color: "#FF0000" } ] } ] }
    // Or simplified: data entries.
    // We need to look at AC Chart schema.
    // For now assuming a simple "data" list in properties for quick prototyping if exact schema isn't fully clear.
    // The user linked samples. I don't have them but standard chart data usually has values, labels, colors.

    // Let's assume a "data" property which is a List.
    final data = adaptiveMap['data'];
    sections = [];

    if (data is List) {
      for (final item in data) {
        final double value = (item['value'] as num? ?? item['y'] as num? ?? 0)
            .toDouble();
        final String title =
            item['title']?.toString() ?? item['x']?.toString() ?? '';
        final String? colorStr = item['color']?.toString();
        final List<Color> defaultPalette = styleResolver.resolveChartPalette();
        final Color fallback =
            defaultPalette[sections.length % defaultPalette.length];
        final Color color = styleResolver.resolveChartColor(
          colorStr,
          fallback: fallback,
        );

        sections.add(
          PieChartSectionData(
            value: value,
            title: title,
            color: color,
            radius: widget.isDonut ? 50 : 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: widget.isDonut ? 40 : 0,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }
}
