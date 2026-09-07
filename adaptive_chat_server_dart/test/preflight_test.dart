import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// Unit tests for OllamaResponder.checkReadiness() — the startup preflight
// against Ollama's /api/tags, which exists so a missing, unreachable, or
// unpulled model surfaces at startup where an operator is looking, instead
// of as an error on the first user message (see the doc comment on
// checkReadiness in ollama_responder.dart). Ollama itself is never contacted
// here: every case is a canned /api/tags response via MockClient, so what's
// actually pinned is this method's interpretation of that response — model
// name matching (including the untagged/:latest alias Ollama itself
// applies), and that every failure shape (network error, non-200, unparseable
// body) degrades to a reported not-ready rather than an uncaught exception
// that would crash startup.
void main() {
  late Directory tempDir;
  late String promptPath;
  late String schemaPath;
  late String seedPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('preflight_test');
    promptPath = '${tempDir.path}/prompt.txt';
    File(promptPath).writeAsStringSync('You are helpful.');
    seedPath = '${tempDir.path}/seed_card.json';
    File(seedPath).writeAsStringSync(
      jsonEncode([
        {'role': 'user', 'content': 'seed-user'},
        {'role': 'assistant', 'content': 'seed-assistant'},
      ]),
    );
    schemaPath = '${tempDir.path}/card_schema.json';
    File(schemaPath).writeAsStringSync(
      jsonEncode({r'$defs': <String, dynamic>{}, 'oneOf': <dynamic>[]}),
    );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  OllamaResponder makeResponder({
    required http.Client client,
    String model = 'qwen2.5-coder:7b',
  }) => OllamaResponder(
    ollamaUrl: 'http://127.0.0.1:11434',
    defaultSystemPromptPath: promptPath,
    seedCardFile: seedPath,
    cardSchemaPath: schemaPath,
    client: client,
    model: model,
  );

  http.Client tagsClient(List<String> names) => MockClient((request) async {
    expect(request.url.path, '/api/tags');
    return http.Response(
      jsonEncode({
        'models': [
          for (final n in names) {'name': n},
        ],
      }),
      200,
    );
  });

  // The interface's simplest implementation (no external dependency) still
  // needs to answer this the same way OllamaResponder does below, since
  // callers treat both as ordinary Responders.
  test('echo responder is always ready', () async {
    final readiness = await EchoResponder().checkReadiness();
    expect(readiness.isReady, isTrue);
  });

  test('a pulled model reports ready and names the model', () async {
    final readiness = await makeResponder(
      client: tagsClient(['qwen2.5-coder:7b', 'gpt-oss:20b']),
    ).checkReadiness();
    expect(readiness.isReady, isTrue);
    expect(readiness.detail, contains('qwen2.5-coder:7b'));
  });

  // Ollama silently resolves a bare model name to its :latest tag;
  // checkReadiness must apply the same resolution or every operator who
  // configured a model without a tag would see a false not-ready.
  test('an untagged model matches its :latest entry', () async {
    final readiness = await makeResponder(
      client: tagsClient(['llama3:latest']),
      model: 'llama3',
    ).checkReadiness();
    expect(readiness.isReady, isTrue);
  });

  // The detail message is the operator's actual remedy, not just a
  // diagnostic — it has to be specific enough to copy-paste and run.
  test('a model that is not pulled reports the pull command', () async {
    final readiness = await makeResponder(
      client: tagsClient(['some-other:7b']),
    ).checkReadiness();
    expect(readiness.isReady, isFalse);
    expect(readiness.detail, contains('ollama pull qwen2.5-coder:7b'));
    // The operator needs to know what *is* available to pick from.
    expect(readiness.detail, contains('some-other:7b'));
  });

  // checkReadiness must never let a connection-level exception escape —
  // that would crash server startup with a stack trace instead of handing
  // the operator an actionable readiness message.
  test('an unreachable Ollama reports unreachable, not a crash', () async {
    final client = MockClient(
      (request) async => throw const SocketException('refused'),
    );
    final readiness = await makeResponder(client: client).checkReadiness();
    expect(readiness.isReady, isFalse);
    expect(readiness.detail, contains('unreachable'));
  });

  // A different failure shape than the unreachable case above: the socket
  // connects and Ollama answers, just unhealthily (wrong port, a proxy in
  // the way) — both must resolve to not-ready, so this checks the response
  // that arrives, not just the ones that never do.
  test('a non-200 from /api/tags reports not ready', () async {
    final client = MockClient((request) async => http.Response('nope', 500));
    final readiness = await makeResponder(client: client).checkReadiness();
    expect(readiness.isReady, isFalse);
    expect(readiness.detail, contains('500'));
  });

  // A 200 whose body isn't the expected {models: [...]} shape (e.g.
  // something intercepting the request before it reaches Ollama) must still
  // resolve to not-ready rather than throwing out of checkReadiness.
  test('an unparseable /api/tags body reports not ready', () async {
    final client = MockClient((request) async => http.Response('{{{', 200));
    final readiness = await makeResponder(client: client).checkReadiness();
    expect(readiness.isReady, isFalse);
  });

  // describe() feeds GET /status, so an operator can see the effective
  // timeout without re-reading server flags — pins that a custom value
  // actually round-trips rather than describe() only ever reporting the
  // built-in default.
  test('the configured timeout is reported by describe()', () {
    final responder = OllamaResponder(
      ollamaUrl: 'http://127.0.0.1:11434',
      defaultSystemPromptPath: promptPath,
      seedCardFile: seedPath,
      cardSchemaPath: schemaPath,
      ollamaTimeout: const Duration(seconds: 180),
    );
    expect(responder.describe()['timeoutSeconds'], 180);
  });
}
