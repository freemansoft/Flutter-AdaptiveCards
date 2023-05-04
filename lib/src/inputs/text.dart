import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../additional.dart';
import '../base.dart';

class AdaptiveTextInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTextInput({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveTextInputState createState() => _AdaptiveTextInputState();
}

class _AdaptiveTextInputState extends State<AdaptiveTextInput>
    with AdaptiveTextualInputMixin, AdaptiveInputMixin, AdaptiveElementMixin {
  TextEditingController controller = TextEditingController();
  late bool isMultiline;
  late int maxLength;
  late TextInputType? style;

  @override
  void initState() {
    super.initState();
    isMultiline = adaptiveMap['isMultiline'] ?? false;
    maxLength = adaptiveMap['maxLength'];
    style = loadTextInputType();
    controller.text = value;
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: SizedBox(
          height: 40,
          child: TextField(
            style:
                TextStyle(backgroundColor: Colors.white, color: Colors.black),
            controller: controller,
            // maxLength: maxLength,
            inputFormatters: [
              LengthLimitingTextInputFormatter(maxLength),
            ],
            keyboardType: style,
            maxLines: isMultiline ? null : 1,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              enabledBorder: const OutlineInputBorder(
                // width: 0.0 produces a thin "hairline" border
                borderSide: const BorderSide(color: Colors.grey, width: 0.0),
              ),
              filled: true,
              fillColor: Colors.white,
              hoverColor: Colors.white,
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.black54),
            ),
          ),
        ));
  }

  @override
  void appendInput(Map map) {
    map[id] = controller.text;
  }

  TextInputType? loadTextInputType() {
    /// Can be one of the following:
    /// - 'text'
    /// - 'tel'
    /// - 'url'
    /// - 'email'
    String style = adaptiveMap['style'] ?? 'text';
    switch (style) {
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
