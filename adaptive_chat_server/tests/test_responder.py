from app.main import build_responder
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
