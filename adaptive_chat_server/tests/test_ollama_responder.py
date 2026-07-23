import json
import logging

import httpx

from app.ollama_responder import CARD_SCHEMA_PATH, DEFAULT_NUM_CTX, OllamaResponder, _load_card_schema
from app.ollama_responder import DEFAULT_JSON_FORMAT

# Single source of truth for these tests — change the model/host/port here, not
# in each test. (These drive the mocked transport; no live Ollama is contacted.)
OLLAMA_HOST = "127.0.0.1"
OLLAMA_PORT = 11434
OLLAMA_URL = f"http://{OLLAMA_HOST}:{OLLAMA_PORT}"
OLLAMA_MODEL = "gpt-oss:20b"


def _client(handler):
    return httpx.Client(transport=httpx.MockTransport(handler))


def _responder(
    handler,
    system_prompt_file=None,
    history_turns=10,
    num_ctx=4096,
    json_format="none",
):
    return OllamaResponder(
        OLLAMA_URL,
        model=OLLAMA_MODEL,
        client=_client(handler),
        system_prompt_file=system_prompt_file,
        history_turns=history_turns,
        num_ctx=num_ctx,
        json_format=json_format,
    )


def _ok_capturing_handler(captured):
    def handler(request: httpx.Request) -> httpx.Response:
        captured["url"] = str(request.url)
        captured["body"] = json.loads(request.content)
        return httpx.Response(
            200,
            json={"message": {"role": "assistant", "content": "hi from ollama"}},
        )

    return handler


def _handler_with_prompt_tokens(captured, prompt_eval_count):
    def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = json.loads(request.content)
        return httpx.Response(
            200,
            json={
                "message": {"role": "assistant", "content": "ok"},
                "prompt_eval_count": prompt_eval_count,
            },
        )

    return handler


def test_load_card_schema_returns_dict_for_valid_file(tmp_path):
    schema_file = tmp_path / "card_schema.json"
    schema_file.write_text(
        json.dumps({"$defs": {"Element": {}}, "oneOf": []}), encoding="utf-8"
    )
    assert _load_card_schema(schema_file) == {"$defs": {"Element": {}}, "oneOf": []}


def test_load_card_schema_returns_none_for_missing_file(tmp_path, caplog):
    missing = tmp_path / "no_such_schema.json"
    with caplog.at_level(logging.ERROR, logger="uvicorn.error"):
        assert _load_card_schema(missing) is None
    assert "unusable" in caplog.text


def test_load_card_schema_returns_none_for_invalid_json(tmp_path, caplog):
    bad = tmp_path / "bad.json"
    bad.write_text("{not valid json", encoding="utf-8")
    with caplog.at_level(logging.ERROR, logger="uvicorn.error"):
        assert _load_card_schema(bad) is None
    assert "unusable" in caplog.text


def test_load_card_schema_returns_none_when_missing_expected_keys(tmp_path, caplog):
    incomplete = tmp_path / "incomplete.json"
    incomplete.write_text(json.dumps({"type": "object"}), encoding="utf-8")
    with caplog.at_level(logging.ERROR, logger="uvicorn.error"):
        assert _load_card_schema(incomplete) is None
    assert "oneOf" in caplog.text


def test_bundled_card_schema_loads_successfully():
    # The real shipped file must itself pass the loader's own sanity check.
    schema = _load_card_schema(CARD_SCHEMA_PATH)
    assert schema is not None
    assert schema["oneOf"]


def test_reply_posts_history_and_new_turn_to_chat_endpoint(tmp_path):
    # Point at a nonexistent prompt file so no system message is injected —
    # this keeps the exact-body assertion decoupled from the default prompt.
    missing = tmp_path / "no_such_prompt.txt"
    captured = {}

    history = [("user", "earlier question"), ("assistant", "earlier answer")]
    result = _responder(
        _ok_capturing_handler(captured), system_prompt_file=str(missing)
    ).reply("new question", history)

    assert result.text == "hi from ollama"
    assert captured["url"] == f"{OLLAMA_URL}/api/chat"
    assert captured["body"] == {
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "user", "content": "earlier question"},
            {"role": "assistant", "content": "earlier answer"},
            {"role": "user", "content": "new question"},
        ],
        "stream": False,
        "options": {"num_ctx": 4096},
    }


