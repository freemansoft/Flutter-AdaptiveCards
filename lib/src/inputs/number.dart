import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.Number.html
///
// ignore_for_file: unnecessary_const
class AdaptiveNumberInput extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveNumberInput({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveNumberInputState createState() => AdaptiveNumberInputState();
}

class AdaptiveNumberInputState extends State<AdaptiveNumberInput>
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          loadLabel(label, isRequired),
          SizedBox(
            height: 40,
            child: TextFormField(
              style: const TextStyle(),
              keyboardType: TextInputType.number,
              inputFormatters: [
                TextInputFormatter.withFunction((oldVal, newVal) {
                  if (newVal.text == '') return newVal;
                  int newNumber = int.parse(newVal.text);
                  if (newNumber >= min && newNumber <= max) return newVal;
                  return oldVal;
                }),
              ],
              controller: controller,
              decoration: InputDecoration(
                // labelText: placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                enabledBorder: const OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  borderSide: const BorderSide(),
                ),
                filled: true,
                fillColor:
                    InheritedReferenceResolver.of(
                      context,
                    ).resolver.resolveInputBackgroundColor(
                      context: context,
                      style: null,
                    ),
                hintText: placeholder,
                // required or box will exist even though field is hidden or half height
                hintStyle: const TextStyle(),
                errorStyle: const TextStyle(height: 0),
              ),
              validator: (value) {
                if (!isRequired) return null;
                if (value == null || value.isEmpty) {
                  return '';
                }
                return null;
              },
            ),
          ),
        ],
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

  @override
  bool checkRequired() {
    var adaptiveCardElement = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adaptiveCardElementStateProvider);
    var formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }
}
