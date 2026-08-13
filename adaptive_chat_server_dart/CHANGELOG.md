# Changelog

## [Unreleased]

- Added: `--ollama-temperature` (default `0`, unchanged behavior) sets
  `options.temperature` per run instead of it being a hardcoded constant. The
  literal value `model` sends no temperature at all, so Ollama applies the
  model's own Modelfile default — useful for models that ship tuned sampling
  settings (`qwen3.6:27b-coding-nvfp4` ships `0.6`). The effective value is
  reported by `GET /status`, and an invalid value now exits with a usage
  error instead of a stack trace.
- Added: a `WARNING` when a reply fails to parse as JSON in `--json-format`
  `json`/`schema` mode. Ollama accepts `format` for every model but honors it
  on only some — `qwen3.6:27b-coding-nvfp4` ignores it and returns
  unconstrained prose with no error — so the constraint could previously look
  like a safety net while doing nothing. Documented in the README.
- Changed: `defaultCardTemperature` no longer claims temperature 0 is
  deterministic. Greedy decoding repeats short replies verbatim but long
  generations still diverge; measured, a ~3.5 K-character table gave two
  different outputs across three calls at 0.
- Added: the card system prompt and `assets/card_schema.json` now advertise six
  flat-data `Chart.*` types (`Chart.Pie`, `Chart.Donut`, `Chart.VerticalBar`,
  `Chart.HorizontalBar`, `Chart.Line`, `Chart.Gauge`), so a model can answer
  with a chart instead of a Markdown table. Multi-series grouped/stacked charts
  are deliberately excluded. A new `test/card_schema_test.dart` reads the chart
  types out of the prompt and fails if the schema enum disagrees.
- Initial Dart port of the Adaptive Chat backend (echo + Ollama responders,
  card detection, `/status` endpoint).
- Resolves standalone (no longer a root pub workspace member) — this package
  has no Flutter dependency, and workspace membership was forcing CI to
  install the full Flutter SDK just to satisfy unrelated Flutter packages
  elsewhere in the repo.
- Fixed: a failed turn's diagnostic (`"(Ollama unreachable …)"` and friends) is
  no longer replayed to the model as an assistant turn. Failed exchanges are
  skipped whole when history is rebuilt, so one transient Ollama failure no
  longer poisons the rest of the conversation.
- Fixed: a client retry that arrives while the first call is still running now
  joins the in-flight call instead of running the model a second time and
  recording a duplicate entry in the conversation order.
- Fixed: an Ollama timeout is reported as a timeout instead of "unreachable" —
  a slow-but-healthy server and a dead one are different problems.
- Added: `--keep-alive` (default `30m`, reported by `GET /status`) so an idle
  chat does not pay a full model reload on its next message. Ollama's own
  default is 5m.
- Removed: `ConversationStore.hasInteraction`, which nothing outside its own
  tests called — the routes use `getInteraction(...) != null`. The existence
  assertion it carried now covers `getInteraction` instead.
- Added: `--ollama-timeout` (seconds, default 60, reported by `GET /status`).
  The per-request timeout was previously hardcoded and unreachable from the
  command line, so a cold load of a large model could only be worked around by
  editing source.
- Added: a startup preflight against `/api/tags` when `--ollama-url` is set.
  It distinguishes "Ollama unreachable" from "model not pulled" (naming the
  `ollama pull` command and the models that are available) and logs the result
  before serving. The server still starts either way, since an Ollama brought
  up afterwards will work.
- Added: `--help` / `-h` prints usage and exits without starting a server. An
  unrecognised flag now prints the same usage and exits `2` instead of
  throwing an unhandled exception with a stack trace.
- Flag parsing moved from `bin/server.dart` to `lib/src/cli.dart`
  (`buildArgParser`, `resolveLogLevel`) so the CLI surface is covered by
  tests; `bin/server.dart` is now a thin entrypoint.
- Now the only Adaptive Chat backend: the Python/FastAPI prototype this package
  was ported from has been removed. README expanded to carry the behavior
  documentation it previously deferred to that package's README (wire
  envelope, conversation context, system prompt, card replies, structured
  output, Ollama diagnostics, macOS local-network notes).
- Added: `POST /conversations` accepts an optional `userLabel` / `assistantLabel`
  body, fixed for that conversation's lifetime and applied to every bubble
  rendered in it (was previously the hardcoded English `user` / `assistant`
  text above each bubble). Defaults to `user` / `assistant` when omitted. Also
  accepts a `language` field, stored on the conversation for future use but
  not yet consumed by any behavior.
- Added: `POST /conversations/{cid}/interactions` no longer 404s for a
  `conversationId` the (in-memory) store has lost across a restart. It now
  auto-vivifies a fresh conversation under the same id and prepends a "this
  conversation no longer exists" notice card to the envelope, so the
  transcript explains what happened instead of the client hitting a bare
  error. Notice body is bundled at `assets/expired_conversation_notice.json`
  (editable without recompiling); the replay route
  (`GET .../interactions/{iid}`) is unchanged and still 404s. The response
  also carries `X-Chat-Notice: conversation-recovered` — the first use of a
  new policy: a noteworthy-but-not-an-error server event on an otherwise
  normal `200` is signalled via this header, not the status code or a body
  field.