def test_reply_prepends_system_prompt_from_file(tmp_path):
    prompt_file = tmp_path / "system.txt"
    prompt_file.write_text("  You are a terse assistant.\n", encoding="utf-8")
    captured = {}

    _responder(
        _ok_capturing_handler(captured), system_prompt_file=str(prompt_file)
    ).reply("hello", [("user", "hi"), ("assistant", "hey")])

    # System message is first and whitespace-stripped; history + turn follow.
    assert captured["body"]["messages"] == [
        {"role": "system", "content": "You are a terse assistant."},
        {"role": "user", "content": "hi"},
        {"role": "assistant", "content": "hey"},
        {"role": "user", "content": "hello"},
    ]


def test_reply_skips_system_message_when_prompt_file_missing(tmp_path):
    missing = tmp_path / "gone.txt"
    captured = {}

    result = _responder(
        _ok_capturing_handler(captured), system_prompt_file=str(missing)
    ).reply("hello", [])

    # A bad path is not fatal: reply still succeeds and no system message is sent.
    assert result.text == "hi from ollama"
    assert captured["body"]["messages"] == [{"role": "user", "content": "hello"}]


def test_reply_skips_system_message_when_prompt_file_empty(tmp_path):
    empty = tmp_path / "empty.txt"
    empty.write_text("   \n", encoding="utf-8")
    captured = {}

    _responder(
        _ok_capturing_handler(captured), system_prompt_file=str(empty)
    ).reply("hello", [])

    assert captured["body"]["messages"] == [{"role": "user", "content": "hello"}]


def test_reply_rereads_prompt_file_each_request(tmp_path):
    prompt_file = tmp_path / "live.txt"
    prompt_file.write_text("first prompt", encoding="utf-8")
    captured = {}
    responder = _responder(
        _ok_capturing_handler(captured), system_prompt_file=str(prompt_file)
    )

    responder.reply("q1", [])
    assert captured["body"]["messages"][0] == {
        "role": "system",
        "content": "first prompt",
    }

    # Edit the file between requests; the change must apply without a new instance.
    prompt_file.write_text("second prompt", encoding="utf-8")
    responder.reply("q2", [])
    assert captured["body"]["messages"][0] == {
        "role": "system",
        "content": "second prompt",
    }


def test_reply_reports_connection_failure_with_exception_detail():
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("connection refused", request=request)

    result = _responder(handler).reply("hello", [])

    # Still identifies the endpoint, but now surfaces the exception type/detail
    # instead of hiding it behind a generic "unreachable".
    assert result.text.startswith(f"(Ollama unreachable at {OLLAMA_URL}")
    assert "ConnectError" in result.text
    assert "connection refused" in result.text


def test_reply_reports_http_error_status_and_body():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(404, json={"error": f'model "{OLLAMA_MODEL}" not found'})

    result = _responder(handler).reply("hello", [])

    # A reachable-but-erroring Ollama (e.g. model not pulled) is NOT "unreachable".
    assert result.text.startswith(f"(Ollama error HTTP 404 at {OLLAMA_URL}")
    assert "not found" in result.text


def test_reply_reports_unexpected_response_body():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"unexpected": "shape"})

    result = _responder(handler).reply("hello", [])

    assert result.text == "(Ollama returned an unexpected response: KeyError)"


def test_reply_trims_history_to_last_n_turns(tmp_path):
    missing = tmp_path / "no_prompt.txt"  # no system message, keep body exact
    captured = {}
    history = [
        ("user", "u1"), ("assistant", "a1"),
        ("user", "u2"), ("assistant", "a2"),
        ("user", "u3"), ("assistant", "a3"),
    ]
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        history_turns=2,
    ).reply("now", history)

    # Only the last 2 exchanges survive, then the current turn.
    assert captured["body"]["messages"] == [
        {"role": "user", "content": "u2"},
        {"role": "assistant", "content": "a2"},
        {"role": "user", "content": "u3"},
        {"role": "assistant", "content": "a3"},
        {"role": "user", "content": "now"},
    ]


def test_reply_sends_no_prior_history_when_turns_zero(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    history = [("user", "u1"), ("assistant", "a1")]
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        history_turns=0,
    ).reply("now", history)

    assert captured["body"]["messages"] == [{"role": "user", "content": "now"}]


def test_reply_does_not_mutate_caller_history(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    history = [("user", "u1"), ("assistant", "a1"), ("user", "u2"), ("assistant", "a2")]
    original = list(history)
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        history_turns=1,
    ).reply("now", history)

    assert history == original  # trim is send-only


