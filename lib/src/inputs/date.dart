///
/// https://adaptivecards.io/explorer/Input.Date.html
///
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../adaptive_card_element.dart';
import '../additional.dart';
import '../base.dart';
import '../utils.dart';

class AdaptiveDateInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveDateInput({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveDateInputState createState() => _AdaptiveDateInputState();
}

class _AdaptiveDateInputState extends State<AdaptiveDateInput>
    with AdaptiveTextualInputMixin, AdaptiveElementMixin, AdaptiveInputMixin {
  String? label;
  late bool isRequired;
  DateTime? selectedDateTime;
  DateTime? min;
  DateTime? max;
  final inputFormat = DateFormat('dd/MM/yyyy');
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    label = adaptiveMap['label'];
    isRequired = adaptiveMap['isRequired'] ?? false;
    try {
      selectedDateTime = inputFormat.parse(value);
      min = inputFormat.parse(adaptiveMap['min']);
      max = inputFormat.parse(adaptiveMap['max']);
    } catch (formatException) {}
  }

  @override
  Widget build(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    print(myLocale);

    return SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          loadLabel(label, isRequired),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextFormField(
              readOnly: true,
              style:
                  TextStyle(backgroundColor: Colors.white, color: Colors.black),
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0)),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(width: 1, color: Colors.red)),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(width: 1, color: Colors.redAccent)),
                filled: true,
                fillColor: Colors.white,
                hoverColor: Colors.white,
                suffixIcon:
                    Icon(Icons.calendar_today, size: 15, color: Colors.black54),
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.black54),
                errorStyle: TextStyle(height: 0),
              ),
              validator: (value) {
                if (!isRequired) return null;
                if (value == null || value.isEmpty) {
                  return '';
                }
                return null;
              },
              onTap: () async {
                await widgetState.pickDate(min, max, (DateTime? date) {
                  setState(() {
                    selectedDateTime = date;
                    controller.text = selectedDateTime == null
                        ? placeholder
                        : inputFormat.format(selectedDateTime!);
                  });
                });
              },
            ),
          )
        ]));
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
      try {
        setState(() {
          selectedDateTime = inputFormat.parse(map[id]);
          controller.text = selectedDateTime == null
              ? placeholder
              : inputFormat.format(selectedDateTime!);
        });
      } catch (formatException) {
        print(formatException);
      }
    }
  }

  @override
  bool checkRequired() {
    var adaptiveCardElement = context.read<AdaptiveCardElementState>();
    var formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }
}
