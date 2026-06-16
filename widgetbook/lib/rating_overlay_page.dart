// Host-only demo: calls [RawAdaptiveCardState.applyUpdates] on display Rating.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/overlay_demo_scaffold.dart';
import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

const _ratingId = 'stars';

final ratingOverlayPageKey = GlobalKey<State<RatingOverlayPage>>();

class RatingOverlayPage extends StatefulWidget {
  const RatingOverlayPage({super.key});

  @override
  State<RatingOverlayPage> createState() => _RatingOverlayPageState();
}

class _RatingOverlayPageState extends State<RatingOverlayPage>
    with OverlayDemoPageState<RatingOverlayPage> {
  static const _assetPath = 'lib/samples/elements/rating_overlay_demo.json';

  double? _lastAppliedValue;
  double? _pendingValue;
  bool _knobsInitialized = false;
  double? _lastSeenValueKnob;

  @override
  void initState() {
    super.initState();
    unawaited(loadOverlayCardAsset(_assetPath));
  }

  void _queueOverlay({required double value}) {
    _pendingValue = value;
    if (_lastAppliedValue == value) return;
    scheduleOverlayApply(_flushPendingOverlay);
  }

  void _flushPendingOverlay() {
    final value = _pendingValue;
    if (value == null) {
      return;
    }

    runWhenCardReady(
      (cardState) {
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
      },
      reschedule: () => scheduleOverlayApply(_flushPendingOverlay),
    );
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

    return buildOverlayCard(registry: widgetbookCardTypeRegistry);
  }
}
