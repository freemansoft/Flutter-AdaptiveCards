import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// https://adaptivecards.microsoft.com/?topic=CodeBlock
///
/// No contract available
// TODO(username): Add language specific highlighting and line folding.
// language specific highlighting is complex without 3p support
//
class AdaptiveCodeBlock extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a code block from [adaptiveMap] JSON.
  AdaptiveCodeBlock({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveCodeBlockState createState() => AdaptiveCodeBlockState();
}

/// State for [AdaptiveCodeBlock]; renders code with optional line numbers.
class AdaptiveCodeBlockState extends ConsumerState<AdaptiveCodeBlock>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Source code from `code`.
  late String codeSnippet;

  /// Optional language hint from `language` (not yet used for highlighting).
  late String? language;

  /// First displayed line number from `startLineNumber` (default 1).
  late int startLineNumber;

  @override
  void initState() {
    super.initState();
    codeSnippet = adaptiveMap['code']?.toString() ?? '';
    language = adaptiveMap['language']?.toString();
    startLineNumber = adaptiveMap['startLineNumber'] as int? ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final resolver = styleResolver;
    final lines = codeSnippet.split('\n');
    final lineNumbers = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      lineNumbers.writeln('${startLineNumber + i}');
    }

    // Using a Row with two Text widgets.
    // The Line numbers are non-selectable usually, but if we want them to scroll together,
    // they should be in the same scrollable.
    // To match height, we use the same Text Style.

    const textStyle = TextStyle(
      fontFamily: 'Roboto',
      fontFeatures: [FontFeature.tabularFigures()],
      fontSize: 14,
      height: 1.2, // Fixed height to ensure alignment
    );

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Numbers
                SelectableText(
                  lineNumbers.toString(),
                  style: textStyle.copyWith(
                    color:
                        resolver.resolveContainerForegroundColor(
                          style: 'default',
                          isSubtle: true,
                        ) ??
                        Colors.grey,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(width: 12),
                // Code
                SelectableText(
                  codeSnippet,
                  style: textStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
