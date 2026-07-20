import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _cardWithActionIcon(String? iconUrl) => {
  'type': 'AdaptiveCard',
  'body': [
    {
      'type': 'ActionSet',
      'actions': [
        {
          'type': 'Action.Submit',
          'id': 'send',
          'title': 'Send',
          'iconUrl': ?iconUrl,
        },
      ],
    },
  ],
};

void main() {
  testWidgets(
    'action iconUrl "icon:Send" renders a Fluent send glyph via the resolver',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: _cardWithActionIcon('icon:Send'),
          title: 'fluent action icon',
        ),
      );
      await tester.pumpAndSettle();

      // Resolved through the same Fluent map the Icon element uses
      // (`send` -> Icons.send_outlined, the `regular` variant).
      expect(find.byIcon(Icons.send_outlined), findsOneWidget);
      // Title is still shown alongside the icon (icon-only is a follow-up).
      expect(find.text('Send'), findsOneWidget);
    },
  );

  testWidgets('an action with no iconUrl renders no glyph (title only)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _cardWithActionIcon(null),
        title: 'no action icon',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.send_outlined), findsNothing);
    expect(find.text('Send'), findsOneWidget);
  });
}
