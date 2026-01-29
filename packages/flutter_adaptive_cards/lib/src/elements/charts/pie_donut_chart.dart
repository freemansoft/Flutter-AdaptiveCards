import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

///
/// https://adaptivecards.microsoft.com/?topic=Chart.Pie
/// https://adaptivecards.microsoft.com/?topic=Chart.Donut
///
class AdaptivePieChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptivePieChart({
    required this.adaptiveMap,
    this.isDonut = false,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  final bool isDonut;

  @override
  AdaptivePieChartState createState() => AdaptivePieChartState();
}

class AdaptivePieChartState extends State<AdaptivePieChart>
    with AdaptiveElementMixin {
  late List<PieChartSectionData> sections;

  @override
  void initState() {
    super.initState();
    // Parse data
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
        String? colorStr = item['color']?.toString();
        Color color = Colors.blue;
        if (colorStr != null) {
          // Basic hex parsing - improving later
          colorStr = colorStr.replaceAll('#', '');
          if (colorStr.length == 6) {
            color = Color(int.parse('FF$colorStr', radix: 16));
          }
        }

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
