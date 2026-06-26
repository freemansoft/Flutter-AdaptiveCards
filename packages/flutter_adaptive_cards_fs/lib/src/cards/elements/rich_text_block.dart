import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/models/text_run.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/date_time_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/RichTextBlock.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/rich-text-block
///
class AdaptiveRichTextBlock extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a rich text block from [adaptiveMap] JSON.
  AdaptiveRichTextBlock({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveRichTextBlockState createState() => AdaptiveRichTextBlockState();
}

/// State for [AdaptiveRichTextBlock]; builds [TextSpan] children from inlines.
class AdaptiveRichTextBlockState extends ConsumerState<AdaptiveRichTextBlock>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  late TextAlign _textAlign;
  late Alignment _horizontalAlignment;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolver = styleResolver;
    _horizontalAlignment = resolver.resolveAlignment(
      adaptiveMap['horizontalAlignment'] as String?,
    );
    _textAlign = resolver.resolveTextAlign(
      adaptiveMap['horizontalAlignment'] as String?,
    );
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  String? _localeOf(BuildContext context) {
    try {
      return Localizations.maybeLocaleOf(context)?.toString();
      // Localization lookup can throw outside a MaterialApp in tests.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  String _formatRunText(String raw, BuildContext context) {
    final parsed = parseTextString(raw, locale: _localeOf(context));
    return DateTimeUtils.formatText(parsed);
  }

  TextDecoration? _decorationFor(TextRunModel run) {
    final decorations = <TextDecoration>[];
    if (run.underline) {
      decorations.add(TextDecoration.underline);
    }
    if (run.strikethrough) {
      decorations.add(TextDecoration.lineThrough);
    }
    if (decorations.isEmpty) return null;
    return TextDecoration.combine(decorations);
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer? _recognizerFor(
    BuildContext context,
    Map<String, dynamic> actionMap,
  ) {
    final action = actionTypeRegistry.getActionForType(map: actionMap);
    if (action == null) return null;
    final recognizer = TapGestureRecognizer()
      ..onTap = () => action.tap(
        context: context,
        rawAdaptiveCardState: rawRootCardWidgetState,
        adaptiveMap: actionMap,
      );
    _recognizers.add(recognizer);
    return recognizer;
  }

  List<InlineSpan> _createInlineSpans(
    BuildContext context,
    Map<String, dynamic> sourceMap,
  ) {
    _disposeRecognizers();
    final resolver = styleResolver;
    final inlinesRaw = sourceMap['inlines'];
    if (inlinesRaw is! List) return const [];

    final spans = <InlineSpan>[];
    for (final inline in inlinesRaw) {
      if (inline is! Map) continue;
      final map = Map<String, dynamic>.from(inline);
      if (map['type']?.toString() != 'TextRun') continue;

      final run = TextRunModel.fromJson(map);
      if (run.text.isEmpty) continue;

      final appearance = resolver.resolveTextBlockStyle(
        styleName: null,
        size: run.size,
        weight: run.weight,
        color: run.color,
        fontType: run.fontType,
        isSubtle: run.isSubtle,
      );
      final color = resolver.resolveContainerForegroundColor(
        style: appearance.color,
        isSubtle: appearance.isSubtle,
      );
      final fontSize = resolver.resolveFontSize(
        context: context,
        sizeString: appearance.size,
      );
      final fontWeight = resolver.resolveFontWeight(appearance.weight);
      final fontFamily = resolver.resolveFontType(context, appearance.fontType);

      TapGestureRecognizer? recognizer;
      final selectAction = run.selectAction;
      if (selectAction != null) {
        recognizer = _recognizerFor(context, selectAction);
      }

      spans.add(
        TextSpan(
          text: _formatRunText(run.text, context),
          recognizer: recognizer,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
            decoration: _decorationFor(run),
            backgroundColor: run.highlight
                ? Theme.of(context).highlightColor.withValues(alpha: 0.35)
                : null,
          ),
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ref.watch(resolvedElementProvider(id)) ?? adaptiveMap;
    final spans = _createInlineSpans(context, resolved);
    final isHeading = style?.toLowerCase() == 'heading';

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Semantics(
          header: isHeading,
          child: Align(
            alignment: _horizontalAlignment,
            child: Text.rich(
              key: generateWidgetKey(adaptiveMap),
              TextSpan(children: spans),
              textAlign: _textAlign,
            ),
          ),
        ),
      ),
    );
  }
}
