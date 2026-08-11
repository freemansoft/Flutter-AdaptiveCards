import 'dart:async';
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

/// Stays inside [reply] until [gate] completes, so a second request can
/// arrive while the first is still in flight.
class _GatedResponder implements Responder {
  _GatedResponder(this.gate, this.onCall);
  final Future<void> gate;
  final void Function() onCall;

  @override
  Future<Reply> reply(String text, List<(String, String)> history) async {
    onCall();
    await gate;
    return const Reply(text: 'ok');
  }

  @override
  Map<String, dynamic> describe() => {'kind': 'gated'};
}

/// Records the history handed to each call so tests can assert on what the
/// model would actually have been shown.
class _HistorySpyResponder implements Responder {
  _HistorySpyResponder(this.replyFor);
  final Reply Function(String text) replyFor;
  final histories = <List<(String, String)>>[];

  @override
  Future<Reply> reply(String text, List<(String, String)> history) async {
    histories.add(List.of(history));
    return replyFor(text);
  }

  @override
  Map<String, dynamic> describe() => {'kind': 'history-spy'};
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

  test('two overlapping POSTs with one X-Interaction-Id run the responder '
      'once and record one interaction', () async {
    // The retry case idempotency exists for: the client gave up waiting and
    // re-sent while the first call was still inside the responder.
    final gate = Completer<void>();
    var callCount = 0;
    final slowHandler = buildHandler(
      store: store,
      responder: _GatedResponder(gate.future, () => callCount++),
    );
    final cid = await startConversation(slowHandler);
    Request makeRequest() => Request(
      'POST',
      Uri.parse('http://localhost/conversations/$cid/interactions'),
      headers: {'x-interaction-id': 'i_0001'},
      body: jsonEncode({
        'data': {'message': 'hello'},
      }),
    );
    final first = Future.value(slowHandler(makeRequest()));
    final second = Future.value(slowHandler(makeRequest()));
    gate.complete();
    final responses = await Future.wait([first, second]);

    expect(callCount, 1, reason: 'the responder must not run twice');
    expect(
      await decode(responses[0]),
      await decode(responses[1]),
      reason: 'both callers get the same envelope',
    );
    expect(store.get(cid)!.order, ['i_0001']);
  });

  test('a failed reply is not replayed to the responder as history', () async {
    final spy = _HistorySpyResponder(
      (text) => text == 'first'
          ? const Reply(
              text: '(Ollama unreachable at http://x — boom)',
              ok: false,
            )
          : const Reply(text: 'ok'),
    );
    final spyHandler = buildHandler(store: store, responder: spy);
    final cid = await startConversation(spyHandler);
    Future<void> send(String iid, String message) async {
      await spyHandler(
        Request(
          'POST',
          Uri.parse('http://localhost/conversations/$cid/interactions'),
          headers: {'x-interaction-id': iid},
          body: jsonEncode({
            'data': {'message': message},
          }),
        ),
      );
    }

    await send('i_0001', 'first');
    await send('i_0002', 'second');

    // The failed exchange is dropped whole: replaying the user turn alone
    // would leave the model an unanswered question to explain.
    expect(spy.histories[1], isEmpty);
  });

  test('a successful reply is still replayed to the responder as '
      'history', () async {
    final spy = _HistorySpyResponder((text) => const Reply(text: 'sure'));
    final spyHandler = buildHandler(store: store, responder: spy);
    final cid = await startConversation(spyHandler);
    Future<void> send(String iid, String message) async {
      await spyHandler(
        Request(
          'POST',
          Uri.parse('http://localhost/conversations/$cid/interactions'),
          headers: {'x-interaction-id': iid},
          body: jsonEncode({
            'data': {'message': message},
          }),
        ),
      );
    }

    await send('i_0001', 'first');
    await send('i_0002', 'second');

    expect(spy.histories[1], [('user', 'first'), ('assistant', 'sure')]);
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
