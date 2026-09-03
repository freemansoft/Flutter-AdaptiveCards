# The tool channel drove malformed JSON to zero and lost on half the models

Moving the card out of the message body and into the arguments of a function
call drove malformed JSON to **zero on all eight models that could use the
channel**. No unexpected-character errors, no arrays missing their `[ ]`, no
cards truncated mid-generation, no duplicate keys. On four of those same eight
models the tool channel still scored worse than prose did, and nothing shipped.

The frame, briefly. In
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
a Dart chat server hands a question to a local Ollama model and asks for the
answer as Adaptive Card JSON in the message body. Ollama also offers a tool
channel, where the same card would instead arrive as the arguments of a
`render_adaptive_card` function. This article is the comparison of the two
channels and the per-bucket accounting for why the better-formed one lost.

Every figure below is transcribed from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md),
a lab notebook in that repository, read at commit `ba02fd98`.

## Both arms are scored by identical code, against the unseeded prose run

[`tool/model_probes/shape_ab.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/shape_ab.dart)
`--channel tool` runs the same 25 shape cases through a `render_adaptive_card`
function and converts its arguments into the reply string a prose answer would
have carried, so both arms are judged by the same code. Run 2026-08-21 on the 8
models a separate capability probe,
[`tool_call_probe.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/tool_call_probe.dart),
rated `supported` out of fifteen — the four-way split that produced those eight
is the first article's material. Conditions: `--samples 2`, unseeded, `t=0`,
cold-start and with-history.

The pairing rule carries weight, so it is worth stating rather than assuming.
**Each tool run is compared against that model's recorded `unaided` run — the
unseeded prose arm — never the seeded one.** The tool arm cannot be seeded: the
card seed is a synthetic assistant turn holding raw card JSON, which is not what
a tool-channel history looks like. Scoring the tool arm against a seeded prose
baseline would hand prose an advantage the tool arm structurally cannot have.
Every other shape figure in this series is seeded; none of the figures below is.

A model counts as a **win** only if the tool channel never made it worse on
either condition.

<!--
DIAGRAM (to be produced): the two reply channels side by side, same question in,
same rendered card out. Top path (prose channel): model → `message.content`
carrying Adaptive Card JSON as text → `card_detect.dart` → renderer, with the
detector drawn as a gate that can reject a malformed body and label it
`broken`. Bottom path (tool channel): model → `tool_calls[0].function.arguments`
carrying the card body as structured arguments → renderer, with no gate on the
path at all. The asymmetry is the point: the prose path has a detector, the tool
path has nothing equivalent, so a tool call naming an element type that does not
exist passes straight through as well-formed arguments. Caption should say that
zero malformed JSON is not the same as zero broken cards.
-->

## Two wins, two unaffected, four losses

