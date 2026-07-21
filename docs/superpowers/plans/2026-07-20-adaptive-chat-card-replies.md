# Adaptive Chat — text-or-card assistant replies Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the assistant reply with a rich Adaptive Card (date picker, drop list, radio/checkbox choice set) embedded in the assistant bubble, decided server-side, display-only.

**Architecture:** The responder returns a `Reply(text, card_body)` value type. `OllamaResponder` parses its own output with a strict `try_parse_card_body` helper. The send route renders `assistant_card_bubble(card_body)` when a card was detected, else the existing text bubble. The client is unchanged.

**Tech Stack:** Python 3.11 / FastAPI / pytest (server); Flutter / Dart (client, no code change).

**Spec:** [`docs/superpowers/specs/2026-07-20-adaptive-chat-card-replies-design.md`](../specs/2026-07-20-adaptive-chat-card-replies-design.md)

## Global Constraints

- **Display-only.** Returned inputs render but never post back. No handler wiring in the log.
- **Inputs only.** The card prompt covers inputs (`Input.Date`, `Input.ChoiceSet`, `Input.Text/Number/Time`); **no** `Action.*` / `actions` / `ActionSet`.
- **Server detects, client unchanged.** No edits to `adaptive_chat/lib/`. Envelope contract unchanged (`messages[]` are pre-styled cards).
- **Echo stays text-only** (`card_body=None`).
- **History unchanged:** `Interaction.reply_text` = `reply.text` (the raw model string).
- **These are sample apps** — no `packages/` CHANGELOG or coverage-floor gates apply.
- **Run server tests from `adaptive_chat_server/`** with `.venv/bin/python -m pytest`. Python commands are **not** fvm-prefixed; only `flutter`/`dart` are.

---

### Task 1: Card detection helper

**Files:**
- Create: `adaptive_chat_server/app/card_detect.py`
- Test: `adaptive_chat_server/tests/test_card_detect.py`

**Interfaces:**
- Consumes: nothing.
- Produces: `try_parse_card_body(raw: str) -> list | None` — returns the Adaptive Card body items when `raw` is *only* a card (full `{"type":"AdaptiveCard","body":[…]}` object or a bare non-empty JSON array of objects), else `None`.

- [ ] **Step 1: Write the failing test**

Create `adaptive_chat_server/tests/test_card_detect.py`:

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_card_detect.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.card_detect'`.

- [ ] **Step 3: Write minimal implementation**

Create `adaptive_chat_server/app/card_detect.py`:

```python
"""Decide whether a model reply is *only* an Adaptive Card, and extract its body.

The Ollama model answers either in plain markdown (rendered in a TextBlock bubble)
or, when the card system prompt is active, with an Adaptive Card fragment we embed
in the assistant bubble. This module decides which — strictly: the *entire* reply
(after stripping an optional code fence) must be the card, or it is treated as text.
"""
from __future__ import annotations

import json
import re

# Matches a whole reply wrapped in a ```json ... ``` (or bare ```) fence.
_FENCE = re.compile(r"^\s*```(?:json)?\s*(.*?)\s*```\s*$", re.DOTALL | re.IGNORECASE)


def _strip_fence(raw: str) -> str:
    match = _FENCE.match(raw)
    return match.group(1) if match else raw.strip()


def try_parse_card_body(raw: str) -> list | None:
    """Return Adaptive Card body items if ``raw`` is *only* a card, else None.

    Accepts either a full ``{"type": "AdaptiveCard", "body": [...]}`` object or a
    bare, non-empty JSON array of objects (a body fragment). Surrounding prose,
    invalid JSON, a non-card object, a scalar, or an array containing non-objects
    all yield None so the caller falls back to a text reply.
    """
    text = _strip_fence(raw)
    try:
        parsed = json.loads(text)
    except ValueError:
        return None
    if isinstance(parsed, list):
        if parsed and all(isinstance(item, dict) for item in parsed):
            return parsed
        return None
    if (
        isinstance(parsed, dict)
        and parsed.get("type") == "AdaptiveCard"
        and isinstance(parsed.get("body"), list)
    ):
        return parsed["body"]
    return None
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_card_detect.py -v`
Expected: PASS (9 passed).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/card_detect.py adaptive_chat_server/tests/test_card_detect.py
git commit -m "feat(adaptive_chat_server): strict try_parse_card_body helper"
```

