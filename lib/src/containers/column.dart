import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

///
/// https://adaptivecards.io/explorer/Column.html
///
class AdaptiveColumn extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveColumn({
    super.key,
    required this.adaptiveMap,
    required this.supportMarkdown,
  });

  @override
  final Map<String, dynamic> adaptiveMap;
  final bool supportMarkdown;

  @override
  AdaptiveColumnState createState() => AdaptiveColumnState();
}

class AdaptiveColumnState extends State<AdaptiveColumn>
    with AdaptiveElementMixin {
  late List<Widget> items;

  /// Can be "auto", "stretch" or "weighted"
  late String mode;
  late int width;

  late MainAxisAlignment verticalAlignment;
  late CrossAxisAlignment horizontalAlignment;
  late Alignment? containerHorizontalAlignment;

  GenericAction? action;

  // Need to do the separator manually for this class
  // because the flexible needs to be applied to the class above
  late bool separator;

  @override
  void initState() {
    super.initState();

    if (adaptiveMap.containsKey('selectAction')) {
      action = widgetState.cardRegistry.getGenericAction(
        adaptiveMap['selectAction'],
        widgetState,
      );
    }
    separator = adaptiveMap['separator'] ?? false;

    var toParseWidth = adaptiveMap['width'];
    if (toParseWidth != null) {
      if (toParseWidth == 'auto') {
        mode = 'auto';
      } else if (toParseWidth == 'stretch') {
        mode = 'stretch';
      } else if (toParseWidth is int) {
        width = toParseWidth;
        mode = 'weighted';
      } else {
        var widthString = toParseWidth.toString();

        if (widthString.endsWith('px')) {
          widthString = widthString.substring(
            0,
            widthString.length - 2,
          ); // remove px
          width = int.parse(widthString);
          mode = 'px';
        } else {
          // Handle gracefully
          mode = 'auto';
        }
      }
    } else {
      mode = 'auto';
    }

    items = adaptiveMap['items'] != null
        ? List<Map<String, dynamic>>.from(adaptiveMap['items']).map((
            child,
          ) {
            return widgetState.cardRegistry.getElement(
              child,
              parentMode: mode,
            );
          }).toList()
        : [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    horizontalAlignment = InheritedReferenceResolver.of(context).resolver
        .resolveHorzontalCrossAxisAlignment(
          adaptiveMap['horizontalAlignment'],
        );
    verticalAlignment = InheritedReferenceResolver.of(context).resolver
        .resolveVerticalMainAxisContentAlginment(
          adaptiveMap['verticalContentAlignment'],
        );

    containerHorizontalAlignment = InheritedReferenceResolver.of(context)
        .resolver
        .resolveContainerAlignment(
          adaptiveMap['horizontalAlignment'],
        );
  }

  @override
  Widget build(BuildContext context) {
    double? preceedingSpacing = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveSpacing(adaptiveMap['spacing']);
    var backgroundImageUrl = resolveBackgroundImage(
      adaptiveMap['backgroundImage'],
    )?.url;
    var backgroundColor =
        InheritedReferenceResolver.of(
          context,
        ).resolver.resolveContainerBackgroundColorIfNoBackgroundImage(
          context: context,
          style: adaptiveMap['style']?.toString(),
          backgroundImageUrl: backgroundImageUrl,
        );

    Widget child = SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: InkWell(
        onTap: action?.tap,
        child: Container(
          // we need this container to be the same size as the row element
          // so that all the columns are the same height
          alignment: containerHorizontalAlignment,
          padding: EdgeInsets.only(left: preceedingSpacing ?? 0),
          decoration: getDecorationFromMap(
            adaptiveMap,
            backgroundColor: backgroundColor,
          ),
          child: ChildStyler(
            adaptiveMap: adaptiveMap,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: horizontalAlignment,
              mainAxisAlignment: verticalAlignment,
              children: [...items.map((it) => it)],
            ),
          ),
        ),
      ),
    );

    // Why is this here if we could have another expanded below?
    if (!widget.supportMarkdown) {
      child = Expanded(child: child);
    }

    var result = child;
    assert(
      mode == 'auto' || mode == 'stretch' || mode == 'weighted' || mode == 'px',
    );
    if (mode == 'auto') {
      result = Flexible(child: child);
    } else if (mode == 'stretch') {
      result = Expanded(child: child);
    } else if (mode == 'weighted') {
      result = Expanded(flex: width, child: child);
    } else if (mode == 'px') {
      result = SizedBox(width: width.toDouble(), child: child);
    }

    return result;
  }
}
