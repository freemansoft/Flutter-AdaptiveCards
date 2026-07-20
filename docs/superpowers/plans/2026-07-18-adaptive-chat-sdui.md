# Adaptive Chat (SDUI) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a server-driven-UI chat demo — a FastAPI echo backend and a Flutter sample app whose compose box is an Adaptive Card and whose scrolling log renders server-authored Adaptive Card "bubbles."

**Architecture:** Two new top-level siblings joined by an HTTP contract. The Flutter client reuses `flutter_adaptive_cards_host_fs` request serialization (`AdaptiveCardInvokeRequest.fromSubmit` + `PlainJsonInvokeAdapter.toMap`) to POST the compose card's `Action.Submit`, then parses a chat *envelope* and **appends** the returned cards to a log (a custom response path — it does **not** run the host package's overlay-applier). The server keeps conversation state in memory and authors all bubble alignment/styling in Adaptive Card JSON.

**Tech Stack:** Python 3.11+, FastAPI, uvicorn, pytest (backend); Flutter 3.44.0 via FVM, `flutter_adaptive_cards_fs` + `flutter_adaptive_cards_host_fs` (path deps), `package:http` + `package:http/testing.dart` (client).

## Global Constraints

- **FVM:** Prefix every `flutter`/`dart` command with `fvm` (e.g. `fvm flutter test`). Pinned Flutter is `3.44.0`; Dart SDK constraint `^3.12.0`.
- **Commit gate:** This repo forbids committing without explicit user confirmation. The `Commit` step in each task means "stage the listed files and propose the commit"; the executor must show the diff and wait for the user before running `git commit`.
- **Lint (`very_good_analysis`):** single quotes only; `always_use_package_imports` (import sibling files as `package:adaptive_chat/...`, never relative); `const` constructors where possible.
- **No published-package changes:** touch nothing under `packages/`. The client only *uses* `flutter_adaptive_cards_host_fs` via its public exports. `adaptive_chat/` and `adaptive_chat_server/` are outside `packages/`, so the per-package coverage floor and `CHANGELOG.md` gate do not apply.
- **Workspace:** `adaptive_chat` is a Dart pub-workspace member (add it to root `pubspec.yaml` `workspace:` list; its pubspec uses `resolution: workspace`). `adaptive_chat_server/` is Python and is **not** in the Dart workspace.
- **Branch:** do all work on a feature branch (e.g. `feat/adaptive-chat-sdui`), not `main`.

## File Structure

**Backend — `adaptive_chat_server/`**
- `requirements.txt` — runtime + test deps
- `README.md` — run instructions
- `app/__init__.py`
- `app/store.py` — `ConversationStore`, `Conversation`, `Interaction`, `Message`
- `app/cards.py` — `user_bubble(text)`, `assistant_bubble(text)`, `envelope(...)`
- `app/responder.py` — `Responder` protocol + `EchoResponder`
- `app/main.py` — FastAPI app, CORS, routes, DI
- `tests/test_store.py`, `tests/test_cards.py`, `tests/test_responder.py`, `tests/test_api.py`

**Client — `adaptive_chat/`**
- `pubspec.yaml`, `analysis_options.yaml`
- `lib/main.dart` — app entry, `HostConfigs`, `ChatPage` host
- `lib/src/chat_models.dart` — `ChatStart`, `ChatEnvelope`, `ChatBackendException`
- `lib/src/chat_backend_client.dart` — `ChatBackendClient`
- `lib/src/conversation_controller.dart` — `ConversationController`, `ChatMode`
- `lib/src/chat_page.dart` — `ChatPage`, compose card, log list, pending bubble
- `lib/src/compose_card.dart` — the compose Adaptive Card JSON
- `test/chat_backend_client_test.dart`, `test/conversation_controller_test.dart`, `test/chat_page_test.dart`

---

## Phase 1 — Backend (FastAPI)

### Task 1: Scaffold server + conversation store

**Files:**
- Create: `adaptive_chat_server/requirements.txt`
- Create: `adaptive_chat_server/README.md`
- Create: `adaptive_chat_server/app/__init__.py` (empty)
- Create: `adaptive_chat_server/app/store.py`
- Test: `adaptive_chat_server/tests/test_store.py`

**Interfaces:**
- Produces: `Message(role: str, card: dict)`, `Interaction(interaction_id: str, text: str, messages: list[Message])`, `Conversation(conversation_id: str, interactions: dict[str, Interaction], order: list[str])`, and `ConversationStore` with `create() -> Conversation`, `get(cid) -> Conversation | None`, `has_interaction(cid, iid) -> bool`, `add_interaction(cid, interaction) -> None`, `get_interaction(cid, iid) -> Interaction | None`.

- [ ] **Step 1: Create `requirements.txt`**

```text
fastapi==0.115.6
uvicorn[standard]==0.34.0
httpx==0.28.1
pytest==8.3.4
```

- [ ] **Step 2: Create venv and install**

Run:
```bash
cd adaptive_chat_server
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```
Expected: installs without error. (Add `.venv/` to the repo `.gitignore` if not already ignored.)

- [ ] **Step 3: Write the failing store test** — `adaptive_chat_server/tests/test_store.py`

```python
from app.store import ConversationStore, Interaction, Message


def test_create_returns_unique_conversation_ids():
    store = ConversationStore()
    a = store.create()
    b = store.create()
    assert a.conversation_id != b.conversation_id
    assert store.get(a.conversation_id) is a


def test_add_and_get_interaction():
    store = ConversationStore()
    conv = store.create()
    inter = Interaction(
        interaction_id="i_0001",
        text="hi",
        messages=[Message(role="user", card={"type": "AdaptiveCard"})],
    )
    assert store.has_interaction(conv.conversation_id, "i_0001") is False
    store.add_interaction(conv.conversation_id, inter)
    assert store.has_interaction(conv.conversation_id, "i_0001") is True
    assert store.get_interaction(conv.conversation_id, "i_0001") is inter


def test_get_missing_conversation_returns_none():
    store = ConversationStore()
    assert store.get("nope") is None
    assert store.get_interaction("nope", "i_0001") is None
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_store.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'app.store'`.

- [ ] **Step 5: Implement `app/store.py`**

```python
"""In-memory conversation state for the Adaptive Chat demo."""
from __future__ import annotations

import uuid
from dataclasses import dataclass, field


@dataclass
class Message:
    """One rendered bubble: an author role plus its Adaptive Card map."""

    role: str
    card: dict


@dataclass
class Interaction:
    """One send/response cycle within a conversation."""

    interaction_id: str
    text: str
    messages: list[Message]


@dataclass
class Conversation:
    """A session: ordered interactions keyed by client-supplied id."""

    conversation_id: str
    interactions: dict[str, Interaction] = field(default_factory=dict)
    order: list[str] = field(default_factory=list)


class ConversationStore:
    """Process-lifetime store of conversations (lost on restart)."""

    def __init__(self) -> None:
        self._conversations: dict[str, Conversation] = {}

    def create(self) -> Conversation:
        cid = f"c_{uuid.uuid4().hex[:12]}"
        conv = Conversation(conversation_id=cid)
        self._conversations[cid] = conv
        return conv

    def get(self, cid: str) -> Conversation | None:
        return self._conversations.get(cid)

    def has_interaction(self, cid: str, iid: str) -> bool:
        conv = self._conversations.get(cid)
        return bool(conv and iid in conv.interactions)

    def add_interaction(self, cid: str, interaction: Interaction) -> None:
        conv = self._conversations[cid]
        conv.interactions[interaction.interaction_id] = interaction
        conv.order.append(interaction.interaction_id)

    def get_interaction(self, cid: str, iid: str) -> Interaction | None:
        conv = self._conversations.get(cid)
        if conv is None:
            return None
        return conv.interactions.get(iid)
```

