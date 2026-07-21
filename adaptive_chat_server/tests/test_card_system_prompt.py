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


def test_card_prompt_documents_display_elements():
    # Display-only elements the core library registers by default (registry.dart):
    # FactSet, Badge, Carousel, Table — safe to render in a chat bubble without
    # handlers. Table cells hold arbitrary items (multi-line / mixed-type cells).
    text = PROMPT.read_text(encoding="utf-8")
    for token in ("FactSet", "Badge", "Carousel", "Table", "TableRow", "TableCell"):
        assert token in text


def test_card_prompt_documents_markdown_fallback():
    # The TextBlock renders GitHub-flavored Markdown both inside a card and as the
    # plain (no-structured-input) reply, so the prompt must document the Markdown
    # palette the default_system_prompt.txt describes.
    text = PROMPT.read_text(encoding="utf-8")
    for token in ("Markdown", "Headings", "Bold", "Links", "code"):
        assert token in text


def test_card_prompt_requires_complete_json():
    # Local models copy "..." straight out of schema examples, producing invalid
    # JSON that renders as text. The prompt must (a) tell the model to write
    # complete JSON without abbreviating, and (b) not itself contain a bare "..."
    # ellipsis token that the model could echo.
    text = PROMPT.read_text(encoding="utf-8")
    lowered = text.lower()
    assert "complete" in lowered
    assert "abbreviat" in lowered
    # No bare ellipsis token (three dots) anywhere in the prompt examples.
    assert "..." not in text


def test_card_prompt_forbids_actions():
    # Display-only: the prompt must steer the model away from action buttons.
    assert "Action" in PROMPT.read_text(encoding="utf-8")  # mentioned in a "do not use" sense


def test_card_prompt_has_no_equals_delimiter_headers():
    # The model mimics "=== ... ===" section headers and leaks "=== " before the
    # JSON, breaking card detection. The prompt must not use that decoration.
    text = PROMPT.read_text(encoding="utf-8")
    assert "===" not in text


def test_card_prompt_forbids_output_around_the_json():
    # Reinforce that the whole card message is raw JSON with nothing wrapped
    # around it, so a leaked prefix/suffix cannot happen.
    text = PROMPT.read_text(encoding="utf-8").lower()
    assert "nothing before" in text
