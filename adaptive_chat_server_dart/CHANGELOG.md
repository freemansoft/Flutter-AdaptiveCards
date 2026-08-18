# Changelog

## [Unreleased]

- Corrected: the warm-start drift candidate screen below conflated two
  different exclusion criteria for reading `qwen2.5-coder:7b`'s six-case
  subset. The screen excluded any case that "failed cold-start under the
  baseline prompt"; the spec's own wording, three times, is narrower — a
  shape the model **cannot produce** cold-start. `table` fails that
  narrower test: the 25-case baseline recorded it as an unbucketed
  _inverted_ case (cold `wrong-shape`, warm a real `Table`), this screen's
  own baseline reproduced that inversion at `--samples 2`, and `table`
  additionally passed cold under two of the five candidates. `ModelBehavior.md`
  now records both readings: excluding `table` (as originally applied),
  N2 (`--seed-card`) clears the Step 6 promotion bar; excluding only the
  uncontested `carousel`, N2's with-history score ties baseline instead.
  No measurements changed — every recorded number was already correct —
  and the four losing candidates (P1/P2/P3/N1) remain losers under either
  reading. Also corrected: a "coincidentally" characterization of
  `table`'s warm regression under N2, which reproduced deterministically
  across two independent runs and is not coincidental; and an inference
  that byte-for-byte reproduction across `--samples 2` runs demonstrates
  statistical robustness — at `t=0` decoding is close to deterministic
  (71 of 72 sampled pairs in this screen agreed), so a second sample
  mostly re-measures rather than re-samples.

- Added: screening results for five warm-start drift candidates (P1 recency,
  P2 Markdown-section guard, P3 escape-hatch narrowing, N1 mid-conversation
  reminder, N2 card-shaped history seed), measured 2026-08-17 over a
  six-case subset at `t=0` with `shape_ab.dart`. `qwen2.5-coder:7b` at
  `--samples 2` decided; three informing models at `--samples 1`
  (`granite4.1:8b`, `gpt-oss:20b`, `llama3-chatqa:8b`) informed the wording
  and surfaced harm. Two subset cases (`table`, `carousel`) had already
  failed cold-start under `qwen2.5-coder:7b`'s own recorded baseline and
  were excluded from its erosion reading (a third, `choice2`, also excluded
  for `granite4.1:8b`) — read on that corrected denominator rather than the
  raw six-case count, `--seed-card` (N2) is the only candidate that
  increases with-history passes without decreasing cold-start on the
  deciding model. Advancing: `N2`. N2 also shows a with-history regression
  on the harm-control model (`gpt-oss:20b`, 5/6 → 4/6) that the stacked run
  should watch. Losers (P1, P2, P3, N1) are recorded with their numbers so
  they are not retried; N1 separately showed a strong positive effect on
  `granite4.1:8b` (an informing, non-deciding model) worth revisiting if
  that model becomes a target in its own right.

- Added: a delivery check for mid-conversation `system` messages, recorded in
  `ModelBehavior.md`. Ollama chat templates differ in whether a `system`
  message placed after the history reaches the model; measured per screening
  model on 2026-08-18. A first attempt used a reminder that contradicted the
  card system prompt and produced no positive result on any model — an
  uninformative design, since a model preferring its main instructions over a
  contradiction looks identical to a template that dropped the message. A
  second, additive reminder (append a checkable `Badge` element rather than
  override the reply) settled it: delivered on `gpt-oss:20b`, unconfirmed on
  `qwen2.5-coder:7b` and `granite4.1:8b`, no suitable case on
  `llama3-chatqa:8b`. Without this, a candidate scoring at baseline is
  ambiguous between "did not help" and "never arrived".

- Added: `shape_ab.dart --seed-card` (candidate N2) prepends a synthetic
  card-shaped exchange ahead of the replayed history, so a card is the
  conversation's established format before any prose accumulates. The seed's
  subject (build timezones) is unrelated to every case prompt, so a pass
  cannot come from the model copying its content — the format is what is
  being seeded. Server-side this would be few-shot priming prepended to every
  request, which also means it costs tokens on every request; N2's evaluation
  records latency alongside pass rate.

