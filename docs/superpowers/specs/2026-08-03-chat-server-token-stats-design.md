# Adaptive Chat Server — token stats and `/status` endpoint

**Date:** 2026-08-03
**Component:** `adaptive_chat_server/` (demo backend; not a published package)

## Problem

The server keeps full per-conversation history in memory but discards every
signal about what that history *costs*. Ollama returns token counts and timing
breakdowns on every `/api/chat` response; `OllamaResponder._log_context_fill`
reads exactly one field (`prompt_eval_count`), logs a tier, and throws the rest
away. There is no way to ask the running server how many conversations it is
holding, how large they have grown, or how it is configured — the only evidence
is log lines you had to be watching when they scrolled past.

Two consequences:

- **Token cost is invisible.** Nothing records tokens sent or generated, so
  "why did that turn take 8 seconds" and "how close is this conversation to
  `num_ctx`" are unanswerable after the fact.
- **Effective configuration is invisible.** `OllamaResponder.__init__` silently
  downgrades `json_format` from `"schema"` to `"none"` when the bundled schema
  is unusable. The process then behaves differently than it was told to, and the
  only trace is a startup log line.

## Goals

- Capture Ollama's token counts and duration breakdown per interaction.
- Store them alongside the interaction they belong to.
- Expose a `GET /status` endpoint reporting effective server configuration, all
  live conversations, their interaction counts, cumulative token totals, and the
  last interaction's stats.

## Non-goals

- **No wire-contract change.** The envelope returned by
  `POST/GET …/interactions` is untouched; `adaptive_chat_client` needs no edits.
  Stats are for the operator, not the chat UI.
- **No persistence.** Stats live in the same process-lifetime in-memory store as
  everything else and are lost on restart.
- **No authentication, eviction, or retention policy.** Out of scope; the store's
  existing unbounded-growth behavior is unchanged.
- **No new measurement.** Every number comes from a field Ollama already returns.

## Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Consumer | Operator only, via `/status` | Smallest blast radius; the documented wire contract and the Flutter client stay untouched. |
| Granularity | Per interaction, plus derived conversation totals | ~6 ints per turn. "Last interaction" becomes `order[-1]`; totals and per-turn history stay recoverable. A single overwritten slot on `Conversation` would discard both. |
| Fields | Tokens **and** durations | Ollama returns both in the same response, so durations are free. Token counts alone cannot distinguish model-load latency from generation latency. |
| Status rows | Counts and stats, **no message text** | CORS is `allow_origins=["*"]` and the endpoint is unauthenticated. Keeping conversation content out means the endpoint cannot leak what anyone said. |
| Config source | `Responder.describe()` | The responder is the only component that knows its *effective* config, including the schema→none downgrade. Re-reading env vars in `main.py` would duplicate defaults and miss the downgrade. |
| Transport | Optional `stats` field on `Reply` | Follows the existing frozen-dataclass style. Every failure path already returns early with a bare `Reply`, so "no stats" falls out with no extra branching. |

### Rejected alternatives

- **Metrics registry inside the responder.** The responder has no notion of a
  conversation id, so bookkeeping would require threading the cid down into it
  purely for accounting — coupling in the wrong direction.
- **ASGI timing middleware.** Captures request wall-clock but not token counts,
  which exist only inside the Ollama response body. Would still need the `Reply`
  change, and would double-count what `total_duration` already reports.

## Design

### Module layout

Two new modules keep `main.py` a thin route layer and give the new logic its own
test files.

| File | Change |
| --- | --- |
| `app/stats.py` *(new)* | `InteractionStats`, `from_ollama_response()`, `to_dict()` |
| `app/status.py` *(new)* | `build_status(store, responder) -> dict` |
| `app/store.py` | `Interaction.stats` field; `list_conversations()` |
| `app/responder.py` | `Reply.stats` field; `describe()` on the `Responder` Protocol; `EchoResponder.describe()` |
| `app/ollama_responder.py` | Populate stats on the success path; `describe()` |
| `app/main.py` | Persist `reply.stats`; `GET /status` route |

Import direction stays acyclic: `store → stats`, and `status → store, stats`.
Aggregation lives in `status.py` rather than `stats.py` precisely because
`stats.py` cannot import `store.py` — `store.py` needs `InteractionStats` for its
own field type.

### `app/stats.py`

```python
@dataclass(frozen=True)
class InteractionStats:
    prompt_tokens: int      # Ollama prompt_eval_count — tokens sent
    reply_tokens: int       # Ollama eval_count — tokens generated
    total_ms: int           # total_duration
    load_ms: int            # load_duration — model load, ~0 when warm
    prompt_eval_ms: int     # prompt_eval_duration — time reading the prompt
    eval_ms: int            # eval_duration — time generating
```

`from_ollama_response(data: dict) -> InteractionStats | None`

- Returns `None` unless **both** token counts are present and are `int`,
  mirroring the defensive style of `_log_context_fill`. A body shape it does not
  recognize yields `None` rather than a half-filled record.
- Missing or non-`int` *duration* fields default to `0` — a duration is
  supplementary, and its absence should not discard usable token counts.
- Ollama reports durations in **nanoseconds**. Conversion to milliseconds happens
  once, here, so no downstream code has to remember the unit.
- Never raises.

`to_dict(stats) -> dict` emits the stored fields plus two **derived** values:

- `totalTokens` = `prompt_tokens + reply_tokens`
- `tokensPerSecond` = `reply_tokens / (eval_ms / 1000)`, rounded to one decimal;
  `0.0` when `eval_ms` is `0` (guards division by zero on a cached or trivial
  reply).

Derived values are computed at serialization, not stored, so the record stays a
faithful copy of what Ollama reported.

