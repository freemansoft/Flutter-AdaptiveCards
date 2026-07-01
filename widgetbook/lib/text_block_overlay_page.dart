// Host-only demo: calls package-internal [RawAdaptiveCardState.setText].

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/overlay_demo_scaffold.dart';
import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

/// Keeps [TextBlockOverlayPage] mounted when knob query params change.
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

class _TextBlockOverlayPageState extends State<TextBlockOverlayPage>
    with OverlayDemoPageState<TextBlockOverlayPage> {
  static const _assetPath = 'lib/samples/text_block/text_overlay_demo.json';
  static const _bodyTextId = 'bodyText';

  String? _lastAppliedBodyText;
  String? _pendingBodyText;

  @override
  void initState() {
    super.initState();
    unawaited(loadOverlayCardAsset(_assetPath, injectIds: true));
  }

  void _queueBodyOverlay(String bodyText) {
    _pendingBodyText = bodyText;
    if (_lastAppliedBodyText == bodyText) {
      return;
    }
    scheduleOverlayApply(_flushPendingOverlay);
  }

  void _flushPendingOverlay() {
    final bodyText = _pendingBodyText;
    if (bodyText == null) {
      return;
    }

    runWhenCardReady(
      (cardState) {
        if (_lastAppliedBodyText != bodyText) {
          cardState.setText(_bodyTextId, bodyText);
          _lastAppliedBodyText = bodyText;
        }
      },
      reschedule: () => scheduleOverlayApply(_flushPendingOverlay),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyText = context.knobs.string(
      label: 'Body TextBlock text',
      initialValue: 'Initial body from card JSON.',
    );
    _queueBodyOverlay(bodyText);

    return buildOverlayCard(registry: widgetbookCardTypeRegistry);
  }
}
