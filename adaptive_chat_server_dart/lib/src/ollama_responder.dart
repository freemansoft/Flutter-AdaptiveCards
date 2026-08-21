/// Responder that calls a local Ollama chat model over HTTP.
///
/// Opt-in: only constructed when the server is started with `--ollama-url`.
/// Never raises to the caller — on any failure it logs the full context and
/// returns a short diagnostic string, so a missing/unreachable/misconfigured
/// Ollama never crashes a request.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:adaptive_chat_server_dart/src/seed_card.dart';
import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('adaptive_chat_server_dart.ollama');

/// qwen2.5-coder:7b is the recommended default: it cleared every documented
/// card failure mode at temperature 0 and fits a 16 GB Mac.
const defaultOllamaModel = 'qwen2.5-coder:7b';

/// Where the server looks for Ollama unless told otherwise.
///
/// IPv4 on purpose: Ollama binds IPv4 while macOS often resolves `localhost`
/// to IPv6 first, which surfaces as a connection refused that looks like
/// Ollama being down.
const defaultOllamaUrl = 'http://127.0.0.1:11434';

/// Prior interactions (user+assistant exchanges) replayed to Ollama by
/// default. Bounds only the outbound prompt — the server store keeps full
/// history.
const defaultHistoryTurns = 10;

/// Context window (tokens) requested from Ollama via `options.num_ctx`.
const defaultNumCtx = 16384;

/// `none` (prompt-only), `json` (generic valid-JSON grammar), or `schema`
/// (grammar-constrained against the bundled card schema).
const defaultJsonFormat = 'none';

/// Sampling temperature sent on every Ollama request. 0 selects greedy
/// decoding, the highest-leverage setting for minimizing malformed card
/// JSON.
///
/// **Not a determinism guarantee.** Greedy decoding repeats short replies
/// verbatim, but long generations still diverge run to run (measured: a
/// ~3.5 K-character table produced two different outputs across three calls
/// at 0). What 0 does buy is the failure mode being *stable* — a card the
/// model gets wrong at 0 is usually wrong the same way on retry, so a broken
/// card never self-heals.
///
/// Override with `--ollama-temperature` when a model's own recommended
/// sampling settings suit it better; `--ollama-temperature model` sends no
/// temperature at all, leaving the model's Modelfile default in force.
/// Measured on `qwen3.6:27b-coding-nvfp4`, whose Modelfile ships 0.6, that
/// model's own default scored *worse* on card generation than 0 (9/15 vs
/// 12/15 on hard cases), mostly by truncating long JSON — so prefer 0 unless
/// a specific model measures better.
const defaultCardTemperature = 0.0;

/// How long Ollama keeps the model resident after a reply, as an Ollama
/// duration string.
///
/// Ollama's own default is 5 minutes, which is shorter than the gaps between
/// messages in a real conversation — so an idle chat pays a full model reload
/// on its next turn (measured: ~20x the warm load time). Holding the model
/// for longer trades idle RAM for a responsive chat.
const defaultKeepAlive = '30m';

