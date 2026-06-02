import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:intl/intl.dart';

///
/// https://adaptivecards.io/explorer/Input.Date.html
///
class AdaptiveDateInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveDateInput({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveDateInputState createState() => AdaptiveDateInputState();
}

class AdaptiveDateInputState extends State<AdaptiveDateInput>
    with
        AdaptiveTextualInputMixin,
        AdaptiveElementMixin,
        AdaptiveInputMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
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
    } on Exception catch (formatException) {
      // what should we do here?
      assert(() {
        developer.log(
          'failed to init state $formatException.',
          name: runtimeType.toString(),
        );
        return true;
      }());
    }
  }

  @override
  void resetInput() {
    super.resetInput();
    setState(() {
      try {
        selectedDateTime = value.isNotEmpty ? inputFormat.parse(value) : null;
      } on Exception {
        selectedDateTime = null;
      }
      controller.text = selectedDateTime == null
          ? placeholder
          : inputFormat.format(selectedDateTime!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Locale myLocale = Localizations.localeOf(context);
    assert(() {
      developer.log(
        'locale: $myLocale',
        name: runtimeType.toString(),
      );
      return true;
    }());

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
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
                key: generateWidgetKey(adaptiveMap),
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
                  fillColor: styleResolver.resolveInputBackgroundColor(
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
                  final DateTime? result = await rawRootCardWidgetState
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
                    final iso = selectedDateTime!.toIso8601String();
                    setDocumentInputValue(iso);
                    rawRootCardWidgetState.changeValue(id, iso);
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
      setDocumentInputValue(map[id]);
    }
  }

  @override
  bool checkRequired() {
    final adaptiveCardElement = adaptiveCardElementState;
    final formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }

  @override
  void onDocumentValueChanged(Object? valueFromDocument) {
    final next = valueFromDocument?.toString();
    if (next == null || next.isEmpty) {
      selectedDateTime = null;
      controller.text = placeholder;
      return;
    }
    try {
      selectedDateTime = DateTime.parse(next);
      controller.text = inputFormat.format(selectedDateTime!);
    } on Exception {
      // If baseline uses yyyy-MM-dd, fall back to that.
      try {
        selectedDateTime = inputFormat.parse(next);
        controller.text = inputFormat.format(selectedDateTime!);
      } on Exception {
        selectedDateTime = null;
        controller.text = '';
      }
    }
  }
}
