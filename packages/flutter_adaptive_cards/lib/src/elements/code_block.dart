import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

/// https://adaptivecards.microsoft.com/?topic=CodeBlock
///
/// No contract available
// TODO(username): Language specific syntax highlighting would be nice,
// but is complex without external deps like flutter_highlight
// TODO(username): Support collapse to specific number of lines
//
class AdaptiveCodeBlock extends StatefulWidget with AdaptiveElementWidgetMixin {
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

class AdaptiveCodeBlockState extends State<AdaptiveCodeBlock>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late String codeSnippet;
  late String? language;
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
      fontFamily: 'Courier',
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
                  style: textStyle.copyWith(color: Colors.grey),
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
