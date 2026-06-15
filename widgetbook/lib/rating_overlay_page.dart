// Host-only demo: calls [RawAdaptiveCardState.applyUpdates] on display Rating.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:widgetbook/widgetbook.dart';

const _ratingId = 'stars';

final ratingOverlayPageKey = GlobalKey<State<RatingOverlayPage>>();

class RatingOverlayPage extends StatefulWidget {
  const RatingOverlayPage({super.key});

  @override
  State<RatingOverlayPage> createState() => _RatingOverlayPageState();
}

class _RatingOverlayPageState extends State<RatingOverlayPage> {
  static const _assetPath = 'lib/samples/elements/rating_overlay_demo.json';
  static const _maxApplyAttempts = 30;

  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();
  late final CardTypeRegistry _cardTypeRegistry = CardTypeRegistry(
    addedElements: CardChartsRegistry.additionalChartElements,
  );

  Map<String, dynamic>? _cardMap;
  double? _lastAppliedValue;
  double? _pendingValue;
  bool _knobsInitialized = false;
  double? _lastSeenValueKnob;
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

  void _queueOverlay({required double value}) {
    _pendingValue = value;
    if (_lastAppliedValue == value) return;
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
    final value = _pendingValue;
    if (!mounted || _cardMap == null || value == null) {
      return;
    }

    final cardState = _cardKey.currentState;
    if (cardState == null || cardState.documentContainer == null) {
      if (_applyAttempts < _maxApplyAttempts) {
        _applyAttempts++;
        _scheduleApplyOverlay();
      }
      return;
    }

    _applyAttempts = 0;
    if (_lastAppliedValue == value) return;

    cardState.applyUpdates(
      elements: [
        AdaptiveElementUpdate(
          id: _ratingId,
          value: value,
        ),
      ],
    );

    _lastAppliedValue = value;
  }

  void _syncValueKnob(double value) {
    if (!_knobsInitialized) {
      _knobsInitialized = true;
      _lastSeenValueKnob = value;
      return;
    }

    if (value == _lastSeenValueKnob) return;
    _lastSeenValueKnob = value;
    _queueOverlay(value: value);
  }

  @override
  Widget build(BuildContext context) {
    final value = context.knobs.double.slider(
      label: 'Rating value',
      initialValue: 2,
      min: 0,
      max: 5,
      divisions: 10,
    );

    _syncValueKnob(value);

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
