# Adaptive Chat — text-or-card assistant replies (display-only)

**Date:** 2026-07-20
**Status:** Approved (design)
**Applies to:** `adaptive_chat_client` (Flutter client) and `adaptive_chat_server` (FastAPI backend)
**Pairs with:** [`2026-07-18-adaptive-chat-sdui-design.md`](2026-07-18-adaptive-chat-sdui-design.md)

## Goal

Let the assistant reply with a **rich Adaptive Card** — inputs such as a date
picker, drop list, or radio/checkbox choice set — instead of only markdown text.
Solve it **generally** (any card body), not just for a date picker.

The **server** decides text-vs-card; the **client is unchanged**. This is
**display-only**: the card renders inside a normal assistant bubble, with **no
post-back** (picking a date does not submit anything yet). Interactive
round-trip is explicitly out of scope and left to future work, consistent with
the SDUI design's "in-card form submits — designed for but not built" note.

## Non-goals (YAGNI guardrails)

- **No round-trip / submit.** Returned inputs render but do not post back.
- **No actions.** The card prompt covers **inputs only**; action buttons
  (`Action.Submit` / `Action.Execute` / `Action.OpenUrl` / `Action.ShowCard` /
  `Action.ToggleVisibility`) are deferred to the future interactive work.
- **No client code change.** The client already renders whatever the server
  sends; inputs render without host handlers.
- **No wire-contract change.** The envelope's `messages[]` stay pre-styled
  Adaptive Cards.
- **Echo mode stays text-only.** `EchoResponder` never emits a card.

## Design decisions (from brainstorming)

1. **Scope:** display-only. If the reply is a card, show it; otherwise behave
   exactly as today.
