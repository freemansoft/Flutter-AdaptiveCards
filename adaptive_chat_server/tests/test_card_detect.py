from app.card_detect import card_parse_failure_reason, try_parse_card_body


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


def test_reported_sample_choiceset_with_leaked_delimiter_returns_body():
    # The verbatim reply that first surfaced this bug: a "=== " prefix leaked
    # ahead of a full Input.ChoiceSet element. Must parse to a one-item body.
    raw = (
        '=== \n{"type":"Input.ChoiceSet","id":"states","style":"compact",'
        '"choices":[{"title":"California","value":"1"},'
        '{"title":"Texas","value":"2"},{"title":"New York","value":"3"},'
        '{"title":"Florida","value":"4"},'
        '{"title":"Pennsylvania","value":"5"}]}'
    )
    assert try_parse_card_body(raw) == [
        {
            "type": "Input.ChoiceSet",
            "id": "states",
            "style": "compact",
            "choices": [
                {"title": "California", "value": "1"},
                {"title": "Texas", "value": "2"},
                {"title": "New York", "value": "3"},
                {"title": "Florida", "value": "4"},
                {"title": "Pennsylvania", "value": "5"},
            ],
        }
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


def test_trailing_only_decoration_returns_body():
    # Isolate the regex's trailing branch (no leading decoration): JSON followed
    # immediately by a delimiter run must still parse to a card.
    assert try_parse_card_body('{"type": "TextBlock", "text": "hi"}\n===') == [
        {"type": "TextBlock", "text": "hi"}
    ]


def test_prose_before_nonempty_card_still_returns_none():
    # Locks the NARROW contract: real prose words are not decoration, so a card
    # embedded after prose stays text. (The existing prose test uses an empty
    # body and would pass regardless; this one uses a renderable body.)
    raw = 'Here is a card: {"type": "AdaptiveCard", "body": [{"type": "TextBlock", "text": "hi"}]}'
    assert try_parse_card_body(raw) is None


# --- card_parse_failure_reason (diagnostic; never affects rendering) ---


def test_failure_reason_none_for_valid_card():
    assert card_parse_failure_reason('{"type": "TextBlock", "text": "hi"}') is None


def test_failure_reason_none_for_plain_prose():
    # Prose does not begin with { or [, so it is a text reply, not a botched card.
    assert card_parse_failure_reason("Here is your answer in words.") is None


def test_failure_reason_reports_invalid_json_when_it_looked_like_a_card():
    # Begins like JSON but is truncated -> a botched card, not prose.
    reason = card_parse_failure_reason('{"type": "Carousel", "pages": [')
    assert reason is not None
    assert "invalid json" in reason.lower()


def test_failure_reason_reports_wrong_shape_for_valid_but_unrenderable_json():
    # Valid JSON, but an empty-body AdaptiveCard is not renderable.
    reason = card_parse_failure_reason('{"type": "AdaptiveCard", "body": []}')
    assert reason is not None
    assert "not a renderable card" in reason.lower()


def test_failure_reason_reports_invalid_json_for_reported_truncated_carousel():
    # The verbatim failure the user reported: a huge Carousel that the model
    # left structurally malformed (an "items" array closed then a stray ", {...}",
    # and the outer object never closed). Must be flagged as invalid JSON.
    raw = (
        '{"type":"Carousel","pages":[{"type":"CarouselPage","items":[{"type":'
        '"Table","rows":[{"type":"TableRow","cells":[{"type":"TableCell",'
        '"items":[{"type":"TextBlock","text":"x"}]},{"type":"Badge","text":"y"}]'
        # ^ outer object intentionally left unclosed, as in the reported log
    )
    reason = card_parse_failure_reason(raw)
    assert reason is not None
    assert "invalid json" in reason.lower()
