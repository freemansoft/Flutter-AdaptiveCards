import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _card(Map<String, dynamic> rating) => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [rating],
};

void main() {
  testWidgets('renders filled stars for value and empty stars up to max', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({'type': 'Rating', 'id': 'stars', 'value': 3, 'max': 5}),
        title: 'rating render',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
  });

  testWidgets('defaults to max 5 and value 0 when unset', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({'type': 'Rating', 'id': 'stars'}),
        title: 'rating defaults',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byIcon(Icons.star_border), findsNWidgets(5));
  });

  for (final color in ['marigold', 'light']) {
    testWidgets('renders with the "$color" color token', (tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: _card({
            'type': 'Rating',
            'id': 'stars',
            'value': 3,
            'max': 5,
            'color': color,
          }),
          title: 'rating color $color',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });
  }
}
