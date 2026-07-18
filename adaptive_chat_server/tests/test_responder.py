from app.responder import EchoResponder


def test_echo_wraps_the_input():
    assert EchoResponder().reply("hello") == "Did you just say: hello"
