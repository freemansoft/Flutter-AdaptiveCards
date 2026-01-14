import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// httfps://adaptivecards.io/explorer/Input.Text.html
///
class AdaptiveTextInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTextInput({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveTextInputState createState() => AdaptiveTextInputState();
}

class AdaptiveTextInputState extends State<AdaptiveTextInput>
    with AdaptiveTextualInputMixin, AdaptiveInputMixin, AdaptiveElementMixin {
  TextEditingController controller = TextEditingController();

  String? label;
  late bool isRequired;
  late bool isMultiline;
  late int maxLength;
  TextInputType? style;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    label = adaptiveMap['label'];
    isRequired = adaptiveMap['isRequired'] ?? false;
    isMultiline = adaptiveMap['isMultiline'] ?? false;
    maxLength = adaptiveMap['maxLength'] ?? 20;
    style = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveTextInputType(adaptiveMap['style']);
    controller.text = value;
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
              controller: controller,
              // maxLength: maxLength,
              inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
              keyboardType: style,
              maxLines: isMultiline ? null : 1,
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
      setState(() {
        controller.text = map[id];
      });
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
