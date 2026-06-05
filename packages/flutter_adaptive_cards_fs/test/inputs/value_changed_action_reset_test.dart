import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'valueChangedAction resets dependent ChoiceSet on country change',
    (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        getTestWidgetFromPath(path: 'value_changed_action_reset_test.json'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paris'), findsOneWidget);

      await tester.tap(find.text('Lyon'));
      await tester.pumpAndSettle();

      final cityState = tester.state<AdaptiveChoiceSetState>(
        find.byWidgetPredicate(
          (widget) => widget is AdaptiveChoiceSet && widget.id == 'city',
        ),
      );
      final Map<String, dynamic> selectedCity = {};
      cityState.appendInput(selectedCity);
      expect(selectedCity['city'], equals('lyon'));

      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();

      final Map<String, dynamic> resetCity = {};
      cityState.appendInput(resetCity);
      expect(resetCity['city'], equals('paris'));

      expect(find.text('Paris'), findsOneWidget);
    },
  );

  testWidgets(
    'valueChangedAction on Text fires on unfocus not each keystroke',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: {
            'type': 'AdaptiveCard',
            'version': '1.6',
            'body': [
              {
                'type': 'Input.Text',
                'id': 'source',
                'label': 'Source',
                'valueChangedAction': {
                  'type': 'Action.ResetInputs',
                  'targetInputIds': ['target'],
                },
              },
              {
                'type': 'Input.Text',
                'id': 'target',
                'label': 'Target',
                'value': 'initial',
              },
            ],
          },
          title: 'valueChangedAction text',
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(generateWidgetKeyFromId('target')),
        'dirty',
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(generateWidgetKeyFromId('source')),
        'abc',
      );
      await tester.pump();

      expect(
        tester
            .widget<TextFormField>(
              find.byKey(generateWidgetKeyFromId('target')),
            )
            .controller!
            .text,
        equals('dirty'),
      );

      await tester.tap(find.byKey(generateWidgetKeyFromId('target')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextFormField>(
              find.byKey(generateWidgetKeyFromId('target')),
            )
            .controller!
            .text,
        equals('initial'),
      );
    },
  );
}
