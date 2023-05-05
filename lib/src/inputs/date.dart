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
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black, // textColor
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: Colors.grey, width: 0.0, style: BorderStyle.solid),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
              ),
            ),
            onPressed: () async {
              await widgetState.pickDate(min, max, (DateTime? date) {
                setState(() {
                  selectedDateTime = date;
                });
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(selectedDateTime == null
                      ? placeholder
                      : inputFormat.format(selectedDateTime!)),
                ),
                Icon(Icons.calendar_today, size: 15)
              ],
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

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      try {
        selectedDateTime = DateTime.parse(map[id]);
      } catch (formatException) {}
    }
  }
}
