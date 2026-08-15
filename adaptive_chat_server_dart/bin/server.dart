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

/// Announces which system prompt is in force, because the wrong one is
/// otherwise invisible.
///
/// Card replies are opt-in: the bundled default prompt tells the model to
/// answer in Markdown and never mentions Adaptive Cards, so a server started
/// without `--system-prompt-file` answers "what are my options?" with bullet
/// points and no amount of rephrasing produces a choice set. Measured on
/// `qwen2.5-coder:7b` at temperature 0 over eight options questions: 0/8 cards
/// on the default prompt, 8/8 on the card prompt. That reads as a model or
/// prompt-wording failure when it is a launch-flag failure, so name the file
/// at startup and spell out the flag that switches modes.
void _logSystemPromptChoice(Logger log, String? systemPromptFile) {
  if (systemPromptFile != null) {
    log.info('System prompt: $systemPromptFile');
    return;
  }
  log.info(
    'System prompt: bundled assets/default_system_prompt.txt (Markdown '
    'replies only — no Adaptive Cards). For card replies restart with '
    '--system-prompt-file assets/card_system_prompt.txt',
  );
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
  _logSystemPromptChoice(log, args['system-prompt-file'] as String?);
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
