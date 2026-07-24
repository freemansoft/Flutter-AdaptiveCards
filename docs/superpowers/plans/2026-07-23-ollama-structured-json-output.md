# Ollama Structured-Output Constraint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `adaptive_chat_server`'s Ollama-backed card replies reliably valid JSON by constraining decoding via Ollama's `format` field, without breaking its existing plain-Markdown reply path.

**Architecture:** A new `--json-format {none,json,schema}` CLI flag (default `schema`) threads through `app/__main__.py` → `OLLAMA_JSON_FORMAT` env var → `app/main.py`'s `build_responder()` → `OllamaResponder`. `schema` mode sends a small hand-authored discriminated-union JSON Schema (`app/card_schema.json`) as Ollama's `format` value, covering both card replies and plain-text replies (as a JSON string) so the model's existing two-shape contract keeps working. `OllamaResponder.reply()`'s response handling is reworked to `json.loads` the guaranteed-valid response and branch on shape, falling back to today's heuristic `card_detect.try_parse_card_body` path when `json_format="none"` or the guarantee is unexpectedly violated.

**Tech Stack:** Python (FastAPI backend), `pytest`, `httpx.MockTransport` for HTTP mocking. No new dependencies.

## Global Constraints

- Design source of truth: `docs/superpowers/specs/2026-07-23-ollama-structured-json-output-design.md`. Re-read it if a task's instructions here seem to conflict with it.
- Default `json_format` is `"schema"`.
- The schema (`app/card_schema.json`) validates only the **outer shapes** `card_detect.try_parse_card_body` already accepts (full card object / element array / single element / plain string) — no per-element property schemas (no `TextBlock.text`, `Input.ChoiceSet.choices`, etc. constraints). Per-element correctness stays the prompt's job.
- `app/card_detect.py` and `tests/test_card_detect.py` are **not modified** by this plan — reused as-is.
- No new runtime dependency (no `jsonschema` package) — schema sanity-checking is a plain `json.loads` + key-presence check; Ollama performs the actual grammar-constrained decoding.
- No package `CHANGELOG.md` entry — `adaptive_chat_server` lives outside `packages/`.
- All commands below run from `adaptive_chat_server/` using the repo's existing venv: `.venv/bin/python -m pytest ...`.
- This repo requires **explicit user confirmation before every `git commit`** (see root `AGENTS.md`) — show the diff and wait for a go-ahead before each task's commit step, same as was done for the design spec.

---

### Task 1: Card schema file + loader

**Files:**

- Create: `adaptive_chat_server/app/card_schema.json`
- Modify: `adaptive_chat_server/app/ollama_responder.py` (imports + new constant + new function, near the top of the file, after the existing `DEFAULT_SYSTEM_PROMPT_PATH` constant at line 41)
- Test: `adaptive_chat_server/tests/test_ollama_responder.py`

**Interfaces:**

- Produces: `app.ollama_responder.CARD_SCHEMA_PATH` (a `pathlib.Path`, resolved relative to `ollama_responder.py`, pointing at the bundled `card_schema.json`); `app.ollama_responder._load_card_schema(path: Path) -> dict | None` (returns the parsed schema dict, or `None` — logged as an error, never raises — if the file is missing, not valid JSON, or lacks the expected `oneOf`/`$defs` top-level keys).

- [ ] **Step 1: Write the failing tests**

