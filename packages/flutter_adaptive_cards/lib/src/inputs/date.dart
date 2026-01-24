import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:format/format.dart';
import 'package:intl/intl.dart';

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
  bool stateHasError = false;

  @override
  void initState() {
    super.initState();

    label = adaptiveMap['label'] as String?;
    isRequired = adaptiveMap['isRequired'] as bool? ?? false;
    try {
      // set the value from the card as the current selected
      selectedDateTime = inputFormat.parse(value);
      if (adaptiveMap.containsKey('min')) {
        min = inputFormat.parse(adaptiveMap['min']);
      }
      if (adaptiveMap.containsKey('max')) {
        max = inputFormat.parse(adaptiveMap['max']);
      }
      // catch them all
      // ignore: avoid_catches_without_on_clauses
    } catch (formatException) {
      // what should we do here?
    }
  }

  @override
  Widget build(BuildContext context) {
    final Locale myLocale = Localizations.localeOf(context);
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
          loadLabel(
            context: context,
            label: label,
            isRequired: isRequired,
          ),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextFormField(
              readOnly: true,
              style: const TextStyle(),
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
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
                fillColor:
                    InheritedReferenceResolver.of(
                      context,
                    ).resolver.resolveInputBackgroundColor(
                      context: context,
                      style: null,
                    ),
                suffixIcon: const Icon(Icons.calendar_today, size: 15),
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
              onTap: () async {
                final DateTime? result = await widgetState
                    .datePickerForPlatform(
                      context,
                      selectedDateTime,
                      min,
                      max,
                    );
                if (result != null) {
                  setState(() {
                    selectedDateTime = result;
                    controller.text = selectedDateTime == null
                        ? placeholder
                        : inputFormat.format(selectedDateTime!);
                  });
                }
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
          controller.text = selectedDateTime == null
              ? placeholder
              : inputFormat.format(selectedDateTime!);
        });
        // catch them all
        // ignore: avoid_catches_without_on_clauses
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
    final adaptiveCardElement = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adaptiveCardElementStateProvider);
    final formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }
}
