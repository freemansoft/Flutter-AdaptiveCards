import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inputs/date.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  testWidgets('DateInput renders with correct key and label', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Date',
          'id': 'myDate',
          'label': 'Choose date',
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

    expect(find.text('Choose date'), findsOneWidget);
    expect(find.byKey(const ValueKey('myDate')), findsOneWidget);
  });

  testWidgets('DateInput initData and appendInput work', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Date',
          'id': 'initDate',
          'label': 'Init Date',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          initData: const {'initDate': '2024-01-02'},
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final TextFormField field = tester.widget(
      find.byKey(const ValueKey('initDate')),
    );

    // Controller should be formatted as yyyy-MM-dd
    expect(field.controller!.text, equals('2024-01-02'));

    final dynamic state = tester.state(find.byType(AdaptiveDateInput));
    final Map<String, dynamic> out = {};
    state.appendInput(out);
    expect((out['initDate'] as String).startsWith('2024-01-02'), isTrue);
  });
}
