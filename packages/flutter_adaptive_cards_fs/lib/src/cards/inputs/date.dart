import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

///
/// https://adaptivecards.io/explorer/Input.Date.html
///
class AdaptiveDateInput extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
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

class AdaptiveDateInputState extends ConsumerState<AdaptiveDateInput>
    with
        AdaptiveTextualInputMixin,
        AdaptiveElementMixin,
        AdaptiveInputMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  DateTime? selectedDateTime;
  DateTime? min;
  DateTime? max;
  final inputFormat = DateFormat('yyyy-MM-dd');
  TextEditingController controller = TextEditingController();
  bool _initialValueSynced = false;

  @override
  void initState() {
    super.initState();

    try {
      if (adaptiveMap.containsKey('min')) {
        min = inputFormat.parse(adaptiveMap['min']);
      }
      if (adaptiveMap.containsKey('max')) {
        max = inputFormat.parse(adaptiveMap['max']);
      }
    } on Exception catch (formatException) {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialValueSynced) {
      _initialValueSynced = true;
      onDocumentValueChanged(readResolvedInput().valueRaw);
    }
  }

  @override
  Widget build(BuildContext context) {
    listenForResolvedValueChanges();
    final input = watchResolvedInput();

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
              label: input.label,
              isRequired: input.isRequired,
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
                  hintText: input.placeholder,
                  // required or box will exist even though field is hidden or half height
                  hintStyle: const TextStyle(),
                  errorStyle: const TextStyle(height: 0),
                ),
                validator: (value) {
                  if (!input.isRequired) return null;
                  if (value == null || value.isEmpty) {
                    setLocalValidationError();
                    return '';
                  }
                  clearLocalValidationError();
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
                          ? input.placeholder
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
              errorMessage: input.errorMessage,
              showError: input.isInvalid,
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
    final input = readResolvedInput();
    final next = valueFromDocument?.toString();
    if (next == null || next.isEmpty) {
      selectedDateTime = null;
      controller.text = input.placeholder;
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
