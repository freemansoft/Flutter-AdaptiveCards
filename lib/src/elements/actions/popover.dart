import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';

class AdaptiveActionPopover extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionPopover({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveActionPopoverState createState() => AdaptiveActionPopoverState();
}

class AdaptiveActionPopoverState extends State<AdaptiveActionPopover>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late Map<String, dynamic>? card;

  @override
  void initState() {
    super.initState();
    // 'card' property contains the Adaptive Card to show
    card = widget.adaptiveMap['card'];
  }

  @override
  void onTapped() {
    if (card == null) return;

    // Show popover (Dialog or PopupMenu or Overlay)
    // Using a Dialog for simplicity as "Popover" usually implies a temporary view.
    // Ideally we assume an anchor, but simpler implementation:
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: SingleChildScrollView(
              child: widgetState.cardRegistry.getElement(card!),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: ElevatedButton(
        onPressed: onTapped,
        child: Text(title),
      ),
    );
  }
}