---

### Task 2: `assistant_card_bubble` + `_bubble` refactor

**Files:**
- Modify: `adaptive_chat_server/app/cards.py`
- Test: `adaptive_chat_server/tests/test_cards.py`

**Interfaces:**
- Consumes: nothing.
- Produces: `assistant_card_bubble(body_items: list) -> dict` — a left-aligned, `emphasis`, `roundedCorners` bubble whose container `items` are exactly `body_items`. `user_bubble(text)` / `assistant_bubble(text)` keep identical output.

- [ ] **Step 1: Write the failing test**

Add to `adaptive_chat_server/tests/test_cards.py` (new import + new test):

```python
# add assistant_card_bubble to the existing import block:
from app.cards import (
    _BUBBLE_WEIGHT,
    _SPACER_WEIGHT,
    assistant_bubble,
    assistant_card_bubble,
    envelope,
    user_bubble,
)


def test_assistant_card_bubble_embeds_fragment_in_left_emphasis_container():
    fragment = [
        {"type": "TextBlock", "text": "Pick a date"},
        {"type": "Input.Date", "id": "when"},
    ]
    card = assistant_card_bubble(fragment)
    cols = _first_columnset(card)["columns"]
    # content (75%) first, spacer (25%) second -> left-aligned like a text reply
    assert cols[0]["width"] == _BUBBLE_WEIGHT
    assert cols[1]["width"] == _SPACER_WEIGHT
    container = cols[0]["items"][0]
    assert container["style"] == "emphasis"
    assert container["roundedCorners"] is True
    # the model's fragment is the container's items verbatim
    assert container["items"] == fragment
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_cards.py -v`
Expected: FAIL — `ImportError: cannot import name 'assistant_card_bubble'`.

- [ ] **Step 3: Write minimal implementation**

Replace the body of `adaptive_chat_server/app/cards.py` from the `_text_container` definition through `assistant_bubble` (lines ~19–50) with:

```python
def _bubble(items: list, *, style: str, align_right: bool) -> dict:
    container = {
        "type": "Container",
        "style": style,
        "roundedCorners": True,
        "items": items,
    }
    content = {"type": "Column", "width": _BUBBLE_WEIGHT, "items": [container]}
    spacer = {"type": "Column", "width": _SPACER_WEIGHT, "items": []}
    columns = [spacer, content] if align_right else [content, spacer]
    return {
        "type": "AdaptiveCard",
        "version": _VERSION,
        "body": [{"type": "ColumnSet", "columns": columns}],
    }


def _text_items(text: str) -> list:
    return [{"type": "TextBlock", "text": text, "wrap": True}]


def user_bubble(text: str) -> dict:
    """Right-aligned accent bubble for the user's message."""
    return _bubble(_text_items(text), style="accent", align_right=True)


def assistant_bubble(text: str) -> dict:
    """Left-aligned emphasis bubble for a plain-text assistant reply."""
    return _bubble(_text_items(text), style="emphasis", align_right=False)


def assistant_card_bubble(body_items: list) -> dict:
    """Left-aligned emphasis bubble whose container holds a model card fragment.

    Same chrome as a text reply (alignment, rounded corners, emphasis fill); the
    detected Adaptive Card body items become the container's contents, so a
    returned date picker / choice set reads as living inside a chat bubble.
    """
    return _bubble(body_items, style="emphasis", align_right=False)
```

Leave `_VERSION`, `_BUBBLE_WEIGHT`, `_SPACER_WEIGHT`, and `envelope(...)` unchanged.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_cards.py -v`
Expected: PASS (all existing card tests + the new one).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/cards.py adaptive_chat_server/tests/test_cards.py
git commit -m "feat(adaptive_chat_server): assistant_card_bubble embeds card fragment"
```

