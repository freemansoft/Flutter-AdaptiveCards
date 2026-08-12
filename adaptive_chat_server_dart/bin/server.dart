import 'dart:io';

import 'package:adaptive_chat_server_dart/src/app.dart';
import 'package:adaptive_chat_server_dart/src/cli.dart';
import 'package:adaptive_chat_server_dart/src/expired_conversation.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Exit code for a malformed command line, matching common CLI convention
/// (2 = usage error, distinct from 1 = the program ran and failed).
const _usageErrorExitCode = 2;

void _printUsage(ArgParser parser) {
  stdout
    ..writeln('Adaptive Chat backend (shelf). Echo by default; pass')
    ..writeln('--ollama-url to answer with a local Ollama model.')
    ..writeln()
    ..writeln('Usage: dart run bin/server.dart [options]')
    ..writeln()
    ..writeln(parser.usage);
}

Future<void> main(List<String> arguments) async {
  final parser = buildArgParser();
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    // A bad flag is user error: say what was wrong and how to invoke it,
    // rather than dumping a Dart stack trace.
    stderr
      ..writeln(e.message)
      ..writeln();
    _printUsage(parser);
    exit(_usageErrorExitCode);
  }

  if (args['help'] as bool) {
    _printUsage(parser);
    return;
  }

  Logger.root.level = resolveLogLevel(args['log-level'] as String);
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
    keepAlive: args['keep-alive'] as String,
    ollamaTimeout: Duration(
      seconds: int.parse(args['ollama-timeout'] as String),
    ),
  );

  // Advisory only: a backend that is not up yet may still come up, so this
  // reports loudly and starts anyway rather than refusing to serve.
  final log = Logger('adaptive_chat_server_dart');
  final readiness = await responder.checkReadiness();
  if (readiness.isReady) {
    log.info('Preflight: ${readiness.detail}');
  } else {
    log.severe(
      'Preflight FAILED: ${readiness.detail}\n  Starting anyway — requests '
      'will return a diagnostic until this is fixed.',
    );
  }

  final handler = buildHandler(
    store: ConversationStore(),
    responder: responder,
    expiredConversationBodyItems: loadExpiredConversationBodyItems(
      p.join(assetsDir, 'expired_conversation_notice.json'),
    ),
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
