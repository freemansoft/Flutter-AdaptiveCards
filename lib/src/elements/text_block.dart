import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../flutter_adaptive_cards.dart';
import '../additional.dart';
import '../base.dart';
import '../utils.dart';

class AdaptiveTextBlock extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTextBlock({Key key, this.adaptiveMap}) : super(key: key);

  final Map adaptiveMap;

  @override
  _AdaptiveTextBlockState createState() => _AdaptiveTextBlockState();
}

class _AdaptiveTextBlockState extends State<AdaptiveTextBlock> with AdaptiveElementMixin {
  FontWeight fontWeight;
  double fontSize;
  Alignment horizontalAlignment;
  int maxLines;
  String text;

  @override
  void initState() {
    super.initState();
    fontSize = resolver.resolveFontSize(adaptiveMap["size"]);
    fontWeight = resolver.resolveFontWeight(adaptiveMap["weight"]);
    horizontalAlignment = loadAlignment();
    maxLines = loadMaxLines();

    text = parseTextString(adaptiveMap['text']);
  }

  /*child: Text(
            text,
            style: TextStyle(
              fontWeight: fontWeight,
              fontSize: fontSize,
              color: getColor(Theme.of(context).brightness),
            ),
            maxLines: maxLines,
          )*/

  // TODO create own widget that parses _basic_ markdown. This might help: https://docs.flutter.io/flutter/widgets/Wrap-class.html
  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Align(
        // TODO IntrinsicWidth finxed a few things, but breaks more
        alignment: horizontalAlignment,
        child: MarkdownBody(
          // TODO the markdown library does currently not support max lines
          // As markdown support is more important than maxLines right now
          // this is in here.
          //maxLines: maxLines,
          data: text,
          styleSheet: loadMarkdownStyleSheet(),
          onTapLink: (href) {
            RawAdaptiveCardState.of(context).openUrl(href);
          },
        ),
      ),
    );
  }

  /*String textCappedWithMaxLines() {
    if(text.split("\n").length <= maxLines) return text;
    return text.split("\n").take(maxLines).reduce((o,t) => "$o\n$t") + "...";
  }*/

  // Probably want to pass context down the tree, until now -> this
  Color getColor(Brightness brightness) {
    Color color = resolver.resolveColor(adaptiveMap["color"], adaptiveMap["isSubtle"]);
    if (color != null && widgetState.widget.approximateDarkThemeColors) {
      color = adjustColorToFitDarkTheme(color, brightness);
    }
    return color;
  }

  Alignment loadAlignment() {
    String alignmentString = widget.adaptiveMap["horizontalAlignment"] ?? "left";
    switch (alignmentString) {
      case "left":
        return Alignment.centerLeft;
      case "center":
        return Alignment.center;
      case "right":
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  /// This also takes care of the wrap property, because maxLines = 1 => no wrap
  int loadMaxLines() {
    bool wrap = widget.adaptiveMap["wrap"] ?? false;
    if (!wrap) return 1;
    // can be null, but that's okay for the text widget.
    return widget.adaptiveMap["maxLines"];
  }

  /// TODO Markdown still has some problems
  MarkdownStyleSheet loadMarkdownStyleSheet() {
    Color color = getColor(Theme.of(context).brightness);

    if  (color == null) {
      var isEmphasis = (adaptiveMap["color"] ?? "default") == "emphasis";

      if (isEmphasis) {
        color = Theme.of(context).textTheme.bodyText2.color;
      } else {
        color = Theme.of(context).textTheme.bodyText1.color;
      }
    }

    TextStyle style = TextStyle(fontWeight: fontWeight, fontSize: fontSize, color: color);
    return MarkdownStyleSheet(
      a: style,
      blockquote: style,
      code: style,
      em: style,
      strong: style.copyWith(fontWeight: FontWeight.bold),
      p: style,
    );
  }
}
