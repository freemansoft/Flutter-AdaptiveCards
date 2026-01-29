import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

class AdaptiveActionPopover extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionPopover({
    required this.adaptiveMap,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionPopoverState createState() => AdaptiveActionPopoverState();
}

class AdaptiveActionPopoverState extends State<AdaptiveActionPopover>
    with AdaptiveActionMixin, AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late Map<String, dynamic>? card;
  // used to inherit the parent's host config
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
    popupParentResolver = InheritedReferenceResolver.of(context).resolver;
  }

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
                  hostConfig: popupParentResolver.getHostConfig(),
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
    final resolver = InheritedReferenceResolver.of(context).resolver;

    // TODO(username): implement the correct styling
    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: resolver.resolveButtonBackgroundColor(
              context: context,
              style: adaptiveMap['style'],
            ),
            foregroundColor: resolver.resolveButtonForegroundColor(
              context: context,
              style: adaptiveMap['style'],
            ),
            // minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () {
            unawaited(onTapped(context));
          },
          child: Text(title),
        ),
      ),
    );
  }
}

/// used for widget tree analysis and testing
class AdaptivePopoverContainer extends StatelessWidget {
  const AdaptivePopoverContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
