import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

const _httpCard = <String, dynamic>{
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': <Map<String, dynamic>>[],
  'actions': [
    <String, dynamic>{
      'type': 'Action.Http',
      'title': 'Go',
      'method': 'GET',
      'url': 'https://contoso.com/api',
    },
  ],
};

Future<void> _pump(
  WidgetTester tester, {
  required AdaptiveHttpExecutor executor,
  void Function(Map<String, dynamic> card)? onCardReplaced,
  void Function(Object error)? onError,
}) async {
  final cardKey = GlobalKey<RawAdaptiveCardState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdaptiveCardBackendHandlers(
          client: _NoopBackendClient(),
          cardKey: cardKey,
          httpExecutor: executor,
          onError: onError,
        ).wrap(
          RawAdaptiveCard.fromMap(
            key: cardKey,
            map: _httpCard,
            hostConfigs: HostConfigs(),
          ),
          onCardReplaced: onCardReplaced,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Action.Http replaces card on CARD-UPDATE-IN-BODY', (
    tester,
  ) async {
    Map<String, dynamic>? replaced;
    final executor = _FakeExecutor(
      const AdaptiveHttpResult(
        statusCode: 200,
        headers: {'card-update-in-body': 'true'},
        body: '{"type":"AdaptiveCard","version":"1.5","body":[]}',
      ),
    );

    await _pump(
      tester,
      executor: executor,
      onCardReplaced: (card) => replaced = card,
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(executor.calls, 1);
    expect(replaced, isNotNull);
    expect(replaced!['type'], 'AdaptiveCard');
  });

  testWidgets('Action.Http surfaces CARD-ACTION-STATUS via onError', (
    tester,
  ) async {
    Object? error;
    final executor = _FakeExecutor(
      const AdaptiveHttpResult(
        statusCode: 400,
        headers: {'card-action-status': 'Not allowed'},
        body: 'fail',
      ),
    );

    await _pump(tester, executor: executor, onError: (e) => error = e);

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(error, isA<AdaptiveCardBackendException>());
    expect((error! as AdaptiveCardBackendException).message, 'Not allowed');
  });
}

class _FakeExecutor implements AdaptiveHttpExecutor {
  _FakeExecutor(this.result);

  final AdaptiveHttpResult result;
  int calls = 0;

  @override
  Future<AdaptiveHttpResult> execute(HttpActionInvoke invoke) async {
    calls++;
    return result;
  }
}

class _NoopBackendClient implements AdaptiveCardBackendClient {
  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async => {};
}
