import 'package:flutter/material.dart';

import '../additional.dart';
import '../base.dart';

class AdaptiveToggle extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveToggle({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveToggleState createState() => _AdaptiveToggleState();
}

class _AdaptiveToggleState extends State<AdaptiveToggle>
    with AdaptiveInputMixin, AdaptiveElementMixin {
  bool boolValue = false;

  late String valueOff;
  late String valueOn;

  late String title;

  @override
  void initState() {
    super.initState();

    valueOff = adaptiveMap["valueOff"] ?? "false";
    valueOn = adaptiveMap["valueOn"] ?? "true";
    boolValue = value == valueOn;
    title = adaptiveMap["title"] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Row(
        children: <Widget>[
          Switch(
            value: boolValue,
            onChanged: (newValue) {
              setState(() {
                boolValue = newValue;
              });
            },
          ),
          Expanded(
            child: Text(title),
          ),
        ],
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = boolValue ? valueOn : valueOff;
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      setState(() {
        boolValue = map[id];
      });
    }
  }

  @override
  bool checkRequired() {
    return true;
  }
}
