// Host-only demo: calls [RawAdaptiveCardState.applyUpdates] / [setInputError].

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/overlay_demo_scaffold.dart';
import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

const _ratingId = 'demoRating';

final ratingInputOverlayPageKey = GlobalKey<State<RatingInputOverlayPage>>();

class RatingInputOverlayPage extends StatefulWidget {
  const RatingInputOverlayPage({super.key});

  @override
  State<RatingInputOverlayPage> createState() => _RatingInputOverlayPageState();
}

class _RatingInputOverlayPageState extends State<RatingInputOverlayPage>
    with OverlayDemoPageState<RatingInputOverlayPage> {
  static const _assetPath = 'lib/samples/inputs/rating_input_overlay_demo.json';

  double? _lastAppliedValue;
  String? _lastAppliedLabel;
  bool? _lastAppliedIsRequired;
  bool? _lastAppliedShowError;
  double? _pendingValue;
  String? _pendingLabel;
  bool? _pendingIsRequired;
  bool? _pendingShowError;
  bool _knobsInitialized = false;
  double? _lastSeenValueKnob;
  String? _lastSeenLabelKnob;
  bool? _lastSeenIsRequiredKnob;
  bool? _lastSeenShowErrorKnob;

  @override
  void initState() {
    super.initState();
    unawaited(loadOverlayCardAsset(_assetPath));
  }

  void _queueOverlay({
    required double value,
    required String label,
    required bool isRequired,
    required bool showError,
  }) {
    _pendingValue = value;
    _pendingLabel = label;
    _pendingIsRequired = isRequired;
    _pendingShowError = showError;
    if (_lastAppliedValue == value &&
        _lastAppliedLabel == label &&
        _lastAppliedIsRequired == isRequired &&
        _lastAppliedShowError == showError) {
      return;
    }
    scheduleOverlayApply(_flushPendingOverlay);
  }

  void _flushPendingOverlay() {
    final value = _pendingValue;
    final label = _pendingLabel;
    final isRequired = _pendingIsRequired;
    final showError = _pendingShowError;
    if (value == null ||
        label == null ||
        isRequired == null ||
        showError == null) {
      return;
    }

    runWhenCardReady(
      (cardState) {
        if (_lastAppliedValue == value &&
            _lastAppliedLabel == label &&
            _lastAppliedIsRequired == isRequired &&
            _lastAppliedShowError == showError) {
          return;
        }

        cardState.applyUpdates(
          elements: [
            AdaptiveElementUpdate(
              id: _ratingId,
              value: value,
              label: label,
              isRequired: isRequired,
            ),
          ],
        );

        if (showError) {
          cardState.setInputError(
            _ratingId,
            message: 'Please select a rating',
            isInvalid: true,
          );
        } else {
          cardState.clearInputError(_ratingId);
        }

        _lastAppliedValue = value;
        _lastAppliedLabel = label;
        _lastAppliedIsRequired = isRequired;
        _lastAppliedShowError = showError;
      },
      reschedule: () => scheduleOverlayApply(_flushPendingOverlay),
    );
  }

  void _syncKnobs({
    required double value,
    required String label,
    required bool isRequired,
    required bool showError,
  }) {
    if (!_knobsInitialized) {
      _knobsInitialized = true;
      _lastSeenValueKnob = value;
      _lastSeenLabelKnob = label;
      _lastSeenIsRequiredKnob = isRequired;
      _lastSeenShowErrorKnob = showError;
      return;
    }

    if (value == _lastSeenValueKnob &&
        label == _lastSeenLabelKnob &&
        isRequired == _lastSeenIsRequiredKnob &&
        showError == _lastSeenShowErrorKnob) {
      return;
    }

    _lastSeenValueKnob = value;
    _lastSeenLabelKnob = label;
    _lastSeenIsRequiredKnob = isRequired;
    _lastSeenShowErrorKnob = showError;

    _queueOverlay(
      value: value,
      label: label,
      isRequired: isRequired,
      showError: showError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = context.knobs.double.slider(
      label: 'Rating value',
      initialValue: 0,
      min: 0,
      max: 5,
      divisions: 10,
    );
    final label = context.knobs.string(
      label: 'Input label',
      initialValue: 'How was your experience?',
    );
    final isRequired = context.knobs.boolean(
      label: 'Required',
      initialValue: false,
    );
    final showError = context.knobs.boolean(
      label: 'Show validation error',
      initialValue: false,
    );

    _syncKnobs(
      value: value,
      label: label,
      isRequired: isRequired,
      showError: showError,
    );

    return buildOverlayCard(registry: widgetbookCardTypeRegistry);
  }
}
