import 'dart:convert';

/// Thrown when a backend response body exceeds the configured byte cap.
///
/// Backend invoke responses are attacker-influenced; decoding an unbounded
/// body risks memory exhaustion. Callers catch this to fail the invoke
/// gracefully instead of OOMing.
class AdaptiveJsonTooLargeException implements Exception {
  /// Records the [maxBytes] cap that the body exceeded.
  const AdaptiveJsonTooLargeException(this.maxBytes);

  /// The byte cap that was exceeded.
  final int maxBytes;

  @override
  String toString() =>
      'AdaptiveJsonTooLargeException: response exceeded $maxBytes bytes';
}

/// Decodes [body] as a JSON object, rejecting bodies larger than [maxBytes].
///
/// Enforces the size cap on the UTF-8 byte length before decoding, then
/// requires the result to be a JSON object. Throws
/// [AdaptiveJsonTooLargeException] when oversized and [FormatException] when the
/// payload is not a JSON object.
Map<String, dynamic> decodeJsonMapWithLimit(
  String body, {
  int maxBytes = 1024 * 1024,
}) {
  final byteLength = utf8.encode(body).length;
  if (byteLength > maxBytes) {
    throw AdaptiveJsonTooLargeException(maxBytes);
  }
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object');
  }
  return decoded;
}
