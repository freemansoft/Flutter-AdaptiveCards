import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/toggle.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('Toggle renders with label and correct key', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Toggle',
          'id': 'myToggle',
          'title': 'Enable feature',
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Toggle Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final toggleMap = map['body'][0] as Map<String, dynamic>;
    expect(find.text('Enable feature'), findsOneWidget);
    expect(find.byKey(generateWidgetKey(toggleMap)), findsOneWidget);
    final Switch sw = tester.widget(find.byKey(generateWidgetKey(toggleMap)));
    expect(sw.value, isFalse);
  });

  testWidgets('Toggle initData and appendInput behave correctly', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Toggle',
          'id': 'initToggle',
          'title': 'Init Toggle',
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Toggle initData Test',
      initData: const {'initToggle': true},
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final toggleMap = map['body'][0] as Map<String, dynamic>;
    final Switch sw = tester.widget(find.byKey(generateWidgetKey(toggleMap)));
    expect(sw.value, isTrue);

    // Toggle it off
    await tester.tap(find.byKey(generateWidgetKey(toggleMap)));
    await tester.pumpAndSettle();

    final dynamic state = tester.state(find.byType(AdaptiveToggle));
    final Map<String, dynamic> out = {};
    state.appendInput(out);
    expect(out['initToggle'], 'false');
  });
}
