///
/// https://adaptivecards.io/explorer/Input.Number.html
///
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../adaptive_card_element.dart';
import '../additional.dart';
import '../base.dart';
import '../utils.dart';

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

  String? label;
  late bool isRequired;
  late int min;
  late int max;

  @override
  void initState() {
    super.initState();

    label = adaptiveMap['label'];
    isRequired = adaptiveMap['isRequired'] ?? false;

    controller.text = value;
    min = adaptiveMap['min'];
    max = adaptiveMap['max'];
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          loadLabel(label, isRequired),
          SizedBox(
            height: 40,
            child: TextFormField(
              style:
                  TextStyle(backgroundColor: Colors.white, color: Colors.black),
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
                // labelText: placeholder,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0)),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                enabledBorder: const OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
                hoverColor: Colors.white,
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.black54),
                errorStyle: TextStyle(height: 0),
              ),
              validator: (value) {
                if (!isRequired) return null;
                if (value == null || value.isEmpty) {
                  return '';
                }
                return null;
              },
            ),
          )
        ]));
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

  @override
  bool checkRequired() {
    var adaptiveCardElement = context.read<AdaptiveCardElementState>();
    var formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }
}
