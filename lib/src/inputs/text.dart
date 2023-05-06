import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';

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

  String? label;
  late bool isRequired;
  late bool isMultiline;
  late int maxLength;
  TextInputType? style;

  @override
  void initState() {
    super.initState();

    label = adaptiveMap['label'];
    isRequired = adaptiveMap['isRequired'] ?? false;
    isMultiline = adaptiveMap['isMultiline'] ?? false;
    maxLength = adaptiveMap['maxLength'];
    style = loadTextInputType();
    controller.text = value;
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          loadLabel(label, isRequired),
          SizedBox(
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
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0)),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
                hoverColor: Colors.white,
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.black54),
              ),
            ),
          )
        ]));
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
