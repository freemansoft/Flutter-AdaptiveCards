import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'Action.Http forwards resolved url/body/headers + raw inputs to onHttp',
    (tester) async {
      HttpActionInvoke? captured;

      const card = {
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {'type': 'Input.Text', 'id': 'nameInput', 'value': 'David'},
        ],
        'actions': [
          {
            'type': 'Action.Http',
            'id': 'http-1',
            'title': 'Send',
            'method': 'post',
            'url': 'https://contoso.com/hi?name={{nameInput.value}}',
            'body': '{"name":"{{nameInput.value}}"}',
            'headers': [
              {'name': 'Content-Type', 'value': 'application/json'},
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'http invoke test',
          onHttp: (invoke) => captured = invoke,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.actionId, 'http-1');
      expect(captured!.method, 'POST');
      expect(captured!.url, 'https://contoso.com/hi?name=David');
      expect(captured!.body, '{"name":"David"}');
      expect(captured!.headers.single.name, 'Content-Type');
      expect(captured!.headers.single.value, 'application/json');
      expect(captured!.inputValues['nameInput'], 'David');
    },
  );

  testWidgets('Action.Http with no handler does not throw', (tester) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.Http',
          'title': 'Go',
          'method': 'GET',
          'url': 'https://example.com',
        },
      ],
    };

    // No handler callbacks -> no InheritedAdaptiveCardHandlers wrapper.
    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'http no handler'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Action.Http aborts forward when URI policy denies the url', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.Http',
          'title': 'Evil',
          'method': 'GET',
          'url': 'javascript:alert(1)',
        },
      ],
    };

    await tester.pumpWidget(
      InheritedAdaptiveCardSecurityPolicy(
        uriPolicy: AdaptiveUriPolicy.standard,
        fetchPolicy: AdaptiveFetchPolicy.standard,
        child: getTestWidgetFromMap(
          map: card,
          title: 'http policy test',
          onHttp: (_) => fail('host handler should not run'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Evil'));
    await tester.pumpAndSettle();

    expect(find.textContaining('blocked'), findsOneWidget);
  });

  testWidgets('Action.Http aborts when a required input is invalid', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {'type': 'Input.Text', 'id': 'req', 'isRequired': true},
      ],
      'actions': [
        {
          'type': 'Action.Http',
          'title': 'Send',
          'method': 'GET',
          'url': 'https://example.com',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'http validation test',
        onHttp: (_) => fail('should not forward with invalid input'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
