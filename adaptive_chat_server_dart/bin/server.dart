import 'dart:io';

import 'package:adaptive_chat_server_dart/src/app.dart';
import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart' as shelf_io;

const _jsonFormatChoices = ['none', 'json', 'schema'];
const _logLevelChoices = [
  'critical',
  'error',
  'warning',
  'info',
  'debug',
  'trace',
];

Level _resolveLogLevel(String name) {
  switch (name) {
    case 'critical':
      return Level.SHOUT;
    case 'error':
      return Level.SEVERE;
    case 'warning':
      return Level.WARNING;
    case 'debug':
      return Level.FINE;
    case 'trace':
      return Level.FINEST;
    case 'info':
    default:
      return Level.INFO;
  }
}

ArgParser _buildParser() {
  return ArgParser()
    ..addOption(
      'ollama-url',
      help:
          'Base URL of a running Ollama server, e.g. http://127.0.0.1:11434. '
          'Omit to run the echo demo.',
    )
    ..addOption(
      'ollama-model',
      defaultsTo: defaultOllamaModel,
      help: 'Ollama model name (default: $defaultOllamaModel).',
    )
    ..addOption(
      'system-prompt-file',
      help:
          'Path to a text file whose contents become the system prompt. '
          'Re-read per request, so edits apply without restart. Omit to '
          'use the bundled default prompt.',
    )
    ..addOption(
      'num-ctx',
      defaultsTo: '$defaultNumCtx',
      help:
          'Ollama context window in tokens (default: $defaultNumCtx). Sent as '
          'options.num_ctx; prompt fill is logged against it.',
    )
    ..addOption(
      'history-turns',
      defaultsTo: '$defaultHistoryTurns',
      help:
          'Number of prior exchanges replayed to Ollama (default: '
          '$defaultHistoryTurns). Bounds only the outbound prompt; the server '
          'keeps full history.',
    )
    ..addOption(
      'json-format',
      defaultsTo: defaultJsonFormat,
      allowed: _jsonFormatChoices,
      help:
          "Constrain Ollama's output via its format field (default: "
          '$defaultJsonFormat).',
    )
    ..addOption('host', defaultsTo: '127.0.0.1')
    ..addOption('port', defaultsTo: '8000')
    ..addOption(
      'log-level',
      defaultsTo: 'info',
      allowed: _logLevelChoices,
      help:
          'Log level (default: info). Use "debug" to surface the '
          'OllamaResponder debug log of the raw model response content and '
          'card-detection result.',
    );
}

Future<void> main(List<String> arguments) async {
  final args = _buildParser().parse(arguments);

  Logger.root.level = _resolveLogLevel(args['log-level'] as String);
  Logger.root.onRecord.listen((record) {
    stdout.writeln(
      '${record.level.name}: ${record.loggerName}: ${record.message}',
    );
  });

  final scriptDir = p.dirname(Platform.script.toFilePath());
  final assetsDir = p.normalize(p.join(scriptDir, '..', 'assets'));

  final responder = buildResponder(
    ollamaUrl: args['ollama-url'] as String?,
    model: args['ollama-model'] as String,
    defaultSystemPromptPath: p.join(assetsDir, 'default_system_prompt.txt'),
    cardSchemaPath: p.join(assetsDir, 'card_schema.json'),
    systemPromptFile: args['system-prompt-file'] as String?,
    numCtx: int.parse(args['num-ctx'] as String),
    historyTurns: int.parse(args['history-turns'] as String),
    jsonFormat: args['json-format'] as String,
  );

  final handler = buildHandler(
    store: ConversationStore(),
    responder: responder,
  );

  final server = await shelf_io.serve(
    handler,
    args['host'] as String,
    int.parse(args['port'] as String),
  );
  Logger(
    'adaptive_chat_server_dart',
  ).info('Serving at http://${server.address.host}:${server.port}');
}
