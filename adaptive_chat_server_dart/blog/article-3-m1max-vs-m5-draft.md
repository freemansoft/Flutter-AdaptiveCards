# Running local models for Adaptive Card JSON on a 64 GB M1 Max and a 16 GB M5

In
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
a demonstration Dart chat server hands a question to a local Ollama model and
asks for the answer as Adaptive Card JSON, a strict, closed-vocabulary schema,
which a Flutter client renders as interactive UI rather than as text. A
directory of probes measures which of fifteen local models manage that, how
well, and how fast. The probes were built on a 64 GB machine. What changes when
they run on one a quarter that size?

## Two machines, one set of test probes

Two Apple machines ran the same probes and the same prompts, with the prompt and
seed files confirmed byte-identical by checksum: a 64 GB M1 Max MacBook Pro
14-inch (`MacBookPro18,4`), the host the probe suite was built on, and a fanless
16 GB M5 MacBook Air (`Mac17,3`).

A system that only runs on a 64 GB box restricts how many people can run their
own tests. The 16 GB column answers what a MacBook Air or a 16 GB dedicated GPU
can reasonably run. The Mac is the tighter of the two, because it shares one
memory pool between macOS and the model instead of reserving the full 16 GB for
weights.

Both hosts ran models back to back for hours, so each median below carries
whatever position in that run its model drew. One control on the M1 Max puts a
number on that: the same model runs **1.54x** slower right after an eight-hour
sweep than it does cold, and that single-machine spread is wider than seven of
the eight host-to-host ratios below. A later section shows the control. Read
the ratios as a direction, not a per-model figure. The 16 GB recommendation
rests on fit and shape score.

Every figure below comes from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md),
a lab notebook in the
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
repository.

## Terms used in this article

The first term describes a model, the next three qualify a score, and the last
three describe a run.

