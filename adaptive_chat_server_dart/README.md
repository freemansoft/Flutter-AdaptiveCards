# adaptive_chat_server_dart

A Dart/`shelf` backend for the **Adaptive Chat** SDUI demo. It authors the
chat bubbles as Adaptive Cards, keeps conversation state in memory, and
answers either with a simple **echo** (default) or a local **Ollama** chat
model. Pairs with the Flutter client in
[`../adaptive_chat_client`](../adaptive_chat_client).

This package started as a wire-compatible port of an earlier Python/FastAPI
prototype; that prototype has since been removed, and this Dart
implementation is now the only backend.

Design notes: [`docs/superpowers/specs/2026-08-09-adaptive-chat-server-dart-design.md`](../docs/superpowers/specs/2026-08-09-adaptive-chat-server-dart-design.md).

## Architecture

The server is **authoritative for everything on screen**: it emits pre-styled
Adaptive Cards and the client renders them verbatim. Bubble alignment, fill,
and rounded corners live in the card JSON, so the look is a server concern.

```mermaid
flowchart TB
  subgraph server["adaptive_chat_server_dart (shelf)"]
    ROUTES["app.dart routes\nPOST /conversations\nPOST .../interactions\nGET .../interactions/{iid}\nGET /status"]
    STORE["store.dart · ConversationStore\nConversation(order, interactions)\nInteraction(text, messages, replyText)"]
    CARDS["cards.dart · bubble authoring\nColumnSet(stretch spacer) + Container(style, roundedCorners)\nuserBubble(accent, right) · assistantBubble(emphasis, left)"]
    RESP["responder.dart · Responder(reply(text, history))"]
    ECHO["EchoResponder\n'Did you just say: ...'"]
    OLLAMA["ollama_responder.dart · OllamaResponder\nPOST {url}/api/chat"]
    PROMPT["assets/default_system_prompt.txt\n(or --system-prompt-file)\nre-read per request"]
    ROUTES --> STORE
    ROUTES --> CARDS
    ROUTES --> RESP
    RESP -. buildResponder(--ollama-url) .-> ECHO
    RESP -. buildResponder(--ollama-url) .-> OLLAMA
    PROMPT -. system message .-> OLLAMA
  end
  CLIENT["adaptive_chat_client (Flutter)"] -->|"POST interaction (X-Interaction-Id, PlainJson body)"| ROUTES
  ROUTES -->|"envelope: messages[] + links"| CLIENT
  OLLAMA -->|"messages (system + history + turn)"| LLM["local Ollama\n/api/chat"]
```

### Wire contract

| Method & path                                 | Purpose                        | In                                                                | Out                                       |
| --------------------------------------------- | ------------------------------ | ----------------------------------------------------------------- | ----------------------------------------- |
| `POST /conversations`                         | Start a session                | —                                                                 | `{ conversationId, links: { postNext } }` |
| `POST /conversations/{cid}/interactions`      | Send one interaction           | header `X-Interaction-Id`; PlainJson invoke body (`data.message`) | `200` + **envelope**                      |
| `GET /conversations/{cid}/interactions/{iid}` | Replay one interaction         | —                                                                 | **envelope**                              |
| `GET /status`                                 | Server + conversation snapshot | —                                                                 | **status payload**                        |

**Envelope:** `{ conversationId, interactionId, messages: [<AdaptiveCard>, ...], links: { self, postNext } }`.
`messages` is an ordered list of pre-styled cards (a right-aligned "you" bubble
and a left-aligned reply bubble). **Idempotent by `X-Interaction-Id`:** a
repeated id returns the stored envelope without re-running the responder —
including a retry that arrives while the first call is _still running_, which
joins the in-flight call and answers with its result rather than starting a
second one.

### Components (`lib/src/`)

