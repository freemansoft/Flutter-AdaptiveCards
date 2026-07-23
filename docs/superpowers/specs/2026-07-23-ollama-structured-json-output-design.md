# Design: Ollama structured-output constraint for card replies (`adaptive_chat_server`)

- **Date:** 2026-07-23
- **Scope:** `adaptive_chat_server` (Python). No change to `adaptive_chat_client` (Flutter) or any package under `packages/`.

## Problem

`OllamaResponder` (`app/ollama_responder.py`) asks the model for JSON purely
through prompt engineering (`app/card_system_prompt.txt`): "output nothing
before the first `{` or `[`", "never abbreviate", etc. Nothing in the
`/api/chat` request constrains the model's output — Ollama's structured-output
support (`format` field) is unused.

This is unreliable by construction. `app/card_detect.py` already documents and
tolerates one observed failure mode (a leaked `=== ` prefix, fixed in
[2026-07-21-card-json-leaked-prefix-design.md](./2026-07-21-card-json-leaked-prefix-design.md)),
and the prompt itself warns that "a big, deeply nested card is where the JSON
most often ends up malformed and is shown as raw text instead." Prompt tuning
and parser tolerance can only chase failure modes after they're observed; they
cannot guarantee correctness up front.

Ollama supports constraining decoding via the request's `format` field:
`format: "json"` (any syntactically valid JSON value) or `format: <json-schema>`
(grammar-constrained decoding against a schema). Neither is used today.

## Constraint: replies are not always cards

`card_system_prompt.txt` gives the model two reply shapes per turn: a raw
Adaptive Card JSON fragment, or plain Markdown prose (the common case — most
turns are ordinary chat answers, not structured input requests). Ollama's
`format` constraint applies to the **entire** response for a request; it
cannot mean "JSON sometimes, plain text other times" within one call. Any
design that constrains output must preserve the plain-Markdown path, not just
the card path.

## Decision

Use a **discriminated-union JSON Schema** covering both reply shapes, applied
via `format`, selectable per-deployment through a new `--json-format
{none,json,schema}` flag (default `schema`):

- **`none`** — today's behavior. No `format` key sent. Escape hatch / basis for
  comparison.
- **`json`** — `format: "json"`. Ollama's generic valid-JSON grammar (any JSON
  value — object, array, or string). Guarantees syntax only.
- **`schema`** — `format: <app/card_schema.json>`. Guarantees syntax **and**
  the outer shape (card object / element array / single element / plain
  string) — the same three shapes `card_detect.py` already parses, plus a
  string branch for prose.

The schema deliberately does **not** constrain each element type's internal
properties (no per-element schema for `TextBlock`, `Input.ChoiceSet`, etc.) —
scope is kept to the outer shapes `try_parse_card_body` already validates,
keeping the schema small and low-maintenance. Per-element correctness remains
the prompt's job, same as today.

Every mode reuses one response-handling path in `OllamaResponder.reply()` —
`json`, and `schema` differ only in what `format` value is sent, not in how
the response is interpreted.

## Design

### 1. New file: `app/card_schema.json`

```json
{
  "$defs": {
    "Element": {
      "type": "object",
      "required": ["type"],
      "properties": { "type": { "type": "string", "minLength": 1 } }
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

This mirrors `try_parse_card_body`'s existing acceptance rules exactly: a full
card needs a non-empty `body` array of typed objects; a bare array must be
non-empty typed objects; a single element just needs a non-empty string
`type`. The `string` branch is the plain-Markdown reply.

### 2. `app/ollama_responder.py`

New constructor parameter `json_format: str = "schema"` (values `"none"`,
`"json"`, `"schema"`), alongside a new `DEFAULT_JSON_FORMAT = "schema"`
constant next to the existing `DEFAULT_*` constants.

**Schema loading** (schema mode only), at construction — not per-request,
since it's static config, unlike the hot-editable system prompt:

```python
def _load_card_schema(path: Path) -> dict | None:
    """Load and sanity-check card_schema.json; None (not fatal) on any problem."""
    try:
        schema = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        logger.error(
            "Card schema unusable (%s: %s) at %s — falling back to "
            "json_format=none for this process.",
            type(exc).__name__, exc, path,
        )
        return None
    if "oneOf" not in schema or "$defs" not in schema:
        logger.error(
            "Card schema at %s missing expected 'oneOf'/'$defs' keys — "
            "falling back to json_format=none for this process.",
            path,
        )
        return None
    return schema
```

If `json_format == "schema"` and loading fails, downgrade `self._json_format`
to `"none"` for the life of the process (never raise at construction or per
request — consistent with this module's existing "never raises to the
caller" contract for the system-prompt file).

**Request payload** — conditionally add `format`:

```python
if self._json_format == "json":
    payload["format"] = "json"
elif self._json_format == "schema" and self._card_schema is not None:
    payload["format"] = self._card_schema
```

**Response handling** — replaces the unconditional
`card_body = try_parse_card_body(content)` call, but must feed into the
*same* shared logging that already follows it (`_log_context_fill`, the
"looked like a card but wasn't usable" warning, the debug log) rather than
early-returning around them:

```python
self._log_context_fill(data)

reply_text = content
card_body: list | None = None
used_format_path = False
if self._json_format != "none":
    try:
        parsed = json.loads(content)
    except ValueError:
        pass  # unexpected: format guarantee failed; fall through to legacy path
    else:
        used_format_path = True
        if isinstance(parsed, str):
            reply_text = parsed
        else:
            card_body = try_parse_card_body(json.dumps(parsed))
if not used_format_path:
    card_body = try_parse_card_body(content)

