import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Implements
/// https://adaptivecards.io/explorer/FactSet.html
/// https://adaptivecards.io/explorer/Fact.html
///
class AdaptiveFactSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveFactSet({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveFactSetState createState() => AdaptiveFactSetState();
}

class AdaptiveFactSetState extends State<AdaptiveFactSet>
    with AdaptiveElementMixin {
  late List<Map> facts;
  Color? backgroundColor;

  @override
  void initState() {
    super.initState();

    /// https://adaptivecards.io/explorer/Fact.html
    facts = List<Map>.from(adaptiveMap['facts']).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    backgroundColor =
        InheritedReferenceResolver.of(
          context,
        ).resolver.resolveContainerBackgroundColorIfNoBackgroundAndNoStyle(
          context: context,
          style: adaptiveMap['style']?.toString(),
          backgroundImageUrl: adaptiveMap['backgroundImage']?['url']
              ?.toString(),
        );
  }

  @override
  Widget build(BuildContext context) {
    var color = getColor(context);

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Container(
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facts
                  .map(
                    (fact) => Text(
                      fact['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facts
                  .map(
                    (fact) => MarkdownBody(
                      data: fact['value'],
                      styleSheet: loadMarkdownStyleSheet(color),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet loadMarkdownStyleSheet(Color? color) {
    TextStyle style = TextStyle(color: color);

    return MarkdownStyleSheet(
      a: style,
      blockquote: style,
      code: style,
      em: style,
      strong: style.copyWith(fontWeight: FontWeight.bold),
      p: style,
    );
  }

  Color? getColor(BuildContext context) {
    Color? color =
        InheritedReferenceResolver.of(
          context,
        ).resolver.resolveContainerForegroundColor(
          context: context,
          style: adaptiveMap['style'],
          isSubtle: adaptiveMap['isSubtle'],
        );

    return color;
  }
}