| File                               | Responsibility                                                                                                                                                                 |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `app.dart`                         | shelf `Router`, CORS middleware, the `buildResponder`/`buildHandler` factories used by `bin/server.dart`.                                                                      |
| `store.dart`                       | In-memory `ConversationStore`; `Interaction` keeps the user `text`, the rendered `messages`, and the plain `replyText` (so chat history can be rebuilt).                       |
| `cards.dart`                       | Bubble authoring: `userBubble` (accent, right), `assistantBubble` (emphasis, left, Markdown text), `assistantCardBubble` (emphasis, left, embedded card), and `envelope(...)`. |
| `responder.dart`                   | `Reply(text, cardBody, stats)`, the `Responder` interface (`Future<Reply> reply(text, history)`, `describe()`), and `EchoResponder`.                                           |
| `card_detect.dart`                 | `tryParseCardBody(raw) -> List<Map>?` — strict text-vs-card detection (see **Card replies** below).                                                                            |
| `stats.dart`                       | `InteractionStats` — one Ollama turn's token counts and timing breakdown; `fromOllamaResponse`, `statsToJson`.                                                                 |
| `status.dart`                      | `buildStatus(store, responder)` — assembles the `GET /status` payload.                                                                                                         |
| `ollama_responder.dart`            | `OllamaResponder` — system prompt, history trim, `POST /api/chat`, card-vs-text detection, duplicate-JSON-key guard, diagnostic error strings.                                 |
| `assets/default_system_prompt.txt` | Bundled default system prompt.                                                                                                                                                 |
| `assets/card_system_prompt.txt`    | Bundled **card** system prompt — select via `--system-prompt-file assets/card_system_prompt.txt`.                                                                              |
| `assets/card_schema.json`          | Bundled schema for `--json-format schema`.                                                                                                                                     |
| `cli.dart`                         | `buildArgParser()` / `resolveLogLevel()` — the flag set, defaults, and allowed values. In `lib/` so the CLI surface is reachable from tests.                                   |
| `bin/server.dart`                  | CLI entrypoint (`dart run bin/server.dart ...`) that selects the responder from `--ollama-url` and starts `shelf_io.serve`.                                                    |

### Responder selection

`buildResponder(...)` returns an `OllamaResponder` when `--ollama-url` is
given, otherwise an `EchoResponder`.

### Conversation context

Server state is **keyed by `conversationId`** — the top level of
`ConversationStore` is a map of `cid -> Conversation`, and each `Conversation`
holds its `Interaction`s keyed by `interactionId`. So it is a **two-level key**
(`cid` -> `iid`): the client-supplied `X-Interaction-Id` namespace is scoped
**inside** one conversation, and the same `i_0001` can exist in two
conversations without collision. All state is in-memory and lost on restart
(fine for a demo; not shared across worker processes).

**How history reaches the model.** On each `POST …/interactions`, the route
rebuilds the conversation's history from the store — walking
`conversation.order` and emitting a `(user, text)` / `(assistant, replyText)`
pair per prior interaction — and passes it to `responder.reply(text, history)`
with the **full** history. `OllamaResponder` then sends **system prompt +
history + current turn** to `/api/chat` (see the request-flow diagrams above)
— trimmed to a recent window as described next. Because history is built from
one conversation's `order`, each `conversationId` gets an independent context.

**Retained in full; trimmed only on send.** The store keeps the **entire**
conversation (durable log + idempotent replay). What is bounded is only the
prompt **sent to Ollama**: `OllamaResponder` replays just the last
`--history-turns` exchanges (default 10). Nothing is pruned from the store, so
raising `--history-turns` or `--num-ctx` later needs no data migration.

**Failed turns are excluded.** When a turn fails (Ollama unreachable, timed
out, an HTTP error, or an unreadable response), the user still sees the
diagnostic bubble and the interaction is still stored and replayable — but the
whole exchange is **skipped** when history is rebuilt for the next request.
Otherwise the model would read `"(Ollama unreachable …)"` as something it once
said and carry that into every later turn. The exchange is dropped whole
rather than user-turn-only, so the model is never left an unanswered question
to explain.

**Startup preflight.** When `--ollama-url` is set, the server asks Ollama for
its model list (`/api/tags`) before serving and logs the result: an `INFO`
line naming the model when all is well, or a `SEVERE` line distinguishing
"Ollama unreachable" from "model not pulled" (with the `ollama pull` command
and the list of models that _are_ available). It **starts either way** — an
Ollama brought up after the server still works — but the operator learns
about a misconfiguration at launch rather than on the first message.

**Reply timeout.** `--ollama-timeout` (seconds, default 60) bounds one
`/api/chat` call. It is sized for a model **load**, not a **download**:
`/api/chat` never pulls a missing model (it 404s, which the preflight above
catches first), so the budget only covers reading an already-present model
into memory and generating one reply — a minutes-long `ollama pull` is
out-of-band and never waited on here. A cold load of a large model plus a
full context window can still exceed 60s; raise the flag rather than assuming
the server is unreachable. The effective value is reported by `GET /status`
as `timeoutSeconds`.

