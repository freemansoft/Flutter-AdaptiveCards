import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:test/test.dart';

void main() {
  group('fromOllamaResponse', () {
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

    test('missing prompt_eval_count returns null', () {
      expect(fromOllamaResponse({'eval_count': 45}), isNull);
    });

    test('non-int eval_count returns null', () {
      expect(
        fromOllamaResponse({'prompt_eval_count': 10, 'eval_count': '45'}),
        isNull,
      );
    });

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
