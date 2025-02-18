import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

import '../adaptive_mixins.dart';
import '../additional.dart';

///
/// https://adaptivecards.io/explorer/Container.html
///
class AdaptiveContainer extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveContainer({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveContainerState createState() => AdaptiveContainerState();
}

class AdaptiveContainerState extends State<AdaptiveContainer>
    with AdaptiveElementMixin {
  // TODO implement verticalContentAlignment
  late List<Widget> children;
  late double spacing;

  @override
  void initState() {
    super.initState();

    if (adaptiveMap['items'] != null) {
      children =
          List<Map<String, dynamic>>.from(adaptiveMap['items']).map((child) {
            return widgetState.cardRegistry.getElement(child);
          }).toList();
    } else {
      children = [];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    spacing =
        InheritedReferenceResolver.of(
          context,
        ).resolver.resolveSpacing(adaptiveMap['spacing']) ??
        0.0;
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
      context: context,
      style: adaptiveMap['style']?.toString(),
      backgroundImageUrl: adaptiveMap['backgroundImage']?['url']?.toString(),
    );

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
              padding: EdgeInsets.symmetric(
                vertical: spacing,
                horizontal: spacing,
              ),
              child: Column(children: children.toList()),
            ),
          ),
        ),
      ),
    );
  }
}
