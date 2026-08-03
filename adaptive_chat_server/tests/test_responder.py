import logging

from app.main import _int_env, build_responder
from app.ollama_responder import DEFAULT_OLLAMA_MODEL, OllamaResponder
from app.responder import EchoResponder, Reply
from app.stats import InteractionStats


def test_echo_wraps_the_input():
    result = EchoResponder().reply("hello", [])
    assert result == Reply(text="Did you just say: hello", card_body=None)


def test_echo_ignores_history():
    history = [("user", "earlier"), ("assistant", "reply")]
    assert EchoResponder().reply("hello", history).text == "Did you just say: hello"


def test_echo_never_returns_a_card():
    assert EchoResponder().reply("hello", []).card_body is None


def test_build_responder_defaults_to_echo_without_url():
    assert isinstance(build_responder(None, DEFAULT_OLLAMA_MODEL), EchoResponder)


def test_build_responder_selects_ollama_when_url_given():
    responder = build_responder("http://x", DEFAULT_OLLAMA_MODEL)
    assert isinstance(responder, OllamaResponder)


def test_int_env_returns_default_when_unset(monkeypatch):
    monkeypatch.delenv("SOME_INT", raising=False)
    assert _int_env("SOME_INT", 4096) == 4096


def test_int_env_parses_value(monkeypatch):
    monkeypatch.setenv("SOME_INT", "2048")
    assert _int_env("SOME_INT", 4096) == 2048


def test_int_env_falls_back_and_warns_on_bad_value(monkeypatch, caplog):
    monkeypatch.setenv("SOME_INT", "not-a-number")
    with caplog.at_level(logging.WARNING, logger="uvicorn.error"):
        assert _int_env("SOME_INT", 4096) == 4096
    assert "SOME_INT" in caplog.text


def test_build_responder_forwards_json_format():
    responder = build_responder("http://x", DEFAULT_OLLAMA_MODEL, json_format="none")
    assert isinstance(responder, OllamaResponder)


def test_reply_stats_default_to_none():
    assert Reply(text="hi").stats is None


def test_reply_carries_stats_when_given():
    stats = InteractionStats(
        prompt_tokens=1,
        reply_tokens=2,
        total_ms=3,
        load_ms=0,
        prompt_eval_ms=1,
        eval_ms=2,
    )
    assert Reply(text="hi", stats=stats).stats is stats


def test_echo_responder_describes_itself():
    assert EchoResponder().describe() == {"kind": "echo"}


def test_echo_responder_reply_has_no_stats():
    assert EchoResponder().reply("hi", []).stats is None
