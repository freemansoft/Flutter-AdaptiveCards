// Host-only demo: rebuilds card JSON from knobs to patch chart properties.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:widgetbook/widgetbook.dart';

/// Default knob values extracted from the first chart in a sample card.
class ChartKnobDefaults {
  /// Creates defaults for Widgetbook chart property knobs.
  const ChartKnobDefaults({
    this.title = '',
    this.xAxisTitle = '',
    this.yAxisTitle = '',
    this.subLabel = '',
    this.showBarValues = false,
    this.showLegend = false,
    this.showMinMax = true,
    this.colorSet = 'default',
    this.sampleValue = 50,
    this.gaugeMin = 0,
    this.gaugeMax = 100,
    this.gaugeValue = 50,
    this.valueFormat = 'Percentage',
  });

  final String title;
  final String xAxisTitle;
  final String yAxisTitle;
  final String subLabel;
  final bool showBarValues;
  final bool showLegend;
  final bool showMinMax;
  final String colorSet;
  final double sampleValue;
  final double gaugeMin;
  final double gaugeMax;
  final double gaugeValue;
  final String valueFormat;
}

/// Keeps knob-driven chart pages mounted when Widgetbook query params change.
final chartKnobsPageKeys = <String, GlobalKey<State<ChartKnobsPage>>>{
  'lib/samples/charts/chart_knobs_demo.json':
      GlobalKey<State<ChartKnobsPage>>(),
  'lib/samples/v1.6/chart_donut.json': GlobalKey<State<ChartKnobsPage>>(),
  'lib/samples/v1.6/chart_pie.json': GlobalKey<State<ChartKnobsPage>>(),
  'lib/samples/v1.6/chart_bar_vertical.json':
      GlobalKey<State<ChartKnobsPage>>(),
  'lib/samples/v1.6/chart_bar_horizontal.json':
      GlobalKey<State<ChartKnobsPage>>(),
  'lib/samples/v1.6/chart_bar_vertical_grouped.json':
      GlobalKey<State<ChartKnobsPage>>(),
  'lib/samples/v1.6/chart_bar_horizontal_stacked.json':
      GlobalKey<State<ChartKnobsPage>>(),
  'lib/samples/v1.6/chart_line.json': GlobalKey<State<ChartKnobsPage>>(),
  'lib/samples/v1.6/chart_gauge.json': GlobalKey<State<ChartKnobsPage>>(),
};

GlobalKey<State<ChartKnobsPage>> chartKnobsPageKeyFor(String assetPath) {
  return chartKnobsPageKeys.putIfAbsent(
    assetPath,
    GlobalKey<State<ChartKnobsPage>>.new,
  );
}

/// Widgetbook page that deep-clones base card JSON and patches chart elements.
class ChartKnobsPage extends StatefulWidget {
  /// Creates a chart knobs page for the sample at [assetPath].
  const ChartKnobsPage({required this.assetPath, super.key});

  /// Asset path to the Adaptive Card JSON (Widgetbook bundle path).
  final String assetPath;

  @override
  State<ChartKnobsPage> createState() => _ChartKnobsPageState();
}

class _ChartKnobsPageState extends State<ChartKnobsPage> {
  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();
  late final CardTypeRegistry _cardTypeRegistry = CardTypeRegistry(
    addedElements: CardChartsRegistry.additionalChartElements,
  );

