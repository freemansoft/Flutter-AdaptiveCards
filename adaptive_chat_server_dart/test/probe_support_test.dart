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
}
