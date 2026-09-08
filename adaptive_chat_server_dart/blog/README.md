# Blog series: local models and strict-shaped output

Working directory for blog articles derived from
[`ModelBehavior.md`](../ModelBehavior.md), the lab notebook recording which
local Ollama models produce renderable Adaptive Cards and what it took to make
them reliable.

This file is the series plan: what each article owns, what it defers to another,
and the conventions all of them share. It is the one place those decisions live,
because an article that restates another's ownership boundary is how two
articles end up telling the same story.

**The notebook is the source of every figure.** These articles carry no
measurement of their own; they select from and explain what is already recorded.
When the notebook and a draft disagree, the notebook wins.

## The articles

| #   | Article                                                                      | File                                         | Status                                             |
| --- | ---------------------------------------------------------------------------- | -------------------------------------------- | -------------------------------------------------- |
| 1   | An SDUI demo that turned into a local-model benchmark                        | `2026-08-29-article-1-origin-story-*`        | Drafted, revised 2026-09-08, screenshot added      |
| 2   | We tried 14 levers to get reliable card JSON from a local model              | `2026-08-30-article-2-tuning-process-*`      | Drafted, revised 2026-09-08, screenshots added     |
| 3   | Running local models for Adaptive Card JSON on a 64 GB M1 Max and a 16 GB M5 | `2026-08-30-article-3-m1max-vs-m5-*`         | Drafted, revised 2026-09-08, mermaid chart added   |
| 4   | The tool channel drove malformed JSON to zero and lost on half the models    | `2026-08-30-article-4-tool-channel-*`        | Drafted, revised 2026-09-08, mermaid diagram added |
| 5   | The measurement was wrong, in a way that looked exactly like a slow model    | `2026-08-30-article-5-measurement-hygiene-*` | Drafted, revised 2026-09-08                        |

All five articles are drafted and have their visuals: articles 3 and 4 carry
mermaid diagrams in place of image placeholders (article 5 already had one),
and articles 1 and 2 have real screenshots from the demo client.

The 2026-09-08 revision removed every em dash from all five (see **Register**),
framed the chat demo as a demo rather than a production architecture, and
rewrote the closing headings of articles 1, 2 and 5 to state a finding.

**Audience:** developers running local models on Ollama who need structured
output. Secondary: Flutter and server-driven-UI readers.

**File naming:** `YYYY-MM-DD-article-N-slug-draft.md`.

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
runtimes: a figure from a pre-0.33 runtime does not appear in it. The
cross-runtime material, stall counts not being comparable across versions and
the ceiling's effect on one 0.32.14 figure, belongs to article 5, which owns it as
a methodological finding rather than as a host comparison.

_Defers:_ bad assertions and undelivered `system` messages to article 5.

**Article 4: the tool channel.** How the two arms are paired, including why the
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

**Article 5: measurement hygiene.** The `granite4.1:3b` stall-signature
account in full, which article 1 names in one sentence and article 3 names in
one clause, both deferring the account here. Co-residency and a queue cascade
both produce the identical 52-stall signature, and which one caused the original
incident is not recoverable. **The queue-cascade material outright**:
how one abandoned generation is recorded as many stalls, how that was proven
from the server log rather than assumed, and how the same harness change, an
unload on timeout with runs labelled before and after runner eviction,
reproduced the archive for one model (`llama3.2:latest`) and not the other
(`granite4.1:3b`, whose run still shows the cascade), with the unload itself
not shown to cancel a generation and the difference unexplained. Why a stall
is the most misread measurement in the set, and what the per-call timeout
changes, including why raising the ceiling was never the answer. Suspect the
harness before the model: a fence-stripping bug and a bad assertion, both
blamed on models first. A null
result means nothing until delivery is established, and a delivery probe must
not contradict the system prompt. Judge with the parser you ship; derive
published tables rather than transcribe them. When to discard numbers and what
survives discarding them.

_Defers:_ the `llama3.2:latest` M5 artifact row and the throttling analysis to
article 3; it recaps article 3's sweep-position control in one paragraph, as a
second instance of the same discipline that resolves the stall counts: isolate
the confound, measure it, do not read a mechanism off a net number.

## Conventions

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
- **Do not quote the superseded 2026-08-14 and 2026-08-16 sweeps** as current
  results. The notebook marks them do-not-quote: they disagree with the
  2026-08-20 re-measurement on eight of ten models. A failure _mode_ first seen
  there may always be named. One narrow exception, which the notebook itself
  takes: a figure from those sweeps may illustrate a _methodological_ finding,
  as article 5 does with the 6/7-then-2/5 pair behind "the easy set does not
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

