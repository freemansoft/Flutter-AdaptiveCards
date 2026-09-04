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

  group('isolationArmOptions', () {
    // These two arms are what turns "the t=0 control disagreed" into a
    // re-runnable answer for *which* parameter is responsible, rather than
    // a claim that rests on a throwaway script. topk-topp-only isolates the
    // half of historicalDefaults that only constrains the sampling step
    // (expected inert under greedy decoding); presence-penalty-only
    // isolates the half that adjusts logits before the argmax (expected to
    // move even a greedy reply).
    test(
      'topk-topp-only carries top_k/top_p, not presence_penalty',
      () {
        final options = isolationArmOptions(
          temperature: 0,
          seed: 7,
          topKTopP: true,
        );
        expect(options['temperature'], 0);
        expect(options['seed'], 7);
        expect(options['top_k'], 40);
        expect(options['top_p'], 0.9);
        expect(options.containsKey('presence_penalty'), isFalse);
      },
    );

    test(
      'presence-penalty-only carries presence_penalty, not top_k/top_p',
      () {
        final options = isolationArmOptions(
          temperature: 0,
          seed: 7,
          topKTopP: false,
        );
        expect(options['temperature'], 0);
        expect(options['seed'], 7);
        expect(options['presence_penalty'], 0);
        expect(options.containsKey('top_k'), isFalse);
        expect(options.containsKey('top_p'), isFalse);
      },
    );
  });

  group('optionsForArm dispatch', () {
    test('every name in ggufProbeArmNames is a known arm', () {
      for (final arm in ggufProbeArmNames) {
        expect(
          () => optionsForArm(arm, temperature: 0.6, seed: 7),
          returnsNormally,
          reason: arm,
        );
      }
    });

    test('an unknown arm name throws rather than silently sending nothing', () {
      expect(
        () => optionsForArm('bogus', temperature: 0.6, seed: 7),
        throwsArgumentError,
      );
    });
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

    Future<void> sendArm(String arm) => probeOnce(
      client: client,
      url: 'http://127.0.0.1:${server.port}',
      model: 'qwen3.5:9b',
      systemPrompt: 'SYS',
      userPrompt: ggufProbeUserPrompt,
      options: optionsForArm(arm, temperature: 0.6, seed: 4242),
    );

    test(
      'unpinned: options carries temperature, num_ctx and seed, and no '
      'candidate-set knobs',
      () async {
        await sendArm('unpinned');
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
        await sendArm('pinned-historical');
        final options = bodies.single['options'] as Map<String, dynamic>;
        expect(options['temperature'], 0.6);
        expect(options['seed'], 4242);
        expect(options.containsKey('num_ctx'), isTrue);
        expect(options['top_k'], 40);
        expect(options['top_p'], 0.9);
        expect(options['presence_penalty'], 0);
      },
    );

    test(
      'topk-topp-only: options carries top_k/top_p and num_ctx, not '
      'presence_penalty',
      () async {
        await sendArm('topk-topp-only');
        final options = bodies.single['options'] as Map<String, dynamic>;
        expect(options['temperature'], 0.6);
        expect(options['seed'], 4242);
        expect(options.containsKey('num_ctx'), isTrue);
        expect(options['top_k'], 40);
        expect(options['top_p'], 0.9);
        expect(options.containsKey('presence_penalty'), isFalse);
      },
    );

    test(
      'presence-penalty-only: options carries presence_penalty and '
      'num_ctx, not top_k/top_p',
      () async {
        await sendArm('presence-penalty-only');
        final options = bodies.single['options'] as Map<String, dynamic>;
        expect(options['temperature'], 0.6);
        expect(options['seed'], 4242);
        expect(options.containsKey('num_ctx'), isTrue);
        expect(options['presence_penalty'], 0);
        expect(options.containsKey('top_k'), isFalse);
        expect(options.containsKey('top_p'), isFalse);
      },
    );

    test('every arm sends the identical seed and identical messages', () async {
      for (final arm in ggufProbeArmNames) {
        await sendArm(arm);
      }
      expect(bodies, hasLength(ggufProbeArmNames.length));
      final seeds = [
        for (final body in bodies)
          (body['options'] as Map<String, dynamic>)['seed'],
      ];
      expect(seeds.toSet(), {4242}, reason: 'every arm must share one seed');
      final messageSets = [for (final body in bodies) body['messages']];
      for (final messages in messageSets.skip(1)) {
        expect(messages, messageSets.first);
      }
    });
  });
}
