import logging

from app.main import _int_env, build_responder
from app.ollama_responder import DEFAULT_OLLAMA_MODEL, OllamaResponder
from app.responder import EchoResponder


def test_echo_wraps_the_input():
    assert EchoResponder().reply("hello", []) == "Did you just say: hello"


def test_echo_ignores_history():
    history = [("user", "earlier"), ("assistant", "reply")]
    assert EchoResponder().reply("hello", history) == "Did you just say: hello"


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
