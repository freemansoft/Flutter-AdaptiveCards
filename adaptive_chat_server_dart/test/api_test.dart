import 'dart:convert';

import 'package:adaptive_chat_server_dart/src/app.dart';
import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _CountingResponder implements Responder {
  _CountingResponder(this.onCall);
  final void Function() onCall;

  @override
  Future<Reply> reply(String text, List<(String, String)> history) async {
    onCall();
    return const Reply(text: 'ok');
  }

  @override
  Map<String, dynamic> describe() => {'kind': 'counting'};
}

void main() {
  late ConversationStore store;
  late Handler handler;

  setUp(() {
    store = ConversationStore();
    handler = buildHandler(store: store, responder: EchoResponder());
  });

  Future<Map<String, dynamic>> decode(Response response) async {
    final body = await response.readAsString();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<String> startConversation(Handler h) async {
    final response = await h(
      Request('POST', Uri.parse('http://localhost/conversations')),
    );
    final json = await decode(response);
    return json['conversationId'] as String;
  }

  test('POST /conversations returns a conversationId and a matching '
      'postNext link', () async {
    final response = await handler(
      Request('POST', Uri.parse('http://localhost/conversations')),
    );
    expect(response.statusCode, 200);
    final json = await decode(response);
    expect(json['conversationId'], startsWith('c_'));
    final links = json['links'] as Map<String, dynamic>;
    expect(
      links['postNext'],
      '/conversations/${json['conversationId']}/interactions',
    );
  });

  test('POST interaction without X-Interaction-Id returns 400', () async {
    final cid = await startConversation(handler);
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/conversations/$cid/interactions'),
        body: jsonEncode({
          'data': {'message': 'hi'},
        }),
      ),
    );
    expect(response.statusCode, 400);
  });

  test(
    'POST interaction against an unknown conversation returns 404',
    () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/conversations/missing/interactions'),
          headers: {'x-interaction-id': 'i_0001'},
          body: jsonEncode({
            'data': {'message': 'hi'},
          }),
        ),
      );
      expect(response.statusCode, 404);
    },
  );

  test('POST interaction with missing data.message returns 400', () async {
    final cid = await startConversation(handler);
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/conversations/$cid/interactions'),
        headers: {'x-interaction-id': 'i_0001'},
        body: jsonEncode({'data': <String, dynamic>{}}),
      ),
    );
    expect(response.statusCode, 400);
  });

  test('a full send + replay round-trip with the echo responder', () async {
    final cid = await startConversation(handler);

    final send = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/conversations/$cid/interactions'),
        headers: {'x-interaction-id': 'i_0001'},
        body: jsonEncode({
          'data': {'message': 'hello'},
        }),
      ),
    );
    expect(send.statusCode, 200);
    final envelope = await decode(send);
    expect(envelope['conversationId'], cid);
    expect(envelope['interactionId'], 'i_0001');
    expect(envelope['messages'], hasLength(2));

    final replay = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/conversations/$cid/interactions/i_0001'),
      ),
    );
    expect(replay.statusCode, 200);
    expect(await decode(replay), envelope);
  });

  test('GET replay of an unknown interaction returns 404', () async {
    final cid = await startConversation(handler);
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/conversations/$cid/interactions/missing'),
      ),
    );
    expect(response.statusCode, 404);
  });

  test('a repeated X-Interaction-Id replays the stored envelope without '
      're-running the responder', () async {
    var callCount = 0;
    final countingHandler = buildHandler(
      store: store,
      responder: _CountingResponder(() => callCount++),
    );
    final cid = await startConversation(countingHandler);
    Request makeRequest() => Request(
      'POST',
      Uri.parse('http://localhost/conversations/$cid/interactions'),
      headers: {'x-interaction-id': 'i_0001'},
      body: jsonEncode({
        'data': {'message': 'hello'},
      }),
    );
    final first = await countingHandler(makeRequest());
    final second = await countingHandler(makeRequest());
    expect(await decode(first), await decode(second));
    expect(callCount, 1);
  });

  test('GET /status returns 2-space indented JSON reporting the echo '
      'responder', () async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/status')),
    );
    expect(response.statusCode, 200);
    final body = await response.readAsString();
    expect(body, contains('\n  "'));
    final json = jsonDecode(body) as Map<String, dynamic>;
    expect(json['responder'], {'kind': 'echo'});
    expect(json['conversationCount'], 0);
  });

  test('an OPTIONS preflight request gets wide-open CORS headers', () async {
    final response = await handler(
      Request('OPTIONS', Uri.parse('http://localhost/conversations')),
    );
    expect(response.headers['access-control-allow-origin'], '*');
  });

  test('a normal response also carries CORS headers', () async {
    final response = await handler(
      Request('POST', Uri.parse('http://localhost/conversations')),
    );
    expect(response.headers['access-control-allow-origin'], '*');
  });
}
