from app.card_detect import try_parse_card_body


def test_full_card_object_returns_body():
    raw = '{"type": "AdaptiveCard", "version": "1.5", "body": [{"type": "Input.Date", "id": "d"}]}'
    assert try_parse_card_body(raw) == [{"type": "Input.Date", "id": "d"}]


def test_fenced_card_returns_body():
    raw = '```json\n{"type": "AdaptiveCard", "body": [{"type": "TextBlock", "text": "hi"}]}\n```'
    assert try_parse_card_body(raw) == [{"type": "TextBlock", "text": "hi"}]


def test_bare_array_fragment_returns_itself():
    raw = '[{"type": "Input.ChoiceSet", "id": "c", "choices": []}]'
    assert try_parse_card_body(raw) == [{"type": "Input.ChoiceSet", "id": "c", "choices": []}]


def test_invalid_json_returns_none():
    assert try_parse_card_body("just a plain text reply") is None


def test_prose_wrapped_json_returns_none():
    assert try_parse_card_body('Here you go: {"type": "AdaptiveCard", "body": []}') is None


def test_non_card_object_returns_none():
    assert try_parse_card_body('{"type": "TextBlock", "text": "hi"}') is None


def test_json_scalar_returns_none():
    assert try_parse_card_body('"a json string"') is None
    assert try_parse_card_body("42") is None


def test_array_of_scalars_returns_none():
    assert try_parse_card_body("[1, 2, 3]") is None


def test_empty_array_returns_none():
    assert try_parse_card_body("[]") is None
