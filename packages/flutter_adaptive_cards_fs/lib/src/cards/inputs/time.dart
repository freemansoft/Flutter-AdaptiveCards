import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.Time.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/input-time
///
class AdaptiveTimeInput extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a time input from [adaptiveMap] JSON.
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

/// State for [AdaptiveTimeInput]; opens a platform time picker on tap.
class AdaptiveTimeInputState extends ConsumerState<AdaptiveTimeInput>
    with
        AdaptiveTextualInputMixin,
        AdaptiveElementMixin,
        AdaptiveInputMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  /// Currently selected time, or null when cleared.
  TimeOfDay? selectedTime;

  /// Minimum allowed time from `min` (`HH:mm`).
  late TimeOfDay min;

  /// Maximum allowed time from `max` (`HH:mm`).
  late TimeOfDay max;
  bool _initialValueSynced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    min = parseTime(adaptiveMap['min']) ?? const TimeOfDay(minute: 0, hour: 0);
    max =
        parseTime(adaptiveMap['max']) ?? const TimeOfDay(minute: 59, hour: 23);

    if (!_initialValueSynced) {
      _initialValueSynced = true;
      selectedTime =
          parseTime(readResolvedInput().valueAsString) ?? TimeOfDay.now();
    }
  }

  @override
  void resetInput() {
    super.resetInput();
    setState(() {});
  }

  /// Parses an Adaptive Cards time string (`HH:mm`) into [TimeOfDay].
  TimeOfDay? parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final List<String> times = time.split(':');
    assert(times.length == 2, 'Invalid TimeOfDay format');
    return TimeOfDay(hour: int.parse(times[0]), minute: int.parse(times[1]));
  }

  @override
  Widget build(BuildContext context) {
    listenForResolvedValueChanges();
    final input = watchResolvedInput();

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: loadLabel(
                context: context,
                label: input.label,
                isRequired: input.isRequired,
              ),
            ),
            labelInputSemantics(
              label: input.label,
              isRequired: input.isRequired,
              field: ElevatedButton(
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
                      );
                    } else {
                      setState(() {
                        selectedTime = result;
                      });
                      final hh = result.hour.toString().padLeft(2, '0');
                      final mm = result.minute.toString().padLeft(2, '0');
                      final value = '$hh:$mm';
                      setDocumentInputValue(value);
                      rawRootCardWidgetState.changeValue(id, value);
                      notifyUserInputValueChanged(value, committed: true);
                    }
                  } else {
                    setState(() {
                      selectedTime = result;
                    });
                  }
                },
                child: Text(
                  selectedTime == null
                      ? input.placeholder
                      : selectedTime!.format(rawRootCardWidgetState.context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    final time = selectedTime;
    if (time == null) {
      map[id] = null;
    } else {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      map[id] = '$hh:$mm';
    }
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
    setState(() {
      selectedTime = parsed;
    });
  }
}
