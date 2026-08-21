# Changelog

## [Unreleased]

- Docs: **`ModelBehavior.md` restructured to read from the outside.** The
  generalizable results are hoisted into a `Key findings` section at the top,
  followed by a **tuning ledger** — all thirteen levers ever pulled on this
  workload, each described without assuming knowledge of this codebase, and
  grouped by _kind_ (context assembly / decoding / prompt wording / server
  code). The grouping is the finding: every change to what the model sees
  before the question moved behavior, while almost every change to the wording
  of the instructions did not. The file is now a candidate for a blog article
  rather than only a lab notebook.
- Docs: **redundancy removed from `ModelBehavior.md`.** The candidate table is
  now a pure roster — model, weights, portability, role, and the everyday +
  stress result that lives nowhere else — and no longer repeats the shape
  score, seed gain, or cascade figures the shape-coverage table already owns.
  Its `Cold start` column, which held everyday/stress numbers while the shape
  table's identically-named column held 25-shape numbers, is renamed. All six
  tables of three rows or fewer are inlined as prose, and the two superseded
  dated sweeps (2026-08-14, 2026-08-16) collapse to the three findings that
  outlived them — their per-model numbers disagreed with the current roster on
  eight of ten models, having been `--samples 1` runs replaced by the
  2026-08-20 re-measurement.
- Fixed: **three contradictions in `ModelBehavior.md`.**
  `qwen3.8:27b-nvfp4` was recorded as 24/25 with a seed gain of 0 in both
  tables and as 23/25 with a gain of −1 in its own section; the tables are
  authoritative and the section now matches. A claim that `granite4.1:8b`
  erodes shapes "without the seed" contradicted the table it cited, which is
  the seeded picture. And the `qwen2.5-coder:7b` section carried a stale
  4.7 GB and ~9 s/call against the tables' 4.4 GB and 2.3 s.

- Changed: **the seed is now opt-in — it is sent only when `--seed-card-file`
  names one.** There is no separate boolean and no implicit default, mirroring
  how the server already treats `--system-prompt-file`: a run says what it
  wants or gets nothing. One flag replaces the two this branch briefly had.
  Every figure in `ModelBehavior.md` was measured with `assets/seed_card.json`
  passed, so quoting one against an unseeded server quotes the wrong
  configuration; the launch configs pass it explicitly. A side effect worth
  knowing: the Markdown-prompt launch targets no longer seed at all, and
  prepending a card-shaped exchange to a server whose prompt asks for Markdown
  was always working against itself.
- Docs: **`ModelBehavior.md`'s shape-coverage table carries a Seed column** tagging what
  the flag is worth per model — **needs it** (+5 or more), helps (+2 to +4), no
  effect (0 or +1), _hurts_ (negative) — derived from the recorded runs rather
  than written by hand, so it cannot disagree with the columns beside it. Ten
  of fifteen models gain something; five gain nothing or lose. The extremes:
  **+9** shapes to `qwen3-coder:30b` and **+6** to `granite4.1:8b`, exactly
  **zero** to `qwen2.5-coder:7b` and `qwen3.8:27b-nvfp4`, and **−2** to
  `gpt-oss:20b`, the only model that answers all 25 shape cases and does so
  without it. A mechanism ranging from essential to mildly harmful depending on
  the model is one a host should be able to switch.
- Docs: `README.md` audited end to end against the new flag surface — the
  request-flow diagrams, the assembled-message description, the `/status`
  sample, and the seed sequence diagram all now show the seed as conditional,
  and the "sending no seed is not configurable" note is gone because it no
  longer is.
- Added: `/status` now reports `seedCard`. `seedCardTurns` reads 0 both when
  the seed is switched off and when the asset fails to parse, and those are
  different problems, so the boolean says which one a reader is looking at.
