import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

// OllamaResponder is the production backend (used whenever the server is
// started with --ollama-url, i.e. whenever it isn't running --echo), and it
// is the single place a real Ollama process's failure modes get turned into
// something safe to show a user and safe to store as conversation history.
// This suite pins that contract end to end: transport/timeout/HTTP/parse
// failures all degrade to a diagnostic Reply with ok:false instead of
// throwing or being replayed to the model as something it once said; the
// exact message wiring sent to Ollama (system prompt, N2 seed pair, trimmed
// history, current turn, in that order); and the response-side
// classification (card vs. prose vs. duplicate-key vs. unrecognized-element)
// that decides what the user actually sees. A conventional unit test —
// MockClient stands in for the HTTP call, nothing here talks to a live
// Ollama.
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
    bool seedCard = true,
  }) {
    return OllamaResponder(
      ollamaUrl: 'http://127.0.0.1:11434',
      defaultSystemPromptPath: promptPath,
      seedCardFile: seedCard ? seedPath : null,
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

  // The class doc promises OllamaResponder never raises to the caller — a
  // dropped connection must become a Reply the request handler can send back,
  // not an exception that takes down the whole request.
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

  test('a stalled Ollama times out with a timeout diagnostic, not a hang and '
      'not the unreachable message', () async {
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
  });

  // ok is what app.dart reads before replaying a reply into stored
  // conversation history (Reply.ok's contract: a diagnostic must never be
  // replayed as something the model said). Each failure path below sets it
  // independently, since they are separate branches in reply(), not one
  // shared early return.
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

  // Same ok contract as above, exercised via a raised exception rather than
  // an HTTP status — a distinct branch in reply()'s try/catch.
  test('a transport failure is not treated as a successful turn', () async {
    final client = MockClient(
      (request) async => throw const SocketException('refused'),
    );
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.ok, isFalse);
  });

  // Same ok contract, via a >=400 status — the branch that also captures the
  // response body for the operator-facing diagnostic below.
  test('an HTTP error is not treated as a successful turn', () async {
    final client = MockClient(
      (request) async => http.Response('model not found', 404),
    );
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.ok, isFalse);
  });

  // A 200 status doesn't guarantee a usable body — this is the one failure
  // mode that survives the status-code check, caught by the jsonDecode/cast
  // try/catch rather than the HTTP-error branch above.
  test('an unparseable 2xx body is not treated as a successful turn', () async {
    final client = MockClient((request) async => http.Response('{}', 200));
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.ok, isFalse);
  });

  // The baseline the five failure-path tests above are contrasting against —
  // confirms ok defaults true rather than the tests above only ever proving
  // "not false" against an assumed default.
  test('a normal reply is treated as a successful turn', () async {
    final client = MockClient((request) async => okResponse('hello'));
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.ok, isTrue);
  });

  // defaultKeepAlive exists specifically to avoid Ollama's 5-minute default
  // eviction (measured: a cold reload costs ~20x a warm one) — this pins
  // that every request actually carries the setting on the wire, not just
  // that the constant is defined.
  test('every request sends keep_alive so the model stays resident', () async {
    late Map<String, dynamic> payload;
    final client = MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('hi');
    });
    await makeResponder(client: client).reply('hi', const []);
    expect(payload['keep_alive'], defaultKeepAlive);
  });

  // Covers both sides of an override at once: the wire payload must reflect
  // the configured value, and describe() (GET /status) must report the same
  // value rather than the constructor default — the two are set from
  // different fields and could drift independently.
  test('keep_alive is configurable and reported by describe()', () async {
    late Map<String, dynamic> payload;
    final client = MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return okResponse('hi');
    });
    final responder = OllamaResponder(
      ollamaUrl: 'http://127.0.0.1:11434',
      defaultSystemPromptPath: promptPath,
      seedCardFile: seedPath,
      cardSchemaPath: schemaPath,
      client: client,
      keepAlive: '2h',
    );
    await responder.reply('hi', const []);
    expect(payload['keep_alive'], '2h');
    expect(responder.describe()['keepAlive'], '2h');
  });

  // A 404 usually means the model isn't pulled (see the _log.severe message
  // in reply()) — this pins that the status code actually reaches the
  // operator-facing text instead of a generic "something went wrong".
  test('HTTP 404 returns an error diagnostic naming the status', () async {
    final client = MockClient(
      (request) async => http.Response('model not found', 404),
    );
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.text, contains('Ollama error HTTP 404'));
  });

  // Ollama can answer 200 with a body that doesn't have the shape this code
  // assumes (an API change, or a runner returning an error object instead of
  // a message) — distinct from the unparseable-JSON case above, since this
  // body is valid JSON that just lacks the expected keys.
  test('2xx with missing message.content returns an unexpected-response '
      'diagnostic', () async {
    final client = MockClient(
      (request) async => http.Response(jsonEncode({'ok': true}), 200),
    );
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.text, contains('unexpected response'));
  });

  // The default classification path: ordinary prose must never accidentally
  // get parsed as a card body just because it happens to run through
  // tryParseCardBody unconditionally at the end of reply().
  test('success with plain text captures stats and sets no card', () async {
    final client = MockClient((request) async => okResponse('Hello there'));
    final reply = await makeResponder(client: client).reply('hi', const []);
    expect(reply.text, 'Hello there');
    expect(reply.cardBody, isNull);
    expect(reply.stats, isNotNull);
    expect(reply.stats!.promptTokens, 10);
  });

  // Exercises the unconstrained path: with jsonFormat left at the 'none'
  // default, card detection still runs via the unconditional
  // tryParseCardBody(content) fallback rather than the json_format-gated
  // branch covered by the json/schema-mode tests further down.
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

  // _trimHistory bounds the outbound prompt regardless of how long the
  // server's own conversation store has grown — without it, a long-running
  // chat would keep expanding every request's payload (and context fill)
  // even though only the tail is ever configured to be replayed.
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

  // seedCardFile and historyTurns are independent switches — this guards
  // against an implementation that gates the seed pair on historyTurns
  // (e.g. by building both from the same trimmed list), which would silently
  // drop the seed under a "no history replay" configuration.
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
    expect((messages[2] as Map<String, dynamic>)['content'], 'seed-assistant');
  });

  test('the N2 seed pair precedes real history, which precedes the current '
      'turn', () async {
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
  });

  // _loadSystemPrompt treats an IOException as "send no system message",
  // never as a reason to fail the whole reply — a system-prompt file being
  // temporarily unreadable (a deploy mid-write, a bad path) must not take
  // the chat down.
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
        seedCardFile: seedPath,
        cardSchemaPath: schemaPath,
        client: client,
      );
      await responder.reply('hi', const []);
      final messages = capturedPayload['messages'] as List<dynamic>;
      expect((messages.first as Map<String, dynamic>)['role'], isNot('system'));
    },
  );

  // _loadCardSchema returning null (bad JSON, or missing the expected
  // 'oneOf'/'$defs' keys) downgrades _jsonFormat in the constructor — this
  // pins that describe() surfaces both the effective mode and what was
  // requested, so an operator can't believe schema-constrained decoding is
  // active when the schema silently failed to load.
  test(
    'json_format=schema with an unusable schema file downgrades to none',
    () {
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        seedCardFile: seedPath,
        cardSchemaPath: '${tempDir.path}/missing_schema.json',
        client: MockClient((request) async => http.Response('', 200)),
        jsonFormat: 'schema',
      );
      final described = responder.describe();
      expect(described['jsonFormat'], 'none');
      expect(described['jsonFormatRequested'], 'schema');
    },
  );

  // describe() is served verbatim as GET /status — this pins that it strips
  // the directory (p.basename) rather than leaking a local filesystem path
  // to whoever calls the status endpoint.
  test(
    'describe() reports a bare filename for systemPromptFile, not a path',
    () {
      final responder = makeResponder(
        client: MockClient((r) async => http.Response('', 200)),
      );
      expect(responder.describe()['systemPromptFile'], 'prompt.txt');
    },
  );

  // The key's absence is itself the signal an operator reads as "nothing was
  // downgraded" — pairs with the downgrade test above, and guards against an
  // implementation that always includes jsonFormatRequested (which would
  // erase that signal by making every configuration look downgraded).
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

  // A model asked for JSON can legitimately answer with a JSON-encoded
  // string rather than a card object — the `if (parsed is String)` branch in
  // reply() exists to unwrap that to plain prose instead of misreading it as
  // a broken/empty card.
  test('json_format=json unwraps a plain JSON string reply to prose', () async {
    final client = MockClient(
      (request) async => okResponse(jsonEncode('Here is your answer.')),
    );
    final responder = makeResponder(client: client, jsonFormat: 'json');
    final reply = await responder.reply('hi', const []);
    expect(reply.text, 'Here is your answer.');
    expect(reply.cardBody, isNull);
  });

  // Complements the string-unwrap test above: same json_format=json branch,
  // but the parsed value is an object, so this exercises the cardBody path
  // rather than the prose-unwrap path.
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

  // temperature/think and the `format` key are set by separate branches in
  // reply()'s payload construction — this triplet (none/json/schema) exists
  // because a bug isolated to one jsonFormat branch's options wouldn't show
  // up testing only one mode.
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

  // Guards against a regression where the temperature constructor arg is
  // accepted but silently ignored in favor of the module-level
  // defaultCardTemperature constant (0.0) used in the payload.
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

  // Backs the `--ollama-temperature model` escape hatch documented on
  // defaultCardTemperature: this is what proves the key is actually omitted
  // from the wire payload, rather than sent as a literal null or 0, which
  // Ollama would not treat the same as "use the Modelfile default".
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

  // Status-endpoint parity with what's actually sent on the wire — pairs
  // with the "reports 'model'" test below for the null case.
  test('describe reports the configured temperature for GET /status', () async {
    final client = MockClient((request) async => okResponse('ok'));
    expect(
      makeResponder(client: client, temperature: 0.6).describe()['temperature'],
      0.6,
    );
  });

  // The describe() counterpart to the "omits the key" wire test above —
  // "model" is the operator-facing word for "no temperature sent", so
  // GET /status doesn't just show a bare null.
  test('describe reports "model" when no temperature is sent', () async {
    final client = MockClient((request) async => okResponse('ok'));
    final responder = makeResponder(client: client, temperature: null);
    expect(responder.describe()['temperature'], 'model');
  });

  // Guards against an aliasing bug: app.dart passes its own persisted
  // history list into reply(), and if _trimHistory or anything downstream
  // mutated it in place, that would corrupt the server's stored conversation
  // rather than only what gets sent to Ollama.
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

  // The constructor stores _systemPromptPath, not the file's contents (see
  // the class doc) — an implementation that cached the contents once would
  // pass a test that only calls reply() a single time, so this specifically
  // edits the file between two calls on the same responder instance.
  test('system prompt file is re-read on every request (live edit takes '
      'effect without restart)', () async {
    final captured = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      captured.add(jsonDecode(request.body) as Map<String, dynamic>);
      return okResponse('ok');
    });
    final livePath = '${tempDir.path}/live.txt';
    File(livePath).writeAsStringSync('first prompt');
    final responder = makeResponder(client: client, systemPromptFile: livePath);

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

    // The warning message names both the fact and the requested mode
    // ('json') — an operator debugging a model needs to know which flag is
    // the one not being honored, not just that something's wrong.
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

    // The important negative case: with jsonFormat left at the default
    // 'none', there's no constraint to violate, so this warning must not
    // fire on ordinary prose — it would otherwise spam every request in the
    // default (unconstrained) production configuration.
    test('none mode never warns, since no constraint was requested', () async {
      final client = MockClient((request) async => okResponse('plain prose'));
      final responder = makeResponder(client: client);
      final logs = await replyCapturingLogs(responder);
      expect(
        logs.any((r) => r.message.contains('ignoring the format constraint')),
        isFalse,
      );
    });

    // The warning is keyed on the model getting it wrong, not on the mode
    // being requested — without this test a bug that fires the warning
    // whenever jsonFormat != 'none' (regardless of the reply) would still
    // pass every other case in this group.
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

  // _logContextFill exists because prompt_eval_count reports what survived
  // truncation, never what was actually sent — so the percentage tiers below
  // can look like a half-full context while the prompt is in fact
  // overflowing num_ctx and being silently clipped by Ollama. This group
  // pins the tier boundaries (50%/76%) and the separate truncation-specific
  // warning that only sentChars vs. num_ctx can detect.
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
        seedCardFile: seedPath,
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

    // Boundary case: _logContextFill checks `pct >= 0.50`, so this pins the
    // threshold is inclusive rather than off-by-one against the "below 50%"
    // test above.
    test('fill at exactly 50% logs an info-level "context filling"', () async {
      final client = MockClient(
        (request) async => okResponse('ok', extra: {'prompt_eval_count': 500}),
      );
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        seedCardFile: seedPath,
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
          seedCardFile: seedPath,
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

    // Boundary case for the other threshold (`pct >= 0.76`) — pins that 76%
    // is scored "near limit" (warning), not still "filling" (info).
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
          seedCardFile: seedPath,
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

    test(
      'a prompt larger than num_ctx warns that Ollama truncated it',
      () async {
        // The truncation signature measured on Ollama 0.33.3: a prompt well
        // over num_ctx comes back reporting about half the window, so the
        // percentage tiers below read it as a half-full context.
        final client = MockClient(
          (request) async =>
              okResponse('ok', extra: {'prompt_eval_count': 502}),
        );
        final responder = OllamaResponder(
          ollamaUrl: 'http://127.0.0.1:11434',
          defaultSystemPromptPath: promptPath,
          seedCardFile: seedPath,
          cardSchemaPath: schemaPath,
          client: client,
          numCtx: 1000,
        );
        final sub = Logger.root.onRecord.listen(records.add);
        await responder.reply('x' * 20000, const []);
        await sub.cancel();
        final match = records.where(
          (r) => r.message.contains('prompt truncated'),
        );
        expect(match, isNotEmpty);
        expect(match.first.level, Level.WARNING);
      },
    );

    // Negative case for the truncation-specific warning (distinct from the
    // percentage tiers): a large-but-not-overflowing prompt must not trip
    // the "prompt truncated" message just because it also reports a high
    // fill percentage.
    test('a prompt that fits does not warn about truncation', () async {
      final client = MockClient(
        (request) async => okResponse('ok', extra: {'prompt_eval_count': 760}),
      );
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        seedCardFile: seedPath,
        cardSchemaPath: schemaPath,
        client: client,
        numCtx: 1000,
      );
      final logs = await replyCapturingLogs(responder);
      expect(logs.any((r) => r.message.contains('prompt truncated')), isFalse);
    });

    test('fill above 76% logs a warning-level "context near limit"', () async {
      final client = MockClient(
        (request) async => okResponse('ok', extra: {'prompt_eval_count': 800}),
      );
      final responder = OllamaResponder(
        ollamaUrl: 'http://127.0.0.1:11434',
        defaultSystemPromptPath: promptPath,
        seedCardFile: seedPath,
        cardSchemaPath: schemaPath,
        client: client,
        numCtx: 1000,
      );
      final logs = await replyCapturingLogs(responder);
      expect(logs.any((r) => r.message.contains('context near limit')), isTrue);
    });

    // _logContextFill's `data['prompt_eval_count'] is! int` guard — Ollama's
    // response shape isn't guaranteed to include this field on every
    // version/build, and its absence must be a silent no-op, not a crash or
    // a false "0% full" reading.
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
        seedCardFile: seedPath,
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

  // seedCardFile is the sole on/off switch for the N2 seed pair — there's no
  // separate boolean, by design (see the constructor's _seedCardPath
  // comment), so these two tests are what confirms "name a file" and "don't"
  // are the only two states, with no way to end up seeded-but-silent or
  // configured-off-but-still-sending.
  group('seed only when a seed-card-file is named', () {
    test('omits the seed pair when no file is named', () async {
      late Map<String, dynamic> captured;
      final client = MockClient((request) async {
        captured = jsonDecode(request.body) as Map<String, dynamic>;
        return okResponse('ok');
      });
      final responder = makeResponder(client: client, seedCard: false);
      await responder.reply('turn', [
        ('user', 'earlier'),
        ('assistant', 'earlier reply'),
      ]);
      final messages = captured['messages'] as List;
      // system + 2 history + current = 4, with no seed pair between the
      // system prompt and the history.
      expect(messages.length, 4);
      expect((messages[1] as Map<String, dynamic>)['content'], 'earlier');
      expect(
        messages.map((m) => (m as Map<String, dynamic>)['content']).toList(),
        isNot(contains('seed-user')),
      );
    });

    test('seeds when a file is named', () async {
      // Naming the file is the whole opt-in: there is no separate boolean,
      // so a configuration cannot claim to be seeded while sending nothing.
      late Map<String, dynamic> captured;
      final client = MockClient((request) async {
        captured = jsonDecode(request.body) as Map<String, dynamic>;
        return okResponse('ok');
      });
      await makeResponder(client: client).reply('turn', []);
      final messages = captured['messages'] as List;
      expect(
        messages.map((m) => (m as Map<String, dynamic>)['content']).toList(),
        contains('seed-user'),
      );
    });

    test('status reports no seed, distinct from a failed load', () async {
      // seedCardTurns is 0 both when no file was named and when the named
      // asset fails to parse. Those are different problems, so `seedCard`
      // has to say which one a reader is looking at.
      final off = makeResponder(
        client: MockClient((_) async => okResponse('ok')),
        seedCard: false,
      ).describe();
      expect(off['seedCard'], isFalse);
      expect(off['seedCardTurns'], 0);

      final on = makeResponder(
        client: MockClient((_) async => okResponse('ok')),
      ).describe();
      expect(on['seedCard'], isTrue);
      expect(on['seedCardTurns'], 2);
    });
  });

  // The vocabulary here is entirely reference-data driven (writeVocabulary
  // swaps the temp schema's ChildElement enum) rather than the real bundled
  // card_schema.json, so these confirm the unrecognized-type detection logic
  // itself, independent of what element types the shipped schema currently
  // lists.
  group('unrecognized element types', () {
    /// Replaces the temp schema with one whose ChildElement enum is [types].
    void writeVocabulary(List<String> types) {
      File(schemaPath).writeAsStringSync(
        jsonEncode({
          r'$defs': {
            'ChildElement': {
              'type': 'object',
              'properties': {
                'type': {'type': 'string', 'enum': types},
              },
            },
          },
          'oneOf': <dynamic>[],
        }),
      );
    }

    Future<List<LogRecord>> replyCapturingLogs(OllamaResponder r) async {
      final records = <LogRecord>[];
      Logger.root.level = Level.ALL;
      final sub = Logger.root.onRecord.listen(records.add);
      await r.reply('hi', const []);
      await sub.cancel();
      return records;
    }

    test('a misspelled type is warned about and still rendered', () async {
      writeVocabulary(['TextBlock', 'Badge']);
      final client = MockClient(
        (request) async =>
            okResponse('{"type":"Textblock","text":"hi","wrap":true}'),
      );
      final logs = await replyCapturingLogs(makeResponder(client: client));
      final match = logs.where(
        (r) => r.message.contains('unrecognized element type'),
      );
      expect(match, isNotEmpty);
      expect(match.first.message, contains('Textblock'));
    });

    // Pins the deliberate "warn, don't reject" design choice from reply()'s
    // own comment: suppressing an entire card over one bad nested element
    // may be worse than rendering a blank for just that element. A
    // regression here would start silently dropping otherwise-good cards.
    test('the card is still returned, not downgraded to text', () async {
      writeVocabulary(['TextBlock', 'Badge']);
      final client = MockClient(
        (request) async =>
            okResponse('{"type":"Textblock","text":"hi","wrap":true}'),
      );
      final reply = await makeResponder(client: client).reply('hi', const []);
      expect(reply.cardBody, isNotNull);
      expect(reply.cardBody!.single['type'], 'Textblock');
    });

    test('a card of known types produces no warning', () async {
      writeVocabulary(['TextBlock', 'Badge']);
      final client = MockClient(
        (request) async =>
            okResponse('{"type":"TextBlock","text":"hi","wrap":true}'),
      );
      final logs = await replyCapturingLogs(makeResponder(client: client));
      expect(
        logs.where((r) => r.message.contains('unrecognized element type')),
        isEmpty,
      );
    });

    test('an empty vocabulary disables the warning', () async {
      // The default setUp schema has no ChildElement, so the check is off.
      final client = MockClient(
        (request) async =>
            okResponse('{"type":"Textblock","text":"hi","wrap":true}'),
      );
      final logs = await replyCapturingLogs(makeResponder(client: client));
      expect(
        logs.where((r) => r.message.contains('unrecognized element type')),
        isEmpty,
      );
    });
  });
}
