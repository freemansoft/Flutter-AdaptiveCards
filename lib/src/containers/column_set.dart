import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

import '../adaptive_mixins.dart';
import '../additional.dart';
import 'column.dart';

///
/// https://adaptivecards.io/explorer/ColumnSet.html
///
class AdaptiveColumnSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveColumnSet(
      {super.key, required this.adaptiveMap, required this.supportMarkdown});

  @override
  final Map<String, dynamic> adaptiveMap;
  final bool supportMarkdown;

  @override
  AdaptiveColumnSetState createState() => AdaptiveColumnSetState();
}

class AdaptiveColumnSetState extends State<AdaptiveColumnSet>
    with AdaptiveElementMixin {
  List<AdaptiveColumn>? columns;
  MainAxisAlignment? horizontalAlignment;
  Color? backgroundColor;

  @override
  void initState() {
    super.initState();
    columns = List<Map<String, dynamic>>.from(adaptiveMap['columns'] ?? [])
        .map((child) => AdaptiveColumn(
            adaptiveMap: child, supportMarkdown: widget.supportMarkdown))
        .toList();

    horizontalAlignment = loadHorizontalAlignment();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    backgroundColor = InheritedReferenceResolver.of(context)
        .resolver
        .resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
            context: context,
            style: adaptiveMap['style']?.toString(),
            backgroundImageUrl:
                adaptiveMap['backgroundImage']?['url']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: horizontalAlignment!,
      children: columns!.toList(),
    );

    if (!widget.supportMarkdown) {
      child = IntrinsicHeight(child: child);
    }

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        child: Container(
          color: backgroundColor,
          child: child,
        ),
      ),
    );
  }

  MainAxisAlignment loadHorizontalAlignment() {
    String horizontalAlignment =
        adaptiveMap['horizontalAlignment']?.toLowerCase() ?? 'left';

    switch (horizontalAlignment) {
      case 'left':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'right':
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
    }
  }
}
