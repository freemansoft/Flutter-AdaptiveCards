import 'package:adaptive_chat/src/chat_host_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _assistantCardBubble(List<Map<String, dynamic>> body) => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': [
    {
      'type': 'ColumnSet',
      'columns': [
        {
          'type': 'Column',
          'width': 3,
          'items': [
            {
              'type': 'Container',
              'style': 'emphasis',
              'roundedCorners': true,
              'items': body,
            },
          ],
        },
        {'type': 'Column', 'width': 1, 'items': <dynamic>[]},
      ],
    },
  ],
};

void main() {
  testWidgets('assistant card bubble renders a date input', (tester) async {
    final card = _assistantCardBubble([
      {'type': 'TextBlock', 'text': 'Pick a date', 'wrap': true},
      {'type': 'Input.Date', 'id': 'when'},
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveCardsCanvas.map(
            content: card,
            hostConfigs: chatHostConfigs(),
            showDebugJson: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pick a date'), findsOneWidget);
    // Input.Date renders a text field the user can type/pick a date into.
    expect(find.byType(TextField), findsWidgets);
  });
}