  Map<String, dynamic>? _baseCardMap;
  ChartKnobDefaults? _defaults;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCard());
  }

  Future<void> _loadCard() async {
    final json = await rootBundle.loadString(widget.assetPath);
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (!mounted) {
      return;
    }
    setState(() {
      _baseCardMap = map;
      _defaults = _extractDefaults(map);
    });
  }

  ChartKnobDefaults _extractDefaults(Map<String, dynamic> root) {
    final charts = _findCharts(root);
    if (charts.isEmpty) {
      return const ChartKnobDefaults();
    }

    final first = charts.first;
    final type = first['type']?.toString() ?? '';

    return ChartKnobDefaults(
      title: first['title']?.toString() ?? '',
      xAxisTitle: first['xAxisTitle']?.toString() ?? '',
      yAxisTitle: first['yAxisTitle']?.toString() ?? '',
      subLabel: first['subLabel']?.toString() ?? '',
      showBarValues: first['showBarValues'] as bool? ?? false,
      showLegend: first['showLegend'] as bool? ?? false,
      showMinMax: first['showMinMax'] as bool? ?? true,
      colorSet: first['colorSet']?.toString() ?? 'default',
      sampleValue: _readSampleValue(first, type),
      gaugeMin: (first['min'] as num?)?.toDouble() ?? 0,
      gaugeMax: (first['max'] as num?)?.toDouble() ?? 100,
      gaugeValue: (first['value'] as num?)?.toDouble() ?? 50,
      valueFormat: first['valueFormat']?.toString() ?? 'Percentage',
    );
  }

  double _readSampleValue(Map<String, dynamic> chart, String type) {
    if (type == 'Chart.Gauge') {
      return (chart['value'] as num?)?.toDouble() ?? 50;
    }

    final data = chart['data'];
    if (data is! List || data.isEmpty) {
      return 50;
    }

    final first = data.first;
    if (first is! Map) {
      return 50;
    }

    if (first['y'] is num) {
      return (first['y'] as num).toDouble();
    }
    if (first['value'] is num) {
      return (first['value'] as num).toDouble();
    }

    final values = first['values'];
    if (values is List && values.isNotEmpty) {
      final v0 = values.first;
      if (v0 is Map && v0['y'] is num) {
        return (v0['y'] as num).toDouble();
      }
    }

    final nested = first['data'];
    if (nested is List && nested.isNotEmpty) {
      final d0 = nested.first;
      if (d0 is Map && d0['value'] is num) {
        return (d0['value'] as num).toDouble();
      }
    }

    return 50;
  }

  List<Map<String, dynamic>> _findCharts(Map<String, dynamic> root) {
    final charts = <Map<String, dynamic>>[];
    _collectCharts(root, charts);
    return charts;
  }

  void _collectCharts(Object? node, List<Map<String, dynamic>> charts) {
    if (node is Map<String, dynamic>) {
      final type = node['type']?.toString();
      if (type != null && type.startsWith('Chart.')) {
        charts.add(node);
      }
      for (final value in node.values) {
        _collectCharts(value, charts);
      }
    } else if (node is List) {
      for (final item in node) {
        _collectCharts(item, charts);
      }
    }
  }

  bool _isBarChartType(String type) => type.contains('Bar');

  Map<String, dynamic> _cloneAndPatchCharts({
    required String title,
    required String xAxisTitle,
    required String yAxisTitle,
    required String subLabel,
    required bool showBarValues,
    required bool showLegend,
    required bool showMinMax,
    required String colorSet,
    required double sampleValue,
    required double gaugeMin,
    required double gaugeMax,
    required double gaugeValue,
    required String valueFormat,
  }) {
    final patched =
        jsonDecode(jsonEncode(_baseCardMap)) as Map<String, dynamic>;
    for (final chart in _findCharts(patched)) {
      _patchChart(
        chart,
        title: title,
        xAxisTitle: xAxisTitle,
        yAxisTitle: yAxisTitle,
        subLabel: subLabel,
        showBarValues: showBarValues,
        showLegend: showLegend,
        showMinMax: showMinMax,
        colorSet: colorSet,
        sampleValue: sampleValue,
        gaugeMin: gaugeMin,
        gaugeMax: gaugeMax,
        gaugeValue: gaugeValue,
        valueFormat: valueFormat,
      );
    }
    return patched;
  }

  void _patchChart(
    Map<String, dynamic> chart, {
    required String title,
    required String xAxisTitle,
    required String yAxisTitle,
    required String subLabel,
    required bool showBarValues,
    required bool showLegend,
    required bool showMinMax,
    required String colorSet,
    required double sampleValue,
    required double gaugeMin,
    required double gaugeMax,
    required double gaugeValue,
    required String valueFormat,
  }) {
    final type = chart['type']?.toString() ?? '';

    if (title.isEmpty) {
      chart.remove('title');
    } else {
      chart['title'] = title;
    }
    chart['showLegend'] = showLegend;
    if (colorSet == 'default') {
      chart.remove('colorSet');
    } else {
      chart['colorSet'] = colorSet;
    }

    if (_isBarChartType(type)) {
      chart['xAxisTitle'] = xAxisTitle;
      chart['yAxisTitle'] = yAxisTitle;
      chart['showBarValues'] = showBarValues;
      _patchSampleValue(chart, sampleValue);
    } else if (type == 'Chart.Line') {
      chart['xAxisTitle'] = xAxisTitle;
      chart['yAxisTitle'] = yAxisTitle;
      _patchSampleValue(chart, sampleValue);
    } else if (type == 'Chart.Pie' || type == 'Chart.Donut') {
      _patchSampleValue(chart, sampleValue);
    } else if (type == 'Chart.Gauge') {
      chart['subLabel'] = subLabel;
      chart['min'] = gaugeMin;
      chart['max'] = gaugeMax;
      chart['value'] = gaugeValue;
      chart['valueFormat'] = valueFormat;
      chart['showMinMax'] = showMinMax;
    }
  }

  void _patchSampleValue(Map<String, dynamic> chart, double sampleValue) {
    final data = chart['data'];
    if (data is! List || data.isEmpty) {
      return;
    }

    final first = data.first;
    if (first is! Map) {
      return;
    }

    if (first.containsKey('y')) {
      first['y'] = sampleValue;
      return;
    }
    if (first.containsKey('value')) {
      first['value'] = sampleValue;
      return;
    }

    final values = first['values'];
    if (values is List && values.isNotEmpty) {
      final v0 = values.first;
      if (v0 is Map && v0.containsKey('y')) {
        v0['y'] = sampleValue;
      }
      return;
    }

    final nested = first['data'];
    if (nested is List && nested.isNotEmpty) {
      final d0 = nested.first;
      if (d0 is Map && d0.containsKey('value')) {
        d0['value'] = sampleValue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Knobs must be read on every build before any early return so Widgetbook
    // registers them (same pattern as TextBlockOverlayPage).
    final defaults = _defaults ?? const ChartKnobDefaults();

    final title = context.knobs.string(
      label: 'title',
      initialValue: defaults.title,
    );
    final xAxisTitle = context.knobs.string(
      label: 'xAxisTitle',
      initialValue: defaults.xAxisTitle.isNotEmpty
          ? defaults.xAxisTitle
          : 'Category',
    );
    final yAxisTitle = context.knobs.string(
      label: 'yAxisTitle',
      initialValue: defaults.yAxisTitle.isNotEmpty ? defaults.yAxisTitle : 'Value',
    );
    final subLabel = context.knobs.string(
      label: 'subLabel',
      initialValue: defaults.subLabel.isNotEmpty ? defaults.subLabel : 'Target',
    );
    final showBarValues = context.knobs.boolean(
      label: 'showBarValues',
      initialValue: defaults.showBarValues,
    );
    final showLegend = context.knobs.boolean(
      label: 'showLegend',
      initialValue: defaults.showLegend,
    );
    final showMinMax = context.knobs.boolean(
      label: 'showMinMax',
      initialValue: defaults.showMinMax,
    );
    const colorSetOptions = [
      'default',
      'categorical',
      'sequential',
      'diverging',
    ];
    final initialColorSet = colorSetOptions.contains(defaults.colorSet)
        ? defaults.colorSet
        : 'default';
    final colorSet = context.knobs.object.dropdown<String>(
      label: 'colorSet',
      options: colorSetOptions,
      initialOption: initialColorSet,
      labelBuilder: (value) => value,
    );
    final sampleValue = context.knobs.double.slider(
      label: 'sampleValue',
      initialValue: defaults.sampleValue,
      min: 0,
      max: 400,
      divisions: 80,
    );
    final gaugeMin = context.knobs.double.slider(
      label: 'gaugeMin',
      initialValue: defaults.gaugeMin,
      min: 0,
      max: 200,
      divisions: 40,
    );
    final gaugeMax = context.knobs.double.slider(
      label: 'gaugeMax',
      initialValue: defaults.gaugeMax,
      min: 1,
      max: 400,
      divisions: 80,
    );
    final gaugeValue = context.knobs.double.slider(
      label: 'gaugeValue',
      initialValue: defaults.gaugeValue,
      min: gaugeMin,
      max: gaugeMax,
      divisions: 80,
    );
    const valueFormatOptions = ['Percentage', 'Fraction'];
    final initialValueFormat = valueFormatOptions.contains(defaults.valueFormat)
        ? defaults.valueFormat
        : 'Percentage';
    final valueFormat = context.knobs.object.dropdown<String>(
      label: 'valueFormat',
      options: valueFormatOptions,
      initialOption: initialValueFormat,
      labelBuilder: (value) => value,
    );

    final baseCardMap = _baseCardMap;
    if (baseCardMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cardMap = _cloneAndPatchCharts(
      title: title,
      xAxisTitle: xAxisTitle,
      yAxisTitle: yAxisTitle,
      subLabel: subLabel,
      showBarValues: showBarValues,
      showLegend: showLegend,
      showMinMax: showMinMax,
      colorSet: colorSet,
      sampleValue: sampleValue,
      gaugeMin: gaugeMin,
      gaugeMax: gaugeMax,
      gaugeValue: gaugeValue,
      valueFormat: valueFormat,
    );

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: RawAdaptiveCard.fromMap(
          key: _cardKey,
          map: cardMap,
          cardTypeRegistry: _cardTypeRegistry,
          hostConfigs: HostConfigs(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
