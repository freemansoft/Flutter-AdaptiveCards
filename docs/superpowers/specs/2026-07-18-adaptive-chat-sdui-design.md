# Adaptive Chat — SDUI chat app + backend

_Design spec — 2026-07-18_

## Summary

Build an SDUI (server-driven UI) chat demo consisting of two new top-level
siblings in the repo, joined by a small HTTP contract:

- **`adaptive_chat_client/`** — a Flutter sample app (peer of `adaptive_explorer/`). A
  scrolling log of server-returned Adaptive Cards rendered as messenger bubbles,
  with a **compose box that is itself an Adaptive Card** (`Input.Text` +
  `Action.Submit`) wired through `flutter_adaptive_cards_host_fs`.
- **`adaptive_chat_server/`** — a Python **FastAPI** service (sibling folder,
  excluded from the Dart pubspec workspace). v1 is an **echo** server; it keeps
  conversation state in memory so a local Ollama responder can drop in later.

The goal is to **demonstrate the host-invoke patterns already built into the
library**: the user's typed text flows through the same `Action.Submit` →
PlainJson request path that in-card form submits will use later. The client stays
"dumb" — the server authors 100% of what appears on screen, including bubble
alignment and styling, entirely in Adaptive Card JSON.

## Goals

- A working local chat demo: type text → server responds → bubbles append.
- Server-authoritative rendering: the client renders only what the server returns.
  Bubble left/right alignment and fill are expressed **in the card JSON**
  (`ColumnSet` spacer columns + container styles), not by client-side role logic.
- Reuse `flutter_adaptive_cards_host_fs` for the **request side** (compose card is
  a real Adaptive Card); provide a small **custom response path** that appends
  returned cards to the log instead of patching the compose card.
- A clean, language-neutral wire contract that is Ollama-ready and lets in-card
  forms (later) post back to their own source URL with no new client code.
- "Make it look good": a polished pending indicator + append animation cover the
  request round-trip so the server-authoritative model never feels dead.

## Non-goals (designed-for, not built in v1)

- **In-card forms** posting back to their `self` URL. The envelope and
  per-card-`self` link are designed so this is a later, additive step.
- **Ollama integration.** v1 ships an `EchoResponder`; `OllamaResponder` drops in
  behind the same interface with no route or protocol change. **(Built in Phase 4 —
  see "Post-design additions" below.)**
- **Markdown/HTML-table → Adaptive `Table` conversion** and richer structured
  cards (movies, tables). Future server-side card authoring.
- **Persistent storage.** v1 state is in-memory and lost on server restart.

## Decisions locked during brainstorming

| Decision | Choice |
| --- | --- |
| Backend runtime | Python **FastAPI**, separate service |
| POST semantics | POST **returns the cards + `links`** (one round-trip); `self` GET endpoint still exists for replay |
| Compose box | **Is an Adaptive Card** (`Input.Text` + `Action.Submit`) — showcases the library |
| Who renders messages | **Server-authoritative** — client renders only server-returned cards; polished pending state |
| Backend state | **In-memory store from day one** (ready for Ollama context) |
| Log look | **Messenger bubbles** |
| Bubble alignment | **Authored in the card JSON** (`ColumnSet` + container styles); **no `role` on the wire** |
| Client architecture | **Reuse host transport (request side) + custom append sink** |

## Repo layout

```text
adaptive_chat_client/            # Flutter sample app (peer of adaptive_explorer/)
adaptive_chat_server/     # Python FastAPI service (NOT in the Dart workspace)
```

`adaptive_chat_client/` is an ordinary Flutter app, so `flutter_localizations` + `.arb`
are allowed there (it is not a published package). `adaptive_chat_server/` has its
own `requirements.txt` / `pyproject.toml` and README.

## Wire contract

**Base URL** (e.g. `http://localhost:8000`) is configured in the client. Every
`links` value in a response is a URL the client resolves against the base and
follows blindly — this keeps the client general and lets a future server route
different interactions to different endpoints.

### Endpoints

| Method & path | Purpose | Body / headers | Returns |
| --- | --- | --- | --- |
| `POST /conversations` | Start a session | — | `{ conversationId, links: { postNext } }` (optionally an initial `messages`) |
| `POST {postNext}` = `/conversations/{cid}/interactions` | Send one interaction | Header `X-Interaction-Id: <client id>`; body = PlainJson submit invoke | `200` + envelope |
| `GET {self}` = `/conversations/{cid}/interactions/{iid}` | Replay one interaction | — | envelope |

### Request body (the send)

The compose card's `Action.Submit`, serialized by the host package's PlainJson
adapter:

```json
{ "kind": "submit", "actionId": "send", "data": { "message": "What's the weather?" } }
```

