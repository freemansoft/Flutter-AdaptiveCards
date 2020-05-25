import 'package:flutter/material.dart';

import '../additional.dart';
import '../base.dart';
import '../utils.dart';

class AdaptiveColumn extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveColumn({Key key, this.adaptiveMap}) : super(key: key);

  final Map adaptiveMap;

  @override
  _AdaptiveColumnState createState() => _AdaptiveColumnState();
}

class _AdaptiveColumnState extends State<AdaptiveColumn> with AdaptiveElementMixin {
  List<Widget> items;

  /// Can be "auto", "stretch" or "manual"
  String mode;
  int width;

  GenericAction action;

  // Need to do the separator manually for this class
  // because the flexible needs to be applied to the class above
  double precedingSpacing;
  Widget backgroundImage;
  bool separator;
  Color backgroundColor;

  @override
  void initState() {
    super.initState();

    if (adaptiveMap.containsKey("selectAction")) {
      action = widgetState.cardRegistry.getGenericAction(adaptiveMap["selectAction"], widgetState);
    }
    precedingSpacing = resolver.resolveSpacing(adaptiveMap["spacing"]);
    separator = adaptiveMap["separator"] ?? false;

    backgroundImage = _getBackgroundImage(adaptiveMap);

    items = adaptiveMap["items"] != null
        ? List<Map>.from(adaptiveMap["items"]).map((child) {
            return widgetState.cardRegistry.getElement(child);
          }).toList()
        : [];

    var toParseWidth = adaptiveMap["width"];
    if (toParseWidth != null) {
      if (toParseWidth == "auto") {
        mode = "auto";
      } else if (toParseWidth == "stretch") {
        mode = "stretch";
      } else if (toParseWidth is int) {
        if (toParseWidth != null) {
          width = toParseWidth;
          mode = "manual";
        } else {
          // Handle gracefully
          mode = "auto";
        }
      } else {
        // Handle gracefully
        mode = "auto";
      }
    } else {
      mode = "auto";
    }
  }

  Widget _getBackgroundImage(Map element) {
    var backgroundImage = adaptiveMap["backgroundImage"];
    if (backgroundImage != null) {
      var backgroundImageUrl = backgroundImage["url"];
      var fillMode = backgroundImage["fillMode"];

      BoxFit fit;
      switch (fillMode) {
        case "RepeatVertically":
        case "RepeatHorizontally":
        case "Repeat":
          fit = BoxFit.none;
          break;
        default:
          fit = BoxFit.cover;
      }

      ImageRepeat repeat;
      switch (fillMode) {
        case "RepeatVertically":
          repeat = ImageRepeat.repeatY;
          break;
        case "RepeatHorizontally":
          repeat = ImageRepeat.repeatX;
          break;
        case "Repeat":
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
    return SizedBox(
      width: 0,
      height: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (backgroundColor == null) {
      setState(() {
        backgroundColor = getBackgroundColor(
          resolver: resolver,
          adaptiveMap: adaptiveMap,
          approximateDarkThemeColors: widgetState.widget.approximateDarkThemeColors,
          brightness: Theme.of(context).brightness,
        );
      });
    }

    Widget result = Stack(
      children: [
        backgroundImage,
        InkWell(
          onTap: action?.tap,
          child: Padding(
            padding: EdgeInsets.only(left: precedingSpacing),
            child: SeparatorElement(
              adaptiveMap: adaptiveMap,
              child: Column(
                children: []..addAll(items.map((it) => it).toList()),
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
            ),
          ),
        ),
      ],
    );

    assert(mode == "auto" || mode == "stretch" || mode == "manual");
    if (mode == "auto") {
      result = Flexible(child: result);
    } else if (mode == "stretch") {
      result = Expanded(
        child: result,
      );
    } else if (mode == "manual") {
      result = Flexible(
        flex: width,
        child: result,
      );
    }

    return ChildStyler(adaptiveMap: adaptiveMap, child: result);
  }
}
