import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/time.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('TimeInput renders with correct key', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Time',
          'id': 'myTime',
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Time Input Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final timeMap = map['body'][0] as Map<String, dynamic>;
    expect(find.byKey(generateWidgetKey(timeMap)), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('TimeInput initData and appendInput work', (
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

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Time Input initData Test',
      initData: const {'initTime': '12:30'},
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final dynamic state = tester.state(find.byType(AdaptiveTimeInput));
    final Map<String, dynamic> out = {};
    state.appendInput(out);
    expect((out['initTime'] as String).contains('12:30'), isTrue);
  });
}