def test_default_context_window_is_16k(tmp_path):
    # The default context window is 16K tokens — large enough for multi-page card
    # replies without Ollama silently dropping the oldest tokens.
    assert DEFAULT_NUM_CTX == 16384
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    # Construct directly (not via _responder, which pins num_ctx) so the DEFAULT
    # flows through to the request payload.
    OllamaResponder(
        OLLAMA_URL,
        model=OLLAMA_MODEL,
        client=_client(_ok_capturing_handler(captured)),
        system_prompt_file=str(missing),
    ).reply("hi", [])
    assert captured["body"]["options"]["num_ctx"] == DEFAULT_NUM_CTX


def test_reply_sends_num_ctx_option(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    _responder(
        _handler_with_prompt_tokens(captured, 10),
        system_prompt_file=str(missing),
        num_ctx=2048,
    ).reply("hi", [])

    assert captured["body"]["options"] == {"num_ctx": 2048}


def test_fill_below_50pct_logs_nothing(tmp_path, caplog):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _handler_with_prompt_tokens(captured, 400),  # 40% of 1000
            system_prompt_file=str(missing),
            num_ctx=1000,
        ).reply("hi", [])
    assert "context filling" not in caplog.text
    assert "context near limit" not in caplog.text


def test_fill_between_50_and_76pct_logs_info(tmp_path, caplog):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _handler_with_prompt_tokens(captured, 600),  # 60% of 1000
            system_prompt_file=str(missing),
            num_ctx=1000,
        ).reply("hi", [])
    assert "context filling" in caplog.text
    assert "context near limit" not in caplog.text


def test_fill_at_or_above_76pct_logs_warning(tmp_path, caplog):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _handler_with_prompt_tokens(captured, 800),  # 80% of 1000
            system_prompt_file=str(missing),
            num_ctx=1000,
        ).reply("hi", [])
    assert "context near limit" in caplog.text
    assert any(r.levelname == "WARNING" for r in caplog.records)


def test_fill_logging_skipped_when_prompt_eval_count_absent(tmp_path, caplog):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        result = _responder(
            _ok_capturing_handler(captured),  # response has no prompt_eval_count
            system_prompt_file=str(missing),
            num_ctx=1000,
        ).reply("hi", [])
    assert result.text == "hi from ollama"
    assert "context filling" not in caplog.text
    assert "context near limit" not in caplog.text


def test_reply_detects_card_output_as_card_body(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = json.loads(request.content)
        card = '{"type": "AdaptiveCard", "body": [{"type": "Input.Date", "id": "d"}]}'
        return httpx.Response(200, json={"message": {"role": "assistant", "content": card}})

    result = _responder(handler, system_prompt_file=str(missing)).reply("date?", [])

    assert result.card_body == [{"type": "Input.Date", "id": "d"}]
    # raw text is preserved for history
    assert '"AdaptiveCard"' in result.text


def test_reply_plain_text_has_no_card_body(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    result = _responder(
        _ok_capturing_handler({}), system_prompt_file=str(missing)
    ).reply("hi", [])

    assert result.text == "hi from ollama"
    assert result.card_body is None


def test_reply_logs_raw_content_at_debug_level(tmp_path, caplog):
    # Opt-in content diagnostics: at DEBUG the verbatim model output and the
    # detection result are logged so a text-instead-of-card reply is diagnosable.
    missing = tmp_path / "no_prompt.txt"
    with caplog.at_level(logging.DEBUG, logger="uvicorn.error"):
        _responder(
            _ok_capturing_handler({}), system_prompt_file=str(missing)
        ).reply("hi", [])
    assert "detected_card" in caplog.text
    assert "hi from ollama" in caplog.text
    # The active model is logged so each captured reply is attributable.
    assert OLLAMA_MODEL in caplog.text


def test_reply_does_not_log_raw_content_at_info_level(tmp_path, caplog):
    # Off by default: nothing content-level is emitted at the normal INFO level.
    missing = tmp_path / "no_prompt.txt"
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _ok_capturing_handler({}), system_prompt_file=str(missing)
        ).reply("hi", [])
    assert "detected_card" not in caplog.text


def _handler_returning_content(content):
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200, json={"message": {"role": "assistant", "content": content}}
        )

    return handler


def test_reply_warns_when_reply_looked_like_a_card_but_was_malformed(tmp_path, caplog):
    # A reply that begins like JSON but is truncated/invalid renders as text; the
    # server logs a WARNING with the reason so this is diagnosable at INFO level.
    missing = tmp_path / "no_prompt.txt"
    malformed = '{"type": "Carousel", "pages": ['  # unclosed -> invalid JSON
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        result = _responder(
            _handler_returning_content(malformed), system_prompt_file=str(missing)
        ).reply("states?", [])
    assert result.card_body is None  # correctly fell back to text
    assert any(r.levelname == "WARNING" for r in caplog.records)
    assert "not usable" in caplog.text
    assert "invalid JSON" in caplog.text
    # The warning names the model that produced the malformed reply.
    assert OLLAMA_MODEL in caplog.text