Add to `adaptive_chat_server/tests/test_ollama_responder.py` (near the top, after the existing imports — add `import json` is already present via other tests? No: this file does not yet import `json` at module level for direct use outside handlers, but the handlers already do `json.loads(request.content)` via the top-level `import json` on line 1, so it's already available):

```python
from app.ollama_responder import CARD_SCHEMA_PATH, _load_card_schema


def test_load_card_schema_returns_dict_for_valid_file(tmp_path):
    schema_file = tmp_path / "card_schema.json"
    schema_file.write_text(
        json.dumps({"$defs": {"Element": {}}, "oneOf": []}), encoding="utf-8"
    )
    assert _load_card_schema(schema_file) == {"$defs": {"Element": {}}, "oneOf": []}


def test_load_card_schema_returns_none_for_missing_file(tmp_path, caplog):
    missing = tmp_path / "no_such_schema.json"
    with caplog.at_level(logging.ERROR, logger="uvicorn.error"):
        assert _load_card_schema(missing) is None
    assert "unusable" in caplog.text


def test_load_card_schema_returns_none_for_invalid_json(tmp_path, caplog):
    bad = tmp_path / "bad.json"
    bad.write_text("{not valid json", encoding="utf-8")
    with caplog.at_level(logging.ERROR, logger="uvicorn.error"):
        assert _load_card_schema(bad) is None
    assert "unusable" in caplog.text


def test_load_card_schema_returns_none_when_missing_expected_keys(tmp_path, caplog):
    incomplete = tmp_path / "incomplete.json"
    incomplete.write_text(json.dumps({"type": "object"}), encoding="utf-8")
    with caplog.at_level(logging.ERROR, logger="uvicorn.error"):
        assert _load_card_schema(incomplete) is None
    assert "oneOf" in caplog.text


def test_bundled_card_schema_loads_successfully():
    # The real shipped file must itself pass the loader's own sanity check.
    schema = _load_card_schema(CARD_SCHEMA_PATH)
    assert schema is not None
    assert schema["oneOf"]
```

Place these new tests anywhere in the file after the existing imports (e.g. right before `def test_reply_posts_history_and_new_turn_to_chat_endpoint`).

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_ollama_responder.py -k card_schema -v`
Expected: FAIL — `ImportError: cannot import name 'CARD_SCHEMA_PATH'` (or `_load_card_schema`), since neither exists yet.

- [ ] **Step 3: Create `app/card_schema.json`**

```json
{
  "$defs": {
    "Element": {
      "type": "object",
      "required": ["type"],
      "properties": {
        "type": { "type": "string", "minLength": 1 }
      }
    },
    "CardObject": {
      "type": "object",
      "required": ["type", "body"],
      "properties": {
        "type": { "const": "AdaptiveCard" },
        "version": { "type": "string" },
        "body": {
          "type": "array",
          "minItems": 1,
          "items": { "$ref": "#/$defs/Element" }
        }
      }
    },
    "ElementArray": {
      "type": "array",
      "minItems": 1,
      "items": { "$ref": "#/$defs/Element" }
    }
  },
  "oneOf": [
    { "$ref": "#/$defs/CardObject" },
    { "$ref": "#/$defs/ElementArray" },
    { "$ref": "#/$defs/Element" },
    { "type": "string" }
  ]
}
```

- [ ] **Step 4: Add `import json`, `CARD_SCHEMA_PATH`, and `_load_card_schema` to `app/ollama_responder.py`**

Add `import json` to the imports at the top of the file (it currently imports `logging` and `Path` but not `json`):

```python
import json
import logging
from pathlib import Path
```

Add the constant right after `DEFAULT_SYSTEM_PROMPT_PATH` (currently line 41):

```python
# Bundled schema for "schema" mode (see DEFAULT_JSON_FORMAT below), resolved
# relative to this file, not the process cwd.
CARD_SCHEMA_PATH = Path(__file__).with_name("card_schema.json")
```

Add the loader function above the `OllamaResponder` class:

```python
def _load_card_schema(path: Path) -> dict | None:
    """Load and sanity-check the card-reply JSON Schema; None on any problem.

    Only a syntax/shape guard (valid JSON, has the expected top-level keys) —
    Ollama performs the actual grammar-constrained decoding against this
    schema, so this is not a full JSON-Schema-spec validation. Never raises:
    a missing, unreadable, or malformed file is logged and returns None so the
    caller can fall back to a less-strict json_format instead of crashing.
    """
    try:
        schema = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        logger.error(
            "Card schema unusable (%s: %s) at %s — falling back to "
            "json_format=none for this process.",
            type(exc).__name__,
            exc,
            path,
        )
        return None
    if not isinstance(schema, dict) or "oneOf" not in schema or "$defs" not in schema:
        logger.error(
            "Card schema at %s missing expected 'oneOf'/'$defs' keys — "
            "falling back to json_format=none for this process.",
            path,
        )
        return None
    return schema
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_ollama_responder.py -k card_schema -v`
Expected: PASS (5 passed)

- [ ] **Step 6: Run the full existing suite to confirm no regressions**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest`
Expected: all previously-passing tests still pass (this task only adds new code paths, nothing existing calls `_load_card_schema` yet).

- [ ] **Step 7: Show the diff and commit (after user confirmation)**

```bash
git status --short
git diff -- adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/app/card_schema.json adaptive_chat_server/tests/test_ollama_responder.py
```

Show the diff to the user, wait for explicit confirmation, then:

```bash
git add adaptive_chat_server/app/card_schema.json adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/tests/test_ollama_responder.py
git commit -m "feat(adaptive_chat_server): add card_schema.json and its loader"
```

---

### Task 2: `json_format` constructor param + request payload wiring

**Files:**

- Modify: `adaptive_chat_server/app/ollama_responder.py` (new constant, constructor changes, payload construction inside `reply()`)
- Test: `adaptive_chat_server/tests/test_ollama_responder.py` (update the shared `_responder()` helper; add new tests)

**Interfaces:**

- Consumes: `CARD_SCHEMA_PATH`, `_load_card_schema` from Task 1.
- Produces: `app.ollama_responder.DEFAULT_JSON_FORMAT` (`str`, value `"schema"`); `OllamaResponder.__init__` gains `json_format: str = DEFAULT_JSON_FORMAT`; the request payload built inside `reply()` gains a conditional `"format"` key.

- [ ] **Step 1: Update the shared test helper first (keeps ~25 existing tests decoupled from the new default)**

In `adaptive_chat_server/tests/test_ollama_responder.py`, change:

```python
def _responder(handler, system_prompt_file=None, history_turns=10, num_ctx=4096):
    return OllamaResponder(
        OLLAMA_URL,
        model=OLLAMA_MODEL,
        client=_client(handler),
        system_prompt_file=system_prompt_file,
        history_turns=history_turns,
        num_ctx=num_ctx,
    )
```

to:

```python
def _responder(
    handler,
    system_prompt_file=None,
    history_turns=10,
    num_ctx=4096,
    json_format="none",
):
    return OllamaResponder(
        OLLAMA_URL,
        model=OLLAMA_MODEL,
        client=_client(handler),
        system_prompt_file=system_prompt_file,
        history_turns=history_turns,
        num_ctx=num_ctx,
        json_format=json_format,
    )
```

`json_format="none"` as the helper's default keeps every existing test (which asserts exact request-body shape without a `"format"` key, or doesn't care about it) decoupled from this feature — the same pattern already used for `system_prompt_file` pointing at a missing path to avoid coupling to the bundled default prompt.