- [ ] **Step 6: Add `tests/__init__.py` and a `conftest.py` so `app` imports resolve**

Create `adaptive_chat_server/conftest.py`:
```python
# Ensures `import app.*` resolves when pytest runs from adaptive_chat_server/.
```
(An empty file is enough; pytest adds the rootdir to `sys.path`.)

- [ ] **Step 7: Run test to verify it passes**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_store.py -v`
Expected: PASS (3 passed).

- [ ] **Step 8: Write `README.md`**

```markdown
# adaptive_chat_server

FastAPI echo backend for the Adaptive Chat SDUI demo.

## Run

    python3 -m venv .venv
    .venv/bin/pip install -r requirements.txt
    .venv/bin/uvicorn app.main:app --reload --port 8000

## Test

    .venv/bin/python -m pytest -v
```

- [ ] **Step 9: Commit**

```bash
git add adaptive_chat_server/requirements.txt adaptive_chat_server/README.md \
        adaptive_chat_server/app/__init__.py adaptive_chat_server/app/store.py \
        adaptive_chat_server/conftest.py adaptive_chat_server/tests/test_store.py
git commit -m "feat(chat-server): scaffold FastAPI project and conversation store"
```

---

### Task 2: Bubble card builder + envelope

**Files:**
- Create: `adaptive_chat_server/app/cards.py`
- Test: `adaptive_chat_server/tests/test_cards.py`

**Interfaces:**
- Consumes: `Message` from `app.store`.
- Produces: `user_bubble(text: str) -> dict` (right-aligned, accent container), `assistant_bubble(text: str) -> dict` (left-aligned, emphasis container), `envelope(cid: str, iid: str, messages: list[Message]) -> dict`.

- [ ] **Step 1: Write the failing test** — `adaptive_chat_server/tests/test_cards.py`

```python
from app.cards import assistant_bubble, envelope, user_bubble
from app.store import Message


def _first_columnset(card: dict) -> dict:
    return card["body"][0]


def test_user_bubble_is_right_aligned_accent():
    card = user_bubble("hello")
    cols = _first_columnset(card)["columns"]
    # spacer first, content second -> pushes bubble right
    assert cols[0]["width"] == "stretch"
    assert cols[1]["width"] == "auto"
    container = cols[1]["items"][0]
    assert container["style"] == "accent"
    assert container["items"][0]["text"] == "hello"


def test_assistant_bubble_is_left_aligned_emphasis():
    card = assistant_bubble("Did you just say: hi")
    cols = _first_columnset(card)["columns"]
    assert cols[0]["width"] == "auto"
    assert cols[1]["width"] == "stretch"
    container = cols[0]["items"][0]
    assert container["style"] == "emphasis"
    assert container["items"][0]["text"] == "Did you just say: hi"


def test_envelope_shape():
    msgs = [
        Message(role="user", card=user_bubble("hi")),
        Message(role="assistant", card=assistant_bubble("Did you just say: hi")),
    ]
    env = envelope("c_1", "i_0001", msgs)
    assert env["conversationId"] == "c_1"
    assert env["interactionId"] == "i_0001"
    assert len(env["messages"]) == 2
    assert env["messages"][0] == msgs[0].card
    assert env["links"]["self"] == "/conversations/c_1/interactions/i_0001"
    assert env["links"]["postNext"] == "/conversations/c_1/interactions"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_cards.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'app.cards'`.

- [ ] **Step 3: Implement `app/cards.py`**

```python
"""Server-authored Adaptive Card bubbles and the response envelope.

All bubble alignment and fill live here, in the card JSON, so the client
stays 'dumb' and renders each card full-width and stacked.
"""
from __future__ import annotations

from app.store import Message

_VERSION = "1.5"


def _text_container(text: str, style: str) -> dict:
    return {
        "type": "Container",
        "style": style,
        "items": [{"type": "TextBlock", "text": text, "wrap": True}],
    }


def _bubble(text: str, *, style: str, align_right: bool) -> dict:
    content = {"type": "Column", "width": "auto", "items": [_text_container(text, style)]}
    spacer = {"type": "Column", "width": "stretch", "items": []}
    columns = [spacer, content] if align_right else [content, spacer]
    return {
        "type": "AdaptiveCard",
        "version": _VERSION,
        "body": [{"type": "ColumnSet", "columns": columns}],
    }


def user_bubble(text: str) -> dict:
    """Right-aligned accent bubble for the user's message."""
    return _bubble(text, style="accent", align_right=True)


def assistant_bubble(text: str) -> dict:
    """Left-aligned emphasis bubble for the assistant's reply."""
    return _bubble(text, style="emphasis", align_right=False)


