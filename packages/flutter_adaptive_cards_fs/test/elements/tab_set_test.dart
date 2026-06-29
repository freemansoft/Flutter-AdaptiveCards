import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _tabSetCard() => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [
    {
      'type': 'TabSet',
      'id': 'tabs1',
      'tabs': [
        {
          'title': 'Tab One',
          'items': [
            {'type': 'TextBlock', 'text': 'Content one'},
          ],
        },
        {
          'title': 'Tab Two',
          'items': [
            {'type': 'TextBlock', 'text': 'Content two'},
          ],
        },
      ],
    },
  ],
};

void main() {
  testWidgets('renders a tab for each entry', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _tabSetCard(), title: 'tab set tabs'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.text('Tab One'), findsOneWidget);
    expect(find.text('Tab Two'), findsOneWidget);
  });

  testWidgets('shows the first tab content and switches on tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _tabSetCard(), title: 'tab set switch'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Content one'), findsOneWidget);
    expect(find.text('Content two'), findsNothing);

    await tester.tap(find.text('Tab Two'));
    await tester.pumpAndSettle();

    expect(find.text('Content two'), findsOneWidget);
  });
}
