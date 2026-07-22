# Card JSON Leaked-Prefix Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the chat server render a card even when the local model leaks a leading/trailing delimiter (e.g. `=== \n{json}`) around the JSON, and stop the model leaking it in the first place.

**Architecture:** Two independent server-side changes. (1) Harden `app/card_detect.py:try_parse_card_body` to strip surrounding *decoration* (whitespace + delimiter runs like `===`/`---`/`###`) before parsing — narrowly, so real prose still falls back to text. (2) Remove the `=== N. … ===` section headers from `app/card_system_prompt.txt` (the thing the model mimics) and add an explicit "raw JSON only" instruction. The Flutter client is untouched.

**Tech Stack:** Python 3.11, pytest. Server lives in `adaptive_chat_server/`; tests run via the repo virtualenv at `adaptive_chat_server/.venv`.

## Global Constraints

- **Server only.** No change to `adaptive_chat_client` (Flutter) or any package under `packages/`.
- **Narrow tolerance.** Strip only *decoration* (whitespace, code fences, pure-delimiter runs). Prose words before/after the JSON must still yield `None` (text). The existing `test_prose_wrapped_json_returns_none` must stay green.
- **Preserve the existing shape contract** in `try_parse_card_body`: full `{"type":"AdaptiveCard","body":[…]}` → its body; non-empty array of objects → as-is; single typed element → `[element]`; empty body / scalars / mixed / empty array / `type`-less dict → `None`.
- **Run commands from `adaptive_chat_server/`** using `.venv/bin/python -m pytest`.
- **Git gate (repo policy):** every `git commit` requires explicit user confirmation at the moment of action — show the diff and wait. Commit steps below are gated on that approval.
- **No bare `...` ellipsis token** may be introduced into `card_system_prompt.txt` (an existing prompt test asserts `"..." not in text`).

---

### Task 1: Harden the parser to strip surrounding decoration

**Files:**
- Modify: `adaptive_chat_server/app/card_detect.py`
- Test: `adaptive_chat_server/tests/test_card_detect.py`

**Interfaces:**
- Consumes: nothing new.
- Produces: `try_parse_card_body(raw: str) -> list | None` — unchanged signature and return contract; now additionally tolerant of leading/trailing decoration. Adds a private helper `_strip_decoration(text: str) -> str`.

- [ ] **Step 1: Write the failing tests**

Append to `adaptive_chat_server/tests/test_card_detect.py`:

```python
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
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run:
```bash
cd adaptive_chat_server
.venv/bin/python -m pytest tests/test_card_detect.py -q -k "delimiter or decoration or prose_before"
```
Expected: the four decoration tests FAIL (currently return `None` for a leaked prefix). `test_prose_before_nonempty_card_still_returns_none` PASSES already (current code returns `None`).

- [ ] **Step 3: Implement decoration stripping**

In `adaptive_chat_server/app/card_detect.py`, add the `_DECORATION` pattern and `_strip_decoration` helper next to `_FENCE` / `_strip_fence`:

```python
# Matches a whole reply wrapped in a ```json ... ``` (or bare ```) fence.
_FENCE = re.compile(r"^\s*```(?:json)?\s*(.*?)\s*```\s*$", re.DOTALL | re.IGNORECASE)

# Leading/trailing DECORATION a local model wraps around the JSON: whitespace and
# runs of section/Markdown delimiters (===, ---, ###, ***, ___, ~~~). Stripped
# from both ends only; the pattern halts at the first content char (e.g. { or [),
# so JSON is never clipped. Real prose words carry none of these chars at the very
# edge, so a prose-wrapped reply is left intact and still fails JSON parsing.
_DECORATION = re.compile(r"^[\s=\-#*_~]+|[\s=\-#*_~]+$")


def _strip_fence(raw: str) -> str:
    match = _FENCE.match(raw)
    return match.group(1) if match else raw.strip()


def _strip_decoration(text: str) -> str:
    return _DECORATION.sub("", text)
```

Then update the parse entry point (currently `text = _strip_fence(raw)`):

```python
    text = _strip_decoration(_strip_fence(raw))
