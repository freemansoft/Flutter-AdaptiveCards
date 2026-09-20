# Blog series: local models and strict-shaped output

Working directory for blog articles derived from
[`ModelBehavior.md`](../ModelBehavior.md), the lab notebook recording which
local Ollama models produce renderable Adaptive Cards and what it took to make
them reliable.

This file is the series plan: what each article owns, what it defers to another,
and the figure and naming conventions all of them share. How to write, review,
and publish an article is in the `adaptive-cards-blog-writing` skill. This file
is the one place the series decisions live, because an article that restates
another's ownership boundary is how two articles end up telling the same story.

**The notebook is the source of every figure.** These articles carry no
measurement of their own; they select from and explain what is already recorded.
When the notebook and a draft disagree, the notebook wins.

## The articles

| #   | Article                                                                               | File                              | Status                                                                                                                          |
| --- | ------------------------------------------------------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 1   | An SDUI demo that turned into a local-model benchmark                                 | `article-1-origin-story-*`        | **Published**, republished 2026-09-16 with the corrected four-way split                                                         |
| 2   | We tried 14 levers to get reliable card JSON from a local model                       | `article-2-tuning-process-*`      | **Published**, republished 2026-09-16. One further fix in the repo awaits a republish, see below                                |
| 3   | Running local models for Adaptive Card JSON on a 64 GB M1 Max and a 16 GB M5          | `article-3-m1max-vs-m5-*`         | **Published.** Revised 2026-09-08, mermaid chart, register pass 2026-09-12, cut pass 2026-09-14                                 |
| 4   | Ollama's tool channel beats prose for card JSON on every model that calls it          | `article-4-tool-channel-*`        | **Published** 2026-09-17, after the rewrite against the re-measurement and a review pass. Retitled and republished 2026-09-18   |
| 5   | Eight measurement rules from a local-model benchmark on Ollama                        | `article-5-measurement-hygiene-*` | **Published** 2026-09-18, rewritten rules first with the Ollama 0.34.0 `granite4.1:3b` control                                  |
| 6   | Ollama silently drops a history message larger than its context window                | `article-6-context-fill-*`        | **Published** 2026-09-20, after the review against the notebook, the Ollama 0.34.0 re-runs, a flowchart and a retitle           |
| 7   | A full context breaks three local models, each in a different way                     | `article-7-full-context-cost-*`   | Not published. Split from 6 on 2026-09-12, mermaid chart, register pass 2026-09-12; retitled and third failure added 2026-09-19 |
| 8   | Ollama's prompt cache reused a shared system prompt on one model and not on the other | `article-8-prompt-cache-*`        | Not published. Split from 5 on 2026-09-18, no visual                                                                            |

**Articles 1 to 6 are published; 7 and 8 are not.** What is published cannot
be silently corrected, so a finding that moves under re-measurement is tracked
here until the live post carries it. A repo fix and a republish are two steps,
and the table below records both.

Articles 1 and 2 were corrected and republished on 2026-09-16, after the
tool-channel re-measurement moved the capability probe's four-way split and
reversed the tool-channel lever's verdict. One correction is still owed:
article 2's claim that card failure "usually arrives as invalid JSON rather
than as a wrong choice of element" does not hold against the archive it quotes,
which gives 101 against 104. That fix is in the repo and needs a second
republish.

Article 4 was retitled and republished on 2026-09-18. The earlier title,
"Ollama's tool channel produces better cards, when the model remembers to use
it", read as though some models forget the tool entirely; the notebook records
66 to 96 of 100 calls using it on every model in the comparison.

Articles 1 to 5 are drafted and have their visuals: articles 3 and 4 carry
mermaid diagrams in place of image placeholders (article 5 already had one),
and articles 1 and 2 have real screenshots from the demo client. Article 7 took
the mermaid chart of the cases each model gains or loses when its window is
filled. Article 6 gained a mermaid flowchart on 2026-09-20: one request, the
allocation rule, the two causes of an overflow and the three outcomes.

The 2026-09-08 revision removed every em dash from articles 1 to 5 (see the register
rules in the `adaptive-cards-blog-writing` skill), framed the chat demo as a demo rather than a production
architecture, and rewrote the closing headings of articles 1, 2 and 5 to state
a finding.

