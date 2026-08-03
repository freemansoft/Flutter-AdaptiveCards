from app.stats import InteractionStats, from_ollama_response, to_dict

# A complete Ollama /api/chat body. Durations are nanoseconds — Ollama's unit.
_FULL = {
    "prompt_eval_count": 1500,
    "eval_count": 300,
    "total_duration": 8_200_000_000,
    "load_duration": 12_000_000,
    "prompt_eval_duration": 900_000_000,
    "eval_duration": 7_200_000_000,
}


def test_from_ollama_response_converts_nanoseconds_to_ms():
    assert from_ollama_response(_FULL) == InteractionStats(
        prompt_tokens=1500,
        reply_tokens=300,
        total_ms=8200,
        load_ms=12,
        prompt_eval_ms=900,
        eval_ms=7200,
    )


def test_from_ollama_response_without_token_counts_returns_none():
    assert from_ollama_response({}) is None
    assert from_ollama_response({"prompt_eval_count": 10}) is None
    assert from_ollama_response({"eval_count": 10}) is None


def test_from_ollama_response_with_non_int_counts_returns_none():
    assert from_ollama_response({"prompt_eval_count": "10", "eval_count": 5}) is None
    assert from_ollama_response({"prompt_eval_count": 10, "eval_count": None}) is None


def test_from_ollama_response_defaults_missing_durations_to_zero():
    stats = from_ollama_response({"prompt_eval_count": 10, "eval_count": 5})
    assert stats is not None
    assert stats.prompt_tokens == 10
    assert stats.reply_tokens == 5
    assert (stats.total_ms, stats.load_ms, stats.prompt_eval_ms, stats.eval_ms) == (0, 0, 0, 0)


def test_from_ollama_response_ignores_non_int_durations():
    stats = from_ollama_response(
        {"prompt_eval_count": 10, "eval_count": 5, "total_duration": "slow"}
    )
    assert stats is not None
    assert stats.total_ms == 0


def test_to_dict_derives_total_tokens_and_speed():
    body = to_dict(from_ollama_response(_FULL))
    assert body["totalTokens"] == 1800
    assert body["tokensPerSecond"] == 41.7
    assert body["promptTokens"] == 1500
    assert body["replyTokens"] == 300
    assert body["evalMs"] == 7200


def test_to_dict_guards_zero_eval_ms():
    stats = InteractionStats(
        prompt_tokens=1,
        reply_tokens=5,
        total_ms=0,
        load_ms=0,
        prompt_eval_ms=0,
        eval_ms=0,
    )
    assert to_dict(stats)["tokensPerSecond"] == 0.0
