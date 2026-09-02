# The same benchmark on a 64 GB M1 Max and a 16 GB M5

## Two machines, one probe set

Two Apple machines ran the same probes and the same prompts, against
byte-identical prompt and seed digests: a 64 GB M1 Max MacBook Pro 14-inch
(`MacBookPro18,4`), where the shape, cascade, everyday, and stress figures
behind the first two articles in this series were measured, and a fanless 16 GB
M5 MacBook Air (`Mac17,3`).

The reason for the second host is narrow. A server default that only runs on a
64 GB box is not much of a default, so the 16 GB column answers what can
reasonably be recommended, not what can be measured.

Every figure below is transcribed from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/fd1e4732/adaptive_chat_server_dart/ModelBehavior.md),
a lab notebook in the
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
repository, read at commit `fd1e4732`.
Shape figures are `--samples 2`, which is why a one-point difference between two
models is noise rather than a ranking.

## Seven models fit a 16 GB host outright, and one fits marginally

| Model                                             | Weights | 16 GB |
| ------------------------------------------------- | ------- | ----- |
| gpt-oss:20b                                       | 12.8 GB | ❌    |
| granite4.1:3b                                     | 2.0 GB  | ✅    |
| granite4.1:8b                                     | 5.0 GB  | ✅    |
| hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest | 22.9 GB | ❌    |
| llama3-chatqa:8b                                  | 4.3 GB  | ✅    |
| llama3-groq-tool-use:8b                           | 4.3 GB  | ✅    |
| llama3.2:latest                                   | 1.9 GB  | ✅    |
| nemotron-3-nano:4b                                | 2.6 GB  | ✅    |
| nemotron-3-nano:30b                               | 22.6 GB | ❌    |
| nemotron-3.5-lightning:30b                        | 23.7 GB | ❌    |
| qwen2.5-coder:7b                                  | 4.4 GB  | ✅    |
| qwen3-coder:30b                                   | 17.3 GB | ❌    |
| qwen3.5:9b                                        | 6.1 GB  | ⚠️    |
| qwen3.6:27b-coding-nvfp4                          | 18.4 GB | ❌    |
| qwen3.8:27b-nvfp4                                 | 16.9 GB | ❌    |

**Seven models fit outright, one fits marginally — `qwen3.5:9b` at 6.1 GB — and
seven do not.** The marginal row matters later, so it is worth keeping separate
from the seven.

Weights are not the memory budget. `gpt-oss:20b` at **12.8 GB** is a ❌ on a 16 GB
host and outscores every model that fits, at **23/25**. The notebook calls it
"the exception the 16 GB column exists to flag".

Read ❌ as "do not make this the recommended default", not "cannot be probed".
The 64 GB host is where the ❌ rows get measured at all; the 16 GB host is where
the column gets checked rather than asserted.

The best 16 GB-capable model is `granite4.1:8b` at **21/25 in 5.0 GB**, against
**24/25 at 16.9 GB** for the best model in the ❌ class. That 21/25 is a
_seeded_, with-history figure: unaided, `granite4.1:8b` scores **15/25**, a **+6**
seed gain, while `qwen2.5-coder:7b` scores **18/25** either way. A 16 GB
recommendation has to name the configuration, not just the model.

## Every model is slower on the M5, from 1.15x to 2.32x

| Model                     | Weights | M1 Max s/call | M5 s/call | M5 ÷ M1 Max | M1 Max sweep | M5 sweep | M1 Max stalls | M5 stalls |
| ------------------------- | ------- | ------------- | --------- | ----------- | ------------ | -------- | ------------- | --------- |
| `granite4.1:8b`           | 5.0 GB  | 2.85 s        | 3.27 s    | 1.15x       | 15 min       | 17 min   | 0             | 0         |
| `qwen3.5:9b`              | 6.1 GB  | 4.92 s        | 5.65 s    | 1.15x       | 24 min       | 29 min   | 0             | 0         |
| `qwen2.5-coder:7b`        | 4.4 GB  | 2.38 s        | 2.90 s    | 1.22x       | 19 min       | 22 min   | 0             | 0         |
| `llama3.2:latest`         | 1.9 GB  | 1.34 s        | 1.65 s    | 1.23x       | 13 min       | 15 min   | 2             | 2         |
| `nemotron-3-nano:4b`      | 2.6 GB  | 2.54 s        | 3.54 s    | 1.40x       | 16 min       | 30 min   | 1             | 4         |
| `granite4.1:3b`           | 2.0 GB  | 0.98 s        | 1.40 s    | 1.43x       | 32 min       | 6 min    | 14            | 0         |
| `llama3-groq-tool-use:8b` | 4.3 GB  | 1.85 s        | 2.67 s    | 1.44x       | 9 min        | 13 min   | 0             | 0         |
| `llama3-chatqa:8b`        | 4.3 GB  | 0.11 s        | 0.25 s    | 2.32x       | 3 min        | 5 min    | 0             | 0         |

