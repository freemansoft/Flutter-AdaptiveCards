/// Outcome of `AdaptiveUriPolicy.validate`.
///
/// Use a `switch` over the sealed subtypes ([AdaptiveUriAllowed] /
/// [AdaptiveUriDenied]) so the compiler enforces handling of both the
/// allowed and denied cases before a card-controlled URL is launched or
/// fetched.
sealed class AdaptiveUriValidationResult {
  /// Shared constructor for allowed/denied validation outcomes.
  const AdaptiveUriValidationResult();
}

/// The validated URL passed every policy check.
///
/// Callers should launch or fetch [uri] rather than re-parsing the original
/// string, so the value that was validated is the value that is used.
class AdaptiveUriAllowed extends AdaptiveUriValidationResult {
  /// Wraps the parsed, policy-approved [uri].
  const AdaptiveUriAllowed(this.uri);

  /// The parsed URI that passed validation.
  final Uri uri;
}

/// The URL was rejected by policy.
///
/// [reason] is a short, human-readable explanation safe to surface in a debug
/// message or log — it never contains secrets.
class AdaptiveUriDenied extends AdaptiveUriValidationResult {
  /// Records why the URL was rejected.
  const AdaptiveUriDenied(this.reason);

  /// Safe-to-log explanation of the rejection.
  final String reason;
}

/// Thrown by fetch paths (e.g. remote card loaders) when a URL fails
/// `AdaptiveUriPolicy` validation and there is no UI affordance to report the
/// denial inline.
///
/// Surfaces the same [reason] string as [AdaptiveUriDenied] so callers can
/// present a consistent message.
class AdaptiveUriPolicyException implements Exception {
  /// Creates an exception describing why a URL was rejected.
  const AdaptiveUriPolicyException(this.reason);

  /// Safe-to-log explanation of the rejection.
  final String reason;

  @override
  String toString() => 'AdaptiveUriPolicyException: $reason';
}
