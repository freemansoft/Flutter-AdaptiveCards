# Changelog

## [Unreleased]

- Docs: **the M1 Max Ollama 0.33.2 sweep is a null result on latency.** All
  fifteen models were re-measured on the same machine with identical weights
  under 0.33.2 against the 0.32.14 archive; 13 of 15 per-model median ratios
  land in 0.86-1.05x. No latency difference between the two Ollama versions
  was demonstrated.
- Docs: **the sweep's premise did not survive its own control.** It was run
  to test whether `qwen3.5:9b` running faster on the M5 than the M1 Max (an
  earlier 0.8x reading) was a runtime effect. A same-host, same-runtime
  control on `qwen3.5:9b` — hot against cold, position 0 against warm — found
  a **1.54x position bias**, larger than the 0.8x gap it was offered to
  explain. Read at matched runtime instead, every model is slower on the M5,
  1.15x to 2.32x; see the same-runtime host comparison in
  [`ModelBehavior.md`](ModelBehavior.md).
- Changed: **`probe_support.dart` now sends an unload (`keep_alive: 0`) after
  a probe call times out**, and results are labelled before and after runner
  eviction. What was measured: `llama3.2:latest` re-run after runner eviction
  reproduces the 0.32.14 archive exactly (seeded 12 stalls/15-12 -> 2
  stalls/15-15; unaided 19 stalls/9-12 -> 0 stalls/15-12), so its 31 recorded
  stalls were 2 real and 29 queued. `granite4.1:3b` re-run the same way does
  not move (14 seeded stalls before and after), and its unaided stalls still
  sit in contiguous blocks at calls 0-20 and 89-99. The unload is not shown
  to cancel a running generation: sent 3 s into an 18 s generation in a
  direct test it completed at 20.9 s (`ollama stop`: 16.3 s), and 53 unloads
  answered in ~8 ms each did not stop a 70-minute generation during the
  granite run. Why `request.abort()` alone was insufficient is NOT
  established — an isolated reproduction of the runaway call cancels
  correctly, and the sweep's did not. `evictModel` closes its client on every
  path and writes one stderr line naming the model when the unload fails.
- Changed: **the shape-coverage table in `ModelBehavior.md` now derives from
  the Ollama 0.33.2 runs instead of the 0.32.14 archive.** Eleven of fifteen
  models have identical coverage across the two runtimes, which is what makes
  the move safe. Four moved: `gpt-oss:20b`, `granite4.1:3b`,
  `qwen3.6:27b-coding-nvfp4`, and `qwen3.8:27b-nvfp4` — see their per-model
  notes for the figures. `granite4.1:3b`'s row is labelled cascade-damaged
  in the notebook and is not a model measurement (next bullet but one).
- Docs: **`gpt-oss:20b`'s seed direction reversed between runtimes.** Under
  0.32.14 it scored 25/25 unaided and 23/25 seeded — the only 25/25 in the
  file, with the seed costing it 2 shapes. Under 0.33.2 it scores 25/25
  seeded and 22/25 unaided — still the only 25/25, now reached with the seed
  rather than without it, a +3 gain rather than −2. Same machine, same
  weights; no mechanism for the reversal is established. Four
  `ModelBehavior.md` claims built on the old direction ("the only 25/25 in
  this file", "the strongest unaided model", "the sole 25/25 under any
  condition") are corrected accordingly.
- Known issue: **`granite4.1:3b`'s 0.33.2 figures differ from 0.32.14, cause
  not established; recorded as OPEN.** It records 14 seeded and 32 unaided
  timeouts under 0.33.2 against 2 and 11 under 0.32.14, and seeded coverage
  reads 17/12 against 17/17. Re-running it after runner eviction changed none
  of that, but the re-run's unaided stalls sit at calls 0-20 (the probe's cold
  opening cases) and 89-99, 21 cold and 11 warm, with the first non-stalled
  call taking 86 s — the queue-cascade signature — and the unload is not
  shown to cancel a generation, so "unchanged by eviction" does not separate
  a model property from a cascade. No regression is established; its 0.33.2
  shape and stall figures are recorded as cascade-damaged, not as a model
  measurement. The open question is whether a runaway generation can be
  cancelled at all, and how.
