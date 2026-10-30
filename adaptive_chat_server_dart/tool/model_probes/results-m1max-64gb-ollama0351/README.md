# Results: Apple M1 Max / 64 GB, Ollama 0.35.1

The eight 16 GB candidates, swept 2026-10-03, 20:05 to 23:24 local, by
`sweep.sh` with `SWEEP_COOLDOWN=600`, in the fixed order
`granite4.1:8b qwen2.5-coder:7b qwen3.5:9b llama3-groq-tool-use:8b
llama3.2:latest llama3-chatqa:8b nemotron-3-nano:4b granite4.1:3b`, to be
matched with the Apple M5 / 16 GB directory `results-m5-16gb-ollama0351/`.
`shape_ab` calls carry Ollama's per-call `timings`. `nemotron-3-nano:4b`
recorded 2 stalls in `temperature_matrix.json`; every other model recorded 0.

## Prompt-cache runs, 2026-10-27

`prefill_cache_probe.dart`, the nine-phase variant, re-run for all seventeen
models of the 0.34.0 prompt-cache matrix, one model resident, `t=0`,
`num_ctx` 8192, `num_predict` 60, `think: false`, 22:40 to 23:58 local, then
one re-run at 23:58. Each model directory that has one holds
`prefill_cache_probe-<variant>.json` and a `server-log-<variant>.txt` filtered
from `/opt/homebrew/var/log/ollama.log` for the run's line window (runner
launch, batch size, memory type, checkpoint and `prefix_cache` lines, request
terminations). The `starting llama-server` line is elided to the batch flags
and the cache and flash-attention flags every launch carried. Variants:

- `entries300-ninephase`: all seventeen models.
- `entries300-ninephase-run2` and `cardprompt-ninephase`: `llama3.2:latest`,
  `qwen3.5:9b`, `nemotron-3-nano:4b`, `qwen3.8:27b-nvfp4`. The card-prompt
  runs send `assets/card_system_prompt.txt` via `--system-file`.
- `entries100/150/200/450-ninephase`: `qwen3.5:9b`; `entries150-ninephase`:
  `nemotron-3-nano:4b`.
- `nemotron-3-nano_30b/prefill_cache_probe-entries300-ninephase-batch512.json`:
  the first run of that model, which Ollama launched with `-b 512 -ub 512` at
  29.9 GiB free memory. It is kept as a batch-size control; the
  `entries300-ninephase` file beside it is the re-run at `-b 1024`. Every
  other `llama-server` run here launched with `-b 1024 -ub 1024`.

Read in `ModelBehavior.md` under "Ollama 0.35.1 reproduces every 0.34.0 cache
shape except the unsloth Nemotron build, which now stays warm".