- Changed: **`.vscode/launch.json` now launches four models rather than three**
  — two large (`qwen3.8:27b-nvfp4`, `qwen3-coder:30b`) and two that fit a 16 GB
  host (`granite4.1:8b`, `qwen2.5-coder:7b`). The four span the full range of
  seed dependence by design, so relaunching `qwen3-coder:30b` with
  `--no-seed-card` and watching it drop from 23/25 to 14/25 is a two-click
  demonstration rather than a claim in a document.
- Docs: **`qwen3-coder:30b` joins the launch set on demo qualities rather than
  raw coverage.** At **1.6 s/call it is the fastest model measured**, ahead of
  models a quarter its weight; it **honors `format`**, which neither `nvfp4`
  build does; and it is the only model that answers both cold-start sets
  entirely in cards, never falling back to Markdown. For a demo somebody clicks
  through by hand, those beat a shape point.
- Docs: `ModelBehavior.md` now says "launch set" rather than "top three", since
  the set is four and expected to keep changing. The test that pinned it at
  three now asserts the invariants that actually matter — the compiled-in
  default is launchable, and no tag appears twice — rather than a count that
  churns.

- Fixed: **five stale `granite4.1:3b` claims that shipped in the correction
  itself.** The batch of edits correcting that model threw on its last
  statement, so the file was never written, and only the edits re-applied
  afterwards took effect. `ModelBehavior.md` consequently still described it as
  12/25 with 46 stalls, called its figures wholly incomparable with its earlier
  ones, said it dropped five shapes warm, and named it the slowest sweep in the
  file — all of which the corrected measurement contradicts. It scores 17/25
  cold and warm, stalls 13 times (11 of them unaided), and `gpt-oss:20b` at
  48 minutes is the longest sweep. Found by checking whether the findings
  claimed in review were actually in the document.

- Fixed: **`granite4.1:3b`'s 2026-08-20 figures were a measurement artifact,
  and are corrected.** It was published at 12/25 seeded with `n/a` on cascade
  and 52 stalled calls, which read as a small model collapsing under a per-call
  timeout. A leaked Ollama runner process was competing for the GPU throughout —
  `ollama stop` had returned while the model was still evicting, and the runner
  never reaped. Re-run on an idle machine it scores **17/25 and 3/3**, matching
  its earlier unbounded figures exactly. Two of the three "findings" reported
  about that model were the busy machine, not the model.
- Docs: what survives is narrower and more interesting. Seeded, the ceiling
  costs it nothing (2 stalls in 100 calls, same score as unbounded). **Unaided
  it stalls eleven times** and drops to 9/25 — without a card in front of the
  history it does not pick the wrong shape, it answers at length in prose until
  it hits the ceiling. That is what a +8 seed gain looks like from the inside,
  and it reproduces on an idle machine.
- Fixed: **`cascade_ab` reported a stalled call as prose.** A timed-out call
  returns an empty reply, and `judgeCascade` cannot distinguish that from a
  model that chose Markdown — six of `granite4.1:3b`'s timeouts were recorded
  as `t1 prose (no card attempted)`, which reads as an answer the model never
  gave, and were invisible to `ProbeRun.timeouts`. The probe now inspects the
  outcome before judging, and preserves the `t1`/`t2` distinction so a turn-2
  stall is not misreported as "never exercised".
- Added: **`tool/model_probes/sweep.sh`** — the sweep driver, previously
  unversioned. It encodes the two rules that are easy to get wrong: one model
  resident at a time, and **wait for eviction to finish**. `ollama stop` is
  asynchronous, and a probe started during the eviction window measured
  **3171 ms/call against 1324 ms** for the same model and the same 25 cases on
  a quiet machine. Waiting is not politeness; it is the difference between a
  latency figure and a fiction. The wait is bounded and warns rather than
  hanging, because a wedged runner must not stall a six-hour sweep.
- Docs: added a **mermaid sequence diagram** of the sweep methodology to
  `ModelBehavior.md`, covering model load, the serial call loop, the timeout
  and `abort()` path, and the unload — with the unload called out as
  load-bearing rather than housekeeping.