- [ ] **Step 2: Run the full suite to verify it still fails only where expected**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest`
Expected: FAIL — `TypeError: __init__() got an unexpected keyword argument 'json_format'` for every test that goes through `_responder()`, since the constructor doesn't accept it yet. This confirms the helper change is exercised.

- [ ] **Step 3: Write the new failing tests**

Add to the same file (as its own new import line — the existing
`from app.ollama_responder import DEFAULT_NUM_CTX, OllamaResponder` on line 6
is left untouched):

```python
from app.ollama_responder import DEFAULT_JSON_FORMAT


def test_json_format_defaults_to_schema():
    assert DEFAULT_JSON_FORMAT == "schema"


def test_reply_sends_no_format_field_in_none_mode(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        json_format="none",
    ).reply("hi", [])
    assert "format" not in captured["body"]


def test_reply_sends_format_json_string(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        json_format="json",
    ).reply("hi", [])
    assert captured["body"]["format"] == "json"


def test_reply_sends_format_schema_dict(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        json_format="schema",
    ).reply("hi", [])
    assert captured["body"]["format"]["oneOf"]  # the loaded card_schema.json


def test_schema_mode_downgrades_to_none_when_schema_file_missing(
    monkeypatch, tmp_path, caplog
):
    # A broken bundled schema file must not crash startup or a request — it
    # downgrades to json_format=none for the process, same as a bad
    # system-prompt path degrades gracefully today.
    import app.ollama_responder as mod

    monkeypatch.setattr(mod, "CARD_SCHEMA_PATH", tmp_path / "missing.json")
    missing_prompt = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.ERROR, logger="uvicorn.error"):
        _responder(
            _ok_capturing_handler(captured),
            system_prompt_file=str(missing_prompt),
            json_format="schema",
        ).reply("hi", [])
    assert "format" not in captured["body"]
    assert "unusable" in caplog.text
```

- [ ] **Step 4: Run tests to verify the new ones fail**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_ollama_responder.py -k "json_format or format_json or format_schema" -v`
Expected: FAIL — `_responder()` (and `OllamaResponder.__init__`) doesn't accept `json_format` yet.

- [ ] **Step 5: Implement the constructor and payload changes**

In `app/ollama_responder.py`, add the constant near `DEFAULT_NUM_CTX`:

```python
# Values: "none" (no format constraint — today's prompt-only behavior), "json"
# (Ollama's generic valid-JSON grammar), "schema" (grammar-constrained against
# CARD_SCHEMA_PATH). See docs/superpowers/specs/2026-07-23-ollama-structured-
# json-output-design.md for the rationale and the "none|json|schema" tradeoffs.
DEFAULT_JSON_FORMAT = "schema"
```

Update `__init__`'s signature and body:

```python
    def __init__(
        self,
        ollama_url: str,
        model: str = DEFAULT_OLLAMA_MODEL,
        client: httpx.Client | None = None,
        system_prompt_file: str | None = None,
        history_turns: int = DEFAULT_HISTORY_TURNS,
        num_ctx: int = DEFAULT_NUM_CTX,
        json_format: str = DEFAULT_JSON_FORMAT,
    ) -> None:
        """Configure the responder.

        The system-prompt file *path* is stored (not its contents) so edits to the
        file take effect on the next request without restarting the server.
        """
        self._ollama_url = ollama_url
        self._model = model
        self._client = client or httpx.Client(timeout=60)
        self._history_turns = history_turns
        self._num_ctx = num_ctx
        # Store the path, not the content: the file is re-read on every request
        # so edits take effect without restarting the server.
        self._system_prompt_path = (
            Path(system_prompt_file)
            if system_prompt_file
            else DEFAULT_SYSTEM_PROMPT_PATH
        )
        self._json_format = json_format
        self._card_schema: dict | None = None
        if self._json_format == "schema":
            self._card_schema = _load_card_schema(CARD_SCHEMA_PATH)
            if self._card_schema is None:
                self._json_format = "none"
```

Update the payload construction inside `reply()` (currently the `payload = {...}` block):

