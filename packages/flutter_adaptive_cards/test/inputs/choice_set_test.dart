import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AdaptiveChoiceSet expanded single select (Radio buttons)', (
    WidgetTester tester,
  ) async {
    String? selectedValue;

    final File file = File('test/samples/choice_set_radio.json');
    final Map<String, dynamic> map =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          hostConfig: HostConfig(),
          onChange: (id, value, state) {
            if (id == 'myChoiceSet') {
              selectedValue = value as String?;
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
