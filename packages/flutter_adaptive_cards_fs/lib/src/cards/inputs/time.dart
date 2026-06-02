import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

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
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
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

  @override
  void resetInput() {
    super.resetInput();
    setState(() {
      selectedTime = value.isNotEmpty ? parseTime(value) : null;
    });
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
              // this should take into account minutes too
              if (result.hour < min.hour && result.hour > max.hour) {
                // can't count on context in async
                rawRootCardWidgetState.showError(
                  'Time ${result.hour} '
                  'must be after ${min.hour} and before ${max.hour} ',
                  // old code
                  //'must be after ${context.mounted ? min.format(rawRootCardWidgetState.context) : min.toString()}'
                  // old code
                  //' and before ${context.mounted ? max.format(rawRootCardWidgetState.context) : max.toString()}',
                );
              } else {
                setState(() {
                  selectedTime = result;
                });
                final value =
                    '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
                setDocumentInputValue(value);
                rawRootCardWidgetState.changeValue(id, value);
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
    map[id] = selectedTime == null
        ? null
        : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      setDocumentInputValue(map[id]);
    }
  }

  @override
  bool checkRequired() {
    return true;
  }

  @override
  void onDocumentValueChanged(Object? valueFromDocument) {
    final next = valueFromDocument?.toString();
    final parsed = parseTime(next);
    if (parsed?.hour == selectedTime?.hour &&
        parsed?.minute == selectedTime?.minute) {
      return;
    }
    selectedTime = parsed;
  }
}
