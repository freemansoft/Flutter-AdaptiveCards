import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:test/test.dart';

// stats.dart converts Ollama's raw /api/chat timing fields (nanoseconds,
// several of them optional) into what GET /status reports. Ollama serves
// one request at a time and older servers omit newer fields entirely
// (prompt_eval_cached_count arrived in 0.33.3), so this guards two distinct
// failure modes: a silently wrong ns-to-ms conversion (an off-by-1e6 would
// report timings that are plausible-looking but 1,000,000x off) and a
// missing/malformed field crashing the response instead of degrading to a
// default. This is a genuine unit suite over pure conversion functions --
// no file I/O, no data-model round trip.
void main() {
  group('fromOllamaResponse', () {
    // Every field at once, so a per-field test elsewhere passing does not
    // mask two fields being swapped against each other.
    test('full body populates all fields with ns-to-ms conversion', () {
      final stats = fromOllamaResponse({
        'prompt_eval_count': 120,
        'eval_count': 45,
        'total_duration': 8200000000,
        'load_duration': 12000000,
        'prompt_eval_duration': 900000000,
        'eval_duration': 7200000000,
      });
      expect(stats, isNotNull);
      expect(stats!.promptTokens, 120);
      expect(stats.replyTokens, 45);
      expect(stats.totalMs, 8200);
      expect(stats.loadMs, 12);
      expect(stats.promptEvalMs, 900);
      expect(stats.evalMs, 7200);
    });

    // promptTokens and replyTokens are required per fromOllamaResponse's
    // doc comment: a record without them answers no question worth asking,
    // so this must fail closed to null rather than return a half-filled
    // InteractionStats with a token count silently defaulted to 0.
    test('missing prompt_eval_count returns null', () {
      expect(fromOllamaResponse({'eval_count': 45}), isNull);
    });

    // A malformed token count is treated the same as a missing one -- a
    // string where Ollama would send an int is a sign of a shape change
    // upstream worth failing on, not something to coerce.
    test('non-int eval_count returns null', () {
      expect(
        fromOllamaResponse({'prompt_eval_count': 10, 'eval_count': '45'}),
        isNull,
      );
    });

    // Durations are supplementary, not required: unlike the token counts
    // above, a response missing every duration field still yields a usable
    // record rather than discarding tokens that were successfully read.
    test('missing duration fields default to 0, tokens preserved', () {
      final stats = fromOllamaResponse({
        'prompt_eval_count': 10,
        'eval_count': 5,
      });
      expect(stats, isNotNull);
      expect(stats!.totalMs, 0);
      expect(stats.loadMs, 0);
      expect(stats.promptEvalMs, 0);
      expect(stats.evalMs, 0);
    });

    test('prompt_eval_cached_count populates cachedPromptTokens', () {
      final stats = fromOllamaResponse({
        'prompt_eval_count': 66,
        'eval_count': 8,
        'prompt_eval_cached_count': 65,
      });
      expect(stats!.cachedPromptTokens, 65);
    });

    // Ollama servers older than 0.33.3 omit this field entirely; a response
    // from one of those must still parse, with cache reuse reading as
    // "none recorded" rather than failing the whole record.
    test(
      'missing prompt_eval_cached_count defaults to 0, tokens preserved',
      () {
        final stats = fromOllamaResponse({
          'prompt_eval_count': 10,
          'eval_count': 5,
        });
        expect(stats!.cachedPromptTokens, 0);
        expect(stats.promptTokens, 10);
      },
    );

    // Unlike a malformed required token count, a malformed cached-count is
    // supplementary and degrades to 0 -- it must not drag the whole
    // response down to null the way non-int eval_count does above.
    test('non-int prompt_eval_cached_count defaults to 0', () {
      final stats = fromOllamaResponse({
        'prompt_eval_count': 10,
        'eval_count': 5,
        'prompt_eval_cached_count': 'not-a-number',
      });
      expect(stats!.cachedPromptTokens, 0);
    });

    // _ms's `value is! int` guard exists precisely so a body with a
    // duration field of the wrong type falls back rather than crashing
    // `int ~/ _nsPerMs` on a non-numeric value.
    test('non-int duration field defaults to 0 rather than throwing', () {
      final stats = fromOllamaResponse({
        'prompt_eval_count': 10,
        'eval_count': 5,
        'total_duration': 'not-a-number',
      });
      expect(stats!.totalMs, 0);
    });
  });

  group('statsToJson', () {
    // totalTokens and tokensPerSecond are derived here rather than stored on
    // InteractionStats, per the class's own doc comment, so this is the one
    // place that can drift from the arithmetic a reader expects.
    test('derives totalTokens and tokensPerSecond', () {
      const stats = InteractionStats(
        promptTokens: 100,
        replyTokens: 50,
        totalMs: 1000,
        loadMs: 10,
        promptEvalMs: 200,
        evalMs: 500,
      );
      final json = statsToJson(stats);
      expect(json['totalTokens'], 150);
      expect(json['tokensPerSecond'], 100.0);
      expect(json['promptTokens'], 100);
      expect(json['replyTokens'], 50);
    });

    // cachedPromptTokens must reach the /status payload verbatim -- it is
    // the one figure this file exists for the server to expose at all.
    test('includes cachedPromptTokens', () {
      const stats = InteractionStats(
        promptTokens: 66,
        replyTokens: 8,
        totalMs: 150,
        loadMs: 5,
        promptEvalMs: 19,
        evalMs: 124,
        cachedPromptTokens: 65,
      );
      expect(statsToJson(stats)['cachedPromptTokens'], 65);
    });

    // Without the explicit `> 0` guard in statsToJson, a response with no
    // recorded generation time would divide by zero and crash the /status
    // endpoint instead of reporting 0.0.
    test('evalMs == 0 yields tokensPerSecond 0.0, no division error', () {
      const stats = InteractionStats(
        promptTokens: 10,
        replyTokens: 5,
        totalMs: 0,
        loadMs: 0,
        promptEvalMs: 0,
        evalMs: 0,
      );
      expect(statsToJson(stats)['tokensPerSecond'], 0.0);
    });

    // 10 tokens / 3s = 3.333...; this pins the rounding to one decimal
    // rather than truncating or reporting a long repeating fraction in the
    // JSON payload.
    test('tokensPerSecond rounds to one decimal place', () {
      const stats = InteractionStats(
        promptTokens: 1,
        replyTokens: 10,
        totalMs: 0,
        loadMs: 0,
        promptEvalMs: 0,
        evalMs: 3000,
      );
      expect(statsToJson(stats)['tokensPerSecond'], 3.3);
    });
  });
}
