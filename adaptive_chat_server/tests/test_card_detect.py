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


def test_single_element_object_becomes_one_item_body():
    # Local models often emit just the one element, not a full card or an array.
    assert try_parse_card_body('{"type": "TextBlock", "text": "hi"}') == [
        {"type": "TextBlock", "text": "hi"}
    ]


def test_fenced_single_element_returns_body():
    # The exact shape a local model returned: a bare ``` fence wrapping a lone
    # Input.ChoiceSet element (no full card, no array).
    raw = (
        "```\n"
        '{\n  "type": "Input.ChoiceSet",\n  "style": "compact",\n'
        '  "choices": [{"title": "GMT+0:00", "value": "+0000"}]\n}\n'
        "```"
    )
    assert try_parse_card_body(raw) == [
        {
            "type": "Input.ChoiceSet",
            "style": "compact",
            "choices": [{"title": "GMT+0:00", "value": "+0000"}],
        }
    ]


def test_dict_without_type_returns_none():
    # A JSON object that isn't an element (no "type") is not a card fragment.
    assert try_parse_card_body('{"foo": "bar"}') is None


def test_empty_body_card_returns_none():
    # A full card with an empty/absent body has nothing to render -> text.
    assert try_parse_card_body('{"type": "AdaptiveCard", "body": []}') is None
    assert try_parse_card_body('{"type": "AdaptiveCard"}') is None


def test_json_scalar_returns_none():
    assert try_parse_card_body('"a json string"') is None
    assert try_parse_card_body("42") is None


def test_array_of_scalars_returns_none():
    assert try_parse_card_body("[1, 2, 3]") is None


def test_empty_array_returns_none():
    assert try_parse_card_body("[]") is None


def test_leading_delimiter_before_full_card_returns_body():
    # The observed failure: the model prefixes "=== " (mimicking the prompt's
    # section headers) before an otherwise-valid card.
    raw = '=== \n{"type": "AdaptiveCard", "body": [{"type": "Input.Date", "id": "d"}]}'
    assert try_parse_card_body(raw) == [{"type": "Input.Date", "id": "d"}]


def test_leading_delimiter_before_single_element_returns_body():
    raw = '=== \n{"type": "Input.ChoiceSet", "id": "s", "choices": []}'
    assert try_parse_card_body(raw) == [
        {"type": "Input.ChoiceSet", "id": "s", "choices": []}
    ]


def test_leading_and_trailing_decoration_around_array_returns_array():
    raw = '===\n[{"type": "TextBlock", "text": "hi"}]\n==='
    assert try_parse_card_body(raw) == [{"type": "TextBlock", "text": "hi"}]


def test_hash_and_dash_delimiters_are_stripped():
    assert try_parse_card_body('###\n{"type": "TextBlock", "text": "hi"}') == [
        {"type": "TextBlock", "text": "hi"}
    ]
    assert try_parse_card_body('---\n{"type": "TextBlock", "text": "hi"}') == [
        {"type": "TextBlock", "text": "hi"}
    ]


def test_prose_before_nonempty_card_still_returns_none():
    # Locks the NARROW contract: real prose words are not decoration, so a card
    # embedded after prose stays text. (The existing prose test uses an empty
    # body and would pass regardless; this one uses a renderable body.)
    raw = 'Here is a card: {"type": "AdaptiveCard", "body": [{"type": "TextBlock", "text": "hi"}]}'
    assert try_parse_card_body(raw) is None