- `conversationId` comes from the URL.
- `interactionId` is **client-generated per send** and carried in the
  **`X-Interaction-Id` header** — the compose card never has to know ids; the
  client injects them at send time.

### Response envelope (POST and GET)

```json
{
  "conversationId": "c_abc",
  "interactionId": "i_004",
  "messages": [
    { "type": "AdaptiveCard", "body": [ /* right-aligned "you" bubble */ ] },
    { "type": "AdaptiveCard", "body": [ /* left-aligned reply bubble */ ] }
  ],
  "links": {
    "self": "/conversations/c_abc/interactions/i_004",
    "postNext": "/conversations/c_abc/interactions"
  }
}
```

`messages` is an ordered array of **pre-styled Adaptive Cards**. The client renders
each full-width and stacked; the card's own `ColumnSet` + container style decides
left/right and fill.

### Idempotency & errors

- Because the client owns `interactionId`, a repeated POST with the **same id
  returns the stored envelope instead of reprocessing** — this buys back the
  double-submit protection given up by returning the body instead of a `302`.
- `400` missing `message` or `X-Interaction-Id`; `404` unknown
  conversation/interaction.
- **CORS** enabled for local dev (Flutter web/desktop → localhost).

### Bubble authoring (server-side)

A right-aligned "you" bubble is a `ColumnSet` of `[{ width: "stretch" (empty) },
{ width: "auto", items: [ accent-styled Container with the text ] }]`; a left
bubble swaps the column order and uses a default/emphasis container. Bubble fill
colors — and any rounded-corner tuning — live in the client **HostConfig**, which
the sample app owns.

## Components

### Backend — `adaptive_chat_server/`

- **`main.py`** — FastAPI app, CORS middleware, route wiring.
- **`store.py`** — `ConversationStore`: `dict[conversationId → Conversation]`;
  each `Conversation` holds ordered interactions keyed by `interactionId`, each
  with **role-tagged** messages + raw text. Roles are kept server-side (for
  Ollama context later) and never serialized to the client.
- **`cards.py`** — the **bubble builder**: text → pre-styled Adaptive Cards
  (right "you" bubble, left reply bubble). All look/alignment authored here.
- **`responder.py`** — `Responder` interface + `EchoResponder`
  ("Did you just say: …"). `OllamaResponder` drops in behind the same interface.
- **Routes** — `POST /conversations`; `POST /conversations/{cid}/interactions`
  (read `X-Interaction-Id`, parse PlainJson `data.message`, idempotency check,
  build bubbles, store, return envelope); `GET /conversations/{cid}/interactions/{iid}`.

### Client — `adaptive_chat_client/lib/`

- **`main.dart`** — MaterialApp, light/dark `HostConfig` (bubble colors + corner
  tuning).
- **`chat_page.dart`** — Scaffold: app bar (New conversation button;
  **Append⇄Replace toggle**), scrolling log (`AnimatedList`), pinned compose card.
- **`conversation_controller.dart`** — `ChangeNotifier` (normal Flutter state —
  **not** Riverpod; that is core-package-only). Holds base URL, `conversationId`,
  current `postNext`, the rendered message cards, `pending`, and mode. Methods:
  `startConversation`, `send`, `appendMessages`, `clear`.
- **`chat_backend_client.dart`** — the **append sink**. Reuses the host package's
  request side (compose card is a real Adaptive Card; `Action.Submit` → PlainJson
  request serialization) but provides its own response path: POST `postNext` with
  `X-Interaction-Id`, parse the **chat envelope**, hand `messages[]` to the
  controller. The host package's overlay-applier is **not** run on the compose
  card.
- **Compose card** — small Adaptive Card JSON (`Input.Text id="message"` +
  `Action.Submit id="send"`); submit calls `controller.send`.
- **Pending + append** — three-dot indicator in the reply slot while `pending`;
  bubbles animate in on arrival.
- **Append vs Replace** — Append is default; Replace shows only the latest
  interaction's messages.
- **Future hook (designed, not built):** each appended card that has its own
  actions gets wrapped with `AdaptiveCardBackendHandlers` pointed at its `self`
  URL, so in-card forms ride identical rails.

## Data flow (one send)

```text
compose Submit
  → controller.send(text)
  → chat_backend_client POST {postNext} (+ X-Interaction-Id, PlainJson body)
  → server: build bubbles, store interaction
  → 200 envelope
  → controller.appendMessages(messages[])
  → AnimatedList renders full-width bubbles
  → pending off
```

## Testing & gates

- **Backend (pytest):** endpoint tests (start / send / replay / idempotency /
  `400` / `404`) + `cards.py` unit tests (envelope shape, bubble alignment JSON).
- **Client (Flutter widget tests):** submit triggers a send; response appends as
  bubbles; Replace shows only the latest; pending shows/hides; New-conversation
  clears the log.
