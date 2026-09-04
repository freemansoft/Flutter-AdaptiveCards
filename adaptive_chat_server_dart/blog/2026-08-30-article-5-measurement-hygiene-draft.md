# The measurement was wrong, in a way that looked exactly like a slow model

## Fifty-two stalled calls, and nothing about the model had changed

`granite4.1:3b` came back from a sweep on 2026-08-20 with **52 stalled calls**,
a seeded score of **12/25** on the shape set with conversation history, and
`n/a` on the drift (cascade) probe. Read as a model result, that is a 2.0 GB
model failing badly. It was not: nothing about the model had changed, or
needed fixing, on that 2026-08-20 run.

The frame, briefly. In
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
a Dart chat server hands a question to a local Ollama model and asks for the
answer as Adaptive Card JSON, which a Flutter app renders. A directory of
probes measures which models manage it; the results live in a lab notebook
there. This article is about the harness, not the models: every lesson below
came from a
measurement that went wrong — a queue cascade, a harness change that
half-worked, a ceiling that was never the problem, a sweep-position bias, a
bad assertion, a probe that can't tell silence from refusal, a silently
truncated prompt that read as a broken cache, a table worth deriving twice.

## One model resident at a time is a correctness requirement

[`sweep.sh`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/sweep.sh)
walks the model list, runs the seven standard probes against one model,
unloads it, and waits for the GPU to idle before the next starts. Two of
those steps look like housekeeping and are not.

```mermaid
sequenceDiagram
  participant D as sweep driver
  participant P as probe script
  participant O as Ollama
  participant V as GPU memory

  loop for each model M
    D->>P: run the 7 standard probes against M
    P->>O: POST /api/chat, first call, keep_alive 30m
    O->>V: load weights
    Note over V: a cold call costs ~6-7x a warm one<br/>and is excluded from the median
    O-->>P: reply
    P->>O: remaining calls, strictly serial
    O-->>P: replies, judged by the server's own tryParseCardBody()
    D->>O: ollama stop M
    O->>V: evict weights
    Note over D,V: without this the finished model lingers for<br/>keep_alive 30m, two models sit resident,<br/>and Ollama thrashes between them
    D->>V: wait for the GPU to go idle
  end
```

Probes send `keep_alive: 30m`, so a finished model stays resident half an
hour unless evicted. The first version of the 2026-08-20 sweep omitted the
`ollama stop`; two models sat in memory together and Ollama thrashed between
them — the working explanation at the time for the 52 stalls, the 12/25, and
the `n/a`. Re-run with the unload in place, on an idle machine,
`granite4.1:3b` scores **17/25 and 3/3**, matching its earlier published
figures, and the sweep takes **7 minutes instead of 124**.

