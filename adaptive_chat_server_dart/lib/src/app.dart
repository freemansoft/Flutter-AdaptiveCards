/// shelf app: routes, CORS, and responder selection for the Adaptive Chat
/// backend (echo or Ollama responder).
library;

import 'dart:convert';

import 'package:adaptive_chat_server_dart/src/cards.dart';
import 'package:adaptive_chat_server_dart/src/expired_conversation.dart';
import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:adaptive_chat_server_dart/src/status.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final _log = Logger('adaptive_chat_server_dart');

const _jsonHeaders = {'content-type': 'application/json'};

/// Policy: an interaction response that still carries a normal envelope
/// (200, a real card the client can render) but reflects something
/// noteworthy that happened server-side — not a client-facing error — is
/// signalled via this header, never via the status code or a body field.
/// The status code says "did the HTTP request succeed"; this says "here's
/// extra context about the answer," which a client may read, log, or
/// ignore. `conversation-recovered` is the first case; add values here
/// (not new headers) for future ones.
const _chatNoticeHeader = 'X-Chat-Notice';

/// Headers for an interaction envelope response, adding [_chatNoticeHeader]
/// when [messages] opens with a server notice (see `noticeCard` /
/// `_runInteraction`'s `notice` param) — including on an idempotent replay
/// of a stored interaction that carried one, so a retry sees the same
/// signal as the original call.
Map<String, String> _envelopeHeaders(List<Message> messages) {
  if (messages.isNotEmpty && messages.first.role == 'notice') {
    return {..._jsonHeaders, _chatNoticeHeader: 'conversation-recovered'};
  }
  return _jsonHeaders;
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': '*',
  'Access-Control-Allow-Headers': '*',
};

Middleware _cors() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

Response _error(int status, String detail) => Response(
  status,
  body: jsonEncode({'detail': detail}),
  headers: _jsonHeaders,
);

/// Selects the responder for this process: Ollama if a URL is set, else
/// echo.
Responder buildResponder({
  required String model,
  required String defaultSystemPromptPath,
  required String cardSchemaPath,
  required String defaultSeedCardPath,
  String? ollamaUrl,
  String? systemPromptFile,
  String? seedCardFile,
  bool seedCard = true,
  int numCtx = defaultNumCtx,
  int historyTurns = defaultHistoryTurns,
  String jsonFormat = defaultJsonFormat,
  String keepAlive = defaultKeepAlive,
  Duration ollamaTimeout = const Duration(
    seconds: defaultOllamaTimeoutSeconds,
  ),
  double? temperature = defaultCardTemperature,
}) {
  if (ollamaUrl != null && ollamaUrl.isNotEmpty) {
    _log.info(
      'Responder: OllamaResponder (url=$ollamaUrl, model=$model, '
      // bin/server.dart always passes an explicit file, so the fallback is
      // only reached by programmatic callers (the tests). Naming a specific
      // prompt here would be a guess.
      'system_prompt=${systemPromptFile ?? "caller-supplied default"}, '
      'num_ctx=$numCtx, '
      'history_turns=$historyTurns, json_format=$jsonFormat, '
      'keep_alive=$keepAlive, timeout=${ollamaTimeout.inSeconds}s, '
      'temperature=${temperature ?? "model default"})',
    );
    return OllamaResponder(
      ollamaUrl: ollamaUrl,
      model: model,
      defaultSystemPromptPath: defaultSystemPromptPath,
      cardSchemaPath: cardSchemaPath,
      defaultSeedCardPath: defaultSeedCardPath,
      systemPromptFile: systemPromptFile,
      seedCardFile: seedCardFile,
      seedCard: seedCard,
      numCtx: numCtx,
      historyTurns: historyTurns,
      jsonFormat: jsonFormat,
      keepAlive: keepAlive,
      ollamaTimeout: ollamaTimeout,
      temperature: temperature,
    );
  }
  // Reached via --echo, or by a caller passing a null URL directly. Saying
  // "no --ollama-url set" would be wrong now that the URL has a default.
  _log.info('Responder: EchoResponder (echo demo — no model is called)');
  return EchoResponder();
}

/// Replays a conversation as alternating user/assistant turns for the model.
///
/// Exchanges whose reply was a failure diagnostic are dropped **whole**: the
/// model must not read "(Ollama unreachable …)" as something it once said,
/// and replaying the user's question without an answer would leave it an
/// unanswered turn to explain. The interaction itself is kept — it happened,
/// and the client can still replay it.
List<(String, String)> _historyFor(Conversation conversation) {
  final history = <(String, String)>[];
  for (final priorIid in conversation.order) {
    final prior = conversation.interactions[priorIid]!;
    if (!prior.ok) continue;
    history
      ..add(('user', prior.text))
      ..add(('assistant', prior.replyText));
  }
  return history;
}

