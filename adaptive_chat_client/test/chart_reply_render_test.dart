import 'package:adaptive_chat_client/src/chat_card_registry.dart';
import 'package:adaptive_chat_client/src/chat_host_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shape `assistantCardBubble` sends for a card reply: a single styled
/// Container, no ColumnSet. See `adaptive_chat_server_dart/lib/src/cards.dart`.
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

List<Map<String, dynamic>> _pieFragment() => [
  {
    'type': 'Chart.Pie',
    'title': 'Sales by region',
    'data': [
      {'title': 'North', 'value': 30},
      {'title': 'South', 'value': 45},
      {'title': 'West', 'value': 25},
    ],
  },
];

List<Map<String, dynamic>> _barFragment() => [
  {
    'type': 'Chart.VerticalBar',
    'title': 'Weekly signups',
    'data': [
      {'x': 'Mon', 'y': 12},
      {'x': 'Tue', 'y': 19},
      {'x': 'Wed', 'y': 7},
    ],
  },
];

Future<void> _pumpBubble(
  WidgetTester tester,
  List<Map<String, dynamic>> body, {
  required CardTypeRegistry registry,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdaptiveCardsCanvas.map(
          content: _fullWidthCardBubble(body),
          hostConfigs: chatHostConfigs(),
          cardTypeRegistry: registry,
          showDebugJson: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pie chart reply renders with the chat registry', (tester) async {
    await _pumpBubble(tester, _pieFragment(), registry: chatCardTypeRegistry);

    // find.byType names the widget the registry was supposed to build, via
    // the widgets barrel added in Task 1.
    expect(find.byType(AdaptivePieChart), findsOneWidget);
    expect(find.text('Sales by region'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical bar chart reply renders with the chat registry', (
    tester,
  ) async {
    await _pumpBubble(tester, _barFragment(), registry: chatCardTypeRegistry);

    expect(find.byType(AdaptiveBarChart), findsOneWidget);
    expect(find.text('Weekly signups'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the same card without the chart registry renders the '
      'unknown-type placeholder', (tester) async {
    await _pumpBubble(
      tester,
      _pieFragment(),
      registry: const CardTypeRegistry(),
    );

    // Pins the before/after difference this feature creates: with the default
    // registry there is no Chart.Pie builder, so AdaptiveUnknown renders an
    // error placeholder instead of a chart. Without this case the two tests
    // above could pass for the wrong reason.
    //
    // The placeholder is matched by message text, not by type:
    // AdaptiveErrorPlaceholder is not exported from flutter_adaptive_cards_fs.
    expect(find.byType(AdaptivePieChart), findsNothing);
    expect(find.textContaining('Type Chart.Pie not found'), findsOneWidget);
  });
}
