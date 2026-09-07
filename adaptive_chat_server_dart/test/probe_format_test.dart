import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';

// json_format_probe.dart exists to answer "does this model honor Ollama's
// `format` constraint?" — an answer only trustworthy if the probe sends
// exactly what the shipped server would send for the same `--json-format`
// flag. 'resolveProbeFormat' is an ordinary unit test of the mode-to-value
// mapping; 'probeOnce format pass-through' goes further and spins up a fake
// HTTP server to inspect the literal JSON body, because resolving the right
// value and actually attaching it to the request are two different places to
// get this wrong — it is a behavioral test of the probe script's own
// correctness, not of application code under lib/.

void main() {
  group('resolveProbeFormat', () {
    test('none yields no constraint', () {
      expect(resolveProbeFormat('none'), isNull);
    });

    test('json yields the bare json constraint', () {
      expect(resolveProbeFormat('json'), 'json');
    });

    test('schema yields the bundled card schema', () {
      // Checks it's the real, shipped assets/card_schema.json (its 'oneOf'
      // shape) rather than a hand-copied stand-in — a probe measuring
      // `--json-format schema` against a schema the server doesn't actually
      // use would be measuring the wrong thing.
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
      // resolveProbeFormat is unit-tested above in isolation; this is the
      // check that probeOnce actually attaches its result to the request
      // rather than computing it and dropping it on the floor.
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
      // A present-but-null 'format' is not the same wire request as an
      // absent key — mirroring the server's own unconstrained mode means
      // omitting the key entirely, not sending a null value for it.
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