- Added: `shape_ab.dart --reinforce` (candidate N1) injects a shape reminder
  as a `system` message after the replayed history and immediately before the
  current user turn. `probeOnce` gained an optional `reminder`, and its
  message assembly moved into a testable `buildProbeMessages` — the
  reminder's position is the whole hypothesis, so a unit test asserts it lands
  after history rather than leaving that to inspection. Every other probe
  passes no reminder, so their requests are unchanged.

- Added: fourth `shape_ab.dart` baseline — `granite4.1:8b`, preceded by a
  five-case go/no-go screen confirming a real cold-start card path, then the
  full 25 cases, `t=0`, `--samples 1`, current shipped prompt: cold-start
  18/25 (third of the four baselines on record, behind `gpt-oss:20b`'s 20
  and `qwen2.5-coder:7b`'s 19), with-history 15/25, 4 shapes eroded by
  history (`choice1`, `choice5`, `columnset`, `number`). Recorded in
  `ModelBehavior.md`: of those four, three eroded to prose — tying
  `qwen2.5-coder:7b`'s 3 prose erosions — while the fourth (`columnset`)
  eroded to a wrong element type, a different failure mechanism a
  prose-drift fix may not touch. Verdict: a viable drift-fix validation
  subject comparable to `qwen2.5-coder:7b`, not clearly better than it.

- Added: third `shape_ab.dart` baseline — `llama3-chatqa:8b`, 25 cases,
  `t=0`, `--samples 1`, current shipped prompt: cold-start 1/25,
  with-history 2/25, zero shapes eroded by history. Recorded in
  `ModelBehavior.md` alongside the `qwen2.5-coder:7b` and `gpt-oss:20b`
  baselines: unlike either, this model is not cold-strong — 22 of its 23
  failing cases scored a flat `prose` verdict under both conditions,
  meaning it mostly never attempted card JSON at all rather than producing
  it and losing it to drift or JSON invalidity, so its earlier 0/6
  choice-set collapse does not generalize into broad shape erosion and it
  is a weaker drift-fix validation subject than that narrower result
  suggested.

- Added: second `shape_ab.dart` baseline — `gpt-oss:20b`, 25 cases, `t=0`,
  `--samples 1`, current shipped prompt: cold-start 20/25, with-history
  22/25, zero shapes eroded by history. Recorded in `ModelBehavior.md`
  alongside `qwen2.5-coder:7b`'s baseline for comparison: unlike qwen's
  three prose-drift losses, every one of this model's 8 failing instances
  (on `carousel`, `table`, and `columnset`) is malformed JSON on the most
  structurally nested shapes, present under both conditions — a
  JSON-validity ceiling rather than a prose-drift problem. Fixed: this run
  exposed `judgeShape` re-prefixing a label `judgeReply` already prefixed
  for parse failures, doubling to `broken: broken: invalid JSON…`; added
  `brokenLabel()` and a regression test. Cosmetic only — bucket
  classification and the recorded numbers are unaffected.

- Fixed: `judgeShape`'s negative-control branch could score a reply the
  server itself calls broken (invalid JSON, duplicate keys, prose wrapping a
  card) as `prose-ok`, because it checked `outcome.ok` only after already
  deciding the reply wasn't a card — the same class of bug the earlier
  duplicate-key fix (`2d61c13`) closed for the branch's card path but missed
  here. `--only` with an empty/blank value (e.g. an empty shell variable) now
  exits 2 instead of silently running zero cases. Added a test pinning that
  `shapeCases`' accepted types stay in sync with `card_schema.json`'s
  element enum. Docs: `tool/model_probes/README.md` names duplicate keys and
  `unwanted-card` and records the deliberate judging difference from
  `choiceset_ab.dart`; `ModelBehavior.md`'s "every With history cell" claim
  is narrowed to measured cells. The recorded `qwen2.5-coder:7b` baseline
  (cold-start 19/25, with-history 18/25) is unaffected — its `prose` case
  returned genuinely clean prose under both conditions.

- Added: first `shape_ab.dart` baseline — `qwen2.5-coder:7b`, 25 cases,
  `t=0`, `--samples 1`, current shipped prompt: cold-start 19/25,
  with-history 18/25. Recorded in `ModelBehavior.md` alongside which shapes
  were lost to history and which the model never produced under either
  condition — the second group being capability gaps rather than drift, which
  no anti-drift wording will move.

- Added: `tool/model_probes/README.md` documents `shape_ab.dart`, its four
  card-failure labels, and the finding that motivated it — that judging
  replies only as "renders or not" left 23 of 24 advertised element types
  unverified.
- Added: `shape_ab.dart`, a shape-aware probe. It runs all 25 cases
  cold-start and again after two prose turns, then prints the shapes a model
  produces cold and loses with history — the number a prompt fix has to move.
  A case counts as passing only when every sample passed, and the erosion
  line is derived from the two pass-sets so its count can never disagree with
  its own list. `--only` rejects unknown case ids rather than silently
  shrinking the denominator; `--baseline`/`--candidate` A/B two prompts.

- Added: `shape_cases.dart` — a 25-case table naming, for each prompt, the
  element types that would answer it acceptably. Expectations are sets rather
  than single types because several shapes are often equally correct
  ("summarize these specs" is defensibly a `FactSet` or a `Table`), and this
  file already records one case where a strict assertion was the bug rather
  than the model. Tests assert every accepted type exists in
  `card_schema.json`'s enum, so a typo cannot silently fail every model.

- Added: `collectElementTypes` and `cardContainsAnyType` in
  `probe_support.dart` — a recursive element-type walker shared by the
  probes, reporting every `type` present anywhere in a parsed card body
  including inside `Carousel` pages, `Table` cells, and `Column` items.
  `choiceset_ab.dart` now uses it instead of a private copy; its prompts,
  conditions, and output are unchanged, so the thirteen `N/6` scores in
  `ModelBehavior.md` remain reproducible. New unit tests pin the walker's
  behavior, which is what makes touching that reproducer safe.

- Added: `judgeShape` in `shape_cases.dart`, a seven-outcome classifier
  layered over the server's own card/prose verdict: `ok`, `prose-ok`,
  `prose`, `no-input`, `wrong-shape`, `unwanted-card`, `broken`. `no-input`
  is decided before `wrong-shape` so "asked for a date, got a bare
  TextBlock" stays distinguishable from "asked for a date, got an
  Input.Text" — different failures with different fixes.

- Changed: `ModelBehavior.md`'s `With history` column now uses one denominator
  for every model. `qwen2.5-coder:7b` was the only cell measured at
  `--samples 2` (Task 7 wanted two samples per prompt because that number
  gated a promote-or-revert decision), so it read `6/12` in a column of `N/6`
  scores and invited a wrong at-a-glance comparison. Re-ran it at
  `--samples 1` on 2026-08-17 against the current shipped prompt:
  `qwen2.5-coder:7b` scores **3/6**, passing and failing exactly the same
  three prompts each as the 12-trial run, so this is a change of resolution
  rather than of finding. The `2/12 → 6/12` before/after is kept in §4 and in
  the per-model section, since that pair is the evidence that justified
  promoting the escape-hatch change in the first place.

  Normalizing adds a thirteenth model to the with-history band tally, which
  moves it off the even three-way split it had at twelve: the bands are now
  **4 collapse / 5 partial / 4 strong**, with `qwen2.5-coder:7b` joining the
  `granite4.1` pair at 3/6 in the partial band. Still no model anywhere at
  4/6, so the band boundaries remain a property of the scores rather than an
  arbitrary cut.

- Added: `ModelBehavior.md` now records the with-history probe of
  `qwen3.6:27b-coding-nvfp4` (18.4 GB), the sixth and last model in this
  sweep — its cold-start cell was already filled, only **With history** was
  blank. Measured 2026-08-16, `choiceset_ab.dart`, two prior prose turns,
  `t=0`, `--samples 1`: ✅ 6/6, a clean sweep matching `gpt-oss:20b`'s —
  every prompt returned a two-element card containing an `Input.ChoiceSet`.
  This is the twelfth `N/6` with-history cell filled in this file
  (re-counted, not incremented). With all twelve now on record, the scores
  split evenly into three bands with real gaps between them (no model
  scored 4/6): four collapsed to 0/6 prose, four landed partial at 1/6-3/6,
  and four — including this one — held up strongly at 5/6 or 6/6. Weight
  class doesn't predict the band (the five large 17-24 GB candidates split
  1/2/2 across all three); family is more mixed — `nemotron-3-nano`'s three
  sizes spread across all three bands, but `granite4.1`'s two sizes
  (3b, 8b) land in the identical partial band at the identical 3/6 score —
  see `ModelBehavior.md` §4 for the full breakdown.
