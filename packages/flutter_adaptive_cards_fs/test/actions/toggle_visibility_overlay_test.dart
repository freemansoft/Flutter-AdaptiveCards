import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Action.ToggleVisibility toggles visibility of target elements', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> cardMap = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'target1',
          'text': 'Target Element 1',
          'isVisible': true,
        },
        {
          'type': 'TextBlock',
          'id': 'target2',
          'text': 'Target Element 2',
          'isVisible': false,
        },
        {
          'type': 'TextBlock',
          'id': 'target3',
          'text': 'Target Element 3',
          'isVisible': true,
        },
      ],
      'actions': [
        {
          'type': 'Action.ToggleVisibility',
          'title': 'Toggle Elements',
          'targetElements': ['target1', 'target2'],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: cardMap,
        title: 'Action Toggle Visibility Test',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Target Element 1'), findsOneWidget);
    expect(find.text('Target Element 2'), findsNothing);
    expect(find.text('Target Element 3'), findsOneWidget);

    final toggleButtonFinder = find.widgetWithText(
      ElevatedButton,
      'Toggle Elements',
    );
    expect(toggleButtonFinder, findsOneWidget);

    await tester.tap(toggleButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Target Element 1'), findsNothing);
    expect(find.text('Target Element 2'), findsOneWidget);
    expect(find.text('Target Element 3'), findsOneWidget);

    await tester.tap(toggleButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Target Element 1'), findsOneWidget);
    expect(find.text('Target Element 2'), findsNothing);
    expect(find.text('Target Element 3'), findsOneWidget);
  });

  testWidgets(
    'Action.ToggleVisibility handles TargetElement objects with elementId',
    (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.4',
        'body': [
          {
            'type': 'TextBlock',
            'id': 'elem1',
            'text': 'Element 1',
            'isVisible': true,
          },
          {
            'type': 'TextBlock',
            'id': 'elem2',
            'text': 'Element 2',
            'isVisible': false,
          },
        ],
        'actions': [
          {
            'type': 'Action.ToggleVisibility',
            'title': 'Toggle',
            'targetElements': [
              {'elementId': 'elem1'},
              {'elementId': 'elem2'},
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Target Element Visibility Test',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Element 1'), findsOneWidget);
      expect(find.text('Element 2'), findsNothing);

      final toggleButtonFinder = find.widgetWithText(ElevatedButton, 'Toggle');
      expect(toggleButtonFinder, findsOneWidget);

      await tester.tap(toggleButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Element 1'), findsNothing);
      expect(find.text('Element 2'), findsOneWidget);
    },
  );
}