**Model residency.** Every request sends `keep_alive` (default `30m`,
`--keep-alive`), overriding Ollama's 5-minute default. An idle chat otherwise
pays a full model reload on its next message — measured at roughly 20× the
warm load time on a 7B model. `--keep-alive 0` unloads immediately;
`--keep-alive -1` keeps the model resident indefinitely.

**Context-fill logging.** The server sends an explicit `options.num_ctx`
(default 16384) and, after each reply, logs the actual prompt tokens
(`prompt_eval_count`) against that window: an `INFO` line at ≥ 50% fill and a
`WARNING` at ≥ 76% (leaving headroom for the generated reply). This surfaces
the otherwise-silent truncation Ollama performs once a prompt exceeds
`num_ctx`. (`EchoResponder` ignores history entirely — it only echoes the
current turn.)

### System prompt

Every Ollama request is prefixed with a `{"role": "system", ...}` message so
the model's behavior and output formatting can be tuned without code changes.
The prompt text comes from a file:

- **Source.** `--system-prompt-file <path>`. When omitted, the bundled
  [`assets/default_system_prompt.txt`](assets/default_system_prompt.txt) is
  used.
- **Live reload.** The file is re-read on **every request**, so editing the
  active prompt file takes effect on the next turn without restarting the
  server.
- **Missing / empty is not fatal.** If the file is unreadable or blank, the
  server logs a warning and sends the request with **no** system message
  rather than failing the chat.
- **Formatting guidance.** Replies render inside an Adaptive Cards
  `TextBlock`, which supports GitHub-flavored Markdown (headings,
  bold/italic, links, lists, blockquotes, inline/fenced code, and tables).
  The default prompt tells the model to keep replies concise and to use
  tables sparingly, since bubbles are narrow.
- **Echo mode ignores it.** The system prompt only applies to
  `OllamaResponder`; `EchoResponder` never sends anything to a model.

### Card replies (display-only)

Instead of Markdown text, the model may answer with an Adaptive Card fragment
that gets embedded directly in the assistant bubble (`assistantCardBubble`),
using the same alignment/fill/rounded-corner chrome as a text reply. Which
shape wins is decided per reply by `card_detect.dart`'s `tryParseCardBody`:
the **entire** message must be a full `{"type": "AdaptiveCard", "body": [...]}`
object or a bare, non-empty JSON array of objects, or it's rendered as
Markdown text instead.

To opt in, select the bundled card system prompt:

```bash
fvm dart run bin/server.dart --ollama-url http://127.0.0.1:11434 \
  --system-prompt-file assets/card_system_prompt.txt
```

The card prompt's palette is intentionally small:

- **Inputs** — `Input.Date`, `Input.ChoiceSet` (`style: compact` /
  `expanded`, `isMultiSelect`), `Input.Text`, `Input.Number`, `Input.Time`.
- **Display** — `TextBlock`, `FactSet`, `Badge`, `Carousel`, `Table`,
  `Rating`, `Icon`, `ProgressBar`, `ProgressRing`, `CodeBlock`, `Image`.

**Display-only.** The prompt forbids `Action`/`ActionSet` elements, so the
card fragment carries no submit button of its own, and any values a user
enters into its inputs do not post back to the server — the fragment is
render-only for now.

### Structured output (`--json-format`)

By default (`--json-format none`), card JSON comes from prompt engineering
alone. With a capable model (e.g. `qwen2.5-coder:7b`) at temperature 0 —
which the server sends on every request — the prompt reliably produces valid
cards, so no `format` constraint is needed.

```bash
fvm dart run bin/server.dart --ollama-url http://127.0.0.1:11434 \
  --json-format none   # default; try --json-format schema or --json-format json
```

- `none` (default) — prompt-only, no `format` field sent. Reliable with a
  capable model at temperature 0.
- `json` — constrains syntax only (any valid JSON value); shape is still
  checked by `card_detect.dart` after parsing.
- `schema` — constrains both syntax and the outer reply shape via Ollama's
  `format` field against `assets/card_schema.json` (a small schema covering
  exactly the shapes `tryParseCardBody` accepts). A safety net for
  weaker/other models, at some latency cost.

### Status endpoint

