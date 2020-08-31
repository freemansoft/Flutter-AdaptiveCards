import 'package:flutter/material.dart';

import '../additional.dart';
import '../base.dart';
import '../utils.dart';
import 'column.dart';

class AdaptiveColumnSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveColumnSet({Key key, this.adaptiveMap, this.supportMarkdown}) : super(key: key);

  final Map adaptiveMap;
  final bool supportMarkdown;

  @override
  _AdaptiveColumnSetState createState() => _AdaptiveColumnSetState();
}

class _AdaptiveColumnSetState extends State<AdaptiveColumnSet> with AdaptiveElementMixin {
  List<AdaptiveColumn> columns;
  MainAxisAlignment horizontalAlignment;

  @override
  void initState() {
    super.initState();
    columns = List<Map>.from(adaptiveMap["columns"] ?? [])
        .map((child) => AdaptiveColumn(adaptiveMap: child, supportMarkdown: widget.supportMarkdown))
        .toList();

    horizontalAlignment = loadHorizontalAlignment();
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor = getBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
      resolver: resolver,
      adaptiveMap: adaptiveMap,
      approximateDarkThemeColors: widgetState.widget.approximateDarkThemeColors,
      brightness: Theme.of(context).brightness,
    );

    Widget child = Row(
      children: columns.toList(),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: horizontalAlignment,
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
    String horizontalAlignment = adaptiveMap["horizontalAlignment"]?.toLowerCase() ?? "left";

    switch (horizontalAlignment) {
      case "left":
        return  MainAxisAlignment.start;
      case "center":
        return MainAxisAlignment.center;
      case "right":
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
    }
  }
}
