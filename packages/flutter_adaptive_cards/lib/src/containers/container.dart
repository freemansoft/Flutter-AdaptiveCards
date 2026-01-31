import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

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
  // TODO(username): implement verticalContentAlignment
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
      InheritedReferenceResolver.of(
        context,
      ).resolver.getSpacingsConfig(),
      adaptiveMap['spacing'],
    );
    final backgroundImageUrl = resolveBackgroundImage(
      adaptiveMap['backgroundImage'],
    )?.url;
    backgroundColor =
        InheritedReferenceResolver.of(
          context,
        ).resolver.resolveContainerBackgroundColorIfNoBackgroundImage(
          context: context,
          style: adaptiveMap['style']?.toString(),
          backgroundImageUrl: backgroundImageUrl,
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
                child: Column(children: children.toList()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
