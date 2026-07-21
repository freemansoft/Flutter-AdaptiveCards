import 'dart:convert';

import 'package:adaptive_chat_client/src/chat_models.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:http/http.dart' as http;

export 'package:adaptive_chat_client/src/chat_models.dart';

/// Talks to the Adaptive Chat backend.
///
/// Reuses `flutter_adaptive_cards_host_fs` request serialization
/// (`AdaptiveCardInvokeRequest.fromSubmit` + `PlainJsonInvokeAdapter.toMap`)
/// for the send body, then parses the chat envelope itself (the response is a
/// list of cards to append, not an invoke-effect patch).
class ChatBackendClient {
  /// Creates a client posting to [baseUrl]; inject [client] in tests.
  ChatBackendClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Base URL of the backend (e.g. `http://localhost:8000`).
  final Uri baseUrl;

  final http.Client _client;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  /// Starts a conversation and returns its id + first `postNext`.
  Future<ChatStart> startConversation() async {
    final resp = await _client.post(
      baseUrl.resolve('/conversations'),
      headers: _jsonHeaders,
    );
    if (resp.statusCode != 200) {
      throw ChatBackendException('start failed: HTTP ${resp.statusCode}');
    }
    return ChatStart.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Sends one interaction and returns the response envelope.
  Future<ChatEnvelope> sendInteraction({
    required String postNext,
    required String interactionId,
    required SubmitActionInvoke invoke,
  }) async {
    final request = AdaptiveCardInvokeRequest.fromSubmit(invoke);
    final body = PlainJsonInvokeAdapter.toMap(request);
    final resp = await _client.post(
      baseUrl.resolve(postNext),
      headers: {..._jsonHeaders, 'X-Interaction-Id': interactionId},
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw ChatBackendException('send failed: HTTP ${resp.statusCode}');
    }
    return ChatEnvelope.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }
}
