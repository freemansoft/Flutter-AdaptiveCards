import json

import httpx

from app.ollama_responder import OllamaResponder


def _client(handler):
    return httpx.Client(transport=httpx.MockTransport(handler))


def test_reply_posts_history_and_new_turn_to_chat_endpoint():
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["url"] = str(request.url)
        captured["body"] = json.loads(request.content)
        return httpx.Response(
            200,
            json={"message": {"role": "assistant", "content": "hi from ollama"}},
        )

    responder = OllamaResponder(
        "http://localhost:11434", model="llama3.2", client=_client(handler)
    )
    history = [("user", "earlier question"), ("assistant", "earlier answer")]
    result = responder.reply("new question", history)

    assert result == "hi from ollama"
    assert captured["url"] == "http://localhost:11434/api/chat"
    assert captured["body"] == {
        "model": "llama3.2",
        "messages": [
            {"role": "user", "content": "earlier question"},
            {"role": "assistant", "content": "earlier answer"},
            {"role": "user", "content": "new question"},
        ],
        "stream": False,
    }


def test_reply_falls_back_when_ollama_is_unreachable():
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("connection refused", request=request)

    responder = OllamaResponder(
        "http://localhost:11434", model="llama3.2", client=_client(handler)
    )

    result = responder.reply("hello", [])

    assert result == "(Ollama unreachable at http://localhost:11434)"