- Docs: recorded that **idle co-residency and active eviction are not the same
  hazard.** Across 3,555 calls the slow-but-successful rate was identical
  whether or not the previous model had been unloaded (5.0% vs 5.1%), so the
  published latency medians stand; but a runner actively evicting inflated a
  median 2.4x. Only stalls, never ordinary call times, were affected by the
  original sweep's missing unload.

- Docs: **re-measured every model in `ModelBehavior.md` end to end** — 15 models
  × 6 probes, 90 recorded runs, ~3,700 calls, one model resident at a time on
  the Apple M1 Max / 64 GB. Every figure in the file now derives from a
  committed result under `tool/model_probes/results/`, and the shape-coverage
  table is generated from those runs rather than transcribed.
- Docs: **the published matrix largely held up.** Ten of the twelve steady
  models reproduce within ±1 on every shape axis and two reproduce exactly, so
  the numbers are stable at ±1 resolution — which also means a one-shape
  difference between two models is noise, not a ranking, and the file now says
  so where it used to imply otherwise.
- Docs: **`gpt-oss:20b` produces a correct shape on all 25 cases unaided** —
  the only perfect score in the file under any condition — while scoring 23/25
  with the seed the server sends. The largest negative seed gain measured (−2),
  on the model that needs help least. Recorded as a live argument for making
  the seed conditional, and as a reason to revisit dropping it from
  `launch.json` rather than treating that as settled.
- Docs: **the card/prose split earned itself on the model that motivated the
  shape probe.** `llama3-chatqa:8b` sweeps the stress set 10/10 with **zero
  cards** — every pass is Markdown. That previously took a 100-call
  `shape_ab` run to discover; the 10-call stress probe now reports it directly.
  `granite4.1:8b`'s 10/10 is likewise 4 cards to 6 prose, while
  `qwen2.5-coder:7b` and `qwen3-coder:30b` answer every stress case with a real
  card.
- Docs: **`qwen3-coder:30b` looks stronger than its rejection implied.** It is
  the only model to answer both cold-start sets entirely in cards, it honors
  `format`, and at **1.6 s/call it is the fastest model measured** — ahead of
  models a quarter its weight. Its +9 seed dependence reproduced exactly and
  remains the case against it; the rejection was right on the evidence then
  available, and that evidence has changed.
- Docs: **`qwen3.6:27b-coding-nvfp4`'s missing stress run came back 8/10**, the
  weakest of the four strong large models. The measurement its `launch.json`
  case was waiting on closed against it. It also reproduced all three shape
  figures exactly — the only model to do so.
- Docs: added **Performance on this machine** with per-model latency, and a
  note on the per-call timeout. Weight predicts neither coverage nor speed:
  `granite4.1:3b` at 2.0 GB took **124 minutes with 46 stalls** while
  `qwen3.8:27b-nvfp4` at eight times the size took 39 with none. Stall risk,
  not gigabytes, is what a sweep should be budgeted by.
- Docs: **`granite4.1:3b` is the one model whose figures are not comparable
  across the sweep.** A 120-second per-call ceiling reclassifies its runaway
  generations as failures: 17/25 → 12/25 warm, and cascade 3/3 → `n/a`. The
  bounded figures are kept — the server has no timeout of its own, so a real
  user simply waits, and a card nobody waits for has failed — but the change in
  meaning is documented rather than published silently.

- Fixed: **`probeOnce` had no timeout, so one runaway generation hung a whole
  sweep.** `granite4.1:3b` was observed generating for **16 minutes** on a
  single `table` case with history and never returning; with several models
  queued behind it, nothing would have finished and nothing would have said
  which model or case was responsible. Calls now take a `--timeout` (default
  180 s, well clear of the ~49 s longest legitimate generation on record) and
  a stall is scored a failure labeled `timeout (Ns)` — its own label, so it is
  never mistaken for a wrong shape or invalid JSON. Found while smoke-testing
  the `--json` path, not by inspection.
- Changed: **every probe takes `--json` and `--timeout`**, added to the shared
  `parseProbeArgs` rather than per script, so recording a run is one flag
  everywhere. `cascade_ab` records `exercised` separately from `cases`, since
  a model whose turn 1 produced no card never cascaded at all.
