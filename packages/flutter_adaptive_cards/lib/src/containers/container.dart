import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

///
/// https://adaptivecards.io/explorer/Container.html
///
class AdaptiveContainer extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveContainer({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
  }) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  late final String id;

  @override
  AdaptiveContainerState createState() => AdaptiveContainerState();
}

class AdaptiveContainerState extends State<AdaptiveContainer>
    with AdaptiveElementMixin {
  // TODO(username): implement verticalContentAlignment
  late List<Widget> children;
  late double spacing;
  late Color? backgroundColor;

  @override
  void initState() {
    super.initState();

    if (adaptiveMap['items'] != null) {
      children = List<Map<String, dynamic>>.from(adaptiveMap['items']).map((
        child,
      ) {
        return widgetState.cardTypeRegistry.getElement(
          map: child,
          widgetState: widgetState,
        );
      }).toList();
    } else {
      children = [];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    return ChildStyler(
      adaptiveMap: adaptiveMap,
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        widgetState: widgetState,
        child: SeparatorElement(
          adaptiveMap: adaptiveMap,
          widgetState: widgetState,
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
    );
  }
}
