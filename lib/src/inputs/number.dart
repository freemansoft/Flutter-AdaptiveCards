import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../additional.dart';
import '../base.dart';

class AdaptiveNumberInput extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveNumberInput({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveNumberInputState createState() => _AdaptiveNumberInputState();
}

class _AdaptiveNumberInputState extends State<AdaptiveNumberInput>
    with AdaptiveTextualInputMixin, AdaptiveInputMixin, AdaptiveElementMixin {
  TextEditingController controller = TextEditingController();

  late int min;
  late int max;

  @override
  void initState() {
    super.initState();

    controller.text = value;
    min = adaptiveMap['min'];
    max = adaptiveMap['max'];
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: TextField(
        keyboardType: TextInputType.number,
        inputFormatters: [
          TextInputFormatter.withFunction((oldVal, newVal) {
            if (newVal.text == '') return newVal;
            int newNumber = int.parse(newVal.text);
            if (newNumber >= min && newNumber <= max) return newVal;
            return oldVal;
          })
        ],
        controller: controller,
        decoration: InputDecoration(
          labelText: placeholder,
        ),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = controller.text;
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      controller.text = map[id];
    }
  }
}
