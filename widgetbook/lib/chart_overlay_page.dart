// Host-only demo: calls [RawAdaptiveCardState.setChartData] / [patchChartProperties].

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/overlay_demo_scaffold.dart';
import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

enum ChartOverlayTitlePreset { baseline, updated, hidden }

const _chartId = 'demoChart';

final chartOverlayPageKey = GlobalKey<State<ChartOverlayPage>>();

class ChartOverlayPage extends StatefulWidget {
  const ChartOverlayPage({super.key});

  @override
  State<ChartOverlayPage> createState() => _ChartOverlayPageState();
}

class _ChartOverlayPageState extends State<ChartOverlayPage>
    with OverlayDemoPageState<ChartOverlayPage> {
  static const _assetPath = 'lib/samples/charts/chart_overlay_demo.json';

  ChartOverlayTitlePreset? _lastAppliedTitlePreset;
  double? _lastAppliedFirstBarValue;
  ChartOverlayTitlePreset? _pendingTitlePreset;
  double? _pendingFirstBarValue;
  ChartOverlayTitlePreset? _lastSeenTitlePresetKnob;
  double? _lastSeenFirstBarValueKnob;
  bool _knobsInitialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(loadOverlayCardAsset(_assetPath));
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
    scheduleOverlayApply(_flushPendingOverlay);
  }

  void _flushPendingOverlay() {
    final titlePreset = _pendingTitlePreset;
    final firstBarValue = _pendingFirstBarValue;
    if (titlePreset == null || firstBarValue == null) return;

    runWhenCardReady(
      (cardState) {
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
      },
      reschedule: () => scheduleOverlayApply(_flushPendingOverlay),
    );
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

    return buildOverlayCard(
      registry: widgetbookChartOverlayCardTypeRegistry,
      wrapScrollView: false,
    );
  }
}
