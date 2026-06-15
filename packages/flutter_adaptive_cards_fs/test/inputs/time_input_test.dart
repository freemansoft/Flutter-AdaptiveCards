import 'package:flutter/material.dart';
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
}
