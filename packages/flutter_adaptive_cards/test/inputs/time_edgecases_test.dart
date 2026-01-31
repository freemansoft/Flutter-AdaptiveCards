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

  testWidgets('TimeInput parseTime handles valid and invalid values', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Time',
          'id': 'someTime',
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

    final state = tester.state<AdaptiveTimeInputState>(
      find.byType(AdaptiveTimeInput),
    );

    // Valid parse
    final TimeOfDay? parsed = state.parseTime('12:30');
    expect(parsed, isNotNull);
    expect(parsed!.hour, equals(12));
    expect(parsed.minute, equals(30));

    // Null or empty returns null
    expect(state.parseTime(null), isNull);
    expect(state.parseTime(''), isNull);
  });

  testWidgets('TimeInput appendInput returns string representation', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Time',
          'id': 'initTime',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          initData: const {'initTime': '09:45'},
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final dynamic state = tester.state(find.byType(AdaptiveTimeInput));

    // Ensure appendInput includes the time string (format preserved)
    final Map<String, dynamic> out = {};
    state.appendInput(out);

    expect(out['initTime'].toString().contains('09:45'), isTrue);
  });
}