- Changed: **every per-host results directory now names its Ollama version.**
  `results-m1max-64gb/` became `results-m1max-64gb-ollama032/` and
  `results-m5-16gb/` became `results-m5-16gb-ollama033/`, beside the
  `results-m1max-64gb-ollama033/` added by the 0.33.x sweep. A bare
  `results-m1max-64gb/` sitting next to an `-ollama033` sibling read as "the
  other one", and its runtime was recoverable only from a rotating server log.
  `shapeTableDir` and `sync_shape_table.dart` follow the rename.
- Added: **`results-m1max-64gb-ollama032/PROVENANCE.md` recovers the
  archive's runtime as Ollama 0.32.14** from the one surviving server-log
  line (`Listening on [::]:11434 (version 0.32.14)`, 2026-08-21T13:34:28).
  That line covers 2026-08-21T13:34 onward; the archive spans 2026-08-20 and
  2026-08-21, and the two earlier server restarts in that window are not
  corroborated by anything on disk. The 113 archived result files are not
  backfilled — each records what the probe stamped.
- Changed: **`check_results.dart` scopes the shape-table check to one
  directory.** `check()` takes a `tableResults` parameter and `main()` passes
  the runs under `shapeTableDir` (`results-m1max-64gb-ollama033`), so a
  second directory for the same host no longer keys two runs by one model;
  the host filter remains the fallback for single-directory data.
- Fixed: **`check_results_test.dart`'s real-tree check compared the shape table
  against two runtimes at once.** It called `check()` without `tableResults`, so
  it fell back to the host filter and keyed two runs by the same model once a
  second Apple M1 Max directory held real data. It now mirrors `main()` and
  scopes to `shapeTableDir`.

- Added: **`blog/` directory — a series plan and drafts of the first three
  articles** derived from `ModelBehavior.md`. `blog/README.md` is the plan:
  it assigns each article a topic it owns outright and records what it defers
  to the others, so no two articles tell the same story, and it carries the
  conventions once — figures traced to a named `ModelBehavior.md` commit and
  transcribed verbatim, every score named with its test set and condition,
  the ±1 noise floor, the do-not-quote ban on the superseded 2026-08-14/16
  sweeps, the repo's documentation register, and three attribution placements
  using absolute GitHub URLs. It also names articles 4 (the tool channel) and
  5 (measurement hygiene), which the drafts commit to by naming them. Drafted:
  article 1 frames the demo as a local-model benchmark, article 2 covers the
  tuning process (the fourteen-lever ledger, the card seed, and the open
  `rating_ask` lever), article 3 compares the two measurement hosts and owns
  the 16 GB-fit question, article 4 carries the tool-channel failure
  decomposition, and article 5 the measurement-hygiene lessons — the
  co-residency mismeasurement, the delivery check behind an unmeasurable null,
  and what survived discarding the superseded sweeps. Articles 1–4 each carry
  an HTML-comment placeholder for the one visual they still need; article 5
  carries a mermaid diagram of the sweep loop. Every link in the directory
  points at this repository: `ModelBehavior.md` references are pinned to the
  commit the figures were read at, and code and asset links track `main`.

- Docs: **`ModelBehavior.md` deduplicated and reorganized for reuse.** Each
  headline story now has one home, with links replacing repeated tellings: the
  seed's model-dependence in the card-seed section, `gpt-oss:20b`'s unaided
  25/25 in its per-model notes, the busy-machine mismeasurement in the sweep
  section, and the 0/8-vs-8/8 prompt result stated once instead of twice. The
  three meta sections at the top merged into one; four measurement-methodology
  lessons moved from Key findings to a new "Measurement lessons" subsection;
  the M5 position-bias caveats compressed from five paragraphs to three; a new
  "Open questions and future work" section collects items previously scattered
  as asides; roster cells now carry figures rather than editorial annotations;
  and the inline 15-model ranking that duplicated the shape table's sort
  column was removed. Also removed a stale paragraph claiming the launch.json
  grep yields three models — it yields four, as the same section says. The
  "words this file uses" section moved to a Glossary at the end of the file
  and gained entries for the rest of the file's vocabulary (shape, warm,
  erosion, cascade, stall, canary, escape hatch, and others), with a pointer
  left at the top. No figure changed.