Articles 6 and 7 were added 2026-09-12, when the notebook gained a context-fill
section. They are the first articles in the series whose subject postdates the
original plan, and they took one caveat back into article 3: every latency
figure in the series before them was measured against a nearly empty context,
which article 3 now says in its own caveat list.

They were drafted as one article and split the same day, on topic rather than on
length: the draft was 1823 prose words, well inside the cap. The split separates
a runtime finding from a model finding, which a reader may want separately.
Article 6 is 1073 prose words and article 7 is 1290.

**Audience:** developers running local models on Ollama who need structured
output. Secondary: Flutter and server-driven-UI readers.

**Publication target:** <https://joe.blog.freemansoft.com>.

**File naming:** `article-N-slug-draft.md`.

**Publishing to Blogger:**
[`tool/blog/to_blogger.dart`](../tool/blog/to_blogger.dart)
converts a draft to semantic HTML with no styling of its own, unwrapping the
78-column source wrapping that Blogger would otherwise render as `<br>`.

```sh
fvm dart run tool/blog/to_blogger.dart blog/<draft>.md | pbcopy
```

It writes to stdout, so a generated page never lands in the tree; these are
transient and are not checked in. The `<h1>` is dropped because Blogger has its
own title field, and each image `src` becomes an `{{IMAGE_URL:<path>}}` token to
substitute after uploading the image through the Blogger editor. Paste into the
HTML view and publish from the HTML view: the Compose view re-serializes the
document, which is the usual way a pasted table gets flattened.

The script does not convert mermaid fences. Render each diagram to a PNG beside
the drafts and replace the fence with an image before converting.

## What each article owns

An article owns a topic outright: it carries the mechanism, the figures, and the
caveats, and every other article links to it rather than re-explaining. The
deferrals below are the reason the series does not repeat itself.

**Article 1: the benchmark.** The four constraints a card reply imposes at
once. The three test classes and how each denominator is built. The
`llama3-chatqa:8b` case, which clears the two usability sets almost entirely in
prose while producing one correct shape in twenty-five, and the generalization
that renderable prose is not always a pass. The fifteen-model shape-coverage
spread. The tool-calling canary's four-way split (supported / declines /
over-calls / unsupported). Judging with the detector the server runs.

_Defers:_ the seed's per-model value and everything tuning to article 2;
hardware fit and latency to article 3; the full tool-channel decomposition to
article 4; the harness lessons to article 5. It names the `granite4.1:3b`
co-residency mismeasurement in one paragraph because the reader needs to trust
the figures immediately; article 5 owns the full treatment.

**Article 2: the tuning process.** The fourteen-lever ledger and the claim that
Kind predicts the outcome better than the specific change does. **The card seed
outright**, meaning mechanism, the per-model range from +10 to −2, and all four
costs.
Decoding settings, including the `format` canary's three behaviors. Prompt
wording: two wins, three nulls, one revert. The detector as the only durable
fix. The `rating_ask` palette omission: its cause, the `Input.Rating` fix and
its uneven repair, and the seven models not yet re-measured against the new
palette.

_Defers:_ the tool channel's failure decomposition to article 4. Article 2
already states the win/loss table (2 wins, 2 unaffected, 4 losses) and one
example of the channel converting a detected failure into a silent one. What
it does not carry is the per-bucket accounting (malformed / declined /
wrong-shape / infra) that explains the losses, or the architecture and
phase-1-canary findings built on top of it.

**Article 3: the two hosts.** The 16 GB fit question outright, including the
detail article 1 defers to it. The M5 ÷ M1 Max ratio band, read at matched
Ollama versions, and why it does not track weight. The `llama3.2:latest`
artifact row. The 1.54x sweep-position bias that bounds how precisely any
single row's ratio can be read. Thermal throttling as plausible and unproven.

Both hosts run the same Ollama line, so the article compares machines and never
runtimes: a figure from a pre-0.33 runtime does not appear in it. Stall
counts not being comparable across runtimes belongs to article 5, which owns it
as a methodological finding rather than as a host comparison, on 0.33.x and
0.34.0 figures only.

Every figure in it was measured against a nearly empty context, a probe call
being a system prompt, one question and at most a two-turn seed. That is a
property of the whole series before article 6 and it is stated in article 3's
caveat list, because article 3 is the one carrying latency figures a reader
might otherwise generalize to a long conversation.