```

Also update the module docstring's fragment-shapes note and the `try_parse_card_body` docstring to record the new tolerance. In the module docstring (top of file), add after the three-shapes list:

```
Leading/trailing decoration a model wraps around the JSON — surrounding
whitespace, a code fence, or delimiter runs like ``=== `` / ``---`` / ``###`` —
is stripped before parsing. Surrounding *prose* is not: a reply with words
before or after the JSON is still treated as text.
```

And in the `try_parse_card_body` docstring, change the sentence "Surrounding prose, invalid JSON, …" to make explicit that decoration is tolerated but prose is not:

```
Leading/trailing decoration (whitespace, a code fence, or delimiter runs such
as ``=== ``) is stripped first. Surrounding prose, invalid JSON, a dict with no
``type``, a scalar, an empty array, or an array with non-objects all yield None
so the caller falls back to a text reply.
```

- [ ] **Step 4: Run the full parser suite to verify pass**

Run:
```bash
cd adaptive_chat_server
.venv/bin/python -m pytest tests/test_card_detect.py -q
```
Expected: PASS — all prior 12 tests plus the 5 new ones (17 passed). Confirm `test_prose_wrapped_json_returns_none` and `test_prose_before_nonempty_card_still_returns_none` are green (narrow contract intact).

- [ ] **Step 5: Commit** (gated on user confirmation — show the diff first)

```bash
git add adaptive_chat_server/app/card_detect.py adaptive_chat_server/tests/test_card_detect.py
git commit -m "fix(chat-server): tolerate leaked delimiter around card JSON"
```

---

### Task 2: Remove `=== ` headers from the card prompt and forbid surrounding output

**Files:**
- Modify: `adaptive_chat_server/app/card_system_prompt.txt`
- Test: `adaptive_chat_server/tests/test_card_system_prompt.py`

**Interfaces:**
- Consumes: nothing from Task 1 (independent).
- Produces: a prompt file with no `=== ` section decoration and an explicit "raw JSON only, nothing before `{`/`[`" instruction.

- [ ] **Step 1: Write the failing prompt test**

Append to `adaptive_chat_server/tests/test_card_system_prompt.py`:

```python
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
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run:
```bash
cd adaptive_chat_server
.venv/bin/python -m pytest tests/test_card_system_prompt.py -q -k "no_equals or forbids_output_around"
```
Expected: both FAIL — the prompt currently contains `===` and no "nothing before" clause.

- [ ] **Step 3: Edit the prompt**

In `adaptive_chat_server/app/card_system_prompt.txt`:

Replace the header on line 7:
```
=== 1. Adaptive Card fragment (structured) ===
```
with:
```
## Reply shape 1: Adaptive Card fragment (structured)
```

Replace the header on line 62:
```
=== 2. Plain Markdown (no structured input) ===
```
with:
```
## Reply shape 2: Plain Markdown (no structured input)
```

In the `WRITE COMPLETE, VALID JSON:` block (starts line 22), add a new first bullet immediately under that heading, before the existing "Never abbreviate" bullet:
```
- Output nothing before the first { or [ and nothing after the closing bracket —
  no headers, labels, delimiters, or prose. The entire message must be raw JSON.
```

(Do not introduce a literal three-dot ellipsis anywhere — an existing test asserts `"..." not in text`. The word "bracket" and the phrase above contain none.)

- [ ] **Step 4: Run the full prompt suite to verify pass**

Run:
```bash
cd adaptive_chat_server
.venv/bin/python -m pytest tests/test_card_system_prompt.py -q
```
Expected: PASS — the two new tests plus all existing ones (content tokens `AdaptiveCard`, `Input.Date`, `FactSet`, `Markdown`, `complete`, `abbreviat`, `Action`, and the `"..." not in text` guard remain satisfied).

- [ ] **Step 5: Commit** (gated on user confirmation — show the diff first)

```bash
git add adaptive_chat_server/app/card_system_prompt.txt adaptive_chat_server/tests/test_card_system_prompt.py
git commit -m "fix(chat-server): drop === headers from card prompt, forbid wrapping the JSON"
```

---

### Final Task: Full verification

- [ ] **Step 1: Run the affected server suites**

Run:
```bash
cd adaptive_chat_server
.venv/bin/python -m pytest tests/test_card_detect.py tests/test_card_system_prompt.py tests/test_responder.py -q
```
Expected: PASS (no failures). This covers the parser tolerance, the prompt guarantees, and the responder path that calls `try_parse_card_body`.

- [ ] **Step 2: Run the whole server test suite**

Run:
```bash
cd adaptive_chat_server
.venv/bin/python -m pytest -q
```
Expected: PASS — confirms no regression in `test_api.py`, `test_cards.py`, `test_store.py`, or `test_ollama_responder.py`.

- [ ] **Step 3: Invoke `superpowers:verification-before-completion`**

Paste the exit code and pass/fail counts from Step 2 before claiming the work complete.

## Notes for the implementer

- The failure being fixed: a model reply like `=== \n{"type":"Input.ChoiceSet",…}` currently `json.loads`-throws in `try_parse_card_body`, so the server wraps it in a `TextBlock` and the client shows raw JSON. Task 1 makes the parser strip the `=== ` decoration; Task 2 stops the model emitting it.
- Why the regex is safe: `^[\s=\-#*_~]+` stops at the first character not in the class, and a JSON card value starts with `{` or `[` (neither in the class), so the value's own content is never clipped. A leading `-` on a bare scalar like `-5` would strip to `5`, which still validates as a scalar → `None`; no meaningful change.
- Tasks 1 and 2 are independent and may be implemented/reviewed in either order.