- Added: **recorded probe results** (`tool/model_probes/probe_results.dart`,
  `shape_ab.dart --json`, `results/`). A probe run now writes every call it
  made, the headline figures, the host, and the **digests of the prompt assets
  it used** to a committed JSON file. Until now every number in
  `ModelBehavior.md` was hand-copied out of console output, which is
  unauditable three ways: a typo is invisible, a re-run cannot be diffed
  against the original, and a figure carries no record of _which_ version of
  `assets/card_system_prompt.txt` produced it — a file that has been edited six
  times, each edit silently turning every number in the doc into a historical
  one.
- Added: **`check_results.dart`, and it runs in CI** — which needs stating
  precisely, because the CI server cannot run a model. It checks the artifacts
  a hand-run probe left behind, which covers the three ways a published figure
  goes wrong unnoticed: **drift** (every score in the shape table is
  re-derived from the recorded calls, and a run whose own summary disagrees
  with its own calls is fatal), **staleness** (a result measured against a
  prompt asset since edited — fatal for a model `launch.json` launches, a note
  for the rest, because re-running fourteen models on every prompt edit is not
  a gate anyone would keep), and **gaps** (a launched model with a probe never
  run against it — the exact hole that let `gpt-oss:20b` hold a `launch.json`
  slot with its `format` support unmeasured).
- Changed: **`temperature_stress` now splits its pass count into cards and
  prose** — `pass 5/5 (6 card, 4 prose)`. `ProbeOutcome.ok` is true for a
  renderable card _and_ for clean prose, because the card prompt permits a
  Markdown answer and only a broken card is a failure. That is right for "did
  anything break" and wrong for "did we get cards", and the gap is not
  hypothetical: `qwen3.8:27b-nvfp4` swept the set 5/5 with four of ten cells
  answered in prose, and `llama3-chatqa:8b` swept both cold-start sets before
  scoring 1/25 on shapes. The distinction was previously recoverable only by
  reading the per-call labels by hand.
- Changed: **`shape_ab.dart` records per-call latency**, which it previously
  discarded — so the one fixed, identical-workload instrument in this
  directory was the only one that could not answer "how fast is this model".
- Added: a **Performance on this machine** section to `ModelBehavior.md`,
  with the host stamped into every result file. Median is taken over warm
  calls only: the first call after a model load costs 6-7x a warm one (51 s
  against 8 s), a large enough outlier to move any average. A second full run
  is deliberately _not_ taken — min-of-two is the usual noise filter, but the
  dominant noise here is that known load event rather than jitter, and on a
  laptop the second run is measured on a hotter, throttling machine, so
  min-of-two would trade one uncontrolled bias for another.
- Added: a **scope note at the top of `ModelBehavior.md`** saying none of this
  measurement was required to ship the demo. The card path turned out to be an
  unusually strict test problem — strict JSON, a closed element vocabulary, a
  shape that must fit the question, and format stability across turns, each
  with an unambiguous pass/fail — so the findings are about the models and
  should transfer to any workload asking a local model for schema-shaped JSON.
  Read it as a lab notebook, not a requirement.

- Changed: **`.vscode/launch.json` now launches `qwen3.8:27b-nvfp4` instead of
  `gpt-oss:20b`** as its large model. Both the card-prompt and Markdown-prompt
  configurations were swapped, along with the two compounds that launch them, so
  the grep `ModelBehavior.md` uses to derive the top three still yields exactly
  three models (`granite4.1:8b`, `qwen2.5-coder:7b`, `qwen3.8:27b-nvfp4`). The
  two models **tie on the figure the file says to read first** — 23/25 with
  history as shipped, and 24/25 cold — and `qwen3.8:27b-nvfp4` wins every other
  measured axis: everyday 21/21 vs. 17/21, stress 10/10 vs. 9/10, pre-seed warm
  24/25 vs. 22/25, one eroded shape vs. two, and it produces `Carousel` and
  `ColumnSet`, which `gpt-oss:20b` permanently fails as invalid JSON. Its seed
  gain is −1 against +1, so it is the more robust of the two unaided. The cost is
  **4.1 GB** (16.9 vs. 12.8), the one axis `gpt-oss:20b` still wins and the
  reason it stays a probed candidate rather than being retired. `format` was not
  traded away: neither model honors it, and `gpt-oss:20b` is the worse of the
  two on it. **`defaultOllamaModel` is unchanged** — the compiled-in default is
  still `qwen2.5-coder:7b`, which is a separate decision from what the debugger
  launches.
