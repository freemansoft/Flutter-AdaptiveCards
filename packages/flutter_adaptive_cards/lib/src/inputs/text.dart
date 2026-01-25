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
/// httfps://adaptivecards.io/explorer/Input.Text.html
///
class AdaptiveTextInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTextInput({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
  });

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

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
    label = adaptiveMap['label']?.toString();
    isRequired = adaptiveMap['isRequired'] as bool? ?? false;
    isMultiline = adaptiveMap['isMultiline'] as bool? ?? false;
    maxLength = adaptiveMap['maxLength'] as int? ?? 20;
    style = resolveTextInputType(adaptiveMap['style']);
    controller.text = value;
    stateHasError = false;
  }

  bool stateHasError = false;

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      widgetState: widgetState,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          loadLabel(context: context, label: label, isRequired: isRequired),
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
      setState(() {
        controller.text = map[id] as String;
      });
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

  /// JSON Schema definition "TextInputStyle"
  TextInputType? resolveTextInputType(String? style) {
    /// Can be one of the following:
    /// - 'text'
    /// - 'tel'
    /// - 'url'
    /// - 'email'
    final String myStyle = (style != null) ? style.toLowerCase() : 'text';
    switch (myStyle) {
      case 'text':
        return TextInputType.text;
      case 'tel':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return null;
    }
  }
}
