# Changelog

## [Unreleased]

- Measured, not promoted: tried adding a paragraph telling the model a
  two-part request ("compare A and B, then tell me which you'd pick") is
  still one message, plus a matching pre-send check-0 clause, to fix a
  reported card-then-loose-paragraph failure. On `qwen2.5-coder:7b` at
  `t=0` the candidate tied baseline on the compare-and-comment set
  (10/10 → 10/10 — Task 2's corrected `judgeReply` already resolves the
  originally-reported failure, so there was no headroom left to measure an
  improvement against) and it _improved_ the stress set's `t=0.6` "mixed"
  compare-then-choice-set case (9/10 → 10/10, `t=0` unchanged at 10/10).
  But the Step 4 regression check on the built-in code A/B set caught a
  real, reproducible regression the compare-and-comment set could not see:
  "what is a closure? show an example" went from a passing plain-Markdown
  reply to a `prose-with-card` reply — raw JSON shown to the user — 8/8 →
  7/8, confirmed deterministic by repeating that one prompt 3 times at
  `t=0` (baseline 3/3 pass, candidate 0/3 pass). Per the promote-only-if-
  better rule, the candidate wording was reverted and not shipped;
  `assets/card_system_prompt.txt` is unchanged. The trade-off (fix an
  already-fixed case, break an unrelated one) is not worth taking, so this
  wording is not something to retry without a materially different
  approach.
- Added: `prompt_ab.dart --prompts <file>` runs an external prompt set. The
  built-in list is code-flavoured and could not express the comparison or
  options shapes, so every investigation had to work around it.
- Added: `choiceset_ab.dart`, a shape-aware probe for pick-from-a-set
  questions. It sends prior prose turns and requires a card containing an
  `Input.ChoiceSet`, because the generic sets score a tidy Markdown list of
  options as a passing `prose` reply while the user is left with something
  they cannot click. `probeOnce` gained an optional `history` parameter and
  `ProbeOutcome` now carries the raw `reply`.
- Added: `dump_reply.dart --history <file>` (repeatable) replays prior
  conversation turns the way `OllamaResponder` does. Every probe was
  single-turn while the server always sends history, so any failure triggered
  by an ongoing conversation was structurally invisible to the whole suite.
- **Breaking:** the server no longer has a default reply mode and refuses to
  start without one. Every invocation names `--system-prompt-file` (the card
  prompt for Adaptive Cards, the Markdown prompt for prose) or `--echo` for the
  echo demo; anything else exits `2` with a message listing all three. The two
  bundled prompts produce the largest single effect on record for this workload
  — **8/8 cards versus 0/8** on the same model at `t=0`, bigger than any model
  or temperature difference — so whichever one had been implicit, somebody
  would eventually run the server, get the other kind of reply, and blame the
  model. Refusing to guess costs one flag and removes that entire class of
  confusion. The chat client is the only consumer, so nothing external breaks.

  `--ollama-url` now defaults to `http://127.0.0.1:11434`, so naming a prompt
  is enough to talk to Ollama; `--echo` withholds the URL and selects the echo
  demo. Startup logs the chosen mode.

  Preflight behaviour is deliberately unchanged: an unreachable Ollama still
  logs `SEVERE` and serves a diagnostic rather than refusing to start, so the
  error surfaces in the chat bubble instead of as a refused connection. The
  message now names both remedies (`ollama serve`, or `--echo`).

  `assets/default_system_prompt.txt` keeps its misleading name — it is not a
  default and is never loaded unless named — because renaming an asset breaks
  every `--system-prompt-file` invocation already written down. Every
  `.vscode/launch.json` server configuration now states its mode in its name
  **and** passes the matching flag, so a name cannot drift from behaviour.

- Added: the server logs which system prompt is active at startup, and says how
  to switch. Card replies are opt-in via `--system-prompt-file`, and the
  bundled default prompt never mentions Adaptive Cards — measured on
  `qwen2.5-coder:7b` at `t=0` over eight options questions: 0/8 cards on the
  default prompt versus 8/8 on the card prompt, same model, same temperature.
  Nothing previously indicated which mode was running, so "the model never
  sends cards" looked like a model or prompt-wording problem when it was a
  launch-flag problem. `--help` now names the card prompt file too.

