import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.Number.html
///
// ignore_for_file: unnecessary_const
class AdaptiveNumberInput extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveNumberInput({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveNumberInputState createState() => AdaptiveNumberInputState();
}

class AdaptiveNumberInputState extends ConsumerState<AdaptiveNumberInput>
    with
        AdaptiveTextualInputMixin,
        AdaptiveInputMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  TextEditingController controller = TextEditingController();
  bool _controllerListenerInstalled = false;
  bool _isUpdatingFromDocument = false;
  bool _initialValueSynced = false;
  late int min;
  late int max;

  @override
  void initState() {
    super.initState();
    min = adaptiveMap['min'] as int? ?? 0;
    max = adaptiveMap['max'] as int? ?? 100;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialValueSynced) {
      _initialValueSynced = true;
      onDocumentValueChanged(readResolvedInput().valueRaw);
    }

    if (!_controllerListenerInstalled) {
      _controllerListenerInstalled = true;
      controller.addListener(() {
        if (_isUpdatingFromDocument) return;
        final text = controller.text;
        setDocumentInputValue(text);
        rawRootCardWidgetState.changeValue(id, text);
      });
    }
  }

  @override
  void onDocumentValueChanged(Object? valueFromDocument) {
    final next = valueFromDocument?.toString() ?? '';
    if (controller.text == next) return;
    _isUpdatingFromDocument = true;
    controller.text = next;
    _isUpdatingFromDocument = false;
  }

  @override
  Widget build(BuildContext context) {
    listenForResolvedValueChanges();
    final input = watchResolvedInput();

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
              height: 40,
              child: TextFormField(
                key: generateWidgetKey(adaptiveMap),
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
                  fillColor: styleResolver.resolveInputBackgroundColor(
                    context: context,
                    style: null,
                  ),
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
    map[id] = controller.text;
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
}
