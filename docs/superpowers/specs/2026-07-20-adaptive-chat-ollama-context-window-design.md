# Design: Adaptive Chat Server — Ollama context-window observability + history turn-window

- **Status:** Approved for planning
- **Date:** 2026-07-20
- **Component:** `adaptive_chat_server` (Python / FastAPI) — `OllamaResponder`
- **Branch:** `feat/ollama-system-prompt`

## Summary

`adaptive_chat_server` replays the **entire** conversation history to Ollama on
every turn and is blind to the model's context window. Ollama does **not** reject
an oversize prompt — it silently drops the oldest tokens and answers anyway — so a
long conversation quietly "forgets" its start with nothing in the logs to show it.

This change adds two complementary, configurable behaviors to `OllamaResponder`:

1. **History turn-window (send-only trim).** Bound the history sent to Ollama to
   the last *N* interactions. **Server-stored history is untouched** — only the
   outbound `/api/chat` prompt is trimmed.
2. **Context-window observability.** Set `num_ctx` explicitly so the window is a
   known, enforced value, then log actual prompt-token fill (`prompt_eval_count`)
   in tiers after each response.

Both are opt-in via CLI + env, mirroring the existing `--ollama-model` /
`--system-prompt-file` plumbing. `main.py`'s history-building and `EchoResponder`
are unchanged.

## Goals

- Bound the prompt sent to Ollama so unbounded history growth can't silently
  overflow the model's context window.
- Make context fill **observable**: known window (`num_ctx`) + tiered logging of
  actual prompt tokens, so silent truncation becomes a visible signal.
- Keep the full conversation **retained** server-side (durable log + idempotent
  replay); trim only what is sent to the model.
- Follow the existing knob pattern (CLI arg → env var → responder) so both
  settings survive uvicorn `--reload` and are tunable without code edits.
- Never crash a request: all new failure modes degrade to a logged warning.

## Non-goals

- **Token-budget trimming or summarization.** We trim by *turn count*, not tokens.
  A token budget or rolling summary is a possible future step but out of scope.
- **Bounding the server-side store.** The store stays unbounded for the process
  lifetime (already "lost on restart"); no cap on retained history.
- **Blocking / rejecting oversize prompts.** We observe and warn; we do not fail
  the request when the prompt is large. (Ollama itself silently truncates.)
- **Changes to `EchoResponder`, `main.py` history-building, or the client.**

## Resolved decisions

- **Trim location:** inside `OllamaResponder.reply()` (Decision 1). `main.py` keeps
  passing full history; the responder decides what to send. Keeps all Ollama
  context concerns in one testable unit.
- **Retain vs. prune:** **retain all** server history; trim is a read-time,
  send-only slice on a local list. The store and the caller's list are untouched.
- **Config surface:** both CLI + env (Decision 2):
  - `--num-ctx` / `OLLAMA_NUM_CTX`, default **4096**.
  - `--history-turns` / `OLLAMA_HISTORY_TURNS`, default **10** (last 10 exchanges).
- **Observability tiers** (Decision 3), computed from `prompt_eval_count / num_ctx`
  after a successful response:
  - **≥ 76% → `WARNING`** — context near limit; Ollama silently drops oldest
    tokens above `num_ctx`. Message suggests lowering `--history-turns` or raising
    `--num-ctx`. (~24% headroom leaves room for the generated reply.)
  - **≥ 50% and < 76% → `INFO`** — context filling; `prompt=X/num_ctx`.
  - **< 50% → no extra line** (the existing "N messages" request log still fires).
  - No pre-flight token estimate — the post-response count is the source of truth.

## Behavior & data flow

`history` reaching `reply()` is a flat list `[(role, content), …]` with **two
entries per interaction** (a `("user", text)` then `("assistant", reply_text)`),
built by `main.py` from the full `conversation.order`.

`OllamaResponder.reply(text, history)` now:

