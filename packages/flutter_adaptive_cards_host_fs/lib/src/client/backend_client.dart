/// Posts serialized invoke requests to a backend service.
abstract class AdaptiveCardBackendClient {
  /// Transport hook for `AdaptiveCardBackendHandlers`; implement to POST invoke
  /// JSON and supply the decoded response map (throws
  /// [AdaptiveCardBackendException] on failure).
  Future<Map<String, dynamic>> post(Map<String, dynamic> body);
}

/// Thrown when [AdaptiveCardBackendClient.post] fails.
class AdaptiveCardBackendException(
  /// Short failure description (for example HTTP status).
  final String message, {

  /// Raw response body when the server returned an error payload.
  final String? body,
}) implements Exception {
  /// Creates an exception with [message] and optional raw response [body].
  this;

  @override
  String toString() => 'AdaptiveCardBackendException: $message';
}