_Defers:_ runner eviction and the queue cascade to article 5.
What the runner allocates and what happens to history
that does not fit, to article 6. What a full context costs a model's coverage,
to article 7.

**Article 4: the tool channel.** That offering a tool does not oblige a model
to use one, so a tool-arm score blends two channels until something records
which path a reply took. The per-call split once it does: the tool wins on
every model where it is actually called, and adoption is what the shape score
was measuring. Malformed JSON as the bulk of the gain, and why a tool call
structurally cannot carry it. History suppressing tool-calling harder than it
suppresses card shape.
The retry on parse failure: 43 of 99 recovered, why the total hides a split
between models, and why the shipped model needs neither half of it.

_Defers:_ the capability probe's four-way split to article 1, recapping it in
one sentence as setup. Its figures are the only unseeded shape figures in the
series, which it states rather than assumes. Its per-call rates are the only
per-call figures in the series; every other article quotes `n/25` cases.

**Article 5: measurement hygiene.** It opens on eight rules grouped by when
they apply, and each later section is the evidence for one of them. The
2026-08-20 `granite4.1:3b` incident under Ollama 0.32.14, a runner still
evicting while the next model's probes ran, which article 1 names in one
paragraph and defers here. That incident is the article's only pre-0.33
material: the fence-stripping bug, the `rows >= 3` assertion, the delivery
check and the superseded 2026-08-14 and 2026-08-16 sweeps are in the notebook
and in no article. **The queue-cascade material outright**: the 2026-09-01
sweep's 52 stalls with one runner resident, how one abandoned generation is
recorded as many stalls, the same 52 calls stalling index for index before
and after the unload-on-timeout change, and that change clearing
`llama3.2:latest`'s stalls only. The unload tests on 0.33.2 and 0.34.0: an
unload does not cancel a running generation and a client disconnect does.
The three-column `granite4.1:3b` control that separates the 0.34.0 runtime
from the `Input.Rating` prompt edit: the runtime stopped the cascade and the
prompt removed the runaway. Why the 120 s ceiling stays. Silent truncation of an oversized system prompt, as the mistake that first made the prompt cache read as broken. Judging with the detector the server ships, and what it cannot
see.

Its prose runs to about 2,300 words, past the 2,000 target, because it owns eight rules and each carries its own measurement. The prompt-cache readings were split out to article 8 on 2026-09-18 for that reason and because they support no rule.

_Defers:_ the `llama3.2:latest` M5 artifact row and the throttling analysis to
article 3; it recaps article 3's sweep-position control in one paragraph, as a
second instance of the same discipline that resolves the stall counts: isolate
the confound, measure it, do not read a mechanism off a net number.

**Article 6: the filled context.** Everything about running a model with its
window actually full. The allocation rule, `min(requested, trained window)`,
measured on both hosts with no counterexample in fifty-one runs across
Ollama 0.33.3 and 0.34.0, and the
reading that retires host memory as a factor. **The silent whole-message drop
outright**: history that exceeds the allocated window is removed rather than
trimmed, nothing errors, and `prompt_eval_count` is the only signal. The
per-tokenizer spread, 4.30 characters per token against 2.74 on the same text,
and the probe defect it caused: a filler sized in characters overflowed the
window sized for it, and three models were written up as discarding history
they had room for when no such model existed. The two `nvfp4` builds that
evaluate roughly 6,700 tokens past their reported allocation, which separates
what the runner allocates from what it enforces, and their Ollama 0.34.0
empty-window and full-window-that-fits baselines: the overrun scores within one case of a full window, and the filled runs two to five cases below an empty one, which `--samples 1` does not establish as a cost. The two 8192-window models keeping a
filler that fits. The 0.34.0 reproduction of the fixed-filler sweep on all
fourteen models.

_Defers:_ the general form of "suspect the harness before the model" to
article 5, naming its own instance in one clause rather than re-deriving the
principle. Host-to-host latency and the 16 GB fit question to article 3; it
quotes no ratio and no sweep timing, because its runs are `--samples 1` at one
fill size and carry no position control.