- **Repo gates:** both new dirs live **outside `packages/`**, so the per-package
  coverage floors and the `CHANGELOG.md` gate do **not** apply. We aim for **zero
  changes to any published package** — the client only *uses*
  `flutter_adaptive_cards_host_fs` via its exported client interface. If an
  unavoidable package tweak surfaces, that change picks up the changelog gate.

## Open questions / risks

- **Bubble corners.** Rounded bubble corners depend on what HostConfig/container
  rendering exposes; rectangular is the default. Tunable during polish, not a
  blocker.
- **Partial transport reuse.** Because the chat response shape differs from the
  host package's invoke-response effects, reuse is on the **request** side plus a
  custom response path — not the package's overlay applier. This is intended, but
  worth confirming during implementation that no host-package change is required.

## Post-design additions (built)

The demo shipped with scope added after this design. The full, current
architecture lives in the app READMEs — treat those as the composite reference:

- **[`adaptive_chat_client/README.md`](../../../adaptive_chat_client/README.md)** — client architecture (SDUI model, compose-as-Adaptive-Card, `ChatBackendClient` / `ConversationController` / `ChatPage`, the wire contract, rounded bubbles).
- **[`adaptive_chat_server/README.md`](../../../adaptive_chat_server/README.md)** — server architecture (bubble authoring, envelope + idempotency, in-memory store, responder seam, Ollama).

Additions beyond the original chat design:

1. **Rounded bubbles → core-library feature.** The "Open questions" item on rounded corners was resolved by adding Teams **`roundedCorners`** support to `flutter_adaptive_cards_fs` across **Container, ColumnSet, Column, Table, Image**, with the radius resolved via a new `HostConfig.cornerRadius` (default 8) / `ReferenceResolver.resolveCornerRadius()`. The chat bubbles opt in server-side (`roundedCorners: true`) and the client uses a 16 px radius. See [`docs/hostconfig.md`](../../hostconfig.md) (Microsoft Teams HostConfig extensions) and the package README status rows. A widgetbook knob demo (`roundedCorners` toggle + `cornerRadius` slider) showcases it.
2. **Local Ollama integration (opt-in).** `python -m app --ollama-url …` selects an `OllamaResponder` (conversation history → `/api/chat`) behind the existing `Responder` seam; no URL → the echo demo. See the server README.
3. **VS Code run targets** for the app (Current/Web), the echo server, the Ollama server, and server+web compounds (`.vscode/launch.json`).
4. **Generated Flutter platform folders** for `adaptive_chat_client` (checked in, matching `adaptive_explorer`).

Implementation phases for (2) and (3) are in the plan: [`docs/superpowers/plans/2026-07-18-adaptive-chat-sdui.md`](../plans/2026-07-18-adaptive-chat-sdui.md) (Phase 3 — VS Code run targets, Phase 4 — Ollama).

### Ollama integration (Phase 4) — design

Opt-in, behind the `Responder` seam the original design anticipated. The echo demo
is preserved byte-for-byte when no Ollama URL is supplied.

- **History-aware responder.** `Responder.reply` becomes
  `reply(text: str, history: list[tuple[str, str]]) -> str`, where `history` is the
  ordered prior turns as `(role, content)` (`role` in `user`/`assistant`).
  `EchoResponder` ignores `history`. The send route builds `history` from the
  conversation's stored interactions before calling the responder; the idempotent
  replay short-circuit stays **before** that call, so a duplicate interaction never
  re-invokes the model.
- **Store keeps reply text.** `Interaction` gains a plain `reply_text` field
  (alongside the user `text`) so `(user, assistant)` history can be rebuilt — the
  role-tagged bubble cards alone aren't a convenient history source.
- **`OllamaResponder(ollama_url, model="llama3.2", client=None)`.** Maps
  `history + current turn` to Ollama `messages` (`[{role, content}, …]`) and POSTs
  `{ollama_url}/api/chat` with `stream: false`, returning `message.content`. On any
  `httpx.HTTPError` (connection refused / timeout / non-2xx) it returns a short
  `"(Ollama unreachable at {url})"` string rather than failing the request. The
  `httpx` client is injectable so tests use `httpx.MockTransport` — no live Ollama.
- **Selection + CLI.** `build_responder(ollama_url, model)` returns an
  `OllamaResponder` when a URL is present, else `EchoResponder`. `main.py` builds the
  responder at import from `OLLAMA_URL` / `OLLAMA_MODEL`. `python -m app`
  (`app/__main__.py`) parses `--ollama-url` / `--ollama-model` / `--host` / `--port`,
  sets those env vars (which survive uvicorn's `--reload` subprocess re-import), and
  runs uvicorn. No new dependencies (`httpx` was already present).
- **Non-goals (still).** No streaming responses, no tool/function calling, no model
  management (the operator runs `ollama serve` + `ollama pull`), no auth.
