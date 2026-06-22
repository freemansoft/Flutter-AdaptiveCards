import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/chart_overlay_mixin.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/gauge_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders Adaptive Card `Chart.Gauge` elements using [CustomPainter].
///
/// Registered in `CardChartsRegistry` for the `Chart.Gauge` type. Uses
/// [AdaptiveElementWidgetMixin] for element identity and is wrapped in
/// [SeparatorElement] for card layout and spacing.
///
/// See also:
/// * https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/charts-in-adaptive-cards
class AdaptiveGaugeChart extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a gauge chart element from [adaptiveMap].
  AdaptiveGaugeChart({required this.adaptiveMap})
    : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveGaugeChartState createState() => AdaptiveGaugeChartState();
}

/// State for [AdaptiveGaugeChart]; parses JSON and builds the gauge widget.
class AdaptiveGaugeChartState extends ConsumerState<AdaptiveGaugeChart>
    with
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin,
        ChartOverlayMixin {
  late double _value;
  late double _min;
  late double _max;
  late List<GaugeSegment> _segments;
  late String? _title;
  late String? _subLabel;
  late bool _showLegend;
  late bool _showMinMax;
  late GaugeValueFormat _valueFormat;

  @override
  void onResolvedChartChanged() {
    _parseData();
  }

  void _parseData() {
    final map = resolvedChartMap;
    _value = (map['value'] as num?)?.toDouble() ?? 0;
    _min = (map['min'] as num?)?.toDouble() ?? 0;
    _max = (map['max'] as num?)?.toDouble() ?? 100;
    _title = map['title']?.toString();
    _subLabel = map['subLabel']?.toString();
    _showLegend = map['showLegend'] as bool? ?? true;
    _showMinMax = map['showMinMax'] as bool? ?? true;
    _valueFormat = _parseValueFormat(map['valueFormat']?.toString());
    _segments = _parseSegments(map['segments'], map);
  }

  GaugeValueFormat _parseValueFormat(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'fraction':
        return GaugeValueFormat.fraction;
      case 'percentage':
      default:
        return GaugeValueFormat.percentage;
    }
  }

  List<GaugeSegment> _parseSegments(
    Object? raw,
    Map<String, dynamic> map,
  ) {
    if (raw is! List) {
      return const [];
    }

    final colorSet = map['colorSet']?.toString();
    final palette = styleResolver.resolveChartPalette(colorSet: colorSet);
    final segments = <GaugeSegment>[];

    for (var index = 0; index < raw.length; index++) {
      final item = raw[index];
      if (item is! Map) {
        continue;
      }

      final size = (item['value'] as num?)?.toDouble() ?? 0;
      final colorStr = item['color']?.toString();
      final fallback = palette[index % palette.length];
      final color = styleResolver.resolveChartColor(
        colorStr,
        fallback: fallback,
      );

      segments.add(
        GaugeSegment(
          color: color,
          size: size,
          legend: item['legend']?.toString(),
        ),
      );
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    listenForChartOverlayChanges();
    final layout = styleResolver.resolveDonutChartLayout();
    final theme = Theme.of(context);
    final labelStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final valueStyle =
        (theme.textTheme.titleLarge ?? const TextStyle(fontSize: 22)).copyWith(
          fontWeight: FontWeight.bold,
        );
    final subLabelStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    final chart = SizedBox(
      height: layout.height,
      child: CustomPaint(
        painter: GaugePainter(
          value: _value,
          min: _min,
          max: _max,
          segments: _segments,
          showMinMax: _showMinMax,
          valueFormat: _valueFormat,
          subLabel: _subLabel,
          trackColor: theme.colorScheme.surfaceContainerHighest,
          needleColor: theme.colorScheme.onSurface,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
          subLabelStyle: subLabelStyle,
        ),
      ),
    );

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: _GaugeChrome(
          title: _title,
          showLegend: _showLegend,
          segments: _segments,
          chart: chart,
        ),
      ),
    );
  }
}

/// Title, chart body, and optional segment legend (inline chrome wrapper).
class _GaugeChrome extends StatelessWidget {
  const _GaugeChrome({
    required this.title,
    required this.showLegend,
    required this.segments,
    required this.chart,
  });

  final String? title;
  final bool showLegend;
  final List<GaugeSegment> segments;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final titleText = title;
    final legendEntries = segments
        .where(
          (segment) => segment.legend != null && segment.legend!.isNotEmpty,
        )
        .map(
          (segment) => Padding(
            padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: segment.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(segment.legend!),
              ],
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (titleText != null && titleText.isNotEmpty) ...[
          Text(
            titleText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        chart,
        if (showLegend && legendEntries.isNotEmpty)
          Wrap(children: legendEntries),
      ],
    );
  }
}
