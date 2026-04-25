import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Container.html
///
class AdaptiveContainer extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveContainer({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveContainerState createState() => AdaptiveContainerState();
}

class AdaptiveContainerState extends State<AdaptiveContainer>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late MainAxisAlignment verticalContentAlignment;
  late List<Widget> children;
  late double spacing;
  late Color? backgroundColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (adaptiveMap['items'] != null) {
      children = List<Map<String, dynamic>>.from(adaptiveMap['items']).map((
        child,
      ) {
        return cardTypeRegistry.getElement(
          map: child,
        );
      }).toList();
    } else {
      children = [];
    }
    spacing = SpacingsConfig.resolveSpacing(
      styleResolver.getSpacingsConfig(),
      adaptiveMap['spacing'],
    );

    // no background if we have an iamge - hmm but should we anyway?

    verticalContentAlignment = styleResolver.resolveVerticalMainAxisContentAlginment(
          adaptiveMap['verticalContentAlignment']?.toString(),
        );

    backgroundColor = backgroundImageSpecified(adaptiveMap)
        ? null
        : styleResolver.resolveContainerBackgroundColor(
                style: style,
              );
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: ChildStyler(
        adaptiveMap: adaptiveMap,
        child: AdaptiveTappable(
          adaptiveMap: adaptiveMap,
          child: SeparatorElement(
            adaptiveMap: adaptiveMap,
            child: Container(
              decoration: getDecorationFromMap(
                adaptiveMap,
                backgroundColor: backgroundColor,
              ),
              child: Padding(
                // padding: const EdgeInsets.symmetric(vertical: 8.0),
                padding: EdgeInsets.symmetric(
                  vertical: spacing,
                  horizontal: spacing,
                ),
                child: Column(
                  mainAxisAlignment: verticalContentAlignment,
                  children: children.toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
