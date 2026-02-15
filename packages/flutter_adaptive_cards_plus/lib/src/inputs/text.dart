import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/additional.dart';
import 'package:flutter_adaptive_cards_plus/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// httfps://adaptivecards.io/explorer/Input.Text.html
///
class AdaptiveTextInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTextInput({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveTextInputState createState() => AdaptiveTextInputState();
}

class AdaptiveTextInputState extends State<AdaptiveTextInput>
    with
        AdaptiveTextualInputMixin,
        AdaptiveInputMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin {
  TextEditingController controller = TextEditingController();

  String? label;
  late bool isRequired;
  late bool isMultiline;
  late int maxLength;
  TextInputType? inputStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    label = adaptiveMap['label']?.toString();
    isRequired = adaptiveMap['isRequired'] as bool? ?? false;
    isMultiline = adaptiveMap['isMultiline'] as bool? ?? false;
    maxLength = adaptiveMap['maxLength'] as int? ?? 20;
    inputStyle = resolveTextInputType(style);
    controller.text = value;
    stateHasError = false;
  }

  bool stateHasError = false;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            loadLabel(context: context, label: label, isRequired: isRequired),
            SizedBox(
              height: 40,
              child: TextFormField(
                key: generateWidgetKey(adaptiveMap),
                style: const TextStyle(),
                controller: controller,
                // maxLength: maxLength,
                inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
                keyboardType: inputStyle,
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
                  fillColor: ProviderScope.containerOf(context)
                      .read(styleReferenceResolverProvider)
                      .resolveInputBackgroundColor(
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
    final adaptiveCardElement = adaptiveCardElementState;
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