Whether the unload step was the cause is not established by the re-run. A
later sweep, run 2026-09-01 with co-residency ruled out by the server log,
recorded the exact same **52 stalls** on this model, in a pattern consistent
with a queue cascade — one abandoned generation running past its timeout
while every later call queues behind it (mechanism
[below](#one-runaway-generation-is-recorded-as-many-stalls)) — which produces
an identical signature. The exact repeat, 52 both times eleven days apart, is
itself unexplained; both accounts stay on the record.

So the rule is a correctness requirement, not a performance tip: **one model
resident at a time** — load, run its probes, record, unload, wait, switch.
Full account:
[the sweep section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#the-sweep-and-why-the-unload-step-matters)
of the notebook; procedure:
[`tool/model_probes/README.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/README.md).

## A stall reads the same whether the model is slow or the machine is busy

A stalling call carries no information about its own cause; the reply just
takes longer. Before concluding that a model stalls: check `ollama ps` for
anything resident that should not be, and re-run on an idle machine — the
two-host article records the second time that rule caught a bad row.

This section's stalls have a different cause — a runaway generation, not a
resident competitor — but surface the same way. Probes bound each call with
`--timeout` (default 180 s; the 2026-08-20 sweep used 120 s for the shape and
cascade sets) and score an over-run reply a failure. Before that bound
existed, one runaway could hang an entire sweep: `granite4.1:3b` was observed
generating for **16 minutes** on one `table` case.

**Under Ollama 0.32.14, the bound changes what one figure means, and only for
`granite4.1:3b` unaided.** Seeded, with the synthetic card-shaped exchange
the server prepends to history, it scores 17/25 either way. Unaided it falls
from **13/25** unbounded to **9/25** under the 120 s ceiling — the stall
counts say why: seeded it stalls twice in 100 calls, unaided eleven,
answering at length in prose until it hits the ceiling. A real property of
the model under that condition: the stalls reproduce on an idle, otherwise
empty machine.

The scope is narrow: on that runtime, nine of fifteen models recorded zero
stalls and no other more than two, so the ceiling caveat applies to one row
of one column. Stall counts under the next runtime are a different story —
the rest of this article.

## One runaway generation is recorded as many stalls

A later Ollama upgrade, from 0.32.14 to 0.33.2, raised two models' recorded
stall counts — one from 2 to 31, the other from 13 to 52 — on the same
machine, weights, and probes. Read as a runtime regression, that looked like a
larger version of the ceiling story; for one model it was not, for the other
it is still open. `OLLAMA_NUM_PARALLEL=1` gives this host a single
generation slot: when a call times out the probe abandons the connection, but
the generation was observed to keep running server-side (why the disconnect
did not cancel it is unestablished — an isolated reproduction cancels
correctly), and every later call queues behind it and is scored as its own
stall. A recorded stall count tracks how long the runaway ran divided by the
timeout, not how many calls were slow: one hour-long runaway under a 120 s
ceiling costs roughly thirty stalls alone.

## Twenty-nine of thirty-one recorded stalls were queue, not model

A queue cascade leaves fingerprints a slow model does not: stalls in one
contiguous block, not scattered, and a server log showing a queue draining —
27 requests completed within 37 seconds, start times exactly 120 s apart,
durations descending in two-minute steps. A long-timeout re-run confirmed it
for `llama3.2:latest`: raising the ceiling to 7200 s resolved **31** recorded
stalls into **2** slow calls, at 64.4 and 62.1 minutes, both on the same case
and both ending in invalid JSON. Twenty-nine of the thirty-one were queue,
not model.

## The same harness change reproduced the archive for one model and not the other

The harness change: send an unload (`keep_alive: 0`) the moment a call times
out, rather than only abandoning the client connection. Runs are labelled
**before runner eviction** and **after runner eviction**, with Ollama 0.33.2,
the weights, the prompt and seed digests, and the machine held constant.

`llama3.2:latest` reproduces the archive exactly: 12 stalls / 26.2 minutes /
seeded 15/12 before runner eviction becomes 2 stalls / 6.5 minutes / **15/15**
after, and its unaided probe drops from 19 stalls to **0**.

`granite4.1:3b` does not move: 14 stalls, 30.1 → 30.0 minutes, seeded 17/12
before and after. An unchanged count was first read as proof the stalls were
the model's own; it is not. The after-eviction unaided run stalls on calls
0-20 — the probe's opening cases, all cold — and again on 89-99, the first
call after the block taking 86 seconds, a queued call draining rather than a
reload — the contiguous-block signature above, still present. "Unchanged by
eviction" is equally explained by the eviction not taking effect.

The server log supports that reading: nothing shows the unload cancelling a
running generation. A direct test sent `keep_alive: 0` 3 s into an 18 s
generation and it ran to 20.9 s; `ollama stop` similarly ran it to 16.3 s.
During the granite run, 53 unloads answered in about 8 ms each while one
generation ran 70 minutes with a queue draining behind it. During the
`llama3.2:latest` run its two stalled calls terminated server-side at
exactly 2m0s, each in the same second as an unload — coincidence or cause,
unexplained.

So the contrast is not artifact against regression: nothing about
`granite4.1:3b` under 0.33.2 is established, and its 14 seeded / 32 unaided
stalls and the coverage figures they produce are recorded as cascade-damaged
rather than a model measurement. What is established comes from the other
machine — the M5's clean run under Ollama 0.33.1 records seeded 17/25 both
cold and with-history and cascade 3/3, matching the model's clean 0.32.14
figures, so no 0.33.x regression is indicated. Open question: whether a
runaway generation can be cancelled at all.

## The timeout ceiling was never the problem

The 120 s ceiling looked like the thing to fix once stall counts spiked. It
was not: a generation running over an hour has already failed for every
purpose a chat server serves — the usability bar is a reply under a minute —
so raising the ceiling only converts a fast failure into a slow one. 120 s is
already twice that threshold; lowering it is worth weighing, since it
records the same failures for less wall clock. What needed attention was
what happened after the ceiling — the abandoned generation kept running —
and the fix for that, unload on timeout, is not yet shown to stop it.

## Sweep position moved a number more than the effect it was meant to explain

A hot-against-cold control run for a separate cross-host investigation held
one model, one host, one runtime fixed: cold, at position 0 after 29 minutes
idle, `qwen3.5:9b` medians **4924 ms**; hot, seven seconds after an
eight-hour sweep, **7563 ms** — a **1.54x** spread from sweep position
alone, larger than the cross-machine effect the control was meant to
explain. A single row in a serial sweep can report position, not the thing
compared.

## Two failures blamed on the model belonged to the harness

A stall is a harness mistake in timing; these two are harness mistakes in
judging. The first: a reply that looked like broken JSON from the model.
Dumping the bytes showed zero real newlines and **11 correctly escaped**
ones — valid JSON, corrupted after arrival by the server's own
fence-stripping heuristic in
[`card_detect.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/lib/src/card_detect.dart).
Dump the bytes before theorising about what produced them.

The second is the sharper one, because the harness was working exactly as
written. One model scored **0/3** on tables. The replies were valid, complete,
renderable Tables — one of them laid out as a 2×2 grid, which the probe's
`rows >= 3` success criterion penalized as a failure. The assertion was wrong,
not the model.

## A null result means nothing until delivery is established

A wrong judgment at least leaves a reply to inspect; the next mistake is
quieter — a lever that measured as doing nothing, when its instructions may
never have arrived. Repeating the instructions in a second `system` message
placed _after_ the conversation history produced nothing measurable, and the
obvious reading — repetition does not help — is not available: Ollama chat
templates vary in whether a second `system` message reaches the model at
all; some keep only the first.

The delivery check, run 2026-08-18 on four screening models by injecting an
additive reminder and reading the printed element-type list with and without
it, came back **delivered** on `gpt-oss:20b` and **unconfirmed** on
`qwen2.5-coder:7b` and `granite4.1:8b` — dropped-by-the-template and
arrived-but-ignored are indistinguishable from outside. The lever is recorded
as **no effect / unmeasurable** rather than a clean negative: establish
delivery before reading a null result from anything depending on it.

A second lesson sits underneath: a delivery probe must not contradict the
system prompt. Asking the model to "disregard the question, reply with only
the word BANANA" produced a null on all four models — uninformative, since
**"the model resisted a contradiction" and "the message never arrived" look
identical**. An additive, prompt-compatible probe — one harmless, checkable
element added to the list — removes that confound.

## A silently truncated prompt read as a broken cache

Ollama 0.33.3 added `prompt_eval_cached_count` — how many prompt tokens the
runner served from its prefix cache rather than re-evaluated. The first probe
built on it appeared to show the cache barely working: turn after turn reusing
**4 of 4,098** prompt tokens. The fault was the probe's configuration, not the
cache: its system prompt tokenized to roughly 15k against an 8,192-token
`num_ctx`, and Ollama truncated it to half the window silently, with no error
or warning, so every turn was a different slice of the oversized prompt and
nothing matched. The tell: `prompt_eval_count` sitting at exactly **4,098 on
every turn** of a growing conversation — a prompt that grows cannot keep a
constant token count. The server's own overflow detector now catches this at
request time, confirmed against a live server.

Sized to fit, the same probe shows the cache is a large performance effect —
Apple M5 / 16 GB, Ollama 0.33.3, `llama3.2:latest`, `t=0`:

| Pattern                                 | cached / prompt | prefill          |
| --------------------------------------- | --------------- | ---------------- |
| identical request repeated              | 2,142 / 2,143   | 2,017 ms → 18 ms |
| growing conversation, turns 2–3         | all but ~15     | ~94 ms per turn  |
| retry after aborting a call mid-prefill | 2,443 / 2,444   | 29 ms            |

A conversation turn pays prefill for its new tokens only, and a retry after an
aborted call costs a warm repeat rather than a cold prefill — pricing the
timeout-and-retry pattern the probes use, whether that reflects 0.33.0's
prefill restore points or the abandoned request completing server-side
(indistinguishable from the client; the price is the same either way). The
prefill timings were always readable; what 0.33.3 added is the cached count
saying _why_ a prefill was cheap — turning a plausible "broken cache" reading
into a measurable configuration error.

The pattern reproduces on a second host with the same model: on an Apple M1
Max / 64 GB under the same Ollama 0.33.3, `llama3.2:latest` matched the M5
readings figure for figure — identical-repeat prefill 2079 ms → 12 ms, a
fresh question against the same system prompt 87 ms, an interleaved unrelated
request 39 ms, retry-after-abort 30 ms against the M5's 29 ms.

It does not reproduce on a second model. `qwen3.8:27b-nvfp4` (~18 GB, too
large for the M5) agreed with `llama3.2` on three of five patterns —
identical repeat, growing conversation, and, unstably, retry-after-abort —
but missed on two, confirmed by a repeat run on an idle machine: a fresh
question sharing the system prompt, and an interleaved unrelated request,
both came back as a full cold prefill in both runs — `cached=4` of roughly
3,177 tokens, ~40 s, indistinguishable from the model's first cold call.
Retry-after-abort was itself unstable on it — 148 ms with most of the prompt
cached on one run, 18,154 ms with under two-thirds cached on the repeat,
while `llama3.2`'s retry cost was unaffected. Reusing a shared system prompt
across a fresh question is what a chat server does on most turns; for one
model that reuse is free, for the other it is not.

The full figures, including cross-conversation reuse and survival across
interleaved requests, are in
[the prompt-cache section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#prompt-cache-reuse-and-retry-cost-measured-with-prompt_eval_cached_count)
of the notebook.

## Both the judge and the published table come out of code

Delivery is one way a measurement can be silently wrong; the judge is another.
The probes judge replies with the server's **own** `tryParseCardBody`,
`cardParseFailureReason`, and `checkNoDuplicateJsonKeys` — a probe with its
own idea of "looks like a card" could report a pass rate the running server
disagrees with. The performance table gets the same treatment: every figure
derives from the recorded runs via
[`perf_table.py`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/perf_table.py),
not typing, so a re-run diffs against the table. Deriving it caught **two
figures that had already drifted**:
`qwen3.8:27b-nvfp4` read 4.4 s against a recorded 4339 ms, and
`llama3-chatqa:8b` read 0.3 s where **253 ms and 248 ms** — a 2% difference —
should have printed as "0.3 s" and "0.2 s" beside a 1.0x ratio. Neither would
have been found by re-reading the table.

## Ten models' numbers were discarded, and three findings outlived them

Everything above is about keeping a measurement from being wrong; this last
one is what to do once a whole batch already was: discard the numbers, not
what they taught. Two dated sweeps — six small models on 2026-08-14, four
large ones on 2026-08-16 — ran the everyday and stress sets at `--samples 1`,
before the shape probe existed. Their per-model numbers, superseded by the
2026-08-20 re-measurement, **disagree with it on eight of the ten models**,
occasionally by five everyday cases; nothing about the models changed.
Marked do-not-quote in the notebook, they are kept only in git history and
the result files, where a provenance question can still reach them.

Three findings survived the numbers, and they are the part worth carrying.

- **The easy set does not discriminate.** In those superseded runs — cited for
  the methodological point, not as current scores — `nemotron-3-nano:4b` and
  `llama3-groq-tool-use:8b` scored 6/7 on the everyday set, then fell to 2/5
  and 1/5 on the cases that break models — why the stress and shape sets
  exist.
- **Every failure was malformed JSON, not a wrong element choice**, in three
  families the detector has to survive: truncation, scaling with reply
  length; an extra closing bracket before the next sibling (`}] ,{`); and a
  missing `{"type":` wrapper on the first array element
  (`["TextBlock","text":…`).
- **The build is a variable, not just the model family.** The `hf.co/unsloth`
  Nemotron GGUF and the Ollama-library `nemotron-3-nano:30b` scored
  identically on the everyday set and diverged on stress.

A failure mode outlasts the number that first exposed it: discarding a
sweep's scores does not oblige you to discard what it taught.

## What transfers

Eleven rules, each the residue of a wrong measurement, not a principle
arrived at in advance: keep one model resident at a time; re-run a suspicious
row on an idle machine before publishing it; run a corrective harness change
on every candidate row and confirm in the server log it took effect;
separate queued calls from slow ones before trusting a stall count; never
raise a timeout ceiling to capture a failure that already missed the
usability bar it exists to enforce; control sweep position before reading a
single row's ratio as the effect under test; distrust a shipped assertion as
readily as the model it judges; establish delivery before reading a null
result, with a probe that does not contradict the prompt beside it; check
for silent truncation before reading any token-level number; judge with the
parser you ship and derive published tables from the recorded runs; and
record what you threw away and why, so a discarded number is not quoted back
at you from git history.

This is the last article in the series. The repository is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook every figure above is read from is at
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md).
