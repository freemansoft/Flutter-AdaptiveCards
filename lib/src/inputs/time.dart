import 'package:flutter/material.dart';

import '../adaptive_mixins.dart';
import '../additional.dart';

///
/// https://adaptivecards.io/explorer/Input.Time.html
///
class AdaptiveTimeInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTimeInput({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveTimeInputState createState() => AdaptiveTimeInputState();
}

class AdaptiveTimeInputState extends State<AdaptiveTimeInput>
    with AdaptiveTextualInputMixin, AdaptiveElementMixin, AdaptiveInputMixin {
  late TimeOfDay? selectedTime;
  late TimeOfDay min;
  late TimeOfDay max;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selectedTime = parseTime(value) ?? TimeOfDay.now();
    min = parseTime(adaptiveMap['min']) ?? const TimeOfDay(minute: 0, hour: 0);
    max =
        parseTime(adaptiveMap['max']) ?? const TimeOfDay(minute: 59, hour: 23);
  }

  TimeOfDay? parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    List<String> times = time.split(':');
    assert(times.length == 2, 'Invalid TimeOfDay format');
    return TimeOfDay(
      hour: int.parse(times[0]),
      minute: int.parse(times[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: ElevatedButton(
        onPressed: () async {
          TimeOfDay? result = await widgetState.timePickerForPlatform(
              context, selectedTime, min, max);
          if (result != null) {
            if (result.hour >= min.hour && result.hour <= max.hour) {
              // can't count on context in async
              widgetState.showError(
                  'Time must be after ${context.mounted ? min.format(widgetState.context) : min.toString()}'
                  ' and before ${context.mounted ? max.format(widgetState.context) : max.toString()}');
            } else {
              setState(() {
                selectedTime = result;
              });
            }
          } else {
            setState(() {
              selectedTime = result;
            });
          }
        },
        child: Text(selectedTime == null
            ? placeholder
            : selectedTime!.format(widgetState.context)),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = selectedTime.toString();
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      selectedTime = parseTime(map[id]);
    }
  }

  @override
  bool checkRequired() {
    return true;
  }
}
