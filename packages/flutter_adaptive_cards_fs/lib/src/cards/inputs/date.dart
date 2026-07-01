import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/date_input_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

///
/// https://adaptivecards.io/explorer/Input.Date.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/input-date
///
class AdaptiveDateInput extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a date input from [adaptiveMap] JSON.
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

/// State for [AdaptiveDateInput]; opens a platform date picker on tap.
class AdaptiveDateInputState extends ConsumerState<AdaptiveDateInput>
    with
        AdaptiveTextualInputMixin,
        AdaptiveElementMixin,
        AdaptiveInputMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  /// Currently selected date, or null when empty.
  DateTime? selectedDateTime;

  /// Minimum allowed date from `min` (`yyyy-MM-dd`).
  DateTime? min;

  /// Maximum allowed date from `max` (`yyyy-MM-dd`).
  DateTime? max;

  /// Parser/formatter for Adaptive Cards date strings.
  final inputFormat = DateFormat('yyyy-MM-dd');

  /// Read-only field showing the formatted selected date.
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
                  // required or box will exist even though field is hidden or
                  // half height
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
                      controller.text = formatAdaptiveDateValue(result);
                    });
                    final formatted = formatAdaptiveDateValue(result);
                    setDocumentInputValue(formatted);
                    rawRootCardWidgetState.changeValue(id, formatted);
                    notifyUserInputValueChanged(formatted, committed: true);
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
      map[id] = formatAdaptiveDateValue(selectedDateTime!);
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
    final parsed = parseAdaptiveDateValue(valueFromDocument);
    if (parsed == null) {
      if (selectedDateTime == null && controller.text.isEmpty) return;
      setState(() {
        selectedDateTime = null;
        controller.text = '';
      });
      return;
    }
    final formatted = formatAdaptiveDateValue(parsed);
    if (selectedDateTime?.year == parsed.year &&
        selectedDateTime?.month == parsed.month &&
        selectedDateTime?.day == parsed.day &&
        controller.text == formatted) {
      return;
    }
    setState(() {
      selectedDateTime = parsed;
      controller.text = formatted;
    });
  }
}
