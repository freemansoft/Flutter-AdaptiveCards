import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.Number.html
///
// ignore_for_file: unnecessary_const
class AdaptiveNumberInput extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveNumberInput({
    required this.adaptiveMap,
    required this.widgetState,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  late final String id;

  @override
  AdaptiveNumberInputState createState() => AdaptiveNumberInputState();
}

class AdaptiveNumberInputState extends State<AdaptiveNumberInput>
    with AdaptiveTextualInputMixin, AdaptiveInputMixin, AdaptiveElementMixin {
  TextEditingController controller = TextEditingController();
  bool stateHasError = false;

  String? label;
  late bool isRequired;
  late int min;
  late int max;

  @override
  void initState() {
    super.initState();

    label = adaptiveMap['label']?.toString();
    isRequired = adaptiveMap['isRequired'] as bool? ?? false;

    controller.text = value;
    stateHasError = false;
    min = adaptiveMap['min'] as int? ?? 0;
    max = adaptiveMap['max'] as int? ?? 100;
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      widgetState: widgetState,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          loadLabel(
            context: context,
            label: label,
            isRequired: isRequired,
          ),
          SizedBox(
            height: 40,
            child: TextFormField(
              style: const TextStyle(),
              keyboardType: TextInputType.number,
              inputFormatters: [
                TextInputFormatter.withFunction((oldVal, newVal) {
                  if (newVal.text == '') return newVal;
                  final int newNumber = int.parse(newVal.text);
                  if (newNumber >= min && newNumber <= max) return newVal;
                  return oldVal;
                }),
              ],
              controller: controller,
              decoration: InputDecoration(
                // labelText: placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
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
                  setState(() {
                    stateHasError = true;
                  });
                  return '';
                }
                setState(() {
                  stateHasError = false;
                });
                return null;
              },
            ),
          ),
          loadErrorMessage(
            context: context,
            errorMessage: errorMessage,
            stateHasError: stateHasError,
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
      controller.text = map[id].toString();
    }
  }

  @override
  bool checkRequired() {
    final adaptiveCardElement = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adaptiveCardElementStateProvider);
    final formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }
}