### Openings

**Every article is standalone.** A reader arrives from a search result or a
single link, not from article 1, and the five are read in no fixed order.
Nothing may depend on another article having been read: each one names the
project, what the model is asked for, and what renders the reply, and expands a
term the first time that article uses it. The ownership map above governs which
article carries a topic in full. It does not license leaving a reader without
the setup needed to read the article they opened.

**Open with a framing paragraph, then the finding.** The first paragraph says
what the thing is, meaning what the project does, what the model is asked for
and what happens to the answer, before any figure or verdict appears. A lead that opens
on the finding asks the reader to weigh a claim about a system nobody has
described to them yet. Article 4 opened on "moving the card out of the message
body and into the arguments of a function call drove malformed JSON to zero",
which names a mechanism, two channels, and a failure family to a reader who has
not yet been told that the server asks a model for card JSON at all.

The framing paragraph carries the setup itself rather than announcing it (see
**Register** on "the frame, briefly"), and two or three sentences is enough.
Framing first is an ordering rule, not a reason to open slowly: the finding
follows immediately, in the paragraph after the setup lands.

### Register

The repo's documentation-tone rules, as in
[`CLAUDE.md`](../../CLAUDE.md): state results plainly, replace superlatives with
the figure they stand for, reserve bold for a section's load-bearing claim and
for figures, hedge inferred mechanisms, and end on the last factual sentence.

Counts are measured; the explanation for them usually is not. Report negative
results as plainly as wins. Articles 2 and 4 are substantially negative results
and they must not read as apologies.

**No em dashes as punctuation.** A dash setting off a clause reads to many
readers as a machine-authored tell, so the published articles carry none.
Restructure the sentence rather than dropping a comma into the same slot, which
leaves a dash-shaped sentence behind: a paired aside becomes commas or a
sentence of its own, and a trailing dash becomes a period or a colon depending
on whether what follows restates or expands. "The obvious repair — tell the
model harder not to write anything after the card — did not work" becomes two
sentences: "The obvious repair was to tell the model harder not to write
anything after the card. That did not work." A definition wedged between a
subject and its verb moves out to its own sentence.

The exception is a table cell, where an em dash may stand in for a value that
does not exist. Prefer `n/a` wherever it reads correctly, and reserve the dash
for cells `n/a` would misdescribe.

Three habits to cut on sight, all of which survived into first drafts:

- **Rebutting an objection no reader raised.** "not a framing choice", "stated
  as a requirement, not as advice", "three parts, not two". Assert the thing;
  the contrast is imaginary.
- **Narrating the article's own rhetoric.** "The obvious doubt that raises is
  worth answering here", "The pairing rule carries weight, so it is worth
  stating". Answer the doubt or state the rule; do not announce that you are
  about to.
- **Announcing the setup instead of giving it.** "The frame, briefly". Never
  write _the frame_ in an article. Open the paragraph with the setup itself:
  what the project is, what the model is asked for, what renders the reply.
- **An ordinal implying an enumeration the text never made.** "a fourth set",
  "splits the roster a fourth way". The reader stops to count and finds no
  list. Name the thing instead.

### Cross-article references

The ownership map above decides _what_ defers. How a deferral is written is a
separate matter, and the drafts got it wrong the same way repeatedly.

- **A deferral is a sentence with a verb, not an equation.** "which seven, and
  what the smaller machine costs, is the two-host article" equates a question
  with a document. Write "A later article names those seven and measures what
  the smaller machine costs."
- **Verify a claim about a sibling article against that article.** A draft
  called `prompt_ab.dart` "the tuning article's instrument"; article 2 uses it
  once, and its evidence is mostly `shape_ab.dart`. A pointer is a factual
  claim.
- **Do not close a section or an article with a bare deferral paragraph.**
  Listing what the next article covers duplicates this file and ends the piece
  on someone else's material. End on the last factual sentence.

### Attribution

Three placements per article, because a reader who stops early should still be
able to reach the source:

1. **First screen.** Name and link the repo.
2. **Beside the artifact under discussion.** A reproduced table needs its
   source anchor next to it, not in the closing paragraph.
3. **Close.** The repo and the notebook, both URLs spelled out.

**All links are absolute GitHub URLs.** Repo-relative paths break the moment an
article leaves the repository. This applies to inline artifact names too:
`assets/card_system_prompt.txt` and `lib/src/card_detect.dart` are links, not
bare filenames.

