/// Per-interaction Ollama usage: token counts plus where the time went.
///
/// Ollama returns these numbers on every `/api/chat` response. Capturing
/// them makes "what did that turn cost" and "how large has this conversation
/// grown" answerable after the fact, via `GET /status`.
library;

const _nsPerMs = 1000000;

/// What one Ollama turn cost: tokens in and out, plus the timing breakdown.
///
/// Stores only what Ollama reported. Derived figures (total tokens,
/// generation speed) are computed in [statsToJson] so this record stays a
/// faithful copy.
class InteractionStats {
  /// Creates a stats record with token counts and timing breakdown.
  const InteractionStats({
    required this.promptTokens,
    required this.replyTokens,
    required this.totalMs,
    required this.loadMs,
    required this.promptEvalMs,
    required this.evalMs,
  });

  /// Ollama `prompt_eval_count` — tokens sent.
  final int promptTokens;

  /// Ollama `eval_count` — tokens generated.
  final int replyTokens;

  /// `total_duration`, in milliseconds.
  final int totalMs;

  /// `load_duration` — model load, ~0 when already warm.
  final int loadMs;

  /// `prompt_eval_duration` — time reading the prompt.
  final int promptEvalMs;

  /// `eval_duration` — time generating.
  final int evalMs;
}

int _ms(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! int) return 0;
  return value ~/ _nsPerMs;
}

/// Builds stats from an Ollama `/api/chat` body, or `null` if unusable.
///
/// Both token counts are required: a record without them answers no
/// question worth asking, so a body missing them yields `null` rather than a
/// half-filled record. Durations are supplementary — a missing or malformed
/// one defaults to 0 instead of discarding usable token counts.
InteractionStats? fromOllamaResponse(Map<String, dynamic> data) {
  final promptTokens = data['prompt_eval_count'];
  final replyTokens = data['eval_count'];
  if (promptTokens is! int || replyTokens is! int) return null;
  return InteractionStats(
    promptTokens: promptTokens,
    replyTokens: replyTokens,
    totalMs: _ms(data, 'total_duration'),
    loadMs: _ms(data, 'load_duration'),
    promptEvalMs: _ms(data, 'prompt_eval_duration'),
    evalMs: _ms(data, 'eval_duration'),
  );
}

/// Serializes for the `/status` payload, deriving totals and speed.
///
/// `tokensPerSecond` is generation speed (reply tokens over generation
/// time), not end-to-end throughput — it excludes model load and prompt
/// evaluation, so it stays comparable across warm and cold turns. Zero when
/// `evalMs` is 0.
Map<String, dynamic> statsToJson(InteractionStats stats) {
  var tokensPerSecond = 0.0;
  if (stats.evalMs > 0) {
    final raw = stats.replyTokens / (stats.evalMs / 1000);
    tokensPerSecond = (raw * 10).round() / 10;
  }
  return {
    'promptTokens': stats.promptTokens,
    'replyTokens': stats.replyTokens,
    'totalTokens': stats.promptTokens + stats.replyTokens,
    'totalMs': stats.totalMs,
    'loadMs': stats.loadMs,
    'promptEvalMs': stats.promptEvalMs,
    'evalMs': stats.evalMs,
    'tokensPerSecond': tokensPerSecond,
  };
}
