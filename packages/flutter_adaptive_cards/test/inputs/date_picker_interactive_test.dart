import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  testWidgets('Date picker allows interactive date change', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Date',
          'id': 'pickDateInteractive',
          'label': 'Pick Date',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          initData: const {'pickDateInteractive': '2025-02-02'},
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Open the date picker
    await tester.tap(find.byKey(const ValueKey('pickDateInteractive')));
    await tester.pumpAndSettle();

    // Try tapping a different day in the calendar, e.g., '10'
    final dayFinder = find.text('10');
    expect(dayFinder, findsWidgets);
    await tester.tap(dayFinder.first);
    await tester.pumpAndSettle();

    // Confirm selection
    final okFinder = find.text('OK');
    expect(okFinder, findsWidgets);
    await tester.tap(okFinder.first);
    await tester.pumpAndSettle();

    // After confirming, the field should contain the new formatted date (same month/year)
    final TextFormField field = tester.widget(
      find.byKey(const ValueKey('pickDateInteractive')),
    );

    expect(field.controller!.text, equals('2025-02-10'));
  });
}
