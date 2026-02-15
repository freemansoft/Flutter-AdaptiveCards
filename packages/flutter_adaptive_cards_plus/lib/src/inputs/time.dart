import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/additional.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Input.Time.html
///
class AdaptiveTimeInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTimeInput({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveTimeInputState createState() => AdaptiveTimeInputState();
}

class AdaptiveTimeInputState extends State<AdaptiveTimeInput>
    with
        AdaptiveTextualInputMixin,
        AdaptiveElementMixin,
        AdaptiveInputMixin,
        AdaptiveVisibilityMixin {
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
    final List<String> times = time.split(':');
    assert(times.length == 2, 'Invalid TimeOfDay format');
    return TimeOfDay(hour: int.parse(times[0]), minute: int.parse(times[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: ElevatedButton(
          key: generateWidgetKey(adaptiveMap),
          onPressed: () async {
            final TimeOfDay? result = await rawRootCardWidgetState
                .timePickerForPlatform(
                  context,
                  selectedTime,
                  min,
                  max,
                );
            if (result != null) {
              if (result.hour >= min.hour && result.hour <= max.hour) {
                // can't count on context in async
                rawRootCardWidgetState.showError(
                  // old code
                  // ignore: use_build_context_synchronously
                  'Time must be after ${context.mounted ? min.format(rawRootCardWidgetState.context) : min.toString()}'
                  // old code
                  // ignore: use_build_context_synchronously
                  ' and before ${context.mounted ? max.format(rawRootCardWidgetState.context) : max.toString()}',
                );
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
          child: Text(
            selectedTime == null
                ? placeholder
                : selectedTime!.format(rawRootCardWidgetState.context),
          ),
        ),
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
