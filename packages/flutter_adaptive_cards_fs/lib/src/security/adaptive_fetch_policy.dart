/// Thrown when a remote response body exceeds [AdaptiveFetchPolicy.maxBytes].
///
/// Card-initiated fetches (remote card JSON, `Action.OpenUrlDialog` content)
/// read attacker-influenced response bodies. This exception lets callers abort
/// before materializing an unbounded body, capping memory/DoS exposure.
class AdaptiveFetchTooLargeException implements Exception {
  /// Creates an exception recording the [maxBytes] cap that was exceeded.
  const AdaptiveFetchTooLargeException(this.maxBytes);

  /// The byte cap that the response body exceeded.
  final int maxBytes;

  @override
  String toString() =>
      'AdaptiveFetchTooLargeException: exceeded $maxBytes bytes';
}

/// Limits applied to card-initiated HTTP GETs.
///
/// Bundles the response-size cap ([maxBytes]) and request [timeout] used when a
/// card causes the renderer to fetch remote content. Use [standard] unless a
/// host needs different bounds.
class AdaptiveFetchPolicy {
  /// Creates a fetch policy with an optional [maxBytes] cap and [timeout].
  const AdaptiveFetchPolicy({
    this.maxBytes = 1024 * 1024,
    this.timeout = const Duration(seconds: 15),
  });

  /// Default policy: 1 MiB body cap, 15-second timeout.
  static const standard = AdaptiveFetchPolicy();

  /// Maximum response body size, in bytes.
  final int maxBytes;

  /// Maximum time to wait for a card-initiated fetch.
  final Duration timeout;
}

/// Returns [body] unchanged when within [maxBytes], otherwise throws
/// [AdaptiveFetchTooLargeException].
///
/// Centralizes the size check so every card-initiated fetch enforces the cap
/// the same way.
List<int> readBodyWithLimit(List<int> body, int maxBytes) {
  if (body.length > maxBytes) {
    throw AdaptiveFetchTooLargeException(maxBytes);
  }
  return body;
}