2. **Detection site:** the **server** detects text-vs-card (preserves the "dumb
   client / server authoritative" SDUI thesis). The client is unchanged.
3. **Presentation:** the LLM's card is embedded **inside the assistant bubble**
   — same left-aligned, rounded, `emphasis`-styled container chrome as a text
   reply — so a date picker reads as living inside a chat bubble.
4. **Prompt:** a **separate** bundled system prompt (`card_system_prompt.txt`),
   selected via the existing `--system-prompt-file` machinery, tells the model
   to reply with an Adaptive Card **fragment**. General component palette,
   **inputs only**.

## Server design (`adaptive_chat_server`)

### 1. `Responder` contract — return a value type

`Responder.reply()` currently returns a `str`. Change it to return a small
immutable value type so history and rendering can diverge cleanly:

```python
@dataclass(frozen=True)
class Reply:
    text: str               # raw model output — ALWAYS used for Ollama history
    card_body: list | None  # parsed Adaptive Card body items, or None for plain text
```

- `EchoResponder` → `Reply(text=f"Did you just say: {text}", card_body=None)`
  (never emits a card).
- `OllamaResponder` → parses its own raw output (see detection) and sets
  `card_body` only when the **entire** reply is an Adaptive Card.

Keeping `text` as the raw model string means **conversation history is
unchanged** — the model always sees exactly what it said, card or not. The store
needs no change (`Interaction.reply_text` = `reply.text`).

### 2. Card detection

A small, testable helper — `try_parse_card_body(raw: str) -> list | None`:

1. Strip surrounding whitespace and a ` ```json … ``` ` (or bare ` ``` `)
   fence if present.
2. `json.loads`; on `ValueError` → `None` (it's text).
3. Accept **either**:
   - a dict with `type == "AdaptiveCard"` **and** a list `body` → return `body`; **or**
   - a bare JSON **array** `[…]` → return it directly (a body fragment).
4. Anything else (prose around the JSON, a bare object that isn't an
   AdaptiveCard, a JSON string/number) → `None`.

Strict "**only** a JSON card counts": the whole (fence-stripped) reply must be
the card, matching the user's "recognize if _only_ a json adaptive card was
returned" framing.

Because we ultimately embed only the **body items**, any top-level `actions`
array the model emits on a full-card form is **dropped automatically** — a
display-only card cannot render a dead action button from card-level `actions`.

### 3. Bubble authoring (`cards.py`)

Refactor the private `_bubble` so it takes an `items` list instead of a single
text string. Keep the existing text path via a thin wrapper, and add a card path:

```python
def _bubble(items: list, *, style: str, align_right: bool) -> dict: ...

def _text_bubble_items(text: str) -> list:
    return [{"type": "TextBlock", "text": text, "wrap": True}]

def user_bubble(text: str) -> dict:          # accent, right — unchanged behavior
    return _bubble(_text_bubble_items(text), style="accent", align_right=True)

def assistant_bubble(text: str) -> dict:     # emphasis, left — unchanged behavior
    return _bubble(_text_bubble_items(text), style="emphasis", align_right=False)

def assistant_card_bubble(body_items: list) -> dict:
    """Left-aligned emphasis bubble whose container holds the model's card fragment."""
    return _bubble(body_items, style="emphasis", align_right=False)
```

The container chrome (`style`, `roundedCorners: true`, the `ColumnSet` spacer for
alignment) is identical to text bubbles — only the container's `items` differ.

### 4. Route selection (`main.py`)

In `send_interaction`, `responder.reply(...)` now returns a `Reply`:

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
# history / store use reply.text as before:
store.add_interaction(cid, Interaction(..., reply_text=reply.text))
```

### 5. System prompts

- Keep `default_system_prompt.txt` (text/markdown replies) unchanged.
- Add bundled **`card_system_prompt.txt`** (card mode), resolved relative to the
  package like the default, re-read per request. It instructs the model to:
  - reply with **only** an Adaptive Card **fragment** — either a full
    `{"type":"AdaptiveCard","version":"1.5","body":[…]}` or a bare `body` array
    `[…]` — with **no surrounding prose** and no code fence required;
  - use the fragment to collect or present structured content, **inputs only**:
    - `Input.Date` (date picker),
    - `Input.ChoiceSet` — `style:"compact"` (drop list), `style:"expanded"`
      (radio), `isMultiSelect:true` (checkboxes),
    - `Input.Text`, `Input.Number`, `Input.Time`,
    - `TextBlock` for labels/prose within the fragment;
  - **not** include any `Action.*` or `actions`/`ActionSet` (display-only; a
    submit path does not exist yet);
  - fall back to a normal markdown text reply when a structured input adds no
    value.
- Selected at run time via the existing flag, e.g.
  `--system-prompt-file app/card_system_prompt.txt` (bridged through
  `OLLAMA_SYSTEM_PROMPT_FILE`, surviving `--reload`).

## Client design (`adaptive_chat_client`)

**No code change.** Log cards are already rendered verbatim via
`AdaptiveCardsCanvas.map`, and Adaptive Card **inputs render without**
`InheritedAdaptiveCardHandlers` (handlers are only required for
submit/execute/open-url). The existing tests keep passing.

## Testing

### Server (`adaptive_chat_server/tests`)

- **Detection helper** `try_parse_card_body`:
  - fenced full card → body list,
  - unfenced full card → body list,
  - bare JSON array fragment → same list,
  - invalid JSON → `None`,
  - prose wrapped around JSON → `None`,
  - non-card JSON (`{"type":"TextBlock",…}`, a JSON string/number) → `None`.
- **`assistant_card_bubble`** structure: left-aligned `ColumnSet` + spacer, an
  `emphasis` `roundedCorners` `Container`, whose `items` are exactly the passed
  body fragment.
- **Route test**: a stub responder returning `Reply(text=…, card_body=[…])`
  yields an envelope whose assistant `messages[1]` is a bubble whose container
  `items` equal the fragment, **and** the stored `reply_text` / rebuilt history
  still use `reply.text`.
- **Echo** path unchanged: `Reply.card_body is None` → text bubble.

### Client (`adaptive_chat_client/test`) — optional

- A widget test that a server card message containing `Input.Date` and
  `Input.ChoiceSet` renders the corresponding fields (no handler wiring needed).

## Docs

- **`adaptive_chat_server/README.md`**: document the text-or-card reply path,
  the `Reply` contract, `try_parse_card_body` detection, `assistant_card_bubble`,
  and how to select `card_system_prompt.txt`.
- **`adaptive_chat_client/README.md`**: note that assistant bubbles may now contain
  rich inputs and that this is **display-only** (ties to the existing "in-card
  form submits — not built" note).
- This spec is the canonical design record.

> Note: `adaptive_chat_client` / `adaptive_chat_server` are **sample apps**, not
> published packages under `packages/`, so the package `CHANGELOG.md` /
> coverage-floor gates do not apply here.
