import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';

void main() {
  group('probeOnce timeout', () {
    late HttpServer server;
    late HttpClient client;

    setUp(() async {
      // Accepts the request and then never answers — the shape of a model
      // that has run away generating. `granite4.1:3b` was observed doing
      // exactly this for 16 minutes on one `table` case.
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((_) {});
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
