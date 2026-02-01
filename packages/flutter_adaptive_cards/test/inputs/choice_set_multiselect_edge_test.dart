import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_set.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('ChoiceSet multi-select appendInput contains multiple values', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'multiChoice',
          'style': 'expanded',
          'isMultiSelect': true,
          'choices': [
            {'title': 'Choice 1', 'value': '1'},
            {'title': 'Choice 2', 'value': '2'},
            {'title': 'Choice 3', 'value': '3'},
          ],
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Tap Choice 1 and Choice 2
    await tester.tap(find.byKey(const ValueKey('multiChoice_Choice 1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('multiChoice_Choice 2')));
    await tester.pumpAndSettle();

    final dynamic state = tester.state(find.byType(AdaptiveChoiceSet));
    final Map<String, dynamic> out = {};
    state.appendInput(out);

    final String csv = out['multiChoice'] as String;
    final parts = csv.split(',');

    // Expect two values and both '1' and '2' present
    expect(parts.length, equals(2));
    expect(parts, contains('1'));
    expect(parts, contains('2'));

    // Tapping Choice 1 again should remove it
    await tester.tap(find.byKey(const ValueKey('multiChoice_Choice 1')));
    await tester.pumpAndSettle();
    final Map<String, dynamic> out2 = {};
    state.appendInput(out2);
    final parts2 = out2['multiChoice'].toString().split(',');
    expect(parts2.length, equals(1));
    expect(parts2, contains('2'));
  });
}
