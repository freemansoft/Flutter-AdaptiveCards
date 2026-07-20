import 'dart:async';
import 'dart:convert';

import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:adaptive_chat/src/chat_page.dart';
import 'package:adaptive_chat/src/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Card whose only TextBlock says [text], so tests can find it on screen.
Map<String, dynamic> _cardSaying(String text) => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': [
    {'type': 'TextBlock', 'text': text, 'wrap': true},
  ],
};

ChatBackendClient _client({Completer<void>? gate}) {
  return ChatBackendClient(
    baseUrl: Uri.parse('http://localhost:8000'),
    client: MockClient((req) async {
      if (req.url.path == '/conversations') {
        return http.Response(
          jsonEncode({
            'conversationId': 'c_1',
            'links': {'postNext': '/conversations/c_1/interactions'},
          }),
          200,
        );
      }
      if (gate != null) {
        await gate.future;
      }
      final decoded = jsonDecode(req.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final message = data['message'] as String;
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'interactionId': req.headers['X-Interaction-Id'],
          'messages': [_cardSaying('you: $message')],
          'links': {
            'self': '/conversations/c_1/interactions/x',
            'postNext': '/conversations/c_1/interactions',
          },
        }),
        200,
      );
    }),
  );
}

/// A client whose `/conversations` response is controlled by [startFails],
/// so a single MockClient can be flipped from failing to succeeding (used to
/// test the Retry affordance).
ChatBackendClient _clientWithStartFailing(bool Function() startFails) {
  return ChatBackendClient(
    baseUrl: Uri.parse('http://localhost:8000'),
    client: MockClient((req) async {
      if (req.url.path == '/conversations') {
        if (startFails()) {
          return http.Response('server error', 500);
        }
        return http.Response(
          jsonEncode({
            'conversationId': 'c_1',
            'links': {'postNext': '/conversations/c_1/interactions'},
          }),
          200,
        );
      }
      final decoded = jsonDecode(req.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final message = data['message'] as String;
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'interactionId': req.headers['X-Interaction-Id'],
          'messages': [_cardSaying('you: $message')],
          'links': {
            'self': '/conversations/c_1/interactions/x',
            'postNext': '/conversations/c_1/interactions',
          },
        }),
        200,
      );
    }),
  );
}

Future<void> _pumpPage(WidgetTester tester, ConversationController c) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatPage(controller: c, hostConfigs: HostConfigs()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sent message appears as a bubble in the log', (tester) async {
    final c = ConversationController(client: _client());
    await c.startConversation();
    await _pumpPage(tester, c);

    await c.send('hello');
    await tester.pumpAndSettle();

    expect(find.text('you: hello'), findsOneWidget);
  });

  testWidgets('pending indicator shows while a send is in flight', (
    tester,
  ) async {
    final gate = Completer<void>();
    final c = ConversationController(client: _client(gate: gate));
    await c.startConversation();
    await _pumpPage(tester, c);

    final future = c.send('slow');
    await tester.pump(); // let pending=true propagate
    expect(find.byKey(const ValueKey('pending-bubble')), findsOneWidget);

    gate.complete();
    await future;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pending-bubble')), findsNothing);
  });

  testWidgets('replace mode shows only the latest message', (tester) async {
    final c = ConversationController(client: _client())
      ..mode = ChatMode.replace;
    await c.startConversation();
    await _pumpPage(tester, c);

    await c.send('one');
    await tester.pumpAndSettle();
    await c.send('two');
    await tester.pumpAndSettle();

    expect(find.text('you: one'), findsNothing);
    expect(find.text('you: two'), findsOneWidget);
  });

  testWidgets('new-conversation button clears the log', (tester) async {
    final c = ConversationController(client: _client());
    await c.startConversation();
    await _pumpPage(tester, c);
    await c.send('hello');
    await tester.pumpAndSettle();
    expect(find.text('you: hello'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new-conversation')));
    await tester.pumpAndSettle();

    expect(find.text('you: hello'), findsNothing);
  });

  testWidgets('start-error affordance appears when startConversation fails', (
    tester,
  ) async {
    final c = ConversationController(
      client: _clientWithStartFailing(() => true),
    );
    await c.startConversation();
    await _pumpPage(tester, c);

    expect(find.byKey(const ValueKey('start-error')), findsOneWidget);
  });

  testWidgets(
    'start-error affordance is absent when startConversation succeeds',
    (tester) async {
      final c = ConversationController(client: _client());
      await c.startConversation();
      await _pumpPage(tester, c);

      expect(find.byKey(const ValueKey('start-error')), findsNothing);
    },
  );

  testWidgets('tapping Retry after a failed start clears the affordance', (
    tester,
  ) async {
    var fails = true;
    final c = ConversationController(
      client: _clientWithStartFailing(() => fails),
    );
    await c.startConversation();
    await _pumpPage(tester, c);
    expect(find.byKey(const ValueKey('start-error')), findsOneWidget);

    fails = false;
    await tester.tap(find.byKey(const ValueKey('start-error-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('start-error')), findsNothing);
  });

  testWidgets('log auto-scrolls to the bottom as messages are added', (
    tester,
  ) async {
    final c = ConversationController(client: _client());
    await c.startConversation();
    await _pumpPage(tester, c);

    // Send enough messages to overflow the viewport.
    for (var i = 0; i < 20; i++) {
      await c.send('message $i');
      await tester.pumpAndSettle();
    }

    final logScrollable = find.descendant(
      of: find.byKey(const ValueKey('chat-log')),
      matching: find.byType(Scrollable),
    );
    final position = tester
        .state<ScrollableState>(logScrollable.first)
        .position;

    // The log overflowed (there is somewhere to scroll)...
    expect(position.maxScrollExtent, greaterThan(0));
    // ...and it is pinned to the very bottom, so the latest message is visible.
    expect(position.pixels, closeTo(position.maxScrollExtent, 1));
  });
}
