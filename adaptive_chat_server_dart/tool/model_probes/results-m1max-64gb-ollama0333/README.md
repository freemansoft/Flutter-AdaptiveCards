# Results: Apple M1 Max / 64 GB, Ollama 0.33.3

Measurements taken on this host under Ollama 0.33.3, distinct from
[`../results-m1max-64gb-ollama0332/`](../results-m1max-64gb-ollama0332/)
(same host, Ollama 0.33.2) and
[`../results-m5-16gb-ollama0331/`](../results-m5-16gb-ollama0331/) (Apple M5 /
16 GB, Ollama 0.33.1).

## `qwen3.6:27b-coding-nvfp4` schema-constrained shape A/B

Three files in `qwen3.6_27b-coding-nvfp4/`, in the order they were measured
(recorded in commit history — each file's own `measuredAt` is a date only, no
time of day):

1. `shape_ab-seeded-format-schema.json` — the A/B arm, all 5 cases
   (`date`, `choice1`, `carousel`, `columnset`, `prose`), `--samples 3`.
2. `shape_ab-seeded-format-schema-confirm.json` — `carousel` only,
   `--samples 1`, a same-day re-run to check the A/B's `carousel`-warm
   result.
3. `shape_ab-seeded-format-schema-recheck.json` — `carousel` only,
   `--samples 3`, run on an idle machine to characterize the confirm run's
   result further.

**The contradiction:** the A/B arm records `carousel` warm passing 3/3. Both
follow-ups disagree — `carousel` warm times out in every attempt they record
(confirm 0/1, recheck 0/3), and `carousel` cold times out in all three files
(A/B 0/3, confirm 0/1, recheck 0/3). A reader who opens only the A/B file
sees a repair; a reader who opens only a follow-up sees a model that never
passes. Neither view is the aggregate.

Aggregate across all three files: `carousel` cold **0/7** (every attempt a
180 s timeout), `carousel` warm **3/7**, with all three passes coming from
the A/B file — the earliest of the three runs. `carousel` is not repaired by
the schema constraint; the A/B file's 3/3 warm pass is an outlier that did
not reproduce on either follow-up.

`columnset` is unaffected by the contradiction above: all three files agree
it passes under the schema constraint, and `shape_ab-seeded-format-none.json`
(below) agrees it fails without one.

## `qwen3.6:27b-coding-nvfp4` unconstrained control arm

`shape_ab-seeded-format-none.json` is the unconstrained control for the same
five cases (`--json-format none`, no schema sent). `columnset` is **0/6**
there (cold 0/3, warm 0/3), against **6/6** in the schema-constrained A/B
arm above (cold 3/3, warm 3/3) — the repair the A/B arm's `columnset` result
records.
