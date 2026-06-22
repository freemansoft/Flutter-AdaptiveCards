import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';

/// Validates card-controlled URLs before they are launched or fetched.
///
/// Adaptive Card JSON is untrusted input. A card can carry an
/// `Action.OpenUrl`, a markdown link, an `Action.OpenUrlDialog` source, or a
/// remote card URL pointing at anything — including `javascript:` payloads or
/// private-network addresses that enable SSRF. [AdaptiveUriPolicy] is the
/// single chokepoint those URLs pass through: it enforces a scheme allowlist
/// and (for `http`/`https`) blocks loopback and private-network hosts unless
/// the host app explicitly opts in.
///
/// Use [standard] in production and [development] for local dev servers and
/// widget tests. Construct a custom instance to permit extra schemes (e.g.
/// `mailto`, `tel`) or to pin an [allowedHosts] allowlist.
class AdaptiveUriPolicy {
  /// Creates a policy.
  ///
  /// By default only `https`/`http` are allowed and loopback/private hosts are
  /// rejected. Set [allowLoopback] / [allowPrivateHosts] for dev scenarios, add
  /// schemes to [allowedSchemes] to permit protocols like `mailto`/`tel`, or
  /// pass [allowedHosts] to restrict to an explicit host allowlist.
  const AdaptiveUriPolicy({
    this.allowedSchemes = const {'https', 'http'},
    this.allowLoopback = false,
    this.allowPrivateHosts = false,
    this.allowedHosts,
  });

  /// Default production policy: `https`/`http` only, no private networks.
  static const standard = AdaptiveUriPolicy();

  /// Relaxed policy for local widget tests and dev servers (permits loopback
  /// and private hosts). Do not use in production.
  static const development = AdaptiveUriPolicy(
    allowLoopback: true,
    allowPrivateHosts: true,
  );

  /// Schemes permitted (compared case-insensitively).
  final Set<String> allowedSchemes;

  /// Whether loopback hosts (`localhost`, `127.0.0.0/8`, `::1`) are permitted.
  final bool allowLoopback;

  /// Whether RFC1918 / link-local private hosts are permitted.
  final bool allowPrivateHosts;

  /// When non-null, only these hosts (case-insensitive) are permitted.
  final Set<String>? allowedHosts;

  /// Validates [url] against this policy.
  ///
  /// Returns [AdaptiveUriAllowed] with the parsed URI on success, or
  /// [AdaptiveUriDenied] with a safe-to-log reason on rejection. Never throws.
  AdaptiveUriValidationResult validate(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return const AdaptiveUriDenied('URL is empty');
    }

    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on Object {
      return const AdaptiveUriDenied('URL is not parseable');
    }

    final scheme = uri.scheme.toLowerCase();
    if (!allowedSchemes.contains(scheme)) {
      return AdaptiveUriDenied('URL scheme "$scheme" is not allowed');
    }

    final host = uri.host.toLowerCase();
    final isHttpOrHttps = scheme == 'http' || scheme == 'https';
    if (isHttpOrHttps && host.isEmpty) {
      return const AdaptiveUriDenied('URL host is missing');
    }

    if (host.isNotEmpty) {
      if (allowedHosts != null && !allowedHosts!.contains(host)) {
        return AdaptiveUriDenied('Host "$host" is not in the allowlist');
      }

      if (!allowLoopback && _isLoopback(host)) {
        return const AdaptiveUriDenied('Host is a loopback address; blocked');
      }

      if (!allowPrivateHosts && _isPrivateHost(host)) {
        return const AdaptiveUriDenied(
          'Host is a private network address; blocked',
        );
      }
    }

    return AdaptiveUriAllowed(uri);
  }

  bool _isLoopback(String host) {
    if (host == 'localhost') return true;
    if (host == '::1') return true;
    // IPv4 loopback 127.0.0.0/8.
    final parts = host.split('.');
    if (parts.length == 4) {
      final first = int.tryParse(parts[0]);
      if (first == 127) return true;
    }
    return false;
  }

  bool _isPrivateHost(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((o) => o == null || o < 0 || o > 255)) return false;
    final a = octets[0]!;
    final b = octets[1]!;
    if (a == 10) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 192 && b == 168) return true;
    if (a == 169 && b == 254) return true; // link-local
    return false;
  }
}