- Docs: added **`qwen3.8:27b-nvfp4`** to `ModelBehavior.md` and measured it on
  every probe in `tool/model_probes/` (2026-08-20, one model resident, 64 GB
  M1) — the fifteenth model in the matrix, added with every axis measured in
  one pass. Everyday 7/7 at all three temperatures;
  stress **5/5 at `t=0` and 5/5 at `t=0.6`**, matched only by
  `qwen3-coder:30b`; shapes **24/25 cold / 23/25 with history** seeded and
  **23/25 / 24/25** unaided; cascade 3/3.
- Docs: it is the **second usable model that is better without the card seed**
  (−1; `llama3-chatqa:8b` is also negative but scores 1/25),
  so it clears the seed-dependence bar that rejected `nemotron-3.5-lightning:30b`
  and `qwen3-coder:30b`, and its 24/25 unaided with-history ties the highest
  such figure in the file. It also **dominates its `qwen3.6:27b-coding-nvfp4`
  sibling on every comparable axis** — better cold-start (24/25 vs. 23/25),
  equal warm, 16.9 GB vs. 18.4 GB — and it produces `Carousel` and `ColumnSet`
  cleanly on every sample, the two nested shapes `gpt-oss:20b` and
  `qwen3.6:27b-coding-nvfp4` both permanently fail, showing that ceiling is not
  a property of the weight class. (It is not free of permanent misses overall:
  `rating_ask` fails under both conditions, so `qwen3-coder:30b` keeps its
  distinction as the only model failing no case under both.) It
  is additionally the first `nvfp4` model run through the stress set, which is
  the measurement `ModelBehavior.md` had named as the open question blocking the
  `qwen3.6` case. **`launch.json` unchanged** — recorded as a judgement call for
  whoever owns the debugger config.
- Docs: measured **`gpt-oss:20b`'s `format` support for the first time** while
  comparing it against `qwen3.8:27b-nvfp4` — it had never been probed, so the
  `format` blind spot recorded against the `nvfp4` builds had no baseline to be
  read against. It **also ignores `format`, and does so destructively**:
  `format=json` returns a zero-character body and `format=schema` returns
  non-card prose, where `qwen3.8:27b-nvfp4` returns the byte-identical good card
  under all three modes. So the constraint does not merely fail to help on the
  currently-shipped large model, it eliminates card production. `--json-format`
  must stay `none` for `gpt-oss:20b`. Noted alongside it that
  `json_format_probe.dart` scores all six of those calls `PASS`, because an
  empty reply is not a _broken card_ — the verdict line, not the PASS, is the
  output that matters for that probe.
- Docs: recorded two cautions with it rather than burying them. It **silently
  ignores Ollama's `format`**, returning byte-identical output under `none`,
  `json`, and `schema`, so `--json-format` is inert — two `nvfp4` builds now
  share this and `README.md` and the probe README were updated to describe it as
  a family trait to check rather than one model's quirk. And **four of its ten
  stress cells passed as prose rather than as cards**, which the stress set
  scores as a pass because the card prompt permits Markdown; the 5/5 means
  "nothing broke", not "ten good cards".

