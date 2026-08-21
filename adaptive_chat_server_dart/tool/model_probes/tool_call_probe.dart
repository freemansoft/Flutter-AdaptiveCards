/// Checks whether a model can return an Adaptive Card through Ollama's
/// **tool channel** rather than the prose channel.
///
/// **Run this before building anything on tool calling.** Ollama accepts
/// `tools` for every model but applies it only for models whose chat
/// template supports it, and says nothing when it does not — the same silent
/// degradation `format` has, where `json_format_probe.dart` found one model
/// ignoring it harmlessly and another destructively.
///
/// Three checks, because one reply cannot tell the failures apart:
///   1. **positive** — a question that plainly wants a card; does the model
///      call `render_adaptive_card`, and do its arguments render?
///   2. **negative control** — a plain prose question; does it correctly
///      leave the tool alone? The seed already over-cards this exact control
///      on 5 of 15 models, so over-calling is a measured risk, not a guess.
///   3. **capability discriminator** — a trivial unrelated tool on a question
///      unanswerable without it. Without this, "declined to call" and "the
///      template never offered the tool" look identical.
///
/// Runs unseeded on purpose: the seed card is a prose-channel artifact, and
/// prepending it while asking for a tool call works against itself.
///
/// ```sh
/// fvm dart run tool/model_probes/tool_call_probe.dart \
///   --model qwen3-coder:30b --samples 2
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:path/path.dart' as p;

// Relative: this file and its helpers live outside `lib/`, so there is no
// `package:` URI for them.
import 'probe_results.dart';
import 'probe_support.dart';

const _cardPrompt =
    'What deployment targets can I choose from for this service?';
const _proseControlPrompt = 'What does SDUI stand for?';
const _trivialToolPrompt = 'What is the current temperature in Paris?';

/// The card tool the server would offer, wrapping the schema's element array.
Map<String, dynamic> _renderCardTool(Map<String, dynamic> schema) {
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

/// A tool no card prompt mentions, used only to prove the model *can* call
/// something. Deliberately additive and prompt-compatible: an earlier probe
/// that asked models to contradict their system prompt produced a null on
/// every model and proved nothing.
const Map<String, dynamic> _trivialTool = {
  'type': 'function',
  'function': {
    'name': 'get_current_temperature',
    'description': 'Get the current temperature for a city.',
    'parameters': {
      'type': 'object',
      'required': ['city'],
      'properties': {
        'city': {'type': 'string'},
      },
    },
  },
};

/// How a model handled the tool channel.
enum ToolVerdict {
  /// Calls tools, reaches for the card tool, and its arguments render.
  supported,

  /// Cannot call tools at all — the chat template has no tool support.
  unsupported,

  /// Can call tools, but never produces a renderable card through one.
  supportedButDeclines,

  /// Calls the card tool even on a question that wanted prose.
  overCalls,
}

/// Reduces the three checks to one verdict.
///
/// Order matters. [calledTrivialTool] is checked first because it is the only
/// signal that separates "cannot" from "chose not to", and every other
/// reading is meaningless without it. Over-calling outranks unrenderable
/// arguments because it changes what a user sees on every prose question.
ToolVerdict classifyToolSupport({
  required bool calledTrivialTool,
  required bool calledCardTool,
  required bool cardArgumentsRender,
  required bool calledOnNegativeControl,
}) {
  if (!calledTrivialTool) return ToolVerdict.unsupported;
  if (calledOnNegativeControl) return ToolVerdict.overCalls;
  if (calledCardTool && cardArgumentsRender) return ToolVerdict.supported;
  return ToolVerdict.supportedButDeclines;
}

/// One `/api/chat` call that offers [tools], returning the raw `message`.
Future<Map<String, dynamic>> _callWithTools({
  required HttpClient client,
  required String url,
  required String model,
  required String systemPrompt,
  required String userPrompt,
  required List<Map<String, dynamic>> tools,
  required Duration timeout,
}) async {
  final request = await client.postUrl(Uri.parse('$url/api/chat'));
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'stream': false,
      'think': false,
      'keep_alive': '30m',
      'options': const {'temperature': 0.0},
      'tools': tools,
    }),
  );
  final response = await request.close().timeout(timeout);
  final body = await response.transform(utf8.decoder).join().timeout(timeout);
  final data = jsonDecode(body) as Map<String, dynamic>;
  final message = data['message'];
  return message is Map<String, dynamic> ? message : <String, dynamic>{};
}

