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
/// Echoes back the reply mode the operator chose, so the log says what this
/// process will actually do.
///
/// The two bundled prompts produce entirely different replies — measured on
/// `qwen2.5-coder:7b` at temperature 0 over eight options questions, the card
/// prompt yields 8/8 Adaptive Cards and the Markdown one 0/8. A mode is always
/// explicit (see the argument check in `main`), so there is no default to
/// explain here; this line exists so a log tells you which of the two you are
/// looking at without re-deriving it from the launch config.
void _logSystemPromptChoice(Logger log, String? systemPromptFile) {
  if (systemPromptFile == null) {
    log.info('Reply mode: echo demo (--echo) — no system prompt is used');
    return;
  }
  log.info('System prompt: $systemPromptFile');
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

  // No default reply mode on purpose. The two bundled prompts produce
  // completely different output — 8/8 Adaptive Cards versus 0/8 on the same
  // model at t=0 — and whichever one is implicit, somebody eventually runs
  // the server, gets the other kind of reply, and blames the model. Refusing
  // to guess costs one flag and removes that whole class of confusion.
  if (!(args['echo'] as bool) && args['system-prompt-file'] == null) {
    _exitWithUsageError(
      'Choose a reply mode — the server does not pick one for you:\n'
      '  --system-prompt-file assets/card_system_prompt.txt     '
      'Adaptive Card replies\n'
      '  --system-prompt-file assets/default_system_prompt.txt  '
      'Markdown replies\n'
      '  --echo                                                 '
      'echo demo, no model called',
      parser,
    );
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
    // buildResponder treats a null URL as "use the echo demo", so --echo is
    // expressed by withholding the URL rather than by a second switch.
    ollamaUrl: (args['echo'] as bool) ? null : args['ollama-url'] as String,
    model: args['ollama-model'] as String,
    defaultSystemPromptPath: p.join(assetsDir, 'card_system_prompt.txt'),
    cardSchemaPath: p.join(assetsDir, 'card_schema.json'),
    defaultSeedCardPath: p.join(assetsDir, 'seed_card.json'),
    systemPromptFile: args['system-prompt-file'] as String?,
    seedCardFile: args['seed-card-file'] as String?,
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
      'will return a diagnostic until this is fixed.\n  Fix by starting '
      'Ollama (`ollama serve`), or restart with --echo to run the echo demo '
      'with no model at all.',
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
