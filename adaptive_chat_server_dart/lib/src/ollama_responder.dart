/// Responder that calls a local Ollama chat model over HTTP.
///
/// Opt-in: only constructed when the server is started with `--ollama-url`.
/// Never raises to the caller — on any failure it logs the full context and
/// returns a short diagnostic string, so a missing/unreachable/misconfigured
/// Ollama never crashes a request.
library;

import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('adaptive_chat_server_dart.ollama');

/// qwen2.5-coder:7b is the recommended default: it cleared every documented
/// card failure mode at temperature 0 and fits a 16 GB Mac.
const defaultOllamaModel = 'qwen2.5-coder:7b';

/// Prior interactions (user+assistant exchanges) replayed to Ollama by
/// default. Bounds only the outbound prompt — the server store keeps full
/// history.
const defaultHistoryTurns = 10;

/// Context window (tokens) requested from Ollama via `options.num_ctx`.
const defaultNumCtx = 16384;

/// `none` (prompt-only), `json` (generic valid-JSON grammar), or `schema`
/// (grammar-constrained against the bundled card schema).
const defaultJsonFormat = 'none';

/// Sampling temperature sent on every Ollama request. 0 = deterministic
/// decoding, the highest-leverage setting for minimizing malformed card
/// JSON.
const defaultCardTemperature = 0.0;

Map<String, dynamic>? _loadCardSchema(String path) {
  Map<String, dynamic> schema;
  try {
    schema = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    _log.severe(
      'Card schema unusable (invalid JSON: $e) at $path — '
      'falling back to json_format=none for this process.',
    );
    return null;
  } on IOException catch (e) {
    _log.severe(
      'Card schema unusable ($e) at $path — falling back to '
      'json_format=none for this process.',
    );
    return null;
  }
  if (!schema.containsKey('oneOf') || !schema.containsKey(r'$defs')) {
    _log.severe(
      "Card schema at $path missing expected 'oneOf'/'\$defs' "
      'keys — falling back to json_format=none for this process.',
    );
    return null;
  }
  return schema;
}

/// A JSON object had a repeated key at the same nesting level.
///
/// Legal JSON syntax, but `jsonDecode` silently keeps only the last value
/// for a repeated key. Observed against a real Ollama under
/// schema-constrained decoding: the model sometimes re-emits an object
/// property key (e.g. Carousel's `pages`, Table's `rows`) once per item
/// instead of appending items to one array.
class DuplicateJsonKeyException implements Exception {
  /// Creates an exception naming the [key] that was repeated.
  DuplicateJsonKeyException(this.key);

  /// The JSON object key that was repeated within one object literal.
  final String key;

  @override
  String toString() => 'duplicate key "$key"';
}

