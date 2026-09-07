import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/dump_reply.dart' as dump_reply;

// Not an app/library behavioral test: dump_reply.dart is a hand-run
// diagnostic script (see its own doc comment — "reach for this before
// theorising about why a card failed to render"), and this file checks the
// script's own CLI wiring rather than anything under lib/src. Specifically:
// that --json-format actually changes the `format` key sent on the wire,
// and that omitting the flag sends no `format` key at all. A fake HTTP
// server stands in for Ollama so this runs without one; a bug here would
// mean the script silently investigates the wrong request shape while
// someone is mid-debugging a real model failure.
void main() {
  group('dump_reply --json-format pass-through', () {
    late HttpServer server;
    late List<Map<String, dynamic>> bodies;

    setUp(() async {
      bodies = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(() async {
        await for (final request in server) {
          final raw = await utf8.decoder.bind(request).join();
          bodies.add(jsonDecode(raw) as Map<String, dynamic>);
          request.response
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'message': {'content': '[]'},
              }),
            );
          await request.response.close();
        }
      }());
    });

    tearDown(() async {
      await server.close(force: true);
    });

    // Confirms resolveProbeFormat('schema') actually resolves to the loaded
    // card schema object and reaches the request body — the flag is only
    // useful for reproducing the server's constrained-decoding path if it's
    // wired to the same schema file, not just accepted and ignored.
    test('a format reaches the wire when --json-format is schema', () async {
      await dump_reply.main([
        '--url',
        'http://127.0.0.1:${server.port}',
        '--model',
        'test-model',
        '--prompt',
        'NOW',
        '--json-format',
        'schema',
      ]);
      expect(bodies.single['format'], isA<Map<String, dynamic>>());
    });

    // The default must mirror the server's own json_format=none — a probe
    // that sent an implicit format key by default would be measuring a
    // different request than the one operators are trying to diagnose.
    test('no format key is sent with the --json-format default', () async {
      await dump_reply.main([
        '--url',
        'http://127.0.0.1:${server.port}',
        '--model',
        'test-model',
        '--prompt',
        'NOW',
      ]);
      expect(bodies.single.containsKey('format'), isFalse);
    });
  });
}
