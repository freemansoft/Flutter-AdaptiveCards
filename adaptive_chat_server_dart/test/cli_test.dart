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
  });
}
