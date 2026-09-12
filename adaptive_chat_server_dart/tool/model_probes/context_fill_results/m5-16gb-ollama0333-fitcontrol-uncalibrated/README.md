# Fit control on a 16 GB host, uncalibrated: the same filler, the same result

Apple M5 / 16 GB, Ollama 0.33.3, `--samples 1`, measured 2026-09-11, with
the filler sized by the fixed `fillerCharsPerToken = 4.0` rather than by
per-model calibration.

**`-uncalibrated` is in the name because a calibrated sibling exists.** The
probe now measures each model's own chars-per-token before sizing the
filler, and [`m5-16gb-ollama0333-fitcontrol-calibrated/`](../m5-16gb-ollama0333-fitcontrol-calibrated)
holds the same three models under that change. This directory is kept
rather than replaced: it is the M5 half of a cross-host comparison whose
value is that both hosts ran the identical uncalibrated condition, and the
M1 Max half of it survives in commit `9698553` rather than in the tree.

This was the memory-constrained half of
[`m1max-64gb-ollama0333-fitcontrol/`](../m1max-64gb-ollama0333-fitcontrol)
as that directory stood on 2026-09-11, before it was re-measured under
calibration. That directory established that a filler sized to fit a
model's own window is ingested rather than dropped; it could not establish
whether host memory was what allowed it, because it was measured on a 64 GB
machine. These three models are the ones a 16 GB host can hold under these
windows.

Every prompt count and every pass count is identical to the M1 Max reading:

| Model                | `--fill-tokens` | `--num-ctx` | Allocated | Prompt tokens | Pass  |
| -------------------- | --------------- | ----------- | --------- | ------------- | ----- |
| `nemotron-3-nano:4b` | 28000           | 65536       | 65536     | 46287         | 6/25  |
| `qwen3.5:9b`         | 28000           | 65536       | 65536     | 42540         | 19/25 |
| `qwen2.5-coder:7b`   | 12000           | 32768       | 32768     | 19974         | 21/25 |

A 16 GB machine allocating the full 65536 window it requested is the reading
that matters here. Together with the fixed-filler runs in
[`m5-16gb-ollama0333-fill28000/`](../m5-16gb-ollama0333-fill28000), where
`qwen2.5-coder:7b` clamps to its own 32768 trained window on both hosts, it
puts allocation at `min(requested, trained window)` on this host too, with
available memory not entering into it.

Median latency is the one column that differs between the hosts, and it
differs in both directions — see `ModelBehavior.md`'s context-fill section,
which reports it rather than attributing it, since each figure is a single
`--samples 1` measurement and the position effect measured elsewhere in that
file is larger than the gap.

Not one of the seven sweep probes, and not swept by `check_results.dart`.
