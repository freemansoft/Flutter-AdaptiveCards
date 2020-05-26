import 'package:flutter/material.dart';

import '../additional.dart';
import '../base.dart';
import '../utils.dart';

class AdaptiveContainer extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveContainer({Key key, this.adaptiveMap}) : super(key: key);

  final Map adaptiveMap;

  @override
  _AdaptiveContainerState createState() => _AdaptiveContainerState();
}

class _AdaptiveContainerState extends State<AdaptiveContainer> with AdaptiveElementMixin {
// TODO implement verticalContentAlignment
  List<Widget> children;

  Color backgroundColor;

  @override
  void initState() {
    super.initState();
    if (adaptiveMap["items"] != null) {
      children = List<Map>.from(adaptiveMap["items"]).map((child) {
        return widgetState.cardRegistry.getElement(child);
      }).toList();
    } else {
      children = [];
    }

    String colorString = resolver.hostConfig["containerStyles"][adaptiveMap["style"] ?? "default"]["backgroundColor"];

    backgroundColor = parseColor(colorString);
  }

  @override
  Widget build(BuildContext context) {
    return ChildStyler(
      adaptiveMap: adaptiveMap,
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        child: SeparatorElement(
          adaptiveMap: adaptiveMap,
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark && adaptiveMap["style"] == null
                ? null
                : backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: children.toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}