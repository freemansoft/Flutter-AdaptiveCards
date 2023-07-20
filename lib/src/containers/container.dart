///
/// https://adaptivecards.io/explorer/Container.html
///
import 'package:flutter/material.dart';

import '../additional.dart';
import '../base.dart';

class AdaptiveContainer extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveContainer({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveContainerState createState() => _AdaptiveContainerState();
}

class _AdaptiveContainerState extends State<AdaptiveContainer>
    with AdaptiveElementMixin {
// TODO implement verticalContentAlignment
  late List<Widget> children;
  late double spacing;

  @override
  void initState() {
    super.initState();

    spacing = resolver.resolveSpacing(adaptiveMap["spacing"]) ?? 0.0;

    if (adaptiveMap["items"] != null) {
      children =
          List<Map<String, dynamic>>.from(adaptiveMap["items"]).map((child) {
        return widgetState.cardRegistry.getElement(child);
      }).toList();
    } else {
      children = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor =
        resolver.resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
            context: context,
            style: adaptiveMap['style']?.toString(),
            backgroundImageUrl:
                adaptiveMap['backgroundImage']?['url']?.toString());

    return ChildStyler(
      adaptiveMap: adaptiveMap,
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        child: SeparatorElement(
          adaptiveMap: adaptiveMap,
          child: Container(
            color: backgroundColor,
            child: Padding(
              // padding: const EdgeInsets.symmetric(vertical: 8.0),
              padding:
                  EdgeInsets.symmetric(vertical: spacing, horizontal: spacing),
              child: Column(
                children: children.toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
