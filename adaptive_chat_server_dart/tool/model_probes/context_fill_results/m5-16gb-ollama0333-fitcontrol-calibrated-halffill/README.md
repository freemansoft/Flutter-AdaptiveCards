# Half fill: the same windows, half the occupancy

Apple M5 / 16 GB, Ollama 0.33.3, `--samples 1`, calibrated, measured
2026-09-12.

The second fill level for the three models a 16 GB host can hold. Each
model keeps the `--num-ctx` it was given in
[`m5-16gb-ollama0333-fitcontrol-calibrated/`](../m5-16gb-ollama0333-fitcontrol-calibrated)
and takes roughly half the filler, so **occupancy is the only variable**
between the two directories. It exists because the filled-context cost was
a single point, and one point cannot distinguish a proportional effect from
a threshold.

| Model                | `--fill-tokens` | `--num-ctx` | Prompt tokens | Pass  | Full-fill pass |
| -------------------- | --------------- | ----------- | ------------- | ----- | -------------- |
| `nemotron-3-nano:4b` | 20000           | 65536       | 25065         | 7/25  | 6/25           |
| `qwen3.5:9b`         | 20000           | 65536       | 24813         | 14/25 | 16/25          |
| `qwen2.5-coder:7b`   | 10000           | 32768       | 13966         | 21/25 | 20/25          |

Pooled against the fixed-filler sweep's near-empty readings, coverage runs
47/75 near-empty, 42/75 here, 42/75 at full fill: the drop is between
near-empty and half, and nothing further is lost between half and full.
Two models decline by one case per step and `qwen3.5:9b` does not decline
at all, so no single model's steps clear the `--samples 1` noise floor on
their own. See `ModelBehavior.md`'s context-fill section for what this does
and does not establish.

Not one of the seven sweep probes, and not swept by `check_results.dart`.
