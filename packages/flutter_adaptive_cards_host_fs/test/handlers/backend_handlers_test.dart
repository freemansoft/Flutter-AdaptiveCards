import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onSubmit posts invoke and applies setInputErrors response', (
    tester,
  ) async {
    final cardKey = GlobalKey<RawAdaptiveCardState>();
    final client = _FakeBackendClient({
      'type': 'adaptiveCard.invokeResponse',
      'effects': [
        {
          'type': 'setInputErrors',
          'errors': {'email': 'Required'},
        },
      ],
    });

    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        <String, dynamic>{
          'type': 'Input.Text',
          'id': 'email',
          'value': 'user@example.com',
        },
      ],
      'actions': [
        <String, dynamic>{
          'type': 'Action.Submit',
          'title': 'Submit',
          'associatedInputs': 'none',
          'data': <String, dynamic>{},
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body:
              AdaptiveCardBackendHandlers(
                client: client,
                cardKey: cardKey,
              ).wrap(
                RawAdaptiveCard.fromMap(
                  key: cardKey,
                  map: map,
                  hostConfigs: HostConfigs(),
                ),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(client.postCount, 1);
    expect(client.lastBody?['kind'], 'submit');
    expect(find.text('Required'), findsOneWidget);
  });

  group('invoke kinds per handler', () {
    testWidgets('onExecute posts an execute-kind invoke', (tester) async {
      final harness = await _pumpWiredCard(tester);
      // The closures resolve card state from cardKey, so a throwaway wrap
      // exposes the same callbacks bound to the mounted card.
      final handlers =
          harness.handlers.wrap(const SizedBox())
              as InheritedAdaptiveCardHandlers;

      handlers.onExecute(
        const ExecuteActionInvoke(data: {'a': 1}, verb: 'go'),
      );
      await tester.pumpAndSettle();

      expect(harness.client.postCount, 1);
      expect(harness.client.lastBody?['kind'], 'execute');
    });

    testWidgets('onRefresh posts an execute-kind invoke', (tester) async {
      final harness = await _pumpWiredCard(tester);
      final handlers =
          harness.handlers.wrap(const SizedBox())
              as InheritedAdaptiveCardHandlers;

      handlers.onRefresh!(
        const RefreshActionInvoke(data: {'b': 2}, verb: 'refresh'),
      );
      await tester.pumpAndSettle();

      expect(harness.client.postCount, 1);
      expect(harness.client.lastBody?['kind'], 'execute');
    });

    testWidgets('onChange posts an inputChange-kind invoke', (tester) async {
      final harness = await _pumpWiredCard(tester);
      final handlers =
          harness.handlers.wrap(const SizedBox())
              as InheritedAdaptiveCardHandlers;

      handlers.onChange(
        InputChangeInvoke(
          inputId: 'email',
          value: 'changed',
          cardState: harness.cardKey.currentState!,
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.client.postCount, 1);
      expect(harness.client.lastBody?['kind'], 'inputChange');
    });
  });

  group('error handling', () {
    testWidgets('reports StateError when cardKey has no mounted state', (
      tester,
    ) async {
      final errors = <Object>[];
      final client = _FakeBackendClient(const {});
      final handlers =
          AdaptiveCardBackendHandlers(
                client: client,
                cardKey: GlobalKey<RawAdaptiveCardState>(),
                onError: errors.add,
              ).wrap(const SizedBox())
              as InheritedAdaptiveCardHandlers;

      handlers.onSubmit(const SubmitActionInvoke(data: {}));
      await tester.pump();

      expect(errors.single, isA<StateError>());
      expect(client.postCount, 0, reason: 'no post when state is missing');
    });

    testWidgets('reports the error when the backend post throws', (
      tester,
    ) async {
      final errors = <Object>[];
      final cardKey = GlobalKey<RawAdaptiveCardState>();
      final handlers = AdaptiveCardBackendHandlers(
        client: _ThrowingBackendClient(),
        cardKey: cardKey,
        onError: errors.add,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: handlers.wrap(
              RawAdaptiveCard.fromMap(
                key: cardKey,
                map: const <String, dynamic>{
                  'type': 'AdaptiveCard',
                  'version': '1.5',
                  'body': [
                    <String, dynamic>{'type': 'Input.Text', 'id': 'email'},
                  ],
                },
                hostConfigs: HostConfigs(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      (handlers.wrap(const SizedBox()) as InheritedAdaptiveCardHandlers)
          .onSubmit(const SubmitActionInvoke(data: {}));
      await tester.pumpAndSettle();

      expect(errors.single, isA<StateError>());
    });
  });
}

/// Pumps a minimal wired card and returns the handlers + key + fake client.
Future<_Harness> _pumpWiredCard(
  WidgetTester tester, {
  void Function(Object error)? onError,
}) async {
  final fake = _FakeBackendClient(<String, dynamic>{
    'type': 'adaptiveCard.invokeResponse',
    'effects': <dynamic>[],
  });
  final cardKey = GlobalKey<RawAdaptiveCardState>();
  final handlers = AdaptiveCardBackendHandlers(
    client: fake,
    cardKey: cardKey,
    onError: onError,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: handlers.wrap(
          RawAdaptiveCard.fromMap(
            key: cardKey,
            map: const <String, dynamic>{
              'type': 'AdaptiveCard',
              'version': '1.5',
              'body': [
                <String, dynamic>{'type': 'Input.Text', 'id': 'email'},
              ],
            },
            hostConfigs: HostConfigs(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(handlers, cardKey, fake);
}

class _Harness {
  _Harness(this.handlers, this.cardKey, this.client);

  final AdaptiveCardBackendHandlers handlers;
  final GlobalKey<RawAdaptiveCardState> cardKey;
  final _FakeBackendClient client;
}

class _FakeBackendClient implements AdaptiveCardBackendClient {
  _FakeBackendClient(this.response);

  final Map<String, dynamic> response;
  int postCount = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    postCount++;
    lastBody = body;
    return response;
  }
}

class _ThrowingBackendClient implements AdaptiveCardBackendClient {
  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    throw StateError('backend unavailable');
  }
}
