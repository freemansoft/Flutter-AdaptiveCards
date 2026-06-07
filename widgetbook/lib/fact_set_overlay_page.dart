// Host-only demo: calls package-internal [RawAdaptiveCardState.setFacts].
// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:widgetbook/widgetbook.dart';

enum FactSetOverlayPreset { colors, cities, foods }

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

List<Fact> factsForPreset(FactSetOverlayPreset preset) {
  return switch (preset) {
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

class _FactSetOverlayPageState extends State<FactSetOverlayPage> {
  static const _assetPath = 'lib/samples/fact_set/facts_overlay_demo.json';
  static const _maxApplyAttempts = 30;

  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();
  late final CardTypeRegistry _cardTypeRegistry = CardTypeRegistry(
    addedElements: CardChartsRegistry.additionalChartElements,
  );

  Map<String, dynamic>? _cardMap;
  FactSetOverlayPreset? _lastAppliedPreset;
  FactSetOverlayPreset? _pendingPreset;
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

  void _queueFactsOverlay(FactSetOverlayPreset? preset) {
    _pendingPreset = preset;
    if (_lastAppliedPreset == preset) return;
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
    final preset = _pendingPreset;
    if (!mounted || _cardMap == null) return;

    final cardState = _cardKey.currentState;
    if (cardState == null || cardState.documentContainer == null) {
      if (_applyAttempts < _maxApplyAttempts) {
        _applyAttempts++;
        _scheduleApplyOverlay();
      }
      return;
    }

    _applyAttempts = 0;
    if (_lastAppliedPreset == preset) return;

    if (preset == null) {
      cardState.clearFacts(_factSetId);
    } else {
      cardState.setFacts(_factSetId, factsForPreset(preset));
    }
    _lastAppliedPreset = preset;
  }

  @override
  Widget build(BuildContext context) {
    final preset = context.knobs.objectOrNull.dropdown<FactSetOverlayPreset>(
      label: 'Facts overlay preset',
      options: FactSetOverlayPreset.values,
      initialOption: null,
      labelBuilder: (value) => switch (value) {
        FactSetOverlayPreset.colors => 'Colors',
        FactSetOverlayPreset.cities => 'Cities',
        FactSetOverlayPreset.foods => 'Foods',
      },
    );
    _queueFactsOverlay(preset);

    final cardMap = _cardMap;
    if (cardMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
