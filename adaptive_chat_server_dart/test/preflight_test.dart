import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

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

  test('an untagged model matches its :latest entry', () async {
    final readiness = await makeResponder(
      client: tagsClient(['llama3:latest']),
      model: 'llama3',
    ).checkReadiness();
    expect(readiness.isReady, isTrue);
  });

  test('a model that is not pulled reports the pull command', () async {
    final readiness = await makeResponder(
      client: tagsClient(['some-other:7b']),
    ).checkReadiness();
    expect(readiness.isReady, isFalse);
    expect(readiness.detail, contains('ollama pull qwen2.5-coder:7b'));
    // The operator needs to know what *is* available to pick from.
    expect(readiness.detail, contains('some-other:7b'));
  });

  test('an unreachable Ollama reports unreachable, not a crash', () async {
    final client = MockClient(
      (request) async => throw const SocketException('refused'),
    );
    final readiness = await makeResponder(client: client).checkReadiness();
    expect(readiness.isReady, isFalse);
    expect(readiness.detail, contains('unreachable'));
  });

  test('a non-200 from /api/tags reports not ready', () async {
    final client = MockClient((request) async => http.Response('nope', 500));
    final readiness = await makeResponder(client: client).checkReadiness();
    expect(readiness.isReady, isFalse);
    expect(readiness.detail, contains('500'));
  });

  test('an unparseable /api/tags body reports not ready', () async {
    final client = MockClient((request) async => http.Response('{{{', 200));
    final readiness = await makeResponder(client: client).checkReadiness();
    expect(readiness.isReady, isFalse);
  });

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
