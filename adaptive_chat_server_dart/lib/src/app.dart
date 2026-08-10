/// shelf app: routes, CORS, and responder selection for the Adaptive Chat
/// backend (echo or Ollama responder).
library;

import 'dart:convert';

import 'package:adaptive_chat_server_dart/src/cards.dart';
import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:adaptive_chat_server_dart/src/status.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final _log = Logger('adaptive_chat_server_dart');

const _jsonHeaders = {'content-type': 'application/json'};

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
  String? ollamaUrl,
  String? systemPromptFile,
  int numCtx = defaultNumCtx,
  int historyTurns = defaultHistoryTurns,
  String jsonFormat = defaultJsonFormat,
}) {
  if (ollamaUrl != null && ollamaUrl.isNotEmpty) {
    _log.info(
      'Responder: OllamaResponder (url=$ollamaUrl, model=$model, '
      'system_prompt=${systemPromptFile ?? "default"}, num_ctx=$numCtx, '
      'history_turns=$historyTurns, json_format=$jsonFormat)',
    );
    return OllamaResponder(
      ollamaUrl: ollamaUrl,
      model: model,
      defaultSystemPromptPath: defaultSystemPromptPath,
      cardSchemaPath: cardSchemaPath,
      systemPromptFile: systemPromptFile,
      numCtx: numCtx,
      historyTurns: historyTurns,
      jsonFormat: jsonFormat,
    );
  }
  _log.info('Responder: EchoResponder (no --ollama-url set)');
  return EchoResponder();
}

/// Builds the shelf [Handler] serving the four Adaptive Chat routes.
Handler buildHandler({
  required ConversationStore store,
  required Responder responder,
}) {
  final router = Router()
    ..post('/conversations', (Request request) {
      final conv = store.create();
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
      if (store.get(cid) == null) {
        return _error(404, 'unknown conversation');
      }

      final existing = store.getInteraction(cid, interactionId);
      if (existing != null) {
        return Response.ok(
          jsonEncode(envelope(cid, interactionId, existing.messages)),
          headers: _jsonHeaders,
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

      final conversation = store.get(cid)!;
      final history = <(String, String)>[];
      for (final priorIid in conversation.order) {
        final prior = conversation.interactions[priorIid]!;
        history
          ..add(('user', prior.text))
          ..add(('assistant', prior.replyText));
      }

      final reply = await responder.reply(message, history);
      final assistantCard = reply.cardBody != null
          ? assistantCardBubble(reply.cardBody!)
          : assistantBubble(reply.text);
      final messages = [
        Message(role: 'user', card: userBubble(message)),
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
        ),
      );
      return Response.ok(
        jsonEncode(envelope(cid, interactionId, messages)),
        headers: _jsonHeaders,
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
