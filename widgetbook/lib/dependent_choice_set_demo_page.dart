// Host-driven dependent ChoiceSet demo (country → city cascade).
//
// Teams dependent inputs:
// https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/dynamic-search#dependent-inputs
//
// Reset semantics and host cascade patterns:
// ../../docs/form-inputs.md

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:format/format.dart';

import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

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

/// Resolves country codes from onChange (all ChoiceSet styles pass `value`).
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

/// Widgetbook demonstrating country → city dependent Input.ChoiceSet fields.
///
/// Both use cases ("host cascade" and "Teams Data.Query") use this widget with
/// different [assetPath] values but the same [handleDependentChoiceSetChange]
/// handler.
///
/// Card JSON defines valueChangedAction reset on the country field. This page
/// supplies country-specific choices via RawAdaptiveCardState.applyUpdates.
///
/// Phase 1: associatedInputs merges sibling input values into Data.Query
/// parameters on city onChange. Country change preloads city choices; the city
/// branch can also resolve choices from dataQuery.parameters['country'].
class DependentChoiceSetDemoPage extends StatelessWidget {
  const DependentChoiceSetDemoPage({
    super.key,
    required this.assetPath,
  });

  final String assetPath;

  /// `onChange` handler shared by Option 1 and Option 2 Widgetbook use cases.
  ///
  /// Option 1 (`value_changed_action_filtered.json`) and
  /// Option 2 (`value_changed_action_dependent_query.json`)
  /// differ only in card JSON;
  /// this method implements both paths via two branches.
  ///
  /// Option 1 = host-driven cascade with a compact city dropdown;
  /// Option 2 = cascade plus Teams-style filtered city backed by choices.data.
  /// The handler’s country branch serves both;
  /// the city/Data.Query branch is Option 2 only.
  static void handleDependentChoiceSetChange(InputChangeInvoke invoke) {
    // Option 1 and Option 2: when country changes, repopulate city choices.
    // Runs after card valueChangedAction resets city value to baseline.
    //
    // Option 1 shows compact dropdown updating (USA vs France cities).
    //
    // Option 2 preloads overlay choices before the filtered city picker opens.
    // Defer until after valueChangedAction reset (after onChange in ChoiceSet).
    if (invoke.inputId == 'country') {
      final countryCode = countryCodeFromOnChangeValue(invoke.value);
      final choices = countryCode == null
          ? const <Choice>[]
          : citiesByCountry[countryCode] ?? const <Choice>[];
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!invoke.cardState.mounted) {
          return;
        }
        // We are applying changes to the city input overlay
        invoke.cardState.applyUpdates(
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
    // a non-null DataQuery with associatedInputs sibling values in parameters.
    //
    // Option 1 city is compact with no choices.data, so
    // dataQuery is null and this branch never runs.
    if (invoke.inputId == 'city' && invoke.dataQuery?.dataset == 'cities') {
      final countryCode = invoke.dataQuery?.parameters?['country']?.toString();
      final choices = countryCode == null
          ? const <Choice>[]
          : citiesByCountry[countryCode] ?? const <Choice>[];
      assert(() {
        developer.log(
          format(
            'city Data.Query onChange: value={}, dataset={}, country={}',
            invoke.value?.toString() ?? '',
            invoke.dataQuery?.dataset ?? '',
            countryCode ?? '',
          ),
          name: 'DependentChoiceSetDemoPage',
        );
        return true;
      }());
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!invoke.cardState.mounted) {
          return;
        }
        // Re-apply the resolved Data.Query choices, but preserve the value the
        // user just selected. Passing [value] keeps the selection: applying
        // `choices` without `value` would clear the input (the notifier treats
        // "new choices, no value" as a stale-value reset), wiping the pick.
        invoke.cardState.applyUpdates(
          elements: [
            AdaptiveElementUpdate(
              id: 'city',
              choices: choices,
              value: invoke.value,
            ),
          ],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: AdaptiveCardsCanvas.asset(
          assetPath: assetPath,
          cardTypeRegistry: widgetbookCardTypeRegistry,
          onChange: handleDependentChoiceSetChange,
          hostConfigs: HostConfigs(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
