import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';

class AdaptiveActionInsertImage extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionInsertImage({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionInsertImageState createState() =>
      AdaptiveActionInsertImageState();
}

class AdaptiveActionInsertImageState extends State<AdaptiveActionInsertImage>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: (BuildContext context) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Action.InsertImage triggered (Not fully implemented)',
            ),
          ),
        );
      },
    );
  }
}