/// Minimal scanner (not a full parser) that throws
/// [DuplicateJsonKeyException] if any JSON object literal in [text] repeats
/// a key at its own nesting level. Assumes [text] is syntactically valid
/// JSON (validated separately via [jsonDecode]); it only needs to track
/// string boundaries and `{}`/`[]` nesting to find key positions.
void checkNoDuplicateJsonKeys(String text) {
  final containers = <String>[];
  final keySets = <Set<String>>[];
  var expectKey = false;
  var i = 0;
  while (i < text.length) {
    final ch = text[i];
    switch (ch) {
      case '"':
        final start = i + 1;
        i++;
        while (i < text.length && text[i] != '"') {
          if (text[i] == r'\') i++;
          i++;
        }
        final value = text.substring(start, i);
        i++; // consume closing quote
        if (expectKey && containers.isNotEmpty && containers.last == '{') {
          if (!keySets.last.add(value)) {
            throw DuplicateJsonKeyException(value);
          }
          expectKey = false;
        }
        continue;
      case '{':
        containers.add('{');
        keySets.add(<String>{});
        expectKey = true;
        i++;
        continue;
      case '[':
        containers.add('[');
        keySets.add(<String>{});
        expectKey = false;
        i++;
        continue;
      case '}':
      case ']':
        if (containers.isNotEmpty) {
          containers.removeLast();
          keySets.removeLast();
        }
        i++;
        continue;
      case ',':
        if (containers.isNotEmpty && containers.last == '{') {
          expectKey = true;
        }
        i++;
        continue;
      default:
        i++;
    }
  }
}

/// Calls `POST {ollamaUrl}/api/chat` with the conversation history.
class OllamaResponder implements Responder {
  /// Configures the responder.
  ///
  /// [defaultSystemPromptPath] and [cardSchemaPath] are resolved once by the
  /// caller (not internally via `Platform.script`) — see the deviation note
  /// in the task brief. The system-prompt file *path* is stored (not its
  /// contents), so edits to the file take effect on the next request without
  /// restarting the server.
  OllamaResponder({
    required String ollamaUrl,
    required String defaultSystemPromptPath,
    required String cardSchemaPath,
    String model = defaultOllamaModel,
    http.Client? client,
    String? systemPromptFile,
    int historyTurns = defaultHistoryTurns,
    int numCtx = defaultNumCtx,
    String jsonFormat = defaultJsonFormat,
  }) : // Field names are prefixed with `_` while the required constructor
       // param names (fixed by the public API contract) are not, so an
       // initializing formal isn't available here.
       // ignore: prefer_initializing_formals
       _ollamaUrl = ollamaUrl,
       // Same reason as _ollamaUrl above.
       // ignore: prefer_initializing_formals
       _model = model,
       _client = client ?? http.Client(),
       // Same reason as _ollamaUrl above.
       // ignore: prefer_initializing_formals
       _historyTurns = historyTurns,
       // Same reason as _ollamaUrl above.
       // ignore: prefer_initializing_formals
       _numCtx = numCtx,
       _systemPromptPath = systemPromptFile ?? defaultSystemPromptPath,
       _jsonFormat = jsonFormat,
       _requestedJsonFormat = jsonFormat {
    if (_jsonFormat == 'schema') {
      _cardSchema = _loadCardSchema(cardSchemaPath);
      if (_cardSchema == null) {
        _jsonFormat = 'none';
      }
    }
  }

  final String _ollamaUrl;
  final String _model;
  final http.Client _client;
  final int _historyTurns;
  final int _numCtx;
  final String _systemPromptPath;
  final String _requestedJsonFormat;
  String _jsonFormat;
  Map<String, dynamic>? _cardSchema;

  @override
  Map<String, dynamic> describe() {
    final config = <String, dynamic>{
      'kind': 'ollama',
      'url': _ollamaUrl,
      'model': _model,
      'numCtx': _numCtx,
      'historyTurns': _historyTurns,
      'jsonFormat': _jsonFormat,
      'systemPromptFile': p.basename(_systemPromptPath),
    };
    if (_requestedJsonFormat != _jsonFormat) {
      config['jsonFormatRequested'] = _requestedJsonFormat;
    }
    return config;
  }

  String? _loadSystemPrompt() {
    String prompt;
    try {
      prompt = File(_systemPromptPath).readAsStringSync().trim();
    } on IOException catch (e) {
      _log.warning(
        'System prompt file unreadable ($e) at $_systemPromptPath '
        '— sending no system message.',
      );
      return null;
    }
    if (prompt.isEmpty) {
      _log.warning(
        'System prompt file is empty at $_systemPromptPath — '
        'sending no system message.',
      );
      return null;
    }
    return prompt;
  }

  List<(String, String)> _trimHistory(List<(String, String)> history) {
    if (_historyTurns <= 0) return const [];
    final keep = 2 * _historyTurns;
    return history.length <= keep
        ? history
        : history.sublist(history.length - keep);
  }

  void _logContextFill(Map<String, dynamic> data) {
    final promptTokens = data['prompt_eval_count'];
    if (promptTokens is! int || _numCtx <= 0) return;
    final pct = promptTokens / _numCtx;
    if (pct >= 0.76) {
      _log.warning(
        'Ollama context near limit: prompt=$promptTokens/$_numCtx '
        '(${(pct * 100).toStringAsFixed(0)}%) — Ollama silently drops '
        'oldest tokens above num_ctx; lower --history-turns or raise '
        '--num-ctx.',
      );
    } else if (pct >= 0.50) {
      _log.info(
        'Ollama context filling: prompt=$promptTokens/$_numCtx '
        '(${(pct * 100).toStringAsFixed(0)}%).',
      );
    }
  }

  @override
  Future<Reply> reply(String text, List<(String, String)> history) async {
    final messages = <Map<String, String>>[];
    final systemPrompt = _loadSystemPrompt();
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final (role, content) in _trimHistory(history)) {
      messages.add({'role': role, 'content': content});
    }
    messages.add({'role': 'user', 'content': text});

    final endpoint = '$_ollamaUrl/api/chat';
    final options = <String, dynamic>{
      'num_ctx': _numCtx,
      'temperature': defaultCardTemperature,
    };
    final payload = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'stream': false,
      'options': options,
      'think': false,
    };
    if (_jsonFormat == 'json') {
      payload['format'] = 'json';
    } else if (_jsonFormat == 'schema') {
      payload['format'] = _cardSchema;
    }

    _log.info(
      'Ollama request: POST $endpoint (model=$_model, '
      '${messages.length} messages)',
    );

    http.Response response;
    try {
      response = await _client.post(
        Uri.parse(endpoint),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(payload),
      );
    } on Object catch (exc) {
      _log.severe(
        'Ollama CONNECTION FAILED: $exc\n  endpoint=$endpoint '
        'model=$_model\n  Is `ollama serve` running and listening there? '
        'On macOS, `localhost` can resolve to IPv6 (::1) while Ollama '
        'binds IPv4 127.0.0.1 — try --ollama-url http://127.0.0.1:11434.',
      );
      return Reply(
        text: '(Ollama unreachable at $_ollamaUrl — ${exc.runtimeType}: $exc)',
      );
    }

    if (response.statusCode >= 400) {
      final body = response.body.length > 1000
          ? response.body.substring(0, 1000)
          : response.body;
      _log.severe(
        'Ollama HTTP ${response.statusCode} for $endpoint '
        '(model=$_model):\n  $body\n  A 404 usually means the model '
        "isn't pulled — run `ollama pull $_model`.",
      );
      return Reply(
        text:
            '(Ollama error HTTP ${response.statusCode} at $_ollamaUrl: $body)',
      );
    }

    Map<String, dynamic> data;
    String content;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
      content = (data['message'] as Map<String, dynamic>)['content'] as String;
    } on Object catch (exc) {
      final body = response.body.length > 1000
          ? response.body.substring(0, 1000)
          : response.body;
      _log.severe('Ollama response could not be parsed ($exc):\n  $body');
      return Reply(
        text: '(Ollama returned an unexpected response: ${exc.runtimeType})',
      );
    }
    _logContextFill(data);
    final stats = fromOllamaResponse(data);

    var replyText = content;
    List<Map<String, dynamic>>? cardBody;
    var usedFormatPath = false;
    var duplicateKeyDetected = false;
    if (_jsonFormat != 'none') {
      try {
        checkNoDuplicateJsonKeys(content);
        final parsed = jsonDecode(content);
        usedFormatPath = true;
        if (parsed is String) {
          replyText = parsed;
        } else {
          cardBody = tryParseCardBody(jsonEncode(parsed));
        }
      } on DuplicateJsonKeyException {
        duplicateKeyDetected = true;
      } on FormatException {
        // Unexpected: format guarantee failed; fall through to the generic
        // detection path below, same as the raw-content path would.
      }
    }
    if (!usedFormatPath && !duplicateKeyDetected) {
      cardBody = tryParseCardBody(content);
    }

    if (duplicateKeyDetected) {
      _log.warning(
        'Model reply had a duplicate JSON object key (model=$_model, '
        '${content.length} chars) — rendered as text instead, since a '
        'repeated key silently drops all but its last value. Reason: '
        'duplicate key in JSON object',
      );
    } else if (cardBody == null) {
      final reason = cardParseFailureReason(content);
      if (reason != null) {
        _log.warning(
          'Model reply looked like an Adaptive Card but was not '
          'usable (model=$_model, ${content.length} chars) — rendered as '
          'text instead. Reason: $reason',
        );
      }
    }
    _log.fine(
      'Ollama content (model=$_model, ${content.length} chars, '
      'detected_card=${cardBody != null}):\n$content',
    );
    return Reply(text: replyText, cardBody: cardBody, stats: stats);
  }
}
