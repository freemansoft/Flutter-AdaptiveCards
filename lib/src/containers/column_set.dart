import 'package:flutter/material.dart';

import '../additional.dart';
import '../base.dart';
import '../utils.dart';
import 'column.dart';

class AdaptiveColumnSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveColumnSet({Key key, this.adaptiveMap}) : super(key: key);

  final Map adaptiveMap;

  @override
  _AdaptiveColumnSetState createState() => _AdaptiveColumnSetState();
}

class _AdaptiveColumnSetState extends State<AdaptiveColumnSet> with AdaptiveElementMixin {
  List<AdaptiveColumn> columns;

  @override
  void initState() {
    super.initState();
    columns = List<Map>.from(adaptiveMap["columns"] ?? []).map((child) => AdaptiveColumn(adaptiveMap: child)).toList();
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor = getBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
      resolver: resolver,
      adaptiveMap: adaptiveMap,
      approximateDarkThemeColors: widgetState.widget.approximateDarkThemeColors,
      brightness: Theme.of(context).brightness,
    );

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        child: Container(
          color: backgroundColor,
          child: Row(
            children: columns.toList(),
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
          ),
        ),
      ),
    );
  }
}
