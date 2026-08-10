import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String promptPath;
  late String schemaPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ollama_responder_test');
    promptPath = '${tempDir.path}/prompt.txt';
    File(promptPath).writeAsStringSync('You are helpful.');
    schemaPath = '${tempDir.path}/card_schema.json';
    File(schemaPath).writeAsStringSync(
      jsonEncode({r'$defs': <String, dynamic>{}, 'oneOf': <dynamic>[]}),
    );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  OllamaResponder makeResponder({
    required http.Client client,
    String jsonFormat = 'none',
    int historyTurns = defaultHistoryTurns,
    String? systemPromptFile,
    Duration? ollamaTimeout,
  }) {
    return OllamaResponder(
      ollamaUrl: 'http://127.0.0.1:11434',
      defaultSystemPromptPath: promptPath,
      cardSchemaPath: schemaPath,
      client: client,
      jsonFormat: jsonFormat,
      historyTurns: historyTurns,
      systemPromptFile: systemPromptFile,
      ollamaTimeout: ollamaTimeout ?? const Duration(seconds: 60),
    );
  }

  http.Response okResponse(
    String content, {
    Map<String, dynamic> extra = const {},
  }) {
    return http.Response(
      jsonEncode({
        'message': {'content': content},
        'prompt_eval_count': 10,
        'eval_count': 5,
        ...extra,
      }),
      200,
    );
  }

  test(
    'transport failure returns an unreachable diagnostic, no stats',
    () async {
      final client = MockClient(
        (request) async => throw const SocketException('refused'),
      );
      final reply = await makeResponder(client: client).reply('hi', const []);
      expect(reply.text, contains('Ollama unreachable'));
      expect(reply.cardBody, isNull);
      expect(reply.stats, isNull);
    },
  );

  test(
    'a stalled Ollama times out and returns the unreachable diagnostic, '
    'not a hang',
    () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return okResponse('should never be returned');
      });
      final reply = await makeResponder(
        client: client,
        ollamaTimeout: const Duration(milliseconds: 50),
      ).reply('hi', const []);
      expect(reply.text, contains('Ollama unreachable'));
      expect(reply.cardBody, isNull);
      expect(reply.stats, isNull);
    },
  );

  test('HTTP 404 returns an error diagnostic naming the status', () async {
    final client = MockClient(
      (request) async => http.Response('model not found', 404),
    );
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.text, contains('Ollama error HTTP 404'));
  });

  test(
    '2xx with missing message.content returns an unexpected-response '
    'diagnostic',
    () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode({'ok': true}), 200),
      );
      final reply = await makeResponder(client: client).reply('hi', const []);
      expect(reply.text, contains('unexpected response'));
    },
  );

  test('success with plain text captures stats and sets no card', () async {
    final client = MockClient((request) async => okResponse('Hello there'));
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.text, 'Hello there');
    expect(reply.cardBody, isNull);
    expect(reply.stats, isNotNull);
    expect(reply.stats!.promptTokens, 10);
  });

  test('success with a full card fragment sets cardBody', () async {
    final cardJson = jsonEncode({
      'type': 'AdaptiveCard',
      'body': [
        {'type': 'TextBlock', 'text': 'hi', 'wrap': true},
      ],
    });
    final client = MockClient((request) async => okResponse(cardJson));
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.cardBody, isNotNull);
    expect(reply.cardBody!.single['type'], 'TextBlock');
    // reply.text is always the raw model output, even for a card reply.
    expect(reply.text, cardJson);
  });

  test('history is trimmed to the last historyTurns exchanges', () async {
    late Map<String, dynamic> capturedPayload;
    final client = MockClient((request) async {
      capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('ok');
    });
    final responder = makeResponder(client: client, historyTurns: 1);
    final history = [
      ('user', 'turn1'),
      ('assistant', 'reply1'),
      ('user', 'turn2'),
      ('assistant', 'reply2'),
    ];
    await responder.reply('turn3', history);
    final messages = capturedPayload['messages'] as List<dynamic>;
    // system + last 1 turn (2 entries) + current turn = 4.
    expect(messages.length, 4);
    expect((messages.last as Map<String, dynamic>)['content'], 'turn3');
    expect((messages[1] as Map<String, dynamic>)['content'], 'turn2');
  });

  test('historyTurns <= 0 sends no prior history', () async {
    late Map<String, dynamic> capturedPayload;
    final client = MockClient((request) async {
      capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('ok');
    });
    final responder = makeResponder(client: client, historyTurns: 0);
    await responder.reply('turn', [
      ('user', 'earlier'),
      ('assistant', 'earlier reply'),
    ]);
    final messages = capturedPayload['messages'] as List;
    // system + current turn only = 2.
    expect(messages.length, 2);
  });

  test(
    'missing system prompt file sends no system message and logs a warning',
    () async {
      late Map<String, dynamic> capturedPayload;
      final client = MockClient((request) async {
        capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return okResponse('ok');
      });
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: '${tempDir.path}/does_not_exist.txt',
        cardSchemaPath: schemaPath,
        client: client,
      );
      await responder.reply('hi', const []);
      final messages = capturedPayload['messages'] as List<dynamic>;
      expect((messages.first as Map<String, dynamic>)['role'], isNot('system'));
    },
  );

  test(
    'json_format=schema with an unusable schema file downgrades to none',
    () {
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        cardSchemaPath: '${tempDir.path}/missing_schema.json',
        client: MockClient((request) async => http.Response('', 200)),
        jsonFormat: 'schema',
      );
      final described = responder.describe();
      expect(described['jsonFormat'], 'none');
      expect(described['jsonFormatRequested'], 'schema');
    },
  );

  test(
    'describe() reports a bare filename for systemPromptFile, not a path',
    () {
      final responder = makeResponder(
        client: MockClient((r) async => http.Response('', 200)),
      );
      expect(responder.describe()['systemPromptFile'], 'prompt.txt');
    },
  );

  test('describe() omits jsonFormatRequested when no downgrade occurred', () {
    final responder = makeResponder(
      client: MockClient((r) async => http.Response('', 200)),
    );
    expect(responder.describe().containsKey('jsonFormatRequested'), isFalse);
  });

  test(
    'a duplicate JSON object key falls back to a text reply, not a crash',
    () async {
      // Two "pages" keys on the same object — legal JSON, but the second
      // silently overwrites the first under plain jsonDecode, which is exactly
      // the data loss this guard exists to catch.
      const duplicateKeyContent =
          '{"type":"Carousel","pages":[1],"pages":[1,2]}';
      final client = MockClient(
        (request) async => okResponse(duplicateKeyContent),
      );
      final responder = makeResponder(client: client, jsonFormat: 'json');
      final reply = await responder.reply('hi', const []);
      expect(reply.cardBody, isNull);
      expect(reply.text, duplicateKeyContent);
    },
  );

  test('json_format=json unwraps a plain JSON string reply to prose', () async {
    final client = MockClient(
      (request) async => okResponse(jsonEncode('Here is your answer.')),
    );
    final responder = makeResponder(client: client, jsonFormat: 'json');
    final reply = await responder.reply('hi', const []);
    expect(reply.text, 'Here is your answer.');
    expect(reply.cardBody, isNull);
  });

  test('json_format=json with a card-shaped value sets cardBody', () async {
    final inner = jsonEncode({
      'type': 'AdaptiveCard',
      'body': [
        {'type': 'TextBlock', 'text': 'hi'},
      ],
    });
    final client = MockClient((request) async => okResponse(inner));
    final responder = makeResponder(client: client, jsonFormat: 'json');
    final reply = await responder.reply('hi', const []);
    expect(reply.cardBody, isNotNull);
  });

  // --- Step 5 parity additions (cross-checked against
  // adaptive_chat_server/tests/test_ollama_responder.py) ---

  test('none mode sends no format field but does send temperature 0 and '
      'think false', () async {
    late Map<String, dynamic> capturedPayload;
    final client = MockClient((request) async {
      capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('ok');
    });
    final responder = makeResponder(client: client);
    await responder.reply('hi', const []);
    expect(capturedPayload.containsKey('format'), isFalse);
    final options = capturedPayload['options'] as Map<String, dynamic>;
    expect(options['temperature'], 0.0);
    expect(capturedPayload['think'], false);
  });

  test(
    'json mode sends temperature 0 and think false alongside format',
    () async {
      late Map<String, dynamic> capturedPayload;
      final client = MockClient((request) async {
        capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return okResponse('ok');
      });
      final responder = makeResponder(client: client, jsonFormat: 'json');
      await responder.reply('hi', const []);
      expect(capturedPayload['format'], 'json');
      final options = capturedPayload['options'] as Map<String, dynamic>;
      expect(options['temperature'], 0.0);
      expect(capturedPayload['think'], false);
    },
  );

  test('schema mode sends temperature 0 and think false alongside the '
      'loaded schema as format', () async {
    late Map<String, dynamic> capturedPayload;
    final client = MockClient((request) async {
      capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('ok');
    });
    final responder = makeResponder(client: client, jsonFormat: 'schema');
    await responder.reply('hi', const []);
    expect(capturedPayload['format'], isA<Map<String, dynamic>>());
    final options = capturedPayload['options'] as Map<String, dynamic>;
    expect(options['temperature'], 0.0);
    expect(capturedPayload['think'], false);
  });

  test('reply does not mutate the caller-supplied history list', () async {
    final client = MockClient((request) async => okResponse('ok'));
    final responder = makeResponder(client: client, historyTurns: 1);
    final history = [
      ('user', 'u1'),
      ('assistant', 'a1'),
      ('user', 'u2'),
      ('assistant', 'a2'),
    ];
    final original = List<(String, String)>.of(history);
    await responder.reply('now', history);
    expect(history, original);
  });

  test('system prompt file is re-read on every request (live edit takes '
      'effect without restart)', () async {
    final captured = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      captured.add(jsonDecode(request.body) as Map<String, dynamic>);
      return okResponse('ok');
    });
    final livePath = '${tempDir.path}/live.txt';
    File(livePath).writeAsStringSync('first prompt');
    final responder = makeResponder(
      client: client,
      systemPromptFile: livePath,
    );

    await responder.reply('q1', const []);
    final firstMessages = captured[0]['messages'] as List<dynamic>;
    expect(
      (firstMessages.first as Map<String, dynamic>)['content'],
      'first prompt',
    );

    File(livePath).writeAsStringSync('second prompt');
    await responder.reply('q2', const []);
    final secondMessages = captured[1]['messages'] as List<dynamic>;
    expect(
      (secondMessages.first as Map<String, dynamic>)['content'],
      'second prompt',
    );
  });

  test('a well-formed nested card reusing a key name at different nesting '
      'levels is not a false-positive duplicate', () async {
    // "type" (and, more subtly, a repeated array-of-objects key like
    // "pages") legitimately appears once per *object*, at many different
    // nesting depths, in ordinary card JSON. The scanner must only flag a
    // key repeated within the SAME object, not a key name reused across
    // sibling/nested objects.
    final cardJson = jsonEncode({
      'type': 'Carousel',
      'pages': [
        {
          'type': 'CarouselPage',
          'items': [
            {'type': 'TextBlock', 'text': 'a'},
          ],
        },
        {
          'type': 'CarouselPage',
          'items': [
            {'type': 'TextBlock', 'text': 'b'},
          ],
        },
      ],
    });
    final client = MockClient((request) async => okResponse(cardJson));
    final responder = makeResponder(client: client, jsonFormat: 'schema');
    final reply = await responder.reply('carousel?', const []);
    expect(reply.cardBody, isNotNull);
    expect(reply.cardBody!.single['type'], 'Carousel');
    expect((reply.cardBody!.single['pages'] as List).length, 2);
  });

  group('context-fill logging tiers', () {
    late List<LogRecord> records;

    setUp(() {
      records = <LogRecord>[];
      Logger.root.level = Level.ALL;
    });

    Future<List<LogRecord>> replyCapturingLogs(
      OllamaResponder responder,
    ) async {
      final sub = Logger.root.onRecord.listen(records.add);
      await responder.reply('hi', const []);
      await sub.cancel();
      return records;
    }

    test('fill below 50% logs nothing', () async {
      final client = MockClient(
        (request) async => okResponse('ok', extra: {'prompt_eval_count': 400}),
      );
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        cardSchemaPath: schemaPath,
        client: client,
        numCtx: 1000,
      );
      final logs = await replyCapturingLogs(responder);
      expect(logs.any((r) => r.message.contains('context filling')), isFalse);
      expect(
        logs.any((r) => r.message.contains('context near limit')),
        isFalse,
      );
    });

    test('fill at exactly 50% logs an info-level "context filling"', () async {
      final client = MockClient(
        (request) async => okResponse('ok', extra: {'prompt_eval_count': 500}),
      );
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        cardSchemaPath: schemaPath,
        client: client,
        numCtx: 1000,
      );
      final logs = await replyCapturingLogs(responder);
      final match = logs.where((r) => r.message.contains('context filling'));
      expect(match, isNotEmpty);
      expect(match.first.level, Level.INFO);
      expect(
        logs.any((r) => r.message.contains('context near limit')),
        isFalse,
      );
    });

    test(
      'fill between 50% and 76% logs an info-level "context filling"',
      () async {
        final client = MockClient(
          (request) async =>
              okResponse('ok', extra: {'prompt_eval_count': 600}),
        );
        final responder = OllamaResponder(
          ollamaUrl: 'http://127.0.0.1:11434',
          defaultSystemPromptPath: promptPath,
          cardSchemaPath: schemaPath,
          client: client,
          numCtx: 1000,
        );
        final logs = await replyCapturingLogs(responder);
        expect(logs.any((r) => r.message.contains('context filling')), isTrue);
        expect(
          logs.any((r) => r.message.contains('context near limit')),
          isFalse,
        );
      },
    );

    test(
      'fill at exactly 76% logs a warning-level "context near limit"',
      () async {
        final client = MockClient(
          (request) async =>
              okResponse('ok', extra: {'prompt_eval_count': 760}),
        );
        final responder = OllamaResponder(
          ollamaUrl: 'http://127.0.0.1:11434',
          defaultSystemPromptPath: promptPath,
          cardSchemaPath: schemaPath,
          client: client,
          numCtx: 1000,
        );
        final logs = await replyCapturingLogs(responder);
        final match = logs.where(
          (r) => r.message.contains('context near limit'),
        );
        expect(match, isNotEmpty);
        expect(match.first.level, Level.WARNING);
      },
    );

    test('fill above 76% logs a warning-level "context near limit"', () async {
      final client = MockClient(
        (request) async => okResponse('ok', extra: {'prompt_eval_count': 800}),
      );
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        cardSchemaPath: schemaPath,
        client: client,
        numCtx: 1000,
      );
      final logs = await replyCapturingLogs(responder);
      expect(logs.any((r) => r.message.contains('context near limit')), isTrue);
    });

    test('fill logging is skipped when prompt_eval_count is absent', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'message': {'content': 'ok'},
          }),
          200,
        ),
      );
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        cardSchemaPath: schemaPath,
        client: client,
        numCtx: 1000,
      );
      final logs = await replyCapturingLogs(responder);
      expect(logs.any((r) => r.message.contains('context filling')), isFalse);
      expect(
        logs.any((r) => r.message.contains('context near limit')),
        isFalse,
      );
    });
  });
}
