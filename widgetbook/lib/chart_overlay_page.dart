// Host-only demo: calls [RawAdaptiveCardState.setChartData] / [patchChartProperties].

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:widgetbook/widgetbook.dart';

enum ChartOverlayTitlePreset { baseline, updated, hidden }

const _chartId = 'demoChart';

final chartOverlayPageKey = GlobalKey<State<ChartOverlayPage>>();

class ChartOverlayPage extends StatefulWidget {
  const ChartOverlayPage({super.key});

  @override
  State<ChartOverlayPage> createState() => _ChartOverlayPageState();
}

class _ChartOverlayPageState extends State<ChartOverlayPage> {
  static const _assetPath = 'lib/samples/charts/chart_overlay_demo.json';
  static const _maxApplyAttempts = 30;

  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();
  late final CardTypeRegistry _cardTypeRegistry = CardTypeRegistry(
    addedElements: CardChartsRegistry.additionalChartElements,
    overlayExtensions: CardChartsRegistry.overlayExtensions,
  );

  Map<String, dynamic>? _cardMap;
  ChartOverlayTitlePreset? _lastAppliedTitlePreset;
  double? _lastAppliedFirstBarValue;
  ChartOverlayTitlePreset? _pendingTitlePreset;
  double? _pendingFirstBarValue;
  ChartOverlayTitlePreset? _lastSeenTitlePresetKnob;
  double? _lastSeenFirstBarValueKnob;
  bool _knobsInitialized = false;
  int _applyAttempts = 0;
  bool _applyScheduled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCard());
  }

  Future<void> _loadCard() async {
    final json = await rootBundle.loadString(_assetPath);
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() => _cardMap = map);
  }

  void _queueOverlay({
    required ChartOverlayTitlePreset titlePreset,
    required double firstBarValue,
  }) {
    _pendingTitlePreset = titlePreset;
    _pendingFirstBarValue = firstBarValue;
    if (_lastAppliedTitlePreset == titlePreset &&
        _lastAppliedFirstBarValue == firstBarValue) {
      return;
    }
    _scheduleApplyOverlay();
  }

  void _scheduleApplyOverlay() {
    if (_applyScheduled) return;
    _applyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyScheduled = false;
      _flushPendingOverlay();
    });
  }

  void _flushPendingOverlay() {
    final titlePreset = _pendingTitlePreset;
    final firstBarValue = _pendingFirstBarValue;
    if (!mounted || _cardMap == null || titlePreset == null) return;
    if (firstBarValue == null) return;

    final cardState = _cardKey.currentState;
    if (cardState == null || cardState.documentContainer == null) {
      if (_applyAttempts < _maxApplyAttempts) {
        _applyAttempts++;
        _scheduleApplyOverlay();
      }
      return;
    }

    _applyAttempts = 0;
    if (_lastAppliedTitlePreset == titlePreset &&
        _lastAppliedFirstBarValue == firstBarValue) {
      return;
    }

    switch (titlePreset) {
      case ChartOverlayTitlePreset.baseline:
        cardState.clearChartProperties(_chartId);
      case ChartOverlayTitlePreset.updated:
        cardState.patchChartProperties(_chartId, {
          'title': 'Updated title',
        });
      case ChartOverlayTitlePreset.hidden:
        cardState.patchChartProperties(_chartId, {
          'title': '',
        });
    }

    cardState.setChartData(_chartId, [
      {'x': 'Category A', 'y': firstBarValue, 'color': '#FF0000'},
      {'x': 'Category B', 'y': 25, 'color': '#00FF00'},
      {'x': 'Category C', 'y': 15, 'color': '#0000FF'},
    ]);

    _lastAppliedTitlePreset = titlePreset;
    _lastAppliedFirstBarValue = firstBarValue;
  }

  @override
  Widget build(BuildContext context) {
    final titlePreset = context.knobs.object.dropdown<ChartOverlayTitlePreset>(
      label: 'Chart title preset',
      options: ChartOverlayTitlePreset.values,
      initialOption: ChartOverlayTitlePreset.baseline,
      labelBuilder: (value) => switch (value) {
        ChartOverlayTitlePreset.baseline => 'Baseline title',
        ChartOverlayTitlePreset.updated => 'Updated title',
        ChartOverlayTitlePreset.hidden => 'Empty title',
      },
    );
    final firstBarValue = context.knobs.double.slider(
      label: 'Category A bar value',
      initialValue: 10,
      min: 0,
      max: 50,
    );

    if (!_knobsInitialized) {
      _knobsInitialized = true;
      _lastSeenTitlePresetKnob = titlePreset;
      _lastSeenFirstBarValueKnob = firstBarValue;
    } else if (_lastSeenTitlePresetKnob != titlePreset ||
        _lastSeenFirstBarValueKnob != firstBarValue) {
      _lastSeenTitlePresetKnob = titlePreset;
      _lastSeenFirstBarValueKnob = firstBarValue;
      _queueOverlay(
        titlePreset: titlePreset,
        firstBarValue: firstBarValue,
      );
    }

    final cardMap = _cardMap;
    if (cardMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RawAdaptiveCard.fromMap(
      key: _cardKey,
      map: cardMap,
      cardTypeRegistry: _cardTypeRegistry,
      hostConfigs: HostConfigs(),
    );
  }
}
