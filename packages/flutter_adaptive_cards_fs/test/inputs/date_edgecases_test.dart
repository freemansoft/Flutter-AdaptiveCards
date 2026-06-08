import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/date.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('DateInput handles invalid initData format gracefully', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Date',
          'id': 'badDate',
          'label': 'Bad Date',
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Date Edge Cases Test',
      initData: const {'badDate': 'not-a-date'},
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Should not throw and controller should be empty (init failed quietly)
    final dateMap = map['body'][0] as Map<String, dynamic>;
    final TextFormField field = tester.widget(
      find.byKey(generateWidgetKey(dateMap)),
    );

    expect(field.controller!.text, equals(''));
  });

  testWidgets(
    'DateInput empty state keeps controller empty (placeholder via hintText)',
    (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Date',
            'id': 'emptyDate',
            'label': 'Date',
            'placeholder': 'Pick a date',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'Date empty controller'),
      );
      await tester.pumpAndSettle();

      final dateMap = map['body'][0] as Map<String, dynamic>;
      final field = tester.widget<TextFormField>(
        find.byKey(generateWidgetKey(dateMap)),
      );

      expect(field.controller!.text, isEmpty);

      final inputDecorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(generateWidgetKey(dateMap)),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(inputDecorator.decoration.hintText, 'Pick a date');

      final state = tester.state<AdaptiveDateInputState>(
        find.byType(AdaptiveDateInput),
      );
      expect(state.selectedDateTime, isNull);

      final out = <String, dynamic>{};
      state.appendInput(out);
      expect(out.containsKey('emptyDate'), isFalse);
    },
  );

  testWidgets(
    'DateInput required validation fails when only placeholder would show',
    (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Date',
            'id': 'reqDate',
            'label': 'Required Date',
            'isRequired': true,
            'placeholder': 'Pick a date',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'Date required validation'),
      );
      await tester.pumpAndSettle();

      final state = tester.state<AdaptiveDateInputState>(
        find.byType(AdaptiveDateInput),
      );
      expect(state.checkRequired(), isFalse);
    },
  );

  testWidgets(
    'DateInput appendInput returns yyyy-MM-dd when a date is selected',
    (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Date',
            'id': 'initDate',
          },
        ],
      };

      final Widget widget = getTestWidgetFromMap(
        map: map,
        title: 'Date Edge Cases appendInput Test',
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(AdaptiveDateInput));
      final Map<String, dynamic> out = {};

      state
        ..selectedDateTime = DateTime.parse('2025-01-15')
        ..appendInput(out);

      expect(out['initDate'], '2025-01-15');
    },
  );
}
