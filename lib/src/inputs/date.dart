import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:format/format.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../adaptive_mixins.dart';
import '../additional.dart';
import '../cards/adaptive_card_element.dart';
import '../utils.dart';

///
/// https://adaptivecards.io/explorer/Input.Date.html
///
class AdaptiveDateInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveDateInput({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveDateInputState createState() => AdaptiveDateInputState();
}

class AdaptiveDateInputState extends State<AdaptiveDateInput>
    with AdaptiveTextualInputMixin, AdaptiveElementMixin, AdaptiveInputMixin {
  String? label;
  late bool isRequired;
  DateTime? selectedDateTime;
  DateTime? min;
  DateTime? max;
  final inputFormat = DateFormat('yyyy-MM-dd');
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    label = adaptiveMap['label'];
    isRequired = adaptiveMap['isRequired'] ?? false;
    try {
      // set the value from the card as the current selected
      selectedDateTime = inputFormat.parse(value);
      if (adaptiveMap.containsKey('min')) {
        min = inputFormat.parse(adaptiveMap['min']);
      }
      if (adaptiveMap.containsKey('max')) {
        max = inputFormat.parse(adaptiveMap['max']);
      }
    } catch (formatException) {
      // what should we do here?
    }
  }

  @override
  Widget build(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    assert(() {
      developer.log(
        format('locale: {}', myLocale),
        name: runtimeType.toString(),
      );
      return true;
    }());

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          loadLabel(label, isRequired),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextFormField(
              readOnly: true,
              style: const TextStyle(),
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(width: 1),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(width: 1),
                ),
                filled: true,
                suffixIcon: const Icon(Icons.calendar_today, size: 15),
                hintText: placeholder,
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
              onTap: () async {
                DateTime? result = await widgetState.datePickerForPlatform(
                  context,
                  selectedDateTime,
                  min,
                  max,
                );
                if (result != null) {
                  setState(() {
                    selectedDateTime = result;
                    controller.text =
                        selectedDateTime == null
                            ? placeholder
                            : inputFormat.format(selectedDateTime!);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void appendInput(Map map) {
    if (selectedDateTime != null) {
      map[id] = selectedDateTime!.toIso8601String();
    }
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      try {
        setState(() {
          selectedDateTime = inputFormat.parse(map[id]);
          controller.text =
              selectedDateTime == null
                  ? placeholder
                  : inputFormat.format(selectedDateTime!);
        });
      } catch (formatException) {
        developer.log(
          format('{}', formatException),
          name: runtimeType.toString(),
        );
      }
    }
  }

  @override
  bool checkRequired() {
    var adaptiveCardElement = context.read<AdaptiveCardElementState>();
    var formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }
}
