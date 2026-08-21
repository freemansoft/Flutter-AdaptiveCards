/// Dumps one raw reply with its invisible characters made visible.
///
/// Reach for this **before theorising** about why a card failed to render.
/// The `Unterminated string` bug was misdiagnosed for a while as "the model
/// wrote a literal newline inside a JSON string"; this script showed the
/// reply contained zero real newlines and 11 correctly escaped ones, which
/// moved the investigation off the model and onto the detector, where the
/// bug actually was.
///
/// ```sh
/// fvm dart run tool/model_probes/dump_reply.dart \
///   --model qwen3.6:27b-coding-nvfp4 \
///   --prompt 'Show me a Dart snippet that reads a JSON file.'
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
// Relative: this file and its helper both live outside `lib/`, so there is
// no `package:` URI for them.
import 'probe_support.dart';

const _defaultPrompt =
    'Show me a Dart snippet that reads a JSON file and prints the "name" '
    'field, with a short explanation above it.';

/// Extracts `message.content`, or null when the body does not carry one.
String? _contentOrNull(String body) {
  try {
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic>) return null;
    final message = data['message'];
    if (message is! Map<String, dynamic>) return null;
    final content = message['content'];
    return content is String ? content : null;
  } on FormatException {
    return null;
  }
}

Future<void> main(List<String> argv) async {
  final promptParser = ArgParser()
    ..addOption('prompt', defaultsTo: _defaultPrompt)
    ..addOption('model')
    ..addOption('url')
    ..addOption('samples')
    ..addMultiOption(
      'history',
      help:
          'File whose contents become one prior turn. Repeatable; turns '
          'alternate user, assistant, user, ... in the order given.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  final parsed = promptParser.parse(argv);
  if (parsed['help'] as bool) {
    stdout.writeln(promptParser.usage);
    return;
  }
  // Only this script accepts --prompt/--history; the shared parser rejects
  // options it does not declare, which is what broke --prompt.
  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);
  final userPrompt = parsed['prompt'] as String;
  final history = parsed['history'] as List<String>;

  final messages = <Map<String, String>>[
    {'role': 'system', 'content': loadCardSystemPrompt()},
    for (final (i, turnFile) in history.indexed)
      {
        'role': i.isEven ? 'user' : 'assistant',
        'content': File(turnFile).readAsStringSync(),
      },
    {'role': 'user', 'content': userPrompt},
  ];

  final client = HttpClient()..idleTimeout = const Duration(minutes: 5);
  final request = await client.postUrl(Uri.parse('${args.url}/api/chat'));
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'model': args.model,
      'messages': messages,
      'stream': false,
      'think': false,
      'keep_alive': '30m',
      'options': const {'num_ctx': 16384, 'temperature': 0.0},
    }),
  );
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    stderr
      ..writeln('HTTP ${response.statusCode} from ${args.url}/api/chat')
      ..writeln(body);
    exitCode = 1;
    // force: a socket still stuck mid-generation must not keep the
    // process alive after its work is done and its result written.
    client.close(force: true);
    return;
  }
  // A 200 whose body carries no `message.content` is a thing to report, not
  // to crash on: this probe's whole job is showing what came back.
  final content = _contentOrNull(body);
  if (content == null) {
    stderr
      ..writeln(
        'Unexpected response: 200 with no message.content. Raw body follows.',
      )
      ..writeln(body);
    exitCode = 1;
    // force: a socket still stuck mid-generation must not keep the
    // process alive after its work is done and its result written.
    client.close(force: true);
    return;
  }

  stdout
    ..writeln('===== ${args.model} =====')
    ..writeln('prompt: $userPrompt')
    ..writeln('--- raw reply (real newlines marked [LF]) ---')
    ..writeln(content.replaceAll('\n', '[LF]\n'))
    ..writeln('--- end ---')
    ..writeln('chars                : ${content.length}')
    // The distinction that matters: a real newline inside a JSON string is
    // invalid, an escaped one is correct. They look identical when printed.
    ..writeln('real newlines        : ${'\n'.allMatches(content).length}')
    ..writeln(
      r'escaped \n sequences : '
      '${r'\n'.allMatches(content).length}',
    )
    ..writeln('contains ``` fence   : ${content.contains('```')}')
    ..writeln('history turns        : ${history.length}')
    ..writeln('verdict              : ${judgeReply(content, 0).label}');
  // force: a socket still stuck mid-generation must not keep the
  // process alive after its work is done and its result written.
  client.close(force: true);
}
