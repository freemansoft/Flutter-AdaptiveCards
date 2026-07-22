import 'package:adaptive_chat_client/src/chat_host_config.dart';
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

Map<String, dynamic> _fullWidthCardBubble(List<Map<String, dynamic>> body) => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': [
    {
      'type': 'Container',
      'style': 'emphasis',
      'roundedCorners': true,
      'items': body,
    },
  ],
};

List<Map<String, dynamic>> _carouselFragment() => [
  {
    'type': 'Carousel',
    'pages': [
      {
        'type': 'CarouselPage',
        'items': [
          {
            'type': 'FactSet',
            'facts': [
              {'title': 'State', 'value': 'California'},
              {'title': 'Population', 'value': '39.24M'},
            ],
          },
        ],
      },
      {
        'type': 'CarouselPage',
        'items': [
          {
            'type': 'FactSet',
            'facts': [
              {'title': 'State', 'value': 'Texas'},
              {'title': 'Population', 'value': '29.18M'},
            ],
          },
        ],
      },
    ],
  },
];

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

  testWidgets('carousel card reply renders full-width without asserting', (
    tester,
  ) async {
    final card = _fullWidthCardBubble(_carouselFragment());

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

    // The full-width bubble has no ColumnSet, so the Carousel's LayoutBuilder
    // is never asked for an intrinsic height -> it lays out and renders. (The
    // old ColumnSet bubble instead floods the renderer with "RenderBox was not
    // laid out" assertions; that is the bug this full-width shape works around
    // until the core Carousel is made intrinsic-safe.)
    expect(tester.takeException(), isNull);
    expect(find.textContaining('California'), findsWidgets);
  });
}
