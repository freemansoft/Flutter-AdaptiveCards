import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Input.Toggle.html
///
class AdaptiveToggle extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveToggle({
    required this.adaptiveMap,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveToggleState createState() => AdaptiveToggleState();
}

class AdaptiveToggleState extends State<AdaptiveToggle>
    with AdaptiveInputMixin, AdaptiveElementMixin, AdaptiveVisibilityMixin {
  bool boolValue = false;

  late String valueOff;
  late String valueOn;

  late String title;

  @override
  void initState() {
    super.initState();

    valueOff = adaptiveMap['valueOff']?.toString().toLowerCase() ?? 'false';
    valueOn = adaptiveMap['valueOn']?.toString().toLowerCase() ?? 'true';
    boolValue = value == valueOn;
    title = adaptiveMap['title']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Row(
          children: <Widget>[
            Switch(
              key: ValueKey('${(widget.key! as ValueKey<String>).value}_input'),
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
        if (map[id] != null) {
          boolValue = map[id] as bool;
        }
      });
    }
  }

  @override
  bool checkRequired() {
    return true;
  }
}
