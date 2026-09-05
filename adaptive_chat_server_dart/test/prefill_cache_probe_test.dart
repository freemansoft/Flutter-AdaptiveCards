import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// Relative: these files and their probe both live outside lib/. Aliased --
// this test file has its own top-level main().
import '../tool/model_probes/prefill_cache_probe.dart' as probe;
import '../tool/model_probes/probe_results.dart';

void main() {
  group('prefill_cache_probe --json', () {
    late HttpServer server;
    late int charlieCount;
    late Directory tmpDir;

    setUp(() async {
      charlieCount = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(() async {
        await for (final request in server) {
          final raw = await utf8.decoder.bind(request).join();
          final body = jsonDecode(raw) as Map<String, dynamic>;
          final messages = body['messages'] as List<dynamic>?;
          try {
            if (messages == null) {
              // The unload call: {'model': ..., 'keep_alive': 0}, no
              // messages. Answer it and move on.
              request.response
                ..headers.contentType = ContentType.json
                ..write(jsonEncode(<String, dynamic>{}));
              await request.response.close();
              continue;
            }
            final userContent = (messages.last as Map)['content'] as String;
            if (userContent.contains('charlie-term7')) {
              charlieCount++;
              if (charlieCount == 1) {
                // Simulate a prefill slow enough for the probe's 400ms
                // abort timer to fire before this reply would otherwise
                // land, so `_call` observes an aborted request rather than
                // a completed one.
                await Future<void>.delayed(const Duration(milliseconds: 700));
              }
            }
            request.response
              ..headers.contentType = ContentType.json
              ..write(
                jsonEncode({
                  'message': {'content': 'reply to $userContent'},
                  'prompt_eval_count': 100,
                  'prompt_eval_cached_count': 90,
                  // Nanoseconds, per Ollama's API -- 5ms and 8ms once the
                  // probe divides by 1e6.
                  'prompt_eval_duration': 5000000,
                  'total_duration': 8000000,
                }),
              );
            await request.response.close();
          } on Object {
            // The aborted request's client has already disconnected by the
            // time this reply would go out; nothing to do.
          }
        }
      }());
      tmpDir = Directory.systemTemp.createTempSync('prefill_cache_probe_test');
    });

    tearDown(() async {
      await server.close(force: true);
      tmpDir.deleteSync(recursive: true);
    });

    test(
      'writes one call per request across the five phases, structured '
      'figures in summary, and round-trips',
      () async {
        final path = p.join(tmpDir.path, 'run.json');

        await probe.main([
          '--model',
          'test-model',
          '--url',
          'http://127.0.0.1:${server.port}',
          '--json',
          path,
        ]);

        // The file on disk uses the `case` key, not `caseId` -- ProbeCall's
        // documented serialisation gotcha.
        final raw =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        final rawCalls = raw['calls'] as List;
        expect(rawCalls, isNotEmpty);
        for (final c in rawCalls) {
          expect((c as Map<String, dynamic>).containsKey('case'), isTrue);
          expect(c.containsKey('caseId'), isFalse);
        }

        // Round-trip: read the file back through ProbeRun and check the
        // figures the probe reported survive.
        final run = ProbeRun.read(File(path));
        expect(run.probe, 'prefill_cache_probe');
        expect(run.model, 'test-model');

        const expectedPhaseCounts = {
          'identical-repeat': 2,
          'new-question': 1,
          'growing-conversation': 3,
          'interleaved': 2,
          'retry-after-abort': 2,
        };
        final byPhase = <String, List<ProbeCall>>{};
        for (final call in run.calls) {
          byPhase.putIfAbsent(call.caseId, () => []).add(call);
        }
        expect(byPhase.keys.toSet(), expectedPhaseCounts.keys.toSet());
        for (final entry in expectedPhaseCounts.entries) {
          expect(
            byPhase[entry.key],
            hasLength(entry.value),
            reason: entry.key,
          );
        }
        expect(
          run.calls.length,
          expectedPhaseCounts.values.reduce((a, b) => a + b),
        );

        // pass records completion, not cache behaviour: the deliberately
        // aborted call in retry-after-abort is the one call that did not
        // complete.
        final retryPhase = byPhase['retry-after-abort']!;
        final aborted = retryPhase.firstWhere((c) => c.condition == 'aborted');
        final retried = retryPhase.firstWhere((c) => c.condition == 'retry');
        expect(aborted.pass, isFalse);
        expect(retried.pass, isTrue);
        expect(
          run.calls.where((c) => c.caseId != 'retry-after-abort'),
          everyElement(predicate<ProbeCall>((c) => c.pass)),
        );

        // Every completed call's figures are machine-readable in summary,
        // not only inside label's prose.
        final identicalRepeat =
            run.summary['identical-repeat'] as List<dynamic>;
        expect(identicalRepeat, hasLength(2));
        final cold = identicalRepeat.first as Map<String, dynamic>;
        expect(cold['label'], 'cold');
        expect(cold['prompt'], 100);
        expect(cold['cached'], 90);
        expect(cold['prefillMs'], 5);
        expect(cold['totalMs'], 8);

        // The aborted call reported no figures -- there was no reply to
        // read them from -- so it is absent from retry-after-abort's first
        // summary entry beyond its label.
        final retrySummary = run.summary['retry-after-abort'] as List<dynamic>;
        final abortedSummary = retrySummary.first as Map<String, dynamic>;
        expect(abortedSummary['label'], 'aborted');
        expect(abortedSummary.containsKey('prompt'), isFalse);
        final retriedSummary = retrySummary.last as Map<String, dynamic>;
        expect(retriedSummary['label'], 'retry');
        expect(retriedSummary['prompt'], 100);
        expect(retriedSummary['cached'], 90);
      },
    );
  });
}
