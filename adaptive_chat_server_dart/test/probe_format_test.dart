import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';

void main() {
  group('resolveProbeFormat', () {
    test('none yields no constraint', () {
      expect(resolveProbeFormat('none'), isNull);
    });

    test('json yields the bare json constraint', () {
      expect(resolveProbeFormat('json'), 'json');
    });

    test('schema yields the bundled card schema', () {
      final format = resolveProbeFormat('schema');
      expect(format, isA<Map<String, dynamic>>());
      expect((format! as Map<String, dynamic>).containsKey('oneOf'), isTrue);
    });
  });

  group('probeOnce format pass-through', () {
    late HttpServer server;
    late HttpClient client;
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
                'prompt_eval_count': 1,
                'eval_count': 1,
              }),
            );
          await request.response.close();
        }
      }());
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    test('a format reaches the wire when one is asked for', () async {
      await probeOnce(
        client: client,
        url: 'http://127.0.0.1:${server.port}',
        model: 'test-model',
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        format: resolveProbeFormat('json'),
      );
      expect(bodies.single['format'], 'json');
    });

    test('no format key is sent when none is asked for', () async {
      await probeOnce(
        client: client,
        url: 'http://127.0.0.1:${server.port}',
        model: 'test-model',
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        format: resolveProbeFormat('none'),
      );
      expect(bodies.single.containsKey('format'), isFalse);
    });
  });
}