`GET /status` is a read-only operator snapshot, rendered **indented**
(`JsonEncoder.withIndent('  ')`) for human `curl`/browser reading; the chat
routes stay compact. Example payload:

```json
{
  "responder": {
    "kind": "ollama",
    "url": "http://127.0.0.1:11434",
    "model": "qwen2.5-coder:7b",
    "numCtx": 16384,
    "historyTurns": 10,
    "jsonFormat": "none",
    "systemPromptFile": "default_system_prompt.txt",
    "keepAlive": "30m",
    "timeoutSeconds": 60
  },
  "conversationCount": 1,
  "conversations": [
    {
      "conversationRef": "9f2a7c1e4b03",
      "interactionCount": 1,
      "totals": { "promptTokens": 120, "replyTokens": 45, "totalTokens": 165 },
      "lastInteraction": {
        "stats": {
          "promptTokens": 120,
          "replyTokens": 45,
          "totalTokens": 165,
          "totalMs": 900,
          "loadMs": 0,
          "promptEvalMs": 100,
          "evalMs": 800,
          "tokensPerSecond": 56.3
        }
      }
    }
  ]
}
```

No message text and no usable conversation id appear in this payload —
`conversationRef` is a truncated sha256 of the conversation id, and
`systemPromptFile` is reduced to a bare filename. Unauthenticated, CORS
`allow_origins: *` — fine bound to `127.0.0.1` (the default); binding to
`0.0.0.0` would expose configuration metadata and conversation-volume data to
the network.

### Request flow

```mermaid
---
title: "Ollama interaction — route to envelope"
---
sequenceDiagram
    autonumber
    participant C as adaptive_chat_client (Flutter)
    participant R as buildHandler route (app.dart)
    participant S as ConversationStore (store.dart)
    participant O as OllamaResponder
    participant L as local Ollama service /api/chat
    participant K as cards.dart (bubble + envelope authoring)

    C->>R: POST /conversations/{cid}/interactions<br/>X-Interaction-Id + body.data.message
    alt missing X-Interaction-Id
        R-->>C: 400 header required
    else missing conversation
        R->>S: get(cid)
        S-->>R: null
        R-->>C: 404 unknown conversation
    else already-seen id (idempotent replay)
        R->>S: getInteraction(cid, iid)
        S-->>R: stored Interaction
        R->>K: envelope(cid, iid, stored.messages)
        R-->>C: 200 envelope (responder NOT re-run)
    else new interaction
        R->>R: read body.data.message (else 400)
        R->>S: walk conversation.order
        S-->>R: prior (user, assistant) pairs = full history
        R->>O: reply(message, history)
        O->>O: load system prompt (per request) + trim history
        O->>L: POST /api/chat<br/>{system + history + turn, num_ctx, temperature:0, think:false}
        L-->>O: message.content (or failure -> diagnostic text)
        O-->>R: Reply(text, cardBody)
        alt cardBody is not null
            R->>K: assistantCardBubble(cardBody)
        else plain text reply
            R->>K: assistantBubble(text)
        end
        R->>K: userBubble(message)
        R->>S: addInteraction(text, messages, replyText)
        R->>K: envelope(cid, iid, messages)
        R-->>C: 200 envelope (user + assistant bubbles)
    end
```

```mermaid
---
title: "OllamaResponder.reply — system prompt, history, card detection"
---
sequenceDiagram
    autonumber
    participant R as Route
    participant O as OllamaResponder
    participant F as system-prompt file<br/>assets/default_system_prompt.txt or --system-prompt-file
    participant L as local Ollama /api/chat
    participant D as card_detect.dart tryParseCardBody

    R->>O: reply(text, history)
    O->>F: _loadSystemPrompt() — read file (per request)
    alt readable and non-empty
        F-->>O: prompt text
        O->>O: messages = [ {role: system, content: prompt} ]
    else missing / unreadable / empty
        F-->>O: exception or ""
        O->>O: log warning, send NO system message
    end
    O->>O: _trimHistory() — keep last historyTurns exchanges
    O->>O: messages += history + {role: user, content: text}
    O->>L: POST /api/chat<br/>{model, messages, stream:false, num_ctx,<br/>temperature:0, think:false, + format (json/schema modes only)}
    alt transport failure (connection / DNS / timeout)
        L--xO: exception
        O-->>R: Reply("(Ollama unreachable ...)", cardBody=null)
    else HTTP status >= 400 (e.g. 404 model not pulled)
        L-->>O: error status + body
        O-->>R: Reply("(Ollama error HTTP ...)", cardBody=null)
    else 2xx but unexpected body
        L-->>O: JSON without message.content
        O-->>R: Reply("(unexpected response)", cardBody=null)
    else 2xx success
        L-->>O: {message.content, prompt_eval_count}
        O->>O: _logContextFill() — INFO >= 50%, WARNING >= 76%
        opt json / schema mode (not the default none)
            O->>O: jsonDecode(content) with duplicate-key guard
        end
        O->>D: tryParseCardBody(content, or the format-parsed JSON)
        alt whole reply is a card fragment
            D-->>O: body items (list)
            O-->>R: Reply(text, cardBody=items)
        else prose / not a card / duplicate-key
            D-->>O: null
            O-->>R: Reply(text, cardBody=null)
        end
    end
```

