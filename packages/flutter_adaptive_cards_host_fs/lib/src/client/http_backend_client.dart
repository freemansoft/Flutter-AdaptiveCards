import 'dart:convert';

import 'package:flutter_adaptive_cards_host_fs/src/client/backend_client.dart';
import 'package:http/http.dart' as http;

/// HTTP POST implementation of [AdaptiveCardBackendClient].
class HttpAdaptiveCardBackendClient implements AdaptiveCardBackendClient {
  /// Creates a client that POSTs JSON to [endpoint].
  ///
  /// Optional [client] supports tests; [headers] are merged with
  /// `Content-Type: application/json`.
  HttpAdaptiveCardBackendClient({
    required this.endpoint,
    http.Client? client,
    Map<String, String> headers = const {},
  }) : _client = client ?? http.Client(),
       _headers = {
         'Content-Type': 'application/json',
         ...headers,
       };

  /// Invoke URL for the flow-service or bot endpoint.
  final Uri endpoint;

  final http.Client _client;
  final Map<String, String> _headers;

  /// Transport hook for `AdaptiveCardBackendHandlers`; implement to POST invoke
  /// JSON and supply the decoded response map (throws
  /// [AdaptiveCardBackendException] on failure).
  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    final response = await _client.post(
      endpoint,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdaptiveCardBackendException(
        'HTTP ${response.statusCode}',
        body: response.body,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