def envelope(cid: str, iid: str, messages: list[Message]) -> dict:
    """Wire envelope: pre-styled cards plus self/postNext links."""
    return {
        "conversationId": cid,
        "interactionId": iid,
        "messages": [m.card for m in messages],
        "links": {
            "self": f"/conversations/{cid}/interactions/{iid}",
            "postNext": f"/conversations/{cid}/interactions",
        },
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_cards.py -v`
Expected: PASS (3 passed).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/cards.py adaptive_chat_server/tests/test_cards.py
git commit -m "feat(chat-server): author bubble cards and response envelope"
```

---

### Task 3: Responder interface + echo

**Files:**
- Create: `adaptive_chat_server/app/responder.py`
- Test: `adaptive_chat_server/tests/test_responder.py`

**Interfaces:**
- Produces: `Responder` (Protocol with `reply(text: str) -> str`) and `EchoResponder` returning `"Did you just say: {text}"`.

- [ ] **Step 1: Write the failing test** — `adaptive_chat_server/tests/test_responder.py`

```python
from app.responder import EchoResponder


def test_echo_wraps_the_input():
    assert EchoResponder().reply("hello") == "Did you just say: hello"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_responder.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'app.responder'`.

- [ ] **Step 3: Implement `app/responder.py`**

```python
"""Reply strategies. v1 echoes; a future OllamaResponder drops in here."""
from __future__ import annotations

from typing import Protocol


class Responder(Protocol):
    """Turns a user message into a reply string."""

    def reply(self, text: str) -> str: ...


class EchoResponder:
    """v1 responder: echoes the user's text back."""

    def reply(self, text: str) -> str:
        return f"Did you just say: {text}"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_responder.py -v`
Expected: PASS (1 passed).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/responder.py adaptive_chat_server/tests/test_responder.py
git commit -m "feat(chat-server): add Responder interface and EchoResponder"
```

---

### Task 4: FastAPI app + start-conversation route

**Files:**
- Create: `adaptive_chat_server/app/main.py`
- Test: `adaptive_chat_server/tests/test_api.py`

**Interfaces:**
- Consumes: `ConversationStore` (Task 1), `EchoResponder` (Task 3), `user_bubble`/`assistant_bubble`/`envelope` (Task 2).
- Produces: FastAPI `app`; `POST /conversations -> {"conversationId": str, "links": {"postNext": str}}`; module-level `store` and `responder` singletons.

- [ ] **Step 1: Write the failing test** — `adaptive_chat_server/tests/test_api.py`

```python
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_start_conversation_returns_id_and_post_next():
    resp = client.post("/conversations")
    assert resp.status_code == 200
    body = resp.json()
    cid = body["conversationId"]
    assert cid.startswith("c_")
    assert body["links"]["postNext"] == f"/conversations/{cid}/interactions"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_api.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'app.main'`.

- [ ] **Step 3: Implement `app/main.py`**

```python
"""FastAPI entrypoint for the Adaptive Chat echo backend."""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.responder import EchoResponder
from app.store import ConversationStore

app = FastAPI(title="Adaptive Chat Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

store = ConversationStore()
responder = EchoResponder()


@app.post("/conversations")
def start_conversation() -> dict:
    conv = store.create()
    cid = conv.conversation_id
    return {
        "conversationId": cid,
        "links": {"postNext": f"/conversations/{cid}/interactions"},
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_api.py -v`
Expected: PASS (1 passed).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/main.py adaptive_chat_server/tests/test_api.py
git commit -m "feat(chat-server): FastAPI app, CORS, and start-conversation route"
```

---

### Task 5: Send-interaction route (with idempotency + validation)

**Files:**
- Modify: `adaptive_chat_server/app/main.py`
- Test: `adaptive_chat_server/tests/test_api.py`

**Interfaces:**
- Produces: `POST /conversations/{cid}/interactions` — header `X-Interaction-Id` (required), body PlainJson invoke (`{"kind","actionId","data":{"message"}}`). Returns `200` + `envelope`. `400` on missing header/message; `404` on unknown conversation; repeated `X-Interaction-Id` returns the stored envelope.

- [ ] **Step 1: Add failing tests to `tests/test_api.py`**

```python
def _start() -> str:
    return client.post("/conversations").json()["conversationId"]


def _send(cid: str, iid: str, message: str):
    return client.post(
        f"/conversations/{cid}/interactions",
        headers={"X-Interaction-Id": iid},
        json={"kind": "submit", "actionId": "send", "data": {"message": message}},
    )


def test_send_returns_two_bubbles_and_links():
    cid = _start()
    resp = _send(cid, "i_0001", "hi there")
    assert resp.status_code == 200
    body = resp.json()
    assert body["interactionId"] == "i_0001"
    assert len(body["messages"]) == 2
    user_text = body["messages"][0]["body"][0]["columns"][1]["items"][0]["items"][0]["text"]
    reply_text = body["messages"][1]["body"][0]["columns"][0]["items"][0]["items"][0]["text"]
    assert user_text == "hi there"
    assert reply_text == "Did you just say: hi there"
    assert body["links"]["postNext"] == f"/conversations/{cid}/interactions"


def test_send_is_idempotent_by_interaction_id():
    cid = _start()
    first = _send(cid, "i_0007", "same").json()
    second = _send(cid, "i_0007", "IGNORED second body").json()
    # Stored envelope is returned unchanged; the second message is not reprocessed.
    assert second == first


def test_send_missing_header_is_400():
    cid = _start()
    resp = client.post(
        f"/conversations/{cid}/interactions",
        json={"kind": "submit", "data": {"message": "hi"}},
    )
    assert resp.status_code == 400


def test_send_missing_message_is_400():
    cid = _start()
    resp = client.post(
        f"/conversations/{cid}/interactions",
        headers={"X-Interaction-Id": "i_0001"},
        json={"kind": "submit", "data": {}},
    )
    assert resp.status_code == 400


def test_send_unknown_conversation_is_404():
    resp = _send("c_missing", "i_0001", "hi")
    assert resp.status_code == 404
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_api.py -v`
Expected: the five new tests FAIL with `404 Not Found` (route not defined yet).

- [ ] **Step 3: Add the route to `app/main.py`**

Add imports at top:
```python
from fastapi import FastAPI, Header, HTTPException, Request

from app.cards import assistant_bubble, envelope, user_bubble
from app.store import Interaction, Message
```

Append the route:
```python
@app.post("/conversations/{cid}/interactions")
async def send_interaction(
    cid: str,
    request: Request,
    x_interaction_id: str | None = Header(default=None),
) -> dict:
    if not x_interaction_id:
        raise HTTPException(status_code=400, detail="X-Interaction-Id header required")
    if store.get(cid) is None:
        raise HTTPException(status_code=404, detail="unknown conversation")

    # Idempotent replay: same interaction id returns the stored envelope.
    existing = store.get_interaction(cid, x_interaction_id)
    if existing is not None:
        return envelope(cid, x_interaction_id, existing.messages)

    body = await request.json()
    message = (body.get("data") or {}).get("message")
    if not message:
        raise HTTPException(status_code=400, detail="data.message required")

    reply_text = responder.reply(message)
    messages = [
        Message(role="user", card=user_bubble(message)),
        Message(role="assistant", card=assistant_bubble(reply_text)),
    ]
    store.add_interaction(
        cid,
        Interaction(interaction_id=x_interaction_id, text=message, messages=messages),
    )
    return envelope(cid, x_interaction_id, messages)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_api.py -v`
Expected: PASS (all api tests green).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/main.py adaptive_chat_server/tests/test_api.py
git commit -m "feat(chat-server): send-interaction route with idempotency and validation"
```

---

### Task 6: Replay route (GET interaction)

**Files:**
- Modify: `adaptive_chat_server/app/main.py`
- Test: `adaptive_chat_server/tests/test_api.py`

**Interfaces:**
- Produces: `GET /conversations/{cid}/interactions/{iid}` → `200` + `envelope`; `404` on unknown conversation or interaction.

- [ ] **Step 1: Add failing tests to `tests/test_api.py`**

```python
def test_replay_returns_stored_envelope():
    cid = _start()
    sent = _send(cid, "i_0009", "replay me").json()
    resp = client.get(f"/conversations/{cid}/interactions/i_0009")
    assert resp.status_code == 200
    assert resp.json() == sent


def test_replay_unknown_interaction_is_404():
    cid = _start()
    resp = client.get(f"/conversations/{cid}/interactions/i_missing")
    assert resp.status_code == 404
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest tests/test_api.py -k replay -v`
Expected: FAIL with `404`/route-missing.

- [ ] **Step 3: Add the route to `app/main.py`**

```python
@app.get("/conversations/{cid}/interactions/{iid}")
def replay_interaction(cid: str, iid: str) -> dict:
    if store.get(cid) is None:
        raise HTTPException(status_code=404, detail="unknown conversation")
    interaction = store.get_interaction(cid, iid)
    if interaction is None:
        raise HTTPException(status_code=404, detail="unknown interaction")
    return envelope(cid, iid, interaction.messages)
```

- [ ] **Step 4: Run the full backend suite**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest -v`
Expected: PASS (all backend tests green).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat_server/app/main.py adaptive_chat_server/tests/test_api.py
git commit -m "feat(chat-server): add replay (GET interaction) route"
```

---

## Phase 2 — Client (Flutter)

### Task 7: Scaffold the `adaptive_chat` app

**Files:**
- Create: `adaptive_chat/pubspec.yaml`
- Create: `adaptive_chat/analysis_options.yaml`
- Create: `adaptive_chat/lib/main.dart`
- Modify: `pubspec.yaml` (repo root — add `adaptive_chat` to `workspace:`)
- Test: `adaptive_chat/test/smoke_test.dart`

**Interfaces:**
- Produces: a runnable app whose home is a `Scaffold` titled "Adaptive Chat".

- [ ] **Step 1: Create `adaptive_chat/pubspec.yaml`**

```yaml
name: adaptive_chat
description: SDUI chat demo for flutter_adaptive_cards_fs.
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.12.0

resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  flutter_adaptive_cards_fs:
    path: ../packages/flutter_adaptive_cards_fs
  flutter_adaptive_cards_host_fs:
    path: ../packages/flutter_adaptive_cards_host_fs
  http: ^1.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^10.3.0

flutter:
  uses-material-design: true
```

- [ ] **Step 2: Create `adaptive_chat/analysis_options.yaml`**

```yaml
include: package:very_good_analysis/analysis_options.yaml
linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
    always_use_package_imports: true
```

- [ ] **Step 3: Add `adaptive_chat` to the root workspace**

In repo-root `pubspec.yaml`, add a final list item under `workspace:`:
```yaml
  - adaptive_chat
```

- [ ] **Step 4: Create minimal `adaptive_chat/lib/main.dart`**

```dart
import 'package:flutter/material.dart';

void main() => runApp(const AdaptiveChatApp());

/// Root of the Adaptive Chat SDUI demo.
class AdaptiveChatApp extends StatelessWidget {
  /// Creates the app.
  const AdaptiveChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Chat',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Adaptive Chat')),
        body: const Center(child: Text('Adaptive Chat')),
      ),
    );
  }
}
```

- [ ] **Step 5: Write the smoke test** — `adaptive_chat/test/smoke_test.dart`

```dart
import 'package:adaptive_chat/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders the Adaptive Chat title', (tester) async {
    await tester.pumpWidget(const AdaptiveChatApp());
    expect(find.text('Adaptive Chat'), findsWidgets);
  });
}
```

- [ ] **Step 6: Install deps and run the smoke test**

Run:
```bash
cd adaptive_chat && fvm flutter pub get && fvm flutter test test/smoke_test.dart
```
Expected: PASS (1 test). If `pub get` reports workspace errors, run `fvm flutter pub get` from the repo root once, then retry.

- [ ] **Step 7: Commit**

```bash
git add adaptive_chat/pubspec.yaml adaptive_chat/analysis_options.yaml \
        adaptive_chat/lib/main.dart adaptive_chat/test/smoke_test.dart pubspec.yaml
