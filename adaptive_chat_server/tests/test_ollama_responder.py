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


def _responder(handler):
    return OllamaResponder(OLLAMA_URL, model=OLLAMA_MODEL, client=_client(handler))


def test_reply_posts_history_and_new_turn_to_chat_endpoint():
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["url"] = str(request.url)
        captured["body"] = json.loads(request.content)
        return httpx.Response(
            200,
            json={"message": {"role": "assistant", "content": "hi from ollama"}},
        )

    history = [("user", "earlier question"), ("assistant", "earlier answer")]
    result = _responder(handler).reply("new question", history)

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
