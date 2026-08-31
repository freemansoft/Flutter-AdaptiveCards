# The same benchmark on a 64 GB M1 Max and a 16 GB M5

## Two machines, one probe set

Two Apple machines ran the same probes and the same prompts, against
byte-identical prompt and seed digests: an M1 Max with 64 GB, where the shape,
cascade, everyday, and stress figures behind the first two articles in this
series were measured, and a fanless 16 GB M5 MacBook Air (`Mac17,3`).

The reason for the second host is narrow. A server default that only runs on a
64 GB box is not much of a default, so the 16 GB column answers what can
reasonably be recommended, not what can be measured.

Every figure below is transcribed from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md),
a lab notebook in the
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
repository, read at commit `ba02fd98`.
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

## Seven of the eight 16 GB rows cost 1.0–1.5x the M1 Max

| Model                     | Weights | M1 Max s/call | M5 s/call | M5 ÷ M1 Max | M1 Max sweep | M5 sweep | M1 Max stalls | M5 stalls |
| ------------------------- | ------- | ------------- | --------- | ----------- | ------------ | -------- | ------------- | --------- |
| `llama3-chatqa:8b`        | 4.3 GB  | 0.25 s        | 0.25 s    | 1.0x        | 3 min        | 5 min    | 0             | 0         |
| `granite4.1:3b`           | 2.0 GB  | 1.1 s         | 1.4 s     | 1.3x        | 34 min       | 13 min   | 13            | 1         |
| `llama3.2:latest`         | 1.9 GB  | 1.4 s         | 1.6 s     | 1.1x        | 12 min       | 15 min   | 2             | 2         |
| `llama3-groq-tool-use:8b` | 4.3 GB  | 1.8 s         | 2.7 s     | 1.5x        | 9 min        | 13 min   | 0             | 0         |
| `qwen2.5-coder:7b`        | 4.4 GB  | 2.3 s         | 2.9 s     | 1.3x        | 18 min       | 22 min   | 0             | 0         |
| `nemotron-3-nano:4b`      | 2.6 GB  | 2.6 s         | 3.5 s     | 1.3x        | 18 min       | 30 min   | 1             | 4         |
| `granite4.1:8b`           | 5.0 GB  | 2.7 s         | 3.3 s     | 1.2x        | 14 min       | 17 min   | 0             | 0         |
| `qwen3.5:9b`              | 6.1 GB  | 6.9 s         | 5.6 s     | 0.8x        | 34 min       | 29 min   | 0             | 0         |

The ratio column is computed from the two s/call columns as printed. The
notebook derives its own quoted ratios from the recorded millisecond figures, so
a value here can differ in the last digit.

<!--
CHART (to be produced): horizontal bar chart, "M5 ÷ M1 Max median s/call, eight
16 GB-capable models". One bar per model, baseline at 1.0x so the single
sub-1.0 bar points the opposite way from the other seven. Label each bar with
its ratio value. Data pairs (model, ratio):
  llama3-chatqa:8b        1.0
  granite4.1:3b           1.3
  llama3.2:latest         1.1
  llama3-groq-tool-use:8b 1.5
  qwen2.5-coder:7b        1.3
  nemotron-3-nano:4b      1.3
  granite4.1:8b           1.2
  qwen3.5:9b              0.8
Caption must carry the runtime caveat: the M5 rows were recorded on Ollama
0.33.1 and the M1 Max rows on an unrecorded version.
-->

**Seven of the eight M5 rows cost 1.0–1.5x the M1 Max.** The eighth,
`qwen3.5:9b` at **0.8x**, runs faster on the smaller host, and it is the subject
of the next section.

The spread does not track weight. The two 4.3 GB models land at opposite ends —
`llama3-chatqa:8b` at 1.0x and `llama3-groq-tool-use:8b` at 1.5x — so "the M5 is
1.2x slower" would be the wrong summary. What drives the per-model spread is not
established.

The median and the sweep can move in opposite directions, and neither is wrong.
`llama3-chatqa:8b` matches the M1 Max median exactly at 0.25 s while its full
sweep goes from 3 min to 5. The median is one greedy probe; the sweep is seven,
including the two that sample at `t=0.2` and `t=0.6`. Splitting the two by probe
class does not yield a rule either: that split looks large on
`llama3-chatqa:8b` (1.30x greedy against 2.16x sampled) and nearly vanishes
across all eight models (1.25x against 1.33x), with two running the other way.
`granite4.1:3b` moves in the opposite direction again — 1.3x on the median with
a sweep of 34 min against 13 — and that row is stalls rather than speed, treated
below.

Weight does not predict speed on either host: the fastest real card producer
measured is `qwen3-coder:30b` at **1.6 s/call** on the M1 Max, ahead of
`qwen2.5-coder:7b` at a quarter its size, and it is off this table because it
needs 17.3 GB. (`llama3-chatqa:8b` tops the raw table only because it answers in
short prose — quick for the wrong reason.)

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
where an idle machine gives **17/25** — a leaked co-resident runner competing
for the GPU. A busy machine and a slow model are indistinguishable from the probe's
side, which is what makes the rule necessary rather than tidy.

## A per-row ratio compares two configurations, not two machines

The two column groups were measured on different Ollama versions. The M5 columns
were recorded 2026-08-28 on **Ollama 0.33.1**. The M1 Max columns were recorded
2026-08-20/21 on a version the runs did not stamp — result files carried the
host but not the runtime until 2026-08-28 — and it is not recoverable.

`qwen3.5:9b` is the row where that shows. It runs faster on the smaller host,
and two `choice*` cases emit an `Input.ChoiceSet` under 0.33.1 where the M1 Max
emitted only a `TextBlock`, consistently across both samples at `t=0` greedy. A
runtime version can change behavior, not only speed.

A genuine host difference sits beside it, and reads differently.
`granite4.1:3b` stalls **13 times on the M1 Max against once on the M5**, with a
sweep of 34 minutes against 13. That is the 120 s per-call ceiling biting the
unaided condition: eleven M1 Max calls hit the ceiling and scored as failures,
so three cases that were ceiling-bound there return real answers on the M5.
**The seeded figures, where neither host stalled, match exactly.** This is a
real difference, not a bad row.

One more thing is folded into every M5 number. Each M5 row is the run taken at
that model's position in one serial sweep that ran 10:27 to 14:32, so later rows
carry more of whatever sustained load costs. How much is unestablished, and the
two models re-measured disagree about the sign.

Re-measuring the M1 Max on 0.33.1 would separate the runtime from the machine.

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
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md).
