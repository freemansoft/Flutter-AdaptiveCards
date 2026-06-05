import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.Toggle.html
///
class AdaptiveToggle extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
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

class AdaptiveToggleState extends ConsumerState<AdaptiveToggle>
    with
        AdaptiveInputMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  bool boolValue = false;

  late String valueOff;
  late String valueOn;

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

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
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
              child: Text(title),
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
    return true;
  }
}