Both hosts are read at the same runtime line here — M1 Max on Ollama 0.33.2,
M5 on 0.33.1, a patch-level difference — for the first time. Doing that
removes an anomaly rather than explaining one: an earlier draft of this table
compared the two hosts across a runtime gap of unknown size and read
`qwen3.5:9b` as the one model that ran faster on the smaller host. At matched
runtime it reads **1.15x**, unremarkable, mid-pack. It is not a subject this
article needs a section for.

<!--
CHART (to be produced): horizontal bar chart, "M5 ÷ M1 Max median s/call,
eight 16 GB-capable models, same runtime line". One bar per model, baseline at
1.0x. Label each bar with its ratio value. Data pairs (model, ratio):
  granite4.1:8b           1.15
  qwen3.5:9b              1.15
  qwen2.5-coder:7b        1.22
  llama3.2:latest         1.23
  nemotron-3-nano:4b      1.40
  granite4.1:3b           1.43
  llama3-groq-tool-use:8b 1.44
  llama3-chatqa:8b        2.32
Caption: every model is slower on the M5, 1.15x-2.32x, consistent with the
memory-bandwidth gap between the two chips (~150 GB/s against ~400 GB/s). A
separate, same-host control (below) measures a 1.54x swing from sweep position
alone — larger than six of these eight ratios — so read a single row's ratio
as a direction, not a precise figure.
-->

**Every model is slower on the M5, 1.15x to 2.32x, seven of the eight inside
1.0-1.5x.** That is roughly what the memory-bandwidth gap between the two
chips predicts — about 150 GB/s on the M5 against about 400 GB/s on the M1
Max — so the result needs no special explanation.

The widest ratio is the least meaningful one. `llama3-chatqa:8b` at **2.32x**
is 0.11 s against 0.25 s: 140 ms of absolute difference on the fastest model
in this table, where load and scheduling overhead are a larger share of the
call than the model's own compute.

Two caveats travel with the table rather than any one row. The M1 Max figures
for `granite4.1:3b` and `llama3.2:latest` were measured after a runner
eviction fix described later in this series; the other six were measured
before it. Eviction is a no-op unless a call times out, and those six recorded
zero stalls on both hosts, so the comparison holds for them — stated rather
than assumed. And `granite4.1:3b`'s sweep column, 32 minutes against the M5's
6, is its genuine with-history timeouts, not a speed difference: its per-call
median is faster on the M1 Max than on the M5, 0.98 s against 1.40 s. Read
that row's sweep time as failures, not latency.

Weight does not predict speed on either host: the fastest real card producer
measured is `qwen3-coder:30b` at **1.5 s/call** on the M1 Max, ahead of
`qwen2.5-coder:7b` at a quarter its size, and it is off this table because it
needs 17.3 GB. (`llama3-chatqa:8b` tops the raw table only because it answers
in short prose — quick for the wrong reason.)

## One row was an artifact: 89 minutes became 15

`llama3.2:latest` first recorded **89 minutes and 40 stalls** on the M5. Re-run
on an idle machine it takes **15 minutes with 2 stalls** and reproduces the M1
Max exactly — **seeded 15/15, unaided 15/12**. Its median barely moved, from
**1559 ms to 1650 ms**, so the model's speed was never what changed. The second
run is the one published, and it is the one in the table above.

The cause is not identified. Co-residency is ruled out: Ollama logged one
resident runner on all 22 loads of the sweep. And **a 1.20x throttling factor is
far too small to account for the gap**, which also bounds what throttling can
be blamed for.

The rule that follows is stated as a requirement, not as advice: re-run a
suspicious row on an idle machine before publishing it. This is the second time
that rule has caught a bad row. The first was `granite4.1:3b`'s initial
2026-08-20 M1 Max sweep, which recorded **52 stalls** and **12/25** seeded
where an idle machine gives **17/25** — attributed at the time to a leaked
co-resident runner competing for the GPU. That attribution is not settled: a
queue cascade, where one abandoned generation keeps running and every later
call queues behind it, produces the identical signature, and this same model
reproduced **52 stalls** again in an unrelated 2026-09-01 sweep under
conditions where co-residency was excluded. The August run's logs did not survive to
check which mechanism applied, so the cause of that specific incident is not
recoverable — the measurement-hygiene article in this series carries the full
account. Either way, a busy or backlogged machine and a slow model are
indistinguishable from the probe's side, which is what makes the idle re-run
rule necessary rather than tidy.