/// Seconds to wait for one `/api/chat` reply before giving up.
///
/// Sized for a model **load**, not a model **download**: `/api/chat` never
/// pulls a missing model (it returns 404, which the startup preflight catches
/// first), so this budget only has to cover reading an already-present model
/// into memory plus generating one reply. Minutes-long pulls happen
/// out-of-band via `ollama pull` and are never waited on here.
///
/// Generous enough for a warm mid-size model on a laptop; a cold load of a
/// large model plus a full context window can still exceed it — raise
/// `--ollama-timeout` rather than assuming the server is unreachable.
const defaultOllamaTimeoutSeconds = 60;

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
    required String defaultSeedCardPath,
    String model = defaultOllamaModel,
    http.Client? client,
    String? systemPromptFile,
    String? seedCardFile,
    this.seedCard = true,
    int historyTurns = defaultHistoryTurns,
    int numCtx = defaultNumCtx,
    String jsonFormat = defaultJsonFormat,
    Duration ollamaTimeout = const Duration(
      seconds: defaultOllamaTimeoutSeconds,
    ),
    String keepAlive = defaultKeepAlive,
    double? temperature = defaultCardTemperature,
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
       _seedCardPath = seedCardFile ?? defaultSeedCardPath,
       _jsonFormat = jsonFormat,
       _requestedJsonFormat = jsonFormat,
       // Same reason as _ollamaUrl above.
       // ignore: prefer_initializing_formals
       _ollamaTimeout = ollamaTimeout,
       // Same reason as _ollamaUrl above.
       // ignore: prefer_initializing_formals
       _keepAlive = keepAlive,
       // Same reason as _ollamaUrl above.
       // ignore: prefer_initializing_formals
       _temperature = temperature {
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
  final String _seedCardPath;

  /// Whether to prepend the seed exchange ahead of the replayed history.
  ///
  /// On by default, because the seed is what every figure in
  /// `ModelBehavior.md` was measured against and turning it off silently
  /// would make the shipped configuration differ from the measured one.
  ///
  /// It is switchable because its value is strongly model-dependent rather
  /// than universal: measured across fifteen models it is worth **+10** shapes
  /// to `nemotron-3-nano:4b` and **+9** to `qwen3-coder:30b`, exactly nothing
  /// to `qwen2.5-coder:7b` and `qwen3.8:27b-nvfp4`, and **−2** to
  /// `gpt-oss:20b`, which is the only model to answer all 25 shape cases
  /// correctly and does so without it. A mechanism that ranges from essential
  /// to mildly harmful depending on the model is one a host should be able to
  /// turn off.
  final bool seedCard;
  final String _requestedJsonFormat;
  final Duration _ollamaTimeout;
  final String _keepAlive;

  /// `null` means send no `temperature`, so Ollama applies the model's own
  /// Modelfile value rather than one this server picked.
  final double? _temperature;
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
      'seedCard': seedCard,
      'seedCardFile': p.basename(_seedCardPath),
      // 0 means the seed failed to load — the warning says why. Surfaced
      // because a silently seedless server loses the measured drift
      // protection while looking healthy. Also 0 when the seed is switched
      // off, which `seedCard` distinguishes from a load failure.
      'seedCardTurns': seedCard
          ? loadSeedCardMessages(_seedCardPath).length
          : 0,
      'keepAlive': _keepAlive,
      'timeoutSeconds': _ollamaTimeout.inSeconds,
      'temperature': _temperature ?? 'model',
    };
    if (_requestedJsonFormat != _jsonFormat) {
      config['jsonFormatRequested'] = _requestedJsonFormat;
    }
    return config;
  }

  /// Asks Ollama for its model list and checks the configured model is there.
  ///
  /// `/api/tags` is the cheapest probe that distinguishes the two failures an
  /// operator actually hits — Ollama not running at all, versus running
  /// without the model pulled — which otherwise both surface as a failed
  /// first message. An untagged model name matches its `:latest` entry, the
  /// same way Ollama resolves it.
  @override
  Future<ResponderReadiness> checkReadiness() async {
    final endpoint = '$_ollamaUrl/api/tags';
    http.Response response;
    try {
      response = await _client
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 5));
    } on Object catch (exc) {
      return ResponderReadiness.notReady(
        'Ollama unreachable at $_ollamaUrl ($exc). Is `ollama serve` '
        'running? On macOS use 127.0.0.1, not localhost — Ollama binds '
        'IPv4 while localhost often resolves to IPv6 first.',
      );
    }
    if (response.statusCode != 200) {
      return ResponderReadiness.notReady(
        'Ollama at $_ollamaUrl answered HTTP ${response.statusCode} for '
        '/api/tags.',
      );
    }

    List<String> names;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      names = [
        for (final m in body['models']! as List)
          (m as Map<String, dynamic>)['name']! as String,
      ];
    } on Object {
      return ResponderReadiness.notReady(
        'Ollama at $_ollamaUrl returned an unreadable /api/tags body.',
      );
    }

    final wanted = _model.contains(':') ? _model : '$_model:latest';
    if (names.contains(_model) || names.contains(wanted)) {
      return ResponderReadiness.ready(
        'Ollama at $_ollamaUrl has $_model',
      );
    }
    return ResponderReadiness.notReady(
      'Ollama at $_ollamaUrl does not have $_model — run '
      '`ollama pull $_model`. Available: ${names.join(", ")}',
    );
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
    // Measured as candidate N2 — see seed_card.dart for what it is and what
    // it costs. Skipped entirely under --no-seed-card, which is not the
    // shipped default: the figures in ModelBehavior.md are seeded ones.
    if (seedCard) {
      for (final message in loadSeedCardMessages(_seedCardPath)) {
        messages.add({'role': message.role, 'content': message.content});
      }
    }
    for (final (role, content) in _trimHistory(history)) {
      messages.add({'role': role, 'content': content});
    }
    messages.add({'role': 'user', 'content': text});

    final endpoint = '$_ollamaUrl/api/chat';
    final options = <String, dynamic>{
      'num_ctx': _numCtx,
      // Omitted entirely when null: Ollama then falls back to the model's
      // own Modelfile temperature instead of one this server chose.
      if (_temperature != null) 'temperature': _temperature,
    };
    final payload = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'stream': false,
      'options': options,
      'think': false,
      'keep_alive': _keepAlive,
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
      response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_ollamaTimeout);
    } on TimeoutException {
      final seconds = _ollamaTimeout.inMilliseconds / 1000;
      _log.severe(
        'Ollama TIMED OUT after ${seconds}s: endpoint=$endpoint '
        'model=$_model\n  Ollama answered nothing in time — it is likely '
        'still loading the model or generating. A cold model load plus a '
        'large prompt can exceed the timeout; raise --ollama-timeout, lower '
        '--num-ctx or --history-turns, or use a smaller model.',
      );
      return Reply(
        text:
            '(Ollama timed out after ${seconds}s at $_ollamaUrl — it may '
            'still be loading the model or generating a long reply)',
        ok: false,
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
        ok: false,
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
        ok: false,
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
        ok: false,
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
        // Under a working grammar constraint invalid JSON is impossible, so
        // this means the constraint was not applied. Ollama accepts `format`
        // for every model but silently honors it on only some — without this
        // warning, `--json-format schema` looks like a safety net while
        // doing nothing at all.
        _log.warning(
          'Model returned invalid JSON despite format=$_jsonFormat '
          '(model=$_model) — the model may be ignoring the format '
          'constraint. Ollama applies it silently or not at all depending on '
          'the model; verify with a trivial format=json request, and treat '
          '--json-format as unavailable for this model if it is ignored.',
        );
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
