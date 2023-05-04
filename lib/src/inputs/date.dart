import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../additional.dart';
import '../base.dart';

class AdaptiveDateInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveDateInput({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveDateInputState createState() => _AdaptiveDateInputState();
}

class _AdaptiveDateInputState extends State<AdaptiveDateInput>
    with AdaptiveTextualInputMixin, AdaptiveElementMixin, AdaptiveInputMixin {
  DateTime? selectedDateTime;
  DateTime? min;
  DateTime? max;
  final inputFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();

    try {
      selectedDateTime = DateTime.parse(value);
      min = DateTime.parse(adaptiveMap['min']);
      max = DateTime.parse(adaptiveMap['max']);
    } catch (formatException) {}
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black, // textColor
            ),
            onPressed: () async {
              await widgetState.pickDate(min, max, (DateTime? date) {
                setState(() {
                  selectedDateTime = date;
                });
              });
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(selectedDateTime == null
                  ? placeholder
                  : inputFormat.format(selectedDateTime!)),
            ),
          ),
        ));
  }

  @override
  void appendInput(Map map) {
    if (selectedDateTime != null) {
      map[id] = selectedDateTime!.toIso8601String();
    }
  }
}
