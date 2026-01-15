import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';

class AdaptivePieChart extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptivePieChart({
    super.key,
    required this.adaptiveMap,
    this.isDonut = false,
  });

  @override
  final Map<String, dynamic> adaptiveMap;
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
    var data = widget.adaptiveMap['data'];
    sections = [];

    if (data is List) {
      for (var item in data) {
        double value = (item['value'] ?? item['y'] ?? 0).toDouble();
        String title = item['title'] ?? item['x'] ?? '';
        String? colorStr = item['color'];
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
            titleStyle: TextStyle(
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
      adaptiveMap: widget.adaptiveMap,
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
