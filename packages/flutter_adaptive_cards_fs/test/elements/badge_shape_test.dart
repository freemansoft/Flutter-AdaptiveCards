import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

BoxDecoration _badgeDecoration(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).borderRadius != null,
      );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('square shape uses a small corner radius', (tester) async {
    final card = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[
        {'type': 'Badge', 'text': 'New', 'shape': 'square'},
      ],
    };
    await tester.pumpWidget(getTestWidgetFromMap(map: card, title: 'sq'));
    await tester.pump();

    expect(_badgeDecoration(tester).borderRadius, BorderRadius.circular(2));
  });

  testWidgets('default (no shape) keeps the pill radius', (tester) async {
    final card = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[
        {'type': 'Badge', 'text': 'New'},
      ],
    };
    await tester.pumpWidget(getTestWidgetFromMap(map: card, title: 'pill'));
    await tester.pump();

    expect(_badgeDecoration(tester).borderRadius, BorderRadius.circular(12));
  });
}