## Run

```bash
fvm dart pub get
fvm dart run bin/server.dart
fvm dart run bin/server.dart --help   # every flag, with defaults
```

`--help` (or `-h`) prints the full flag list and exits without starting a
server; an unrecognised flag prints the same usage and exits `2`.

CORS is enabled for local dev so the Flutter web client can reach it.

**macOS: allow Chrome on the local network.** The first time the Flutter web
client (running in Chrome) calls this server, macOS may silently block the
connection until Chrome is enabled under **System Settings → Privacy &
Security → Local Network**. If the app loads but every send fails with a
connection error, toggle **Google Chrome** on there.

**macOS native client** (`adaptive_chat_client` run with `-d macos`) hits the
same "unable to connect" symptom for a _different_ reason: its App Sandbox
needs the `com.apple.security.network.client` entitlement to make outbound
calls. That is enabled in the client's `macos/Runner/*.entitlements`; see the
client's [`README`](../adaptive_chat_client/README.md#run) — it requires a
full rebuild, not the system-settings toggle above.

## Test

```bash
fvm dart test
```

Covers the store, bubble authoring, the routes (start/send/replay/status,
idempotency, validation), responder selection, card detection, token-stats
capture and the status payload, and the Ollama responder (mocked HTTP — no
live Ollama).

## Ollama (optional)

By default the server runs the echo demo (every reply is `"Did you just say:
..."`). To answer with a local [Ollama](https://ollama.com) chat model
instead:

```bash
ollama pull qwen2.5-coder:7b   # once, if you haven't already (the default model)
ollama serve                   # if it isn't already running

fvm dart run bin/server.dart --ollama-url http://127.0.0.1:11434 [--ollama-model qwen2.5-coder:7b]
```

**Use `127.0.0.1`, not `localhost`.** With Ollama's "expose to the network"
setting off, Ollama binds IPv4 `127.0.0.1` only; on macOS `localhost` often
resolves to IPv6 `::1` first, so `http://localhost:11434` fails to connect
even though Ollama is running.

**Diagnostics.** Every reply logs to the server console: the selected
responder at startup, each outgoing `POST …/api/chat`, and — on failure —
the exception. Failures are reported distinctly rather than all as
"unreachable": a connection failure returns `"(Ollama unreachable at … —
<error>)"`, a **timeout** (Ollama is alive but slow — usually a cold model
load or a long generation) returns `"(Ollama timed out after Ns at …)"`, an
HTTP error (e.g. the model isn't pulled → 404) returns `"(Ollama error HTTP
404 at …: <body>)"`, and an unexpected 2xx body returns `"(Ollama returned an
unexpected response: …)"`.

None of these diagnostics is threaded back into the conversation — see
**Failed turns** under Conversation context.

```bash
fvm dart run bin/server.dart --ollama-url http://127.0.0.1:11434 \
  --system-prompt-file assets/card_system_prompt.txt \
  --json-format none \
  --num-ctx 16384 \
  --history-turns 10 \
  --port 8000
```

- `--num-ctx` (default 16384) — context window sent as `options.num_ctx`.
- `--history-turns` (default 10) — prior exchanges replayed to the model.
- `--json-format` (default `none`) — `none`/`json`/`schema`.
- `--host`/`--port` default to `127.0.0.1`/`8000`. `--log-level` defaults to
  `info`; use `debug` to see the raw model response content and
  card-detection result for each turn.

Omit `--ollama-url` to keep the echo demo.
