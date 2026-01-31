import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inputs/time.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  testWidgets(
    'Tapping TimeInput opens picker and confirming OK preserves time',
    (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Time',
            'id': 'pickTime',
          },
        ],
      };

      final Widget widget = MaterialApp(
        home: Scaffold(
          body: RawAdaptiveCard.fromMap(
            map: map,
            initData: const {'pickTime': '12:30'},
            hostConfig: HostConfig(),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Tap the time button to open the picker
      await tester.tap(find.byKey(const ValueKey('pickTime')));
      await tester.pumpAndSettle();

      // Confirm by tapping OK in the dialog
      final okFinder = find.text('OK');
      expect(okFinder, findsWidgets);
      await tester.tap(okFinder.first);
      await tester.pumpAndSettle();

      // Append input to verify the value returned contains the expected time
      final dynamic state = tester.state(find.byType(AdaptiveTimeInput));
      final Map<String, dynamic> out = {};
      state.appendInput(out);
      expect(out['pickTime'].toString().contains('12:30'), isTrue);
    },
  );
}