1. **Trim (send-only):** keep the last *N* interactions —
   `history = history[-2 * history_turns:]`. This rebinds a **local** variable to a
   slice; the caller's list and the store are never mutated. If
   `history_turns <= 0`, send **no** prior history (guarded — `history[-0:]` would
   otherwise keep everything).
2. **Build messages:** `[system?] + trimmed_history + [current turn]` (system
   prepend + current-turn append are unchanged; trimming touches only prior
   history).
3. **Set the window:** `payload["options"] = {"num_ctx": self._num_ctx}` so the
   window is known and enforced rather than a model default.
4. **Log fill:** after a 2xx parse, read `prompt_eval_count` from the response and
   emit the tiered INFO/WARN log against `num_ctx`.

The trim (turn count) and the fill log (tokens) are **independent**: even after
trimming to *N* turns, a few very long turns can still exceed `num_ctx`; the tier
log is what surfaces that residual case.

## Config plumbing (mirrors existing knobs)

- **`__main__.py`:** add `--num-ctx` (int, default 4096) → `OLLAMA_NUM_CTX`, and
  `--history-turns` (int, default 10) → `OLLAMA_HISTORY_TURNS`.
- **`main.py`:** `build_responder(...)` reads both env vars with int parsing and a
  fallback to defaults, and passes them to `OllamaResponder`. Extend the startup
  `OllamaResponder` INFO line to include `num_ctx` and `history_turns`.
- **`ollama_responder.py`:** add module constants `DEFAULT_NUM_CTX = 4096` and
  `DEFAULT_HISTORY_TURNS = 10`; constructor gains `num_ctx: int` and
  `history_turns: int` params (after the existing ones).

## Error handling / edge cases

- **`history_turns <= 0`** → send no prior history (explicit guard, not a slice
  quirk).
- **Missing `prompt_eval_count`** (older Ollama or absent field) → skip the fill
  log; never raise. The reply still returns normally.
- **Non-int env value** (e.g. `OLLAMA_NUM_CTX=abc`) → log a warning and fall back
  to the default. Consistent with "never crash a request."
- **All existing Ollama failure paths** (connection, HTTP ≥ 400, unparseable body)
  are unchanged; the fill log runs only on the success path.

## Documentation

Update `adaptive_chat_server/README.md`:

- **Conversation context** subsection: replace the "No truncation" paragraph with
  the new bounded behavior — the store retains the **full** conversation and the
  turn-window bounds only what is **sent** to the model. State the `num_ctx` fill
  logging and the 50% / 76% tiers.
- **Ollama** section: document `--num-ctx` and `--history-turns` (with defaults)
  and a one-line note that Ollama silently truncates above `num_ctx`, which the
  fill log surfaces.

No `packages/` changelog gate applies — this is the sample server, not a
published package.

## Testing (`tests/test_ollama_responder.py`, mocked HTTP)

All via `httpx.MockTransport`, asserting on the captured request body and (for
logging) `caplog`:

- **Trim:** with `history_turns=2` and 5 interactions of history, the request body
  `messages` keeps only the last 2 exchanges plus the current turn (and system if
  present); oldest are dropped.
- **`history_turns=0`** → request body has no prior history (only current turn,
  plus system if present).
- **`num_ctx` in payload:** `options.num_ctx` equals the configured value.
- **Tiered logging** (drive `prompt_eval_count` from the mock response):
  - ~40% of `num_ctx` → no INFO/WARN fill line.
  - ~60% → `INFO` fill line.
  - ~80% → `WARNING` fill line.
- **Missing `prompt_eval_count`** → no crash, no fill line, reply returned.
- **Bad env int** → `build_responder` falls back to the default (may live in a
  `main.py`/`build_responder`-level test).
- **Non-mutation:** the caller's `history` list is unchanged after `reply()`
  (guards against accidental in-place trimming).

## Verification

From `adaptive_chat_server/`:

```bash
.venv/bin/python -m pytest -v
```

All tests green (existing 28 + the new cases). No Dart/Flutter changes, so the
monorepo `fvm` suites are unaffected.
