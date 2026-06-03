import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/date_time_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  // will be replaced later
  late FontWeight fontWeight = FontWeight.normal;
  late double fontSize = 12;
  late Alignment horizontalAlignment;
  late int maxLines;
  late TextAlign textAlign;
  late String text;
  late String? fontFamily;
  ProviderSubscription<Map<String, dynamic>?>? _textSubscription;

  ///We're assuming that the only type of action on a text block is an open url
  late GenericActionOpenUrl action;

  String? _localeOf(BuildContext context) {
    try {
      return Localizations.maybeLocaleOf(context)?.toString();
      // Localization lookup can throw outside a MaterialApp in tests.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  String _formatDisplayText(String rawFromResolved) {
    final parsed = parseTextString(rawFromResolved, locale: _localeOf(context));
    return DateTimeUtils.formatText(parsed);
  }

  @override
  void initState() {
    super.initState();
    text = _formatDisplayText(widget.adaptiveMap['text']?.toString() ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _textSubscription?.close();
    final container = ProviderScope.containerOf(context);
    _textSubscription = container.listen<Map<String, dynamic>?>(
      resolvedElementProvider(id),
      (previous, next) {
        if (next == null) return;
        final nextRaw = next['text']?.toString() ?? '';
        final nextDisplay = _formatDisplayText(nextRaw);
        if (nextDisplay == text) return;
        setState(() => text = nextDisplay);
      },
      fireImmediately: true,
    );

    // gag me with a hack - the api is built against a type key in a map
    action =
        actionTypeRegistry.getActionForType(
              map: {'type': 'Action.OpenUrl', 'url': ''},
            )!
            as GenericActionOpenUrl;
    // should be lazily calculated because styling could have changed
    final resolver = styleResolver;
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

  @override
  void dispose() {
    _textSubscription?.close();
    _textSubscription = null;
    super.dispose();
  }

  /*child: */

  // TODOcreate own widget that parses_basic markdown. This might help: https://docs.flutter.io/flutter/widgets/Wrap-class.html
  @override
  Widget build(BuildContext context) {
    final textBody = widget.supportMarkdown
        ? getMarkdownText(context: context)
        : getText();

    final isHeading = style?.toLowerCase() == 'heading';

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

  /// Returns Text
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

  /// Returns MarkdownBody
  Widget getMarkdownText({required BuildContext context}) {
    return MarkdownBody(
      key: generateWidgetKey(adaptiveMap),
      // Bug: the markdown library does currently not support max lines
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

  Color? getColor(BuildContext context) {
    final Color? color = styleResolver.resolveContainerForegroundColor(
      style: adaptiveMap['color'],
      isSubtle: adaptiveMap['isSubtle'],
    );
    return color;
  }

  // TODO(username): Markdown still has some problems
  MarkdownStyleSheet loadMarkdownStyleSheet(BuildContext context) {
    final color = getColor(context);
    final TextStyle style = TextStyle(
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
    );
    // this doesn't actually work as is documented in flutter_markdown and flutter_markdown_plus
    final TextStyle pStyle = (maxLines == 1)
        ? TextStyle(
            fontWeight: fontWeight,
            fontSize: fontSize,
            color: color,
            overflow: TextOverflow.ellipsis,
          )
        : TextStyle(
            fontWeight: fontWeight,
            fontSize: fontSize,
            color: color,
          );


    final TextStyle aStyle = TextStyle(
      fontWeight: fontWeight,
      fontSize: fontSize,
      decoration: TextDecoration.underline, // Add the underline
      color: color,
    );

    return MarkdownStyleSheet(
      a: aStyle,
      blockquote: style,
      code: style,
      em: style,
      strong: style.copyWith(fontWeight: FontWeight.bold),
      p: pStyle,
      //pPadding: EdgeInsets.zero, // for the bullet points
    );
  }
}