# --- unchanged from here: the existing card_parse_failure_reason warning
# block and logger.debug call, operating on `content` as before, followed by
# `return Reply(text=reply_text, card_body=card_body)` ---
```

Notes:

- `reply_text` (not `content`) feeds the final `Reply(...)` call. The
  plain-string branch sets it to the **unwrapped** string (real
  newlines/Markdown, via `json.loads`'s own unescaping) instead of the
  JSON-quoted form, since `Reply.text` threads into conversation history sent
  as plain message content on the next turn. Every other branch leaves it as
  `content`, unchanged from today.
- `used_format_path` distinguishes "format guarantee held, use its result" from
  "fall back to the legacy heuristic on raw `content`" — the latter covers both
  `json_format == "none"` and the unexpected case where `json.loads` itself
  raised despite a format constraint being set.
- `try_parse_card_body` and `card_parse_failure_reason` in `app/card_detect.py`
  are **unchanged** — reused as-is, on `json.dumps(parsed)` (already-valid
  JSON) instead of raw model text when the format path held. In `schema` mode
  this call effectively always succeeds (the schema already enforces the
  shape); in `json` mode it is still load-bearing, since generic JSON allows
  shapes the schema would have excluded (e.g. a bare number) — that case falls
  through to the existing "looked like JSON but not usable" warning exactly as
  it does today.
- The existing `card_parse_failure_reason` warning and `logger.debug` calls
  still run against `content` (the raw wire text) in every path, so debugging
  a bad reply still shows exactly what Ollama sent, not the post-processed
  `reply_text`.

### 3. `app/__main__.py` / `app/main.py`

Add `--json-format` following the existing `--num-ctx` / `--history-turns`
pattern exactly:

- `__main__.py`: `argparse` choice `["none", "json", "schema"]`, default
  `DEFAULT_JSON_FORMAT`; sets `OLLAMA_JSON_FORMAT` env var.
- `main.py`: `build_responder()` gains `json_format: str = DEFAULT_JSON_FORMAT`
  param, read via `os.environ.get("OLLAMA_JSON_FORMAT", DEFAULT_JSON_FORMAT)`,
  passed to `OllamaResponder(...)`; include it in the existing startup log
  line.

### 4. `app/card_system_prompt.txt` (additive)

Add one short paragraph clarifying the dual-shape contract now that the whole
response may be JSON-constrained — the grammar enforces valid JSON either way,
but the model should understand *why* a plain-text answer comes back quoted:

> When your reply is plain Markdown text (Reply shape 2), your entire response
> is still a JSON value — write it as a JSON string (e.g.
> `"Here's what I found:\n\n- ..."`). Your Markdown content goes inside the
> string unchanged; only the surrounding quoting is new.

Existing instructions (the three card shapes, "never abbreviate", element
list, etc.) are untouched.

## Error handling

| Failure | Handling |
| --- | --- |
| `card_schema.json` missing/invalid JSON/missing expected keys | Logged as error at construction; `json_format` downgraded to `"none"` for the process. Never crashes startup or a request. |
| Ollama too old to honor `format` | Already handled by the existing `response.status_code >= 400` path (logged, diagnostic `Reply`) — no new code needed. |
| `json.loads(content)` fails despite `format` being set | Falls through to the existing heuristic `try_parse_card_body(content)` path — same behavior as `json_format="none"` today. |
| Valid JSON, but not string/card-shaped (only reachable in `json` mode) | `try_parse_card_body` returns `None`; `Reply(text=content, card_body=None)` — renders as raw-JSON text, same externally-visible outcome as today's "valid JSON but not a renderable card" case. |

## Testing

`tests/test_ollama_responder.py` (extends existing mocked-`httpx.Client` style):

- Payload construction per mode: no `format` key (`none`); `format == "json"`;
  `format == <loaded schema dict>`.
- Response branching: plain-text JSON string → unwrapped `Reply.text`,
  `card_body=None`; card-shaped JSON → `card_body` populated, `Reply.text`
  unchanged raw content; `json.loads` failure despite format set → falls back
  to heuristic path (reuse an existing malformed-JSON test case).
- Schema loading: valid file loads; missing/corrupt file logs an error and
  downgrades to `none` (assert no `format` key sent on the next request).

New test coverage for `app/card_schema.json` itself: `json.loads` the file and
assert the expected `$defs`/`oneOf` keys are present — no new `jsonschema`
dependency; Ollama performs the actual grammar enforcement, so this is only a
"did I typo the file" guard, not spec validation.

`app/card_detect.py` and `tests/test_card_detect.py` are **unchanged** — the
parser is reused as-is, not modified, per design decision above.

## Non-goals

- No change to the Flutter client (`adaptive_chat_client`) — card-vs-text
  detection stays server-side.
- No per-element property schemas (`TextBlock.text`, `Input.ChoiceSet.choices`,
  etc.) — out of scope; the prompt remains the source of truth for
  per-element correctness.
- No version/model compatibility detection for Ollama's `format` support —
  assumed available on any reasonably current Ollama install (supported since
  ~0.1.9 / early 2024).
- No package `CHANGELOG.md` entry: `adaptive_chat_server` lives outside
  `packages/`.

## Verification

From `adaptive_chat_server` (using the repo `.venv`):

```bash
cd adaptive_chat_server
.venv/bin/python -m pytest tests/test_ollama_responder.py tests/test_card_system_prompt.py tests/test_card_detect.py
```

Expect all existing tests to keep passing, plus new cases for the three
`json_format` modes and schema-loading failure handling.

Manual check against a running Ollama (`--json-format=schema`): a request that
would ask for structured input (e.g. "let me pick a date") returns a renderable
card; a plain question (e.g. "what's 2+2") returns readable Markdown text, not
a quoted JSON string leaking into the chat bubble.
