import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';

class AdaptiveActionInsertImage extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionInsertImage({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveActionInsertImageState createState() =>
      AdaptiveActionInsertImageState();
}

class AdaptiveActionInsertImageState extends State<AdaptiveActionInsertImage>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: widget.adaptiveMap,
      onTapped: onTapped,
    );
  }

  @override
  void onTapped() {
    // Placeholder logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action.InsertImage triggered (Not fully implemented)'),
      ),
    );
  }
}
