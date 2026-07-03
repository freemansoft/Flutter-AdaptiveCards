import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final authCardJson = <String, dynamic>{
    'type': 'AdaptiveCard',
    'version': '1.4',
    'body': <dynamic>[
      <String, dynamic>{'type': 'TextBlock', 'text': 'Please sign in'},
    ],
    'authentication': <String, dynamic>{
      'text': 'Sign in to continue',
      'connectionName': 'myConnection',
      'buttons': <dynamic>[
        <String, dynamic>{
          'type': 'signin',
          'title': 'Sign in',
          'value': 'https://login.example.com/oauth',
        },
      ],
    },
  };

  testWidgets('sign-in tap opens URL; completeSignin replaces the card', (
    tester,
  ) async {
    final opened = <String>[];
    Map<String, dynamic>? replacement;

    final client = _FakeBackendClient({
      'effects': <dynamic>[
        <String, dynamic>{
          'type': 'replaceCard',
          'card': <String, dynamic>{
            'type': 'AdaptiveCard',
            'version': '1.4',
            'body': <dynamic>[
              <String, dynamic>{'type': 'TextBlock', 'text': 'Signed in'},
            ],
          },
        },
      ],
    });

    final cardKey = GlobalKey<RawAdaptiveCardState>();
    final handlers = AdaptiveCardBackendHandlers(
      client: client,
      cardKey: cardKey,
      urlOpener: (url) async => opened.add(url),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: handlers.wrap(
            RawAdaptiveCard.fromMap(
              key: cardKey,
              map: authCardJson,
              hostConfigs: HostConfigs(),
            ),
            onCardReplaced: (c) => replacement = c,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(opened, ['https://login.example.com/oauth']);

    await handlers.completeSignin(state: 'magic-123');
    await tester.pumpAndSettle();

    expect(replacement, isNotNull);
    expect(replacement!['body'], isNotEmpty);
  });

  testWidgets('completeSignin without prior tap reports StateError', (
    tester,
  ) async {
    final errors = <Object>[];
    final cardKey = GlobalKey<RawAdaptiveCardState>();
    final handlers = AdaptiveCardBackendHandlers(
      client: _FakeBackendClient(const {}),
      cardKey: cardKey,
      onError: errors.add,
    );

    await handlers.completeSignin(state: 'orphan');

    expect(errors.single, isA<StateError>());
  });

  testWidgets('onError fires when client throws during completeSignin', (
    tester,
  ) async {
    final errors = <Object>[];
    final opened = <String>[];
    final cardKey = GlobalKey<RawAdaptiveCardState>();
    final handlers = AdaptiveCardBackendHandlers(
      client: _ThrowingBackendClient(),
      cardKey: cardKey,
      onError: errors.add,
      urlOpener: (url) async => opened.add(url),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: handlers.wrap(
            RawAdaptiveCard.fromMap(
              key: cardKey,
              map: authCardJson,
              hostConfigs: HostConfigs(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(opened, ['https://login.example.com/oauth']);

    await handlers.completeSignin(state: 'bad-state');
    await tester.pumpAndSettle();

    expect(errors, isNotEmpty);
  });
}

class _FakeBackendClient implements AdaptiveCardBackendClient {
  _FakeBackendClient(this.response);

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    return response;
  }
}

class _ThrowingBackendClient implements AdaptiveCardBackendClient {
  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    throw StateError('backend unavailable');
  }
}
