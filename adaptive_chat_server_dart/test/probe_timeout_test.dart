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
