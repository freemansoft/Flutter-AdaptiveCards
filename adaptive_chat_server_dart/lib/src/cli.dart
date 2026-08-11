/// Command-line surface for `bin/server.dart`.
///
/// Lives in `lib/` rather than beside `main()` so the flag set — names,
/// defaults, and allowed values — is reachable from tests. A wrong default
/// here silently changes how every request is sent to Ollama.
library;

import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';

const _jsonFormatChoices = ['none', 'json', 'schema'];
const _logLevelChoices = [
  'critical',
  'error',
  'warning',
  'info',
  'debug',
  'trace',
];

/// Maps a `--log-level` name to its [Level], defaulting to [Level.INFO].
Level resolveLogLevel(String name) {
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

/// Builds the parser for every flag `bin/server.dart` accepts.
ArgParser buildArgParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information and exit.',
    )
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
    ..addOption(
      'ollama-timeout',
      defaultsTo: '$defaultOllamaTimeoutSeconds',
      help:
          'Seconds to wait for one Ollama reply (default: '
          '$defaultOllamaTimeoutSeconds). A cold load of a large model plus a '
          'full context window can exceed this; raise it rather than assuming '
          'the server is unreachable.',
    )
    ..addOption(
      'keep-alive',
      defaultsTo: defaultKeepAlive,
      help:
          'How long Ollama keeps the model in memory after a reply, as an '
          "Ollama duration (default: $defaultKeepAlive). Ollama's own "
          'default is 5m, short enough that an idle chat pays a full model '
          'reload on its next message. Use "0" to unload immediately or '
          '"-1" to keep the model loaded indefinitely.',
    )
    ..addOption(
      'host',
      defaultsTo: '127.0.0.1',
      help:
          'Address to bind (default: 127.0.0.1, loopback only). Use 0.0.0.0 '
          'to accept connections from other machines.',
    )
    ..addOption(
      'port',
      defaultsTo: '8000',
      help: 'Port to listen on (default: 8000).',
    )
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
