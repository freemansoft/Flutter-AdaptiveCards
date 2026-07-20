import 'dart:convert';

import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:adaptive_chat/src/conversation_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ChatBackendClient _clientReturning(List<Map<String, dynamic>> messages) {
  final mock = MockClient((req) async {
    if (req.url.path == '/conversations') {
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'links': {'postNext': '/conversations/c_1/interactions'},
        }),
        200,
      );
    }
    return http.Response(
      jsonEncode({
        'conversationId': 'c_1',
        'interactionId': req.headers['X-Interaction-Id'],
        'messages': messages,
        'links': {
          'self': '/conversations/c_1/interactions/x',
          'postNext': '/conversations/c_1/interactions',
        },
      }),
      200,
    );
  });
  return ChatBackendClient(
    baseUrl: Uri.parse('http://localhost:8000'),
    client: mock,
  );
}

void main() {
  test(
    'startConversation makes the controller ready and clears messages',
    () async {
      final c = ConversationController(client: _clientReturning([]));
      expect(c.ready, isFalse);
      await c.startConversation();
      expect(c.ready, isTrue);
      expect(c.messages, isEmpty);
    },
  );

  test('send appends returned cards and bumps composeEpoch', () async {
    final c = ConversationController(
      client: _clientReturning([
        {'type': 'AdaptiveCard', 'body': <dynamic>[]},
        {'type': 'AdaptiveCard', 'body': <dynamic>[]},
      ]),
    );
    await c.startConversation();
    final epoch0 = c.composeEpoch;
    await c.send('hello');
    expect(c.messages.length, 2);
    expect(c.composeEpoch, greaterThan(epoch0));
    expect(c.pending, isFalse);
  });

  test('send does nothing before startConversation', () async {
    final c = ConversationController(client: _clientReturning([]));
    await c.send('hello');
    expect(c.messages, isEmpty);
  });

  test(
    'a failed startConversation records startError without throwing and '
    'leaves ready false',
    () async {
      final mock = MockClient((req) async {
        return http.Response('server error', 500);
      });
      final c = ConversationController(
        client: ChatBackendClient(
          baseUrl: Uri.parse('http://localhost:8000'),
          client: mock,
        ),
      );

      await c.startConversation();

      expect(c.ready, isFalse);
      expect(c.startError, isNotNull);
      expect(c.starting, isFalse);
    },
  );
}
