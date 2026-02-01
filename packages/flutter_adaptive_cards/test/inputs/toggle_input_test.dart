import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inputs/toggle.dart';
import 'package:flutter_test/flutter_test.dart';

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

    expect(find.text('Enable feature'), findsOneWidget);
    expect(find.byKey(const ValueKey('myToggle')), findsOneWidget);
    final Switch sw = tester.widget(find.byKey(const ValueKey('myToggle')));
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

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          initData: const {'initToggle': true},
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final Switch sw = tester.widget(find.byKey(const ValueKey('initToggle')));
    expect(sw.value, isTrue);

    // Toggle it off
    await tester.tap(find.byKey(const ValueKey('initToggle')));
    await tester.pumpAndSettle();

    final dynamic state = tester.state(find.byType(AdaptiveToggle));
    final Map<String, dynamic> out = {};
    state.appendInput(out);
    expect(out['initToggle'], 'false');
  });
}
