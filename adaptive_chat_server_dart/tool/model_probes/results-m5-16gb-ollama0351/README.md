# Results: Apple M5 / 16 GB, Ollama 0.35.1

The eight 16 GB candidates, swept starting 2026-10-03 by `sweep.sh` with
`SWEEP_COOLDOWN=600`, in the fixed order
`granite4.1:8b qwen2.5-coder:7b qwen3.5:9b llama3-groq-tool-use:8b
llama3.2:latest llama3-chatqa:8b nemotron-3-nano:4b granite4.1:3b`, matched
with the Apple M1 Max / 64 GB directory `results-m1max-64gb-ollama0351/`.
`shape_ab` calls carry Ollama's per-call `timings`. `powermetrics.txt` holds
GPU frequency and thermal-pressure samples taken during the sweep.