| Term                                      | What it means here                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Weights** and the `b` in a model tag    | The weights are the parameter file Ollama loads into memory, and the GB figure in the fit table is that file's size. The `b` in a tag such as `granite4.1:8b` counts parameters in billions, which is a different quantity: quantization decides how many bytes each parameter costs, so the three models tagged `:30b` here range from 17.3 GB to 23.7 GB. Fit is decided by the GB figure, never by the parameter count.                                                                               |
| **Shape score**, `n/25` (`shape_ab.dart`) | 25 prompt test cases, one user question each, paired with the Adaptive Card element types (the schema's UI component types, such as `Input.ChoiceSet` or `Table`) that would acceptably answer it. Each is scored on one thing: did the reply use one of them? "What are my options for deployment targets" passes only on an `Input.ChoiceSet`. Each case is run twice and passes only if both runs did. This is shape coverage, not accuracy: a model can be entirely correct in prose and score 1/25. |
| **Cold start** and **with history**       | The shape probe's two conditions: the question asked first, or asked with ordinary exchanges already in the conversation. The two differ, and a score under one is never quoted against the other. Figures below are with-history unless the text says otherwise.                                                                                                                                                                                                                                        |
| **Seeded** and **unaided**                | Seeded is the configuration the server ships, a synthetic two-turn card exchange prepended to the context. Unaided is the same probe without it. The seed is worth +10 shapes to −2 depending on the model, so a score named without its configuration is half a fact.                                                                                                                                                                                                                                   |
| **Median s/call**                         | Median over the 25-case shape sweep, excluding the first call after a model load (roughly 6-7x a warm one) and excluding stalled calls, which measure the timeout rather than the model.                                                                                                                                                                                                                                                                                                                 |
| **Full sweep**                            | Wall clock for the seven standard probes against one model, stalls included. That is time someone waited.                                                                                                                                                                                                                                                                                                                                                                                                |
| **Stall**                                 | A call that exceeds the probe's 120 s per-call ceiling and is scored a failure. A stall does not name its cause: a slow model and a busy machine are indistinguishable from the probe's side.                                                                                                                                                                                                                                                                                                            |

Shape figures are `--samples 2`: every case runs twice and counts as passed only
if both runs passed. That is why a one-point difference between two models is
noise, not a ranking. One borderline call flips the whole case.

## Seven models fit a 16 GB host outright, and one fits marginally

Both hosts are Apple Silicon Macs with unified memory, so there is no separate
VRAM budget. The number on the box is one pool shared by macOS, the model and
everything else running on the machine. The table below reads all fifteen
against a 16 GB host: ✅ fits, ⚠️ marginal, ❌ does not. The Weights column
decides a row, meaning the size of the model's parameter file, not the `b` in
its name.

| Model                                               | Weights | 16 GB |
| --------------------------------------------------- | ------- | ----- |
| `gpt-oss:20b`                                       | 12.8 GB | ❌    |
| `granite4.1:3b`                                     | 2.0 GB  | ✅    |
| `granite4.1:8b`                                     | 5.0 GB  | ✅    |
| `hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` | 22.9 GB | ❌    |
| `llama3-chatqa:8b`                                  | 4.3 GB  | ✅    |
| `llama3-groq-tool-use:8b`                           | 4.3 GB  | ✅    |
| `llama3.2:latest`                                   | 1.9 GB  | ✅    |
| `nemotron-3-nano:4b`                                | 2.6 GB  | ✅    |
| `nemotron-3-nano:30b`                               | 22.6 GB | ❌    |
| `nemotron-3.5-lightning:30b`                        | 23.7 GB | ❌    |
| `qwen2.5-coder:7b`                                  | 4.4 GB  | ✅    |
| `qwen3-coder:30b`                                   | 17.3 GB | ❌    |
| `qwen3.5:9b`                                        | 6.1 GB  | ⚠️    |
| `qwen3.6:27b-coding-nvfp4`                          | 18.4 GB | ❌    |
| `qwen3.8:27b-nvfp4`                                 | 16.9 GB | ❌    |

**Seven of the fifteen do not fit at all**, and the marginal row is
`qwen3.5:9b` at 6.1 GB.

The weights are not the whole memory budget. `gpt-oss:20b` is **12.8 GB**
against a 16 GB machine and is still a ❌, because those weights share the pool
with macOS and the runtime, so the usable ceiling sits below the number on the
box. ❌ means "do not recommend this as the default on a 16 GB host", not
"untested". Every ❌ row was measured, on the 64 GB machine.

The best pick for a 16 GB host is `granite4.1:8b`: 21 of 25 shape cases, in
5.0 GB. A shape score counts only whether the reply used an element type that
would answer the question, so this measures coverage, not accuracy.

`gpt-oss:20b` scores 25 of 25 on the 64 GB machine. It is the only model in the
notebook to do so under any condition, and at 12.8 GB it is still a ❌ for
16 GB. Moving to the smaller machine costs four test cases out of twenty-five.
The notebook's
[roster](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#candidate-models),
where the ✅/⚠️/❌ marks above come from, calls `gpt-oss:20b` "the exception the
16 GB column exists to flag".

That 21/25 score is a _seeded_, with-history figure. Unaided, `granite4.1:8b`
scores **15/25**, a **+6** seed gain, while `qwen2.5-coder:7b` scores **18/25**
either way. A 16 GB recommendation has to name the configuration, not just the
model.

## All eight rows read slower on the M5, 1.15x to 2.32x

The eight models that fit or nearly fit then ran on both hosts, recorded in
[the notebook's per-host performance section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#performance-by-host-and-runtime).
Median s/call is the like-for-like column: the same 25 shape cases on each
machine, with the load call and any stalled call excluded. The sweep and stall
columns describe the run rather than the model, and they part company with the
median wherever a call hit the 120 s ceiling. Rows are ordered by ratio.

| Model                     | Size   | M1 Max s/call | M5 s/call | M5 ÷ M1 Max | M1 Max sweep | M5 sweep | M1 Max stalls | M5 stalls |
| ------------------------- | ------ | ------------- | --------- | ----------- | ------------ | -------- | ------------- | --------- |
| `granite4.1:8b`           | 5.0 GB | 2.85 s        | 3.27 s    | 1.15x       | 15 min       | 17 min   | 0             | 0         |
| `qwen3.5:9b`              | 6.1 GB | 4.92 s        | 5.65 s    | 1.15x       | 24 min       | 29 min   | 0             | 0         |
| `qwen2.5-coder:7b`        | 4.4 GB | 2.38 s        | 2.90 s    | 1.22x       | 19 min       | 22 min   | 0             | 0         |
| `llama3.2:latest`         | 1.9 GB | 1.34 s        | 1.65 s    | 1.23x       | 13 min       | 15 min   | 2             | 2         |
| `nemotron-3-nano:4b`      | 2.6 GB | 2.54 s        | 3.54 s    | 1.40x       | 16 min       | 30 min   | 1             | 4         |
| `granite4.1:3b`           | 2.0 GB | 0.98 s        | 1.40 s    | 1.43x       | 124 min      | 13 min   | 52            | 1         |
| `llama3-groq-tool-use:8b` | 4.3 GB | 1.85 s        | 2.67 s    | 1.44x       | 9 min        | 13 min   | 0             | 0         |
| `llama3-chatqa:8b`        | 4.3 GB | 0.11 s        | 0.25 s    | 2.32x       | 3 min        | 5 min    | 0             | 0         |

Both hosts run the same Ollama line, the M1 Max on 0.33.2 and the M5 on 0.33.1,
a patch-level difference, so each row compares two machines and not two
runtimes. `qwen3.5:9b` is the row to read carefully even so. Its M1 Max figure
is a standalone cold control, not an in-sweep measurement like the other seven.
The same model measured hot on that host medians **7563 ms**, which would put
the row below 1.0x instead of at 1.15x.

```mermaid
xychart-beta horizontal
    title "M5 ÷ M1 Max median s/call, eight 16 GB-capable models"
    x-axis ["granite4.1:8b", "qwen3.5:9b", "qwen2.5-coder:7b", "llama3.2:latest", "nemotron-3-nano:4b", "granite4.1:3b", "llama3-groq-tool-use:8b", "llama3-chatqa:8b"]
    y-axis "M5 ÷ M1 Max ratio" 1.0 --> 2.4
    bar [1.15, 1.15, 1.22, 1.23, 1.40, 1.43, 1.44, 2.32]
```

**Every row is slower on the M5, and seven of the eight ratios fall inside
1.0-1.5x.** Compute is not the likely explanation.
[The notebook](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#performance-by-host-and-runtime)
puts this 8-core M5 at roughly parity with or ahead of the 32-core M1 Max on AI
compute, scaling Apple's own core counts and published multipliers, not anything
measured here. What the M5 does not have is the memory bus: **153 GB/s**
against **400 GB/s**. Single-stream token generation spends its time streaming
the model's weights out of memory, not on arithmetic, so it is bandwidth-bound.
Bandwidth is the ratio consistent with these medians.

The widest ratio in the table is the least meaningful one. `llama3-chatqa:8b`
at **2.32x** is 0.11 s against 0.25 s: 140 ms of absolute difference on the
fastest model in this table, where load and scheduling overhead are a larger
share of the call than the model's own compute. It heads the table for the
wrong reason as well. It answers in short prose instead of building a card,
which is what its **1/25** shape score looks like from the latency side.

`nemotron-3-nano:4b` is the row where the sweep column moves further than the
median does: 16 minutes to 30, against 1.40x on the median. Its stall count
moves the same way, 1 to 4, and a stalled call is wall clock the median
excludes by construction. The notebook records `chart`, a case in the everyday
set of ordinary one-shot requests that asks for a chart element, as a hang
trigger for this model that reproduces on both runtimes. The extra M5 minutes
are consistent with more calls reaching the 120 s ceiling, not with slower
generation throughout.

Model size does not predict speed on either host. The fastest real card
producer measured is `qwen3-coder:30b` at **1.5 s/call** on the M1 Max, ahead
of `qwen2.5-coder:7b` at a quarter its size, and it is off this table because
it needs 17.3 GB. The slowest is `gpt-oss:20b` at **7.2 s**, in 12.8 GB.

Five caveats apply to the table as a whole.

1. The M1 Max runs for `granite4.1:3b` and `llama3.2:latest` came **after
   runner eviction**, and the other six **before runner eviction**. Runner
   eviction is a harness change, described in the measurement-hygiene article
   in this series, that sends Ollama an unload after a call times out. It is a
   no-op unless a call times out, and those six recorded zero stalls on both
   hosts, so the comparison holds for them.
2. `granite4.1:3b`'s M1 Max sweep and stall cells, 124 minutes and 52, are
   cascade-damaged and are not model figures. That run's stall positions still
   carry the queue-cascade signature: one abandoned generation keeps running on
   the server, every later call queues behind it and scores as its own stall,
   and the stall count tracks how long the runaway ran, not how many calls were
   slow. The measurement-hygiene article in this series owns that account. Read
   only the median from that row: 0.98 s against 1.40 s, faster on the M1 Max.
3. `qwen3.5:9b`'s **1.15x** is not a finding either way. Its cold and hot M1
   Max figures fall on opposite sides of 1.0x, a spread that sits inside the
   1.54x sweep-position effect measured below.
4. Neither Ollama version here is current. **Ollama 0.33.3** is the release to
   install for a fresh setup, and no figure in this article comes from it.
5. **Every figure in this article was measured against a nearly empty
   context.** A probe call sends the card system prompt, one question, and at
   most a two-turn seed. The prompt runs a few thousand tokens, so generating
   tokens dominates the call, not reading them. A conversation that has filled
   its window is a different measurement on both axes. Reading the prompt
   grows with the history and can come to dominate the call, and coverage
   moves too. A later run with roughly 48,000 tokens actually in the window
   costs three of these models about a third of their shape coverage while
   leaving others unchanged. The full-context article in this series owns that
   account. Read the medians here as what a short exchange costs, which is what
   the demo's own traffic looks like, and not as what a long conversation
   costs.

### One row was an artifact: 89 minutes became 15

`llama3.2:latest` first recorded **89 minutes and 40 stalls** on the M5, its
unaided cold-start score falling from **15/25 to 5/25**. Of those 40, **28**
were in the unaided arm, in one contiguous block at the probe's opening. The
cause was never identified. Ollama logged one resident runner on all 22 loads
of the sweep, which rules out co-residency, and a 1.20x throttling factor is
too small to cover the gap. The stall block matches a queue cascade, but that
run predates runner eviction and nobody checked the M5 server log, so it is a
match, not proof.

Re-run on an idle machine it takes **15 minutes with 2 stalls**, reproduces the
M1 Max exactly, and medians **1650 ms** against the first run's **1559 ms**, so
the model's speed was never what changed. That run is the one published and the
one in the table above. The rule it enforces: re-run a suspicious row on an idle
machine before publishing, because a busy machine and a slow model are
indistinguishable from the probe's side. It is not the first row the rule has
caught. The measurement-hygiene article in this series accounts for the earlier
one.

### The same model runs 1.54x slower late in a sweep than at the start

The control is one model, one host, one runtime, measured twice. `qwen3.5:9b`
at position 0, after 29 minutes idle, medians **4924 ms**. The same model on
the same machine and the same Ollama, seven seconds after an eight-hour sweep,
medians **7563 ms**.

**1.54x, from nothing but when the measurement was taken.** Call that position
bias. Behavior did not move with it: 0 of 100 calls differed cold versus hot,
so this is latency only, not coverage.

`llama3-chatqa:8b`'s 2.32x sits outside that band, but on absolute latencies
small enough (0.11 s versus 0.25 s) that overhead, not position, is the likelier
explanation. `qwen3.5:9b` is the only row carrying a position control today.

The M5 column has the same problem in a different form. Its eight rows come
from a single sweep that ran 10:27 to 14:32, so later rows carry more of
whatever sustained load costs. How much is still open.

### Nothing measured on the M5 shows thermal throttling

A fanless chassis is the obvious candidate for a sustained-load penalty, so
`granite4.1:8b` ran twice more against its own in-sweep run: once thirteen
seconds after an eight-model sweep, and once after the machine had sat idle
overnight. On a thermal reading the hot re-run is slow and the idle one returns
to baseline. All three are in
[the same notebook section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#performance-by-host-and-runtime).

| `granite4.1:8b` measurement       | Relative to its position-0 run  |
| --------------------------------- | ------------------------------- |
| In-sweep run at position 0        | 1.00x (the baseline)            |
| Re-run 13 seconds after the sweep | **1.20x**                       |
| Re-run after 7h37m idle           | **1.12x** (p25 1.07 / p75 1.15) |

The hot re-run does read **1.20x**. The idle one is what breaks the reading.
7h37m should have returned the model to baseline, and it came back **1.12x**
slower anyway, with a tight interquartile spread, so a handful of slow calls
pulling an average does not explain it. Two nominally cold measurements twelve
hours apart differing that far is a reproducibility floor, and it absorbs most
of the 1.20x. `qwen2.5-coder:7b` then moved the other way, **1.03x** slower
after 31 minutes idle, and two models moving in opposite directions is not a
machine property.

The **1.54x** spread on the M1 Max just above, a machine with fans, is wider
than either figure here, so a swing this size does not need a fanless chassis
to explain it. Throttling is not ruled out, only unmeasured: **no run read die
temperature or clock frequency**. No row carries a correction. Read the M5
column as one sweep's figures carrying a position-dependent bias about the size
of its reproducibility floor.

## Among the eight models that fit, coverage runs 21/25 to 1/25

Fit only decides the shortlist. Among the eight that clear it, `granite4.1:8b`
(5.0 GB) scores 21/25 and `qwen3.5:9b` (6.1 GB) 19/25, while `llama3.2:latest`
(1.9 GB) scores 15/25 and `llama3-chatqa:8b` (4.3 GB) **1/25**, all seeded,
with-history figures. All four run on the small machine, so the recommendation
is **`granite4.1:8b`** and not whatever fits. With 64 GB, `gpt-oss:20b` is four
cases better at 25/25.

Three measurement rules came out of running the same probes twice on different
hardware. Stamp the host and the runtime version into every result file; a
figure that cannot name its machine and its runtime is not comparable to
anything. Derive published tables from the recorded runs instead of
transcribing them; the measurement-hygiene article records what that caught.
And report a bias you cannot correct for instead of correcting for it.

The repository is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook these figures come from is
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md).