git commit -m "feat(chat): scaffold adaptive_chat Flutter sample app"
```

---

### Task 8: Wire models + backend client

**Files:**
- Create: `adaptive_chat/lib/src/chat_models.dart`
- Create: `adaptive_chat/lib/src/chat_backend_client.dart`
- Test: `adaptive_chat/test/chat_backend_client_test.dart`

**Interfaces:**
- Consumes: `AdaptiveCardInvokeRequest`, `PlainJsonInvokeAdapter` (from `flutter_adaptive_cards_host_fs`); `SubmitActionInvoke` (from `flutter_adaptive_cards_fs`); `package:http`.
- Produces:
  - `ChatStart({required String conversationId, required String postNext})` with `ChatStart.fromJson(Map<String,dynamic>)`.
  - `ChatEnvelope({required String conversationId, required String interactionId, required List<Map<String,dynamic>> messages, required String self, required String postNext})` with `ChatEnvelope.fromJson(Map<String,dynamic>)`.
  - `ChatBackendException(String message)`.
  - `ChatBackendClient({required Uri baseUrl, http.Client? client})` with `Future<ChatStart> startConversation()` and `Future<ChatEnvelope> sendInteraction({required String postNext, required String interactionId, required SubmitActionInvoke invoke})`.

- [ ] **Step 1: Write the failing client test** — `adaptive_chat/test/chat_backend_client_test.dart`

```dart
import 'dart:convert';

