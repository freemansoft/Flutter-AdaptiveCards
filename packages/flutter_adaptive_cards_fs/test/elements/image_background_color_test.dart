import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Image renders a ColoredBox for backgroundColor', (
    WidgetTester tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Image',
          'url': 'https://example.com/x.png',
          'backgroundColor': '#FF0000',
          'altText': 'red-backed',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'image bg'),
    );
    await tester.pump();

    final coloredBox = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((b) => b.color == const Color(0xFFFF0000));
    expect(coloredBox, isNotEmpty);
  });
}