- Added: `ModelBehavior.md` now records the with-history probe of
  `qwen3.5:9b` (6.1 GB) — its cold-start cell was already filled, only
  **With history** was blank. Measured 2026-08-16, `choiceset_ab.dart`,
  two prior prose turns, `t=0`, `--samples 1`, `think:false` (the probe
  tooling's `probeOnce` hardcodes `think: false` unconditionally, so this
  is the same thinking-off condition as the model's existing "usable only
  with thinking disabled" cold-start note, not a thinking-on measurement).
  Scored ⚠️ 5/6, one miss ("what build modes can I choose from?") where the
  reply was a valid single-element card whose element was a `TextBlock`
  Markdown list of the three modes rather than an `Input.ChoiceSet`,
  confirmed with `dump_reply.dart`; the other five prompts each returned a
  card containing the `Input.ChoiceSet`. Ties `nemotron-3-nano:30b` for the
  second-best with-history score on record among candidate models — only
  `gpt-oss:20b`'s 6/6 is higher. Also corrects this model's per-model
  section, which stated it was "not currently installed locally"; it is
  present in `ollama list`. This is the eleventh `N/6` with-history cell
  filled in this file (re-counted, not incremented).
- Added: `ModelBehavior.md` now records the first probe of `qwen3-coder:30b`
  (17.3 GB), previously blank in every column. Measured 2026-08-16, one
  model resident at a time, card system prompt, `--samples 1`: everyday set
  7/7 · 6/7 · 7/7 across `t=0`/`0.2`/`0.6` (`temperature_matrix.dart`, one
  loss — `rating` at `t=0.2`, missing array brackets around two elements),
  a clean stress set 5/5 at both `t=0` and `t=0.6` (`temperature_stress.dart`
  — the best large-candidate stress score on record, the only one of the
  four large candidates to sweep every case), and 2/6 with two prior prose
  turns (`choiceset_ab.dart`, `t=0`) — a new with-history failure signature:
  all four failures attempted a card rather than dropping to prose, each
  missing the wrapping `[ ]` around a `TextBlock`/`Input.ChoiceSet` pair,
  and three of the four (including "help me pick a database engine", which
  shares no wording with the topic) returned content that is, once the
  missing `[ ]` and comma-for-newline swap are accounted for,
  character-for-character identical to the worked example on line 28 of
  `assets/card_system_prompt.txt` — same `TextBlock` text, same
  `Input.ChoiceSet` id and `Staging`/`Production` choices — rather than
  question-specific content; re-confirmed per-prompt with `dump_reply.dart`
  and a direct string comparison against the prompt file. The best
  large-candidate cold start on record did not predict either the
  with-history score or its failure mode.
- Added: `ModelBehavior.md` now records the first probe of
  `nemotron-3.5-lightning:30b` (23.7 GB), previously blank in every column.
  Measured 2026-08-16, one model resident at a time, card system prompt,
  `--samples 1`: everyday set 6/7 · 6/7 · 5/7 across `t=0`/`0.2`/`0.6`
  (`temperature_matrix.dart`, the weakest large-candidate everyday score so
  far — `table` fails at all three temperatures rather than only `t=0.6`),
  stress set 3/5 at `t=0` and 4/5 at `t=0.6` (`temperature_stress.dart`, the
  best large-candidate stress score so far, three failures: two truncated
  `bigtable` responses and one last-character `nested` malformation), and
  0/6 with two prior prose turns (`choiceset_ab.dart`, `t=0`) — a total
  collapse to prose on every prompt. A weaker everyday score and a stronger
  stress score than either `nemotron` 30B build, on the same model, land on
  opposite sides of the large-candidate ranking without predicting its
  total with-history collapse.
- Added: `ModelBehavior.md` now records the first probe of
  `nemotron-3-nano:30b` (22.6 GB, the Ollama-library build), previously
  blank in every column. Measured 2026-08-16, one model resident at a time,
  card system prompt, `--samples 1`: everyday set 7/7 · 7/7 · 6/7 across
  `t=0`/`0.2`/`0.6` (`temperature_matrix.dart`, the same single `t=0.6`
  truncated-table loss as the `hf.co/unsloth` build), stress set 2/5 at
  `t=0` and 1/5 at `t=0.6` (`temperature_stress.dart`, seven failures
  spanning three distinct malformation types rather than one shared
  pattern), and 5/6 with two prior prose turns (`choiceset_ab.dart`,
  `t=0`). Despite a weaker cold start than the `hf.co/unsloth` build of the
  same nominal model, this build scored far better with history (5/6 vs
  1/6) — the two builds land at opposite ends of the with-history scale
  under identical conditions.
- Added: `ModelBehavior.md` now records the first probe of
  `hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` (22.9 GB), previously
  blank in every column. Measured 2026-08-16, one model resident at a time,
  card system prompt, `--samples 1`: everyday set 7/7 · 7/7 · 6/7 across
  `t=0`/`0.2`/`0.6` (`temperature_matrix.dart`), stress set 3/5 at both `t=0`
  and `t=0.6` (`temperature_stress.dart`, `bigtable` and `mixed` failing at
  both temperatures with a repeated extra-closing-bracket pattern), and
  1/6 with two prior prose turns (`choiceset_ab.dart`, `t=0`). Unlike
  `llama3-chatqa:8b`'s collapse from a strong cold start, this model's
  cold-start stress weakness already predicted the multi-turn result.
- Fixed: findings from the final whole-branch review. `ModelBehavior.md`'s
  six-model history sweep (2026-08-16) now says explicitly it was measured
  _after_ Task 7's escape-hatch fix was already promoted, both in the sweep's
  own paragraph and as a note next to the `With history` column, so the
  6/12 (`--samples 2`) cell for `qwen2.5-coder:7b` no longer reads as the
  odd one out among the other `N/6` (`--samples 1`) cells; that cell is now
  labelled with its own sample count. `tool/model_probes/README.md`'s "What
  these found" section gained the two probe-side findings this branch
  actually produced — cold start not predicting multi-turn behavior, and
  three of six models collapsing to 0/6 with prior prose turns — which its
  own stated contract said belonged there. `-h`/`--help` now works in
  `choiceset_ab.dart`, `prompt_ab.dart`, and `dump_reply.dart`; all three
  declared the flag but never checked it, so it silently started a full
  probe run instead of printing usage. `dump_reply.dart`'s `history turns`
  summary line now aligns its colon with its siblings.
- Added: `ModelBehavior.md` now records the `qwen2.5-coder:7b` fence rate and
  the default-vs-card prompt comparison measured on 2026-08-14, which had
  lived only in scratch reports until now. It also records this branch's own
  measurements in full: the escape-hatch fix's real multi-turn numbers
  (2/12 → 6/12 with history, `choiceset_ab.dart --samples 2`, `t=0` — not the
  2026-08-14 investigation's original 0/6 reference figure, which was
  superseded once the fix actually shipped and was re-measured) and the
  compare-and-comment wording's negative result (tied baseline, then caught a
  reproducible regression, not promoted). This is exactly the loss the file
  exists to prevent.
- Added: multi-turn (`With history`) results for the six models that already
  had cold-start numbers. The column previously had one value out of fourteen,
  which let cold-start figures read as though they described real
  conversations. Measured with `choiceset_ab.dart` at `t=0`, `--samples 1`,
  one model resident at a time.
- Fixed: an ongoing Markdown conversation talked the model out of cards
  entirely. The escape hatch was keyed on confidence ("if you are unsure
  whether a card helps"), and two prose turns are enough to make it unsure —
  measured 2/12 on options questions with prior prose turns on
  `qwen2.5-coder:7b` at `t=0`. The hatch is now keyed on capability ("if no
  element type fits"), the prompt says to judge the current question on its
  own, and pick-from-a-set questions are named explicitly as ChoiceSet
  questions. Measured on `qwen2.5-coder:7b` at `t=0`: 2/12 → 6/12 with
  history (`choiceset_ab.dart --samples 2`). Regression checks stayed clean:
  stress (`temperature_stress.dart --samples 2`) held 10/10 at both `t=0`
  and `t=0.6`, and code A/B (`prompt_ab.dart --samples 1`) held 8/8,
  including the closure case Task 6 regressed.
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