import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('startConversation parses id and postNext', () async {
    final mock = MockClient((req) async {
      expect(req.url.path, '/conversations');
      expect(req.method, 'POST');
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'links': {'postNext': '/conversations/c_1/interactions'},
        }),
        200,
      );
    });
    final client = ChatBackendClient(
      baseUrl: Uri.parse('http://localhost:8000'),
      client: mock,
    );

    final start = await client.startConversation();

    expect(start.conversationId, 'c_1');
    expect(start.postNext, '/conversations/c_1/interactions');
  });

  test('sendInteraction posts PlainJson body + interaction header and parses envelope', () async {
    late http.Request captured;
    final mock = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'interactionId': 'i_0001',
          'messages': [
            {'type': 'AdaptiveCard', 'body': []},
          ],
          'links': {
            'self': '/conversations/c_1/interactions/i_0001',
            'postNext': '/conversations/c_1/interactions',
          },
        }),
        200,
      );
    });
    final client = ChatBackendClient(
      baseUrl: Uri.parse('http://localhost:8000'),
      client: mock,
    );

    final env = await client.sendInteraction(
      postNext: '/conversations/c_1/interactions',
      interactionId: 'i_0001',
      invoke: const SubmitActionInvoke(data: {'message': 'hello'}),
    );

    expect(captured.headers['X-Interaction-Id'], 'i_0001');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['kind'], 'submit');
    expect((body['data'] as Map)['message'], 'hello');
    expect(env.interactionId, 'i_0001');
    expect(env.messages.single['type'], 'AdaptiveCard');
    expect(env.postNext, '/conversations/c_1/interactions');
  });

  test('non-200 throws ChatBackendException', () async {
    final mock = MockClient((req) async => http.Response('boom', 500));
    final client = ChatBackendClient(
      baseUrl: Uri.parse('http://localhost:8000'),
      client: mock,
    );
    expect(client.startConversation(), throwsA(isA<ChatBackendException>()));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat && fvm flutter test test/chat_backend_client_test.dart`
Expected: FAIL — `chat_backend_client.dart` does not exist.

- [ ] **Step 3: Implement `lib/src/chat_models.dart`**

```dart
/// Data types for the Adaptive Chat wire contract.
library;

/// Result of starting a conversation.
class ChatStart {
  /// Creates a start result.
  const ChatStart({required this.conversationId, required this.postNext});

  /// Parses the `POST /conversations` response.
  factory ChatStart.fromJson(Map<String, dynamic> json) {
    final links = json['links'] as Map<String, dynamic>;
    return ChatStart(
      conversationId: json['conversationId'] as String,
      postNext: links['postNext'] as String,
    );
  }

  /// Server-minted conversation id.
  final String conversationId;

  /// URL the next interaction posts to.
  final String postNext;
}

/// One interaction's response: pre-styled cards plus follow-up links.
class ChatEnvelope {
  /// Creates an envelope.
  const ChatEnvelope({
    required this.conversationId,
    required this.interactionId,
    required this.messages,
    required this.self,
    required this.postNext,
  });

  /// Parses a send/replay response envelope.
  factory ChatEnvelope.fromJson(Map<String, dynamic> json) {
    final links = json['links'] as Map<String, dynamic>;
    final rawMessages = json['messages'] as List<dynamic>;
    return ChatEnvelope(
      conversationId: json['conversationId'] as String,
      interactionId: json['interactionId'] as String,
      messages: rawMessages
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList(),
      self: links['self'] as String,
      postNext: links['postNext'] as String,
    );
  }

  /// Conversation this interaction belongs to.
  final String conversationId;

  /// Client-supplied id echoed by the server.
  final String interactionId;

  /// Ordered, pre-styled Adaptive Card maps to render as bubbles.
  final List<Map<String, dynamic>> messages;

  /// Re-GET URL for this interaction (replay).
  final String self;

  /// URL the next interaction posts to.
  final String postNext;
}

/// Raised when the chat backend returns an error or unreachable response.
class ChatBackendException implements Exception {
  /// Creates the exception with a [message].
  ChatBackendException(this.message);

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'ChatBackendException: $message';
}
```

- [ ] **Step 4: Implement `lib/src/chat_backend_client.dart`**

```dart
import 'dart:convert';

import 'package:adaptive_chat/src/chat_models.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:http/http.dart' as http;

/// Talks to the Adaptive Chat backend.
///
/// Reuses `flutter_adaptive_cards_host_fs` request serialization
/// (`AdaptiveCardInvokeRequest.fromSubmit` + `PlainJsonInvokeAdapter.toMap`)
/// for the send body, then parses the chat envelope itself (the response is a
/// list of cards to append, not an invoke-effect patch).
class ChatBackendClient {
  /// Creates a client posting to [baseUrl]; inject [client] in tests.
  ChatBackendClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// Base URL of the backend (e.g. `http://localhost:8000`).
  final Uri baseUrl;

  final http.Client _client;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  /// Starts a conversation and returns its id + first `postNext`.
  Future<ChatStart> startConversation() async {
    final resp = await _client.post(
      baseUrl.resolve('/conversations'),
      headers: _jsonHeaders,
    );
    if (resp.statusCode != 200) {
      throw ChatBackendException('start failed: HTTP ${resp.statusCode}');
    }
    return ChatStart.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Sends one interaction and returns the response envelope.
  Future<ChatEnvelope> sendInteraction({
    required String postNext,
    required String interactionId,
    required SubmitActionInvoke invoke,
  }) async {
    final request = AdaptiveCardInvokeRequest.fromSubmit(invoke);
    final body = PlainJsonInvokeAdapter.toMap(request);
    final resp = await _client.post(
      baseUrl.resolve(postNext),
      headers: {..._jsonHeaders, 'X-Interaction-Id': interactionId},
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw ChatBackendException('send failed: HTTP ${resp.statusCode}');
    }
    return ChatEnvelope.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd adaptive_chat && fvm flutter test test/chat_backend_client_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add adaptive_chat/lib/src/chat_models.dart \
        adaptive_chat/lib/src/chat_backend_client.dart \
        adaptive_chat/test/chat_backend_client_test.dart
git commit -m "feat(chat): add wire models and backend client"
```

---

### Task 9: Conversation controller

**Files:**
- Create: `adaptive_chat/lib/src/conversation_controller.dart`
- Test: `adaptive_chat/test/conversation_controller_test.dart`

**Interfaces:**
- Consumes: `ChatBackendClient`, `ChatEnvelope`, `ChatStart` (Task 8); `SubmitActionInvoke` (core).
- Produces: `ChatMode { append, replace }`; `ConversationController extends ChangeNotifier` with fields `List<Map<String,dynamic>> messages`, `bool pending`, `ChatMode mode`, `int composeEpoch`, getter `bool ready`; methods `Future<void> startConversation()`, `Future<void> send(String text)`, `void toggleMode()`, `void clear()`.

- [ ] **Step 1: Write the failing controller test** — `adaptive_chat/test/conversation_controller_test.dart`

```dart
import 'dart:convert';

import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:adaptive_chat/src/conversation_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ChatBackendClient _clientReturning(List<Map<String, dynamic>> messages) {
  final mock = MockClient((req) async {
    if (req.url.path == '/conversations') {
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'links': {'postNext': '/conversations/c_1/interactions'},
        }),
        200,
      );
    }
    return http.Response(
      jsonEncode({
        'conversationId': 'c_1',
        'interactionId': req.headers['X-Interaction-Id'],
        'messages': messages,
        'links': {
          'self': '/conversations/c_1/interactions/x',
          'postNext': '/conversations/c_1/interactions',
        },
      }),
      200,
    );
  });
  return ChatBackendClient(baseUrl: Uri.parse('http://localhost:8000'), client: mock);
}

void main() {
  test('startConversation makes the controller ready and clears messages', () async {
    final c = ConversationController(client: _clientReturning([]));
    expect(c.ready, isFalse);
    await c.startConversation();
    expect(c.ready, isTrue);
    expect(c.messages, isEmpty);
  });

  test('send appends returned cards and bumps composeEpoch', () async {
    final c = ConversationController(
      client: _clientReturning([
        {'type': 'AdaptiveCard', 'body': []},
        {'type': 'AdaptiveCard', 'body': []},
      ]),
    );
    await c.startConversation();
    final epoch0 = c.composeEpoch;
    await c.send('hello');
    expect(c.messages.length, 2);
    expect(c.composeEpoch, greaterThan(epoch0));
    expect(c.pending, isFalse);
  });

  test('replace mode keeps only the latest interaction', () async {
    final c = ConversationController(
      client: _clientReturning([
        {'type': 'AdaptiveCard', 'body': []},
      ]),
    )..mode = ChatMode.replace;
    await c.startConversation();
    await c.send('one');
    await c.send('two');
    expect(c.messages.length, 1);
  });

  test('send does nothing before startConversation', () async {
    final c = ConversationController(client: _clientReturning([]));
    await c.send('hello');
    expect(c.messages, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat && fvm flutter test test/conversation_controller_test.dart`
Expected: FAIL — `conversation_controller.dart` does not exist.

- [ ] **Step 3: Implement `lib/src/conversation_controller.dart`**

```dart
import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Whether new interactions append to the log or replace it.
enum ChatMode {
  /// Keep the full history.
  append,

  /// Show only the latest interaction.
  replace,
}

/// Holds chat state and drives the [ChatBackendClient].
///
/// Ordinary Flutter state — Riverpod is reserved for the core library.
class ConversationController extends ChangeNotifier {
  /// Creates a controller backed by [client].
  ConversationController({required this.client});

  /// Backend transport.
  final ChatBackendClient client;

  /// Rendered bubble cards, oldest first.
  final List<Map<String, dynamic>> messages = [];

  /// True while a send is in flight (drives the pending indicator).
  bool pending = false;

  /// Append vs replace behavior.
  ChatMode mode = ChatMode.append;

  /// Bumped after each send so the compose card rebuilds empty.
  int composeEpoch = 0;

  String? _conversationId;
  String? _postNext;
  int _counter = 0;

  /// True once a conversation exists and sends are allowed.
  bool get ready => _postNext != null;

  /// Active conversation id, if any.
  String? get conversationId => _conversationId;

  /// Starts a new conversation and clears the log.
  Future<void> startConversation() async {
    final start = await client.startConversation();
    _conversationId = start.conversationId;
    _postNext = start.postNext;
    messages.clear();
    notifyListeners();
  }

  String _nextInteractionId() =>
      'i_${(++_counter).toString().padLeft(4, '0')}';

  /// Sends [text] and appends (or replaces with) the returned cards.
  Future<void> send(String text) async {
    final postNext = _postNext;
    if (postNext == null || text.trim().isEmpty || pending) {
      return;
    }
    pending = true;
    composeEpoch++;
    notifyListeners();
    try {
      final envelope = await client.sendInteraction(
        postNext: postNext,
        interactionId: _nextInteractionId(),
        invoke: SubmitActionInvoke(data: {'message': text}),
      );
      _postNext = envelope.postNext;
      if (mode == ChatMode.replace) {
        messages.clear();
      }
      messages.addAll(envelope.messages);
    } finally {
      pending = false;
      notifyListeners();
    }
  }

  /// Flips between append and replace.
  void toggleMode() {
    mode = mode == ChatMode.append ? ChatMode.replace : ChatMode.append;
    notifyListeners();
  }

  /// Clears the visible log (keeps the conversation).
  void clear() {
    messages.clear();
    notifyListeners();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd adaptive_chat && fvm flutter test test/conversation_controller_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add adaptive_chat/lib/src/conversation_controller.dart \
        adaptive_chat/test/conversation_controller_test.dart
git commit -m "feat(chat): add conversation controller"
```

---

### Task 10: Chat page UI (compose card, log, pending)

**Files:**
- Create: `adaptive_chat/lib/src/compose_card.dart`
- Create: `adaptive_chat/lib/src/chat_page.dart`
- Modify: `adaptive_chat/lib/main.dart`
- Test: `adaptive_chat/test/chat_page_test.dart`

**Interfaces:**
- Consumes: `ConversationController`, `ChatMode` (Task 9); `AdaptiveCardsCanvas`, `HostConfigs`, `InheritedAdaptiveCardHandlers`, `SubmitActionInvoke` (core).
- Produces: `composeCard` (a `Map<String,dynamic>` Adaptive Card with `Input.Text id="message"` + `Action.Submit id="send"`); `ChatPage({required ConversationController controller, required HostConfigs hostConfigs})`.

- [ ] **Step 1: Write the failing widget test** — `adaptive_chat/test/chat_page_test.dart`

```dart
import 'dart:async';
import 'dart:convert';

import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:adaptive_chat/src/chat_page.dart';
import 'package:adaptive_chat/src/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Card whose only TextBlock says [text], so tests can find it on screen.
Map<String, dynamic> _cardSaying(String text) => {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {'type': 'TextBlock', 'text': text, 'wrap': true},
      ],
    };

ChatBackendClient _client({Completer<void>? gate}) {
  return ChatBackendClient(
    baseUrl: Uri.parse('http://localhost:8000'),
    client: MockClient((req) async {
      if (req.url.path == '/conversations') {
        return http.Response(
          jsonEncode({
            'conversationId': 'c_1',
            'links': {'postNext': '/conversations/c_1/interactions'},
          }),
          200,
        );
      }
      if (gate != null) {
        await gate.future;
      }
      final message =
          (jsonDecode(req.body) as Map)['data']['message'] as String;
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'interactionId': req.headers['X-Interaction-Id'],
          'messages': [_cardSaying('you: $message')],
          'links': {
            'self': '/conversations/c_1/interactions/x',
            'postNext': '/conversations/c_1/interactions',
          },
        }),
        200,
      );
    }),
  );
}

Future<void> _pumpPage(WidgetTester tester, ConversationController c) async {
  await tester.pumpWidget(
    MaterialApp(home: ChatPage(controller: c, hostConfigs: HostConfigs())),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sent message appears as a bubble in the log', (tester) async {
    final c = ConversationController(client: _client());
    await c.startConversation();
    await _pumpPage(tester, c);

    await c.send('hello');
    await tester.pumpAndSettle();

    expect(find.text('you: hello'), findsOneWidget);
  });

  testWidgets('pending indicator shows while a send is in flight',
      (tester) async {
    final gate = Completer<void>();
    final c = ConversationController(client: _client(gate: gate));
    await c.startConversation();
    await _pumpPage(tester, c);

    final future = c.send('slow');
    await tester.pump(); // let pending=true propagate
    expect(find.byKey(const ValueKey('pending-bubble')), findsOneWidget);

    gate.complete();
    await future;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pending-bubble')), findsNothing);
  });

  testWidgets('replace mode shows only the latest message', (tester) async {
    final c = ConversationController(client: _client())..mode = ChatMode.replace;
    await c.startConversation();
    await _pumpPage(tester, c);

    await c.send('one');
    await tester.pumpAndSettle();
    await c.send('two');
    await tester.pumpAndSettle();

    expect(find.text('you: one'), findsNothing);
    expect(find.text('you: two'), findsOneWidget);
  });

  testWidgets('new-conversation button clears the log', (tester) async {
    final c = ConversationController(client: _client());
    await c.startConversation();
    await _pumpPage(tester, c);
    await c.send('hello');
    await tester.pumpAndSettle();
    expect(find.text('you: hello'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new-conversation')));
    await tester.pumpAndSettle();

    expect(find.text('you: hello'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd adaptive_chat && fvm flutter test test/chat_page_test.dart`
Expected: FAIL — `chat_page.dart` does not exist.

- [ ] **Step 3: Implement `lib/src/compose_card.dart`**

```dart
/// The compose box, authored as an Adaptive Card so its `Action.Submit`
/// flows through the host-invoke path just like an in-card form would.
Map<String, dynamic> composeCard() => {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'message',
          'placeholder': 'Type a message',
          'isMultiline': false,
        },
      ],
      'actions': [
        {'type': 'Action.Submit', 'id': 'send', 'title': 'Send'},
      ],
    };
```

- [ ] **Step 4: Implement `lib/src/chat_page.dart`**

```dart
import 'package:adaptive_chat/src/compose_card.dart';
import 'package:adaptive_chat/src/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// The chat screen: a scrolling log of server bubbles plus a compose card.
class ChatPage extends StatelessWidget {
  /// Creates the page bound to [controller].
  const ChatPage({
    required this.controller,
    required this.hostConfigs,
    super.key,
  });

  /// Chat state and transport.
  final ConversationController controller;

  /// Light/dark HostConfig used to render every card.
  final HostConfigs hostConfigs;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Adaptive Chat'),
            actions: [
              IconButton(
                key: const ValueKey('new-conversation'),
                tooltip: 'New conversation',
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: controller.startConversation,
              ),
              Row(
                children: [
                  const Text('Replace'),
                  Switch(
                    key: const ValueKey('mode-toggle'),
                    value: controller.mode == ChatMode.replace,
                    onChanged: (_) => controller.toggleMode(),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildLog(context)),
              const Divider(height: 1),
              _buildCompose(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLog(BuildContext context) {
    final itemCount = controller.messages.length + (controller.pending ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= controller.messages.length) {
          return const _PendingBubble(key: ValueKey('pending-bubble'));
        }
        final card = controller.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: AdaptiveCardsCanvas.map(
              content: card,
              hostConfigs: hostConfigs,
              showDebugJson: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompose(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InheritedAdaptiveCardHandlers(
        onSubmit: (invoke) {
          final text = invoke.data['message'] as String? ?? '';
          controller.send(text);
        },
        onExecute: (_) {},
        onOpenUrl: (_) {},
        onOpenUrlDialog: (_) {},
        onChange: (_) {},
        child: AdaptiveCardsCanvas.map(
          // Rebuild empty after each send.
          key: ValueKey('compose-${controller.composeEpoch}'),
          content: composeCard(),
          hostConfigs: hostConfigs,
          showDebugJson: false,
        ),
      ),
    );
  }
}

/// Three-dot "typing" indicator shown while a send is in flight.
class _PendingBubble extends StatelessWidget {
  const _PendingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Rewrite `lib/main.dart` to host `ChatPage`**

```dart
import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:adaptive_chat/src/chat_page.dart';
import 'package:adaptive_chat/src/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

void main() => runApp(const AdaptiveChatApp());

/// Root of the Adaptive Chat SDUI demo.
class AdaptiveChatApp extends StatefulWidget {
  /// Creates the app.
  const AdaptiveChatApp({super.key});

  @override
  State<AdaptiveChatApp> createState() => _AdaptiveChatAppState();
}

class _AdaptiveChatAppState extends State<AdaptiveChatApp> {
  late final ConversationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConversationController(
      client: ChatBackendClient(baseUrl: Uri.parse('http://localhost:8000')),
    );
    _controller.startConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Chat',
      theme: ThemeData(useMaterial3: true),
      home: ChatPage(controller: _controller, hostConfigs: HostConfigs()),
    );
  }
}
```

- [ ] **Step 6: Update the smoke test** — `adaptive_chat/test/smoke_test.dart`

The app now starts a network call on launch; assert the app bar title without settling network I/O:
```dart
import 'package:adaptive_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders the Adaptive Chat app bar', (tester) async {
    await tester.pumpWidget(const AdaptiveChatApp());
    await tester.pump();
    expect(find.widgetWithText(AppBar, 'Adaptive Chat'), findsOneWidget);
  });
}
```

- [ ] **Step 7: Run the page + smoke tests**

Run: `cd adaptive_chat && fvm flutter test test/chat_page_test.dart test/smoke_test.dart`
Expected: PASS (4 page tests + 1 smoke test).

- [ ] **Step 8: Commit**

```bash
git add adaptive_chat/lib/src/compose_card.dart adaptive_chat/lib/src/chat_page.dart \
        adaptive_chat/lib/main.dart adaptive_chat/test/chat_page_test.dart \
        adaptive_chat/test/smoke_test.dart
git commit -m "feat(chat): chat page with compose card, log, and pending indicator"
```

---

### Task 11: HostConfig theming + bubble polish

**Files:**
- Create: `adaptive_chat/lib/src/chat_host_config.dart`
- Modify: `adaptive_chat/lib/main.dart`
- Test: `adaptive_chat/test/chat_host_config_test.dart`

**Interfaces:**
- Consumes: `HostConfig`, `HostConfigs` (core).
- Produces: `chatHostConfigs() -> HostConfigs` — a light/dark pair whose container styles give the `accent` (user) and `emphasis` (assistant) bubbles readable fills.

- [ ] **Step 1: Inspect the container-style HostConfig shape**

Run: `grep -rn "class ContainerStylesConfig\|accent\|emphasis" packages/flutter_adaptive_cards_fs/lib/src/hostconfig/ | head`
Read the matching config classes so the next step uses real field names. (If the default `HostConfig()` already renders distinguishable accent/emphasis containers, keep this task minimal — a passing "constructs without throwing and current==light" test plus using `chatHostConfigs()` in `main.dart` is sufficient; deeper color overrides are optional polish.)

- [ ] **Step 2: Write the failing test** — `adaptive_chat/test/chat_host_config_test.dart`

```dart
import 'package:adaptive_chat/src/chat_host_config.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chatHostConfigs builds a light/dark pair defaulting to light', () {
    final configs = chatHostConfigs();
    expect(configs, isA<HostConfigs>());
    expect(configs.current, same(configs.light));
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd adaptive_chat && fvm flutter test test/chat_host_config_test.dart`
Expected: FAIL — `chat_host_config.dart` does not exist.

- [ ] **Step 4: Implement `lib/src/chat_host_config.dart`**

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// HostConfig pair for the chat demo.
///
/// Bubble fills come from the `accent` (user) and `emphasis` (assistant)
/// container styles. Start from the library defaults; override container-style
/// colors here if the defaults do not read as distinct bubbles (use the real
/// field names discovered in Step 1 of Task 11).
HostConfigs chatHostConfigs() {
  return HostConfigs(
    light: const HostConfig(),
    dark: const HostConfig(),
  );
}
```

- [ ] **Step 5: Use it in `main.dart`**

Replace `HostConfigs()` in `lib/main.dart` with `chatHostConfigs()` and add:
```dart
import 'package:adaptive_chat/src/chat_host_config.dart';
```
so the home line reads:
```dart
      home: ChatPage(controller: _controller, hostConfigs: chatHostConfigs()),
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd adaptive_chat && fvm flutter test test/chat_host_config_test.dart`
Expected: PASS (1 test).

- [ ] **Step 7: Commit**

```bash
git add adaptive_chat/lib/src/chat_host_config.dart adaptive_chat/lib/main.dart \
        adaptive_chat/test/chat_host_config_test.dart
git commit -m "feat(chat): host config for bubble theming"
```

---

## Phase 3 — VS Code run targets

Adds run/debug configurations to the existing `.vscode/launch.json` (which already has Widgetbook + Adaptive Explorer entries) and, where useful, `.vscode/tasks.json`. Config-only; no automated tests — verified by the targets appearing in the VS Code Run menu and launching.

### Task 19: VS Code launch configs for the chat app + server

**Files:**
- Modify: `.vscode/launch.json`
- Modify (optional): `.vscode/tasks.json`

- Add Flutter launch configs (type `dart`) for `adaptive_chat`, mirroring the existing Adaptive Explorer / Widgetbook entries:
  - `Adaptive Chat - Current` — `cwd: ${workspaceFolder}/adaptive_chat`, `program: lib/main.dart`.
  - `Adaptive Chat - Web` — adds `-d chrome`, `--web-port 3000`, `--web-browser-flag=--disable-web-security` (local CORS during dev, same pattern as `Widgetbook - Web`).
- Add a Python launch config for the FastAPI server (type `debugpy`): `python` = `${workspaceFolder}/adaptive_chat_server/.venv/bin/python`, `module` = `uvicorn`, `args` = `["app.main:app","--reload","--port","8000"]`, `cwd` = `${workspaceFolder}/adaptive_chat_server`.
- Add a `compounds` entry `Adaptive Chat (server + web)` launching the server config + the web app config together.
- Optionally add a `tasks.json` shell task `Run Adaptive Chat Server` (`.venv/bin/uvicorn app.main:app --reload --port 8000`, cwd `adaptive_chat_server`) as a non-debug alternative.
- Verify: `.vscode/launch.json` is valid JSON (`python -c "import json;json.load(open('.vscode/launch.json'))"`); the new configs appear in the Run menu (full launch is a manual VS Code step).
- **When Phase 4 lands**, add an `Adaptive Chat Server (Ollama)` config that passes `--ollama-url`.

---

## Phase 4 — Local Ollama integration (opt-in via CLI)

The original design anticipated this: `OllamaResponder` drops in behind the existing `Responder` interface. The server chooses its responder at startup from a command-line parameter; with no Ollama URL it stays the echo demo (existing behavior preserved).

### Task 20: OllamaResponder + CLI wiring

**Files:**
- Create: `adaptive_chat_server/app/ollama_responder.py`
- Create: `adaptive_chat_server/app/__main__.py` (CLI entrypoint + responder selection)
- Modify: `adaptive_chat_server/app/responder.py` (interface), `app/main.py` (responder injection seam), `app/store.py` (persist assistant reply text for history)
- Test: `adaptive_chat_server/tests/test_ollama_responder.py`, extend `tests/test_api.py`
- Docs: `adaptive_chat_server/README.md`

- **Responder interface:** extend `reply()` to receive prior conversation turns so a chat model has context — `reply(text: str, history: list[tuple[str, str]]) -> str`, each tuple `(role, text)` for a prior turn (`role` in `user`/`assistant`). `EchoResponder` ignores `history` (still returns `Did you just say: {text}`); adjust the `send_interaction` call site to pass history and keep the existing echo tests green.
- **Store:** persist the plain assistant reply text per interaction (alongside the user `text`) so the send route can rebuild `(user, assistant)` history for the responder — add a `reply_text` field to `Interaction` (or derive it).
- **OllamaResponder:** constructed with `ollama_url` + `model` (default e.g. `llama3.2`). `reply()` POSTs to `{ollama_url}/api/chat` with the history + current user text mapped to Ollama's `messages` (`{role, content}`, `stream: false`), returns the assistant `message.content`. Handle Ollama-unreachable gracefully (clear error or a short fallback string — decide at implementation).
- **CLI selection:** `python -m app --ollama-url http://localhost:11434 [--ollama-model llama3.2] [--port 8000]` parses args, builds the chosen responder (Ollama when `--ollama-url` is given, else `EchoResponder`), injects it into the app (module-level setter or `app.state`), and runs uvicorn. Without `--ollama-url`, the server is the echo demo. (Because `uvicorn app.main:app` can't take app args directly, the CLI entrypoint owns responder selection.)
- **Tests:** `OllamaResponder.reply()` with a mocked HTTP client (assert the POST body's `messages` shape to `{url}/api/chat` and that it returns the parsed content); responder-selection logic (URL present → OllamaResponder, absent → EchoResponder); echo path unchanged. Do NOT require a live Ollama in tests.
- **Docs:** `adaptive_chat_server/README.md` gains the `--ollama-url` usage, the model default, and the note that Ollama must be running locally.
- Verify: `cd adaptive_chat_server && .venv/bin/python -m pytest -v` all pass; a manual `python -m app --ollama-url http://localhost:11434` smoke against a real local Ollama is a human step.

---

## Final Task: Full verification

- [ ] **Step 1: Backend suite**

Run: `cd adaptive_chat_server && .venv/bin/python -m pytest -v`
Expected: all tests PASS. Record the pass count.

- [ ] **Step 2: Client analyze (from repo root)**

Run: `fvm flutter analyze`
Expected: `No issues found!` (or only pre-existing warnings unrelated to `adaptive_chat/`).

- [ ] **Step 3: Client test suite**

Run: `cd adaptive_chat && fvm flutter test`
Expected: all tests PASS. Record the pass count.

- [ ] **Step 4: Manual end-to-end smoke (document the result)**

Terminal 1:
```bash
cd adaptive_chat_server && .venv/bin/uvicorn app.main:app --port 8000
```
Terminal 2:
```bash
cd adaptive_chat && fvm flutter run -d macos   # or -d chrome
```
Type a message, press Send, confirm a right-aligned "you" bubble and a left-aligned "Did you just say: …" reply appear, and the pending indicator shows during the round-trip. Toggle Replace and confirm only the latest interaction remains. Tap New conversation and confirm the log clears.

- [ ] **Step 5: Invoke `superpowers:verification-before-completion`**

Paste the exit codes and pass/fail counts from Steps 1–3 before claiming the plan complete. Do not report success until the backend suite, `fvm flutter analyze`, and the client suite are all green.

---

## Self-review notes (verification of this plan)

- **Spec coverage:** start/send/replay endpoints (Tasks 4–6); POST-returns-cards+links envelope (Task 2); header-carried `interactionId` + idempotency (Task 5); compose-box-as-Adaptive-Card via host-invoke request path (Tasks 8, 10); server-authoritative messenger bubbles authored in JSON (Task 2); pending indicator + entrance animation (Task 10); append/replace toggle + new-conversation (Tasks 9, 10); in-memory store from day one (Task 1); FastAPI/Python + Flutter/host-package reuse (throughout); testing + gates (per-task + Final Task).
- **Deviation from spec (intentional):** the log uses `ListView.builder` with a per-item fade (not `AnimatedList`) — simpler and equally smooth; the append/replace contract is unchanged.
- **Naming consistency:** `postNext`, `X-Interaction-Id`, `messages`, `composeEpoch`, `ChatMode.{append,replace}`, `ChatBackendClient.{startConversation,sendInteraction}`, `ConversationController.{startConversation,send,toggleMode,clear,ready}` are used identically across every task that references them.
