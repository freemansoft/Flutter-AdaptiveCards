import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';

/// Mock city lists keyed by country choice value (Teams dependent-input demo data).
const citiesByCountry = <String, List<Choice>>{
  'usa': [
    Choice(title: 'New York', value: 'nyc'),
    Choice(title: 'Los Angeles', value: 'la'),
  ],
  'france': [
    Choice(title: 'Paris', value: 'paris'),
    Choice(title: 'Lyon', value: 'lyon'),
  ],
  'india': [
    Choice(title: 'Mumbai', value: 'mumbai'),
    Choice(title: 'Delhi', value: 'delhi'),
  ],
};

/// Resolves country codes from onChange values (all ChoiceSet styles pass `value`).
String? countryCodeFromOnChangeValue(Object? value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return null;
  if (citiesByCountry.containsKey(raw)) return raw;
  final lower = raw.toLowerCase();
  if (citiesByCountry.containsKey(lower)) return lower;
  for (final entry in citiesByCountry.entries) {
    for (final choice in entry.value) {
      if (choice.title == raw) return entry.key;
    }
  }
  return null;
}

/// Host onChange handler for country → city dependent ChoiceSet samples.
///
/// City choice updates are scheduled for the next frame so they run after embedded
/// `valueChangedAction` reset on the country field (reset runs after the host
/// `onChange` callback in the input notification path).
void handleDependentChoiceSetChange(
  String id,
  dynamic value,
  DataQuery? dataQuery,
  RawAdaptiveCardState cardState,
) {
  if (id == 'country') {
    final countryCode = countryCodeFromOnChangeValue(value);
    final choices = countryCode == null
        ? const <Choice>[]
        : citiesByCountry[countryCode] ?? const <Choice>[];
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!cardState.mounted) {
        return;
      }
      cardState.applyUpdates(
        elements: [
          AdaptiveElementUpdate(
            id: 'city',
            choices: choices,
            clearValue: true,
            clearError: true,
          ),
        ],
      );
    });
    return;
  }

  if (id == 'city' && dataQuery?.dataset == 'cities') {
    // Phase 1: choices preloaded on country change; city branch observable in tests.
  }
}