## Every row still carries a 1.54x position bias

With both hosts read at the same runtime line, the confound this table cannot
rule out on its own is not the runtime — it is where each model sat in its
serial sweep. A same-runtime, same-host control isolates that effect directly.
Measured cold on the M1 Max — position 0, 29 minutes idle — `qwen3.5:9b`
medians **4924 ms**; measured hot, seven seconds after an eight-hour sweep, it
medians **7563 ms**. That is a **1.54x** spread from position alone, on one
machine, one runtime, one model — larger than six of the eight ratios in the
host table above. Behavior was unaffected by the swing: 0 of 100 calls
differed cold versus hot, so this is a latency effect only, not a coverage
one.

Every row in that table is one point in a serial sweep on each host, so a
ratio anywhere from 1.15x to 1.44x is not reliably distinguishable from where
the model happened to fall in its own sweep, absent a hot/cold control run on
that specific row. `llama3-chatqa:8b`'s 2.32x sits further outside that band
than the rest, but on absolute latencies small enough (0.11 s versus 0.25 s)
that overhead, not position, is the likelier explanation. Only `qwen3.5:9b`
has a position control today; read the direction of the M5/M1-Max comparison,
not a precise per-model figure, until more rows do.

One more thing is folded into every M5 number specifically. Each M5 row is the
run taken at that model's position in one serial sweep that ran 10:27 to
14:32, so later rows carry more of whatever sustained load costs. How much is
unestablished — see the throttling section below, where the two models
re-measured for it disagree about the sign.

## Thermal throttling stays plausible and unproven

| `granite4.1:8b` measurement       | Relative to its position-0 run  |
| --------------------------------- | ------------------------------- |
| In-sweep run at position 0        | 1.00x (the baseline)            |
| Re-run 13 seconds after the sweep | **1.20x**                       |
| Re-run after 7h37m idle           | **1.12x** (p25 1.07 / p75 1.15) |

The 1.20x figure is unreplicated. `qwen2.5-coder:7b`, whose published figure was
taken 17 minutes into the same sweep, measured **1.03x** after 31 minutes idle —
slightly slower cold, in the opposite direction. Two models moving in opposite
directions is not a machine property.

Under that sits a reproducibility floor. Two nominally cold measurements of
`granite4.1:8b`, twelve hours apart, differ by **12%**, with a tight per-call
spread, so systematic rather than noisy. An effect of 1.20x sitting on a floor
of 1.12x is not cleanly separable from it.

A companion figure sharpens this rather than resolving it. The **1.54x**
hot/cold spread measured on the M1 Max in the section above — a machine with
fans — is larger than either the 1.20x or the 1.12x measured here on the
fanless M5. A swing at least that size shows up without a fanless chassis,
which argues for a position effect that does not depend on thermal throttling.
It does not rule throttling out on the M5; it means a swing this size does not
require a thermal explanation to make sense.

Thermal throttling on a fanless `Mac17,3` remains plausible and unproven, and
the honest way to state that is to name what was not measured: **no die
temperature or clock frequency was read**, and Ollama server uptime, ambient
temperature, and accumulated OS state all differed between those runs, none of
them excluded.

No correction factor is applied to any row. A measured bias would be reportable;
this one is not yet measured well enough to correct for. Read the M5 column as
one sweep's figures carrying a position-dependent bias of roughly the same size
as its reproducibility floor.

## Fitting is the entry requirement, not the answer

Two parts to the answer, and the second is the larger one. Size first: **seven of
fifteen models do not fit a 16 GB host at all**, and weights are not the budget,
since a 12.8 GB model is out.

Then the part that matters more: **among the eight that do fit, the choice still
decides the outcome.** The top two are `granite4.1:8b` (5.0 GB, 21/25) and
`qwen3.5:9b` (6.1 GB, 19/25); the bottom two are `llama3.2:latest` (1.9 GB,
15/25) and `llama3-chatqa:8b` (4.3 GB, **1/25**) — all seeded, with-history
figures. Every one of those four runs on the small machine, and they are not
interchangeable.

Three measurement rules came out of running the same probes twice on different
hardware. Stamp the host and the runtime version into every result file; a
figure that cannot name its machine and its runtime is not comparable to
anything. Derive published tables from the recorded runs rather than
transcribing them — the derivation script caught two figures that had silently
drifted. And report a bias you cannot correct for instead of correcting for it.

The remaining harness lessons — bad assertions, and `system` messages that
never reach the model — belong to the next article in this series.

The repository is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook these figures are read from is
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/fd1e4732/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/fd1e4732/adaptive_chat_server_dart/ModelBehavior.md).
