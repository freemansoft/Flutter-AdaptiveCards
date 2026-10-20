# Results: Apple M5 / 16 GB, Ollama 0.35.1

The eight 16 GB candidates, swept 2026-10-03 to 2026-10-04 by `sweep.sh` with
`SWEEP_COOLDOWN=600`, in the fixed order
`granite4.1:8b qwen2.5-coder:7b qwen3.5:9b llama3-groq-tool-use:8b
llama3.2:latest llama3-chatqa:8b nemotron-3-nano:4b granite4.1:3b`, matched
with the Apple M1 Max / 64 GB directory `results-m1max-64gb-ollama0351/`.
`shape_ab` calls carry Ollama's per-call `timings`. `powermetrics.txt` holds
GPU frequency and thermal-pressure samples taken during the sweep.
`granite4.1:3b` stalled on 56 of its 100 calls in `shape_ab-unaided.json` (45 warm, 11 cold; 0 stalls in `shape_ab-seeded.json` and `cascade_ab.json`); `llama3.2:latest` stalled on 4 calls in `temperature_matrix.json`; `nemotron-3-nano:4b` on 3, also in `temperature_matrix.json`; every other model recorded 0.
