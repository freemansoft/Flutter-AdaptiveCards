# Fit control on a 16 GB host, calibrated

Apple M5 / 16 GB, Ollama 0.33.3, `--samples 1`, measured 2026-09-12, with
the filler sized by per-model calibration rather than the fixed
`fillerCharsPerToken = 4.0`.

This is the M5 half of
[`m1max-64gb-ollama0333-fitcontrol-calibrated/`](../m1max-64gb-ollama0333-fitcontrol-calibrated)
under the same parameters that directory now uses, so the cross-host
comparison cites two live archives instead of resting on a superseded
commit. The uncalibrated predecessor is kept separately in
[`m5-16gb-ollama0333-fitcontrol-uncalibrated/`](../m5-16gb-ollama0333-fitcontrol-uncalibrated),
because both hosts ran that condition and re-running one side would not
preserve the comparison it establishes.

| Model                | `--fill-tokens` | `--num-ctx` | Allocated | Prompt tokens | Pass  | M1 Max pass |
| -------------------- | --------------- | ----------- | --------- | ------------- | ----- | ----------- |
| `nemotron-3-nano:4b` | 42000           | 65536       | 65536     | 48559         | 6/25  | 6/25        |
| `qwen3.5:9b`         | 42000           | 65536       | 65536     | 48537         | 16/25 | 16/25       |
| `qwen2.5-coder:7b`   | 20000           | 32768       | 32768     | 24721         | 20/25 | 19/25       |

Prompt counts and allocations match the M1 Max exactly, and the measured
chars-per-token match to every digit — calibration reads the tokenizer, and
the tokenizer is a property of the model rather than of the host. One case
separates the hosts, on `qwen2.5-coder:7b`, which is noise at `--samples 1`.

`qwen2.5-coder:7b` takes a smaller fill because its trained window is 32768
and Ollama allocates `min(requested, trained window)`, so a larger
`--num-ctx` would change nothing for it.

The medians in these runs are not comparable to the ones in the sibling
directories; see `ModelBehavior.md`'s context-fill section, which records a
3.8x same-host swing and does not rest any claim on them.

Not one of the seven sweep probes, and not swept by `check_results.dart`.
