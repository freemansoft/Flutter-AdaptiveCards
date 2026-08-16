import 'dart:io';

import 'package:adaptive_chat_server_dart/src/app.dart';
import 'package:adaptive_chat_server_dart/src/cli.dart';
import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('--keep-alive', () {
    test('defaults to the bundled keep-alive window', () {
      final args = buildArgParser().parse([]);
      expect(args['keep-alive'], defaultKeepAlive);
    });

    test('parses an explicit value', () {
      final args = buildArgParser().parse(['--keep-alive', '2h']);
      expect(args['keep-alive'], '2h');
    });

    test('reaches the responder, so GET /status reports it', () {
      final responder = buildResponder(
        model: 'test-model',
        defaultSystemPromptPath: 'assets/default_system_prompt.txt',
        cardSchemaPath: 'assets/card_schema.json',
        ollamaUrl: 'http://127.0.0.1:11434',
        keepAlive: '90m',
      );
      expect(responder.describe()['keepAlive'], '90m');
    });
  });

  group('--ollama-temperature', () {
    test('defaults to the documented card temperature', () {
      final args = buildArgParser().parse([]);
      expect(args['ollama-temperature'], '$defaultCardTemperature');
    });

    test('parses an explicit value', () {
      final args = buildArgParser().parse(['--ollama-temperature', '0.6']);
      expect(args['ollama-temperature'], '0.6');
    });

    test('reaches the responder, so GET /status reports it', () {
      final responder = buildResponder(
        model: 'test-model',
        defaultSystemPromptPath: 'assets/default_system_prompt.txt',
        cardSchemaPath: 'assets/card_schema.json',
        ollamaUrl: 'http://127.0.0.1:11434',
        temperature: 0.6,
      );
      expect(responder.describe()['temperature'], 0.6);
    });

    test('"model" reaches the responder as no temperature at all', () {
      final responder = buildResponder(
        model: 'test-model',
        defaultSystemPromptPath: 'assets/default_system_prompt.txt',
        cardSchemaPath: 'assets/card_schema.json',
        ollamaUrl: 'http://127.0.0.1:11434',
        temperature: null,
      );
      expect(responder.describe()['temperature'], 'model');
    });
  });

  group('resolveTemperature', () {
    test('parses a numeric value', () {
      expect(resolveTemperature('0.6'), 0.6);
      expect(resolveTemperature('0'), 0.0);
    });

    test('maps "model" to null, meaning send no temperature', () {
      expect(resolveTemperature('model'), isNull);
    });

    test('rejects a non-numeric value', () {
      expect(() => resolveTemperature('warm'), throwsFormatException);
    });

    test('rejects a negative value', () {
      expect(() => resolveTemperature('-1'), throwsFormatException);
    });
  });

  group('resolveLogLevel', () {
    test('maps each accepted name to a logging level', () {
      expect(resolveLogLevel('critical'), Level.SHOUT);
      expect(resolveLogLevel('error'), Level.SEVERE);
      expect(resolveLogLevel('warning'), Level.WARNING);
      expect(resolveLogLevel('info'), Level.INFO);
      expect(resolveLogLevel('debug'), Level.FINE);
      expect(resolveLogLevel('trace'), Level.FINEST);
    });

    test('falls back to info for an unrecognised name', () {
      expect(resolveLogLevel('nonsense'), Level.INFO);
    });
  });

  group('--ollama-timeout', () {
    test('defaults to the bundled timeout', () {
      final args = buildArgParser().parse([]);
      expect(args['ollama-timeout'], '$defaultOllamaTimeoutSeconds');
    });

    test('reaches the responder, so GET /status reports it', () {
      final responder = buildResponder(
        model: 'test-model',
        defaultSystemPromptPath: 'assets/default_system_prompt.txt',
        cardSchemaPath: 'assets/card_schema.json',
        ollamaUrl: 'http://127.0.0.1:11434',
        ollamaTimeout: const Duration(seconds: 240),
      );
      expect(responder.describe()['timeoutSeconds'], 240);
    });
  });

  group('--help', () {
    test('is off by default', () {
      expect(buildArgParser().parse([])['help'], isFalse);
    });

    test('is set by --help and by -h', () {
      expect(buildArgParser().parse(['--help'])['help'], isTrue);
      expect(buildArgParser().parse(['-h'])['help'], isTrue);
    });

    test('usage lists every flag the server accepts', () {
      final usage = buildArgParser().usage;
      for (final flag in [
        'echo',
        'ollama-url',
        'ollama-model',
        'system-prompt-file',
        'num-ctx',
        'history-turns',
        'json-format',
        'keep-alive',
        'host',
        'port',
        'log-level',
      ]) {
        expect(usage, contains('--$flag'), reason: '$flag missing from usage');
      }
    });
  });

  group('bin/server.dart', () {
    test(
      '--help prints usage and exits 0 without starting a server',
      () async {
        // Platform.resolvedExecutable, not `fvm dart`: CI runs this suite on
        // a plain Dart SDK with no fvm on PATH. This invokes whichever SDK is
        // executing the test, so it works locally and in CI alike.
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/server.dart',
          '--help',
        ], workingDirectory: Directory.current.path);
        expect(result.exitCode, 0);
        expect('${result.stdout}', contains('--keep-alive'));
        expect('${result.stdout}', contains('--ollama-url'));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'an unknown flag fails with a message, not a stack trace',
      () async {
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/server.dart',
          '--nonsense',
        ], workingDirectory: Directory.current.path);
        expect(result.exitCode, isNot(0));
        final output = '${result.stdout}${result.stderr}';
        expect(output, contains('nonsense'));
        expect(
          output,
          isNot(contains('#0')),
          reason: 'a bad flag is user error, not a crash to dump a trace for',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'naming no reply mode fails with guidance, not a stack trace',
      () async {
        // The server refuses to guess between card, Markdown, and echo — the
        // three produce completely different output.
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/server.dart',
        ], workingDirectory: Directory.current.path);
        expect(result.exitCode, isNot(0));
        final output = '${result.stdout}${result.stderr}';
        expect(output, contains('Choose a reply mode'));
        // The message must name all three ways out, or it is a riddle.
        expect(output, contains('card_system_prompt.txt'));
        expect(output, contains('default_system_prompt.txt'));
        expect(output, contains('--echo'));
        expect(
          output,
          isNot(contains('#0')),
          reason: 'a missing flag is user error, not a crash',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      '--echo alone is a complete invocation',
      () async {
        // --echo names a mode, so it must satisfy the requirement on its own.
        // Verified via --help + --echo so the process exits instead of serving.
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/server.dart',
          '--echo',
          '--help',
        ], workingDirectory: Directory.current.path);
        expect(result.exitCode, 0);
        expect('${result.stdout}', isNot(contains('Choose a reply mode')));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'a bad --ollama-temperature fails with a message, not a stack trace',
      () async {
        // --echo names a reply mode so this reaches the temperature check.
        // Without it the run stops earlier, on the missing-mode error, and
        // this test would pass on the usage dump alone — which lists every
        // flag name, including this one.
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/server.dart',
          '--echo',
          '--ollama-temperature',
          'warm',
        ], workingDirectory: Directory.current.path);
        expect(result.exitCode, isNot(0));
        final output = '${result.stdout}${result.stderr}';
        expect(output, contains('Invalid --ollama-temperature'));
        expect(
          output,
          isNot(contains('#0')),
          reason: 'a bad value is user error, not a crash to dump a trace for',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  test('existing flags keep their documented defaults', () {
    final args = buildArgParser().parse([]);
    expect(args['ollama-model'], defaultOllamaModel);
    expect(args['num-ctx'], '$defaultNumCtx');
    expect(args['history-turns'], '$defaultHistoryTurns');
    expect(args['json-format'], defaultJsonFormat);
    expect(args['host'], '127.0.0.1');
    expect(args['port'], '8000');
    expect(args['log-level'], 'info');
    // Changed deliberately: talking to a local Ollama is now the default and
    // the echo demo is opt-in. See the --echo group below.
    expect(args['ollama-url'], defaultOllamaUrl);
    expect(args['echo'], isFalse);
  });

  group('--echo and the default responder', () {
    test('the echo demo is opt-in, not the default', () {
      expect(buildArgParser().parse([])['echo'], isFalse);
      expect(buildArgParser().parse(['--echo'])['echo'], isTrue);
    });

    test('--ollama-url defaults to the local Ollama', () {
      expect(
        buildArgParser().parse([])['ollama-url'],
        'http://127.0.0.1:11434',
      );
    });

    test('--ollama-url is still overridable', () {
      final args = buildArgParser().parse(['--ollama-url', 'http://box:9999']);
      expect(args['ollama-url'], 'http://box:9999');
    });

    test('the parser itself supplies no prompt default', () {
      // Deliberate: there is no default reply mode. bin/server.dart rejects an
      // invocation that names neither --system-prompt-file nor --echo, which
      // is asserted end-to-end in the bin/server.dart group.
      expect(buildArgParser().parse([])['system-prompt-file'], isNull);
    });
  });
}
