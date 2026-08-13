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

/// Reports user error the way a CLI should — the problem plus how to invoke
/// it — rather than dumping a Dart stack trace.
Never _exitWithUsageError(String message, ArgParser parser) {
  stderr
    ..writeln(message)
    ..writeln();
  _printUsage(parser);
  exit(_usageErrorExitCode);
}

Future<void> main(List<String> arguments) async {
  final parser = buildArgParser();
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    _exitWithUsageError(e.message, parser);
  }

  if (args['help'] as bool) {
    _printUsage(parser);
    return;
  }

  // Resolved before any work starts: a typo here should fail at launch, not
  // silently sample at the wrong heat for the life of the process.
  final double? temperature;
  try {
    temperature = resolveTemperature(args['ollama-temperature'] as String);
  } on FormatException catch (e) {
    _exitWithUsageError(e.message, parser);
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
    temperature: temperature,
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
