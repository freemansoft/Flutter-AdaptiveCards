# Blog series: local models and strict-shaped output

Working directory for blog articles derived from
[`ModelBehavior.md`](../ModelBehavior.md), the lab notebook recording which
local Ollama models produce renderable Adaptive Cards and what it took to make
them reliable.

This file is the series plan: what each article owns, what it defers to another,
and the conventions all of them share. It is the one place those decisions live
— an article that restates another's ownership boundary is how two articles end
up telling the same story.

**The notebook is the source of every figure.** These articles carry no
measurement of their own; they select from and explain what is already recorded.
When the notebook and a draft disagree, the notebook wins.

## The articles

| #   | Article                                                                   | File                                         | Status                  |
| --- | ------------------------------------------------------------------------- | -------------------------------------------- | ----------------------- |
| 1   | An SDUI demo that turned into a local-model benchmark                     | `2026-08-29-article-1-origin-story-*`        | Drafted, image needed   |
| 2   | Fourteen levers for reliable card JSON from a local model                 | `2026-08-30-article-2-tuning-process-*`      | Drafted, image needed   |
| 3   | The same benchmark on a 64 GB M1 Max and a 16 GB M5                       | `2026-08-30-article-3-m1max-vs-m5-*`         | Drafted, chart needed   |
| 4   | The tool channel drove malformed JSON to zero and lost on half the models | `2026-08-30-article-4-tool-channel-*`        | Drafted, diagram needed |
| 5   | The measurement was wrong, in a way that looked exactly like a slow model | `2026-08-30-article-5-measurement-hygiene-*` | Drafted                 |

All five articles are drafted. Article 5 carries a mermaid diagram of the sweep
loop rather than an image placeholder, so it needs no visual work.

**Audience:** developers running local models on Ollama who need structured
output. Secondary: Flutter and server-driven-UI readers.

**File naming:** `YYYY-MM-DD-article-N-slug-draft.md`.

## What each article owns

An article owns a topic outright: it carries the mechanism, the figures, and the
caveats, and every other article links to it rather than re-explaining. The
deferrals below are the reason the series does not repeat itself.

**Article 1 — the benchmark.** The four constraints a card reply imposes at
once. The three test classes and how each denominator is built. The
`llama3-chatqa:8b` case — sweeping both cold-start sets while producing one
correct shape in twenty-five — and the generalization that renderable prose is
not always a pass. The fifteen-model shape-coverage spread. The tool-calling
canary's four-way split (supported / declines / over-calls / unsupported).
Judging with the parser the server ships.

_Defers:_ the seed's per-model value and everything tuning to article 2;
hardware fit and latency to article 3; the full tool-channel decomposition to
article 4; the harness lessons to article 5. It names the `granite4.1:3b`
co-residency mismeasurement in one paragraph because the reader needs to trust
the figures immediately; article 5 owns the full treatment.

**Article 2 — the tuning process.** The fourteen-lever ledger and the claim that
Kind predicts the outcome better than the specific change does. **The card seed
outright** — mechanism, the per-model range from +10 to −2, and all four costs.
Decoding settings, including the `format` canary's three behaviors. Prompt
wording: two wins, three nulls, one revert. The detector as the only durable
fix. `rating_ask` as the largest open prompt lever.

_Defers:_ the tool channel's failure decomposition to article 4. Article 2
already states the win/loss table (2 wins, 2 unaffected, 4 losses) and one
example of the channel converting a detected failure into a silent one — what
it does not carry is the per-bucket accounting (malformed / declined /
wrong-shape / infra) that explains the losses, or the architecture and
phase-1-canary findings built on top of it.

**Article 3 — the two hosts.** The 16 GB fit question outright, including the
detail article 1 defers to it. The M5 ÷ M1 Max ratio band and why it does not
track weight. The `llama3.2:latest` artifact row. The runtime-version confound
that makes a per-row ratio a comparison of two configurations rather than two
machines. Thermal throttling as plausible and unproven.

_Defers:_ bad assertions and undelivered `system` messages to article 5.

**Article 4 — the tool channel.** How the two arms are paired, including why the
tool arm is scored against the unseeded prose run. The eight-model comparison.
The failure decomposition: malformed JSON recovered, minus declines and shape
regressions gained, and why that subtraction accounts for all eight rows
including the two the noise floor leaves unexplained. Architecture not
separating wins from losses, and the chat template predicting better. The
phase-1 canary over-predicting willingness. The channel converting detected
failures into silent ones.

_Defers:_ the canary's four-way split to article 1, recapping it in one sentence
as setup. Its figures are the only unseeded shape figures in the series, which
it states rather than assumes.

