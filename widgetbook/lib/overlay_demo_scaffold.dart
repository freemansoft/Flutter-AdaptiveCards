// Widgetbook-only: uses package-internal injectIds for text_block overlay demo.
// ignore_for_file: implementation_imports

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart'
    as adaptive_utils;

/// Shared state for widgetbook overlay demo pages.
///
/// Provides card loading, post-frame apply scheduling with retry until
/// [RawAdaptiveCardState.documentContainer] is ready, and common card shell.
mixin OverlayDemoPageState<T extends StatefulWidget> on State<T> {
  static const _maxApplyAttempts = 30;

  final GlobalKey<RawAdaptiveCardState> cardKey = GlobalKey();

  Map<String, dynamic>? cardMap;

  int _applyAttempts = 0;
  bool _applyScheduled = false;

  /// Loads overlay demo JSON from the widgetbook asset bundle.
  ///
  /// If [injectIds] is true, assigns stable element ids (text_block demo only).
  Future<void> loadOverlayCardAsset(
    String assetPath, {
    bool injectIds = false,
  }) async {
    final json = await rootBundle.loadString(assetPath);
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (injectIds) {
      adaptive_utils.injectIds(map);
    }
    if (!mounted) {
      return;
    }
    setState(() => cardMap = map);
  }

  /// Schedules [flushPendingOverlay] on the next frame (deduped per frame).
  void scheduleOverlayApply(void Function() flushPendingOverlay) {
    if (_applyScheduled) {
      return;
    }
    _applyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyScheduled = false;
      flushPendingOverlay();
    });
  }

  /// Invokes [apply] when [cardKey]'s document is ready.
  ///
  /// On failure (card not mounted yet), retries up to [_maxApplyAttempts] via
  /// [reschedule]. Returns whether [apply] ran.
  bool runWhenCardReady(
    void Function(RawAdaptiveCardState cardState) apply, {
    required void Function() reschedule,
  }) {
    if (!mounted || cardMap == null) {
      return false;
    }

    final cardState = cardKey.currentState;
    if (cardState == null || cardState.documentContainer == null) {
      if (_applyAttempts < _maxApplyAttempts) {
        _applyAttempts++;
        reschedule();
      }
      return false;
    }

    _applyAttempts = 0;
    apply(cardState);
    return true;
  }

  /// Builds a loading indicator or the overlay demo card shell.
  Widget buildOverlayCard({
    required CardTypeRegistry registry,
    bool showDebugJson = true,
    bool wrapScrollView = true,
  }) {
    final map = cardMap;
    if (map == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final card = RawAdaptiveCard.fromMap(
      key: cardKey,
      map: map,
      cardTypeRegistry: registry,
      hostConfigs: HostConfigs(),
      showDebugJson: showDebugJson,
    );

    if (!wrapScrollView) {
      return card;
    }

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: card,
      ),
    );
  }
}