- Fixed: **the M5 thermal claim was overstated, and `granite4.1:8b`'s row is
  back to its in-sweep run.** A hot re-run made that model 1.20x its own cold
  run, and the row was swapped to the hot figure on the reasoning that it made
  the eight rows comparable. It did the opposite: the hot run was taken at 4h05m,
  more exposed than any row in the sweep, and the only row not drawn from the
  sweep at all. The rows sit on a 17-minute-to-3h52m gradient rather than being
  hot or cold, so the table now uses each model's own sweep slot and documents
  the gradient. `granite4.1:8b` reads 3.3 s / 17 min again.
- Changed: **the 1.20x figure is reported as unreplicated.**
  `qwen2.5-coder:7b` does not reproduce it — 1.03x, slightly slower cold — and a
  third `granite4.1:8b` run after 7h37m idle came back 1.12x its first, so two
  nominally cold measurements differ by 12% systematically. An effect that size
  sitting on a floor that size is not cleanly separable from it. Thermal
  throttling stays plausible and unproven: no die temperature or clock frequency
  was read, and server uptime, ambient temperature, and OS state all varied.
- Fixed: **the sweep diagram said 6 probes when there are 7.** It had gone stale
  when a probe was added; `expectedProbes` in `check_results.dart` carries the
  real count.
- Docs: **`ModelBehavior.md` defines probe, sweep, and sweep driver.** It used
  "probe" 61 times and "sweep" 43 without introducing either, and "sweep driver"
  appeared once, as an unexplained label in a sequence diagram. The vocabulary
  now sits before first use, including that "sweep" means both one model's seven
  probes and all models end to end — the two senses the `Full sweep` column and
  the four-hour figure each use. The sweep section also opens with prose rather
  than with a mermaid diagram.

- Changed: **`check_results.dart` reads every host, not one.** It read only
  `results-m1max-64gb/`, so the 58 files of the Apple M5 sweep were committed
  without CI ever checking them. It now discovers every `results-*` directory
  and checks 171 runs. Self-consistency and asset staleness apply to all hosts;
  the shape-table and launch-set-coverage checks stay scoped to the host the
  table describes, since running them across hosts would key two runs by the
  same model and report a mismatch that is not one.
- Added: **two checks that guard the per-host layout.** A results directory
  holding runs from more than one host now fails — `sweep.sh` writes wherever
  `SWEEP_RESULTS` points, so a sweep aimed at the wrong directory files one
  machine's timings under another's name and nothing looks wrong until someone
  compares hosts. And a directory that stamps the Ollama version on some runs
  but not all now fails, which is the shape of the `shape_ab.dart` bug that left
  18 of one sweep's 58 files without a runtime.

- Added: **`ModelBehavior.md` records latency for a second host.** The eight
  models the roster marks 16 GB-capable were swept on an **Apple M5 / 16 GB**
  MacBook Air on Ollama 0.33.1, and the performance table now carries both hosts
  in one table rather than asserting one. Seven of the eight cost 1.0-1.5x the
  Apple M1 Max / 64 GB figures; `qwen3.5:9b` runs faster on the smaller host.
  **Superseded 2026-09-02: that last clause does not survive.** The two hosts
  were measured at different positions in their sweeps, and re-running one model
  hot against cold on a fixed host and runtime measured a **1.54x** position
  bias — larger than the 0.8x it was offered to explain. Read as a null result.
  Shape coverage reproduced the M1 Max on six of eight exactly, which is what
  says the difference is the box and not the measurement.
- Added: **the fanless M5 throttles 1.20x over a four-hour sweep**, measured by
  re-running `granite4.1:8b` 13 seconds after the sweep ended and comparing with
  its cold first run. Uniform at every percentile with zero stalls either way,
  so a clock reduction rather than slow outliers. Its hot run is the published
  one, so all eight M5 rows are comparable; no correction factor is applied to
  any row.
