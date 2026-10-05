# Results: Apple M1 Max / 64 GB, Ollama 0.35.1

The eight 16 GB candidates, swept 2026-10-03, 20:05 to 23:24 local, by
`sweep.sh` with `SWEEP_COOLDOWN=600`, in the fixed order
`granite4.1:8b qwen2.5-coder:7b qwen3.5:9b llama3-groq-tool-use:8b
llama3.2:latest llama3-chatqa:8b nemotron-3-nano:4b granite4.1:3b`, to be
matched with the Apple M5 / 16 GB directory `results-m5-16gb-ollama0351/`.
`shape_ab` calls carry Ollama's per-call `timings`. `nemotron-3-nano:4b`
recorded 2 stalls in `temperature_matrix.json`; every other model recorded 0.
