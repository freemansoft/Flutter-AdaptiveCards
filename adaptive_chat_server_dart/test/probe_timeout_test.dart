import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';

void main() {
  group('probeOnce timeout', () {
    late HttpServer server;
    late HttpClient client;

    setUp(() async {
      // Accepts a chat request and then never answers — the shape of a model
      // that has run away generating. `granite4.1:3b` was observed doing
      // exactly this for 16 minutes on one `table` case.
      //
      // `/api/generate` answers promptly, because the real server does (~8 ms
      // per unload in the recorded logs): a timed-out call issues an unload,
      // and a fake that stalled that too would model an Ollama that cannot
      // answer one — and would charge every timeout test the eviction bound.
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((req) async {
          if (req.uri.path != '/api/generate') return; // stall the chat call
          await req.response.close();
        });
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    test('scores a stalled call a failure instead of hanging', () async {
      final outcome = await probeOnce(
        client: client,
        url: 'http://127.0.0.1:${server.port}',
        model: 'stalls:1b',
        systemPrompt: 'sys',
        userPrompt: 'hi',
        timeout: const Duration(milliseconds: 300),
      );
      expect(outcome.ok, isFalse);
      expect(outcome.label, 'timeout (0s)');
      // Distinct from every other failure label, so a stall is never read as
      // a wrong shape or as invalid JSON.
      expect(outcome.label, isNot(contains('broken')));
      expect(outcome.reply, isEmpty);
    });

    test('gives its connection back, so a later call still succeeds', () async {
      // The discriminating test. `Future.timeout` does not cancel the request
      // underneath it, so without abort() a timed-out call keeps its socket
      // checked out of the pool. With a two-connection pool, three timeouts
      // exhaust it and every later call blocks — which is how a sweep came to
      // sit for 3.5 hours having used 1.9 seconds of CPU.
      //
      // Bounding postUrl stops that being an infinite hang, but a leaked pool
      // still turns a perfectly good reply into a timeout. So the assertion is
      // that a call after the stalls actually SUCCEEDS, not merely that it
      // returns: with abort() it does, without it the pool is empty and it
      // times out acquiring a connection.
      var seen = 0;
      final stallThenAnswer =
          await HttpServer.bind(
              InternetAddress.loopbackIPv4,
              0,
            )
            ..listen((req) async {
              if (req.uri.path == '/api/generate') {
                await req.response.close(); // the eviction; not a chat attempt
                return;
              }
              seen++;
              if (seen <= 3) return; // stall: never respond
              req.response
                ..headers.contentType = ContentType.json
                ..write(
                  r'{"message":{"content":"[{\"type\":\"TextBlock\"}]"}}',
                );
              await req.response.close();
            });
      addTearDown(() => stallThenAnswer.close(force: true));

      final pooled = HttpClient()..maxConnectionsPerHost = 2;
      addTearDown(() => pooled.close(force: true));

      Future<ProbeOutcome> call() => probeOnce(
        client: pooled,
        url: 'http://127.0.0.1:${stallThenAnswer.port}',
        model: 'stalls:1b',
        systemPrompt: 'sys',
        userPrompt: 'hi',
        timeout: const Duration(milliseconds: 200),
      );

      for (var i = 0; i < 3; i++) {
        expect((await call()).label, startsWith('timeout'), reason: 'stall $i');
      }
      final after = await call();
      expect(
        after.label,
        isNot(startsWith('timeout')),
        reason: 'the pool was never refilled — abort() did not run',
      );
    });

    test('issues an unload after a timeout', () async {
      // The bound alone leaves the generation running. Ollama serves one
      // request at a time, so an abandoned call that keeps generating makes
      // every later call queue and time out without reaching the model --
      // recorded as stalls the model never earned. `llama3.2:latest` scored
      // 31 where two were real. This asserts only that the unload request
      // follows the timed-out chat call; whether the unload cancels the
      // generation is not shown (see `evictModel`), so nothing here claims
      // the next call is unqueued.
      final paths = <String>[];
      final watcher = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((req) async {
          paths.add(req.uri.path);
          if (req.uri.path != '/api/generate') return; // stall the chat call
          await req.response.close();
        });
      addTearDown(() => watcher.close(force: true));
      final probeClient = HttpClient();
      addTearDown(() => probeClient.close(force: true));

      final outcome = await probeOnce(
        client: probeClient,
        url: 'http://127.0.0.1:${watcher.port}',
        model: 'stalls:1b',
        systemPrompt: 'sys',
        userPrompt: 'hi',
        timeout: const Duration(milliseconds: 300),
      );

      expect(outcome.label, startsWith('timeout'));
      expect(
        paths,
        containsAllInOrder(<String>['/api/chat', '/api/generate']),
        reason: 'the timed-out call must be followed by an unload',
      );
    });

    test('returns rather than waiting for the full generation', () async {
      final sw = Stopwatch()..start();
      await probeOnce(
        client: client,
        url: 'http://127.0.0.1:${server.port}',
        model: 'stalls:1b',
        systemPrompt: 'sys',
        userPrompt: 'hi',
        timeout: const Duration(milliseconds: 300),
      );
      sw.stop();
      // The bound is what makes a multi-model sweep finite.
      expect(sw.elapsed, lessThan(const Duration(seconds: 10)));
    });
  });
}
