import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/models/resolved_text_appearance.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/date_time_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/TextBlock.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/text-block
///
class AdaptiveTextBlock extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a text block from [adaptiveMap] JSON.
  ///
  /// When [supportMarkdown] is true, renders markdown and routes link taps
  /// through `Action.OpenUrl`.
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

  /// Whether to render `text` as markdown instead of plain [Text].
  final bool supportMarkdown;

  @override
  AdaptiveTextBlockState createState() => AdaptiveTextBlockState();
}

/// State for [AdaptiveTextBlock]; resolves typography and reactive text.
class AdaptiveTextBlockState extends ConsumerState<AdaptiveTextBlock>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Resolved font weight from HostConfig and element properties.
  late FontWeight fontWeight = FontWeight.normal;

  /// Resolved font size in logical pixels.
  late double fontSize = 12;

  /// Widget alignment from `horizontalAlignment`.
  late Alignment horizontalAlignment;

  /// Maximum lines from `maxLines` / `wrap` resolution.
  late int maxLines;

  /// Text alignment within the text widget.
  late TextAlign textAlign;

  /// Display string after DATE/TIME macro formatting.
  late String text;

  /// Resolved font family from `fontType`.
  late String? fontFamily;

  /// Merged size, weight, color, and subtle flags from HostConfig.
  late ResolvedTextAppearance _textAppearance = const ResolvedTextAppearance();

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    // gag me with a hack - the api is built against a type key in a map
    action =
        actionTypeRegistry.getActionForType(
              map: {'type': 'Action.OpenUrl', 'url': ''},
            )!
            as GenericActionOpenUrl;
    // should be lazily calculated because styling could have changed
    final resolver = styleResolver;
    final appearance = resolver.resolveTextBlockStyle(
      styleName: adaptiveMap['style'] as String?,
      size: adaptiveMap['size'] as String?,
      weight: adaptiveMap['weight'] as String?,
      color: adaptiveMap['color'] as String?,
      fontType: adaptiveMap['fontType'] as String?,
      isSubtle: adaptiveMap['isSubtle'] as bool?,
    );
    horizontalAlignment = resolver.resolveAlignment(
      adaptiveMap['horizontalAlignment'] as String?,
    );
    fontSize = resolver.resolveFontSize(
      context: context,
      sizeString: appearance.size,
    );
    fontWeight = resolver.resolveFontWeight(appearance.weight);
    textAlign = resolver.resolveTextAlign(
      adaptiveMap['horizontalAlignment'] as String?,
    );
    fontFamily = resolver.resolveFontType(
      context,
      appearance.fontType,
    );
    _textAppearance = appearance;
    maxLines = resolver.resolveMaxLines(
      wrap: adaptiveMap['wrap'],
      maxLines: adaptiveMap['maxLines'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ref.watch(resolvedElementProvider(id));
    text = _formatDisplayText(
      resolved?['text']?.toString() ?? widget.adaptiveMap['text']?.toString() ?? '',
    );

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
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: fontWeight,
        fontSize: fontSize,
        fontFamily: fontFamily,
        color: getColor(context),
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

  /// Resolves foreground color from [_textAppearance] and HostConfig.
  Color? getColor(BuildContext context) {
    final Color? color = styleResolver.resolveContainerForegroundColor(
      style: _textAppearance.color,
      isSubtle: _textAppearance.isSubtle,
    );
    return color;
  }

  /// Builds a [MarkdownStyleSheet] matching resolved text appearance.
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
