import json

import httpx

from app.ollama_responder import OllamaResponder

# Single source of truth for these tests — change the model/host/port here, not
# in each test. (These drive the mocked transport; no live Ollama is contacted.)
OLLAMA_HOST = "127.0.0.1"
OLLAMA_PORT = 11434
OLLAMA_URL = f"http://{OLLAMA_HOST}:{OLLAMA_PORT}"
OLLAMA_MODEL = "gpt-oss:20b"


def _client(handler):
    return httpx.Client(transport=httpx.MockTransport(handler))


def _responder(handler, system_prompt_file=None, history_turns=10):
    return OllamaResponder(
        OLLAMA_URL,
        model=OLLAMA_MODEL,
        client=_client(handler),
        system_prompt_file=system_prompt_file,
        history_turns=history_turns,
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


def test_reply_posts_history_and_new_turn_to_chat_endpoint(tmp_path):
    # Point at a nonexistent prompt file so no system message is injected —
    # this keeps the exact-body assertion decoupled from the default prompt.
    missing = tmp_path / "no_such_prompt.txt"
    captured = {}

    history = [("user", "earlier question"), ("assistant", "earlier answer")]
    result = _responder(
        _ok_capturing_handler(captured), system_prompt_file=str(missing)
    ).reply("new question", history)

    assert result == "hi from ollama"
    assert captured["url"] == f"{OLLAMA_URL}/api/chat"
    assert captured["body"] == {
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "user", "content": "earlier question"},
            {"role": "assistant", "content": "earlier answer"},
            {"role": "user", "content": "new question"},
        ],
        "stream": False,
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
    assert result == "hi from ollama"
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
    assert result.startswith(f"(Ollama unreachable at {OLLAMA_URL}")
    assert "ConnectError" in result
    assert "connection refused" in result


def test_reply_reports_http_error_status_and_body():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(404, json={"error": f'model "{OLLAMA_MODEL}" not found'})

    result = _responder(handler).reply("hello", [])

    # A reachable-but-erroring Ollama (e.g. model not pulled) is NOT "unreachable".
    assert result.startswith(f"(Ollama error HTTP 404 at {OLLAMA_URL}")
    assert "not found" in result


def test_reply_reports_unexpected_response_body():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"unexpected": "shape"})

    result = _responder(handler).reply("hello", [])

    assert result == "(Ollama returned an unexpected response: KeyError)"


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