- Fixed: **`llama3-chatqa:8b`'s median read 0.3 s** where 253 ms and 248 ms — a
  2% difference across hosts — printed as "0.3 s" against "0.2 s" beside a 1.0x
  ratio. Sub-second medians now print two decimals.

- Changed: **probe results are stored per host.** `tool/model_probes/results/`
  is now `results-m1max-64gb/`, beside `results-m5-16gb/`. The old name read as
  "the results" when it was always one machine's, which mattered little while
  there was one and misleads once there are two. `check_results.dart`,
  `sync_shape_table.dart`, and their tests follow the rename; the dated entries
  below still name the old path, which is where those runs lived at the time.
- Changed: **`sweep.sh` requires `SWEEP_RESULTS`** rather than defaulting. There
  is no directory that is right for every host, and a wrong one fails quietly
  in both directions: run() skips models whose JSON already exists, so a sweep
  aimed at another host's directory records nothing, and aimed at a fresh one it
  files these timings under that host's name. This mirrors `--system-prompt-file`
  and `--seed-card-file` -- a run says what it wants or gets nothing.

- Docs: **tone pass over `ModelBehavior.md`, `README.md`, and this file — analyst
  register, not publicist.** Wording only: no figure, date, verdict, or claim
  changed, verified by diffing the numeric tokens of each file against the
  previous commit. Rhetorical framing became statements ("Is X the better large
  model? No." → "X is not the better large model"), amplifiers were dropped
  ("helped decisively" → "helped", "collapses to 9/25" → "falls to 9/25"), and
  vague superlatives were replaced with the figure they stood for ("the only
  perfect score in this file" → "the only 25/25"). Two headings were renamed and
  their inbound links updated. Bold is now reserved for section claims and
  figures rather than for emphasis.
- Measured: **why the tool channel did not pay — a failure decomposition, no new
  model calls.** Re-scored both arms of the shape A/B from the shipped results
  JSON, bucketing every failed call by the judge's own `label`. Malformed JSON
  went to zero on all eight models, which is what the channel was expected to
  fix, but two costs replace it: declining to call the tool (0–4% of card cases
  on the four qwen models, 11–50% on the four losses) and weaker element choice
  (`nemotron-3-nano:30b` +12 wrong-shape, `:4b` +22). The outcome is a
  subtraction rather than a model category — malformed failures recovered minus
  declines and shape regressions gained — which accounts for all eight rows,
  including the two the ±1 noise floor leaves unexplained. Architecture does not
  separate the groups (`qwen3-coder:30b` and `nemotron-3-nano:30b` are the same
  class with opposite results); thinking is untested, since every probe sends
  `think: false`. Also records that the phase-1 canary over-predicted
  willingness by testing a single card request, and that the channel converts
  detected failures into silent ones. In `ModelBehavior.md`.
- Measured: **the tool channel does not pay, and nothing ships.** `shape_ab.dart`
  gained `--channel prose|tool`, and the 25 shape cases were run through Ollama's
  tool channel on the 8 models that can use it at all, scored against each
  model's recorded unaided prose run. Result: **2 wins, 2 unaffected, 4 losses**,
  two of the losses by 5 shapes. Half the capable models get materially worse, so
  it could not be a default, and two beneficiaries out of fifteen roster models
  did not justify a second code path through the reply loop. There is **no
  `--reply-channel` flag** and the server is unchanged. What ships is the
  measurement — `tool/model_probes/tool_channel.dart` and the `--channel` option —
  so the finding is re-checkable when models change. Full table and a do-not-retry
  note in `ModelBehavior.md`.
- Added: **`shape_ab-channel-tool` is registered conditionally.** Only a model
  whose `tool_call_probe` verdict is `supported` can produce this run, so
  `check_results.dart` gates the expectation on that verdict and `sweep.sh` skips
  the rest — otherwise `qwen2.5-coder:7b`, the compiled-in default, would report a
  permanently missing result for a run it can never perform.

- Fixed: **unknown-element-type detection no longer flags types the client
  renders correctly.** `TextRun`, `AdaptiveCard`, and every `Action.*` type
  are legal `type` values in positions `$defs/ChildElement` never lists —
  `RichTextBlock.inlines`, `Action.ShowCard.card`, and an `actions` array,
  respectively — because that enum is an element vocabulary, not every legal
  `type` value. `unknownElementTypes` now tolerates these explicitly instead
  of flagging them, which matters because false positives on a warn-only
  check corrupt the fire-rate metric the check exists to collect.
- Fixed: **`tool_call_probe.dart` recorded digests for assets it never sent.**
  `writeProbeRun`/`currentAssetDigests` hardcoded `card_system_prompt.txt` and
  `seed_card.json`, but the tool-calling probe runs unseeded against
  `card_tool_prompt.txt` instead. Both now take an `assetNames` list, and the
  15 already-recorded `tool_call_probe.json` files were corrected in place to
  digest the asset they actually used — no model was re-run, since the asset
  has not changed since those runs were measured.
- Added: **`shape_ab.dart --channel prose|tool`.** The tool arm offers a
  `render_adaptive_card` function and converts its arguments into the reply
  string a prose answer would have carried, so `judgeShape` and every existing
  scoring rule — including the negative control — apply unchanged rather than
  growing a parallel set that could drift from the path it is compared against.
  The shared tool definition moves to `tool_channel.dart` so the canary and the
  A/B cannot disagree about what they offered. `--channel tool` refuses to run
  with the seed card and defaults to `card_tool_prompt.txt`.

- Docs: **tool-calling capability measured across all fifteen models.**
  `ModelBehavior.md` gains a tool-calling canary section recording which
  models can return a card through Ollama's tool channel. 8 of 15 verdict
  `supported`, so the phase-2 gate (a channel dimension in `shape_ab.dart`)
  opened; 3 can call a tool but never reach for the card tool
  (`supportedButDeclines`, including `llama3-groq-tool-use:8b`, fine-tuned
  for tool use), 2 leak the card tool onto a plain prose question
  (`overCalls`), and 2 — including `qwen2.5-coder:7b`, the compiled-in
  default model — expose no tool-calling path at all (`unsupported`).
  `check_results.dart` and `sweep.sh` now track `tool_call_probe` like every
  other per-model probe.

- Added: **`tool_call_probe.dart`, a tool-calling capability canary.** Answers
  whether a model can return a card through Ollama's tool channel rather than
  the prose channel, using three checks — a card request, a prose negative
  control, and a trivial unrelated tool that separates "cannot call" from
  "chose not to". Verdicts are `supported`, `unsupported`,
  `supportedButDeclines`, and `overCalls`. Ships with
  `assets/card_tool_prompt.txt`, the tool-channel recast of the card system
  prompt. Runs unseeded: the seed card is a prose-channel artifact.

- Added: **unknown-element-type detection (`lib/src/element_types.dart`).**
  `loadKnownElementTypes` reads the schema's `ChildElement` vocabulary and
  `unknownElementTypes` walks a parsed card body for anything outside it,
  at any nesting depth. A misspelled type such as `Textblock` is valid JSON
  that renders as an invisible blank, so it is the one failure a user sees
  and no probe scores. A missing or malformed schema disables the check
  rather than failing requests.

- Added: **`OllamaResponder` warns when a rendered card carries an
  unrecognized element type.** Warning only — the card still renders, because
  suppressing it over one bad nested element may be worse than an invisible
  blank, and the observed fire rate is the evidence for whether to promote
  this to a rejection. `/status` reports `knownElementTypes`, which is `0`
  when the vocabulary failed to load and the check is inert.

- Changed: **`card_schema.json` now mirrors the renderable registry.** The
  `Element` enum grew from 24 to 33 types, adding `Media`, `Container`,
  `RichTextBlock`, `ActionSet`, `ImageSet`, `Input.Rating`, `CompoundButton`,
  `Accordion`, and `TabSet`. `card_schema_test.dart` now reads `registry.dart`
  and the charts registry as source text, so the schema and the renderable
  vocabulary can no longer drift apart silently. Note this **loosens**
  `--json-format schema`: on models that honor `format`, the grammar now admits
  33 types where it admitted 24. The system prompt is unchanged, so what the
  model is asked to produce is unchanged. `Chart.VerticalBar.Grouped` and
  `Chart.HorizontalBar.Stacked` are renderable but stay out by decision, now
  recorded as an explicit exclusion set rather than an absence. `ActionSet` is
  the one entry where the widened enum and the prompts now disagree: both
  `card_system_prompt.txt` and `card_tool_prompt.txt` tell the model not to
  include an `ActionSet`, but the enum admits it because mirroring the
  registry — what the client can render — is this task's stated intent, while
  the prompt separately governs what the model is asked to produce.
- Fixed: **the chart-type count was wrong wherever it was counted.** A
  `Chart\.[A-Za-z]+` pattern truncates `Chart.HorizontalBar.Stacked` to
  `Chart.HorizontalBar` and dedupes it away, reporting 6 types where the charts
  registry declares 8. Anything counting chart types must match the
  multi-segment form.
- Changed: **shape coverage is pinned to the prompt palette, not the schema
  enum.** Widening the enum split two meanings that had been one: the enum now
  records what the client can render, while `shapeCases` is about what the model
  is asked to produce. A shape case for a type the prompt never advertises would
  fail on every model forever. This also makes the test agree with the
  `shapeCases` doc comment, which already claimed the prompt as its reference.
  The new `promptElementTypes()` reads bullet headings as well as `"type":"X"`
  examples, because `Input.Text`, `Input.Number`, and `Input.Time` share one
  bullet with no example between them.

- Added: **`$defs/ChildElement` in `card_schema.json`.** A 38-type vocabulary
  covering every legal position — the 33 top-level types plus `CarouselPage`,
  `TabPage`, `Column`, `TableRow`, and `TableCell`, which the prompt nests but
  no registry switch declares. Nothing in the schema references it and
  `--json-format schema` is unaffected; it exists so a validator can recognize
  nested elements.

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
  entirely in cards, never falling back to Markdown. For a demo someone clicks
  through by hand, those matter more than a single shape point.
- Docs: `ModelBehavior.md` now says "launch set" rather than "top three", since
  the set is four and expected to keep changing. The test that pinned it at
  three now asserts the invariants that actually matter — the compiled-in
  default is launchable, and no tag appears twice — rather than a count that
  churns.

- Fixed: **`granite4.1:3b`'s 2026-08-20 figures were a measurement artifact,
  and are corrected.** It was published at 12/25 seeded with `n/a` on cascade
  and 52 stalled calls, which read as a small model failing under a per-call
  timeout. A leaked Ollama runner process was competing for the GPU throughout —
  `ollama stop` had returned while the model was still evicting, and the runner
  never reaped. **Qualified 2026-09-02:** a second mechanism produces the same
  signature, and that run's logs are gone, so this attribution is no longer the
  only candidate. A single runaway generation holds Ollama's one slot while
  later calls queue behind it and time out without reaching the model, turning
  one stall into dozens. `granite4.1:3b` recorded **52 stalls again** on
  2026-09-01 with `loaded runners count=1` on every load — co-residency
  excluded. Which mechanism produced the August figure is not recoverable. Re-run on an idle machine it scores **17/25 and 3/3**, matching
  its earlier unbounded figures exactly. Two of the three "findings" reported
  about that model were the busy machine, not the model.
- Docs: what survives is narrower. Seeded, the ceiling
  costs it nothing (2 stalls in 100 calls, same score as unbounded). **Unaided
  it stalls eleven times** and drops to 9/25 — without a card in front of the
  history it does not pick the wrong shape, it answers at length in prose until
  it hits the ceiling. That is the mechanism behind its +8 seed gain, and it
  reproduces on an idle machine.
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
  a quiet machine. Waiting is what separates a usable latency figure from a
  meaningless one. The wait is bounded and warns rather than
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
  the only 25/25 in the file under any condition — while scoring 23/25
  with the seed the server sends. The largest negative seed gain measured (−2),
  on the model that needs help least. Recorded as a live argument for making
  the seed conditional, and as a reason to revisit dropping it from
  `launch.json` rather than treating that as settled.
- Docs: **the card/prose split paid off on the model that motivated the
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
- Fixed: **`probeOnce` had no timeout, so one runaway generation hung a whole
  sweep.** `granite4.1:3b` was observed generating for **16 minutes** on a
  single `table` case with history and never returning; with several models
  queued behind it, nothing would have finished and nothing would have said
  which model or case was responsible. Calls now take a `--timeout` (default
  180 s, well clear of the ~49 s longest legitimate generation on record) and
  a stall is scored a failure labeled `timeout (Ns)` — its own label, so it is
  never mistaken for a wrong shape or invalid JSON. Found while smoke-testing
  the `--json` path, not by inspection. **Incomplete, corrected 2026-09-02:**
  bounding the call did not stop the generation. Ollama kept running the
  abandoned request and serves one at a time, so later calls queued behind it
  and recorded stalls they never reached the model to earn. The probe now also
  evicts the runner on timeout.
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
  for the rest, because re-running every probed model on each prompt edit is not
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
  measurement was required to ship the demo. The card path turned out to be a
  strict test problem — strict JSON, a closed element vocabulary, a
  shape that must fit the question, and format stability across turns, each
  with an unambiguous pass/fail — so the findings are about the models and
  should transfer to any workload asking a local model for schema-shaped JSON.
  Read it as a lab notebook, not a requirement.

- Docs: added **`qwen3.8:27b-nvfp4`** to `ModelBehavior.md` and measured it on
  every probe in `tool/model_probes/` (2026-08-20, one model resident, 64 GB
  M1) — the fifteenth model in the matrix, added with every axis measured in
  one pass. Everyday 7/7 at all three temperatures;
  stress **5/5 at `t=0` and 5/5 at `t=0.6`**, matched only by
  `qwen3-coder:30b`; shapes **24/25 both cold and with history**, seeded and
  unaided alike — a seed gain of zero; cascade 3/3. It holds the large-model
  `launch.json` slot on the strength of that with-history figure, the highest
  in the file.
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
- Docs: recorded two cautions with it. It **silently
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
  condition is the point: a model can cascade the format correctly and silently
  drop items off the list — observed dropping five states to three — and every
  other probe here scores that a pass, because the reply is a valid card of the
  requested type. Judged with the server's own `tryParseCardBody`; seed on by
  default, as the server ships. `test/cascade_judge_test.dart` covers the
  scoring without needing a model.
- Changed: the seed exchange moved out of Dart source into
  **`assets/seed_card.json`**, beside the system prompts, and is re-read per
  request — so it can be re-tuned without a rebuild. `--seed-card-file`
  (server) and `shape_ab.dart --seed-card-file` (probe) point at a candidate,
  the way `--system-prompt-file` and `--candidate` already do for prompts;
  both sides read the same asset by default, so a probe measures what the
  server sends. A missing or malformed file degrades to no seed with a
  `WARNING` rather than refusing requests, and `GET /status` gained `seedCardFile` /
  `seedCardTurns` so that degradation is visible instead of silent. Roles
  must alternate from `user` — Ollama chat templates mangle a seed that opens
  with an assistant turn, which would read as a model failure rather than a
  bad asset. `test/seed_card_test.dart` pins the shipped bytes to the content
  `ModelBehavior.md`'s numbers were measured against, so re-tuning the seed
  fails the suite until the new content is measured and the record updated.

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

- Fixed: an ongoing Markdown conversation stopped the model producing cards.
  The escape hatch was keyed on confidence ("if you are unsure
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
  or temperature difference — so whichever one had been implicit would
  eventually hand someone the other kind of reply with no indication why.
  Refusing to guess costs one flag and removes that confusion. The chat client is the only consumer, so nothing external breaks.

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
  symptom people report, scored as a pass by every probe. `card_detect.dart`
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
  longer carries into the rest of the conversation.
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
