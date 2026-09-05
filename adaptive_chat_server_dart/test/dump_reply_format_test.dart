import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/dump_reply.dart' as dump_reply;

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
