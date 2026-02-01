import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/actions/generic_action.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/TextBlock.html
///
class AdaptiveTextBlock extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTextBlock({
    required this.adaptiveMap,
    required this.supportMarkdown,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  final bool supportMarkdown;

  @override
  AdaptiveTextBlockState createState() => AdaptiveTextBlockState();
}

class AdaptiveTextBlockState extends State<AdaptiveTextBlock>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  // will be replaced later
  late FontWeight fontWeight = FontWeight.normal;
  late double fontSize = 12;
  late Alignment horizontalAlignment;
  late int maxLines;
  late TextAlign textAlign;
  late String text;
  late String? fontFamily;

  late GenericActionOpenUrl action;

  @override
  void initState() {
    super.initState();
    text = parseTextString(
      adaptiveMap['text'] ?? '',
    ); // text block with no text
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // gag me with a hack - the api is built against a type key in a map
    action =
        actionTypeRegistry.getActionForType(
              map: {'type': 'Action.OpenUrl', 'url': ''},
            )!
            as GenericActionOpenUrl;
    // should be lazily calculated because styling could have changed
    final resolver = ProviderScope.containerOf(
      context,
    ).read(styleReferenceResolverProvider);
    horizontalAlignment = resolver.resolveAlignment(
      adaptiveMap['horizontalAlignment'],
    );
    fontSize = resolver.resolveFontSize(
      context: context,
      sizeString: adaptiveMap['size'],
    );
    fontWeight = resolver.resolveFontWeight(adaptiveMap['weight']);
    textAlign = resolver.resolveTextAlign(
      adaptiveMap['horizontalAlignment'],
    );
    fontFamily = resolver.resolveFontType(
      context,
      adaptiveMap['fontType'],
    );
    maxLines = resolver.resolveMaxLines(
      wrap: adaptiveMap['wrap'],
      maxLines: adaptiveMap['maxLines'],
    );
  }

  /*child: */

  // TODOcreate own widget that parses_basic markdown. This might help: https://docs.flutter.io/flutter/widgets/Wrap-class.html
  @override
  Widget build(BuildContext context) {
    final textBody = widget.supportMarkdown
        ? getMarkdownText(context: context)
        : getText();

    final isHeading =
        adaptiveMap['style']?.toString().toLowerCase() == 'heading';

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Semantics(
          header: isHeading,
          // Heading level doesn't have a direct field in Semantics,
          // but we can potentially use custom semantics if needed.
          child: Align(
            // IntrinsicWidth fixed a few things, but breaks more
            alignment: horizontalAlignment,
            child: textBody,
          ),
        ),
      ),
    );
  }

  Widget getText() {
    return Text(
      key: generateWidgetKey(adaptiveMap),
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
      key: generateWidgetKey(adaptiveMap),
      // TODOthe markdown library does currently not support max lines
      // As markdown support is more important than maxLines right now
      // this is in here.
      //maxLines: maxLines,
      data: text,
      styleSheet: loadMarkdownStyleSheet(context),
      onTapLink: (text, href, title) {
        if (href != null) {
          action.tap(
            context: context,
            rawAdaptiveCardState: rawRootCardWidgetState,
            adaptiveMap: adaptiveMap,
            altUrl: href,
          );
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
    final Color? color = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveContainerForegroundColor(
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