`_log_context_fill` keeps its own independent read of `prompt_eval_count`. It
answers a different question — warn when the prompt nears `num_ctx` — and folding
it into the stats path would couple a log tier to a data record for no gain.

### `Responder.describe()`

Added to the `Responder` Protocol.

- `EchoResponder.describe()` → `{"kind": "echo"}`
- `OllamaResponder.describe()` → `kind`, `url`, `model`, `numCtx`,
  `historyTurns`, effective `jsonFormat`, and `systemPromptFile`
  - `systemPromptFile` is the **basename only** (`Path(...).name`), never a full
    path.
  - `jsonFormatRequested` appears **only when a downgrade occurred** — i.e. the
    constructor was asked for `"schema"` and fell back to `"none"`. Its presence
    is the signal; its absence means the process is running what it was told to.

Tests swap the responder via `monkeypatch.setattr("app.main.responder", …)`, so
`build_status` reads `describe` defensively and falls back to
`{"kind": "unknown"}`. A bare test stub must not be able to return a 500.

### `GET /status`

```json
{
  "responder": {
    "kind": "ollama",
    "url": "http://127.0.0.1:11434",
    "model": "qwen2.5-coder:7b",
    "numCtx": 16384,
    "historyTurns": 10,
    "jsonFormat": "none",
    "systemPromptFile": "default_system_prompt.txt"
  },
  "conversationCount": 2,
  "conversations": [
    {
      "conversationId": "c_ab12cd34ef56",
      "interactionCount": 3,
      "totals": { "promptTokens": 4200, "replyTokens": 900, "totalTokens": 5100 },
      "lastInteraction": {
        "interactionId": "i_0003",
        "stats": {
          "promptTokens": 1500,
          "replyTokens": 300,
          "totalTokens": 1800,
          "totalMs": 8200,
          "loadMs": 12,
          "promptEvalMs": 900,
          "evalMs": 7200,
          "tokensPerSecond": 41.7
        }
      }
    }
  ]
}
```

Semantics:

- `stats` is `null` in echo mode and on **any** Ollama failure (transport, HTTP
  status, unparseable body). The interaction still counts — it happened, it just
  produced no tokens.
- `totals` sums only interactions that carry stats. A conversation whose
  interactions all failed reports zeros, not `null`.
- `lastInteraction` is `null` for a conversation with zero interactions.
- `interactionCount` counts **distinct** interactions. An idempotent replay of an
  existing `X-Interaction-Id` returns before `add_interaction`, so it does not
  inflate the count.
- Conversations appear in creation order (`dict` preserves insertion order).
- No message text appears anywhere in the payload.

## Error handling

Every new code path is non-raising, consistent with the module's existing
posture that a misbehaving Ollama must never break a request:

| Condition | Behavior |
| --- | --- |
| Ollama body missing token counts | `from_ollama_response` returns `None`; interaction stored with `stats=None` |
| Ollama body has non-`int` counts | Same as above |
| Ollama duration fields missing | Default to `0`; token counts still captured |
| `eval_ms == 0` | `tokensPerSecond` is `0.0`, no `ZeroDivisionError` |
| Responder lacks `describe()` | `responder` block reports `{"kind": "unknown"}` |
| Echo responder | `stats` is `null` throughout; `responder.kind` is `"echo"` |
| Empty store | `conversationCount: 0`, `conversations: []` |

## Testing

All tests run offline against `httpx.MockTransport` and FastAPI's `TestClient`.
No live Ollama is contacted.

**`tests/test_stats.py`** *(new)*

- Full Ollama body → all fields populated; nanosecond→millisecond conversion
- Missing / non-`int` token counts → `None`
- Missing duration fields → `0`, token counts preserved
- `to_dict` derives `totalTokens` and `tokensPerSecond`
- `eval_ms == 0` → `tokensPerSecond == 0.0`

**`tests/test_status.py`** *(new)*

- Empty store → `conversationCount: 0`, `conversations: []`
- Echo responder → `stats: null`, `kind: "echo"`
- Multi-conversation totals skip null-stat interactions
- Conversation with zero interactions → `lastInteraction: null`
- Stub responder without `describe()` → `{"kind": "unknown"}`, no raise

**`tests/test_ollama_responder.py`** *(extend)*

- MockTransport body with counts → `Reply.stats` populated
- Each of the three failure paths (transport, HTTP ≥ 400, unparseable) →
  `stats is None`
- `describe()` reports effective config; after a schema downgrade it reports
  `jsonFormat: "none"` **and** `jsonFormatRequested: "schema"`
- `describe()["systemPromptFile"]` is a bare filename, not a path

**`tests/test_api.py`** *(extend)*

- `GET /status` after two conversations returns both, with correct
  `interactionCount` values
- An idempotent replay does not increment `interactionCount`

**`tests/test_store.py`** *(extend)*

- An `Interaction` round-trips its `stats` through `add_interaction` /
  `get_interaction`

## Documentation

- `adaptive_chat_server/README.md`:
  - Add a `GET /status` row to the **Wire contract** table
  - New section documenting the payload and the null-stats cases
  - Add `GET /status` to the `ROUTES` node in **both** mermaid diagrams
  - Note `app/stats.py` and `app/status.py` in **Components (`app/`)**

No `CHANGELOG.md` entry: `adaptive_chat_server/` is a top-level demo server, not
a published package under `packages/`, so the AGENTS.md changelog gate does not
apply.

## Security note

`/status` is unauthenticated and CORS is `allow_origins=["*"]`. The payload
deliberately carries no message text, and `systemPromptFile` is reduced to a
basename so no filesystem layout is disclosed. The `url` and `model` fields do
describe the local Ollama deployment. This is acceptable for a demo server bound
to `127.0.0.1` (the default); binding to `0.0.0.0` would expose configuration
metadata and conversation-volume data to the network.
