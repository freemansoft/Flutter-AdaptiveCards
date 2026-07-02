import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.Toggle.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/input-toggle
///
class AdaptiveToggle extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a toggle input from [adaptiveMap] JSON.
  AdaptiveToggle({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveToggleState createState() => AdaptiveToggleState();
}

/// State for [AdaptiveToggle]; maps a [Switch] to `valueOn` / `valueOff`.
class AdaptiveToggleState extends ConsumerState<AdaptiveToggle>
    with
        AdaptiveInputMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  /// Current switch position derived from the document value.
  bool boolValue = false;

  /// Submitted value when the switch is off (`valueOff`).
  late String valueOff;

  /// Submitted value when the switch is on (`valueOn`).
  late String valueOn;

  /// Label shown beside the switch (`title`).
  late String title;

  @override
  void initState() {
    super.initState();

    valueOff = adaptiveMap['valueOff']?.toString().toLowerCase() ?? 'false';
    valueOn = adaptiveMap['valueOn']?.toString().toLowerCase() ?? 'true';
    title = adaptiveMap['title']?.toString() ?? '';
    boolValue = readResolvedInput().valueAsString == valueOn;
  }

  @override
  void resetInput() {
    super.resetInput();
    setState(() {});
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merge the switch and its adjacent label into one semantics node
            // so a screen reader announces the label with the toggle state
            // (the Row holds only the switch + its label, so merging is safe).
            MergeSemantics(
              child: Row(
                children: <Widget>[
                  Switch(
                    key: generateWidgetKey(adaptiveMap),
                    value: boolValue,
                    onChanged: (newValue) {
                      setState(() {
                        boolValue = newValue;
                      });
                      final docValue = boolValue ? valueOn : valueOff;
                      setDocumentInputValue(docValue);
                      rawRootCardWidgetState.changeValue(id, docValue);
                      notifyUserInputValueChanged(docValue, committed: true);
                    },
                  ),
                  Expanded(
                    child: loadLabel(
                      context: context,
                      label: input.label ?? title,
                      isRequired: input.isRequired,
                    ),
                  ),
                ],
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
    map[id] = boolValue ? valueOn : valueOff;
  }

  @override
  void initInput(Map map) {
    if (map[id] == null) return;
    final raw = map[id];
    if (raw is bool) {
      setDocumentInputValue(raw ? valueOn : valueOff);
    } else {
      setDocumentInputValue(raw);
    }
  }

  @override
  void onDocumentValueChanged(Object? valueFromDocument) {
    final next = valueFromDocument?.toString().toLowerCase();
    final nextBool = next == valueOn;
    if (nextBool == boolValue) return;
    setState(() {
      boolValue = nextBool;
    });
  }

  @override
  bool checkRequired() {
    final input = readResolvedInput();
    if (input.isRequired && !boolValue) {
      setLocalValidationError();
      return false;
    }
    clearLocalValidationError();
    return true;
  }
}
