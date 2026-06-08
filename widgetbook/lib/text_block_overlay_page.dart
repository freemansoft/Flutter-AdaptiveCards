// Host-only demo: calls package-internal [RawAdaptiveCardState.setText].
// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:widgetbook/widgetbook.dart';

/// Keeps [TextBlockOverlayPage] mounted when Widgetbook knob query params change.
///
/// Widgetbook's workbench keys the use-case builder with `ValueKey(uri)`, so
/// knob edits recreate that subtree; this key preserves card + document state.
final textBlockOverlayPageKey = GlobalKey<State<TextBlockOverlayPage>>();

/// Widgetbook page that applies knob-driven text to the `bodyText` element
/// via [RawAdaptiveCardState.setText].
class TextBlockOverlayPage extends StatefulWidget {
  const TextBlockOverlayPage({super.key});

  @override
  State<TextBlockOverlayPage> createState() => _TextBlockOverlayPageState();
}

class _TextBlockOverlayPageState extends State<TextBlockOverlayPage> {
  static const _assetPath = 'lib/samples/text_block/text_overlay_demo.json';
  static const _bodyTextId = 'bodyText';
  static const _maxApplyAttempts = 30;

  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();
  late final CardTypeRegistry _cardTypeRegistry = CardTypeRegistry(
    addedElements: CardChartsRegistry.additionalChartElements,
  );

  Map<String, dynamic>? _cardMap;
  String? _lastAppliedBodyText;
  String? _pendingBodyText;
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
    injectIds(map);
    if (!mounted) {
      return;
    }
    setState(() => _cardMap = map);
  }

  void _queueBodyOverlay(String bodyText) {
    _pendingBodyText = bodyText;
    if (_lastAppliedBodyText == bodyText) {
      return;
    }
    _scheduleApplyOverlay();
  }

  void _scheduleApplyOverlay() {
    if (_applyScheduled) {
      return;
    }
    _applyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyScheduled = false;
      _flushPendingOverlay();
    });
  }

  void _flushPendingOverlay() {
    final bodyText = _pendingBodyText;
    if (!mounted || _cardMap == null || bodyText == null) {
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
    if (_lastAppliedBodyText != bodyText) {
      cardState.setText(_bodyTextId, bodyText);
      _lastAppliedBodyText = bodyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyText = context.knobs.string(
      label: 'Body TextBlock text',
      initialValue: 'Initial body from card JSON.',
    );
    _queueBodyOverlay(bodyText);

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