**Article 5 — measurement hygiene.** The full `granite4.1:3b` co-residency
account that articles 1 and 3 only name. Why a stall is the most misread
measurement in the set, and what the per-call timeout changes. Suspect the
harness before the model — a fence-stripping bug and a bad assertion, both
blamed on models first. A null result means nothing until delivery is
established, and a delivery probe must not contradict the system prompt. Judge
with the parser you ship; derive published tables rather than transcribe them.
When to discard numbers and what survives discarding them.

_Defers:_ the `llama3.2:latest` M5 artifact row and the throttling analysis to
article 3, referencing them in one clause as a second instance of the
re-run-on-an-idle-machine rule.

## Conventions

### Figures

- **Every figure traces to `ModelBehavior.md`.** The drafts were written against
  commit `ba02fd98`. Re-check against the file at head before publishing, and
  when drafting a new article, verify each figure in the notebook directly —
  do not trust an intermediate document that quotes it.
- **Transcribe verbatim.** Do not round, paraphrase, or recompute a score.
- **Every score carries its test set and its condition.** An `n/m` is
  uninterpretable without both. Everyday and stress figures are cold-start;
  shape figures come in cold-start and with-history flavours and the two differ.
  Never quote one against the other. Tuning figures additionally carry their
  model and temperature — `6/10 → 15/15` is not quotable without `at t=0`.
- **Shape figures are seeded unless stated otherwise**, and the seed is worth
  +10 to −2 by model, so a seeded score named without its configuration is
  half a fact.
- **The noise floor is ±1.** Shape figures are `--samples 2`; everyday and
  stress are `--samples 1`. A one-point difference between two models is noise
  rather than a ranking — a re-measurement moved ten of twelve steady models by
  ±1 with nothing about them changing.
- **Do not quote the superseded 2026-08-14 and 2026-08-16 sweeps** as current
  results. The notebook marks them do-not-quote: they disagree with the
  2026-08-20 re-measurement on eight of ten models. A failure _mode_ first seen
  there may always be named. One narrow exception, which the notebook itself
  takes: a figure from those sweeps may illustrate a _methodological_ finding —
  as article 5 does with the 6/7-then-2/5 pair behind "the easy set does not
  discriminate" — but only when labelled as superseded at the point of use, and
  never as a model's score.

### Register

The repo's documentation-tone rules, as in
[`CLAUDE.md`](../../CLAUDE.md): state results plainly, replace superlatives with
the figure they stand for, reserve bold for a section's load-bearing claim and
for figures, hedge inferred mechanisms, and end on the last factual sentence.

Counts are measured; the explanation for them usually is not. Report negative
results as plainly as wins — articles 2 and 4 are substantially negative results
and they must not read as apologies.

### Attribution

Three placements per article, because a reader who stops early should still be
able to reach the source:

1. **First screen** — name and link the repo.
2. **Beside the artifact under discussion** — a reproduced table needs its
   source anchor next to it, not in the closing paragraph.
3. **Close** — the repo and the notebook, both URLs spelled out.

**All links are absolute GitHub URLs.** Repo-relative paths break the moment an
article leaves the repository. This applies to inline artifact names too:
`assets/card_system_prompt.txt` and `lib/src/card_detect.dart` are links, not
bare filenames.

**Two link targets, and the distinction is deliberate.** References to
`ModelBehavior.md` are pinned to the commit the figures were read at
(`/blob/ba02fd98/…`), including the one in the closing paragraph, so a quoted
figure still resolves after the notebook changes. Links to code and assets
track `/blob/main/` — a reader following them wants the current file, not an
archived one.

### Presentation

- Prefer a table to a prose list anywhere a section compares more than two
  things.
- A wide source table needs fitting to blog width — either split it into
  per-category mini-tables placed with the prose that discusses them, or shorten
  the widest column and move its content into prose. Do not trim an Evidence
  column; that is where the figures live.
- Section headings state a finding, not a verdict.
- Image and chart placeholders are HTML comments describing what the visual
  should show, including any data it needs. Article 3's chart placeholder
  carries its eight data pairs and its required caption.

## Writing a new article

Articles 1–3 were drafted from per-article outlines that specified section
order, a word budget per section, the figures each section quotes, and explicit
"do not write X" traps guarding known misreadings. Those outlines were removed
once the drafts existed and were verified — maintaining a second description of
an article that already exists is drift waiting to happen.

The structure is worth reusing for articles 4 and 5:

- A section list with a word budget each, summing to the target length.
- The figures each section quotes, with the arithmetic behind any denominator
  spelled out so the drafter cannot guess it.
- The tables the article needs, with their rows named.
- The traps: for each figure that is easy to misread, a sentence saying what not
  to write. These caught more errors than any other part of the outlines.
- Where the three attributions go, and which visuals are needed.
