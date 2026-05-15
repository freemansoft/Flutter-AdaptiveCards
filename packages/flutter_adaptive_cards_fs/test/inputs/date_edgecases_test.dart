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
    'DateInput appendInput returns ISO8601 string when a date is selected',
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

      // Set a selectedDateTime and ensure appendInput uses ISO8601
      state
        ..selectedDateTime = DateTime.parse('2025-01-15')
        ..appendInput(out);

      expect(out['initDate'].toString().startsWith('2025-01-15'), isTrue);
    },
  );
}