- Fixed: every probe crashed with an unhandled
  `type 'Null' is not a subtype of type 'Map<String, dynamic>'` when Ollama
  answered `200` with a body carrying no `message.content` — an error object,
  or a reply the runner cut short. `probeOnce` and `dump_reply.dart` both cast
  straight through to `message.content`; they now report the unusable body the
  way `OllamaResponder` already does, as
  `unexpected-response (no message.content)`, and `dump_reply.dart` also stops
  treating a non-200 as if it were a reply. Found on `gpt-oss:20b`, where the
  stack trace named nothing about the actual condition.
- Added: `cascade_ab.dart` and `cascade_cases.dart` — the first probe that
  scores a **two-turn edit** rather than a single reply. The server stores a
  card reply's raw JSON as `replyText` and replays it verbatim, so a follow-up
  turn arrives with the previous card in context; turn 1 asks for a pick-one
  list and turn 2 asks to widen it to multi-select, referring back rather than
  restating the items. A pass needs the turn-2 `Input.ChoiceSet` to be
  `isMultiSelect: true` **and** to keep every choice turn 1 offered. That last
  condition is the point: a model can cascade the format perfectly and quietly
  drop items off the list — observed dropping five states to three — and every
  other probe here scores that a pass, because the reply is a valid card of the
  requested type. Judged with the server's own `tryParseCardBody`; seed on by
  default, as the server ships. `test/cascade_judge_test.dart` covers the
  scoring without needing a model.
- Docs: added a **Cascade** column to `ModelBehavior.md`'s model table and
  measured every model for it. Thirteen score `3/3`; `llama3-chatqa:8b` is
  `n/a`, not `0/3`, because it answers turn 1 in prose and so never produces a
  card for turn 2 to edit — attributing that to the cascade would report a
  turn-1 shortcoming twice. The column separates no two usable models and is
  carried deliberately anyway: follow-up editing is the kind of behavior
  everyone assumes and nobody had measured, and the column records that it was
  checked on every model and holds wherever a card gets produced.
  `cascade_ab.dart` reports the same distinction, summarising untestable cases
  as "not exercised" rather than folding them into the failure count.

- Docs: measured the remaining seven pre-seed baselines
  (`shape_ab.dart --no-seed-card --samples 2`, `t=0`), so **all fourteen**
  models in `ModelBehavior.md` now carry a seed-dependence figure. The gain
  from the seed runs +11 to −1: it rescues `nemotron-3-nano:4b` from unusable
  (6/25 → 17/25) and carries most of the top group's score, but the two models
  that need it least are the two best on the unaided axis, so a high seeded
  score is not evidence of a good model until the pre-seed column is read
  beside it. Pre-seed erosion is concentrated in the `choice*` cases — five of
  eight models lose them to two prose turns — which names what the seed is
  actually protecting.
- Docs: **`qwen3.6:27b-coding-nvfp4` is now a live case to change the
  `launch.json` set**, and the first challenger to survive the seed-dependence
  test that rejected `nemotron-3.5-lightning:30b` and `qwen3-coder:30b`. It is
  the only model of fourteen that scores _better without_ the seed: 24/25 with
  history unaided, the highest with-history figure in the file under any
  configuration, against `gpt-oss:20b`'s 22/25. Against it: 18.4 GB vs.
  12.8 GB for no gain as the server actually runs (both 23/25 seeded), and it
  silently ignores Ollama's `format`. **`launch.json` unchanged** — recorded as
  a judgement call for whoever owns the debugger config, not a measurement
  gap. A stress-set run for it is the measurement that would settle it.

- Docs: measured `qwen3-coder:30b`'s pre-seed shape baseline
  (`shape_ab.dart --no-seed-card --samples 2`, `t=0`), the one open question
  left by the 2026-08-19 sweep. **16/25 cold, 14/25 with history** against
  24/25 and 23/25 with the seed — a +9 swing, tying
  `nemotron-3.5-lightning:30b` for the largest seed-dependence in the file,
  against `gpt-oss:20b`'s +1 from an already-strong 22/25. That settles the
  `launch.json` slot in `gpt-oss:20b`'s favour on the grounds already used to
  settle it once: it is the large model that does not need the seed.
  `launch.json` unchanged. Also recorded a mechanism the comparison exposes —
  9 of `qwen3-coder:30b`'s 11 unaided with-history failures are invalid JSON
  (the missing-array-brackets signature), so the seed repairs JSON framing and
  not only shape choice.

