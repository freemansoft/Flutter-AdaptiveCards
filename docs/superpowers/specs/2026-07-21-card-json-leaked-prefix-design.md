# Design: fix leaked-prefix card JSON (`adaptive_chat_server`)

- **Date:** 2026-07-21
- **Scope:** `adaptive_chat_server` (Python). No change to `adaptive_chat_client` (Flutter) or any package under `packages/`.

## Problem

When the card system prompt is active, the local Ollama model sometimes emits a
leading delimiter before the JSON, e.g.:

```
=== \n{"type":"Input.ChoiceSet","id":"states","style":"compact","choices":[...]}
```

The server's card detector (`app/card_detect.py:try_parse_card_body`) requires the
_entire_ reply (after stripping an optional code fence) to be valid JSON. The
`=== ` prefix makes `json.loads` throw, so the reply falls back to a raw-text
`TextBlock` and the user sees raw JSON instead of a rendered card.

### Root cause

The `=== ` almost certainly comes from the model mimicking the `=== 1. … ===` /
`=== 2. … ===` section headers in `app/card_system_prompt.txt` (lines 7 and 62).
`_strip_fence` only removes ` ```json ` / ` ``` ` code fences — not a `=== `
prefix — so the leaked delimiter breaks parsing.

### Layer note

Card-vs-text detection is **server-side** only. The Flutter client parses just the
chat _envelope_ (`adaptive_chat_client/lib/src/chat_backend_client.dart`) and
renders whatever pre-styled cards the server sends (`cards.py`, "client stays
dumb"). Any JSON pruning therefore belongs in the **server**, not the client.

## Decisions

1. **Fix both layers** — harden the server parser (the load-bearing fix) _and_
   remove the `=== ` decoration from the prompt (removes the failure at the
   source). Belt-and-suspenders, as production LLM integrations do.
2. **Narrow tolerance** — strip only surrounding _decoration_ (whitespace, code
   fences, pure-delimiter runs like `===`, `---`, `###`). Real prose words before
   or after the JSON keep the reply as text, preserving the existing conservative
   "prose-wrapped JSON → text" contract and minimizing false positives.

## Design

### 1. Parser hardening — `app/card_detect.py`

Add a decoration-stripping step to the existing fence handling. Define
**decoration** as a maximal run of whitespace plus the delimiter punctuation
`= - # * _ ~`.

Pipeline inside `try_parse_card_body` (via a helper, e.g. `_strip_decoration`
composed with the existing `_strip_fence`):

1. `raw.strip()`
2. strip a surrounding code fence (existing `_FENCE` regex)
3. strip a **leading** run of decoration-only chars — halts at the first
   non-decoration char (e.g. `{` or `[`)
4. strip a **trailing** run of decoration-only chars
5. `json.loads` → existing shape validation, unchanged (full
   `{"type":"AdaptiveCard","body":[…]}` → its body; non-empty array of objects →
   as-is; single typed element → `[element]`; empty body, scalars, mixed/empty
   arrays, and `type`-less dicts → `None`)

Implementation sketch:

```python
_DECORATION = re.compile(r"^[\s=\-#*_~]+|[\s=\-#*_~]+$")

def _strip_decoration(text: str) -> str:
    # Applied after fence stripping. Removes leading/trailing whitespace and
    # pure-delimiter runs (===, ---, ###, ***). Halts at the first content char
    # (e.g. { or [), so JSON is never clipped.
    return _DECORATION.sub("", text)
```

Ordering matters: strip fence first, then decoration (a fenced reply's inner text
may still carry a stray delimiter line), then parse.

**Why this is narrow / safe:**

| Input                  | Leading/trailing stripped                | Result               |
| ---------------------- | ---------------------------------------- | -------------------- |
| `=== \n{card}`         | leading `=== \n`                         | card ✓               |
| `Here you go: {card}`  | leading whitespace only (`H` is content) | parse fails → text ✓ |
| `{card}\nLet me know!` | trailing `!`/letters are content         | parse fails → text ✓ |
| `{card}\n===`          | trailing `\n===`                         | card (symmetric) ✓   |
| `###\n[element,…]`     | leading `###\n`                          | array ✓              |

The first `{`/`[` halts leading stripping, so a JSON value's own content is never
removed. A leading `-` on a bare scalar (`-5`) would be stripped to `5`, which
still validates as a scalar → `None`, so no meaningful behavior change.

Update the module docstring and `try_parse_card_body` docstring to state that
leading/trailing decoration (delimiter lines such as `=== `) is tolerated, while
surrounding **prose** still yields `None`.

### 2. Prompt cleanup — `app/card_system_prompt.txt`

- Replace the `=== 1. Adaptive Card fragment (structured) ===` header (line 7) and
  the `=== 2. Plain Markdown (no structured input) ===` header (line 62) with plain
  headers, e.g. `## Reply shape 1: Adaptive Card fragment (structured)` and
  `## Reply shape 2: Plain Markdown (no structured input)`, so the model has no
  `=== ` delimiter to mimic.
- Add one explicit instruction near the card-fragment rules: _"Output nothing
  before the first `{` or `[` and nothing after the closing bracket — the entire
  message must be the raw JSON."_ (Reinforces the existing "no surrounding prose /
  no code fence" guidance.)
- Check `tests/test_card_system_prompt.py`; update any assertion that pins the old
  `=== ` header text.

### 3. Tests — `tests/test_card_detect.py`

Add:

- `=== \n{full AdaptiveCard with non-empty body}` → its body
- `=== \n{single Input.ChoiceSet element}` → `[element]`
- leading **and** trailing decoration around a bare array → the array
- `###\n{…}` and `---\n{…}` prefix variants → parsed
- **prose with a non-empty body** (e.g. `Here is a card: {"type":"AdaptiveCard",
"body":[{"type":"TextBlock","text":"hi"}]}`) → `None` (locks the narrow
  contract; the existing prose test uses an empty body and would pass regardless)

Keep all existing tests green, including `test_prose_wrapped_json_returns_none`.

## Non-goals

- No change to the Flutter client (`adaptive_chat_client`).
- No "broad" extraction of JSON embedded mid-prose (explicitly rejected — would
  drop a chatty reply's explanatory text).
- No package `CHANGELOG.md` entry: these apps live outside `packages/`. The
  `card_detect.py` docstring is the source of truth and is updated in place.

## Verification

From `adaptive_chat_server` (using the repo `.venv`):

```bash
cd adaptive_chat_server
.venv/bin/python -m pytest tests/test_card_detect.py tests/test_card_system_prompt.py tests/test_responder.py
```

Expect all tests to pass, including the new decoration cases and the existing
prose/empty-body/scalar guards.