---

### Task 3: `Reply` value type + responder contract + route wiring

**Files:**
- Modify: `adaptive_chat_server/app/responder.py`
- Modify: `adaptive_chat_server/app/main.py`
- Test: `adaptive_chat_server/tests/test_responder.py`, `adaptive_chat_server/tests/test_api.py`

**Interfaces:**
- Consumes: `assistant_card_bubble` (Task 2).
- Produces: `Reply(text: str, card_body: list | None = None)` frozen dataclass; `Responder.reply(...) -> Reply`; `EchoResponder.reply(...) -> Reply(text=..., card_body=None)`. The send route renders `assistant_card_bubble(reply.card_body)` when non-None, else `assistant_bubble(reply.text)`, and stores `reply_text=reply.text`.

- [ ] **Step 1: Write the failing tests**

Edit `adaptive_chat_server/tests/test_responder.py` — change the two echo assertions to read `.text` and add a `Reply` shape test:

```python
from app.responder import EchoResponder, Reply


def test_echo_wraps_the_input():
    result = EchoResponder().reply("hello", [])
    assert result == Reply(text="Did you just say: hello", card_body=None)


def test_echo_ignores_history():
    history = [("user", "earlier"), ("assistant", "reply")]
    assert EchoResponder().reply("hello", history).text == "Did you just say: hello"


def test_echo_never_returns_a_card():
    assert EchoResponder().reply("hello", []).card_body is None
```

(Keep the existing `build_responder` / `_int_env` tests unchanged.)

Add a card-path route test to `adaptive_chat_server/tests/test_api.py`:

```python
from app.responder import Reply


class _CardStubResponder:
    def reply(self, text, history):
        return Reply(
            text='{"type":"AdaptiveCard"}',
            card_body=[{"type": "Input.Date", "id": "when"}],
        )


def test_send_renders_card_reply_in_assistant_bubble(monkeypatch):
    monkeypatch.setattr("app.main.responder", _CardStubResponder())
    cid = _start()
    resp = _send(cid, "i_card1", "book me")
    assert resp.status_code == 200
    body = resp.json()
    container = body["messages"][1]["body"][0]["columns"][0]["items"][0]
    assert container["style"] == "emphasis"
    assert container["items"] == [{"type": "Input.Date", "id": "when"}]
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_responder.py tests/test_api.py -v`
Expected: FAIL — `ImportError: cannot import name 'Reply'` (and the stub route test errors).

- [ ] **Step 3: Write minimal implementation**

Rewrite `adaptive_chat_server/app/responder.py`:

```python
"""Reply strategies and the value type they return."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class Reply:
    """A responder's answer: raw text (for history) plus an optional card body.

    ``text`` is always the model's raw output and is what threads into Ollama
    conversation history. ``card_body`` holds the parsed Adaptive Card body items
    when the reply is *only* a card (rendered inside the assistant bubble); ``None``
    means render ``text`` as a plain-text bubble.
    """

    text: str
    card_body: list | None = None


class Responder(Protocol):
    """Turns a user message (plus prior turns) into a :class:`Reply`."""

    def reply(self, text: str, history: list[tuple[str, str]]) -> Reply: ...


class EchoResponder:
    """v1 responder: echoes the user's text back. Ignores history; never a card."""

    def reply(self, text: str, history: list[tuple[str, str]]) -> Reply:
        return Reply(text=f"Did you just say: {text}")
```

In `adaptive_chat_server/app/main.py`, update the import line:

```python
from app.cards import assistant_bubble, assistant_card_bubble, envelope, user_bubble
```

and replace the `reply_text = responder.reply(...)` / `messages = [...]` / `store.add_interaction(...)` block in `send_interaction` (currently lines ~128–141) with:

```python
    reply = responder.reply(message, history)
    assistant_card = (
        assistant_card_bubble(reply.card_body)
        if reply.card_body is not None
        else assistant_bubble(reply.text)
    )
    messages = [
        Message(role="user", card=user_bubble(message)),
        Message(role="assistant", card=assistant_card),
    ]
    store.add_interaction(
        cid,
        Interaction(
            interaction_id=x_interaction_id,
            text=message,
            messages=messages,
            reply_text=reply.text,
        ),
    )
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_responder.py tests/test_api.py -v`
Expected: PASS (echo route tests still green — echo output is unchanged; new card route test green).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/responder.py adaptive_chat_server/app/main.py adaptive_chat_server/tests/test_responder.py adaptive_chat_server/tests/test_api.py
git commit -m "feat(adaptive_chat_server): Reply value type; route renders card replies"
```

---

### Task 4: `OllamaResponder` returns `Reply` with card parsing

**Files:**
- Modify: `adaptive_chat_server/app/ollama_responder.py`
- Test: `adaptive_chat_server/tests/test_ollama_responder.py`

**Interfaces:**
- Consumes: `Reply` (Task 3), `try_parse_card_body` (Task 1).
- Produces: `OllamaResponder.reply(...) -> Reply`. Success → `Reply(text=content, card_body=try_parse_card_body(content))`. Every error fallback → `Reply(text=<diagnostic>, card_body=None)`.

- [ ] **Step 1: Write / update the failing tests**

In `adaptive_chat_server/tests/test_ollama_responder.py`:

1. Add import at the top: `from app.responder import Reply`.
2. Update these existing success/error assertions to read `.text`:
   - `test_reply_posts_history_and_new_turn_to_chat_endpoint`: `assert result.text == "hi from ollama"`
   - `test_reply_skips_system_message_when_prompt_file_missing`: `assert result.text == "hi from ollama"`
   - `test_reply_reports_connection_failure_with_exception_detail`: `assert result.text.startswith(...)`, `assert "ConnectError" in result.text`, `assert "connection refused" in result.text`
   - `test_reply_reports_http_error_status_and_body`: `assert result.text.startswith(...)`, `assert "not found" in result.text`
   - `test_reply_reports_unexpected_response_body`: `assert result.text == "(Ollama returned an unexpected response: KeyError)"`
   - `test_fill_logging_skipped_when_prompt_eval_count_absent`: `assert result.text == "hi from ollama"`
3. Add two new tests:

```python
def test_reply_detects_card_output_as_card_body(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = json.loads(request.content)
        card = '{"type": "AdaptiveCard", "body": [{"type": "Input.Date", "id": "d"}]}'
        return httpx.Response(200, json={"message": {"role": "assistant", "content": card}})

    result = _responder(handler, system_prompt_file=str(missing)).reply("date?", [])

    assert result.card_body == [{"type": "Input.Date", "id": "d"}]
    # raw text is preserved for history
    assert '"AdaptiveCard"' in result.text


def test_reply_plain_text_has_no_card_body(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    result = _responder(
        _ok_capturing_handler({}), system_prompt_file=str(missing)
    ).reply("hi", [])

    assert result.text == "hi from ollama"
    assert result.card_body is None
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_ollama_responder.py -v`
Expected: FAIL — `AttributeError: 'str' object has no attribute 'text'` (and the new card test fails).

- [ ] **Step 3: Write minimal implementation**

In `adaptive_chat_server/app/ollama_responder.py`:

1. Add imports near the top (after `import httpx`):

```python
from app.card_detect import try_parse_card_body
from app.responder import Reply
```

2. Change the `reply` signature return type to `-> Reply`.
3. Wrap each of the three error `return` strings in `Reply(text=..., card_body=None)`:

```python
            return Reply(
                text=(
                    f"(Ollama unreachable at {self._ollama_url} — "
                    f"{type(exc).__name__}: {exc})"
                )
            )
```
```python
            return Reply(
                text=(
                    f"(Ollama error HTTP {response.status_code} at "
                    f"{self._ollama_url}: {body})"
                )
            )
```
```python
            return Reply(
                text=f"(Ollama returned an unexpected response: {type(exc).__name__})"
            )
```

4. Replace the final `return content` with:

```python
        self._log_context_fill(data)
        return Reply(text=content, card_body=try_parse_card_body(content))
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_ollama_responder.py -v`
Expected: PASS (all updated + 2 new).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/tests/test_ollama_responder.py
git commit -m "feat(adaptive_chat_server): OllamaResponder returns Reply, detects card output"
```

---

### Task 5: Bundled `card_system_prompt.txt`

**Files:**
- Create: `adaptive_chat_server/app/card_system_prompt.txt`
- Test: `adaptive_chat_server/tests/test_card_system_prompt.py`

**Interfaces:**
- Consumes: nothing (selected at runtime via the existing `--system-prompt-file` flag).
- Produces: a bundled prompt file next to `default_system_prompt.txt`, resolvable relative to the package.

- [ ] **Step 1: Write the failing test**

Create `adaptive_chat_server/tests/test_card_system_prompt.py`:

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_card_system_prompt.py -v`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Write the prompt file**

Create `adaptive_chat_server/app/card_system_prompt.txt`:

```
You are a chat assistant whose replies are rendered as Adaptive Cards inside a
narrow chat bubble.

When a structured input helps the user (choosing a date, picking from options,
entering a value), reply with ONLY an Adaptive Card fragment and no surrounding
prose. The fragment may be either a full object,
{"type":"AdaptiveCard","version":"1.5","body":[ ... ]}, or a bare JSON array of
body elements, [ ... ]. Do not wrap it in explanation; the entire message must be
the JSON.

Use these body elements only:
- TextBlock — a short label or prompt (set "wrap": true).
- Input.Date — a date picker. Give it an "id".
- Input.ChoiceSet — a list of options. "style":"compact" is a drop list,
  "style":"expanded" is radio buttons, and "isMultiSelect":true makes checkboxes.
  Provide "choices" as [{"title": "...", "value": "..."}].
- Input.Text, Input.Number, Input.Time — free-form entry. Give each an "id".

Do NOT include any Action, an "actions" array, or an ActionSet: this UI is
display-only and has no submit button yet, so action buttons would do nothing.

When no structured input is useful, reply normally in concise GitHub-flavored
Markdown (do not return JSON). Keep everything compact — the bubble is narrow.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_card_system_prompt.py -v`
Expected: PASS (3 passed).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/card_system_prompt.txt adaptive_chat_server/tests/test_card_system_prompt.py
git commit -m "feat(adaptive_chat_server): bundled card_system_prompt.txt (inputs only)"
```

---

### Task 6: Client widget test — a card reply renders its inputs

**Files:**
- Test: `adaptive_chat/test/card_reply_render_test.dart` (create)

**Interfaces:**
- Consumes: `assistant_card_bubble`-shaped JSON (Task 2), the client's existing `AdaptiveCardsCanvas.map` render path. No client `lib/` change.

- [ ] **Step 1: Inspect an existing client test for setup**

Run: `ls adaptive_chat/test && sed -n '1,40p' adaptive_chat/test/*_test.dart | head -60`
Purpose: copy the existing pump/hostConfig setup pattern (imports, `chatHostConfigs()` usage, `pumpWidget` wrapping) used by the current widget tests, so the new test matches repo conventions.

- [ ] **Step 2: Write the failing test**

Create `adaptive_chat/test/card_reply_render_test.dart`. Build the same card an assistant card bubble produces (a left `ColumnSet` → `Column` → `emphasis` `Container` whose items are the fragment) and pump it through the same `AdaptiveCardsCanvas.map` + `chatHostConfigs()` the page uses. Assert an `Input.Date` field renders:

```dart
import 'package:adaptive_chat/src/chat_host_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _assistantCardBubble(List<Map<String, dynamic>> body) => {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'ColumnSet',
          'columns': [
            {
              'type': 'Column',
              'width': 3,
              'items': [
                {
                  'type': 'Container',
                  'style': 'emphasis',
                  'roundedCorners': true,
                  'items': body,
                }
              ],
            },
            {'type': 'Column', 'width': 1, 'items': <dynamic>[]},
          ],
        }
      ],
    };

void main() {
  testWidgets('assistant card bubble renders a date input', (tester) async {
    final card = _assistantCardBubble([
      {'type': 'TextBlock', 'text': 'Pick a date', 'wrap': true},
      {'type': 'Input.Date', 'id': 'when'},
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveCardsCanvas.map(
            content: card,
            hostConfigs: chatHostConfigs(),
            showDebugJson: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pick a date'), findsOneWidget);
    // The date input renders some interactive field (date text or a picker button).
    expect(find.byType(TextField), findsWidgets);
  });
}
```

Note: if Step 1 shows the existing tests import `chatHostConfigs` from a different path or wrap differently, match that. If `find.byType(TextField)` proves brittle for `Input.Date` in this library version, assert on the label (`find.text('Pick a date')`) plus `find.byType(InkWell)`/the date field widget the library actually emits (confirm from the render).

- [ ] **Step 3: Run test to verify it fails (or passes) meaningfully**

Run: `cd adaptive_chat && fvm flutter test test/card_reply_render_test.dart`
Expected: If the finder is wrong it FAILs with a clear "found 0 widgets" — adjust the finder to what `Input.Date` actually renders, then it PASSES. The label assertion (`find.text('Pick a date')`) must pass regardless.

- [ ] **Step 4: Run the full client suite**

Run: `cd adaptive_chat && fvm flutter test`
Expected: PASS (existing tests + the new one).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat/test/card_reply_render_test.dart
git commit -m "test(adaptive_chat): assistant card bubble renders its inputs"
```

---

### Task 7: Docs — READMEs

**Files:**
- Modify: `adaptive_chat_server/README.md`
- Modify: `adaptive_chat/README.md`

**Interfaces:**
- Consumes: everything above. No code.

- [ ] **Step 1: Update the server README**

In `adaptive_chat_server/README.md`:
- In the `responder.py` / `ollama_responder.py` rows of the Components table, note that `reply(...)` now returns a `Reply(text, card_body)`; `OllamaResponder` runs `try_parse_card_body` on its output.
- Add a `cards.py` note for `assistant_card_bubble`, and a new `card_detect.py` row: "Strict text-vs-card detection — the whole reply must be an Adaptive Card object or a bare body array, else it's text."
- Add a short **"Card replies (display-only)"** subsection: the model may answer with an Adaptive Card fragment that is embedded in the assistant bubble; select the card prompt with
  `--system-prompt-file app/card_system_prompt.txt`; inputs only, no post-back yet.

- [ ] **Step 2: Update the client README**

In `adaptive_chat/README.md`, under "Not covered here (by design)" (or a new note), state that assistant bubbles may now contain rich **inputs** (date pickers, choice sets) authored by the server, but this is **display-only** — the returned inputs do not post back yet (same gap as in-card form submits).

- [ ] **Step 3: Verify no stale references**

Run: `git grep -n "reply_text = responder" adaptive_chat_server` and `git grep -n "reply(self" adaptive_chat_server/app`
Expected: the route uses `reply = responder.reply(...)`; all `reply(...)` signatures return `Reply`. No `-> str` left on a responder.

- [ ] **Step 4: Commit**

```bash
git add adaptive_chat_server/README.md adaptive_chat/README.md
git commit -m "docs(adaptive_chat): document display-only card replies"
```

---

## Final Task: Full verification

- [ ] **Step 1: Server suite**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest -v`
Expected: PASS (all files, including the new `test_card_detect.py`, `test_card_system_prompt.py`, and updated responder/api/ollama tests). Paste the pass/fail summary line.

- [ ] **Step 2: Client suite**

Run: `cd adaptive_chat && fvm flutter test`
Expected: PASS. Paste the summary line.

- [ ] **Step 3: Analyzer (client)**

Run: `cd adaptive_chat && fvm flutter analyze`
Expected: No new issues.

- [ ] **Step 4: Report**

Per `superpowers:verification-before-completion`, paste the actual command output (exit codes + pass counts) before claiming completion. Do not report complete until both suites pass.
