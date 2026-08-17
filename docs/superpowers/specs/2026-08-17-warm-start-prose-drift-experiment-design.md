# Warm-start prose drift — experiment design

**Status:** approved, ready for an implementation plan
**Package:** `adaptive_chat_server_dart`
**Date:** 2026-08-17
**Depends on:** [`2026-08-17-shape-aware-model-probe-design.md`](./2026-08-17-shape-aware-model-probe-design.md) —
this experiment's instrument is `shape_ab.dart`, which that spec defines. Its
baseline cold-start numbers for the three screening models must exist before
any result here can be interpreted.

## The problem

Once a conversation has been answered in Markdown, models stop sending cards —
even for questions whose right answer is a card. Measured on `qwen2.5-coder:7b`
at `t=0`, asking "what are my options for deployment targets":

| History before the question | Result                           |
| --------------------------- | -------------------------------- |
| none                        | `card[2]` — an `Input.ChoiceSet` |
| 1 prose turn                | prose — 867 chars of Markdown    |
| 2 prose turns               | prose — 903 chars of Markdown    |

One prose turn is enough. Across thirteen models measured with two prior prose
turns, four collapse completely (0/6) and five land partial (1/6-3/6).

**The critical constraint on this experiment:** the shipped prompt _already
contains_ an anti-drift instruction. Task 7 added it and it measurably helped
the server default (`qwen2.5-coder:7b`, 2/12 → 6/12, later normalized to 3/6):

> Decide the shape from the CURRENT question by itself. Having answered in
> Markdown earlier in this conversation is NOT a reason to answer in Markdown
> now — a question that asks the user to pick from a set gets a card even when
> every previous turn was prose.

Every 0/6 in the record was measured **with that paragraph in place**. So the
direct instruction not to drift is already there and is being ignored
completely — not partially — by four models. Any candidate here is competing
against an instruction that has already been tried, which is why the design
tests three distinct _mechanisms_ rather than three rewordings, and why
"nothing ships" is an explicitly allowed outcome.

## Goals

1. Determine whether warm-start prose drift is fixable, and by which of five
   candidate mechanisms.
2. Attribute any improvement to a specific candidate rather than to a bundle.
3. Produce a measured negative result if no candidate works, so the next person
   does not retry the same ideas.

## Non-goals

- Shipping a fix regardless of measurement. If all five lose, none ships.
- Fixing shapes a model cannot produce cold-start. Those are capability or
  palette problems, not drift; see "Erosion is measured against cold start".
- Variant-level assertions (`style` / `isMultiSelect` on `Input.ChoiceSet`).

## Why the non-prompt candidates are cheap to test

`probeOnce` in `tool/model_probes/probe_support.dart` builds
`[system, ...history, user]`. `OllamaResponder` (`lib/src/ollama_responder.dart`
lines 392-400) builds the same list the same way. The probe already mirrors the
server, so both non-prompt candidates can be evaluated entirely probe-side by
varying message assembly. **Server code changes only if a candidate wins.**

## The five candidates

### Prompt-side — edits to `assets/card_system_prompt.txt`

Each tests a different mechanism, not a different phrasing.

#### P1 · Recency

Hypothesis: the shape rule loses to distance. It appears once, early, and then
several turns of conversation sit between it and generation.

A note on why this is not "add an item to the pre-send checklist", which was
the first form of this idea: that checklist opens _"Before you send a card
reply, check it:"_ — it is on the card path only. A model that has already
drifted to Markdown never reaches it, so a shape item there would be checking a
decision made earlier. P1 instead appends a new final section, so it is the
last thing read before generation:

```txt
## Before you answer: pick the shape

Look only at the CURRENT question. If it asks the user to choose, pick, enter,
schedule, or rate something — or asks to see data as a table, a chart, or
labelled facts — answer with reply shape 1 (a card). Answer with reply shape 2
only when none of those apply. What shape you used in earlier turns is not
evidence about this turn: a conversation that has been plain Markdown for five
turns still gets a card the moment the user asks to pick something.
```

#### P2 · Guard the destination

