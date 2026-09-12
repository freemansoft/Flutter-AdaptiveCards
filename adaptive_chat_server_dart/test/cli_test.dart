import 'dart:io';

import 'package:adaptive_chat_server_dart/src/app.dart';
import 'package:adaptive_chat_server_dart/src/cli.dart';
import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

// cli.dart's own doc comment says why this suite exists: the flag set lives
// in lib/ specifically so it is reachable from tests, because a wrong
// default here silently changes what every request sends to Ollama (a
// temperature nobody chose, a timeout nobody set). This is a genuine
// behavioral suite, not a data-model check -- it exercises buildArgParser,
// resolveTemperature, resolveLogLevel and buildResponder directly, then
// closes the loop with real `bin/server.dart` subprocess runs in the
// 'bin/server.dart' group so a flag's failure mode (message vs. stack trace)
// is checked end to end, not just at the parser.
void main() {
  group('--keep-alive', () {
    // Pins the shipped default so a change to defaultKeepAlive is a
    // deliberate edit to this constant, not a side effect of touching the
    // parser wiring.
    test('defaults to the bundled keep-alive window', () {
      final args = buildArgParser().parse([]);
      expect(args['keep-alive'], defaultKeepAlive);
    });

    // args package option values are always strings; this guards against a
    // future switch to addOption's type coercion silently changing that.
    test('parses an explicit value', () {
      final args = buildArgParser().parse(['--keep-alive', '2h']);
      expect(args['keep-alive'], '2h');
    });

    // The parser and the responder are separate objects wired together in
    // app.dart; a flag that stops at the parser and never reaches
    // buildResponder would still pass every parser-only test above.
    test('reaches the responder, so GET /status reports it', () {
      final responder = buildResponder(
        model: 'test-model',
        defaultSystemPromptPath: 'assets/default_system_prompt.txt',
        seedCardFile: 'assets/seed_card.json',
        cardSchemaPath: 'assets/card_schema.json',
        ollamaUrl: 'http://127.0.0.1:11434',
        keepAlive: '90m',
      );
      expect(responder.describe()['keepAlive'], '90m');
    });
  });

  group('--ollama-temperature', () {
    // defaultCardTemperature (0, greedy decoding) is called out in cli.dart
    // as measured better for card generation than the model's own default --
    // this pins that the flag actually ships with it.
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
        seedCardFile: 'assets/seed_card.json',
        cardSchemaPath: 'assets/card_schema.json',
        ollamaUrl: 'http://127.0.0.1:11434',
        temperature: 0.6,
      );
      expect(responder.describe()['temperature'], 0.6);
    });

    // The sentinel string "model" must round-trip to Dart null inside the
    // responder (so no temperature field is sent to Ollama at all) and back
    // out to the string "model" in describe() -- not to 0 or to a literal
    // null, either of which would misreport what was actually sent.
    test('"model" reaches the responder as no temperature at all', () {
      final responder = buildResponder(
        model: 'test-model',
        defaultSystemPromptPath: 'assets/default_system_prompt.txt',
        seedCardFile: 'assets/seed_card.json',
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

    // Throwing here, rather than clamping or falling back to a default,
    // is deliberate per resolveTemperature's doc comment: a typo should fail
    // loudly at startup instead of silently sampling at the wrong heat.
    test('rejects a non-numeric value', () {
      expect(() => resolveTemperature('warm'), throwsFormatException);
    });

    // Ollama's sampling temperature has no meaning below 0; letting a
    // negative value through would not error later, it would just quietly
    // change how every reply is generated.
    test('rejects a negative value', () {
      expect(() => resolveTemperature('-1'), throwsFormatException);
    });
  });

  group('resolveLogLevel', () {
    // The names are the CLI's own vocabulary, not `package:logging`'s --
    // this pins each one against the exact Level it must map to, since a
    // swapped pair (say warning/error) would still compile and would only
    // ever surface as oddly-leveled log lines in production.
    test('maps each accepted name to a logging level', () {
      expect(resolveLogLevel('critical'), Level.SHOUT);
      expect(resolveLogLevel('error'), Level.SEVERE);
      expect(resolveLogLevel('warning'), Level.WARNING);
      expect(resolveLogLevel('info'), Level.INFO);
      expect(resolveLogLevel('debug'), Level.FINE);
      expect(resolveLogLevel('trace'), Level.FINEST);
    });

    // --log-level is validated by _logLevelChoices before this ever runs in
    // practice, but the mapping function itself defaults rather than throws
    // -- this is what keeps it that way if the switch's default arm changes.
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
        seedCardFile: 'assets/seed_card.json',
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

    // -h is registered as an abbreviation on the same addFlag call; this
    // guards against the abbr getting detached from the flag in a future
    // edit and silently becoming a no-op.
    test('is set by --help and by -h', () {
      expect(buildArgParser().parse(['--help'])['help'], isTrue);
      expect(buildArgParser().parse(['-h'])['help'], isTrue);
    });

    // Every option's `help:` text is what a user actually reads to learn a
    // flag exists; a flag added to the parser but missing from this list
    // would still work and still be undiscoverable.
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

  // Everything above exercises the parser and buildResponder in isolation;
  // this group runs the real entrypoint as a subprocess so a startup failure
  // (unknown flag, missing required mode, bad value) is checked the way a
  // user actually hits it -- including that it prints a message and not a
  // Dart stack trace, which the unit-level tests above cannot see.
  group('bin/server.dart', () {
    test('--help prints usage and exits 0 without starting a server', () async {
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
    }, timeout: const Timeout(Duration(minutes: 2)));

    // args throws a plain ArgParserException for this; the risk is that
    // something upstream (a bare rethrow, a bug in error handling) turns
    // that into an uncaught exception and a printed stack trace instead.
    test('an unknown flag fails with a message, not a stack trace', () async {
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
    }, timeout: const Timeout(Duration(minutes: 2)));

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

    test('--echo alone is a complete invocation', () async {
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
    }, timeout: const Timeout(Duration(minutes: 2)));

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

  // A catch-all so a default value change anywhere in buildArgParser shows
  // up as a failing assertion here, not as a silent behavior change a user
  // only discovers by noticing their server answered differently than
  // before.
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
    // Named explicitly because the polarity flipped: --echo used to be the
    // implicit default before talking to a local Ollama became the norm, and
    // this is the test that would catch a revert.
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

    // A default only counts as a convenience if it can still be overridden;
    // this rules out defaultsTo accidentally becoming a fixed value.
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
