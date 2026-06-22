import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_utils.dart';

({List<int> bytes, String contentType}) _urlResponder(Uri url) {
  final path = url.toString();
  if (path == 'https://example.com/card.json') {
    final card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {'type': 'TextBlock', 'text': 'Fetched Card Content'},
      ],
    };
    return (
      bytes: utf8.encode(json.encode(card)),
      contentType: 'application/json; charset=utf-8',
    );
  }
  return (
    bytes: utf8.encode('<html><body><h1>Hello</h1></body></html>'),
    contentType: 'text/html; charset=utf-8',
  );
}

void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides(urlResponder: _urlResponder);
  });

  testWidgets('Action.OpenUrlDialog opens dialog and fetches card', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> cardMap = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {'type': 'TextBlock', 'text': 'Main Card'},
      ],
      'actions': [
        {
          'type': 'Action.OpenUrlDialog',
          'title': 'Open Dialog',
          'url': 'https://example.com/card.json',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: cardMap, title: 'OpenUrlDialog Test'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Dialog'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Fetched Card Content'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Fetched Card Content'), findsNothing);
  });

  testWidgets(
    'Action.OpenUrlDialog auto-launches browser for non-JSON content',
    (WidgetTester tester) async {
      final Map<String, dynamic> cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {'type': 'TextBlock', 'text': 'Main Card'},
        ],
        'actions': [
          {
            'type': 'Action.OpenUrlDialog',
            'title': 'Open Web Page',
            'url': 'https://example.com/page.html',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'OpenUrlDialog Browser Launch Test',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Web Page'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Opening in browser...'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Opening in browser...'), findsNothing);
      expect(find.text('Main Card'), findsOneWidget);
    },
  );
}
