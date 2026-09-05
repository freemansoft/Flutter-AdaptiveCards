# Raw captures: stdout from before `prefill_cache_probe.dart` had `--json`

Four files. Three are stdout transcripts from `prefill_cache_probe.dart` runs
taken 2026-09-04, on the Apple M1 Max / 64 GB, before the probe supported
`--json` and could archive a `ProbeRun`. The fourth is a `--json` run from
2026-09-05, kept here rather than archived — see below.

## Why not under a `results-*/` directory

`check_results.dart`'s `resultsDirs()` only scans directories whose basename
starts with `results-`; this directory does not, so these files are outside
its scan by construction. That is deliberate, not incidental: the three
`.txt` files are not `ProbeRun` JSON and `check_results.dart` has nothing to
validate them against, and `m1max-64gb-qwen3.8_27b-nvfp4-2026-09-05-confirm.json`,
despite being `ProbeRun`-shaped, is an unarchived corroboration run — placing
it under a `results-*/` model directory would have it read as an archived
run, changing the recorded count and the model-name match `check_results.dart`
performs against `launch.json`.

## Files

- `m1max-64gb-llama3.2_latest-2026-09-04.txt` — `llama3.2:latest`, the single
  2026-09-04 run.
- `m1max-64gb-qwen3.8_27b-nvfp4-2026-09-04.txt` — `qwen3.8:27b-nvfp4`, the
  first 2026-09-04 run.
- `m1max-64gb-qwen3.8_27b-nvfp4-2026-09-04-rerun.txt` — `qwen3.8:27b-nvfp4`,
  a same-day repeat of the full five-phase probe, run to rule out a one-off
  scheduling or GPU-contention artifact after the first run's
  "same system prompt, different question" and "interleaved unrelated
  request" rows came back as apparent full cold prefills.
- `m1max-64gb-qwen3.8_27b-nvfp4-2026-09-05-confirm.json` — `qwen3.8:27b-nvfp4`,
  a `--json`-capable run against the full five-phase probe, taken the same
  day as the archived 2026-09-05 re-measurement to check a since-retracted
  "flip" reading before it was recorded. It is a `ProbeRun`-shaped file, but
  it is not one of the counted archived runs — the notebook cites it as
  corroboration only, and it lives here so `check_results.dart` does not
  count it as one.

## What these back

All figures in `ModelBehavior.md`, "Three readings hold on both models; one
is a confirmed miss on the large model; retry-after-abort is unstable on
it" (grep `prompt_eval_cached_count`):

- `m1max-64gb-llama3.2_latest-2026-09-04.txt` backs every `llama3.2:latest`
  figure in that section's first M1 Max table (2079 ms → 12 ms; 87 ms;
  54 ms, 53 ms; 2170 ms; 39 ms; 30 ms).
- `m1max-64gb-qwen3.8_27b-nvfp4-2026-09-04.txt` backs that table's first
  `qwen3.8:27b-nvfp4` reading in each cell: 37779 ms → 133 ms; 40426 ms;
  812 ms, 804 ms; 40381 ms; 215 ms; 148 ms.
- `m1max-64gb-qwen3.8_27b-nvfp4-2026-09-04-rerun.txt` backs that table's
  second `qwen3.8:27b-nvfp4` reading in each cell (158 ms; 40377 ms; the
  repeat run's 430 ms, 802 ms, 812 ms per-turn figures cited in prose;
  40604 ms; 205 ms; **18154 ms**, the retry-after-abort outlier).
- `m1max-64gb-qwen3.8_27b-nvfp4-2026-09-05-confirm.json` backs the prose
  figures attributed to "the unarchived same-day rerun" / "unarchived
  corroboration run": cold prefill 35025 ms, interleaved-unrelated 36601 ms,
  the following repeat at 165 ms, the cross-question miss at 36685 ms, and
  the retry-after-abort reading at 142 ms.

## Relationship to the 2026-09-05 archived runs

`results-m1max-64gb-ollama0333/llama3.2_latest/prefill_cache_probe.json` and
`results-m1max-64gb-ollama0333/qwen3.8_27b-nvfp4/prefill_cache_probe.json`
are separate, later measurements — a third observation on each model, not a
re-take of the readings captured here. `ModelBehavior.md` reports the two
sets alongside each other rather than replacing one with the other.

The M5 / 16 GB readings in the same section have no capture at all, archived
or otherwise, and cannot get one from this host: the M5 measurement predates
`--json`, was never re-run, and this directory only holds M1 Max captures.
