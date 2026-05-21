import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
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
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  late MainAxisAlignment verticalContentAlignment;
  late List<Widget> children;
  late double spacing;
  late Color? backgroundColor;
  double? minHeight;

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
    spacing = styleResolver.resolveSpacing(
      adaptiveMap['spacing'],
    );

    // no background if we have an iamge - hmm but should we anyway?

    verticalContentAlignment = styleResolver
        .resolveVerticalMainAxisContentAlginment(
          adaptiveMap['verticalContentAlignment']?.toString(),
        );

    backgroundColor = backgroundImageSpecified(adaptiveMap)
        ? null
        : styleResolver.resolveContainerBackgroundColor(
            style: style,
          );

    minHeight = parseMinHeight(adaptiveMap['minHeight']);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChildren = children.isNotEmpty;
    final bool hasBackgroundImage = backgroundImageSpecified(adaptiveMap);

    Widget containerChild;
    if (!hasChildren && hasBackgroundImage) {
      containerChild =
          getBackgroundImageFromMap(adaptiveMap) ?? const SizedBox();
    } else {
      containerChild = Padding(
        // padding: const EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.symmetric(
          vertical: spacing,
          horizontal: spacing,
        ),
        child: Column(
          mainAxisAlignment: verticalContentAlignment,
          children: children.toList(),
        ),
      );
    }

    final decoration = hasChildren
        ? getDecorationFromMap(
            adaptiveMap,
            backgroundColor: backgroundColor,
          )
        : BoxDecoration(color: backgroundColor);

    return Visibility(
      visible: isVisible,
      child: ChildStyler(
        adaptiveMap: adaptiveMap,
        child: AdaptiveTappable(
          adaptiveMap: adaptiveMap,
          child: SeparatorElement(
            adaptiveMap: adaptiveMap,
            child: Container(
              constraints: minHeight != null
                  ? BoxConstraints(minHeight: minHeight!)
                  : null,
              decoration: decoration,
              child: containerChild,
            ),
          ),
        ),
      ),
    );
  }
}