- Fixed: probes scored a prose-wrapped card as a passing `prose` reply. A model
  that writes "Sure, here you go:" before a fenced card produces a message the
  server renders as Markdown, so the user sees raw JSON in a code block — the
  exact symptom people report, scored green by every probe. `card_detect.dart`
  gained `replyWrapsCardInProse`, and `judgeReply` now returns
  `prose-with-card` as a failure. Prose that merely contains a non-card code
  fence is still a legitimate pass, so a Markdown answer with a Dart snippet is
  unaffected. Every pass rate measured before this change counted this shape as
  a success.

- Fixed: the README's element palette listed neither `Input.Toggle` nor
  `ColumnSet` after both were added to the card system prompt and schema, so
  the documented palette disagreed with the shipped one. Added a test that
  asserts every type the prompt advertises appears in both the schema enum
  and the README, turning this drift into a build failure instead of a
  discrepancy someone has to notice.

- Added: `Input.Toggle` and `ColumnSet` to the card system prompt and to
  `card_schema.json`. Both were already registered and renderable on the
  Flutter side but named nowhere the model could see, so it could not emit
  them — a binary question got a two-choice `Input.ChoiceSet` and "compare X
  and Y side by side" had no side-by-side element at all. Both files needed
  the change: the prompt decides what the model reaches for, the schema enum
  is the grammar under `--json-format schema`, and adding only the prompt
  leaves schema mode rejecting what the prompt just started requesting.
  Measured on `qwen2.5-coder:7b` at `t=0` — the new types are emitted for the
  prompts that call for them, with stress 5/5 at `t=0` and `t=0.6` and the
  code A/B set 8/8, i.e. no regression.

- Added: `ModelBehavior.md` — the durable record of which models produce
  renderable cards, what settings they need, and which of the card test
  classes each has been through. Results previously lived only in plans and
  design specs that get archived; this file is where they survive. Seeded with
  six newly probed models plus the four already on record.

- Fixed: asked to explain a code snippet, a model no longer answers with a
  card followed by a loose explanation — a mixed reply that is shown to the
  user as raw JSON. The card system prompt now gives that explanation a legal
  home (a `TextBlock` beside the `CodeBlock` in the same array) instead of
  only forbidding the append; forbidding alone was measured and did not work,
  it just pushed the model out of cards into prose. Measured on
  `qwen2.5-coder:7b`: hard cases 6/10 → 15/15 at `t=0`, 7/10 → 14/15 at
  `t=0.6`; code-snippet prompts 14/16 → 16/16 and now render as cards rather
  than falling back to Markdown.

- Fixed: `card_detect.dart` recovers a card whose top-level elements were
  emitted comma-separated without the enclosing `[ ]`. This is the shape a
  model reaches for once asked to send two elements, and it is an array
  missing its brackets and nothing else. The repair runs only on a reply that
  has already failed to parse and only when bracketing makes it parse, so a
  card followed by trailing prose is still (correctly) treated as text, and a
  full `AdaptiveCard` object keeps its meaning.

- Added: `tool/model_probes/prompt_ab.dart` — runs the shipped card system
  prompt and an edited copy over the same user prompts and prints both pass
  rates, so a prompt-wording change is measured rather than argued.

- Added: `tool/model_probes/` — hand-run scripts that measure whether a local
  Ollama model produces renderable cards, which temperature suits it, whether
  it honors `format`, and what it literally emitted. They judge replies with
  the server's own card detection, so their pass rates match the running
  server. Not wired into `dart test` or CI (they need a local Ollama and take
  minutes). The directory README records the findings behind the temperature
  and `--json-format` guidance in the package README.

- Fixed: a card whose own text contains a Markdown code fence is no longer
  truncated and shown as raw JSON. The unbalanced-closing-fence heuristic
  (` ```[^\n]*$ `) matched the ` ```dart ` **inside** the card's text — a
  model reply is a single line, so the pattern ran to end-of-string and
  deleted everything from that fence on, leaving unparseable JSON. Fence and
  decoration stripping are repair heuristics, so they now run only when the
  reply does not already parse as JSON. The defect was in the detector, not
  in any model: every reply that was valid single-line JSON containing a
  fence was corrupted. Observed with `qwen3.6:27b-coding-nvfp4` on "show me
  a code snippet" requests, identically at temperature 0 and 0.6.

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
