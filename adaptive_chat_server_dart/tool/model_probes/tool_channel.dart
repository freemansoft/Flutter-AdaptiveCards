/// The `render_adaptive_card` tool definition and the plumbing to call
/// through it, shared by `tool_call_probe.dart` and `shape_ab.dart`.
///
/// Two probes need to offer the same tool: `tool_call_probe.dart` asks
/// whether a model can use the tool channel at all, and `shape_ab.dart`'s
/// `--channel tool` asks whether the cards it returns that way are any good.
/// If each built its own copy of the tool definition, the two probes could
/// silently drift apart on what they offered — one adding a description
/// tweak the other never got — and a "supported" verdict from one would stop
/// meaning anything to the other. Defining it once here rules that out.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/ollama_responder.dart'
    show defaultNumCtx;

// Relative: this file and its callers live outside `lib/`, so there is no
// `package:` URI for them.
import 'probe_support.dart';

/// The card tool the server would offer, wrapping the schema's element array.
Map<String, dynamic> renderCardTool(Map<String, dynamic> schema) {
  final defs = schema[r'$defs'] as Map<String, dynamic>;
  return {
    'type': 'function',
    'function': {
      'name': 'render_adaptive_card',
      'description':
          'Render the reply as an Adaptive Card. Use when a structured '
          'input or layout helps the user.',
      'parameters': {
        'type': 'object',
        'required': ['body'],
        'properties': {'body': defs['ElementArray']},
      },
    },
  };
}

/// The arguments of the first call to [name] in [message], or null.
Map<String, dynamic>? toolCallArguments(
  Map<String, dynamic> message,
  String name,
) {
  final calls = message['tool_calls'];
  if (calls is! List) return null;
  for (final call in calls) {
    if (call is! Map<String, dynamic>) continue;
    final function = call['function'];
    if (function is! Map<String, dynamic>) continue;
    if (function['name'] != name) continue;
    final args = function['arguments'];
    // Ollama returns arguments already decoded; some builds return a string.
    if (args is Map<String, dynamic>) return args;
    if (args is String) {
      try {
        final decoded = jsonDecode(args);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        return null;
      }
    }
  }
  return null;
}

/// The string a prose-channel reply would have carried for this [message].
///
/// The whole point of the tool channel is that a card arrives as structured
/// arguments rather than as text the server must guess about. But every
/// scoring rule in this directory — `judgeShape`, `judgeReply`, the negative
/// control — is written against a reply *string*. Converting here means the
/// tool path reuses all of it instead of growing a parallel set of rules that
/// could drift out of agreement with the prose path it is being compared to.
///
/// A reply with no tool call passes its `content` through untouched, which is
/// what makes the negative control meaningful: declining to call the tool must
/// read as prose, not as an empty card.
String replyEquivalent(Map<String, dynamic> message, String toolName) {
  final args = toolCallArguments(message, toolName);
  if (args == null) {
    final content = message['content'];
    return content is String ? content : '';
  }
  final body = args['body'];
  // Absence is an empty reply, never the four characters `null`, which
  // tryParseCardBody would read as a scalar rather than as nothing.
  if (body == null) return '';
  return jsonEncode(body);
}

/// One `/api/chat` call that offers [tool], scored exactly as a prose reply.
///
/// Mirrors `probeOnce`'s contract so a caller can swap channels without
/// changing how it handles the result.
Future<ProbeOutcome> probeOnceViaTool({
  required HttpClient client,
  required String url,
  required String model,
  required String systemPrompt,
  required String userPrompt,
  required Map<String, dynamic> tool,
  List<String> history = const [],
  Map<String, dynamic> options = const {},
  Duration timeout = defaultProbeTimeout,
}) async {
  final started = DateTime.now();
  ProbeOutcome timedOut() => ProbeOutcome(
    ok: false,
    label: 'timeout (${timeout.inSeconds}s)',
    chars: 0,
    ms: DateTime.now().difference(started).inMilliseconds,
    hash: '-',
    reply: '',
  );

  final HttpClientRequest request;
  try {
    request = await client.postUrl(Uri.parse('$url/api/chat')).timeout(timeout);
  } on TimeoutException {
    return timedOut();
  }
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'model': model,
      'messages': buildProbeMessages(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        history: history,
      ),
      'stream': false,
      'think': false,
      'keep_alive': '30m',
      'options': {'num_ctx': defaultNumCtx, ...options},
      'tools': [tool],
    }),
  );

  final String rawBody;
  try {
    final response = await request.close().timeout(timeout);
    if (response.statusCode != 200) {
      final errorBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return ProbeOutcome(
        ok: false,
        label: 'HTTP ${response.statusCode}',
        chars: errorBody.length,
        ms: DateTime.now().difference(started).inMilliseconds,
        hash: '-',
        reply: errorBody,
      );
    }
    rawBody = await response.transform(utf8.decoder).join().timeout(timeout);
  } on TimeoutException {
    // abort() is what makes the bound real: without it a timed-out request
    // keeps its connection and a handful of them exhausts the pool.
    request.abort();
    return timedOut();
  }
  final ms = DateTime.now().difference(started).inMilliseconds;

  final Object? decoded;
  try {
    decoded = jsonDecode(rawBody);
  } on FormatException {
    return ProbeOutcome(
      ok: false,
      label: 'unexpected-response (body not JSON)',
      chars: rawBody.length,
      ms: ms,
      hash: '-',
      reply: rawBody,
    );
  }
  final message = decoded is Map<String, dynamic> ? decoded['message'] : null;
  if (message is! Map<String, dynamic>) {
    return ProbeOutcome(
      ok: false,
      label: 'unexpected-response (no message)',
      chars: rawBody.length,
      ms: ms,
      hash: '-',
      reply: rawBody,
    );
  }
  return judgeReply(replyEquivalent(message, 'render_adaptive_card'), ms);
}
