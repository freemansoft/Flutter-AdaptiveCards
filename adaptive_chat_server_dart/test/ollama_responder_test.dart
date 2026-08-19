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
  late String seedPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ollama_responder_test');
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
    String jsonFormat = 'none',
    int historyTurns = defaultHistoryTurns,
    String? systemPromptFile,
    Duration? ollamaTimeout,
    double? temperature = defaultCardTemperature,
  }) {
    return OllamaResponder(
      ollamaUrl: 'http://127.0.0.1:11434',
      defaultSystemPromptPath: promptPath,
      defaultSeedCardPath: seedPath,
      cardSchemaPath: schemaPath,
      client: client,
      jsonFormat: jsonFormat,
      historyTurns: historyTurns,
      systemPromptFile: systemPromptFile,
      ollamaTimeout: ollamaTimeout ?? const Duration(seconds: 60),
      temperature: temperature,
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
    'a stalled Ollama times out with a timeout diagnostic, not a hang and '
    'not the unreachable message',
    () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return okResponse('should never be returned');
      });
      final reply = await makeResponder(
        client: client,
        ollamaTimeout: const Duration(milliseconds: 50),
      ).reply('hi', const []);
      // A slow-but-alive Ollama is a different problem from a dead one, and
      // sends the operator somewhere different. Keep the two distinguishable.
      expect(reply.text, contains('timed out'));
      expect(reply.text, isNot(contains('unreachable')));
      expect(reply.cardBody, isNull);
      expect(reply.stats, isNull);
    },
  );

  test('a timeout is not treated as a successful turn', () async {
    final client = MockClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return okResponse('should never be returned');
    });
    final reply = await makeResponder(
      client: client,
      ollamaTimeout: const Duration(milliseconds: 50),
    ).reply('hi', const []);
    expect(reply.ok, isFalse);
  });

  test('a transport failure is not treated as a successful turn', () async {
    final client = MockClient(
      (request) async => throw const SocketException('refused'),
    );
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.ok, isFalse);
  });

  test('an HTTP error is not treated as a successful turn', () async {
    final client = MockClient(
      (request) async => http.Response('model not found', 404),
    );
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.ok, isFalse);
  });

  test('an unparseable 2xx body is not treated as a successful turn', () async {
    final client = MockClient((request) async => http.Response('{}', 200));
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.ok, isFalse);
  });

  test('a normal reply is treated as a successful turn', () async {
    final client = MockClient((request) async => okResponse('hello'));
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.ok, isTrue);
  });

  test('every request sends keep_alive so the model stays resident', () async {
    late Map<String, dynamic> payload;
    final client = MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('hi');
    });
    await makeResponder(client: client).reply('hi', const []);
    expect(payload['keep_alive'], defaultKeepAlive);
  });

  test('keep_alive is configurable and reported by describe()', () async {
    late Map<String, dynamic> payload;
    final client = MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('hi');
    });
    final responder = OllamaResponder(
      ollamaUrl: 'http://127.0.0.1:11434',
      defaultSystemPromptPath: promptPath,
      defaultSeedCardPath: seedPath,
      cardSchemaPath: schemaPath,
      client: client,
      keepAlive: '2h',
    );
    await responder.reply('hi', const []);
    expect(payload['keep_alive'], '2h');
    expect(responder.describe()['keepAlive'], '2h');
  });

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
    // system + N2 seed pair (2 entries) + last 1 turn (2 entries) + current
    // turn = 6.
    expect(messages.length, 6);
    expect((messages.last as Map<String, dynamic>)['content'], 'turn3');
    expect((messages[3] as Map<String, dynamic>)['content'], 'turn2');
  });

  test('historyTurns <= 0 sends no prior history, but the N2 seed still '
      'goes out', () async {
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
    // system + N2 seed pair (2 entries) + current turn only = 4.
    expect(messages.length, 4);
    expect((messages[1] as Map<String, dynamic>)['content'], 'seed-user');
    expect(
      (messages[2] as Map<String, dynamic>)['content'],
      'seed-assistant',
    );
  });

  test(
    'the N2 seed pair precedes real history, which precedes the current '
    'turn',
    () async {
      // Pins the promoted candidate's message order end to end: this fails
      // if the seed lands after the real history, or after the current
      // user turn, rather than strictly between the system prompt and the
      // replayed conversation.
      late Map<String, dynamic> capturedPayload;
      final client = MockClient((request) async {
        capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return okResponse('ok');
      });
      final responder = makeResponder(client: client, historyTurns: 5);
      final history = [('user', 'turn1'), ('assistant', 'reply1')];
      await responder.reply('turn2', history);
      final messages = (capturedPayload['messages'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        messages.map((m) => m['role']).toList(),
        equals(['system', 'user', 'assistant', 'user', 'assistant', 'user']),
      );
      expect(
        messages.skip(1).map((m) => m['content']).toList(),
        equals(['seed-user', 'seed-assistant', 'turn1', 'reply1', 'turn2']),
      );
    },
  );

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
        defaultSeedCardPath: seedPath,
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
        defaultSeedCardPath: seedPath,
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

  // --- Parity additions (cross-checked against the removed Python
  // prototype's test_ollama_responder.py during the port) ---

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

  test('sends the configured temperature, not a hardcoded zero', () async {
    late Map<String, dynamic> capturedPayload;
    final client = MockClient((request) async {
      capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('ok');
    });
    final responder = makeResponder(client: client, temperature: 0.6);
    await responder.reply('hi', const []);
    final options = capturedPayload['options'] as Map<String, dynamic>;
    expect(options['temperature'], 0.6);
  });

  test(
    'a null temperature omits the key so Ollama uses the model default',
    () async {
      late Map<String, dynamic> capturedPayload;
      final client = MockClient((request) async {
        capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return okResponse('ok');
      });
      final responder = makeResponder(client: client, temperature: null);
      await responder.reply('hi', const []);
      final options = capturedPayload['options'] as Map<String, dynamic>;
      expect(options.containsKey('temperature'), isFalse);
      // num_ctx still goes out — only temperature is deferred to the model.
      expect(options['num_ctx'], defaultNumCtx);
    },
  );

  test('describe reports the configured temperature for GET /status', () async {
    final client = MockClient((request) async => okResponse('ok'));
    expect(
      makeResponder(client: client, temperature: 0.6).describe()['temperature'],
      0.6,
    );
  });

  test('describe reports "model" when no temperature is sent', () async {
    final client = MockClient((request) async => okResponse('ok'));
    final responder = makeResponder(client: client, temperature: null);
    expect(responder.describe()['temperature'], 'model');
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

  group('a model that ignores the format constraint', () {
    // Ollama accepts `format` for every model but only honors it on some
    // (qwen3.6:27b-coding-nvfp4 returns plain prose and no error). Silent
    // degradation is the worst version of that, so it must be logged.
    Future<List<LogRecord>> replyCapturingLogs(OllamaResponder r) async {
      final records = <LogRecord>[];
      Logger.root.level = Level.ALL;
      final sub = Logger.root.onRecord.listen(records.add);
      await r.reply('hi', const []);
      await sub.cancel();
      return records;
    }

    test('json mode warns when the reply is not JSON at all', () async {
      final client = MockClient(
        (request) async => okResponse('Hello. How are you doing today?'),
      );
      final responder = makeResponder(client: client, jsonFormat: 'json');
      final logs = await replyCapturingLogs(responder);
      final match = logs.where(
        (r) => r.message.contains('ignoring the format constraint'),
      );
      expect(match, isNotEmpty);
      expect(match.first.level, Level.WARNING);
      expect(match.first.message, contains('json'));
    });

    test('schema mode warns when the reply is not JSON at all', () async {
      final client = MockClient((request) async => okResponse('plain prose'));
      final responder = makeResponder(client: client, jsonFormat: 'schema');
      final logs = await replyCapturingLogs(responder);
      expect(
        logs.any((r) => r.message.contains('ignoring the format constraint')),
        isTrue,
      );
    });

    test('none mode never warns, since no constraint was requested', () async {
      final client = MockClient((request) async => okResponse('plain prose'));
      final responder = makeResponder(client: client);
      final logs = await replyCapturingLogs(responder);
      expect(
        logs.any((r) => r.message.contains('ignoring the format constraint')),
        isFalse,
      );
    });

    test('a valid JSON reply in json mode does not warn', () async {
      final client = MockClient(
        (request) async => okResponse('{"text":"Hello!"}'),
      );
      final responder = makeResponder(client: client, jsonFormat: 'json');
      final logs = await replyCapturingLogs(responder);
      expect(
        logs.any((r) => r.message.contains('ignoring the format constraint')),
        isFalse,
      );
    });
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
        defaultSeedCardPath: seedPath,
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
        defaultSeedCardPath: seedPath,
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
          defaultSeedCardPath: seedPath,
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
          defaultSeedCardPath: seedPath,
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
        defaultSeedCardPath: seedPath,
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
        defaultSeedCardPath: seedPath,
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
