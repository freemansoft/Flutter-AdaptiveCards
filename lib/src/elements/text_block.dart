///
/// https://adaptivecards.io/explorer/TextBlock.html
///
import 'dart:developer' as developer;
import 'package:format/format.dart';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../flutter_adaptive_cards.dart';
import '../additional.dart';
import '../base.dart';
import '../utils.dart';

class AdaptiveTextBlock extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTextBlock(
      {super.key, required this.adaptiveMap, required this.supportMarkdown});

  final Map<String, dynamic> adaptiveMap;
  final bool supportMarkdown;

  @override
  _AdaptiveTextBlockState createState() => _AdaptiveTextBlockState();
}

class _AdaptiveTextBlockState extends State<AdaptiveTextBlock>
    with AdaptiveElementMixin {
  late FontWeight fontWeight = FontWeight.normal;
  late double fontSize = 12;
  late Alignment horizontalAlignment;
  late int maxLines;
  late TextAlign textAlign;
  late String text;

  @override
  void initState() {
    super.initState();
    text = parseTextString(adaptiveMap['text']);
  }

  /*child: */

  // TODO create own widget that parses _basic_ markdown. This might help: https://docs.flutter.io/flutter/widgets/Wrap-class.html
  @override
  Widget build(BuildContext context) {
    // should be lazily calculated because styling could have changed
    horizontalAlignment = loadAlignment();
    fontSize = loadSize();
    fontWeight = loadWeight();
    textAlign = loadTextAlign();
    maxLines = loadMaxLines();

    var textBody =
        widget.supportMarkdown ? getMarkdownText(context: context) : getText();

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Align(
        // TODO IntrinsicWidth finxed a few things, but breaks more
        alignment: horizontalAlignment,
        child: textBody,
      ),
    );
  }

  Widget getText() {
    return Text(
      text,
      textAlign: textAlign,
      softWrap: true,
      overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
      maxLines: maxLines,
    );
  }

  Widget getMarkdownText({BuildContext? context}) {
    return MarkdownBody(
      // TODO the markdown library does currently not support max lines
      // As markdown support is more important than maxLines right now
      // this is in here.
      //maxLines: maxLines,
      data: text,
      styleSheet: loadMarkdownStyleSheet(),
      onTapLink: (text, href, title) {
        if (href != null) {
          var rawAdaptiveCardState = context?.watch<RawAdaptiveCardState>();
          rawAdaptiveCardState?.openUrl(href);
        }
      },
    );
  }

  /*String textCappedWithMaxLines() {
    if(text.split("\n").length <= maxLines) return text;
    return text.split("\n").take(maxLines).reduce((o,t) => "$o\n$t") + "...";
  }*/

  // Probably want to pass context down the tree, until now -> this
  Color? getColor(Brightness brightness) {
    Color? color = resolver.resolveForegroundColor(
        context: context,
        colorType: adaptiveMap["color"],
        isSubtle: adaptiveMap["isSubtle"]);
    return color;
  }

  FontWeight loadWeight() {
    String weightString =
        widget.adaptiveMap["weight"]?.toLowerCase() ?? "default";
    switch (weightString) {
      case "default":
        return FontWeight.normal;
      case "lighter":
        return FontWeight.w300;
      case "bolder":
        return FontWeight.bold;
      default:
        return FontWeight.normal;
    }
  }

  double loadSize() {
    String sizeString = widget.adaptiveMap["size"]?.toLowerCase() ?? "default";
    TextTheme textTheme = Theme.of(context).textTheme;
    TextStyle? textStyle;
    switch (sizeString) {
      case "default":
        textStyle = textTheme.bodyMedium;
      case "small":
        textStyle = textTheme.bodySmall;
      case "medium":
        textStyle = textTheme.bodyMedium;
      case "large":
        textStyle = textTheme.bodyLarge;
      case "extraLarge":
        textStyle = textTheme.titleLarge;
      default: // in case some invalid value
        // should log here for debugging
        textStyle = textTheme.bodyMedium;
    }
    // Style might not exist but that seems unlikely
    double? foo = textStyle?.fontSize;
    if (foo == null) {
      developer.log(format("Unable to find TextStyle for {}", sizeString));
    }
    return foo ??= 12.0;
  }

  Alignment loadAlignment() {
    String alignmentString =
        widget.adaptiveMap["horizontalAlignment"]?.toLowerCase() ?? "left";

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

  TextAlign loadTextAlign() {
    String alignmentString =
        widget.adaptiveMap["horizontalAlignment"]?.toLowerCase() ?? "left";

    switch (alignmentString) {
      case "left":
        return TextAlign.start;
      case "center":
        return TextAlign.center;
      case "right":
        return TextAlign.right;
      default:
        return TextAlign.start;
    }
  }

  /// This also takes care of the wrap property, because maxLines = 1 => no wrap
  int loadMaxLines() {
    bool wrap = widget.adaptiveMap["wrap"] ?? false;
    if (!wrap) return 1;
    // can be null, but that's okay for the text widget.
    // int cannot be null
    return widget.adaptiveMap["maxLines"] ?? 1;
  }

  /// TODO Markdown still has some problems
  MarkdownStyleSheet loadMarkdownStyleSheet() {
    var color = getColor(Theme.of(context).brightness);
    TextStyle style =
        TextStyle(fontWeight: fontWeight, fontSize: fontSize, color: color);

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
