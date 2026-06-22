import 'dart:convert';

import 'package:flutter_adaptive_cards_host_fs/src/client/backend_client.dart';
import 'package:flutter_adaptive_cards_host_fs/src/security/bounded_json.dart';
import 'package:http/http.dart' as http;

/// HTTP POST implementation of [AdaptiveCardBackendClient].
class HttpAdaptiveCardBackendClient implements AdaptiveCardBackendClient {
  /// Creates a client that POSTs JSON to [endpoint].
  ///
  /// Optional [client] supports tests; [headers] are merged with
  /// `Content-Type: application/json`. The response body is capped at
  /// [maxResponseBytes] (default 1 MiB) to bound memory use on untrusted
  /// backend responses.
  HttpAdaptiveCardBackendClient({
    required this.endpoint,
    http.Client? client,
    Map<String, String> headers = const {},
    this.maxResponseBytes = 1024 * 1024,
  }) : _client = client ?? http.Client(),
       _headers = {
         'Content-Type': 'application/json',
         ...headers,
       };

  /// Invoke URL for the flow-service or bot endpoint.
  final Uri endpoint;

  /// Maximum decoded response body size, in bytes.
  final int maxResponseBytes;

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
    return decodeJsonMapWithLimit(response.body, maxBytes: maxResponseBytes);
  }
}
