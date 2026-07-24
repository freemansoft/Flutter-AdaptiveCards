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
_same_ shared logging that already follows it (`_log_context_fill`, the
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
but the model should understand _why_ a plain-text answer comes back quoted:

> When your reply is plain Markdown text (Reply shape 2), your entire response
> is still a JSON value — write it as a JSON string (e.g.
> `"Here's what I found:\n\n- ..."`). Your Markdown content goes inside the
> string unchanged; only the surrounding quoting is new.

Existing instructions (the three card shapes, "never abbreviate", element
list, etc.) are untouched.

## Error handling

| Failure                                                                | Handling                                                                                                                                                                                        |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `card_schema.json` missing/invalid JSON/missing expected keys          | Logged as error at construction; `json_format` downgraded to `"none"` for the process. Never crashes startup or a request.                                                                      |
| Ollama too old to honor `format`                                       | Already handled by the existing `response.status_code >= 400` path (logged, diagnostic `Reply`) — no new code needed.                                                                           |
| `json.loads(content)` fails despite `format` being set                 | Falls through to the existing heuristic `try_parse_card_body(content)` path — same behavior as `json_format="none"` today.                                                                      |
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

## Addendum (2026-07-23): duplicate-key data loss in `Carousel.pages` / `Table.rows`

Manual testing against a real Ollama (`0.32.3`, `llama3.2:latest`) after PR #31
merged Tasks 1-7 found a real gap: `schema` mode's grammar constraint
guarantees _syntactic_ JSON validity but not _semantic_ correctness, and one
semantic failure mode is dangerous enough to need its own fix.

### What was found

Direct `/api/chat` testing (bypassing the server, isolating Ollama's actual
behavior) with a schema that **explicitly and correctly** models
`Carousel.pages` / `Table.rows` as typed arrays (not the generic
envelope-only `Element`) still produced responses like:

```
{"type":"Carousel","pages":[{...page 1...}],"pages":[{...page 2...}]}
```

This is **legal JSON syntax** — object keys may legally repeat — but
`json.loads` (both Python's default and `card_detect.py`'s usage of it)
silently keeps only the **last** occurrence of a repeated key, so a 5-page
carousel silently collapses to 1 page with no error, no warning, and no
visible sign anything went wrong. This is worse than a visible parse
failure: the model repeating an object-property key instead of extending
one array, under grammar-constrained decoding, is a genuine limitation of
this small model (llama3.2) combined with Ollama's schema-to-grammar
compilation — not something fixable by better schema authoring, confirmed
by testing an explicit, correctly-typed schema and still observing the
failure.

**Measured failure rate** (repeated identical requests against the real
model): `Carousel.pages` failed 5/5 times; `Table.rows` failed 1/4 times.
Flat elements and _top-level_ bare arrays (not nested as an object
property) were reliable in every test — the failure is specific to
"multi-item array required as an object property."

**Important correction — the corruption is not one pattern, it's a family.**
Inspecting all 7 non-clean captures from testing found the model corrupts
these structures in at least four distinct ways, only one of which is a
literal duplicate key:

1. **Literal duplicate key** — `"pages":[...],"pages":[...]`. The pattern
   above; the guard below catches exactly this.
2. **Misplaced sibling key** — the second item's content lands as a _new,
   different_ key directly on the parent object instead of properly nested
   (observed: a second Carousel page's items appeared as a bare `"items"`
   property sitting alongside `"pages"` on the `Carousel` object itself,
   rather than inside a second `CarouselPage`). Not a repeated key, so the
   guard does **not** catch this.
3. **Trailing garbage appended after a structurally-complete object** —
   e.g. a valid `Carousel` object followed by a stray duplicate `"type"` key
   fragment and disconnected empty-object noise, all still inside the
   _same_ JSON object due to how the garbage was tokenized. Legal JSON;
   the guard does not catch this either since no key is literally repeated.
4. **Wrong nesting depth** — e.g. a `TableCell` nested directly inside
   another `TableCell` instead of forming a second `TableRow`, silently
   losing an entire row. Also not a duplicate key.

All four are variations on the same root cause (the model cannot reliably
extend a required multi-item array property under grammar-constrained
decoding) but only pattern 1 is mechanically detectable by checking for a
repeated object key. Patterns 2-4 require actual per-element structural
validation (e.g. "a `Carousel` object may only have `type`/`version`/
`pages`") to catch — which is exactly the per-element property schema
work this design's Non-goals section explicitly ruled out, and which
`jsonschema`-style validation would be needed for (a new dependency,
also ruled out).

### Decision

1. **Ship a duplicate-key guard** (Task 9 below) for pattern 1 specifically.
   This is a **narrow, honest mitigation** — it converts the single most
   mechanically-detectable corruption signature from silent data loss into
   a visible fallback. It does **not** make `Carousel`/`Table` reliable
   under `schema` mode; patterns 2-4 above still pass through undetected
   and may still render as a broken or incomplete card. It is still worth
   shipping: it is general-purpose (protects any element with this shape,
   not just these two), zero-risk to well-formed content, and closes the
   most-likely-to-recur single pattern for free.
2. **Do not** attempt a deeper architectural fix (e.g. having the model
   emit pages/rows as reliable top-level arrays with server-side
   reassembly into the proper nested shape) at this time. That would touch
   `card_detect.py` (previously "unchanged, reused as-is") and is real new
   scope. Carousel/Table remain a known lower-reliability case under
   `schema` mode for small local models; documented here rather than
   silently shipped.
3. **Do not** attempt a prompt-wording nudge ("never repeat the pages/rows
   key") as a mitigation — deferred; it would at best help pattern 1 (and
   is unproven for a 3B model), while patterns 2-4 are unrelated to key
   repetition and wouldn't be touched by prompt wording at all.

### Design: the guard

**Where:** `app/ollama_responder.py` only — `card_detect.py` stays
untouched, per the original constraint. The guard is needed precisely
_because_ `card_detect.py`'s own `json.loads` usage has the same blind
spot, so falling back to it after detecting a duplicate key would silently
reproduce the exact bug being fixed.

```python
class _DuplicateJsonKeyError(ValueError):
    """A JSON object had a repeated key -- legal JSON, but json.loads silently
    keeps only the last value, silently dropping data (observed for
    Carousel.pages / Table.rows under Ollama's schema-constrained decoding:
    the model sometimes re-emits the same property key once per item instead
    of appending items to one array)."""


def _reject_duplicate_keys(pairs: list[tuple[str, object]]) -> dict:
    seen: set[str] = set()
    for key, _ in pairs:
        if key in seen:
            raise _DuplicateJsonKeyError(f"duplicate key {key!r}")
        seen.add(key)
    return dict(pairs)
```

`reply()`'s response-handling block passes `object_pairs_hook=
_reject_duplicate_keys` to its `json.loads(content, ...)` call. A new
`except _DuplicateJsonKeyError:` branch (checked _before_ the existing
generic `except ValueError:`, since `_DuplicateJsonKeyError` subclasses it)
sets a `duplicate_key_detected` flag. When set: skip the legacy
`try_parse_card_body(content)` fallback entirely (same blind spot), skip
`card_parse_failure_reason` (same blind spot — it also calls
`try_parse_card_body` internally and would report "no failure, this is a
valid card"), and log a new dedicated warning naming the actual cause
instead. `card_body` stays `None`, `reply_text` stays `content` — renders
as visible raw text, the same safe outcome as any other detected failure.

### Testing

- A duplicate-key `Carousel` response (`{"pages":[...],"pages":[...]}`)
  renders as text (`card_body is None`), with a WARNING logged naming the
  duplicate-key cause specifically (not the generic "not usable" message).
- A regression check that a normal, non-duplicate nested card (e.g. the
  existing `test_reply_detects_card_through_schema_format` case) is
  unaffected — the hook must not change behavior for well-formed JSON.
- No test is added for patterns 2-4 above — by design, the guard does not
  claim to catch them, so there is nothing to assert.

### Verification

```bash
cd adaptive_chat_server
.venv/bin/python -m pytest
```

Expect all existing tests to keep passing, plus new cases for the three
`json_format` modes and schema-loading failure handling.

Manual check against a running Ollama (`--json-format=schema`): a request that
would ask for structured input (e.g. "let me pick a date") returns a renderable
card; a plain question (e.g. "what's 2+2") returns readable Markdown text, not
a quoted JSON string leaking into the chat bubble.

## Addendum (2026-07-23, part 2): `additionalProperties` and the `isMultiSelect` limitation

Further manual testing surfaced a second, distinct real-Ollama failure, and
an attempt to fix a related prompt-accuracy issue that testing showed does
**not** actually work.

### Finding: properties smuggled into the `type` string

A live request for radio buttons over 5 US states returned:

```
{"type":"Input.ChoiceSet','id':'top5states','style':'expanded','isMultiSelect':false,'choices':[...]}assistant"

  }
```

This is legal JSON with exactly **one** key, `"type"` — its value is the
entire garbled blob (single-quoted pseudo-JSON, not real JSON structure).
`try_parse_card_body` correctly-but-uselessly accepted this as "a single
element with a non-empty `type`," and the Flutter client then tried to
render an element whose `type` is that whole garbage string, showing an
unknown-element fallback.

**Root cause:** `card_schema.json`'s `Element` definition did not set
`"additionalProperties": true`. Without it, Ollama's schema-to-grammar
compiler has no legal path for the model to write `id`/`style`/
`isMultiSelect`/`choices` as real sibling JSON keys — the model, still
wanting to express that content (per the prompt's own `Input.ChoiceSet`
example), smuggles it as fake single-quoted text inside the only string
slot available (`type`'s value) instead, since a JSON string may legally
contain any character including unescaped single quotes.

**Verified fix:** adding `"additionalProperties": true` to `Element`.
Reproduced the bug 1/1 with the unmodified schema, then confirmed the fix
3/3 clean runs (proper double-quoted JSON, all real keys) with the same
requests. Also re-tested the already-documented `Carousel.pages`
duplicate-key issue with this same change: not a full fix (2/4 runs still
showed a duplicate key or merged content), but a clear improvement over the
0% clean rate recorded in the prior addendum, with no observed downside.
Implemented in `app/card_schema.json`; no other file changes were needed —
`ollama_responder.py`'s response-handling logic (Task 3) already handles a
well-formed multi-property `Element` correctly, since that capability was
never schema-specific.

### Finding: `isMultiSelect` accuracy — tested, not fixable by prompt wording

Separately, the model was reported returning `Input.ChoiceSet` with
`"isMultiSelect":false` for an explicit checkbox request (should be `true`).
Two prompt-wording mitigations were tested empirically against the live
model (10 additional live requests) before deciding not to ship either:

- **Strengthened instruction** ("isMultiSelect controls single-vs-multiple
  selection... do not default to false"): 4/4 still wrong, byte-identical
  output to the unmodified prompt.
- **Reordered examples** (checkboxes example last, with an explicit
  "OPPOSITE of radio buttons above" callout): 5/6 still wrong, 1/6 correct.

Combined across both wordings and the original: 13/14 wrong. This is not a
prompt-clarity problem fixable with reasonable wording effort — it reads as
a genuine capability limitation of llama3.2 (3B) for this specific boolean
semantic mapping, the same character of limitation as the `Carousel`/
`Table` array issue, just manifesting on a boolean instead of array
structure.

**Decision:** do not ship a prompt change for this. Shipping a change that
testing shows barely moves the needle (0/8 → 1/6) would overstate what was
fixed. `card_system_prompt.txt` is unchanged from the prior addendum's
`Input.RadioButtons`/`Input.Checkboxes` fix (which **did** work — the model
now reliably uses the real `Input.ChoiceSet` type name; only the
`isMultiSelect` boolean value is unreliable for checkbox requests
specifically). Documented here as a known limitation rather than silently
left unmentioned.

### Testing

- `test_bundled_card_schema_element_allows_additional_properties`: asserts
  the shipped schema's `Element` has `additionalProperties: true` — a
  config regression guard, since this cannot be exercised by a mocked unit
  test (Ollama's grammar compiler is what actually changes behavior; the
  fix is validated by the live-Ollama testing above, not by this test
  alone).
- `test_reply_detects_choiceset_with_real_properties_through_schema_format`:
  confirms a well-formed multi-property `Input.ChoiceSet` response parses
  correctly end-to-end — locks in the target shape this fix aims for.

### Verification

```bash
cd adaptive_chat_server
.venv/bin/python -m pytest
```

Manual check against a running Ollama (`--json-format=schema`): a radio-button
or checkbox request over several choices returns a single well-formed
`Input.ChoiceSet` with `id`/`style`/`isMultiSelect`/`choices` all present as
real JSON keys, not smuggled into the `type` string.

## Addendum (2026-07-23, part 3): enum-constrained `type` + palette expansion

### Finding: an unconstrained `type` string permits invalid element names

`Element.type` was `{"type":"string","minLength":1}` — any non-empty string,
including a hallucinated name that doesn't exist in the client's registry
(e.g. `Input.RadioButtons` instead of the real `Input.ChoiceSet`, fixed by
prompt wording in an earlier commit). That prompt fix worked, but nothing at
the schema layer _guaranteed_ it — a differently-phrased prompt or a
different model could reintroduce the same class of failure.

**Fix:** constrain `type` to a JSON Schema `enum` of exactly the element
names `card_system_prompt.txt` documents. Verified empirically:

- With the enum in place, using the **original, pre-fix prompt wording**
  (the weaker version that never mentions `Input.RadioButtons` as forbidden)
  — 3/3 clean runs, correct `Input.ChoiceSet` every time. This proves the
  enum is a genuine _structural_ guarantee, not just reinforcement of the
  prompt fix: the prior prompt-only fix remains in place (belt-and-suspenders),
  but the schema now makes an invalid type name impossible under `schema`
  mode regardless of prompt wording.

Cross-checked against the real dispatchers to confirm every enum value is a
real, correctly-cased, spelled-correctly registered type:
`packages/flutter_adaptive_cards_fs/lib/src/registry.dart:158-242`
(`_getBaseElement`, case-sensitive exact string match, no normalization).

### Decision: expand the palette with read-only display primitives

The dispatcher supports far more than the prompt's original 10 types. Rather
than expand to the full registry (which would include types the model has
no in-prompt worked examples for, shifting malformation risk elsewhere) or
leave the palette untouched, added six additional types matching the
existing risk model this whole feature is built around: all six have
**flat/scalar properties only, no nested arrays-of-items** (confirmed
against each element's actual Dart property-reading code before adding):

- `Rating` — the read-only display variant (not `Input.Rating`, a separate
  interactive input, intentionally excluded — inputs already have their own
  section).
- `Icon`, `ProgressBar`, `ProgressRing`, `CodeBlock` — all-scalar properties,
  no external resource dependency, unambiguously non-interactive.
- `Image` — the one exception with an external dependency (`url` must
  resolve to a real image). Considered and accepted the risk: the model has
  no access to real image assets and could invent a non-resolving URL,
  showing a broken-image icon. The prompt explicitly instructs "only use
  this when you have a real, working image URL... never invent a
  placeholder or made-up URL" as mitigation. This is a _visible_ failure
  mode (a broken image icon is obviously broken to the user), not the
  silent-data-loss class of bug this whole feature exists to close, so the
  residual risk was judged acceptable.

**Explicitly excluded:** `CompoundButton` — renders as a disabled/inert
button without a `selectAction` (which the prompt forbids providing),
visually implying interactivity it doesn't have. A worse UX surprise than
the elements above, none of which look interactive. `Container`, `ColumnSet`,
`ImageSet`, `Media`, `RichTextBlock`, `Accordion`, `TabSet`/`TabPage`, and all
`Chart.*` types were not considered for this pass — several have nested
arrays-of-items (the exact unreliable pattern documented in the first
addendum), `RichTextBlock` is redundant with `TextBlock`'s existing Markdown
support (already noted in the prompt), and `Chart.*` requires
`flutter_adaptive_charts_fs`, which isn't wired into this chat demo.

**Validated all six against a live Ollama** (6 requests, one per new type,
using the actual updated prompt + schema): all six produced valid JSON with
no malformed output. Two requests (`ProgressRing`, `CodeBlock`) had the model
substitute a different valid existing type (`Badge`, `TextBlock`
respectively) for ambiguous phrasing — a model _preference_, not a
reliability defect; `TextBlock`'s Markdown already documents fenced-code
support, so a one-line code request landing there is a reasonable outcome.
`Image` picked a real, working Wikipedia URL for a well-known landmark in
testing, consistent with the "only real URLs" instruction.

### Testing

- `test_bundled_card_schema_constrains_type_to_the_prompt_palette`: asserts
  the shipped schema's `Element.type` enum is exactly the 16-name set
  (10 original + 6 new) matching `card_system_prompt.txt`.
- `test_card_prompt_documents_readonly_display_elements`: asserts all six
  new type names are documented in the prompt.

### Verification

```bash
cd adaptive_chat_server
.venv/bin/python -m pytest
```

## Addendum (2026-07-24): model + decoding-settings comparison matrix

All prior addendums measured a single model (`llama3.2:3b`) at the server's
default decoding settings. A follow-up re-ran the documented failure modes
against two additional models to answer "would a bigger model fix this?" and,
incidentally, isolated a larger lever than model choice.

### Method

A harness drove `format=schema` requests through the same `card_schema.json`,
`card_system_prompt.txt`, and `card_detect` parser the server uses (duplicate-
key guard included), one request per documented failure mode, 3 reps each,
classifying each result as a clean/complete renderable card. Small sample
(n=3/case) — directional, not statistical. Prompts asked for: radio buttons
(type name + `isMultiSelect:false` + real property placement), checkboxes
(`isMultiSelect:true`), a 4-page Carousel (nested `pages` array), a 4-row
Table (nested `rows` array), a FactSet (flat baseline), and a plain-prose
question (string branch).

### Results

| Case                     | `llama3.2:3b` (server defaults, prior addenda) | `qwen3.5:9b` — thinking **on**, temp **1** (= server defaults today) | `qwen3.5:9b` — `think:false`, temp **0** | `qwen2.5-coder:7b` — temp **0**, non-thinking |
| ------------------------ | ---------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------- | --------------------------------------------- |
| radio                    | mixed                                          | —                                                                    | —                                        | 3/3                                           |
| checkbox `isMultiSelect` | 1/14                                           | garbage (see below)                                                  | clean                                    | 3/3                                           |
| carousel (nested pages)  | 0/5                                            | —                                                                    | clean                                    | 3/3                                           |
| table (nested rows)      | 1/4                                            | —                                                                    | —                                        | valid ✓ (see note)                            |
| factset (flat)           | reliable                                       | —                                                                    | —                                        | 3/3                                           |
| prose (string branch)    | ok                                             | —                                                                    | —                                        | 3/3                                           |
| **latency / call**       | fast                                           | **~77 s**                                                            | **~10 s**                                | **~9 s**                                      |

`qwen3.5:9b` weights are 6.6 GB (Q4_K_M, 9.7B); `qwen2.5-coder:7b` is 4.7 GB —
both fit a 16 GB Mac with room for the 16 K context.

### Findings

1. **Decoding settings dominate model choice for this task.** At the server's
   current defaults (temp 1, thinking on — the responder sends only
   `options:{num_ctx}`, so a thinking model thinks and samples hot),
   `qwen3.5:9b` answered a checkbox request with a `CodeBlock` of raw HTML
   (`<input type='checkbox'/>`) using invented keys (`codeLanguage`/`content`
   instead of `codeSnippet`), taking 77 s. The **same model** with
   `think:false` + `temperature:0` produced a clean `Input.ChoiceSet` and a
   clean 4-page Carousel in ~10 s. The garbage was a settings artifact, not a
   capability limit. **The single highest-leverage change is to have
   `OllamaResponder` send `temperature: 0` (and `think: false` for thinking-
   capable models) on the card path** — a code gap in `ollama_responder.py`,
   which today sends neither.

2. **`qwen2.5-coder:7b` at temp 0 is the recommended default for a 16 GB Mac.**
   It cleared every documented failure mode — including the two that defeated
   `llama3.2`: checkbox `isMultiSelect:true` (was 1/14) and nested-array
   Carousel (was 0/5) — at ~9 s/call, non-thinking so no `think` handling
   needed. Coder-tuned models are unusually strong at strict JSON syntax,
   which is precisely the card path's failure surface. Trade-off: coder models
   are terser on the plain-prose reply path; **`qwen2.5:7b`** (plain instruct,
   ~4.7 GB) is the better all-rounder if conversational answers matter more
   than maximal JSON reliability.

3. **`qwen3.5:9b` is usable only with thinking disabled**, and even then offers
   no reliability edge over `qwen2.5-coder:7b` here while costing slightly more
   latency and memory. Its thinking capability is a liability for constrained-
   JSON output. Not recommended as the default for this workload.

4. **The nested-array corruption family (this design's central concern) did not
   reproduce** on `qwen2.5-coder:7b` or tuned `qwen3.5:9b` in this run — it
   reads as specific to the 3B model under hot sampling. A better model + temp
   0 largely closes the gap the duplicate-key guard was built for. Keep the
   guard regardless: it is cheap, general-purpose insurance for any model/
   settings combination, and this run is a small sample.

5. **The Table "0/3" is a harness misclassification, not a model defect.** The
   raw output was a valid, complete, renderable Table containing all four
   country/capital pairs — the model laid them out as a 2×2 grid (two countries
   per row) rather than a 4-row country/capital table. The `rows >= 3` success
   criterion wrongly penalized a legitimate layout. No data loss, no
   corruption. (Prompt phrasing, not reliability.)

### Recommendation summary

- **Change the responder** to send `temperature: 0` on the card path, and
  `think: false` when the model advertises the thinking capability. Highest
  leverage; independent of model choice.
- **Default model on a 16 GB Mac:** `qwen2.5-coder:7b` (max JSON reliability)
  or `qwen2.5:7b` (best card + prose balance). Retire `llama3.2:3b` as the
  card-path default — it is the source of every failure documented above.
- Keep the duplicate-key guard as cheap insurance.

### Verification

```bash
cd adaptive_chat_server
# Harness (scratch, not committed): drives format=schema through the real
# card_schema.json / card_system_prompt.txt / card_detect path per model.
```

## Addendum (2026-07-24): `none` vs `schema` — the default flips to `none`

The prior addendum established that decoding settings (temperature 0, thinking
off) dominate model choice. This one asks the follow-on question: once the model
is capable and the settings are right, **does the schema grammar still earn its
place?** — and concludes it does not, as the default.

### Method

Same harness and failure-mode prompts as the model/settings addendum, run
against `qwen2.5-coder:7b` with the improved `card_system_prompt.txt`, comparing
`--json-format` modes at matched settings. A separate "adversarial type" probe
asked for elements outside the palette (pie chart, slider, submit button, bar
chart) to test schema's one structural guarantee — the `type` enum. Small
samples (n=3–5/case); directional, not statistical.

### Results (`qwen2.5-coder:7b`, improved prompt)

| Config                                             | Clean           | Latency   | Note                                                                                                                     |
| -------------------------------------------------- | --------------- | --------- | ------------------------------------------------------------------------------------------------------------------------ |
| `schema`, temp 0                                   | 18/18           | 8.9 s     | Table rendered as a 2×2 grid — the enum/`additionalProperties` grammar nudged a _worse_ layout                           |
| `none`, temp 0                                     | **24/24**       | **5.0 s** | Table = clean 4 rows; all cases clean                                                                                    |
| `none`, temp 1 (hot)                               | 18/18           | 6.4 s     | Still all clean without temp 0                                                                                           |
| `none`, temp 0, adversarial out-of-palette prompts | 5/5 valid types | —         | pie chart→FactSet, slider→Input.Number, submit button→TextBlock, radio→Input.ChoiceSet — never emitted an invalid `type` |

### Findings

1. **`none` matched or beat `schema` on every case**, while being simpler and
   ~40% faster (no schema-to-grammar compilation). The schema even _hurt_ once
   (the 2×2 table), consistent with the earlier `additionalProperties`/property-
   smuggling observations: grammar-constrained decoding can distort a capable
   model's output.
2. **Schema's marquee guarantee — the `type` enum — never fired.** Even under
   prompts designed to induce a hallucinated/out-of-palette type, the model
   degraded gracefully to a valid palette type or prose every time. The whole
   schema apparatus (enum, `additionalProperties`, the duplicate-key guard) was
   built to prop up the weak 3B model; a competent 7B model + the improved
   prompt + temp 0 does not need it.
3. **The heavy lifting is done by prompt + model + temperature 0, not the
   grammar.** `none` held even at temp 1 for this model, though temp 0 remains
   cheap variance insurance and is decisive for other models (e.g. qwen3.5).

### Decision

1. **Default `--json-format` flips from `schema` to `none`.** With the default
   model at temp 0 the prompt is sufficient; `schema` adds latency and can
   distort output without measurably improving reliability.
2. **Deterministic settings (`temperature 0`, `think:false`) are ungated** — now
   applied on **every** Ollama request, in all `json_format` modes, since they
   (not the grammar) are what make `none` reliable. Previously they were gated to
   the constrained modes.
3. **`schema` (and `json`) mode is kept, not removed.** It remains a real safety
   net for **weaker or different models**, where the earlier addenda show it is
   decisive (llama3.2: Carousel 0/5, checkbox `isMultiSelect` 1/14). The flag and
   schema file cost ~nothing to keep. The `.vscode/launch.json` card targets pin
   `--json-format none` explicitly and note schema as the fallback.

### Caveats

Small samples, one model, curated prompts. The single failure `schema` prevents
(a silent invisible-blank from a hallucinated `type`) is low-frequency, high-
severity, and silent — exactly the kind a small sample under-detects. That is
why `schema` is demoted from the default, **not deleted**: it stays one flag away
for anyone running a weaker model or wanting the worst-case structural guarantee.

### Verification

```bash
cd adaptive_chat_server
.venv/bin/python -m pytest   # 113 passing incl. temp/think + default-none tests
```
