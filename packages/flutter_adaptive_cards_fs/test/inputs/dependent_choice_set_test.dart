import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/dependent_choice_set_handler.dart';
import '../utils/test_utils.dart';

Future<void> _selectFilteredCountry(
  WidgetTester tester,
  String choiceTitle,
) async {
  await tester.tap(find.byKey(generateWidgetKeyFromId('country')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('country_$choiceTitle')));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _selectFilteredCityByValue(
  WidgetTester tester,
  String choiceTitle,
) async {
  await tester.tap(find.byKey(generateWidgetKeyFromId('city')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('city_$choiceTitle')));
  await tester.pumpAndSettle();
}

Future<void> _selectCompactChoice(
  WidgetTester tester,
  String inputId,
  String choiceTitle,
) async {
  await tester.tap(find.byKey(generateWidgetKeyFromId(inputId)));
  await tester.pumpAndSettle();

  await tester.tap(find.text(choiceTitle).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'filtered country host cascade repopulates compact city choices',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromPath(
          path: 'value_changed_action_filtered.json',
          onChange: handleDependentChoiceSetChange,
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdaptiveChoiceSet).last),
      );
      var resolved = container.read(resolvedElementProvider('city'));
      expect(resolved?['choices'], [
        {'title': 'None Selected', 'value': ''},
        {'title': 'Paris', 'value': 'paris'},
        {'title': 'Lyon', 'value': 'lyon'},
      ]);

      await _selectFilteredCountry(tester, 'USA');
      await tester.pumpAndSettle();

      resolved = container.read(resolvedElementProvider('city'));
      expect(resolved?['choices'], [
        {'title': 'New York', 'value': 'nyc'},
        {'title': 'Los Angeles', 'value': 'la'},
      ]);

      await _selectCompactChoice(tester, 'city', 'New York');

      final cityState = tester.state<AdaptiveChoiceSetState>(
        find.byWidgetPredicate(
          (widget) => widget is AdaptiveChoiceSet && widget.id == 'city',
        ),
      );
      final submitted = <String, dynamic>{};
      cityState.appendInput(submitted);
      expect(submitted['city'], equals('nyc'));
    },
  );

  testWidgets(
    'dependent query sample preloads city choices and passes DataQuery on select',
    (WidgetTester tester) async {
      DataQuery? cityDataQuery;
      String? cityChangeId;

      await tester.pumpWidget(
        getTestWidgetFromPath(
          path: 'value_changed_action_dependent_query.json',
          onChange: (id, value, dataQuery, cardState) {
            handleDependentChoiceSetChange(id, value, dataQuery, cardState);
            if (id == 'city') {
              cityChangeId = id;
              cityDataQuery = dataQuery;
            }
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paris'), findsNothing);

      await _selectFilteredCountry(tester, 'France');
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdaptiveChoiceSet).last),
      );
      final resolved = container.read(resolvedElementProvider('city'));
      expect(resolved?['choices'], [
        {'title': 'Paris', 'value': 'paris'},
        {'title': 'Lyon', 'value': 'lyon'},
      ]);

      await _selectFilteredCityByValue(tester, 'Paris');
      await tester.pumpAndSettle();

      expect(cityChangeId, equals('city'));
      expect(cityDataQuery, isNotNull);
      expect(cityDataQuery!.dataset, equals('cities'));

      final cityState = tester.state<AdaptiveChoiceSetState>(
        find.byWidgetPredicate(
          (widget) => widget is AdaptiveChoiceSet && widget.id == 'city',
        ),
      );
      final submitted = <String, dynamic>{};
      cityState.appendInput(submitted);
      expect(submitted['city'], equals('paris'));
    },
  );

  testWidgets(
    'valueChangedAction resets city value when country changes before host cascade',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromPath(
          path: 'value_changed_action_filtered.json',
          onChange: handleDependentChoiceSetChange,
        ),
      );
      await tester.pumpAndSettle();

      await _selectCompactChoice(tester, 'city', 'Lyon');

      final cityState = tester.state<AdaptiveChoiceSetState>(
        find.byWidgetPredicate(
          (widget) => widget is AdaptiveChoiceSet && widget.id == 'city',
        ),
      );
      var submitted = <String, dynamic>{};
      cityState.appendInput(submitted);
      expect(submitted['city'], equals('lyon'));

      await _selectFilteredCountry(tester, 'France');
      await tester.pumpAndSettle();

      submitted = <String, dynamic>{};
      cityState.appendInput(submitted);
      expect(submitted['city'], isEmpty);
    },
  );
}
