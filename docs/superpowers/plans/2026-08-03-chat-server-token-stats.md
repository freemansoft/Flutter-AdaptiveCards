# Chat Server Token Stats + `/status` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capture Ollama's per-turn token counts and timing on each stored interaction, and expose a `GET /status` endpoint reporting effective server configuration plus per-conversation volume.

**Architecture:** `OllamaResponder` builds an `InteractionStats` record from the same `/api/chat` response body it already parses, returns it on `Reply`, and the send route persists it on the `Interaction`. A new `app/status.py` aggregates the store into a payload; a new `app/stats.py` owns the record type and its serialization. Import direction stays acyclic: `store → stats`, `status → store, stats`.

**Tech Stack:** Python 3, FastAPI 0.115.6, httpx 0.28.1, pytest 8.3.4. Plain dataclasses, no ORM, no code-gen.

**Spec:** [`docs/superpowers/specs/2026-08-03-chat-server-token-stats-design.md`](../specs/2026-08-03-chat-server-token-stats-design.md)

## Global Constraints

- **Working directory is `adaptive_chat_server/`** for every command in this plan. It is a top-level Python demo server, *not* a Flutter package — `fvm`, `flutter`, and `dart` are not involved.
- **Test command:** `.venv/bin/python -m pytest -v`. Create the venv first if absent: `python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`.
- **No `CHANGELOG.md` entry.** `adaptive_chat_server/` is not under `packages/`, so the AGENTS.md changelog gate does not apply.
- **No wire-contract change** to the interaction envelope. `POST/GET …/interactions` responses must be byte-identical to today. `adaptive_chat_client` is not modified.
- **Every new code path is non-raising.** A malformed Ollama body, a missing duration field, a zero divisor, or a responder stub lacking `describe()` must degrade to a default — never a 500 and never an exception into a request.
- **No message text in the `/status` payload.** The endpoint is unauthenticated and CORS is `allow_origins=["*"]`.
- **Commit gate (overrides the template's commit steps):** AGENTS.md forbids committing or pushing without explicit user confirmation at the moment of action. Each "Commit" step below means: show the diff, summarize it, **wait for the user to approve**, then run the command.
- **Branch first:** before Task 1, create a feature branch off `main` (`git checkout -b feat/chat-server-token-stats`). Do not work directly on `main`.
- Style follows the existing modules: `from __future__ import annotations`, frozen dataclasses for value types, `"""Docstrings"""` explaining *why* and the caller contract, module logger `logging.getLogger("uvicorn.error")`.

---

### Task 1: `app/stats.py` — the stats record

**Files:**
- Create: `adaptive_chat_server/app/stats.py`
- Test: `adaptive_chat_server/tests/test_stats.py`

**Interfaces:**
- Consumes: nothing (leaf module — imports only `dataclasses`).
- Produces:
  - `InteractionStats` frozen dataclass with `int` fields `prompt_tokens`, `reply_tokens`, `total_ms`, `load_ms`, `prompt_eval_ms`, `eval_ms`
  - `from_ollama_response(data: dict) -> InteractionStats | None`
  - `to_dict(stats: InteractionStats) -> dict`

- [x] **Step 1: Write the failing tests**

Create `tests/test_stats.py`:

```python
from app.stats import InteractionStats, from_ollama_response, to_dict

# A complete Ollama /api/chat body. Durations are nanoseconds — Ollama's unit.
_FULL = {
    "prompt_eval_count": 1500,
    "eval_count": 300,
    "total_duration": 8_200_000_000,
    "load_duration": 12_000_000,
    "prompt_eval_duration": 900_000_000,
    "eval_duration": 7_200_000_000,
}


def test_from_ollama_response_converts_nanoseconds_to_ms():
    assert from_ollama_response(_FULL) == InteractionStats(
        prompt_tokens=1500,
        reply_tokens=300,
        total_ms=8200,
        load_ms=12,
        prompt_eval_ms=900,
        eval_ms=7200,
    )


def test_from_ollama_response_without_token_counts_returns_none():
    assert from_ollama_response({}) is None
    assert from_ollama_response({"prompt_eval_count": 10}) is None
    assert from_ollama_response({"eval_count": 10}) is None


def test_from_ollama_response_with_non_int_counts_returns_none():
    assert from_ollama_response({"prompt_eval_count": "10", "eval_count": 5}) is None
    assert from_ollama_response({"prompt_eval_count": 10, "eval_count": None}) is None


def test_from_ollama_response_defaults_missing_durations_to_zero():
    stats = from_ollama_response({"prompt_eval_count": 10, "eval_count": 5})
    assert stats is not None
    assert stats.prompt_tokens == 10
    assert stats.reply_tokens == 5
    assert (stats.total_ms, stats.load_ms, stats.prompt_eval_ms, stats.eval_ms) == (0, 0, 0, 0)


def test_from_ollama_response_ignores_non_int_durations():
    stats = from_ollama_response(
        {"prompt_eval_count": 10, "eval_count": 5, "total_duration": "slow"}
    )
    assert stats is not None
    assert stats.total_ms == 0


def test_to_dict_derives_total_tokens_and_speed():
    body = to_dict(from_ollama_response(_FULL))
    assert body["totalTokens"] == 1800
    assert body["tokensPerSecond"] == 41.7
    assert body["promptTokens"] == 1500
    assert body["replyTokens"] == 300
    assert body["evalMs"] == 7200


def test_to_dict_guards_zero_eval_ms():
    stats = InteractionStats(
        prompt_tokens=1,
        reply_tokens=5,
        total_ms=0,
        load_ms=0,
        prompt_eval_ms=0,
        eval_ms=0,
    )
    assert to_dict(stats)["tokensPerSecond"] == 0.0
```

- [x] **Step 2: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest tests/test_stats.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.stats'`

- [x] **Step 3: Write the implementation**

Create `app/stats.py`:

```python
"""Per-interaction Ollama usage: token counts plus where the time went.

Ollama returns these numbers on every ``/api/chat`` response and the server
previously discarded all but one of them. Capturing them makes "what did that
turn cost" and "how large has this conversation grown" answerable after the
fact, via ``GET /status``.
"""
from __future__ import annotations

from dataclasses import dataclass

# Ollama reports every duration in nanoseconds. Convert once, here, so no
# downstream caller has to remember the unit.
_NS_PER_MS = 1_000_000


@dataclass(frozen=True)
class InteractionStats:
    """What one Ollama turn cost: tokens in and out, plus the timing breakdown.

    Stores only what Ollama reported. Derived figures (total tokens, generation
    speed) are computed in :func:`to_dict` so this record stays a faithful copy.
    """

    prompt_tokens: int  # Ollama prompt_eval_count — tokens sent
    reply_tokens: int  # Ollama eval_count — tokens generated
    total_ms: int  # total_duration
    load_ms: int  # load_duration — model load, ~0 when already warm
    prompt_eval_ms: int  # prompt_eval_duration — time reading the prompt
    eval_ms: int  # eval_duration — time generating


def _ms(data: dict, key: str) -> int:
    """Nanosecond field as whole milliseconds; 0 when absent or not an int."""
    value = data.get(key)
    if not isinstance(value, int):
        return 0
    return value // _NS_PER_MS


def from_ollama_response(data: dict) -> InteractionStats | None:
    """Build stats from an Ollama ``/api/chat`` body, or ``None`` if unusable.

    Both token counts are required: a record without them answers no question
    worth asking, so a body missing them yields ``None`` rather than a
    half-filled record. Durations are supplementary — a missing or malformed one
    defaults to 0 instead of discarding usable token counts. Never raises, so a
    misbehaving Ollama cannot break a request.
    """
    prompt_tokens = data.get("prompt_eval_count")
    reply_tokens = data.get("eval_count")
    if not isinstance(prompt_tokens, int) or not isinstance(reply_tokens, int):
        return None
    return InteractionStats(
        prompt_tokens=prompt_tokens,
        reply_tokens=reply_tokens,
        total_ms=_ms(data, "total_duration"),
        load_ms=_ms(data, "load_duration"),
        prompt_eval_ms=_ms(data, "prompt_eval_duration"),
        eval_ms=_ms(data, "eval_duration"),
    )


def to_dict(stats: InteractionStats) -> dict:
    """Serialize for the ``/status`` payload, deriving totals and speed.

    ``tokensPerSecond`` is generation speed (reply tokens over generation time),
    not end-to-end throughput — it excludes model load and prompt evaluation, so
    it stays comparable across warm and cold turns. Zero when ``eval_ms`` is 0.
    """
    tokens_per_second = 0.0
    if stats.eval_ms > 0:
        tokens_per_second = round(stats.reply_tokens / (stats.eval_ms / 1000), 1)
    return {
        "promptTokens": stats.prompt_tokens,
        "replyTokens": stats.reply_tokens,
        "totalTokens": stats.prompt_tokens + stats.reply_tokens,
        "totalMs": stats.total_ms,
        "loadMs": stats.load_ms,
        "promptEvalMs": stats.prompt_eval_ms,
        "evalMs": stats.eval_ms,
        "tokensPerSecond": tokens_per_second,
    }
```

- [x] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/python -m pytest tests/test_stats.py -v`
Expected: PASS — 7 passed

- [x] **Step 5: Commit** *(show diff, wait for user approval, then run)*

```bash
git add app/stats.py tests/test_stats.py
git commit -m "feat(chat-server): add InteractionStats record for Ollama token usage"
```

---

### Task 2: Store the stats on an interaction

**Files:**
- Modify: `adaptive_chat_server/app/store.py:16-23` (`Interaction`), `:35-63` (`ConversationStore`)
- Test: `adaptive_chat_server/tests/test_store.py`

**Interfaces:**
- Consumes: `InteractionStats` from Task 1.
- Produces:
  - `Interaction.stats: InteractionStats | None = None` (defaults to `None`, so all existing construction sites keep working unchanged)
  - `ConversationStore.list_conversations() -> list[Conversation]`

- [x] **Step 1: Write the failing tests**

Append to `tests/test_store.py`:

```python
def test_interaction_stats_default_to_none():
    inter = Interaction(interaction_id="i_0001", text="hi", messages=[])
    assert inter.stats is None


def test_interaction_round_trips_stats():
    store = ConversationStore()
    conv = store.create()
    stats = InteractionStats(
        prompt_tokens=10,
        reply_tokens=5,
        total_ms=100,
        load_ms=1,
        prompt_eval_ms=20,
        eval_ms=70,
    )
    store.add_interaction(
        conv.conversation_id,
        Interaction(interaction_id="i_0001", text="hi", messages=[], stats=stats),
    )
    stored = store.get_interaction(conv.conversation_id, "i_0001")
    assert stored.stats is stats


def test_list_conversations_returns_creation_order():
    store = ConversationStore()
    first = store.create()
    second = store.create()
    assert [c.conversation_id for c in store.list_conversations()] == [
        first.conversation_id,
        second.conversation_id,
    ]


def test_list_conversations_empty_store():
    assert ConversationStore().list_conversations() == []
```

Extend the existing import at the top of the file from:

```python
from app.store import ConversationStore, Interaction, Message
```

to:

```python
from app.stats import InteractionStats
from app.store import ConversationStore, Interaction, Message
```

- [x] **Step 2: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest tests/test_store.py -v`
Expected: FAIL — `TypeError: Interaction.__init__() got an unexpected keyword argument 'stats'` and `AttributeError: 'ConversationStore' object has no attribute 'list_conversations'`

- [x] **Step 3: Write the implementation**

In `app/store.py`, add the import below the existing `dataclasses` import:

```python
from app.stats import InteractionStats
```

Replace the `Interaction` dataclass with:

```python
@dataclass
class Interaction:
    """One send/response cycle within a conversation."""

    interaction_id: str
    text: str
    messages: list[Message]
    reply_text: str = ""
    # None whenever the reply cost no measurable tokens: echo mode, or any
    # Ollama failure. The interaction still counts — it happened.
    stats: InteractionStats | None = None
```

Add to `ConversationStore`, after `get_interaction`:

```python
    def list_conversations(self) -> list[Conversation]:
        """Every live conversation, in creation order.

        Insertion order is guaranteed by ``dict``; the status endpoint relies on
        it so conversations read oldest-first.
        """
        return list(self._conversations.values())
```

- [x] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/python -m pytest tests/test_store.py -v`
Expected: PASS — all store tests, including the 3 pre-existing ones

- [x] **Step 5: Commit** *(show diff, wait for user approval, then run)*

```bash
git add app/store.py tests/test_store.py
git commit -m "feat(chat-server): store per-interaction stats and expose conversation listing"
```

---

### Task 3: `Reply.stats` and the `describe()` contract

**Files:**
- Modify: `adaptive_chat_server/app/responder.py:8-33`
- Test: `adaptive_chat_server/tests/test_responder.py`

**Interfaces:**
- Consumes: `InteractionStats` from Task 1.
- Produces:
  - `Reply.stats: InteractionStats | None = None` (third positional field, after `card_body`)
  - `Responder.describe(self) -> dict` on the Protocol
  - `EchoResponder.describe() -> {"kind": "echo"}`

- [x] **Step 1: Write the failing tests**

Append to `tests/test_responder.py`:

```python
def test_reply_stats_default_to_none():
    assert Reply(text="hi").stats is None


def test_reply_carries_stats_when_given():
    stats = InteractionStats(
        prompt_tokens=1,
        reply_tokens=2,
        total_ms=3,
        load_ms=0,
        prompt_eval_ms=1,
        eval_ms=2,
    )
    assert Reply(text="hi", stats=stats).stats is stats


def test_echo_responder_describes_itself():
    assert EchoResponder().describe() == {"kind": "echo"}


def test_echo_responder_reply_has_no_stats():
    assert EchoResponder().reply("hi", []).stats is None
```

Ensure the file's imports include:

```python
from app.responder import EchoResponder, Reply
from app.stats import InteractionStats
```

- [x] **Step 2: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest tests/test_responder.py -v`
Expected: FAIL — `TypeError: Reply.__init__() got an unexpected keyword argument 'stats'` and `AttributeError: 'EchoResponder' object has no attribute 'describe'`

- [x] **Step 3: Write the implementation**

In `app/responder.py`, add the import:

```python
from app.stats import InteractionStats
```

Add the `stats` field to `Reply` (keep the existing docstring, append the new paragraph):

```python
@dataclass(frozen=True)
class Reply:
    text: str
    card_body: list | None = None
    stats: InteractionStats | None = None
```

Append to `Reply`'s docstring:

```
    ``stats`` carries the responder's token/timing usage for this turn, or
    ``None`` when the reply cost nothing measurable (echo mode, or any failure
    path). It never affects what the user sees — it exists for ``GET /status``.
```

Add `describe` to the Protocol and to `EchoResponder`:

```python
class Responder(Protocol):
    """Turns a user message (plus prior turns) into a :class:`Reply`."""

    def reply(self, text: str, history: list[tuple[str, str]]) -> Reply: ...

    def describe(self) -> dict:
        """Effective configuration of this responder, for ``GET /status``.

        Reports what the process is *actually* running, not what it was asked
        for — a responder may resolve or downgrade its own settings at
        construction, and it is the only component that knows the difference.
        Keys are camelCase because the result is served verbatim as JSON.
        """
        ...


class EchoResponder:
    """v1 responder: echoes the user's text back. Ignores history; never a card."""

    def reply(self, text: str, history: list[tuple[str, str]]) -> Reply:
        return Reply(text=f"Did you just say: {text}")

    def describe(self) -> dict:
        return {"kind": "echo"}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/python -m pytest tests/test_responder.py -v`
Expected: PASS

- [x] **Step 5: Commit** *(show diff, wait for user approval, then run)*

```bash
git add app/responder.py tests/test_responder.py
git commit -m "feat(chat-server): add Reply.stats and Responder.describe() contract"
```

---

### Task 4: `OllamaResponder` captures stats and reports config

**Files:**
- Modify: `adaptive_chat_server/app/ollama_responder.py:128-160` (`__init__`), `:322-340` (success path), and add `describe()`
- Test: `adaptive_chat_server/tests/test_ollama_responder.py`

**Interfaces:**
- Consumes: `from_ollama_response` (Task 1), `Reply.stats` (Task 3).
- Produces: `OllamaResponder.describe() -> dict` with keys `kind`, `url`, `model`, `numCtx`, `historyTurns`, `jsonFormat`, `systemPromptFile`, and `jsonFormatRequested` **only on downgrade**.

- [x] **Step 1: Write the failing tests**

Append to `tests/test_ollama_responder.py`:

```python
def _ok_handler(body):
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=body)

    return handler


_STATS_BODY = {
    "message": {"content": "hello"},
    "prompt_eval_count": 1500,
    "eval_count": 300,
    "total_duration": 8_200_000_000,
    "load_duration": 12_000_000,
    "prompt_eval_duration": 900_000_000,
    "eval_duration": 7_200_000_000,
}


def test_reply_captures_token_stats():
    reply = _responder(_ok_handler(_STATS_BODY)).reply("hi", [])
    assert reply.stats is not None
    assert reply.stats.prompt_tokens == 1500
    assert reply.stats.reply_tokens == 300
    assert reply.stats.eval_ms == 7200


def test_reply_without_counts_has_no_stats():
    reply = _responder(_ok_handler({"message": {"content": "hello"}})).reply("hi", [])
    assert reply.text == "hello"
    assert reply.stats is None


def test_transport_failure_has_no_stats():
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("connection refused")

    assert _responder(handler).reply("hi", []).stats is None


def test_http_error_has_no_stats():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(404, text="model not found")

    assert _responder(handler).reply("hi", []).stats is None


def test_unparseable_body_has_no_stats():
    assert _responder(_ok_handler({"nope": True})).reply("hi", []).stats is None


def test_describe_reports_effective_config():
    config = _responder(
        _ok_handler({"message": {"content": "hi"}}), num_ctx=4096, history_turns=3
    ).describe()
    assert config["kind"] == "ollama"
    assert config["url"] == OLLAMA_URL
    assert config["model"] == OLLAMA_MODEL
    assert config["numCtx"] == 4096
    assert config["historyTurns"] == 3
    assert config["jsonFormat"] == "none"
    assert config["systemPromptFile"] == "default_system_prompt.txt"
    assert "jsonFormatRequested" not in config


def test_describe_system_prompt_file_is_basename_only(tmp_path):
    prompt = tmp_path / "custom_prompt.txt"
    prompt.write_text("be brief", encoding="utf-8")
    config = _responder(
        _ok_handler({"message": {"content": "hi"}}), system_prompt_file=str(prompt)
    ).describe()
    assert config["systemPromptFile"] == "custom_prompt.txt"
    assert str(tmp_path) not in str(config)


def test_describe_flags_schema_downgrade(monkeypatch):
    monkeypatch.setattr(
        "app.ollama_responder.CARD_SCHEMA_PATH", Path("/nonexistent/schema.json")
    )
    config = _responder(
        _ok_handler({"message": {"content": "hi"}}), json_format="schema"
    ).describe()
    assert config["jsonFormat"] == "none"
    assert config["jsonFormatRequested"] == "schema"
```

Add `from pathlib import Path` to the file's imports (it currently imports `json`, `logging`, and `httpx`).

- [x] **Step 2: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest tests/test_ollama_responder.py -v`
Expected: FAIL — `AttributeError: 'Reply' object has no attribute 'stats'` is already fixed by Task 3, so the failures are `assert reply.stats is not None` (stats never populated) and `AttributeError: 'OllamaResponder' object has no attribute 'describe'`

- [x] **Step 3: Write the implementation**

In `app/ollama_responder.py`, extend the import from `app.responder`:

```python
from app.responder import Reply
from app.stats import from_ollama_response
```

In `__init__`, replace the `self._json_format = json_format` line and the schema block with:

```python
        self._json_format = json_format
        # Remembered before the downgrade below so describe() can report that the
        # process is not running the format it was asked for.
        self._requested_json_format = json_format
        self._card_schema: dict | None = None
        if self._json_format == "schema":
            self._card_schema = _load_card_schema(CARD_SCHEMA_PATH)
            if self._card_schema is None:
                self._json_format = "none"
```

Add `describe()` immediately after `__init__`:

```python
    def describe(self) -> dict:
        """Effective config for ``GET /status`` — what this process is running.

        ``jsonFormatRequested`` appears only when the constructor downgraded a
        requested ``"schema"`` to ``"none"`` because the bundled schema was
        unusable. Its presence is the signal that the process is not doing what
        it was told; its absence means requested and effective agree.
        ``systemPromptFile`` is the bare filename — the endpoint is
        unauthenticated, so no filesystem layout is disclosed.
        """
        config = {
            "kind": "ollama",
            "url": self._ollama_url,
            "model": self._model,
            "numCtx": self._num_ctx,
            "historyTurns": self._history_turns,
            "jsonFormat": self._json_format,
            "systemPromptFile": self._system_prompt_path.name,
        }
        if self._requested_json_format != self._json_format:
            config["jsonFormatRequested"] = self._requested_json_format
        return config
```

In `reply()`, immediately after the existing `self._log_context_fill(data)` line, add:

```python
        # Independent of _log_context_fill's own prompt-token read: that logs a
        # warning tier, this records data. Keeping them separate avoids coupling
        # a log threshold to the stored record.
        stats = from_ollama_response(data)
```

Change the final return of `reply()` from:

```python
        return Reply(text=reply_text, card_body=card_body)
```

to:

```python
        return Reply(text=reply_text, card_body=card_body, stats=stats)
```

Leave all three early-return failure paths untouched — they already return a bare `Reply`, so `stats` defaults to `None`.

- [x] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/python -m pytest tests/test_ollama_responder.py -v`
Expected: PASS — new tests plus all pre-existing Ollama tests

- [x] **Step 5: Commit** *(show diff, wait for user approval, then run)*

```bash
git add app/ollama_responder.py tests/test_ollama_responder.py
git commit -m "feat(chat-server): capture Ollama token stats and report effective config"
```

---

### Task 5: `app/status.py` — payload assembly

**Files:**
- Create: `adaptive_chat_server/app/status.py`
- Test: `adaptive_chat_server/tests/test_status.py`

**Interfaces:**
- Consumes: `to_dict` (Task 1), `Interaction.stats` + `ConversationStore.list_conversations` (Task 2), `describe()` (Tasks 3–4).
- Produces: `build_status(store: ConversationStore, responder: object) -> dict`

- [x] **Step 1: Write the failing tests**

Create `tests/test_status.py`:

```python
import json

from app.responder import EchoResponder
from app.stats import InteractionStats
from app.status import build_status
from app.store import ConversationStore, Interaction, Message


def _stats(prompt: int, reply: int) -> InteractionStats:
    return InteractionStats(
        prompt_tokens=prompt,
        reply_tokens=reply,
        total_ms=100,
        load_ms=1,
        prompt_eval_ms=20,
        eval_ms=70,
    )


def _add(store, cid, iid, stats=None):
    store.add_interaction(
        cid, Interaction(interaction_id=iid, text="hi", messages=[], stats=stats)
    )


def test_empty_store_reports_no_conversations():
    body = build_status(ConversationStore(), EchoResponder())
    assert body["conversationCount"] == 0
    assert body["conversations"] == []
    assert body["responder"] == {"kind": "echo"}


def test_totals_sum_only_interactions_with_stats():
    store = ConversationStore()
    cid = store.create().conversation_id
    _add(store, cid, "i_0001", _stats(100, 20))
    _add(store, cid, "i_0002", None)
    _add(store, cid, "i_0003", _stats(200, 30))
    row = build_status(store, EchoResponder())["conversations"][0]
    assert row["interactionCount"] == 3
    assert row["totals"] == {
        "promptTokens": 300,
        "replyTokens": 50,
        "totalTokens": 350,
    }


def test_last_interaction_is_the_most_recent():
    store = ConversationStore()
    cid = store.create().conversation_id
    _add(store, cid, "i_0001", _stats(100, 20))
    _add(store, cid, "i_0002", _stats(200, 30))
    last = build_status(store, EchoResponder())["conversations"][0]["lastInteraction"]
    assert last["interactionId"] == "i_0002"
    assert last["stats"]["promptTokens"] == 200
    assert last["stats"]["totalTokens"] == 230


def test_last_interaction_stats_null_when_absent():
    store = ConversationStore()
    cid = store.create().conversation_id
    _add(store, cid, "i_0001", None)
    last = build_status(store, EchoResponder())["conversations"][0]["lastInteraction"]
    assert last["interactionId"] == "i_0001"
    assert last["stats"] is None


def test_conversation_with_no_interactions_has_null_last():
    store = ConversationStore()
    store.create()
    row = build_status(store, EchoResponder())["conversations"][0]
    assert row["interactionCount"] == 0
    assert row["lastInteraction"] is None
    assert row["totals"]["totalTokens"] == 0


def test_conversations_appear_in_creation_order():
    store = ConversationStore()
    first = store.create().conversation_id
    second = store.create().conversation_id
    body = build_status(store, EchoResponder())
    assert [c["conversationId"] for c in body["conversations"]] == [first, second]
    assert body["conversationCount"] == 2


def test_responder_without_describe_reports_unknown():
    class _Stub:
        def reply(self, text, history):
            raise AssertionError("reply should not be called by build_status")

    body = build_status(ConversationStore(), _Stub())
    assert body["responder"] == {"kind": "unknown"}


def test_status_carries_no_message_text():
    store = ConversationStore()
    cid = store.create().conversation_id
    store.add_interaction(
        cid,
        Interaction(
            interaction_id="i_0001",
            text="my secret question",
            messages=[Message(role="user", card={"type": "AdaptiveCard"})],
            reply_text="my secret answer",
        ),
    )
    serialized = json.dumps(build_status(store, EchoResponder()))
    assert "my secret question" not in serialized
    assert "my secret answer" not in serialized
```

- [x] **Step 2: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest tests/test_status.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.status'`

- [x] **Step 3: Write the implementation**

Create `app/status.py`:

```python
"""Assembles the ``GET /status`` payload from the store and the live responder.

Deliberately carries no message text: the endpoint is unauthenticated and CORS
is wide open, so conversation content must not be reachable through it. What it
does report is volume (how many conversations, how many turns, how many tokens)
and the effective configuration the process is actually running.
"""
from __future__ import annotations

from app.stats import to_dict
from app.store import Conversation, ConversationStore


def _describe_responder(responder: object) -> dict:
    """Effective responder config, or a placeholder when it cannot report one.

    Tests swap in stubs via ``monkeypatch.setattr("app.main.responder", ...)``
    that need not implement the full protocol. A stub must not be able to turn
    /status into a 500, so a missing ``describe`` degrades instead of raising.
    """
    describe = getattr(responder, "describe", None)
    if not callable(describe):
        return {"kind": "unknown"}
    return describe()


def _conversation_row(conversation: Conversation) -> dict:
    """One conversation's volume: turn count, cumulative tokens, last turn."""
    prompt_tokens = 0
    reply_tokens = 0
    for iid in conversation.order:
        stats = conversation.interactions[iid].stats
        if stats is not None:
            prompt_tokens += stats.prompt_tokens
            reply_tokens += stats.reply_tokens

    last: dict | None = None
    if conversation.order:
        last_iid = conversation.order[-1]
        last_stats = conversation.interactions[last_iid].stats
        last = {
            "interactionId": last_iid,
            # None when that turn cost nothing measurable — echo mode or an
            # Ollama failure. The turn still counts toward interactionCount.
            "stats": to_dict(last_stats) if last_stats is not None else None,
        }

    return {
        "conversationId": conversation.conversation_id,
        "interactionCount": len(conversation.order),
        "totals": {
            "promptTokens": prompt_tokens,
            "replyTokens": reply_tokens,
            "totalTokens": prompt_tokens + reply_tokens,
        },
        "lastInteraction": last,
    }


def build_status(store: ConversationStore, responder: object) -> dict:
    """Operator snapshot of the running server.

    ``responder`` is typed loosely because the route passes the module-level
    singleton, which tests replace with stubs; only ``describe()`` is used.
    """
    conversations = store.list_conversations()
    return {
        "responder": _describe_responder(responder),
        "conversationCount": len(conversations),
        "conversations": [_conversation_row(c) for c in conversations],
    }
```

- [x] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/python -m pytest tests/test_status.py -v`
Expected: PASS — 8 passed

- [x] **Step 5: Commit** *(show diff, wait for user approval, then run)*

```bash
git add app/status.py tests/test_status.py
git commit -m "feat(chat-server): assemble status payload from store and responder"
```

---

### Task 6: Wire the route and persist stats

**Files:**
- Modify: `adaptive_chat_server/app/main.py:10-19` (imports), `:151-159` (`add_interaction` call), and add the route after `replay_interaction`
- Test: `adaptive_chat_server/tests/test_api.py`

**Interfaces:**
- Consumes: `build_status` (Task 5), `Reply.stats` (Task 3), `Interaction.stats` (Task 2).
- Produces: `GET /status` returning the payload from `build_status`.

**Note on test isolation:** `app.main.store` is a module-level singleton shared across every test in `test_api.py`, so `conversationCount` grows as the file runs. Assert against rows looked up **by conversation id**, never against list length or index.

- [x] **Step 1: Write the failing tests**

Append to `tests/test_api.py`:

```python
class _StatsStubResponder:
    def reply(self, text, history):
        return Reply(
            text="ok",
            stats=InteractionStats(
                prompt_tokens=1500,
                reply_tokens=300,
                total_ms=8200,
                load_ms=12,
                prompt_eval_ms=900,
                eval_ms=7200,
            ),
        )

    def describe(self):
        return {"kind": "stub"}


def _rows_by_id() -> dict:
    return {c["conversationId"]: c for c in client.get("/status").json()["conversations"]}


def test_status_reports_conversations_and_echo_responder():
    cid_a = _start()
    _send(cid_a, "i_s001", "hello")
    _send(cid_a, "i_s002", "again")
    cid_b = _start()

    body = client.get("/status").json()
    assert body["responder"]["kind"] == "echo"
    assert body["conversationCount"] >= 2

    rows = {c["conversationId"]: c for c in body["conversations"]}
    assert rows[cid_a]["interactionCount"] == 2
    assert rows[cid_a]["lastInteraction"]["interactionId"] == "i_s002"
    assert rows[cid_a]["lastInteraction"]["stats"] is None
    assert rows[cid_a]["totals"]["totalTokens"] == 0
    assert rows[cid_b]["interactionCount"] == 0
    assert rows[cid_b]["lastInteraction"] is None


def test_status_replay_does_not_increment_interaction_count():
    cid = _start()
    _send(cid, "i_s010", "hello")
    _send(cid, "i_s010", "hello")
    assert _rows_by_id()[cid]["interactionCount"] == 1


def test_status_reports_stats_captured_from_the_responder(monkeypatch):
    monkeypatch.setattr("app.main.responder", _StatsStubResponder())
    cid = _start()
    _send(cid, "i_s020", "hello")

    body = client.get("/status").json()
    assert body["responder"] == {"kind": "stub"}
    row = {c["conversationId"]: c for c in body["conversations"]}[cid]
    assert row["totals"] == {
        "promptTokens": 1500,
        "replyTokens": 300,
        "totalTokens": 1800,
    }
    assert row["lastInteraction"]["stats"]["tokensPerSecond"] == 41.7
    assert row["lastInteraction"]["stats"]["evalMs"] == 7200


def test_send_envelope_is_unchanged_by_stats():
    cid = _start()
    body = _send(cid, "i_s030", "hello").json()
    assert set(body) == {"conversationId", "interactionId", "messages", "links"}
```

Extend the file's imports to:

```python
from app.responder import Reply
from app.stats import InteractionStats
```

- [x] **Step 2: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest tests/test_api.py -v`
Expected: FAIL — `GET /status` returns 404 (`assert 404 == 200` / `KeyError: 'conversations'`)

- [x] **Step 3: Write the implementation**

In `app/main.py`, add the import beside the existing `app.store` import:

```python
from app.status import build_status
```

In `send_interaction`, add `stats=reply.stats` to the `Interaction` construction:

```python
    store.add_interaction(
        cid,
        Interaction(
            interaction_id=x_interaction_id,
            text=message,
            messages=messages,
            reply_text=reply.text,
            stats=reply.stats,
        ),
    )
```

Add the route after `replay_interaction`:

```python
@app.get("/status")
def server_status() -> dict:
    """Operator snapshot: effective responder config and per-conversation volume.

    Read-only and side-effect free. Carries no message text — see
    :func:`app.status.build_status`.
    """
    return build_status(store, responder)
```

- [x] **Step 4: Run tests to verify they pass**

Run: `.venv/bin/python -m pytest tests/test_api.py -v`
Expected: PASS — new tests plus all pre-existing route tests

- [x] **Step 5: Commit** *(show diff, wait for user approval, then run)*

```bash
git add app/main.py tests/test_api.py
git commit -m "feat(chat-server): add GET /status and persist stats on interactions"
```

---

### Task 7: README documentation

**Files:**
- Modify: `adaptive_chat_server/README.md` — wire-contract table (~line 42), components table (~line 53), both mermaid `ROUTES` nodes (lines 19 and 198), plus a new status section

**Interfaces:**
- Consumes: the payload shape produced by Task 6. No code changes.

- [x] **Step 1: Add the wire-contract row**

In the **Wire contract** table, add after the `GET /conversations/{cid}/interactions/{iid}` row:

```markdown
| `GET /status`                                 | Server + conversation snapshot | —                                                                 | **status payload**                        |
```

- [x] **Step 2: Add the components rows**

In the **Components (`app/`)** table, add after the `card_detect.py` row:

```markdown
| `stats.py`                  | `InteractionStats` — one Ollama turn's token counts (`prompt_eval_count` / `eval_count`) and timing breakdown, with nanosecond→millisecond conversion done once at capture. `from_ollama_response(data)` returns `None` unless both token counts are present, so a malformed body degrades instead of producing a half-filled record; `to_dict(stats)` derives `totalTokens` and `tokensPerSecond` at serialization. |
| `status.py`                 | `build_status(store, responder)` — assembles the `GET /status` payload: effective responder config plus per-conversation turn counts, cumulative tokens, and the last turn's stats. Carries **no message text**; a responder without `describe()` degrades to `{"kind": "unknown"}` rather than erroring.                                                                                                              |
```

- [x] **Step 3: Update both mermaid ROUTES nodes**

Line 19 — replace:

```
    ROUTES["main.py routes\nPOST /conversations · POST .../interactions · GET .../interactions/{iid}"]
```

with:

```
    ROUTES["main.py routes\nPOST /conversations · POST .../interactions · GET .../interactions/{iid} · GET /status"]
```

Line 198 — replace:

```
        ROUTES["Routes (main.py)\nstart / send / replay"]
```

with:

```
        ROUTES["Routes (main.py)\nstart / send / replay / status"]
```

- [x] **Step 4: Add the status section**

Add a new `### Status endpoint` section immediately after the **Conversation context** section:

````markdown
### Status endpoint

`GET /status` is a read-only operator snapshot — how the process is configured and
how much traffic it is holding. It is **not** part of the chat wire contract and
the Flutter client never calls it.

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

**`responder` reports _effective_ config, not requested config.** If
`--json-format schema` was given but the bundled schema was unusable, the
constructor silently falls back to `none`; `/status` then reports
`"jsonFormat": "none"` **and** `"jsonFormatRequested": "schema"`. The extra key
appears only on a downgrade, so its presence is the signal. In echo mode the
block is just `{"kind": "echo"}`.

**`stats` is `null` whenever a turn cost nothing measurable** — echo mode, or any
Ollama failure (unreachable, HTTP error, unparseable body). The interaction still
counts toward `interactionCount`; `totals` sums only the turns that have stats.
`lastInteraction` is `null` for a conversation with no turns yet. An idempotent
replay of an existing `X-Interaction-Id` does not increment `interactionCount`.

**`tokensPerSecond`** is generation speed (`replyTokens` over `evalMs`), excluding
model load and prompt evaluation, so it stays comparable between warm and cold
turns.

**No message text appears in this payload**, and `systemPromptFile` is reduced to
a bare filename. The endpoint is unauthenticated and CORS is `allow_origins=["*"]`
— fine for the default `127.0.0.1` bind, but binding to `0.0.0.0` would expose
configuration metadata and conversation-volume data to the network.
````

- [x] **Step 5: Update the Test section blurb**

In the **Test** section, replace:

```
Covers the store, bubble authoring, the routes (start/send/replay, idempotency,
validation), responder selection, and the Ollama responder (mocked HTTP — no live
Ollama).
```

with:

```
Covers the store, bubble authoring, the routes (start/send/replay/status,
idempotency, validation), responder selection, token-stats capture and the
status payload, and the Ollama responder (mocked HTTP — no live Ollama).
```

- [x] **Step 6: Verify the docs match reality**

Start the server and compare the documented payload against the live one:

```bash
.venv/bin/uvicorn app.main:app --port 8000 &
sleep 2
curl -s localhost:8000/status
curl -s -X POST localhost:8000/conversations
```

Expected: `{"responder":{"kind":"echo"},"conversationCount":0,"conversations":[]}`, then a conversation id. Stop the server afterward.

- [x] **Step 7: Commit** *(show diff, wait for user approval, then run)*

```bash
git add README.md
git commit -m "docs(chat-server): document GET /status and the stats modules"
```

---

### Final Task: Full verification

Per the AGENTS.md plan-completion gate, do not claim completion until this passes and its output is pasted.

- [ ] **Step 1: Run the full server suite**

```bash
cd adaptive_chat_server
.venv/bin/python -m pytest -v
```

Expected: PASS, zero failures. Record the pass count.

- [ ] **Step 2: Confirm nothing outside the server changed**

```bash
git diff --stat main...HEAD
```

Expected: only files under `adaptive_chat_server/` plus the two `docs/superpowers/` files. **No** Flutter package, `widgetbook/`, or `adaptive_chat_client/` files. If any appear, the no-wire-change constraint was violated.

- [ ] **Step 3: Invoke the verification skill**

Use `superpowers:verification-before-completion` and paste the command output (exit code and pass/fail counts) before making any success claim.

- [ ] **Step 4: Report**

State the pass count and the changed-file list. Only then is the plan complete.
