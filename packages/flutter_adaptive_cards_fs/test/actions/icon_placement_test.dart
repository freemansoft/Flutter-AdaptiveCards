import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('action with icon stacks icon above label (default aboveTitle)', (
    WidgetTester tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.Submit',
          'title': 'Go',
          'iconUrl': 'https://example.com/i.png',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'icon above'),
    );
    await tester.pump();

    // aboveTitle builds a plain ElevatedButton whose child is a Column
    // (icon over label), rather than ElevatedButton.icon (a Row).
    final buttonColumn = find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.byType(Column),
    );
    expect(buttonColumn, findsOneWidget);
    expect(find.text('Go'), findsOneWidget);
  });
}