**Article 7: what a full window costs a model.** The filled-context measurement
for eight models, five moving by three cases or fewer and three losing a quarter
to a third of their shape coverage. **The failure decomposition outright**: the
three largest losses are three different failures, `nemotron-3.5-lightning:30b`
abandoning card output for prose, `nemotron-3-nano:30b` emitting well-formed
cards with a `TextBlock` where an `Input.*` was asked for, and
`qwen3.8:27b-nvfp4` emitting bodies that do not parse, with the consequence that
a parse check catches the first and third and misses the second. The two
`nvfp4` builds' empty-window arm comes from an Ollama 0.34.0 run, which the
article states beside the table. The reordering, in which a model ahead
on an empty window falls behind on a full one. The `qwen2.5-coder:7b` partial
reversion at roughly half the fill, which is the only sign in the set that the
effect begins below a full window.

_Defers:_ everything about the runtime to article 6, including what `num_ctx`
does, what the runner allocates, and how history that does not fit is removed.
It states in one paragraph that its fill sizes were verified as delivered and
cites article 6 for why that needed verifying, rather than re-deriving the
tokenizer defect.

**Article 8: the prompt cache.** What Ollama's prefix cache saves a chat
server, measured with `prompt_eval_cached_count` under Ollama 0.33.3 by
`prefill_cache_probe.dart`: five request patterns on `llama3.2:latest` on
both hosts and on `qwen3.8:27b-nvfp4` on the M1 Max. A conversation turn pays
prefill for its new tokens only, on both models. **The new-conversation miss
outright**: a byte-identical system prompt with a different first question
reuses the cache on `llama3.2:latest` and misses entirely on
`qwen3.8:27b-nvfp4`, on three runs, with the cause not established. The
retry-after-abort cost, stable on one model and unstable on the other.

_Defers:_ the truncated-prompt mistake that first made the cache read as
broken to article 5, naming it in one paragraph because the probe's prompt
size depends on it. What the runner allocates and what happens to oversized
history to article 6.

### Resolved: the M5 calibrated run

Landed 2026-09-12. The three models a 16 GB host can hold were re-run under the
M1 Max's calibrated parameters, and article 7 now carries the comparison: prompt
counts identical to the digit, two of three scores unchanged, one case apart on
the third. Article 7 keeps its M1 Max attribution for the eight-row table, since
five of those rows are still single-host, and states the three-row cross-host
confirmation beside the reproduction paragraph rather than adding a column that
would be empty for five models.

The same run added a second fill level with the window held constant, which
answered a caveat article 7 had left open. Pooled coverage runs 47/75 near-empty,
42/75 half and 42/75 full, so the filled-context cost is neither proportional to
occupancy nor a cliff. Article 7's closing caveat was narrowed to what is still
open: the two 30-billion-parameter Nemotron builds that carry the largest losses
were not among the three models measured that way.

What the same run withdrew is worth recording, because it is the kind of figure
an article would otherwise have quoted. The latency medians from these runs do
not reproduce: `nemotron-3-nano:4b` medians 13356 ms and 3506 ms on the same host
a day apart at a 5% larger prompt, and the cross-host direction flips between
those days. Pass and token columns reproduce across every one of those runs and
the medians do not, so no article carries a latency claim from the fit control.
Article 3 owns host-to-host latency and its figures are from the shape sweep,
which is unaffected.

## Conventions

How to write, review, verify, and publish an article (openings, register,
headings and titles, terminology, attribution, presentation, and the outline for
a new article) is in the `adaptive-cards-blog-writing` skill,
[`.claude/skills/adaptive-cards-blog-writing/`](../../.claude/skills/adaptive-cards-blog-writing/SKILL.md).
The two sections below stay here because they are facts about this notebook's
figures and the series' names, which every article and the skill depend on.

### Figures

- **Every figure traces to `ModelBehavior.md`.** While the articles are
  drafts, all five link the notebook at `/blob/main/`, and a change that
  moves a notebook finding updates the affected drafts in the same change.
  At publication, pin all five articles to the same commit, the one the
  figures were last verified against, so a quoted figure still resolves
  after the notebook moves on. Re-check against the file at head
  before publishing, and when drafting a new article, verify each figure in
  the notebook directly rather than trusting an intermediate document that
  quotes it.
- **Transcribe verbatim.** Do not round, paraphrase, or recompute a score.
- **Every score carries its test set and its condition.** An `n/m` is
  uninterpretable without both. Everyday and stress figures are cold-start;
  shape figures come in cold-start and with-history flavours and the two differ.
  Never quote one against the other. Tuning figures additionally carry their
  model and temperature: `6/10 → 15/15` is not quotable without `at t=0`.