Cold-start and with-history scores are out of 25 cases each, unseeded, `t=0`,
`--samples 2`, from
[the tool-channel section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md#the-tool-channel-measured-against-prose)
of the notebook.

| Model                        | Tool cold | Prose cold |   Δ | Tool warm | Prose warm |   Δ | Verdict    |
| ---------------------------- | --------: | ---------: | --: | --------: | ---------: | --: | ---------- |
| `qwen3-coder:30b`            |        19 |         16 |  +3 |        20 |         14 |  +6 | **win**    |
| `qwen3.5:9b`                 |        17 |         17 |   0 |        21 |         17 |  +4 | **win**    |
| `qwen3.6:27b-coding-nvfp4`   |        24 |         23 |  +1 |        24 |         24 |   0 | unaffected |
| `qwen3.8:27b-nvfp4`          |        22 |         23 |  −1 |        24 |         24 |   0 | unaffected |
| `nemotron-3.5-lightning:30b` |        18 |         21 |  −3 |         9 |         13 |  −4 | loss       |
| `gpt-oss:20b`                |        20 |         18 |  +2 |        20 |         25 |  −5 | loss       |
| `nemotron-3-nano:30b`        |        12 |         16 |  −4 |        11 |         16 |  −5 | loss       |
| `nemotron-3-nano:4b`         |         4 |          9 |  −5 |         5 |          7 |  −2 | loss       |

The two `unaffected` rows are the same result on either side of an arbitrary
line. **±1 is inside this file's own noise floor** — the 2026-08-20
re-measurement moved ten of twelve steady models by ±1 with nothing about them
changing — so a row that reads `+1` and a row that reads `−1` are not
distinguishable from each other or from zero. Only `qwen3-coder:30b`'s +6 and
`qwen3.5:9b`'s +4 are gains worth relying on, and only the four losses are large
enough to act on.

That leaves a table with an apparent contradiction in it. The channel removed a
whole failure family from every row, and half the rows got worse anyway. The
decomposition is where that resolves.

## Every failed call, bucketed by the label the judge already wrote

The decomposition costs no model calls. It is a re-scoring of the same results
JSON, bucketing every failed call by the `label` the judge wrote at the time.
Each arm is **100 calls** — 25 cases × 2 samples × cold-start and with-history —
of which 96 ask for a card and 4 are the negative control, the case that wants a
plain prose answer. The headline `n/25` counts a case as passing only when every
sample of it passed, so these per-call buckets are a finer view of the same runs
rather than a second metric.

Four buckets, by `label` prefix:

- `malformed` — `broken: invalid JSON`, `broken: duplicate-key`.
- `declined` — `label == prose` on a case that wanted a card.
- `wrong-shape` — `wrong-shape:`, `no-input:`, `unwanted-card:`.
- `infra` — `broken: HTTP 500`, `broken: timeout`. Listed separately because it
  is not attributable to the channel.

Counts are per 100 calls per arm, from
[the failure decomposition](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md#why-it-did-not-pay--the-failure-decomposition).

| Model                        | Verdict    | Prose mal / dec / shape / infra | Tool mal / dec / shape / infra | Tool decline rate |
| ---------------------------- | ---------- | ------------------------------: | -----------------------------: | ----------------: |
| `qwen3-coder:30b`            | win        |                 21 / 0 / 18 / 0 |                 0 / 3 / 18 / 0 |                3% |
| `qwen3.5:9b`                 | win        |                 18 / 0 / 14 / 0 |                 0 / 2 / 22 / 0 |                2% |
| `qwen3.6:27b-coding-nvfp4`   | unaffected |                   6 / 0 / 0 / 0 |                  0 / 0 / 4 / 0 |                0% |
| `qwen3.8:27b-nvfp4`          | unaffected |                   0 / 2 / 3 / 0 |                  0 / 4 / 4 / 0 |                4% |
| `nemotron-3.5-lightning:30b` | loss       |                  8 / 16 / 8 / 0 |                0 / 30 / 16 / 0 |               31% |
| `gpt-oss:20b`                | loss       |                   1 / 4 / 3 / 3 |                 0 / 11 / 3 / 5 |               11% |
| `nemotron-3-nano:30b`        | loss       |                 10 / 4 / 22 / 0 |                0 / 20 / 34 / 0 |               21% |
| `nemotron-3-nano:4b`         | loss       |                 6 / 52 / 10 / 0 |                0 / 48 / 32 / 2 |               50% |

**The `malformed` column is zero on all eight models in the tool arm.** Moving
the card out of the message body removes the serialization burden. That is what
the change was expected to do, and it held on every row, including the three
where prose lost 18, 21, and 10 calls to it.

Two costs replace it.

The first is **declining to call the tool at all**. In the prose channel the
model has already committed to emitting something; the tool channel adds a
decision point ahead of every card. The four qwen models decline on 0–4% of card
cases. The four losses decline on 11%, 21%, 31%, and 50%.

The second is **weaker element choice**. Filling a schema argument appears to
favour the cheapest legal filler — that is an inference from the labels rather
than a measured mechanism. `nemotron-3-nano:30b` gains 12 wrong-shape failures,
labelled `{TextBlock} want {Chart.Line}`, `{TextBlock} want {CodeBlock}`, and
`{} want {FactSet, Table}`. `nemotron-3-nano:4b` gains 22.

## The outcome is a subtraction, not a model category

**Malformed failures recovered, minus declines and shape regressions gained.**
That accounts for all eight rows, including the two the ±1 noise floor leaves
unexplained on the headline numbers:

- `qwen3-coder:30b` recovers 21 and pays 3.
- `qwen3.5:9b` recovers 18 and pays 10.
- `qwen3.6:27b-coding-nvfp4` recovers 6 and pays 4. The net falls inside the
  noise floor, which is why it reads as unaffected.
- `qwen3.8:27b-nvfp4` had no malformed failures in prose at all, so it has
  nothing to recover and only costs to pay. Its "unaffected" is a small loss the
  noise floor absorbs.
- `gpt-oss:20b` had one malformed failure, with the same result.
- The three nemotrons recover 8, 10, and 6 while paying 22, 28, and 18.

The two wins are the two rows where the recovered column is large and the paid
column is small, and neither is a property of size or family. As a rule for the
next roster: **the tool channel helps a model that selects the right card but
fails to serialize it.** It does not help a model whose failures are about
selecting the wrong card, and it costs a model that is reluctant to commit to a
card at all.

## Architecture does not separate wins from losses; the chat template predicts better

`qwen3-coder:30b` (30B, 3B active) is a win. `nemotron-3-nano:30b` (30B, 3B
active) is a loss. Same architecture class, opposite results, so the parameter
count and the sparsity pattern are not what is doing the work here.

The chat template is the better predictor. `nemotron-3-nano:30b` and the
`hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` build are the same base
weights under different packaging, and
[the tool-calling canary](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md#not-a-card-test-the-tool-calling-canary)
rates one `supported` and the other `supportedButDeclines` — the packaging
changed the verdict where the weights did not. Separately,
`llama3-groq-tool-use:8b`, fine-tuned for tool use, does not reach for the card
tool at all.

One variable is untested rather than ruled out. **Every probe in the notebook
sends `think: false` unconditionally, so all sixteen runs above are
thinking-off.** A thinking-on arm is the one variant of this measurement not yet
covered, and the notebook lists it as open work rather than as a result.

Chat template and thinking mode are both properties of how a model was asked,
not of the eight-model comparison table itself. The two things below are a
different kind of gap: not a variable the comparison didn't control for, but a
question the comparison's own design could not see the answer to.

## A one-request gate over-predicted willingness, and the channel hides what it does not remove

Two things the availability probe could not see, both visible only once the
channel ran across 25 cases.

**The phase-1 canary over-predicted willingness.** It rated all eight of these
models `supported` on a single card request. Across 25 cases, four of them
decline on 11–50% of card requests. "Will call the card tool once" and "will
reach for it reliably" are separate properties, in the same way the canary
itself found "can call a tool" and "uses it for a card" to be separate. A
one-request gate measures the weaker of the two.

**The channel also converts detected failures into silent ones.** A malformed
prose card is caught by
[`lib/src/card_detect.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/lib/src/card_detect.dart)
and surfaces as `broken`. A tool call carrying an invented element type is
well-formed arguments that render as an invisible blank: `nemotron-3-nano:4b`'s
tool arm produced eight calls labelled `no-input: got {Input, TextBlock}`, where
`Input` is not an element type. The shape probe catches those only because it
scores against an expected element set. A user would see nothing.
**Zero malformed JSON is not the same as zero broken cards.**

## Nothing shipped, and the measurement is what does

There is no `--reply-channel` flag and the server still asks for card JSON in
the message body. Half the models that can use the channel get materially worse
on it, so it could not be a default, and two beneficiaries out of fifteen roster
models did not justify a second code path through the reply loop.

What ships is the measurement —
[`tool/model_probes/tool_channel.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/tool_channel.dart)
and `shape_ab.dart --channel tool` — so the finding is re-checkable when the
roster or a model's tool support changes. It is worth re-checking on that
trigger and not otherwise: the run is roughly 800 serial model calls across
eight models, three of them 18–25 GB, and it took hours of wall clock.

The repo is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook every figure above came from is
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md).
