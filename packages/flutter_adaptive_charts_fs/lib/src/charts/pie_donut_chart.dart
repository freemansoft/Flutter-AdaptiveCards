import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/chart_chrome.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/chart_overlay_mixin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders Adaptive Card pie and donut chart elements using fl_chart.
///
/// Registered in the chart element dispatch table for the
/// `Chart.Pie` and `Chart.Donut` types. Uses
/// [AdaptiveElementWidgetMixin] for element identity and is wrapped in
/// [SeparatorElement] for card layout and spacing.
///
/// See also:
/// * https://adaptivecards.microsoft.com/?topic=Chart.Pie
/// * https://adaptivecards.microsoft.com/?topic=Chart.Donut
class AdaptivePieChart extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a pie or donut chart element from [adaptiveMap].
  ///
  /// Set [isDonut] to `true` for donut charts.
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
class AdaptivePieChartState extends ConsumerState<AdaptivePieChart>
    with
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin,
        ChartOverlayMixin {
  /// Parsed pie sections passed to the underlying [PieChart].
  late List<PieChartSectionData> sections;

  String? _chartTitle;
  bool _showLegend = false;
  List<ChartLegendEntry> _legendEntries = [];

  @override
  void onResolvedChartChanged() {
    _parseData();
  }

  void _parseData() {
    final map = resolvedChartMap;
    final layout = widget.isDonut
        ? styleResolver.resolveDonutChartLayout()
        : styleResolver.resolvePieChartLayout();
    final colorSet = map['colorSet']?.toString();
    final palette = styleResolver.resolveChartPalette(colorSet: colorSet);
    final sectionRadius = _fitSectionRadius(layout);

    _chartTitle = map['title']?.toString();
    _showLegend = map['showLegend'] as bool? ?? false;
    _legendEntries = [];

    final data = map['data'];
    sections = [];

    if (data is List) {
      for (final item in data) {
        final double value = (item['value'] as num? ?? item['y'] as num? ?? 0)
            .toDouble();
        final String sliceTitle =
            item['legend']?.toString() ??
            item['title']?.toString() ??
            item['x']?.toString() ??
            '';
        final String? colorStr = item['color']?.toString();
        final Color fallback = palette[sections.length % palette.length];
        final Color color = styleResolver.resolveChartColor(
          colorStr,
          fallback: fallback,
        );

        if (_showLegend && sliceTitle.isNotEmpty) {
          _legendEntries.add(
            ChartLegendEntry(label: sliceTitle, color: color),
          );
        }

        sections.add(
          PieChartSectionData(
            value: value,
            title: _showLegend ? '' : sliceTitle,
            color: color,
            radius: sectionRadius,
            titlePositionPercentageOffset: widget.isDonut ? 0.65 : 0.55,
            titleStyle: TextStyle(
              fontSize: layout.titleFontSize,
              fontWeight: layout.titleFontWeight,
              color: layout.titleColor,
            ),
          ),
        );
      }
    }
  }

  /// Keeps slice labels inside the configured chart height (fl_chart canvas).
  double _fitSectionRadius(PieChartLayout layout) {
    const labelPadding = 20.0;
    final maxOuterRadius = (layout.height / 2) - labelPadding;
    final maxSectionRadius = maxOuterRadius - layout.centerSpaceRadius;
    if (maxSectionRadius <= 0) {
      return layout.sectionRadius;
    }
    return layout.sectionRadius.clamp(0.0, maxSectionRadius);
  }

  @override
  Widget build(BuildContext context) {
    listenForChartOverlayChanges();
    final layout = widget.isDonut
        ? styleResolver.resolveDonutChartLayout()
        : styleResolver.resolvePieChartLayout();

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: ChartChrome(
          title: _chartTitle,
          legendEntries: _showLegend ? _legendEntries : const [],
          chart: SizedBox(
            height: layout.height,
            width: double.infinity,
            child: ClipRect(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: layout.centerSpaceRadius,
                  sectionsSpace: layout.sectionsSpace,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