Hypothesis: the Markdown section is an attractor. It is the last section the
model reads and it reads invitingly ("Prefer short paragraphs and light
formatting"). Guard its entrance rather than restating the rule elsewhere.

Inserted directly beneath the `## Reply shape 2: Plain Markdown (no structured
input)` heading:

```txt
Do NOT use this shape when the current question asks the user to choose, pick,
enter, schedule, or rate something, or asks to see data as a table or chart —
those get reply shape 1, even when every earlier turn in this conversation was
Markdown.
```

#### P3 · Close the rationalization route

Hypothesis: the escape hatch is the leak. "If no element type fits" is
rationalizable as "a bullet list fits fine here."

The existing paragraph is extended (new text appended to it):

```txt
This is an escape for shapes the list cannot express, NOT a preference: if the
question asks the user to choose, enter, schedule, or rate something, or to see
a table or chart, the list does fit it and shape 1 is required. A Markdown
bullet list is never the fitting answer to "what are my options".
```

### Non-prompt — message assembly

#### N1 · Per-turn reinforcement

A `role: system` message inserted **after** the history, immediately before the
current user turn — so the rule is adjacent to generation rather than behind N
turns of conversation:

```txt
Reminder: decide the reply shape from the question you are about to answer, not
from the format of earlier turns. If it asks the user to choose, enter,
schedule, or rate something, or to see a table or chart, reply with a card.
```

Implemented as a `--reinforce` flag on `shape_ab.dart`. Server-side equivalent,
if promoted: append the same message in `OllamaResponder` after
`_trimHistory(history)` and before the current user turn.

#### N2 · Card-shaped history seed

Prepend one synthetic exchange — a short pick-from-a-set question and a
card-shaped assistant reply — ahead of the real history, so a card is already
the established pattern before any prose accumulates.

This is implementable server-side: it is few-shot priming via fabricated
leading history, prepended to every request. It does not depend on the real
conversation containing a card.

Implemented as a `--seed-card` flag on `shape_ab.dart`. Because it adds tokens
to **every** request, its evaluation records latency alongside pass rate; a
candidate that buys two shapes at the cost of doubling time-to-first-token is a
different trade than one that is free.

## How candidates are expressed

Prompt candidates are reconstructed from the exact text in this spec and
applied to `/tmp` copies at run time, passed via `shape_ab.dart --candidate`.
They are deliberately **not** committed as five near-duplicate 220-line files
that go stale the moment a winner is chosen. This matches how Tasks 6 and 7
were run, and how Task 6's rejected wording is preserved today — as prose in
the durable record.

Non-prompt candidates change message assembly, so they are committed code:
`--reinforce` and `--seed-card` flags on `shape_ab.dart`.

## Measurement protocol

### Stage 0 — N1 delivery check

**Not every chat template respects a second system message.** Some models fold
only the first `role: system` into the template and drop or misplace later
ones. If N1 scored exactly at baseline, that would be ambiguous between "the
reminder did not help" and "the reminder was never delivered."

So before any N1 number is interpreted, on each screening model: inject a
deliberately conspicuous reminder in N1's exact position — _"always begin your
reply with the word BANANA"_ — and run `dump_reply.dart`. If the reply does not
begin with BANANA, that model's template is not delivering the message and N1
is **untestable** on that model. Recorded as a plumbing finding about the
model, never as a null result for the candidate.

This is `ModelBehavior.md`'s own "suspect the harness before the model" rule,
applied in advance rather than after a confusing number.

### Stage 1 — screening

| Model                | Weights | Baseline with-history | Why in the screen            |
| -------------------- | ------- | --------------------- | ---------------------------- |
| `qwen2.5-coder:7b`   | 4.4 GB  | 3/6 (partial)         | server default, has headroom |
| `llama3-chatqa:8b`   | 4.3 GB  | 0/6 (collapse)        | swept cold start, collapsed  |
| `nemotron-3-nano:4b` | 2.6 GB  | 0/6 (collapse)        | smallest total collapse      |

Six configurations per model: baseline, P1, P2, P3, N1, N2. Instrument is
`shape_ab.dart --only` over a fixed subset spanning the failure surface — two
ChoiceSet cases (the known-eroding shape), `date` (another input), `table` and
`carousel` (display), `gauge` (chart) — at `--samples 1`, both conditions.

Roughly 3 models × 6 configs × 6 cases × 2 conditions ≈ 216 calls;
minutes-scale on 2.6-4.4 GB models.

### Erosion is measured against cold start

A shape a model cannot produce cold-start is **not** a warm-start problem — it
is a capability or palette problem, and no anti-drift wording will fix it.
Scoring such a shape as a drift failure would credit or blame a candidate for
something it cannot affect.

So the primary screening metric is **with-history passes**, always reported
beside that same candidate's **cold-start passes**. Reporting both is what
stops a candidate from appearing to win by dragging cold start down to meet
with-history.

This is the ordering dependency on the shape-probe spec: baseline cold-start
numbers for these three models must exist first.

### Stage 2 — stack the winners

One combined configuration containing every candidate that individually beat
baseline, on the same three models. Prompt winners combine into a single file
carrying all winning edits; N-candidates are additive flags. Attribution comes
from Stage 1; Stage 2 measures whether the combination composes or interferes.

### Stage 3 — confirm

The surviving configuration on the **full 25 cases**, both conditions,
`--samples 2`, across a wider set: the three screening models plus
`llama3-groq-tool-use:8b`, `nemotron-3.5-lightning:30b` (the two remaining
total-collapse models), and at least one strong model
(`gpt-oss:20b` or `qwen3.6:27b-coding-nvfp4`) to confirm the change does not
_harm_ a model that already worked.

### Stage 4 — regression gates

Any prompt change reaching Stage 3 must clear both gates every prior prompt
change in this package has cleared:

- `temperature_stress.dart` at `t=0` and `t=0.6`
- `prompt_ab.dart`'s built-in code set

Task 6 is the precedent: a candidate that tied on its target set and silently
broke _"what is a closure? show an example"_ (8/8 → 7/8, deterministic across
3 repeats). These gates are not optional, and a Stage 3 winner that fails them
is reverted and recorded rather than shipped.

## Decision rule

**Promotion bar:** a candidate advances from screening if it raises
with-history passes on **at least two of the three** screening models and
lowers it on **none**.

Requiring all three would let one stubborn model veto a real improvement;
requiring only one would promote noise. A tie everywhere is not an
improvement — the Task 6 lesson, where a tie-at-ceiling was treated as
satisfying a `>=` rule and only the regression check caught the problem.

**The narrow-win case, stated so it is not decided ad hoc later.** A candidate
that improves only `qwen2.5-coder:7b` — the partial-band server default — and
leaves both collapse models at 0/6 does **not** meet the bar above. It may
still be worth shipping as an incremental improvement to the default model;
Task 7 shipped on exactly that evidence, measured on that model alone. But it
must be recorded and described as a narrow win on the server default, **not**
as fixing warm-start drift, and it still has to clear Stages 3 and 4. The
distinction matters because the durable record is what the next person
reasons from: "improves the default model by one shape" and "fixes prose
drift" invite very different follow-on work.

**Nothing shipping is an allowed outcome.** Four models sit at 0/6 with Task
7's anti-drift wording already in place, which is direct evidence that prompt
wording has a ceiling here. If all five candidates fail, the finding is "this
class of fix does not rescue total-collapse models," recorded as a measured
negative. That is a successful experiment, not a failed one.

## Recording results

Into `ModelBehavior.md`, per the file's standing rule that every number names
its model, temperature, and condition:

- Per-candidate screening results **including losers**, with the instrument
  named.
- The Stage 0 delivery-check result per model, recorded separately as a
  capability fact about that model's chat template — reusable knowledge
  independent of this experiment.
- If a candidate ships: the before/after pair that justified it, plus the
  regression-gate results.
- If nothing ships: the negative result, explicitly framed so the next person
  does not retry these five mechanisms.

`CHANGELOG.md` gets an `## [Unreleased]` bullet either way.

## Constraints inherited from the package

- Prefix every `dart` command with `fvm`.
- Work from `adaptive_chat_server_dart/`; it resolves standalone.
- One Ollama model resident at a time; never interleave. Unload between models.
- Markdown is Prettier-governed (`npm run format:md:chat` / `check:md:chat`);
  Prettier rewrites `*italic*` to `_italic_`.
- `very_good_analysis`: single quotes, package imports, no `print`.
- Gates: `fvm dart analyze` clean, `fvm dart test` passing,
  `fvm dart format --output=none --set-exit-if-changed .` clean.

## Open risks

- **P1 and P2 are positionally close.** P1 appends a final section; P2 inserts
  near the top of the section immediately preceding it. If both win by similar
  margins, the mechanisms may not be distinguishable at this sample size —
  report that rather than claiming two independent wins.
- **N2 changes cost on every request.** A win here has an ongoing latency and
  token price the prompt candidates do not, and that trade belongs to the
  human, not to the pass rate.
- **The screening subset could mislead.** Six cases chosen to span the failure
  surface may not represent all 25. Stage 3 exists to catch that, and a Stage 1
  winner that does not survive the full set is recorded as such.
