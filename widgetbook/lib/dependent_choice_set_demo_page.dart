// Host-driven dependent ChoiceSet demo (country → city cascade).
//
// Teams dependent inputs:
// https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/dynamic-search#dependent-inputs
//
// Reset semantics and host cascade patterns:
// ../../docs/form-inputs.md
// ignore_for_file: implementation_imports

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:format/format.dart';

/// Mock city lists keyed by country choice value.
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

/// Widgetbook page demonstrating country → city dependent Input.ChoiceSet fields.
///
/// Both use cases ("host cascade" and "Teams Data.Query") use this widget with
/// different [assetPath] values but the same [handleDependentChoiceSetChange]
/// handler.
///
/// Card JSON defines valueChangedAction reset on the country field. This page
/// supplies country-specific city choices via RawAdaptiveCardState.applyUpdates.
///
/// Phase 1 workaround: city choices are preloaded when country changes because
/// Data.Query associatedInputs is not yet implemented in the renderer. Filtered
/// city UI searches resolved overlay choices (not live bot invoke on each keystroke).
class DependentChoiceSetDemoPage extends StatelessWidget {
  const DependentChoiceSetDemoPage({
    super.key,
    required this.assetPath,
  });

  final String assetPath;

  /// Host onChange handler shared by Option 1 and Option 2 Widgetbook use cases.
  ///
  /// Option 1 (`value_changed_action_filtered.json`) and Option 2
  /// (`value_changed_action_dependent_query.json`) differ only in card JSON;
  /// this method implements both paths via two branches.
  static void handleDependentChoiceSetChange(
    String id,
    dynamic value,
    DataQuery? dataQuery,
    RawAdaptiveCardState cardState,
  ) {
    // Option 1 and Option 2: when country changes, repopulate city choices.
    // Runs after card valueChangedAction resets city value to baseline.
    // Option 1 shows compact dropdown updating (USA vs France cities).
    // Option 2 preloads overlay choices before the filtered city picker opens.
    // Defer until after valueChangedAction reset (runs after onChange in ChoiceSet).
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

    // Option 2 only: city has choices.data (dataset "cities"); onChange passes
    // a non-null DataQuery. Option 1 city is compact with no choices.data, so
    // dataQuery is null and this branch never runs.
    // Phase 1: log only — choices were already loaded in the country branch.
    // Phase 2: read dataQuery.parameters['country'] here instead of preloading.
    if (id == 'city' && dataQuery?.dataset == 'cities') {
      assert(() {
        developer.log(
          format(
            'city Data.Query onChange: value={}, dataset={}',
            value?.toString() ?? '',
            dataQuery?.dataset ?? '',
          ),
          name: 'DependentChoiceSetDemoPage',
        );
        return true;
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: AdaptiveCardsCanvas.asset(
          assetPath: assetPath,
          cardTypeRegistry: CardTypeRegistry(
            addedElements: CardChartsRegistry.additionalChartElements,
          ),
          onChange: handleDependentChoiceSetChange,
          hostConfigs: HostConfigs(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
