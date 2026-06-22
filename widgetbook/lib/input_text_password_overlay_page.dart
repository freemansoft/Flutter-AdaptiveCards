// Host-only demo: calls [RawAdaptiveCardState.setRevealPasswordEnabled].

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/overlay_demo_scaffold.dart';
import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

const _passwordId = 'passwordField';

final inputTextPasswordOverlayPageKey =
    GlobalKey<State<InputTextPasswordOverlayPage>>();

class InputTextPasswordOverlayPage extends StatefulWidget {
  const InputTextPasswordOverlayPage({super.key});

  @override
  State<InputTextPasswordOverlayPage> createState() =>
      _InputTextPasswordOverlayPageState();
}

class _InputTextPasswordOverlayPageState
    extends State<InputTextPasswordOverlayPage>
    with OverlayDemoPageState<InputTextPasswordOverlayPage> {
  static const _assetPath =
      'lib/samples/inputs/input_text/password_overlay_demo.json';

  bool? _lastApplied;
  bool? _pending;
  bool _knobsInitialized = false;
  bool? _lastSeenKnob;

  @override
  void initState() {
    super.initState();
    unawaited(loadOverlayCardAsset(_assetPath));
  }

  void _queueOverlay(bool revealEnabled) {
    _pending = revealEnabled;
    if (_lastApplied == revealEnabled) return;
    scheduleOverlayApply(_flushPendingOverlay);
  }

  void _flushPendingOverlay() {
    final revealEnabled = _pending;
    if (revealEnabled == null) return;

    runWhenCardReady(
      (cardState) {
        if (_lastApplied == revealEnabled) return;
        cardState.setRevealPasswordEnabled(
          _passwordId,
          enabled: revealEnabled,
        );
        _lastApplied = revealEnabled;
      },
      reschedule: () => scheduleOverlayApply(_flushPendingOverlay),
    );
  }

  void _syncKnob(bool revealEnabled) {
    if (!_knobsInitialized) {
      _knobsInitialized = true;
      _lastSeenKnob = revealEnabled;
      return;
    }
    if (revealEnabled == _lastSeenKnob) return;
    _lastSeenKnob = revealEnabled;
    _queueOverlay(revealEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final revealEnabled = context.knobs.boolean(
      label: 'Enable password reveal toggle',
      initialValue: true,
    );
    _syncKnob(revealEnabled);
    return buildOverlayCard(registry: widgetbookCardTypeRegistry);
  }
}