/// The arguments of the first call to [name] in [message], or null.
Map<String, dynamic>? _toolCallArguments(
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

/// Whether the tool arguments hold a body the running server would render.
bool _argumentsRender(Map<String, dynamic>? args) {
  if (args == null) return false;
  final body = args['body'];
  if (body == null) return false;
  return tryParseCardBody(jsonEncode(body)) != null;
}

Future<void> main(List<String> argv) async {
  final args = parseProbeArgs(argv, defaultSamples: 2);
  final schema = loadCardSchema();
  final toolPrompt = File(
    p.join(probeAssetsDir(), 'card_tool_prompt.txt'),
  ).readAsStringSync().trim();
  final cardTool = _renderCardTool(schema);
  final client = HttpClient()..idleTimeout = const Duration(minutes: 5);

  final calls = <ProbeCall>[];
  var calledTrivialTool = false;
  var calledCardTool = false;
  var cardArgumentsRender = false;
  var calledOnNegativeControl = false;

  stdout.writeln('=== check 3: capability discriminator ===');
  for (var i = 0; i < args.samples; i++) {
    final message = await _callWithTools(
      client: client,
      url: args.url,
      model: args.model,
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: _trivialToolPrompt,
      tools: const [_trivialTool],
      timeout: args.timeout,
    );
    final called =
        _toolCallArguments(message, 'get_current_temperature') != null;
    calledTrivialTool = calledTrivialTool || called;
    calls.add(
      ProbeCall(
        caseId: 'trivial-tool',
        sample: i,
        pass: called,
        label: called ? 'called' : 'no tool_calls',
        setting: 'tools=trivial',
      ),
    );
    stdout.writeln('  #$i ${called ? "called" : "no tool_calls"}');
  }

  stdout.writeln('=== check 1: positive, a question that wants a card ===');
  for (var i = 0; i < args.samples; i++) {
    final message = await _callWithTools(
      client: client,
      url: args.url,
      model: args.model,
      systemPrompt: toolPrompt,
      userPrompt: _cardPrompt,
      tools: [cardTool],
      timeout: args.timeout,
    );
    final toolArgs = _toolCallArguments(message, 'render_adaptive_card');
    final renders = _argumentsRender(toolArgs);
    calledCardTool = calledCardTool || toolArgs != null;
    cardArgumentsRender = cardArgumentsRender || renders;
    calls.add(
      ProbeCall(
        caseId: 'card-request',
        sample: i,
        pass: renders,
        label: toolArgs == null
            ? 'no tool_calls'
            : (renders ? 'tool body renders' : 'tool body not renderable'),
        setting: 'tools=card',
      ),
    );
    final what = toolArgs == null
        ? 'no tool_calls'
        : (renders ? 'renders' : 'not renderable');
    stdout.writeln('  #$i $what');
  }

  stdout.writeln('=== check 2: negative control, a prose question ===');
  for (var i = 0; i < args.samples; i++) {
    final message = await _callWithTools(
      client: client,
      url: args.url,
      model: args.model,
      systemPrompt: toolPrompt,
      userPrompt: _proseControlPrompt,
      tools: [cardTool],
      timeout: args.timeout,
    );
    final called = _toolCallArguments(message, 'render_adaptive_card') != null;
    calledOnNegativeControl = calledOnNegativeControl || called;
    calls.add(
      ProbeCall(
        caseId: 'prose-control',
        sample: i,
        pass: !called,
        label: called ? 'over-called the tool' : 'answered in prose',
        setting: 'tools=card',
      ),
    );
    stdout.writeln('  #$i ${called ? "OVER-CALLED" : "prose (correct)"}');
  }

  final verdict = classifyToolSupport(
    calledTrivialTool: calledTrivialTool,
    calledCardTool: calledCardTool,
    cardArgumentsRender: cardArgumentsRender,
    calledOnNegativeControl: calledOnNegativeControl,
  );
  stdout.writeln('\nVERDICT: ${verdict.name}');

  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'tool_call_probe',
      model: args.model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      temperature: 0,
      summary: {
        'verdict': verdict.name,
        'calledTrivialTool': calledTrivialTool,
        'calledCardTool': calledCardTool,
        'cardArgumentsRender': cardArgumentsRender,
        'calledOnNegativeControl': calledOnNegativeControl,
        ...passSummary(calls),
      },
      calls: calls,
      notes: 'Unseeded by design: the seed card is a prose-channel artifact.',
    );
  }
  // force: a socket stuck mid-generation must not outlive the run.
  client.close(force: true);
}
