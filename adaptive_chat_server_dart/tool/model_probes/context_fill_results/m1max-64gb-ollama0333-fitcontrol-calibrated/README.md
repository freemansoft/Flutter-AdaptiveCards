# Fit control, calibrated: a filler sized to fit each model's own window

Apple M1 Max / 64 GB, Ollama 0.33.3, `--samples 1`, measured 2026-09-12
with per-model calibration on, so each `--fill-tokens` target means what it
says on that model's tokenizer rather than on an assumed 4.0 chars/token.

**`-calibrated` is in the name because uncalibrated fit controls exist.**
This directory was measured under the fixed 4.0 constant until 2026-09-12
and re-measured after it; the run it replaced survives in commit `9698553`
rather than in the tree. The M5 host carries both conditions side by side,
in [`m5-16gb-ollama0333-fitcontrol-uncalibrated/`](../m5-16gb-ollama0333-fitcontrol-uncalibrated)
and [`m5-16gb-ollama0333-fitcontrol-calibrated/`](../m5-16gb-ollama0333-fitcontrol-calibrated),
so no fit-control directory anywhere in this tree leaves its calibration
state to be inferred from a date.

The sibling `m1max-64gb-ollama0333-fill28000/` directories hold a **fixed**
filler: the same text, sized at 28000 tokens by `fillerCharsPerToken = 4.0`,
sent to every model. That constant holds for llama, granite and gpt-oss
tokenizers at roughly 4.30 chars/token and for nothing else measured, so for
models whose tokenizers are denser the prompt overflowed the window the
probe had sized for it and Ollama dropped the history message whole. Six
models recorded that way look like they discarded a message they had room
for.

This directory is the control that shows they did not. Each model here gets
a filler that fits inside the window it is actually allocated, and every one
ingests it. The name deliberately does not use the `-fillN` form the sibling
directories use, because the parameters differ per model rather than being
one number the directory can state. Each run's own `summary` fields are the
record:

| Model                        | `--fill-tokens` | `--num-ctx` | chars/token | Prompt tokens | Pass  |
| ---------------------------- | --------------- | ----------- | ----------- | ------------- | ----- |
| `qwen3-coder:30b`            | 42000           | 65536       | 3.08        | 48459         | 20/25 |
| `qwen3.6:27b-coding-nvfp4`   | 42000           | 65536       | 3.07        | 48535         | 20/25 |
| `qwen2.5-coder:7b`           | 20000           | 32768       | 3.08        | 24721         | 19/25 |
| `qwen3.5:9b`                 | 42000           | 65536       | 3.07        | 48537         | 16/25 |
| `qwen3.8:27b-nvfp4`          | 42000           | 65536       | 3.07        | 48539         | 16/25 |
| `nemotron-3.5-lightning:30b` | 42000           | 65536       | 3.07        | 48600         | 13/25 |
| `nemotron-3-nano:30b`        | 42000           | 65536       | 3.07        | 48611         | 12/25 |
| `nemotron-3-nano:4b`         | 42000           | 65536       | 2.81        | 48559         | 6/25  |

Prompt tokens run about 3% above target once each model's own system prompt
is subtracted. The filler is indexed, so its digit strings lengthen as it
grows and a 118,000-character filler tokenizes slightly denser than the
10,000-character sample calibration measures. Read the achieved count, not
the flag.

The two `nvfp4` builds are here for a different reason than the rest. They
never dropped the filler: under the fixed-filler sweep they evaluated about
6,700 tokens more than the 35851 `/api/ps` reported allocating, and scored
17/25 and 21/25 rather than collapsing. Exceeding the reported allocation
cost them nothing where it costs every other model the whole message.

`qwen2.5-coder:7b` is the one that could not be fixed by raising the
ceiling. Its trained window is 32768 and Ollama allocates
`min(requested, trained window)`, so a larger `--num-ctx` changes nothing
for it. It takes a smaller filler instead, and at 24721 tokens still runs
its window about three quarters full.

Not one of the seven sweep probes, and not swept by `check_results.dart`.
See `ModelBehavior.md`'s context-fill section for what these runs
establish.
