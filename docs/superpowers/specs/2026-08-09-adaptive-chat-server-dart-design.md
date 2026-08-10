# adaptive_chat_server_dart — Dart port of the Adaptive Chat backend

**Date:** 2026-08-09
**Component:** `adaptive_chat_server_dart/` (new top-level demo backend; not a
published package under `packages/`)

## Problem

This repository's stated goal is **all Dart and Flutter** for executable
programs, examples, and libraries. `adaptive_chat_server` — the backend half of
the Adaptive Chat SDUI demo — is a Python/FastAPI service, the one non-Dart
executable in the repo. It has no Dart equivalent, so anyone building or running
the demo needs a Python toolchain (`venv`, `pip`) alongside `fvm`/Dart, and the
demo's backend can't share code, tooling, or CI patterns with the rest of the
workspace.

`adaptive_chat_server` is well-specified: a thorough README (architecture
diagram, wire contract, two sequence diagrams, component table) and ~1800 lines
of tests across 9 files already document its exact behavior. That specification
is the input to this port — not a redesign.

## Goals

- A new `adaptive_chat_server_dart/` app, functionally identical to
  `adaptive_chat_server`: same routes, same JSON wire shapes (the existing
  `adaptive_chat_client` must work against either backend with zero client
  changes), same CLI flags/defaults/help text intent, same responder behaviors
  (echo, Ollama — including card detection, history trimming, context-fill
  logging, structured-output modes, diagnostic error strings), same `/status`
  payload.
- Own bundled prompt files (`default_system_prompt.txt`, `card_system_prompt.txt`)
  and `card_schema.json`, resolved the same way the Python version resolves
  them — relative to the running server's own source location, not the process
  `cwd` — so behavior doesn't depend on where the server is launched from.
- A README at the same depth as `adaptive_chat_server/README.md` — architecture
  diagram, wire contract, component table, both sequence diagrams, `/status`
  example, System prompt / Card replies / Structured output sections, Run/Test
  instructions.
- A test suite that mirrors the Python suite file-for-file and case-for-case, so
  parity is checkable line by line, not just "it starts and echoes."
- Resolves standalone (own `pubspec.yaml`/`pubspec.lock`, `dart pub get` from
  within the package directory) — **not** a member of the root pub workspace.
  See the Decisions table and the CI correction note below for why.

## Non-goals

- **Not a cutover.** `adaptive_chat_server` (Python) is untouched — not deleted,
  not deprecated in docs, its CI job keeps running. This plan stands the Dart
  server up _alongside_ it. Retiring the Python version (deleting it, rewriting
  the root README's chat section, `.github/workflows/adaptive_chat.yml`,
  `.vscode/launch.json`) is an explicit follow-up once parity is proven, not
  part of this work.
- **Not a redesign.** No new routes, flags, or behaviors beyond what
  `adaptive_chat_server` already has. Anything that looks like an improvement
  opportunity (e.g., persistence, auth, a different card-fragment grammar) is
  out of scope.
- **No `--reload` flag.** `python -m app`'s own argparse doesn't expose one
  either (it's only used in the raw `uvicorn app.main:app --reload` dev
  invocation) — nothing to port.
- **No compiled-executable asset bundling.** Prompt/schema resolution only needs
  to work for `dart run bin/server.dart` (source-tree invocation), the same
  scope as the Python original, which is never compiled/relocated either.
- **No coverage-floor gate.** `tool/coverage_floors.yaml` covers `packages/*`
  only; apps like `adaptive_chat_client` aren't gated by it, and neither is
  this.

## Decisions

