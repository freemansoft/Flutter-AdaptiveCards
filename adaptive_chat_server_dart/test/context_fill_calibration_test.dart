import 'package:test/test.dart';

// Relative: this lives outside lib/.
import '../tool/model_probes/context_fill_probe.dart';

// The fixed fillerCharsPerToken=4.0 constant sized history in characters
// and silently overflowed num_ctx on any tokenizer denser than the llama
// family's ~4.30 chars/token, which is what produced the retracted
// "models discard history they had room for" reading. These cover the
// arithmetic that replaces it: turn a measured prompt_eval_count into a
// ratio, and refuse a reading that cannot be one.
void main() {
  group('charsPerTokenFrom', () {
    test('derives the ratio a measured sample implies', () {
      // 12000 characters that cost 4000 tokens is 3.0 chars/token.
      expect(charsPerTokenFrom(sampleChars: 12000, promptEvalCount: 4000), 3.0);
    });

    test('reproduces the llama-family figure this file records', () {
      // 127,020 chars at 29546 tokens is the measured llama3.2 reading.
      final r = charsPerTokenFrom(sampleChars: 127020, promptEvalCount: 29546);
      expect(r, isNotNull);
      expect(r, closeTo(4.30, 0.01));
    });

    test('reproduces the denser Qwen figure this file records', () {
      final r = charsPerTokenFrom(sampleChars: 127020, promptEvalCount: 42542);
      expect(r, closeTo(2.99, 0.01));
    });

    // A zero, negative or absent count is "no reading", not a ratio. An
    // unguarded division here would produce Infinity and size a filler
    // from it.
    test('returns null rather than a nonsense ratio', () {
      expect(charsPerTokenFrom(sampleChars: 12000, promptEvalCount: 0), isNull);
      expect(
        charsPerTokenFrom(sampleChars: 12000, promptEvalCount: -1),
        isNull,
      );
      expect(
        charsPerTokenFrom(sampleChars: 12000, promptEvalCount: null),
        isNull,
      );
      expect(charsPerTokenFrom(sampleChars: 0, promptEvalCount: 4000), isNull);
    });

    // The count carries a few tokens of chat-template overhead the sample
    // text did not contain, so the derived ratio runs slightly low and the
    // filler built from it lands slightly under target. Undershooting is
    // the safe direction: it cannot overflow the window.
    test('overhead in the count biases the ratio low, not high', () {
      final clean = charsPerTokenFrom(
        sampleChars: 12000,
        promptEvalCount: 4000,
      )!;
      final withOverhead = charsPerTokenFrom(
        sampleChars: 12000,
        promptEvalCount: 4020,
      )!;
      expect(withOverhead, lessThan(clean));
    });
  });

  group('buildFillerText with a measured ratio', () {
    test('sizes the text so a denser tokenizer still hits the target', () {
      // At 2.99 chars/token, 28000 tokens needs ~83,720 chars, not the
      // 112,000 the 4.0 constant would have produced.
      final dense = buildFillerText(28000, charsPerToken: 2.99);
      final assumed = buildFillerText(28000);
      expect(dense.length, lessThan(assumed.length));
      expect((dense.length / 2.99).round(), closeTo(28000, 40));
    });
  });
}
