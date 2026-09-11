import 'dart:convert';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';

// judgeReply is the one place a probe turns a raw reply into a
// ProbeOutcome, so promptEvalCount -- the actual token count Ollama reports
// for the request that produced the reply -- has to survive that trip
// unchanged. context_fill_probe calibrates its filler text against this
// field; if judgeReply silently dropped it, calibration would compare
// against nothing instead of failing loudly.
void main() {
  group('judgeReply promptEvalCount', () {
    test('carries the measured token count into the outcome', () {
      final outcome = judgeReply(
        'why is the sky blue',
        12,
        promptEvalCount: 4096,
      );
      expect(outcome.promptEvalCount, 4096);
    });

    test('defaults to null when the caller has no count', () {
      final outcome = judgeReply('why is the sky blue', 12);
      expect(outcome.promptEvalCount, isNull);
    });
  });

  // /api/ps is the only place the runner says what context it actually
  // allocated. context_fill_probe records `numCtx` -- the value it asked for
  // -- which is silent about clamping: a run whose filler vanished and a run
  // whose filler was ingested record the identical number. Parsing is split
  // out from the HTTP call so the shapes that matter can be tested without a
  // live Ollama, including the ones that must degrade to null rather than
  // throw and cost a 30-minute sweep its result.
  group('parseRunnerStatus', () {
    String bodyFor(String name, {int? contextLength = 35851}) => jsonEncode({
      'models': [
        {
          'name': name,
          'model': name,
          'size': 3213224836,
          'size_vram': 3213224836,
          'context_length': ?contextLength,
        },
      ],
    });

    test('reads the allocated context for the requested model', () {
      final status = parseRunnerStatus(
        bodyFor('granite4.1:8b'),
        'granite4.1:8b',
      );
      expect(status, isNotNull);
      expect(status!.contextLength, 35851);
      expect(status.sizeVram, 3213224836);
    });

    test('matches a bare tag against the :latest the server reports', () {
      final status = parseRunnerStatus(bodyFor('llama3.2:latest'), 'llama3.2');
      expect(status?.contextLength, 35851);
    });

    test('returns null when another model is resident', () {
      expect(parseRunnerStatus(bodyFor('granite4.1:3b'), 'qwen3.5:9b'), isNull);
    });

    test('returns null when nothing is resident', () {
      expect(
        parseRunnerStatus(jsonEncode({'models': <Object>[]}), 'qwen3.5:9b'),
        isNull,
      );
    });

    test('returns null rather than throwing on a malformed body', () {
      expect(parseRunnerStatus('not json at all', 'qwen3.5:9b'), isNull);
      expect(parseRunnerStatus('', 'qwen3.5:9b'), isNull);
      expect(parseRunnerStatus(jsonEncode({'oops': 1}), 'qwen3.5:9b'), isNull);
    });

    // An older Ollama, or a runner that does not report the field, must not
    // produce a zero that reads as "clamped to nothing" in the archive.
    test('leaves contextLength null when the server omits it', () {
      final status = parseRunnerStatus(
        bodyFor('granite4.1:8b', contextLength: null),
        'granite4.1:8b',
      );
      expect(status, isNotNull);
      expect(status!.contextLength, isNull);
    });
  });
}
