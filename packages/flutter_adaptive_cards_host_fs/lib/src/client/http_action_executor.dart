import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/client/backend_client.dart';
import 'package:http/http.dart' as http;

/// Result of executing an [HttpActionInvoke] request.
///
/// Carries the raw transport outcome so the backend handlers can interpret the
/// Outlook Actionable Messages response conventions (`CARD-UPDATE-IN-BODY`,
/// `CARD-ACTION-STATUS`).
class AdaptiveHttpResult {
  /// Creates a result with [statusCode], lower-cased [headers], and [body].
  const AdaptiveHttpResult({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  /// HTTP status code returned by the endpoint.
  final int statusCode;

  /// Response headers with lower-cased names (as `package:http` returns them).
  final Map<String, String> headers;

  /// Response body as text.
  final String body;

  /// Whether [statusCode] is in the 2xx success range.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Executes a card-authored `Action.Http` request.
///
/// **Deprecated/legacy:** `Action.Http` was the original Adaptive Cards HTTP
/// action model (schema v1.0), superseded by `Action.Execute` (Universal Action
/// Model, schema v1.4); still used by Outlook Actionable Messages.
/// Unlike [AdaptiveCardBackendClient], which posts to a single preconfigured
/// endpoint, the request target, method, headers, and body all come from the
/// card via [HttpActionInvoke].
abstract class AdaptiveHttpExecutor {
  /// Performs the request described by [invoke] and returns its result.
  Future<AdaptiveHttpResult> execute(HttpActionInvoke invoke);
}

/// Default [AdaptiveHttpExecutor] built on `package:http`.
class HttpAdaptiveHttpExecutor implements AdaptiveHttpExecutor {
  /// Creates an executor; pass [client] in tests.
  ///
  /// [maxResponseBytes] caps the response body length read into memory
  /// (default 1 MiB) to bound exposure to untrusted endpoints.
  HttpAdaptiveHttpExecutor({
    http.Client? client,
    this.maxResponseBytes = 1024 * 1024,
  }) : _client = client ?? http.Client();

  /// Maximum response body length, in bytes.
  final int maxResponseBytes;

  final http.Client _client;

  @override
  Future<AdaptiveHttpResult> execute(HttpActionInvoke invoke) async {
    final uri = Uri.parse(invoke.url);
    final headers = <String, String>{
      for (final header in invoke.headers) header.name: header.value,
    };

    final http.Response response;
    if (invoke.method == 'POST') {
      response = await _client.post(uri, headers: headers, body: invoke.body);
    } else {
      response = await _client.get(uri, headers: headers);
    }

    final body = response.bodyBytes.length > maxResponseBytes
        ? throw AdaptiveCardBackendException(
            'Action.Http response exceeded $maxResponseBytes bytes',
          )
        : response.body;

    return AdaptiveHttpResult(
      statusCode: response.statusCode,
      headers: {
        for (final entry in response.headers.entries)
          entry.key.toLowerCase(): entry.value,
      },
      body: body,
    );
  }
}
