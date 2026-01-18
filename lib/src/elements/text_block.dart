import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/TextBlock.html
///
class AdaptiveTextBlock extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTextBlock({
    super.key,
    required this.adaptiveMap,
    required this.supportMarkdown,
  });

  @override
  final Map<String, dynamic> adaptiveMap;
  final bool supportMarkdown;

  @override
  AdaptiveTextBlockState createState() => AdaptiveTextBlockState();
}

class AdaptiveTextBlockState extends State<AdaptiveTextBlock>
    with AdaptiveElementMixin {
  // will be replaced later
  late FontWeight fontWeight = FontWeight.normal;
  late double fontSize = 12;
  late Alignment horizontalAlignment;
  late int maxLines;
  late TextAlign textAlign;
  late String text;
  late String? fontFamily;

  @override
  void initState() {
    super.initState();
    text = parseTextString(adaptiveMap['text']);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // should be lazily calculated because styling could have changed
    final resolver = InheritedReferenceResolver.of(context).resolver;
    horizontalAlignment = resolver.resolveAlignment(
      widget.adaptiveMap['horizontalAlignment'],
    );
    fontSize = resolver.resolveFontSize(
      context: context,
      sizeString: widget.adaptiveMap['size'],
    );
    fontWeight = resolver.resolveFontWeight(widget.adaptiveMap['weight']);
    textAlign = resolver.resolveTextAlign(
      widget.adaptiveMap['horizontalAlignment'],
    );
    fontFamily = resolver.resolveFontType(
      context,
      widget.adaptiveMap['fontType'],
    );
    maxLines = resolver.resolveMaxLines(
      wrap: widget.adaptiveMap['wrap'],
      maxLines: widget.adaptiveMap['maxLines'],
    );
  }

  /*child: */

  // TODOcreate own widget that parses_basic markdown. This might help: https://docs.flutter.io/flutter/widgets/Wrap-class.html
  @override
  Widget build(BuildContext context) {
    final textBody = widget.supportMarkdown
        ? getMarkdownText(context: context)
        : getText();

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Align(
        // IntrinsicWidth fixed a few things, but breaks more
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
        fontFamily: fontFamily,
      ),
      maxLines: maxLines,
    );
  }

  Widget getMarkdownText({required BuildContext context}) {
    return MarkdownBody(
      // TODOthe markdown library does currently not support max lines
      // As markdown support is more important than maxLines right now
      // this is in here.
      //maxLines: maxLines,
      data: text,
      styleSheet: loadMarkdownStyleSheet(context),
      onTapLink: (text, href, title) {
        if (href != null) {
          ProviderScope.containerOf(
            context,
            listen: false,
          ).read(rawAdaptiveCardStateProvider).openUrl(href);
        }
      },
    );
  }

  /*String textCappedWithMaxLines() {
    if(text.split("\n").length <= maxLines) return text;
    return text.split("\n").take(maxLines).reduce((o,t) => "$o\n$t") + "...";
  }*/

  // Probably want to pass context down the tree, until now -> this
  Color? getColor(BuildContext context) {
    final Color? color =
        InheritedReferenceResolver.of(
          context,
        ).resolver.resolveContainerForegroundColor(
          context: context,
          style: adaptiveMap['color'],
          isSubtle: adaptiveMap['isSubtle'],
        );
    return color;
  }

  // TODOMarkdown still has some problems
  MarkdownStyleSheet loadMarkdownStyleSheet(BuildContext context) {
    final color = getColor(context);
    final TextStyle style = TextStyle(
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
    );

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
