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

/// Value of `--ollama-temperature` that defers to the model's own default.
const temperatureModelDefault = 'model';

/// Parses `--ollama-temperature` into the value the responder should send.
///
/// Returns `null` for the literal `model`, which means "send no temperature
/// at all" so Ollama applies the model's Modelfile value. Throws a
/// [FormatException] for anything that is not a non-negative number, so a
/// typo fails at startup rather than silently sampling at the wrong heat.
double? resolveTemperature(String value) {
  if (value == temperatureModelDefault) return null;
  final parsed = double.tryParse(value);
  if (parsed == null || parsed.isNaN || parsed < 0) {
    throw FormatException(
      'Invalid --ollama-temperature "$value": expected a non-negative '
      'number (e.g. 0, 0.6) or "$temperatureModelDefault".',
    );
  }
  return parsed;
}

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
    ..addFlag(
      'echo',
      negatable: false,
      help:
          'Run the echo demo instead of calling a model. Selects a reply mode, '
          'so it satisfies the requirement to name one; otherwise pass '
          '--system-prompt-file.',
    )
    ..addOption(
      'ollama-url',
      defaultsTo: defaultOllamaUrl,
      help:
          'Base URL of a running Ollama server (default: $defaultOllamaUrl). '
          'Pass --echo to skip Ollama entirely and run the echo demo.',
    )
    ..addOption(
      'ollama-model',
      defaultsTo: defaultOllamaModel,
      help: 'Ollama model name (default: $defaultOllamaModel).',
    )
    ..addOption(
      'system-prompt-file',
      help:
          'REQUIRED unless --echo. Path to a text file whose contents become '
          'the system prompt; re-read per request, so edits apply without '
          'restart. Use assets/card_system_prompt.txt for Adaptive Card '
          'replies or assets/default_system_prompt.txt for Markdown. There is '
          'no default — the two produce completely different output, so the '
          'server makes you say which one you want.',
    )
    ..addOption(
      'seed-card-file',
      help:
          'Path to a JSON array of {"role","content"} turns prepended ahead '
          'of every conversation, so a card is the established format before '
          'any prose accumulates (measured as candidate N2 — see '
          'ModelBehavior.md). Defaults to assets/seed_card.json; re-read per '
          'request, so edits apply without restart. Override it to re-tune '
          'the seed. Pass --no-seed-card to send none at all.',
    )
    ..addFlag(
      'seed-card',
      defaultsTo: true,
      help:
          'Prepend the seed exchange ahead of the replayed history. On by '
          'default, because every figure in ModelBehavior.md was measured '
          'with it and a silently seedless server would not match the '
          'documented behavior. Switchable because its value is strongly '
          'model-dependent: measured across fifteen models it is worth +10 '
          'shapes to nemotron-3-nano:4b and +9 to qwen3-coder:30b, nothing at '
          'all to qwen2.5-coder:7b and qwen3.8:27b-nvfp4, and -2 to '
          'gpt-oss:20b, the only model that answers all 25 shape cases and '
          'does so without it.',
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
      'ollama-temperature',
      defaultsTo: '$defaultCardTemperature',
      help:
          'Sampling temperature sent as options.temperature (default: '
          '$defaultCardTemperature). 0 selects greedy decoding, which '
          'minimizes malformed card JSON but makes a bad card reproducibly '
          'bad. Pass "$temperatureModelDefault" to send no temperature and '
          "let the model's own Modelfile default apply — measured worse than "
          '0 for card generation, so prefer the default.',
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
