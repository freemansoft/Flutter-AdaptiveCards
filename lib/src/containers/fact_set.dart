/// Implements
/// https://adaptivecards.io/explorer/FactSet.html
/// https://adaptivecards.io/explorer/Fact.html
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../additional.dart';
import '../base.dart';

class AdaptiveFactSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveFactSet({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveFactSetState createState() => _AdaptiveFactSetState();
}

class _AdaptiveFactSetState extends State<AdaptiveFactSet>
    with AdaptiveElementMixin {
  late List<Map> facts;

  @override
  void initState() {
    super.initState();

    /// https://adaptivecards.io/explorer/Fact.html
    facts = List<Map>.from(adaptiveMap["facts"]).toList();
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor =
        resolver.resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
            context: context,
            style: adaptiveMap['style']?.toString(),
            backgroundImageUrl:
                adaptiveMap['backgroundImage']?['url']?.toString());

    var color = getColor();

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Container(
        color: backgroundColor,
        child: Row(
          children: [
            Column(
              children: facts
                  .map((fact) => Text(
                        fact["title"],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: color),
                      ))
                  .toList(),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            SizedBox(
              width: 8.0,
            ),
            Column(
              children: facts
                  .map((fact) => MarkdownBody(
                        data: fact["value"],
                        styleSheet: loadMarkdownStyleSheet(color),
                      ))
                  .toList(),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
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

  Color? getColor() {
    Color? color = resolver.resolveForegroundColor(
        context: context,
        colorType: adaptiveMap["style"],
        isSubtle: adaptiveMap["isSubtle"]);

    return color;
  }
}
