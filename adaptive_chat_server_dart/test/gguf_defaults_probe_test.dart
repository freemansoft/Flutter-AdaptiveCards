import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/gguf_defaults_probe.dart';
import '../tool/model_probes/probe_support.dart';

void main() {
  group('armOptions', () {
    test(
      'unpinned carries temperature and seed, not the candidate-set knobs',
      () {
        final options = armOptions(
          temperature: 0.6,
          seed: 7,
          pinnedHistorical: false,
        );
        expect(options['temperature'], 0.6);
        expect(options['seed'], 7);
        expect(options.containsKey('top_k'), isFalse);
        expect(options.containsKey('top_p'), isFalse);
        expect(options.containsKey('presence_penalty'), isFalse);
      },
    );

    test(
      'pinned-historical adds the pre-0.33.3 defaults on top of the same '
      'temperature and seed',
      () {
        final options = armOptions(
          temperature: 0.6,
          seed: 7,
          pinnedHistorical: true,
        );
        expect(options['temperature'], 0.6);
        expect(options['seed'], 7);
        expect(options['top_k'], 40);
        expect(options['top_p'], 0.9);
        expect(options['presence_penalty'], 0);
      },
    );
  });

  group('probeOnce request bodies for each arm', () {
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
                'message': {'content': 'prose reply'},
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

    Future<void> sendArm({required bool pinnedHistorical}) => probeOnce(
      client: client,
      url: 'http://127.0.0.1:${server.port}',
      model: 'qwen3.5:9b',
      systemPrompt: 'SYS',
      userPrompt: ggufProbeUserPrompt,
      options: armOptions(
        temperature: 0.6,
        seed: 4242,
        pinnedHistorical: pinnedHistorical,
      ),
    );

    test(
      'unpinned: options carries temperature, num_ctx and seed, and no '
      'candidate-set knobs',
      () async {
        await sendArm(pinnedHistorical: false);
        final options = bodies.single['options'] as Map<String, dynamic>;
        expect(options['temperature'], 0.6);
        expect(options['seed'], 4242);
        expect(options.containsKey('num_ctx'), isTrue);
        expect(options.containsKey('top_k'), isFalse);
        expect(options.containsKey('top_p'), isFalse);
        expect(options.containsKey('presence_penalty'), isFalse);
      },
    );

    test(
      'pinned-historical: options carries all of those, with the '
      'pre-0.33.3 default values',
      () async {
        await sendArm(pinnedHistorical: true);
        final options = bodies.single['options'] as Map<String, dynamic>;
        expect(options['temperature'], 0.6);
        expect(options['seed'], 4242);
        expect(options.containsKey('num_ctx'), isTrue);
        expect(options['top_k'], 40);
        expect(options['top_p'], 0.9);
        expect(options['presence_penalty'], 0);
      },
    );

    test('both arms send the identical seed and identical messages', () async {
      await sendArm(pinnedHistorical: false);
      await sendArm(pinnedHistorical: true);
      expect(bodies, hasLength(2));
      final unpinnedOptions = bodies[0]['options'] as Map<String, dynamic>;
      final pinnedOptions = bodies[1]['options'] as Map<String, dynamic>;
      expect(unpinnedOptions['seed'], pinnedOptions['seed']);
      expect(bodies[0]['messages'], bodies[1]['messages']);
    });
  });
}