- **Shape figures are seeded unless stated otherwise**, and the seed is worth
  +10 to −2 by model, so a seeded score named without its configuration is
  half a fact.
- **The noise floor is ±1.** Shape figures are `--samples 2`, meaning every case
  runs twice and is scored a pass only if both runs passed, so one borderline
  call takes the whole case, while everyday and stress run each case once, at
  `--samples 1`. Gloss that rule at an article's first use of the flag; the
  bare number does not say what a second run does to a score. A one-point
  difference between two models is noise rather than a ranking, and a
  re-measurement moved ten of twelve steady models by ±1 with nothing about
  them changing.
- **Name the probe that produced the figure**, not only the set and the
  condition. `shape_ab.dart`, `temperature_matrix.dart`, `tool_call_probe.dart`
  and the rest ask different questions, and a reader who cannot tell which one
  ran cannot tell what the number claims. The same applies to a sweep: "one
  shape sweep", not "one sweep".
- **When more than one component can reject a reply, say which one judged.**
  The server's `card_detect` decides card-vs-prose, a server-only vocabulary
  check warns on unknown element types, and the Flutter client does the real
  Adaptive Cards parse. Calling any of them "the parser" claims validation that
  only the client performs.
- **State what the scores cannot see, beside the scores.** An invented element
  type clears the detector and reaches the user as an invisible blank; no set
  scores it. A blind spot named once in the article is worth more than a
  qualifier attached to every figure.
- **A vendor-published spec may support an inference the notebook does not
  measure, but only with the notebook's own hedge attached.** The notebook's
  bandwidth table and its GPU-core-count paragraph, both in
  [Performance, by host and runtime](../ModelBehavior.md#performance-by-host-and-runtime),
  are the pattern: cite the vendor page inline, name the exact SKU and
  workload a multiplier was measured for (an M5 Max figure is not a base M5
  figure; prompt processing is not decode), and call the result "consistent
  with" a direction rather than "established as" a cause. A draft that adds a
  new vendor figure backfills it into the notebook in the same change, next to
  the existing spec table, so the next article can cite it the same way.
- **Do not quote the superseded 2026-08-14 and 2026-08-16 sweeps** as current
  results. The notebook marks them do-not-quote: they disagree with the
  2026-08-20 re-measurement on eight of ten models. A failure _mode_ first seen
  there may always be named. One narrow exception, which the notebook itself
  takes: a figure from those sweeps may illustrate a _methodological_ finding,
  as the notebook does with the 6/7-then-2/5 pair behind "the easy set does not
  discriminate", but only when labelled as superseded at the point of use, and
  never as a model's score.

### Terms and units

Most of the rewriting these drafts needed was a term doing two jobs at once, not
a wrong figure.

- **Define a term before scoring against it.** An article that opens on
  `21/21` against `1/25` has to have said what each set asks first, or the
  reader reconciles two numbers they cannot yet interpret.
- **A condition and a test set must not share a name.** Cold start and with
  history are _conditions_ the shape probe runs under; everyday, stress and
  shape are _sets_. "Both cold-start sets" collapses the two and is
  unrecoverable for a reader.
- **One name per condition, series-wide.** _Cold start_ and _with history_ are
  the shape probe's condition names; do not introduce _warm_ (or any other
  synonym) for the with-history condition, though a table header may abbreviate
  to `w/ history`. "Warm" keeps its other senses, a warm call after a model
  load or a warm cache, which is exactly why the condition cannot also own it.
- **One unit per quantity, series-wide.** A prose _exchange_ is a question and
  its answer; a _turn_ is one message. Pick one and use it everywhere: the
  same history was described as "one prose turn" in one paragraph and "two
  prose turns" in another.
- **Do not write a non-fraction as `n/m`.** Every score in the series is
  `n` of `m` cases, so a cold/with-history pair written `15/12` reads as a
  score. Write `15/25 cold and 12/25 with history`.
- **Name the metric the score measures.** Shape coverage is whether the reply
  used the element type the question called for. It is not accuracy, quality,
  or correctness, and a model can be entirely correct and score 4/25.
- **Gloss a probe or case identifier the first time it appears.** `rating_ask`
  and `cascade` mean nothing to a reader who has not opened the repo.
