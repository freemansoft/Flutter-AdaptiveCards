import 'dart:convert';

import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('startConversation parses id and postNext', () async {
    final mock = MockClient((req) async {
      expect(req.url.path, '/conversations');
      expect(req.method, 'POST');
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'links': {'postNext': '/conversations/c_1/interactions'},
        }),
        200,
      );
    });
    final client = ChatBackendClient(
      baseUrl: Uri.parse('http://localhost:8000'),
      client: mock,
    );

    final start = await client.startConversation();

    expect(start.conversationId, 'c_1');
    expect(start.postNext, '/conversations/c_1/interactions');
  });

  test(
    'sendInteraction posts PlainJson body + interaction header, parses '
    'envelope',
    () async {
      late http.Request captured;
      final mock = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'conversationId': 'c_1',
            'interactionId': 'i_0001',
            'messages': [
              {'type': 'AdaptiveCard', 'body': <dynamic>[]},
            ],
            'links': {
              'self': '/conversations/c_1/interactions/i_0001',
              'postNext': '/conversations/c_1/interactions',
            },
          }),
          200,
        );
      });
      final client = ChatBackendClient(
        baseUrl: Uri.parse('http://localhost:8000'),
        client: mock,
      );

      final env = await client.sendInteraction(
        postNext: '/conversations/c_1/interactions',
        interactionId: 'i_0001',
        invoke: const SubmitActionInvoke(data: {'message': 'hello'}),
      );

      expect(captured.headers['X-Interaction-Id'], 'i_0001');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['kind'], 'submit');
      expect((body['data'] as Map)['message'], 'hello');
      expect(env.interactionId, 'i_0001');
      expect(env.messages.single['type'], 'AdaptiveCard');
      expect(env.postNext, '/conversations/c_1/interactions');
    },
  );

  test('non-200 throws ChatBackendException', () async {
    final mock = MockClient((req) async => http.Response('boom', 500));
    final client = ChatBackendClient(
      baseUrl: Uri.parse('http://localhost:8000'),
      client: mock,
    );
    expect(client.startConversation(), throwsA(isA<ChatBackendException>()));
  });
}