**Two link targets, and the distinction is deliberate, but only after
publication.** While the articles are drafts, references to
`ModelBehavior.md` track `/blob/main/` so the drafts follow the notebook as
it changes. At publication, re-point them, all five articles to the same
commit, the one the figures were read at, including the link in the closing
paragraph, so a quoted figure still resolves after the notebook moves on.
Links to code and assets track `/blob/main/` in drafts and published
articles alike, because a reader following them wants the current file, not an
archived one.

### Presentation

- **Target length: about 2,000 words of prose per article, hard cap 3,000.**
  Prose excludes fenced code/diagram blocks, table rows, and link URLs, so
  measure with `wc -w` after stripping those, not on the raw file, which runs
  5–10% higher. An article that outgrows the cap gets trimmed or split, with
  the ownership map updated if split. (The per-article outlines that once
  carried section word budgets were deleted after drafting; this is the one
  number from them worth keeping.)
- Prefer a table to a prose list anywhere a section compares more than two
  things.
- **A table section runs intro, table, then commentary.** The intro is one or
  two sentences saying what the table holds and what to look for in it; a
  section that opens on a table makes the reader infer that. After the table,
  the rows that carry a finding get a paragraph each, two sentences or more,
  because a single sentence restates the row rather than explaining it. Not
  every row earns one: a fifteen-row roster is discussed by group, and rows that
  only supply the denominator need no commentary at all. What the paragraphs
  must not do is leave a row that the reader will stop on, an outlier or a
  reversed sign or a figure that contradicts a neighbouring row, standing
  without an account.
- **Keep every table, including one the notebook also carries.** A table is
  easier to read than the equivalent prose, so duplication between an article
  and [`ModelBehavior.md`](../ModelBehavior.md) is accepted rather than avoided.
  Do not sort tables into "main" and "supporting" and cut the second kind: that
  line is not reliably drawable, and drawing it is how a useful table gets
  dropped. The primary table for a claim belongs in the article, beside the
  paragraph it supports: a paragraph of supporting statements reads better with
  its table next to it than with a link to one. What defers to the notebook is
  hard prose detail, meaning per-run readings, provenance caveats and mechanism
  discussion, not the tables that carry the finding.
- **Converting prose into a table costs nothing against the cap**, because the
  word count excludes table rows. A passage that enumerates readings, such as
  rules paired with the measurement behind each, per-run figures, or a list of
  conditions, reads better as a table and buys headroom at the same time. It is the
  cheapest way to make room in an article sitting at the cap without dropping
  content.
- A wide source table needs fitting to blog width. Either split it into
  per-category mini-tables placed with the prose that discusses them, or shorten
  the widest column and move its content into prose. Do not trim an Evidence
  column; that is where the figures live.
- Section headings state a finding, not a verdict, **and get re-derived when
  the section beneath them changes.** "None of this was needed to ship the
  demo" outlived the paragraphs that made that claim by one revision, and a
  heading promising three test sets sat over forty lines about something else.
- **At least one intro paragraph sits between the `#` title and the first `##`
  heading**, and it is the background: what the project is, what the model is
  asked for, what renders the reply, and what this article asks. A reader who
  arrived from a search result needs all four before the first heading makes a
  claim. Filing that paragraph under the first `##` puts general background
  beneath a specific heading and leaves the title standing alone above nothing.
- **Quote one real question per test set.** A denominator describes a set's
  size; a prompt describes its difficulty, and the gap between "What size shirt
  should I order?" and a nine-field expense form is the argument the prose was
  making anyway.
- **When cutting a sentence, check whether it was the paragraph's only hedge.**
  Removing a caveat can silently promote an inferred mechanism to an
  established one.
- Image and chart placeholders are HTML comments describing what the visual
  should show, including any data it needs. Article 3's chart placeholder
  carries its eight data pairs and its required caption.

## Writing a new article

Articles 1–3 were drafted from per-article outlines that specified section
order, a word budget per section, the figures each section quotes, and explicit
"do not write X" traps guarding known misreadings. Those outlines were removed
once the drafts existed and were verified, because maintaining a second
description of an article that already exists is drift waiting to happen.

The structure is worth reusing for any further article:

- A section list with a word budget each, summing to the target length.
- The figures each section quotes, with the arithmetic behind any denominator
  spelled out so the drafter cannot guess it.
- The tables the article needs, with their rows named.
- The traps: for each figure that is easy to misread, a sentence saying what not
  to write. These caught more errors than any other part of the outlines.
- Where the three attributions go, and which visuals are needed.
