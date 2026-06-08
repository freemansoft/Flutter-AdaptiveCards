/// Posts serialized invoke requests to a backend service.
abstract class AdaptiveCardBackendClient {
  /// POST [body] as JSON and return the decoded response map.
  Future<Map<String, dynamic>> post(Map<String, dynamic> body);
}

/// Thrown when [AdaptiveCardBackendClient.post] fails.
class AdaptiveCardBackendException implements Exception {
  /// Creates an exception with [message] and optional raw response [body].
  AdaptiveCardBackendException(this.message, {this.body});

  /// Short failure description (for example HTTP status).
  final String message;

  /// Raw response body when the server returned an error payload.
  final String? body;

  @override
  String toString() => 'AdaptiveCardBackendException: $message';
}
