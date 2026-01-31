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

  testWidgets('Tapping DateInput opens picker and selecting OK sets value', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Date',
          'id': 'pickDate',
          'label': 'Pick Date',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          initData: const {'pickDate': '2025-02-02'},
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Tap the date field to open the picker
    await tester.tap(find.byKey(const ValueKey('pickDate')));
    await tester.pumpAndSettle();

    // Confirm by tapping OK in the dialog
    final okFinder = find.text('OK');
    expect(okFinder, findsWidgets);
    await tester.tap(okFinder.first);
    await tester.pumpAndSettle();

    // After confirming, the field should contain the formatted date
    final TextFormField field = tester.widget(
      find.byKey(const ValueKey('pickDate')),
    );
    expect(field.controller!.text, equals('2025-02-02'));
  });
}
