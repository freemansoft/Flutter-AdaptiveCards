import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.Popover.html
///
/// Renders `Action.Popover` as an elevated button that opens the nested `card`
/// payload in a dialog.
class AdaptiveActionPopover extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates an `Action.Popover` widget from [adaptiveMap].
  AdaptiveActionPopover({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }
  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionPopoverState createState() => AdaptiveActionPopoverState();
}

/// State for [AdaptiveActionPopover].
class AdaptiveActionPopoverState extends State<AdaptiveActionPopover>
    with AdaptiveElementMixin, ProviderScopeMixin {
  /// Nested adaptive card JSON from the action's `card` property.
  late Map<String, dynamic>? card;

  /// Parent [ReferenceResolver] so the popover inherits HostConfig styling.
  late ReferenceResolver popupParentResolver;

  @override
  void initState() {
    super.initState();
    // 'card' property contains the Adaptive Card to show
    card = adaptiveMap['card'] as Map<String, dynamic>? ?? {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    popupParentResolver = styleResolver;
  }

  /// Opens a dialog containing the nested `card` payload.
  Future<void> onTapped(BuildContext context) async {
    if (card == null) return;

    // Show popover (Dialog or PopupMenu or Overlay)
    // Using a Dialog for simplicity as "Popover" usually implies a temporary view.
    // Ideally we assume an anchor, but simpler implementation:
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: SingleChildScrollView(
              child: AdaptivePopoverContainer(
                child: RawAdaptiveCard.fromMap(
                  map: card!,
                  hostConfigs: popupParentResolver.getHostConfigs(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: (BuildContext context) {
        unawaited(onTapped(context));
      },
    );
  }
}

/// Marker wrapper around popover card content for widget tests and tree lookup.
class AdaptivePopoverContainer extends StatelessWidget {
  /// Creates a popover content container with [child].
  const AdaptivePopoverContainer({super.key, required this.child});

  /// Popover card subtree rendered inside the dialog.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
