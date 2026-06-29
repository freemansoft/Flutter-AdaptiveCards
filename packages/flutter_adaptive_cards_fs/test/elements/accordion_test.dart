import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _accordionCard() => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [
    {
      'type': 'Accordion',
      'id': 'acc1',
      'items': [
        {
          'title': 'First Section',
          'items': [
            {'type': 'TextBlock', 'text': 'First body'},
          ],
        },
        {
          'title': 'Second Section',
          'items': [
            {'type': 'TextBlock', 'text': 'Second body'},
          ],
        },
      ],
    },
  ],
};

void main() {
  testWidgets('renders an expansion tile header for each item', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _accordionCard(), title: 'accordion headers'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExpansionTile), findsNWidgets(2));
    expect(find.text('First Section'), findsOneWidget);
    expect(find.text('Second Section'), findsOneWidget);
  });

  testWidgets('section body is collapsed until its header is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _accordionCard(), title: 'accordion expand'),
    );
    await tester.pumpAndSettle();

    // Collapsed sections keep their body offstage.
    expect(find.text('First body'), findsNothing);

    await tester.tap(find.text('First Section'));
    await tester.pumpAndSettle();

    expect(find.text('First body'), findsOneWidget);
    // Tapping one section does not expand the others.
    expect(find.text('Second body'), findsNothing);
  });
}
