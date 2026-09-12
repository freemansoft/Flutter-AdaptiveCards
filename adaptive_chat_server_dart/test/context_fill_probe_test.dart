import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/context_fill_probe.dart';

// context_fill_probe exists to answer one question: does a model still
// function once its context is mostly filled, on a machine tight enough
// that the answer might be "no". buildFillerText is the piece that has to
// be trustworthy for that to mean anything -- if it silently under- or
// over-shoots the requested token budget, a run that reports "handled
// 28k tokens fine" may not have sent 28k tokens at all. defaultNumCtxFor
// is the other piece worth pinning: get the margin wrong and num_ctx sits
// at or below the filler itself, and Ollama silently truncates the prompt
// instead of the probe actually exercising the requested context size.
void main() {
  group('buildFillerText', () {
    test('reaches at least the requested token budget in characters', () {
      final filler = buildFillerText(1000);
      expect(filler.length, greaterThanOrEqualTo(1000 * fillerCharsPerToken));
    });

    test('is deterministic across calls with the same target', () {
      expect(buildFillerText(500), buildFillerText(500));
    });

    test('a larger target produces longer filler', () {
      expect(
        buildFillerText(2000).length,
        greaterThan(buildFillerText(500).length),
      );
    });

    test('a non-positive target produces no filler', () {
      expect(buildFillerText(0), isEmpty);
      expect(buildFillerText(-10), isEmpty);
    });
  });

  group('defaultNumCtxFor', () {
    test('adds the default margin on top of the fill target', () {
      expect(defaultNumCtxFor(28000), 28000 + defaultFillMargin);
    });

    test('honors an explicit margin', () {
      expect(defaultNumCtxFor(1000, margin: 500), 1500);
    });

    // The bug this guards against: a real run's system prompt (~15KB, ~4800
    // tokens) was never budgeted for, so num_ctx sized off the fill target
    // alone left the actual request short of its own window before the
    // filler even mattered -- see ModelBehavior.md's context-fill section.
    test('adds systemPromptTokens on top of the fill target and margin', () {
      expect(
        defaultNumCtxFor(28000, systemPromptTokens: 4800),
        28000 + 4800 + defaultFillMargin,
      );
    });

    test('defaults systemPromptTokens to zero', () {
      expect(defaultNumCtxFor(1000, margin: 0), 1000);
    });
  });

  group('estimateTokenCount', () {
    test('estimates via charsPerToken', () {
      expect(estimateTokenCount('a' * 400), 100);
    });

    test('rounds up a partial token', () {
      expect(estimateTokenCount('a' * 401), 101);
    });

    test('is zero for empty text', () {
      expect(estimateTokenCount(''), 0);
    });
  });
}
