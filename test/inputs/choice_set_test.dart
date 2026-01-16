import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AdaptiveChoiceSet expanded single select (Radio buttons)', (
    WidgetTester tester,
  ) async {
    String? selectedValue;

    Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          // TODO: Replace with test/samples/choice_set_radio.json file
          {
            'type': 'AdaptiveCard',
            'version': '1.2',
            'body': [
              {
                'type': 'Input.ChoiceSet',
                'id': 'myChoiceSet',
                'style': 'expanded',
                'isMultiSelect': false,
                'choices': [
                  {'title': 'Choice 1', 'value': '1'},
                  {'title': 'Choice 2', 'value': '2'},
                ],
              },
            ],
          },
          onChange: (id, value, state) {
            if (id == 'myChoiceSet') {
              selectedValue = value;
            }
          },
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Find the RadioListTiles
    final choice1Finder = find.widgetWithText(
      RadioListTile<String>,
      'Choice 1',
    );
    final choice2Finder = find.widgetWithText(
      RadioListTile<String>,
      'Choice 2',
    );

    expect(choice1Finder, findsOneWidget);
    expect(choice2Finder, findsOneWidget);

    // Initial state: nothing selected

    // Tap Choice 2
    await tester.tap(choice2Finder);
    await tester.pump();

    // Verify onChange was called with '2'
    expect(selectedValue, equals('2'));

    // Tap Choice 1
    await tester.tap(choice1Finder);
    await tester.pump();

    // Verify onChange was called with '1'
    expect(selectedValue, equals('1'));
  });
}
