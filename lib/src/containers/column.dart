import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

import '../adaptive_mixins.dart';
import '../additional.dart';
import '../generic_action.dart';

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
  late Widget backgroundImage;
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

    backgroundImage = _getBackgroundImage(adaptiveMap);

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

    items =
        adaptiveMap['items'] != null
            ? List<Map<String, dynamic>>.from(adaptiveMap['items']).map((
              child,
            ) {
              return widgetState.cardRegistry.getElement(
                child,
                parentMode: mode,
              );
            }).toList()
            : [];

    verticalAlignment = loadVerticalAlignment();
    horizontalAlignment = loadHorizontalAlignment();
    containerHorizontalAlignment = loadHorizontalContainerAlignment();
  }

  MainAxisAlignment loadVerticalAlignment() {
    String verticalAlignment =
        adaptiveMap['verticalContentAlignment']?.toLowerCase() ?? 'top';

    switch (verticalAlignment) {
      case 'top':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'bottom':
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment loadHorizontalAlignment() {
    String horizontalAlignment =
        adaptiveMap['horizontalAlignment']?.toLowerCase() ?? 'left';

    switch (horizontalAlignment) {
      case 'left':
        return CrossAxisAlignment.start;
      case 'center':
        return CrossAxisAlignment.center;
      case 'right':
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  Alignment? loadHorizontalContainerAlignment() {
    String horizontalAlignment =
        adaptiveMap['horizontalAlignment']?.toLowerCase() ?? '';

    switch (horizontalAlignment) {
      case 'left':
        return Alignment.topLeft;
      case 'center':
        return Alignment.topCenter;
      case 'right':
        return Alignment.topRight;
      default:
        return null;
    }
  }

  Widget _getBackgroundImage(Map element) {
    var backgroundImage = adaptiveMap['backgroundImage'];
    if (backgroundImage != null) {
      var backgroundImageUrl = backgroundImage['url'];
      var fillMode = backgroundImage['fillMode'];

      BoxFit fit;
      switch (fillMode) {
        case 'RepeatVertically':
        case 'RepeatHorizontally':
        case 'Repeat':
          fit = BoxFit.none;
          break;
        default:
          fit = BoxFit.cover;
      }

      ImageRepeat repeat;
      switch (fillMode) {
        case 'RepeatVertically':
          repeat = ImageRepeat.repeatY;
          break;
        case 'RepeatHorizontally':
          repeat = ImageRepeat.repeatX;
          break;
        case 'Repeat':
          repeat = ImageRepeat.repeat;
          break;
        default:
          repeat = ImageRepeat.noRepeat;
      }

      if (backgroundImageUrl != null) {
        return Image(
          repeat: repeat,
          image: NetworkImage(backgroundImageUrl),
          fit: fit,
        );
      }
    }
    return const SizedBox(width: 0, height: 0);
  }

  @override
  Widget build(BuildContext context) {
    double? precedingSpacing = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveSpacing(adaptiveMap['spacing']);
    var backgroundColor = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
      context: context,
      style: adaptiveMap['style']?.toString(),
      backgroundImageUrl: adaptiveMap['backgroundImage']?['url'],
    );

    Widget child = Container(
      alignment: containerHorizontalAlignment,
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: horizontalAlignment,
        mainAxisAlignment: verticalAlignment,
        children: [...items.map((it) => it)],
      ),
    );

    if (!widget.supportMarkdown) {
      child = Expanded(child: child);
    }

    Widget result = Stack(
      children: [
        backgroundImage,
        InkWell(
          onTap: action?.tap,
          child: Padding(
            padding: EdgeInsets.only(left: precedingSpacing ?? 0),
            child: SeparatorElement(adaptiveMap: adaptiveMap, child: child),
          ),
        ),
      ],
    );

    assert(
      mode == 'auto' || mode == 'stretch' || mode == 'weighted' || mode == 'px',
    );
    if (mode == 'auto') {
      return Flexible(child: result);
    } else if (mode == 'stretch') {
      return Expanded(child: result);
    } else if (mode == 'weighted') {
      return Expanded(flex: width, child: result);
    } else if (mode == 'px') {
      return SizedBox(width: width.toDouble(), child: result);
    }

    return ChildStyler(adaptiveMap: adaptiveMap, child: result);
  }
}
