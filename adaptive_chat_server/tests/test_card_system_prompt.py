from pathlib import Path

import app as app_pkg

PROMPT = Path(app_pkg.__file__).with_name("card_system_prompt.txt")


def test_card_prompt_file_exists_and_is_non_empty():
    assert PROMPT.is_file()
    assert PROMPT.read_text(encoding="utf-8").strip()


def test_card_prompt_documents_input_palette():
    text = PROMPT.read_text(encoding="utf-8")
    for token in ("AdaptiveCard", "Input.Date", "Input.ChoiceSet"):
        assert token in text


def test_card_prompt_forbids_actions():
    # Display-only: the prompt must steer the model away from action buttons.
    assert "Action" in PROMPT.read_text(encoding="utf-8")  # mentioned in a "do not use" sense