/// Runs one interaction end to end and stores it, returning its bubbles.
///
/// [notice], when set, is prepended ahead of the user/assistant bubbles and
/// stored as part of the interaction — see the unknown-conversation
/// auto-vivify branch in `buildHandler`, which sets it exactly once, on the
/// interaction that discovers the conversation is gone.
Future<List<Message>> _runInteraction({
  required ConversationStore store,
  required Responder responder,
  required String cid,
  required String interactionId,
  required String message,
  String userLabel = defaultUserLabel,
  String assistantLabel = defaultAssistantLabel,
  Message? notice,
}) async {
  final reply = await responder.reply(message, _historyFor(store.get(cid)!));
  final assistantCard = reply.cardBody != null
      ? assistantCardBubble(reply.cardBody!, label: assistantLabel)
      : assistantBubble(reply.text, label: assistantLabel);
  final messages = [
    ?notice,
    Message(
      role: 'user',
      card: userBubble(message, label: userLabel),
    ),
    Message(role: 'assistant', card: assistantCard),
  ];
  store.addInteraction(
    cid,
    Interaction(
      interactionId: interactionId,
      text: message,
      messages: messages,
      replyText: reply.text,
      stats: reply.stats,
      ok: reply.ok,
    ),
  );
  return messages;
}

/// Builds the shelf [Handler] serving the four Adaptive Chat routes.
///
/// [expiredConversationBodyItems] is the notice card body prepended when a
/// `POST .../interactions` targets a `conversationId` the store has lost
/// (e.g. a restart) — see the auto-vivify branch below. Defaults to
/// [fallbackExpiredConversationBodyItems]; `bin/server.dart` passes the
/// bundled asset instead.
Handler buildHandler({
  required ConversationStore store,
  required Responder responder,
  List<Map<String, dynamic>> expiredConversationBodyItems =
      fallbackExpiredConversationBodyItems,
}) {
  // Interactions currently inside `responder.reply`, keyed `cid|iid`. The
  // stored-envelope check alone cannot make a retry idempotent: nothing is
  // stored until the responder returns, so a client that gives up waiting
  // and re-sends would run the model a second time. Joining the in-flight
  // call instead means the retry waits for — and answers with — the first
  // result. Entries are removed once the call settles.
  final inFlight = <String, Future<List<Message>>>{};

  final router = Router()
    ..post('/conversations', (Request request) async {
      final rawBody = await request.readAsString();
      final body = rawBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(rawBody) as Map<String, dynamic>;
      final conv = store.create(
        userLabel: body['userLabel'] as String? ?? defaultUserLabel,
        assistantLabel:
            body['assistantLabel'] as String? ?? defaultAssistantLabel,
        language: body['language'] as String?,
      );
      final cid = conv.conversationId;
      return Response.ok(
        jsonEncode({
          'conversationId': cid,
          'links': {'postNext': '/conversations/$cid/interactions'},
        }),
        headers: _jsonHeaders,
      );
    })
    ..post('/conversations/<cid>/interactions', (
      Request request,
      String cid,
    ) async {
      final interactionId = request.headers['x-interaction-id'];
      if (interactionId == null || interactionId.isEmpty) {
        return _error(400, 'X-Interaction-Id header required');
      }
      // A restart drops all conversations; a client resending to one it
      // still holds an id for would otherwise get a bare 404 with no
      // in-chat explanation. Auto-vivify a fresh Conversation under the
      // same id instead (default labels — the originals were lost too) and
      // carry on, so the transcript itself says what happened.
      var conv = store.get(cid);
      Message? expiredNotice;
      if (conv == null) {
        conv = store.create(conversationId: cid);
        expiredNotice = Message(
          role: 'notice',
          card: noticeCard(expiredConversationBodyItems),
        );
      }

      final existing = store.getInteraction(cid, interactionId);
      if (existing != null) {
        return Response.ok(
          jsonEncode(envelope(cid, interactionId, existing.messages)),
          headers: _envelopeHeaders(existing.messages),
        );
      }

      final rawBody = await request.readAsString();
      final body = rawBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(rawBody) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final message = data?['message'] as String?;
      if (message == null || message.isEmpty) {
        return _error(400, 'data.message required');
      }

      final key = '$cid|$interactionId';
      final List<Message> messages;
      final joined = inFlight[key];
      if (joined != null) {
        // A retry arrived while the first call is still running: wait for it
        // and answer with the same result instead of running the model again.
        messages = await joined;
      } else {
        final started = _runInteraction(
          store: store,
          responder: responder,
          cid: cid,
          interactionId: interactionId,
          message: message,
          userLabel: conv.userLabel,
          assistantLabel: conv.assistantLabel,
          notice: expiredNotice,
        );
        inFlight[key] = started;
        try {
          messages = await started;
        } finally {
          // `removeWhere`, not `remove`: the map's values are Futures, so
          // `remove` would hand back the very Future this function is
          // completing and read as a discarded async call.
          inFlight.removeWhere((k, _) => k == key);
        }
      }

      return Response.ok(
        jsonEncode(envelope(cid, interactionId, messages)),
        headers: _envelopeHeaders(messages),
      );
    })
    ..get('/conversations/<cid>/interactions/<iid>', (
      Request request,
      String cid,
      String iid,
    ) {
      if (store.get(cid) == null) {
        return _error(404, 'unknown conversation');
      }
      final interaction = store.getInteraction(cid, iid);
      if (interaction == null) {
        return _error(404, 'unknown interaction');
      }
      return Response.ok(
        jsonEncode(envelope(cid, iid, interaction.messages)),
        headers: _jsonHeaders,
      );
    })
    ..get('/status', (Request request) {
      const encoder = JsonEncoder.withIndent('  ');
      final body = '${encoder.convert(buildStatus(store, responder))}\n';
      return Response.ok(
        body,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

  return const Pipeline().addMiddleware(_cors()).addHandler(router.call);
}