```python
        endpoint = f"{self._ollama_url}/api/chat"
        payload = {
            "model": self._model,
            "messages": messages,
            "stream": False,
            "options": {"num_ctx": self._num_ctx},
        }
        if self._json_format == "json":
            payload["format"] = "json"
        elif self._json_format == "schema":
            payload["format"] = self._card_schema
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_ollama_responder.py -v`
Expected: all pass, including the 5 new tests from this task and all pre-existing tests (now decoupled via the helper's `json_format="none"` default).

- [ ] **Step 7: Run the full suite**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest`
Expected: all pass.

- [ ] **Step 8: Show the diff and commit (after user confirmation)**

```bash
git diff -- adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/tests/test_ollama_responder.py
```

Show the diff, wait for explicit confirmation, then:

```bash
git add adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/tests/test_ollama_responder.py
git commit -m "feat(adaptive_chat_server): add json_format constructor param and format payload field"
```

---

### Task 3: Response-handling rework (the dual text/card branch)

**Files:**

- Modify: `adaptive_chat_server/app/ollama_responder.py` (the content-handling block inside `reply()`, currently starting at `self._log_context_fill(data)` and ending at `return Reply(text=content, card_body=card_body)`)
- Test: `adaptive_chat_server/tests/test_ollama_responder.py`

**Interfaces:**

- Consumes: `try_parse_card_body`, `card_parse_failure_reason` from `app.card_detect` (already imported, unchanged signatures).
- Produces: `OllamaResponder.reply()`'s externally-visible `Reply` behavior for `json_format in {"json", "schema"}` — a JSON-string reply unwraps to plain text; a card-shaped reply populates `card_body`; anything else falls back to today's heuristic path. No new public interface — this task only changes behavior inside `reply()`.

- [ ] **Step 1: Write the failing tests**

Add to `adaptive_chat_server/tests/test_ollama_responder.py` (uses the existing `_handler_returning_content` helper defined later in the file — if not yet visible above these new tests, that's fine, Python resolves module-level names at call time, not definition order within the same module):

```python
def test_reply_unwraps_json_string_for_plain_text_reply(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    plain = "Here's the answer:\n\n- Option one\n- Option two"
    content = json.dumps(plain)
    result = _responder(
        _handler_returning_content(content),
        system_prompt_file=str(missing),
        json_format="json",
    ).reply("what are my options?", [])
    assert result.text == plain
    assert result.card_body is None


def test_reply_detects_card_through_schema_format(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    content = json.dumps(
        {"type": "AdaptiveCard", "body": [{"type": "Input.Date", "id": "d"}]}
    )
    result = _responder(
        _handler_returning_content(content),
        system_prompt_file=str(missing),
        json_format="schema",
    ).reply("date?", [])
    assert result.card_body == [{"type": "Input.Date", "id": "d"}]
    assert result.text == content  # raw JSON preserved for history, as before


def test_reply_falls_back_to_heuristic_path_when_format_guarantee_violated(tmp_path):
    # Simulates an old Ollama that ignores `format` and returns non-JSON text
    # despite json_format != "none" -- must not crash, falls back to legacy parsing.
    missing = tmp_path / "no_prompt.txt"
    result = _responder(
        _handler_returning_content("plain non-JSON reply"),
        system_prompt_file=str(missing),
        json_format="json",
    ).reply("hi", [])
    assert result.text == "plain non-JSON reply"
    assert result.card_body is None


def test_reply_json_mode_renders_non_card_json_value_as_raw_text(tmp_path):
    # "json" mode's generic grammar allows shapes "schema" mode would exclude
    # (e.g. a bare number) -- must still render safely as text, not crash.
    missing = tmp_path / "no_prompt.txt"
    result = _responder(
        _handler_returning_content("42"),
        system_prompt_file=str(missing),
        json_format="json",
    ).reply("how many?", [])
    assert result.text == "42"
    assert result.card_body is None


def test_reply_schema_mode_does_not_warn_for_plain_text_json_string(tmp_path, caplog):
    # A JSON-string plain-text reply is intentional (Reply shape 2), not a
    # botched card -- must not trigger the "looked like a card" warning.
    missing = tmp_path / "no_prompt.txt"
    content = json.dumps("just chatting")
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _handler_returning_content(content),
            system_prompt_file=str(missing),
            json_format="schema",
        ).reply("hi", [])
    assert "not usable" not in caplog.text
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_ollama_responder.py -k "unwraps_json_string or detects_card_through_schema or falls_back_to_heuristic or json_mode_renders_non_card or does_not_warn_for_plain_text_json" -v`
Expected: FAIL — with today's unconditional `try_parse_card_body(content)` call, `test_reply_unwraps_json_string_for_plain_text_reply` fails because `result.text` is still the JSON-quoted form (`'"Here\'s the answer..."'`), not the unwrapped plain string.

- [ ] **Step 3: Implement the response-handling rework**

Replace, inside `reply()`, from `self._log_context_fill(data)` through `return Reply(text=content, card_body=card_body)` with:

```python
        self._log_context_fill(data)

        reply_text = content
        card_body: list | None = None
        used_format_path = False
        if self._json_format != "none":
            try:
                parsed = json.loads(content)
            except ValueError:
                pass  # unexpected: format guarantee failed; fall through below
            else:
                used_format_path = True
                if isinstance(parsed, str):
                    reply_text = parsed
                else:
                    card_body = try_parse_card_body(json.dumps(parsed))
        if not used_format_path:
            card_body = try_parse_card_body(content)

        # When a reply *looked like* a card (began with JSON) but could not be
        # used, surface WHY at WARNING so it is diagnosable at the default INFO
        # level — the common cause is the model emitting malformed/truncated JSON
        # for a large, deeply nested card. Plain-prose replies return None here
        # and are not warned about (they are intentional text answers). Always
        # evaluated against the raw wire `content`, not `reply_text`, so the
        # diagnosis reflects exactly what Ollama sent.
        if card_body is None:
            reason = card_parse_failure_reason(content)
            if reason is not None:
                logger.warning(
                    "Model reply looked like an Adaptive Card but was not usable "
                    "(model=%s, %d chars) — rendered as text instead. Reason: %s",
                    self._model,
                    len(content),
                    reason,
                )
        # Content-level diagnostics: logged at DEBUG so they are off in normal
        # operation but available for testing without a code change. Enable DEBUG
        # logging (e.g. `uvicorn --log-level debug`, or set the "uvicorn.error"
        # logger to DEBUG) to see the verbatim model output and whether it was
        # accepted as a card — the quickest way to diagnose a reply that renders
        # as text instead of a card. logger.debug skips formatting when disabled,
        # so this costs nothing at the default INFO level.
        logger.debug(
            "Ollama content (model=%s, %d chars, detected_card=%s):\n%r",
            self._model,
            len(content),
            card_body is not None,
            content,
        )
        return Reply(text=reply_text, card_body=card_body)
```

Note the only semantic change from today: `Reply(text=reply_text, ...)` instead of `Reply(text=content, ...)` — `reply_text` equals `content` in every branch except the plain-JSON-string branch, where it's the unwrapped Markdown.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_ollama_responder.py -v`
Expected: all pass, including the 5 new tests and every pre-existing test in the file (all of which use `json_format="none"` via the Task 2 helper default, taking the unchanged legacy path).

- [ ] **Step 5: Run the full suite**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest`
Expected: all pass.

- [ ] **Step 6: Show the diff and commit (after user confirmation)**

```bash
git diff -- adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/tests/test_ollama_responder.py
```

Show the diff, wait for explicit confirmation, then:

```bash
git add adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/tests/test_ollama_responder.py
git commit -m "feat(adaptive_chat_server): branch reply() on format-constrained JSON shape"
```

---

### Task 4: CLI flag + `build_responder` wiring

**Files:**

- Modify: `adaptive_chat_server/app/main.py` (`build_responder()` signature + body, the module-level `responder = build_responder(...)` call, imports)
- Modify: `adaptive_chat_server/app/__main__.py` (new argparse flag, env var bridge, import)
- Test: `adaptive_chat_server/tests/test_responder.py`

**Interfaces:**

- Consumes: `DEFAULT_JSON_FORMAT` from `app.ollama_responder` (Task 2).
- Produces: `build_responder(ollama_url, model, system_prompt_file=None, num_ctx=DEFAULT_NUM_CTX, history_turns=DEFAULT_HISTORY_TURNS, json_format=DEFAULT_JSON_FORMAT) -> Responder` (new trailing param); CLI flag `--json-format {none,json,schema}` (default `DEFAULT_JSON_FORMAT`); env var `OLLAMA_JSON_FORMAT`.

- [ ] **Step 1: Write the failing test**

Add to `adaptive_chat_server/tests/test_responder.py`:

```python
def test_build_responder_forwards_json_format():
    responder = build_responder("http://x", DEFAULT_OLLAMA_MODEL, json_format="none")
    assert isinstance(responder, OllamaResponder)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_responder.py -k forwards_json_format -v`
Expected: FAIL — `TypeError: build_responder() got an unexpected keyword argument 'json_format'`.

- [ ] **Step 3: Implement `app/main.py` changes**

Update the import block:

```python
from app.ollama_responder import (
    DEFAULT_HISTORY_TURNS,
    DEFAULT_JSON_FORMAT,
    DEFAULT_NUM_CTX,
    DEFAULT_OLLAMA_MODEL,
    OllamaResponder,
)
```

Update `build_responder`:

```python
def build_responder(
    ollama_url: str | None,
    model: str,
    system_prompt_file: str | None = None,
    num_ctx: int = DEFAULT_NUM_CTX,
    history_turns: int = DEFAULT_HISTORY_TURNS,
    json_format: str = DEFAULT_JSON_FORMAT,
) -> Responder:
    """Selects the responder for this process: Ollama if a URL is set, else echo."""
    if ollama_url:
        logger.info(
            "Responder: OllamaResponder (url=%s, model=%s, system_prompt=%s, "
            "num_ctx=%d, history_turns=%d, json_format=%s)",
            ollama_url,
            model,
            system_prompt_file or "default",
            num_ctx,
            history_turns,
            json_format,
        )
        return OllamaResponder(
            ollama_url,
            model,
            system_prompt_file=system_prompt_file,
            num_ctx=num_ctx,
            history_turns=history_turns,
            json_format=json_format,
        )
    logger.info("Responder: EchoResponder (no --ollama-url / OLLAMA_URL set)")
    return EchoResponder()
```

Update the module-level construction call:

```python
responder = build_responder(
    os.environ.get("OLLAMA_URL"),
    os.environ.get("OLLAMA_MODEL", DEFAULT_OLLAMA_MODEL),
    os.environ.get("OLLAMA_SYSTEM_PROMPT_FILE"),
    num_ctx=_int_env("OLLAMA_NUM_CTX", DEFAULT_NUM_CTX),
    history_turns=_int_env("OLLAMA_HISTORY_TURNS", DEFAULT_HISTORY_TURNS),
    json_format=os.environ.get("OLLAMA_JSON_FORMAT", DEFAULT_JSON_FORMAT),
)
```

- [ ] **Step 4: Implement `app/__main__.py` changes**

Update the import:

```python
from app.ollama_responder import (
    DEFAULT_HISTORY_TURNS,
    DEFAULT_JSON_FORMAT,
    DEFAULT_NUM_CTX,
    DEFAULT_OLLAMA_MODEL,
)
```

Add the new argument (after the existing `--history-turns` argument, before `--host`):

```python
    parser.add_argument(
        "--json-format",
        default=DEFAULT_JSON_FORMAT,
        choices=["none", "json", "schema"],
        help=f"Constrain Ollama's output via its `format` field (default: "
        f"{DEFAULT_JSON_FORMAT}). 'none' is today's prompt-only behavior; "
        "'json' asks for any syntactically valid JSON; 'schema' additionally "
        "constrains the outer shape against the bundled card_schema.json so "
        "both card and plain-text replies come back as guaranteed-valid JSON.",
    )
```

Set the env var alongside the others:

```python
    os.environ["OLLAMA_NUM_CTX"] = str(args.num_ctx)
    os.environ["OLLAMA_HISTORY_TURNS"] = str(args.history_turns)
    os.environ["OLLAMA_JSON_FORMAT"] = args.json_format
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_responder.py -v`
Expected: all pass.

- [ ] **Step 6: Run the full suite**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest`
Expected: all pass. (`__main__.py` has no dedicated test file today — none is added here, consistent with existing coverage.)

- [ ] **Step 7: Show the diff and commit (after user confirmation)**

```bash
git diff -- adaptive_chat_server/app/main.py adaptive_chat_server/app/__main__.py adaptive_chat_server/tests/test_responder.py
```

Show the diff, wait for explicit confirmation, then:

```bash
git add adaptive_chat_server/app/main.py adaptive_chat_server/app/__main__.py adaptive_chat_server/tests/test_responder.py
git commit -m "feat(adaptive_chat_server): add --json-format CLI flag"
```

---

### Task 5: Prompt update for the dual text/card JSON contract

**Files:**

- Modify: `adaptive_chat_server/app/card_system_prompt.txt`
- Test: `adaptive_chat_server/tests/test_card_system_prompt.py`

**Interfaces:** None (prompt content only — no code interface).

- [ ] **Step 1: Write the failing test**

Add to `adaptive_chat_server/tests/test_card_system_prompt.py`:

```python
def test_card_prompt_documents_structured_output_mode():
    # When --json-format enforces JSON (json or schema mode), a plain-text
    # reply (Reply shape 2) must still come back as valid JSON -- the prompt
    # must tell the model this explicitly, and must not reintroduce a bare
    # ellipsis or "===" delimiter (guarded by the other tests in this file).
    text = PROMPT.read_text(encoding="utf-8")
    assert "--json-format" in text
    assert "JSON string" in text
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_card_system_prompt.py -k structured_output_mode -v`
Expected: FAIL — neither token is in the prompt yet.

- [ ] **Step 3: Add the paragraph to `app/card_system_prompt.txt`**

Append this new section at the end of the file (after the existing "## Reply shape 2: Plain Markdown (no structured input)" content, i.e. after the current final line "small chat bubble."):

```

### Structured-output mode

When the server runs with `--json-format json` or `--json-format schema`,
every reply -- including a plain Markdown answer -- must be valid JSON. If
your reply is plain Markdown text (Reply shape 2), write it as a JSON string,
for example "Here's what I found:\n\n- Option one\n- Option two". Your
Markdown content goes inside the string unchanged; only the surrounding
quoting is new.
```

Do not use `===` delimiters or a literal `...` ellipsis anywhere in the new text (both are forbidden elsewhere in this file by existing tests).

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_card_system_prompt.py -v`
Expected: all pass, including every pre-existing test in this file (the addition is purely additive and avoids the forbidden tokens).

- [ ] **Step 5: Run the full suite**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest`
Expected: all pass.

- [ ] **Step 6: Show the diff and commit (after user confirmation)**

```bash
git diff -- adaptive_chat_server/app/card_system_prompt.txt adaptive_chat_server/tests/test_card_system_prompt.py
```

Show the diff, wait for explicit confirmation, then:

```bash
git add adaptive_chat_server/app/card_system_prompt.txt adaptive_chat_server/tests/test_card_system_prompt.py
git commit -m "docs(adaptive_chat_server): document the structured-output JSON contract in the card prompt"
```

---

### Task 6: README documentation

**Files:**

- Modify: `adaptive_chat_server/README.md`

**Interfaces:** None (documentation only).

- [ ] **Step 1: Add a subsection after "Card replies (display-only)"**

In `adaptive_chat_server/README.md`, after the existing paragraph that ends "...is render-only for now." (the last line of the "### Card replies (display-only)" section, immediately before "### Request flow"), insert:

````markdown
### Structured output (`--json-format`)

By default (`--json-format schema`), every Ollama reply is constrained via
Ollama's `format` field against `app/card_schema.json` — a small schema
covering exactly the shapes `card_detect.try_parse_card_body` accepts (a full
card object, a bare element array, a single element, or a plain string for
Markdown replies) so the model cannot emit invalid or leaked-prefix JSON.

```bash
.venv/bin/python -m app --ollama-url http://127.0.0.1:11434 \
  --json-format schema   # default; try --json-format json or --json-format none
```
````

- `schema` (default) — constrains both syntax and the outer reply shape.
- `json` — constrains syntax only (any valid JSON value); shape is still
  checked by `card_detect.py` after parsing.
- `none` — today's prompt-only behavior, no `format` field sent.

See
[docs/superpowers/specs/2026-07-23-ollama-structured-json-output-design.md](../docs/superpowers/specs/2026-07-23-ollama-structured-json-output-design.md)
for the design rationale.

````

- [ ] **Step 2: Add a CLI reference bullet**

In the same file, in the "**Context window & history.**" area, after the existing `--history-turns` bullet (currently ending "...Bounds only the outbound prompt; the server retains full history.") and before "Omit `--ollama-url`...", add:

```markdown
- `--json-format` (default `schema`) — `none`/`json`/`schema`; see **Structured
  output** above.
````

- [ ] **Step 3: Review the diff**

```bash
git diff -- adaptive_chat_server/README.md
```

Read it back to confirm the markdown renders sensibly (fenced code blocks closed correctly, list formatting intact).

- [ ] **Step 4: Show the diff and commit (after user confirmation)**

Show the diff, wait for explicit confirmation, then:

```bash
git add adaptive_chat_server/README.md
git commit -m "docs(adaptive_chat_server): document --json-format in the README"
```

---

### Task 7: Final verification

**Files:** None (verification only).

- [ ] **Step 1: Run the full `adaptive_chat_server` test suite**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest -v`
Expected: all tests pass (0 failed), including every test added across Tasks 1-6.

- [ ] **Step 2: Confirm no stray files or uncommitted changes**

Run: `git status --short`
Expected: clean (nothing untracked or modified outside what was committed in Tasks 1-6).

- [ ] **Step 3: Manual smoke check against a running Ollama (optional but recommended)**

If a local Ollama is available:

```bash
cd adaptive_chat_server
.venv/bin/python -m app --ollama-url http://127.0.0.1:11434 \
  --system-prompt-file app/card_system_prompt.txt --json-format schema
```

Send a structured-input request (e.g. "let me pick a date") and confirm a
card renders; send a plain question (e.g. "what's 2+2") and confirm readable
Markdown text renders — not a quoted JSON string leaking into the chat
bubble.

- [ ] **Step 4: Report completion to the user**

Summarize: all tasks committed, full suite green, manual check result (if
performed). Do not invoke `superpowers:finishing-a-development-branch` unless
the user asks — this repo's `AGENTS.md` plan-completion gate requires the
full verification above before any "complete" claim, which this task
satisfies.

---

### Task 8 (addendum, post-PR): `.vscode/launch.json` card-mode targets

**Gap identified after PR #31 was opened:** Tasks 1-7 never touched
`.vscode/launch.json`, even though it is a git-tracked file with two launch
configs whose entire purpose is exercising card replies —
`"Adaptive Chat Server (Ollama llama3.2, card prompt)"` and
`"Adaptive Chat Server (Ollama gpt-oss:20b, card prompt)"` — both passing
`--system-prompt-file app/card_system_prompt.txt`. They relied silently on
the `schema` default rather than naming `--json-format` explicitly, which
made the connection between "this target asks for cards" and "this feature
constrains the JSON" invisible to anyone reading the file.

**Files:**

- Modify: `.vscode/launch.json` (both card-prompt configs' `args` arrays and
  their explanatory comments)

**Change:** add `"--json-format", "schema"` to both configs' `args` (no
behavior change — `schema` was already the default — purely making it
explicit and self-documenting), plus a comment line pointing at
`docs/superpowers/specs/2026-07-23-ollama-structured-json-output-design.md`.

**No test coverage applies** — `.vscode/launch.json` is IDE configuration,
not code under test; verification is visual inspection that the JSON/JSONC
structure remains valid (matched braces, comma placement) after the edit.

- [x] **Step 1: Edit both card-prompt configs in `.vscode/launch.json`**

For `"Adaptive Chat Server (Ollama llama3.2, card prompt)"`, insert
`"--json-format", "schema"` immediately after `"app/card_system_prompt.txt"`
in its `args` array, and add this line to its leading comment block:

```
// --json-format schema is the default (docs/superpowers/specs/2026-07-23-
// ollama-structured-json-output-design.md) but named explicitly here since
// this target's whole purpose is exercising reliable card JSON.
```

Repeat identically for `"Adaptive Chat Server (Ollama gpt-oss:20b, card
prompt)"`.

- [x] **Step 2: Verify the file is still well-formed**

Read the edited regions back and confirm brace/comma structure is intact
(no automated linter for VS Code's JSONC `launch.json` in this repo).

- [ ] **Step 3: Show the diff and commit (after user confirmation)**

```bash
git diff -- .vscode/launch.json docs/superpowers/plans/2026-07-23-ollama-structured-json-output.md
```

Show the diff, wait for explicit confirmation, then commit and push to the
already-open PR's branch (`feat/ollama-structured-json-output`) — not `main`.
