// Host-only demo: calls [RawAdaptiveCardState.setFacts] on the rendered card.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/overlay_demo_scaffold.dart';
import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

enum FactSetOverlayPreset { baseline, colors, cities, foods }

const _factSetId = 'demoFactSet';

const _colorsFacts = [
  Fact(title: 'Red', value: '#FF0000'),
  Fact(title: 'Blue', value: '#0000FF'),
  Fact(title: 'Green', value: '#00FF00'),
  Fact(title: 'Yellow', value: '#FFFF00'),
];

const _citiesFacts = [
  Fact(title: 'New York', value: 'USA'),
  Fact(title: 'Paris', value: 'France'),
  Fact(title: 'Tokyo', value: 'Japan'),
  Fact(title: 'Sydney', value: 'Australia'),
];

const _foodsFacts = [
  Fact(title: 'Pizza', value: 'Italy'),
  Fact(title: 'Sushi', value: 'Japan'),
  Fact(title: 'Tacos', value: 'Mexico'),
  Fact(title: 'Pasta', value: 'Italy'),
];

List<Fact>? factsForPreset(FactSetOverlayPreset preset) {
  return switch (preset) {
    FactSetOverlayPreset.baseline => null,
    FactSetOverlayPreset.colors => _colorsFacts,
    FactSetOverlayPreset.cities => _citiesFacts,
    FactSetOverlayPreset.foods => _foodsFacts,
  };
}

final factSetOverlayPageKey = GlobalKey<State<FactSetOverlayPage>>();

class FactSetOverlayPage extends StatefulWidget {
  const FactSetOverlayPage({super.key});

  @override
  State<FactSetOverlayPage> createState() => _FactSetOverlayPageState();
}

class _FactSetOverlayPageState extends State<FactSetOverlayPage>
    with OverlayDemoPageState<FactSetOverlayPage> {
  static const _assetPath = 'lib/samples/fact_set/facts_overlay_demo.json';

  FactSetOverlayPreset? _lastAppliedPreset;
  FactSetOverlayPreset? _pendingPreset;
  FactSetOverlayPreset? _lastSeenPresetKnob;
  bool _knobsInitialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(loadOverlayCardAsset(_assetPath));
  }

  void _queueFactsOverlay(FactSetOverlayPreset preset) {
    _pendingPreset = preset;
    if (_lastAppliedPreset == preset) return;
    scheduleOverlayApply(_flushPendingOverlay);
  }

  void _flushPendingOverlay() {
    final preset = _pendingPreset;
    if (preset == null) return;

    runWhenCardReady(
      (cardState) {
        if (_lastAppliedPreset == preset) return;

        if (preset == FactSetOverlayPreset.baseline) {
          cardState.clearFacts(_factSetId);
        } else {
          cardState.setFacts(_factSetId, factsForPreset(preset)!);
        }
        _lastAppliedPreset = preset;
      },
      reschedule: () => scheduleOverlayApply(_flushPendingOverlay),
    );
  }

  void _syncPresetKnob(FactSetOverlayPreset preset) {
    if (!_knobsInitialized) {
      _knobsInitialized = true;
      _lastSeenPresetKnob = preset;
      return;
    }

    if (preset == _lastSeenPresetKnob) return;
    _lastSeenPresetKnob = preset;
    _queueFactsOverlay(preset);
  }

  @override
  Widget build(BuildContext context) {
    final preset = context.knobs.object.dropdown<FactSetOverlayPreset>(
      label: 'Baseline restores to preset',
      options: FactSetOverlayPreset.values,
      initialOption: FactSetOverlayPreset.baseline,
      labelBuilder: (value) => switch (value) {
        FactSetOverlayPreset.baseline => 'Baseline',
        FactSetOverlayPreset.colors => 'Colors',
        FactSetOverlayPreset.cities => 'Cities',
        FactSetOverlayPreset.foods => 'Foods',
      },
    );
    _syncPresetKnob(preset);

    return buildOverlayCard(registry: widgetbookCardTypeRegistry);
  }
}