| Decision                    | Choice                                                                       | Rationale                                                                                                                                                                                                                                                                                                |
| --------------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| HTTP framework              | `shelf` + `shelf_router`                                                     | Idiomatic Dart ecosystem choice; composable middleware gives an easy CORS seam and closely mirrors FastAPI's route-handler ergonomics.                                                                                                                                                                   |
| Location                    | `adaptive_chat_server_dart/` at repo root                                    | Sibling to `adaptive_chat_server` / `adaptive_chat_client`, not under `packages/` — it's a demo app, not a published library.                                                                                                                                                                            |
| Workspace membership        | Standalone — **not** added to root `pubspec.yaml`'s `workspace:` list        | Reversed after the PR's first CI run (see the CI section's correction note): pub workspaces resolve as one unit, and this is the only member with zero Flutter dependency — joining it would force every resolution (CI included) to install the full Flutter SDK solely to satisfy the _other_ members. |
| CLI parsing                 | `args`                                                                       | Direct analog of Python's `argparse`; same flag names, defaults, and choices.                                                                                                                                                                                                                            |
| Ollama HTTP client          | `http`, mockable via `package:http/testing.dart`'s `MockClient`              | Direct analog of the Python tests' mocked `httpx.Client`/`MockTransport` — no live Ollama needed in tests.                                                                                                                                                                                               |
| Logging                     | `logging` package → stdout, level from `--log-level`                         | `debug` surfaces raw model content + card-detection result, mirroring `logger.debug` in `ollama_responder.py`.                                                                                                                                                                                           |
| `conversationRef` hashing   | `crypto` (sha256)                                                            | Same algorithm as Python's `hashlib.sha256(...).hexdigest()[:12]`.                                                                                                                                                                                                                                       |
| CORS                        | Small hand-rolled shelf middleware (`allow_origins: *`, handles `OPTIONS`)   | ~10 lines; avoids a dependency for behavior this narrow and keeps full control to match FastAPI's `CORSMiddleware(allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])` exactly.                                                                                                               |
| Asset resolution            | Relative to `bin/server.dart` via `Platform.script`, walking up to `assets/` | Dart analog of Python's `Path(__file__).with_name(...)` — cwd-independent, matching `python -m app`'s behavior regardless of launch directory.                                                                                                                                                           |
| Env-var config bridging     | None                                                                         | Existed in Python solely so config survived uvicorn's `--reload` subprocess re-import. Not applicable — `--reload` isn't ported (see Non-goals), and Dart has no equivalent reload boundary to cross.                                                                                                    |
| Retirement of Python server | Deferred                                                                     | Confirmed with the user: stand up alongside first, remove later once verified.                                                                                                                                                                                                                           |

### Rejected alternatives

- **Raw `dart:io` `HttpServer`.** Would remove one dependency but push all
  routing, path-parameter extraction, and middleware composition into hand-rolled
  code — more surface to keep correct across 4 routes, for no behavioral gain.
- **`dart_frog`.** Its file-based routing and DI conventions are more structure
  than four routes and one background HTTP client need; `shelf` gets the same
  result with a flatter learning curve for anyone reading the Python original
  side by side.
- **`shelf_cors_headers` package.** The exact CORS behavior needed (wildcard
  origin, all methods, all headers, working `OPTIONS` preflight) is small enough
  that a dependency isn't worth it, and hand-rolling keeps the behavior visibly
  identical to the FastAPI `CORSMiddleware` call it mirrors.

## Design

### Project layout

```
adaptive_chat_server_dart/
  bin/server.dart          # CLI entrypoint: args parsing, shelf_io.serve   (~ __main__.py)
  lib/src/app.dart         # shelf Router, route handlers, build_responder  (~ main.py)
  lib/src/store.dart       # ConversationStore, Conversation, Interaction, Message
  lib/src/cards.dart       # bubble + envelope authoring
  lib/src/responder.dart   # Reply, Responder interface, EchoResponder
  lib/src/card_detect.dart # tryParseCardBody, cardParseFailureReason
  lib/src/ollama_responder.dart
  lib/src/stats.dart       # InteractionStats, fromOllamaResponse, toJson
  lib/src/status.dart      # buildStatus, conversationRef
  assets/default_system_prompt.txt
  assets/card_system_prompt.txt
  assets/card_schema.json
  test/
    store_test.dart
    cards_test.dart
    responder_test.dart
    card_detect_test.dart
    ollama_responder_test.dart
    stats_test.dart
    status_test.dart
    api_test.dart
  README.md
  CHANGELOG.md
  pubspec.yaml
  analysis_options.yaml
```

Import direction mirrors the Python module graph: `store` has no dependency on
`stats` beyond the `InteractionStats?` field type; `status` depends on `store`
and `stats`; `app.dart` depends on everything as the thin route layer.

### `lib/src/store.dart` (~ `store.py`)

- `Message` — `{role, card}` (`card` is a `Map<String, dynamic>`).
- `Interaction` — `{interactionId, text, messages, replyText, stats}` (`stats`
  nullable — `null` whenever the turn cost nothing measurable, same semantics
  as Python).
- `Conversation` — `{conversationId, interactions: Map<String, Interaction>,
order: List<String>}`.
- `ConversationStore` — `create()` (id = `'c_' + <12 hex chars>` via `Random` +
  hex encoding, not `uuid.uuid4` itself but the same shape/entropy class),
  `get(cid)`, `hasInteraction(cid, iid)`, `addInteraction(cid, interaction)`,
  `getInteraction(cid, iid)`, `listConversations()` (insertion order — Dart's
  `LinkedHashMap`, the default `Map` literal/constructor, preserves insertion
  order the same way Python's `dict` does, so no extra bookkeeping needed).

### `lib/src/cards.dart` (~ `cards.py`)

Ports `_bubble`, `_fullWidthBubble`, `_textItems`, `userBubble`,
`assistantBubble`, `assistantCardBubble`, `envelope` verbatim — same
`_BUBBLE_WEIGHT`/`_SPACER_WEIGHT` = 3/1 column weights, same `roundedCorners:
true`/style choices (`accent` right-aligned user, `emphasis` left-aligned
assistant), same full-width-no-`ColumnSet` treatment for card replies (still
required: the Carousel/`IntrinsicHeight` interaction that motivated it lives in
`flutter_adaptive_cards_fs`, unrelated to which backend renders the bubble).

### `lib/src/responder.dart` (~ `responder.py`)

- `Reply` — immutable class `{text, cardBody, stats}`, `cardBody` a
  `List<Map<String, dynamic>>?`, `stats` an `InteractionStats?`.
- `abstract interface class Responder` — `Reply reply(String text,
List<(String, String)> history)` and `Map<String, dynamic> describe()`.
- `EchoResponder implements Responder` — `reply()` returns `Reply(text: 'Did
you just say: $text')`, `describe()` returns `{'kind': 'echo'}`.

### `lib/src/card_detect.dart` (~ `card_detect.py`)

Ports the regex-based fence/decoration stripping and shape detection exactly:

- `_fence` — balanced ` ```json ... ``` ` (or bare ` ``` `) wrapping
  the whole reply.
- `_openFence` / `_closeFence` — unbalanced single-sided fence markers.
- `_decoration` — leading/trailing whitespace and delimiter runs (`=== `, `---`,
  `###`, `***`, `___`, `~~~`), halting at the first `{`/`[`/`"`/digit so real
  JSON content is never clipped.
- `tryParseCardBody(String raw) -> List<Map<String, dynamic>>?` — accepts a full
  `{"type": "AdaptiveCard", "body": [...]}` (returns its body), a bare non-empty
  array of objects (as-is), or a single element object with a non-empty `type`
  string (wrapped as a one-item list). Everything else (prose, invalid JSON, an
  empty/mixed array, a typeless dict, a scalar) returns `null`.
- `cardParseFailureReason(String raw) -> String?` — diagnostic-only, same rule:
  `null` for valid cards and for plain prose (text that doesn't start with `{`/
  `[` after stripping); a short reason string for JSON that looked like a card
  but wasn't usable.

Dart's `RegExp` supports the same constructs used here (multiline/dotAll via
flags, non-greedy `*?`), so this is a direct pattern-for-pattern port, not a
reimplementation.

### `lib/src/ollama_responder.dart` (~ `ollama_responder.py`)

Constants ported as top-level `const`s: `defaultOllamaModel =
'qwen2.5-coder:7b'`, `defaultHistoryTurns = 10`, `defaultNumCtx = 16384`,
`defaultJsonFormat = 'none'`, `defaultCardTemperature = 0.0`.

`OllamaResponder`:

- Constructor takes `ollamaUrl`, `model`, an injectable `http.Client`,
  `systemPromptFile` (path, not contents — re-read every request), `historyTurns`,
  `numCtx`, `jsonFormat`. On `jsonFormat == 'schema'`, loads and sanity-checks
  `card_schema.json` (`oneOf` + `$defs` keys present) exactly like
  `_load_card_schema`; on failure, logs and downgrades to `'none'`, remembering
  the originally requested value for `describe()`.
- `describe()` — same shape as Python: `kind`, `url`, `model`, `numCtx`,
  `historyTurns`, `jsonFormat`, `systemPromptFile` (basename only), plus
  `jsonFormatRequested` **only** when a downgrade occurred.
- `_loadSystemPrompt()` — reads the file fresh each call; missing/unreadable/
  empty logs a warning and returns `null` (no system message), never throws.
- `_trimHistory()` — last `2 * historyTurns` entries; `historyTurns <= 0` → `[]`.
- `_logContextFill(data)` — INFO ≥ 50%, WARNING ≥ 76% of `numCtx`, same
  wording/intent as the Python log lines.
- `reply(text, history)` — builds `messages` (system + trimmed history + turn),
  POSTs `{url}/api/chat` with `stream: false`, `options.num_ctx`, `options.temperature:
0`, `think: false`, and `format` only in `json`/`schema` modes. Three failure
  tiers, each returning a `Reply` with a diagnostic `text` and `cardBody: null`,
  never throwing to the caller:
  1. transport failure (`http.ClientException`/socket errors) → `"(Ollama
unreachable at $ollamaUrl — ...)"`.
  2. HTTP status ≥ 400 → `"(Ollama error HTTP $status at ...)"`.
  3. 2xx with an unparseable/missing `message.content` → `"(Ollama returned an
unexpected response: ...)"`.
     On success: captures stats via `fromOllamaResponse`, then — in `json`/`schema`
     modes — parses `content` with a duplicate-key guard (Dart's `json.decode` has
     no `object_pairs_hook`, so this is implemented as a small custom JSON-object
     scanner that walks the raw text and raises on a repeated key at the same
     nesting level as the target object, ported from the Python
     `_reject_duplicate_keys` intent rather than its literal mechanism, since
     `dart:convert` doesn't expose a pairs hook) — a duplicate key skips straight to
     a text reply, exactly like the Python `_DuplicateJsonKeyError` path. Otherwise
     falls through to `tryParseCardBody` on the raw content. Logs a WARNING with
     `cardParseFailureReason` when a reply looked like JSON but wasn't usable, and a
     DEBUG line with the raw content + detection result.

### `lib/src/stats.dart` (~ `stats.py`)

- `InteractionStats` — immutable `{promptTokens, replyTokens, totalMs, loadMs,
promptEvalMs, evalMs}` (ints; ns→ms conversion via integer division, done once
  at capture).
- `fromOllamaResponse(Map<String, dynamic> data) -> InteractionStats?` — `null`
  unless both `prompt_eval_count` and `eval_count` are present and `int`;
  missing/non-int durations default to `0`.
- `toJson(InteractionStats)` — adds derived `totalTokens` and `tokensPerSecond`
  (rounded to 1 decimal; `0.0` when `evalMs == 0`).

### `lib/src/status.dart` (~ `status.py`)

- `conversationRef(String conversationId) -> String` — `sha256(utf8).hex`,
  truncated to 12 chars, via `package:crypto`.
- `buildStatus(store, responder) -> Map<String, dynamic>` — `responder` block
  from `describe()` (defensively — a responder without a working `describe()`
  degrades to `{'kind': 'unknown'}`, never a 500), `conversationCount`, and a
  `conversations` list with `conversationRef`, `interactionCount`, `totals`
  (sums only interactions with non-null stats), and `lastInteraction` (`null`
  for zero-interaction conversations; otherwise `{stats: ...}`, `null` stats when
  the last turn cost nothing measurable). No message text, no raw conversation
  id, anywhere in the payload.

### `lib/src/app.dart` (~ `main.py`)

- Builds the `shelf_router.Router` with the four routes, wraps it with the CORS
  middleware and a logging middleware.
- `buildResponder(ollamaUrl, model, systemPromptFile, numCtx, historyTurns,
jsonFormat) -> Responder` — same selection rule: `OllamaResponder` when
  `ollamaUrl` is non-null/non-empty, else `EchoResponder`; logs the selection at
  startup.
- `POST /conversations` — creates a conversation, returns `{conversationId,
links: {postNext}}`.
- `POST /conversations/{cid}/interactions` — requires `X-Interaction-Id` header
  (400 if absent), 404s an unknown conversation, short-circuits an
  already-seen interaction id by replaying its stored envelope (responder **not**
  re-run), else reads `body.data.message` (400 if absent/empty), rebuilds
  history by walking `conversation.order`, calls `responder.reply(message,
history)`, authors `userBubble`/`assistantBubble` or `assistantCardBubble`,
  stores the interaction, returns the envelope.
- `GET /conversations/{cid}/interactions/{iid}` — 404s unknown conversation or
  interaction, else returns the stored envelope.
- `GET /status` — returns `buildStatus(store, responder)` JSON-encoded with a
  two-space indent (`JsonEncoder.withIndent('  ')`), trailing newline, `Content-
Type: application/json; charset=utf-8` — matching `_IndentedJSONResponse`'s
  human-readable intent. Chat routes stay compact (`jsonEncode`, no indent) —
  same "machine-consumed, wire format must not change" reasoning as the Python
  comment.

### `bin/server.dart` (~ `__main__.py`)

`args`-based parser with the exact flag set, defaults, and `--json-format`/
`--log-level` allowed-value lists from `__main__.py`'s `argparse` setup:
`--ollama-url`, `--ollama-model` (default `qwen2.5-coder:7b`),
`--system-prompt-file`, `--num-ctx` (default 16384, int), `--history-turns`
(default 10, int), `--json-format` (`none`/`json`/`schema`, default `none`),
`--host` (default `127.0.0.1`), `--port` (default 8000, int), `--log-level`
(`critical`/`error`/`warning`/`info`/`debug`/`trace`, default `info` — Dart's
`logging` package doesn't have a `trace` level distinct from `finest`; mapped
onto the `logging` package's `Level` values with `trace` → `Level.FINEST`,
`debug` → `Level.FINE`, `info` → `Level.INFO`, `warning` → `Level.WARNING`,
`error` → `Level.SEVERE`, `critical` → `Level.SHOUT`). No `--reload` (see
Non-goals). Configures `Logger.root.level` + a `Logger.root.onRecord` sink to
`stdout`, builds the responder from the parsed flags directly (no env-var
bridging — see Decisions), and starts the server with `shelf_io.serve(handler,
host, port)`.

### Asset resolution

```dart
final scriptDir = p.dirname(Platform.script.toFilePath());
final assetsDir = p.normalize(p.join(scriptDir, '..', 'assets'));
```

`bin/server.dart` always lives at `<package root>/bin/server.dart`, so
`assetsDir` always resolves to `<package root>/assets` regardless of the
directory the process was launched from — the same cwd-independence Python gets
from `Path(__file__).with_name(...)`. `--system-prompt-file` (when given) is
still resolved against the process cwd, matching Python's `Path(path)` (relative
to cwd unless given absolute), since that flag is explicitly operator-supplied.

## Error handling

Every failure mode from the Python version has a direct Dart equivalent, kept
in the same table shape as the token-stats design doc for consistency:

| Condition                                          | Behavior                                                                      |
| -------------------------------------------------- | ----------------------------------------------------------------------------- |
| Missing `X-Interaction-Id`                         | `400`                                                                         |
| Unknown conversation                               | `404`                                                                         |
| Repeated interaction id                            | `200`, stored envelope replayed, responder not re-run                         |
| Missing/empty `data.message`                       | `400`                                                                         |
| Ollama transport failure                           | `Reply` with `"(Ollama unreachable at ...)"`, `cardBody: null`, `stats: null` |
| Ollama HTTP ≥ 400                                  | `Reply` with `"(Ollama error HTTP ... )"`                                     |
| Ollama 2xx, unparseable body                       | `Reply` with `"(Ollama returned an unexpected response: ...)"`                |
| Duplicate JSON object key in `json`/`schema` mode  | Rendered as text, WARNING logged, never a crash                               |
| System-prompt file missing/unreadable/empty        | WARNING logged, request proceeds with no system message                       |
| `card_schema.json` missing/malformed (schema mode) | ERROR logged, downgrades to `jsonFormat: 'none'` for the process              |
| Responder without a working `describe()`           | `/status` reports `{'kind': 'unknown'}`, never 500s                           |
| Empty store                                        | `/status` reports `conversationCount: 0, conversations: []`                   |

## Testing

Route tests call the built `shelf.Handler` directly with constructed
`shelf.Request`s (no bound socket) — the Dart analog of FastAPI's `TestClient`.
Ollama calls are mocked via `http.testing.MockClient`, so no live Ollama is
contacted, mirroring the Python suite's `httpx.MockTransport`/monkeypatched
client approach.

Ported 1:1 from the Python suite:

- **`store_test.dart`** (~`test_store.py`) — create/get, idempotent-id lookup,
  interaction round-trip including `stats`.
- **`cards_test.dart`** (~`test_cards.py`) — bubble shape/alignment/style for
  user, assistant-text, assistant-card; envelope structure.
- **`responder_test.dart`** (~`test_responder.py`) — `EchoResponder` ignores
  history, never returns a card, `describe()` shape.
- **`card_detect_test.dart`** (~`test_card_detect.py`) — full-card object,
  bare array, single element, fenced/unfenced/unbalanced-fence variants,
  decoration stripping, prose rejection, empty/mixed arrays, `cardParseFailureReason`
  cases.
- **`ollama_responder_test.dart`** (~`test_ollama_responder.py`, the largest file
  at 856 lines) — all three failure tiers, success with/without a card reply,
  history trimming boundaries, context-fill log tiers, system-prompt load/missing/
  empty, `json`/`schema` format modes, duplicate-key detection, schema-load
  failure → downgrade, `describe()` including the `jsonFormatRequested` signal.
- **`stats_test.dart`** (~`test_stats.py`) — full body, missing/non-int counts →
  `null`, missing durations → `0`, `toJson` derivation, `evalMs == 0` → `0.0`.
- **`status_test.dart`** (~`test_status.py`) — empty store, echo responder,
  multi-conversation totals skipping null-stat turns, zero-interaction
  conversation, stub responder without `describe()`.
- **`api_test.dart`** (~`test_api.py`) — start/send/replay/status routes,
  idempotency, header/body validation, 404s.

## Documentation

- `adaptive_chat_server_dart/README.md` — same structure and depth as
  `adaptive_chat_server/README.md`: architecture Mermaid diagram, wire-contract
  table, component table (mapped to the Dart file layout above), the two
  sequence diagrams (route → envelope; `OllamaResponder.reply` internals),
  `/status` payload example and its semantics, System prompt / Card replies
  (display-only) / Structured output (`--json-format`) sections, Run/Test
  instructions (`dart pub get`, `dart run bin/server.dart [flags]`, `dart test`).
- Root `README.md`'s "adaptive_chat_server + adaptive_chat_client" section gets
  a short note pointing at `adaptive_chat_server_dart` as an alternative
  backend implementing the same wire contract — not a rewrite of that section
  (full cutover is the deferred follow-up).
- No `CHANGELOG.md` gate applies (same reasoning as the token-stats spec):
  `adaptive_chat_server_dart/` is a top-level demo app, not a package under
  `packages/`. It still gets its own `CHANGELOG.md` for its own history, per
  general repo hygiene, just not under the AGENTS.md package-changelog gate.

## CI

New `dart-server:` job in `.github/workflows/adaptive_chat.yml`, alongside the
existing `client:` (Flutter) and `server:` (Python) jobs: checkout, set up a
standalone Dart SDK (`dart-lang/setup-dart`, `sdk: "stable"`), `dart pub get`
**from within `adaptive_chat_server_dart/`** (not the repo root — see
Workspace membership above), then `dart test` from the same directory. The
Python `server:` job is untouched.

**History (discovered on the PR's first two real CI runs):** this section
originally specified exactly the setup above, on the reasoning that
`adaptive_chat_server_dart` has no Flutter dependency so a standalone Dart SDK
would be sufficient — but the plan also added the package to the root pub
workspace. Those two decisions contradict each other: pub workspaces resolve
as **one unit**, so `dart pub get` from the repo root necessarily resolves
every workspace member together, including the Flutter packages
(`flutter_adaptive_cards_fs`, etc.), which depend on `flutter_test` from the
Flutter SDK. A standalone Dart SDK can't satisfy that, so the first real CI
run failed at `dart pub get` before ever reaching `dart test`. The first fix
attempt swapped in `subosito/flutter-action` + `flutter pub get` (matching the
`client:` job) to satisfy the workspace's Flutter dependency — which worked,
but only by installing a full Flutter toolchain for a job that fundamentally
doesn't need one. The root-cause fix instead removed
`adaptive_chat_server_dart` from the workspace entirely (see Workspace
membership above), letting the original standalone-Dart-SDK design stand as
originally intended. Both gaps were missed by every local verification step
in the plan because they all ran via `fvm`, which already wraps a full
Flutter SDK regardless of workspace membership — the gap only surfaced once
CI ran with a genuinely Flutter-free SDK.

## Workflow

Implementation happens on a feature branch (e.g.
`feat/adaptive-chat-server-dart`), created before any code changes, per user
instruction.

## Security note

Same posture as the Python server, ported unchanged: `/status` is
unauthenticated and CORS is wide open (`allow_origins: *`), `conversationRef` is
a truncated sha256 (not the raw id, which is the bearer credential for the
transcript endpoints), `systemPromptFile` in `describe()` is a bare filename.
Acceptable for a demo server bound to `127.0.0.1` (the default); binding to
`0.0.0.0` would expose configuration metadata and conversation-volume data to
the network — identical caveat to the Python README.