def test_reply_does_not_warn_for_plain_text_reply(tmp_path, caplog):
    # Prose is an intentional text reply, not a botched card -> no card warning.
    # (Point at an existing empty prompt file so the missing-file warning, which
    # is unrelated to card parsing, does not confound the assertion.)
    empty = tmp_path / "empty.txt"
    empty.write_text("   \n", encoding="utf-8")
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _ok_capturing_handler({}), system_prompt_file=str(empty)
        ).reply("hi", [])
    assert "not usable" not in caplog.text
    assert "looked like an Adaptive Card" not in caplog.text


def test_json_format_defaults_to_schema():
    assert DEFAULT_JSON_FORMAT == "schema"


def test_reply_sends_no_format_field_in_none_mode(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        json_format="none",
    ).reply("hi", [])
    assert "format" not in captured["body"]


def test_reply_sends_format_json_string(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        json_format="json",
    ).reply("hi", [])
    assert captured["body"]["format"] == "json"


def test_reply_sends_format_schema_dict(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        json_format="schema",
    ).reply("hi", [])
    assert captured["body"]["format"]["oneOf"]  # the loaded card_schema.json


def test_schema_mode_downgrades_to_none_when_schema_file_missing(
    monkeypatch, tmp_path, caplog
):
    # A broken bundled schema file must not crash startup or a request — it
    # downgrades to json_format=none for the process, same as a bad
    # system-prompt path degrades gracefully today.
    import app.ollama_responder as mod

    monkeypatch.setattr(mod, "CARD_SCHEMA_PATH", tmp_path / "missing.json")
    missing_prompt = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.ERROR, logger="uvicorn.error"):
        _responder(
            _ok_capturing_handler(captured),
            system_prompt_file=str(missing_prompt),
            json_format="schema",
        ).reply("hi", [])
    assert "format" not in captured["body"]
    assert "unusable" in caplog.text


def test_reply_unwraps_json_string_for_plain_text_reply(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    plain = "Here's the answer:\n\n- Option one\n- Option two"
    content = json.dumps(plain)
    result = _responder(
        _handler_returning_content(content),
        system_prompt_file=str(missing),
        json_format="json",
    ).reply("what are my options?", [])
    assert result.text == plain
    assert result.card_body is None


def test_reply_detects_card_through_schema_format(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    content = json.dumps(
        {"type": "AdaptiveCard", "body": [{"type": "Input.Date", "id": "d"}]}
    )
    result = _responder(
        _handler_returning_content(content),
        system_prompt_file=str(missing),
        json_format="schema",
    ).reply("date?", [])
    assert result.card_body == [{"type": "Input.Date", "id": "d"}]
    assert result.text == content  # raw JSON preserved for history, as before


def test_reply_falls_back_to_heuristic_path_when_format_guarantee_violated(tmp_path):
    # Simulates an old Ollama that ignores `format` and returns non-JSON text
    # despite json_format != "none" -- must not crash, falls back to legacy parsing.
    missing = tmp_path / "no_prompt.txt"
    result = _responder(
        _handler_returning_content("plain non-JSON reply"),
        system_prompt_file=str(missing),
        json_format="json",
    ).reply("hi", [])
    assert result.text == "plain non-JSON reply"
    assert result.card_body is None


def test_reply_json_mode_renders_non_card_json_value_as_raw_text(tmp_path):
    # "json" mode's generic grammar allows shapes "schema" mode would exclude
    # (e.g. a bare number) -- must still render safely as text, not crash.
    missing = tmp_path / "no_prompt.txt"
    result = _responder(
        _handler_returning_content("42"),
        system_prompt_file=str(missing),
        json_format="json",
    ).reply("how many?", [])
    assert result.text == "42"
    assert result.card_body is None


def test_reply_schema_mode_does_not_warn_for_plain_text_json_string(tmp_path, caplog):
    # A JSON-string plain-text reply is intentional (Reply shape 2), not a
    # botched card -- must not trigger the "looked like a card" warning.
    missing = tmp_path / "no_prompt.txt"
    content = json.dumps("just chatting")
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _handler_returning_content(content),
            system_prompt_file=str(missing),
            json_format="schema",
        ).reply("hi", [])
    assert "not usable" not in caplog.text