- Changed: `shape_ab.dart`'s card seed is now **on by default**
  (`--no-seed-card` opts out). The flag had been opt-in since before the seed
  shipped, so a bare probe run measured a configuration
  `OllamaResponder.reply()` had stopped using — the probe and the server could
  drift apart silently, which is the one failure this directory exists to
  prevent. No recorded number changes: every figure in `ModelBehavior.md` was
  taken with the flag passed explicitly, and passing it still works.

- Docs: `ModelBehavior.md`'s candidate table now carries an as-shipped 25-shape
  score for **all fourteen** models, not six. The remaining eight were measured
  on 2026-08-19 under the full-set table's own conditions (`--seed-card
--samples 2`, `t=0`, both conditions), replacing the pre-seed
  `choiceset_ab.dart` `N/6` figures the table had been carrying. Two of those
  `N/6` scores turned out to badly under-predict the model:
  `hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` went 1/6 → 22/25 and
  `qwen3-coder:30b` 2/6 → 23/25, both pre-seed collapses the seed recovers.
  `qwen3-coder:30b` measures as the strongest candidate in the file (24/25
  cold, 23/25 warm, no shape it fails under both conditions); `launch.json` is
  **unchanged** pending a pre-seed baseline for it, since the case that kept
  `gpt-oss:20b`'s slot over `nemotron-3.5-lightning:30b` was robustness without
  the seed. Two findings generalized: `rating_ask` now fails on 8 of 14 models
  with the identical show-vs-collect substitution (a prompt problem), and the
  seed's over-carding of the `prose` control case is now 5 of 14 rather than
  the single model the 2026-08-18 run flagged.

- Changed: the seed exchange moved out of Dart source into
  **`assets/seed_card.json`**, beside the system prompts, and is re-read per
  request — so it can be re-tuned without a rebuild. `--seed-card-file`
  (server) and `shape_ab.dart --seed-card-file` (probe) point at a candidate,
  the way `--system-prompt-file` and `--candidate` already do for prompts;
  both sides read the same asset by default, so a probe measures what the
  server sends. The **content** is configurable but sending **no seed** is
  not, because a seed is what every recorded measurement was taken with; a
  missing or malformed file degrades to no seed with a `WARNING` rather than
  refusing requests, and `GET /status` gained `seedCardFile` /
  `seedCardTurns` so that degradation is visible instead of silent. Roles
  must alternate from `user` — Ollama chat templates mangle a seed that opens
  with an assistant turn, which would read as a model failure rather than a
  bad asset. `test/seed_card_test.dart` pins the shipped bytes to the content
  `ModelBehavior.md`'s numbers were measured against, so re-tuning the seed
  fails the suite until the new content is measured and the record updated.

- **Breaking:** `OllamaResponder.reply()` now prepends a synthetic
  card-shaped exchange (`lib/src/seed_card.dart`) ahead of the replayed
  history on every request — unconditionally, with no opt-out. This is a code
  change, not a prompt edit: `assets/card_system_prompt.txt` is unmodified. It
  won a five-candidate screen as the only mechanism that moved the server
  default, then held across six models on the full 25-shape set — cold-start
  coverage rose on 6 of 6 models and with-history on 5 of 6
  (`qwen2.5-coder:7b` 19/25 → 21/25 cold, 18/25 → 19/25 warm). It also costs
  tokens on every request, newly erodes `table` with history on 4 of the 6
  models, and regressed `llama3-chatqa:8b`'s with-history score. Full numbers,
  the four trade-offs, and what the standing regression gates can and cannot
  cover are in `ModelBehavior.md` — "Warm-start prose drift" and "Promoted:
  N2".

- Added: `shape_ab.dart` and `shape_cases.dart` — a shape-aware probe that
  asks whether a reply used the element type the question called for, not just
  whether it rendered. 25 cases run cold-start and again after two prose
  turns, judged by a seven-outcome classifier (`judgeShape`), with the shapes
  a model produces cold and then loses with history derived from the two
  pass-sets so the count can never disagree with its own list. It exists
  because judging replies only as "renders or not" left 23 of 24 advertised
  element types unverified and scored an unclickable Markdown options list as
  a pass. `--reinforce` and `--seed-card` implement the two message-assembly
  drift candidates; `--baseline`/`--candidate` A/B two prompt files.

- Added: `collectElementTypes` and `cardContainsAnyType` in
  `probe_support.dart` — one recursive element-type walker shared by the
  probes, reporting every `type` present anywhere in a parsed card body
  including inside `Carousel` pages, `Table` cells, and `Column` items.
  `choiceset_ab.dart` now uses it instead of a private copy; its prompts,
  conditions, and output are unchanged, so its recorded scores stay
  reproducible.

- Fixed: `judgeShape`'s negative-control branch could score a reply the server
  itself calls broken (invalid JSON, duplicate keys, prose wrapping a card) as
  `prose-ok`, because it checked `outcome.ok` only after already deciding the
  reply wasn't a card. Also fixed: the doubled `broken: broken: invalid JSON…`
  label (`judgeShape` re-prefixing what `judgeReply` had already prefixed),
  and `--only` with a blank value silently running zero cases instead of
  exiting 2.

- Added: measurements, recorded in `ModelBehavior.md` rather than here — six
  `shape_ab.dart` 25-case baselines (`qwen2.5-coder:7b`, `gpt-oss:20b`,
  `llama3-chatqa:8b`, `granite4.1:8b`, `llama3-groq-tool-use:8b`,
  `nemotron-3.5-lightning:30b`), the five-candidate warm-start drift screen
  and its full-set confirmation, and a delivery check establishing that a
  mid-conversation `system` message reaches `gpt-oss:20b` but is unconfirmed
  on `qwen2.5-coder:7b` and `granite4.1:8b` — which is what makes a
  scores-at-baseline result on those models unreadable rather than negative.

- Changed: the top three is now `gpt-oss:20b`, `granite4.1:8b`, and
  `qwen2.5-coder:7b`. `granite4.1:8b` replaces `qwen3.5:9b` in
  `.vscode/launch.json` (both its card-prompt and markdown-prompt
  configurations) on the strength of the 25-case sweep: 22/25 with history as
  shipped, second only to `gpt-oss:20b`, in 5.0 GB. `qwen3.5:9b` has never
  been run through `shape_ab.dart` at all — its only with-history number is a
  six-prompt `choiceset_ab.dart` score — and its own notes already record it
  as offering no reliability edge over `qwen2.5-coder:7b` at more latency and
  memory. Rationale, and why `gpt-oss:20b` keeps the large-model slot over
  `nemotron-3.5-lightning:30b`, are in `ModelBehavior.md`.

- Changed: the `With history` column of `ModelBehavior.md`'s candidate table
  now leads with each model's `shapes N/25` score **as the server ships** —
  measured with the unconditional card seed in place — rather than the
  pre-seed `N/6` choice-set score, which is retained beside it for the models
  that have nothing better. Two rows read as self-contradictory as a result
  (`nemotron-3.5-lightning:30b` and `llama3-groq-tool-use:8b` each scored 0/6
  pre-seed and recover their whole choice-set path with the seed); the note
  under the table says the shape figure is the current one.

- Changed: `ModelBehavior.md`'s `With history` column uses one denominator for
  every model. `qwen2.5-coder:7b` was the only cell measured at `--samples 2`,
  so it read `6/12` in a column of `N/6` scores and invited a wrong
  at-a-glance comparison. Re-run at `--samples 1` it scores 3/6, passing and
  failing exactly the same three prompts each as the 12-trial run — a change
  of resolution, not of finding. The `2/12 → 6/12` before/after is kept where
  it justifies promoting the escape-hatch change.

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
