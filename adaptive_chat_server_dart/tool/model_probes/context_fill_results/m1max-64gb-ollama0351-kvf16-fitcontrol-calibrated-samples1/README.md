# Calibrated fit control, `--samples 1` under Ollama 0.35.1, f16 KV cache

Apple M1 Max / 64 GB, Ollama 0.35.1 (Homebrew 0.35.1_1), measured 2026-10-22.

This directory repeats [`m1max-64gb-ollama0340-fitcontrol-calibrated/`](../m1max-64gb-ollama0340-fitcontrol-calibrated), via `context_fill_fit_control.sh`, same per-model `--num-ctx` and `--fill-tokens`. The card system prompt hash is `8cbfde243266`. The server was a hand-started `ollama serve` with `OLLAMA_KV_CACHE_TYPE=f16`, `OLLAMA_CONTEXT_LENGTH=32768` and `OLLAMA_FLASH_ATTENTION` unset (`llama-server` launched with `--flash-attn auto --cache-type-k f16`), the 0.34.0 Ollama app's effective settings.

Its sibling with the other KV cache type is [`m1max-64gb-ollama0351-kvq8-fitcontrol-calibrated-samples1/`](../m1max-64gb-ollama0351-kvq8-fitcontrol-calibrated-samples1).

The two `nvfp4` builds load on Ollama's MLX runner rather than `llama-server`; the KV cache setting does not reach it, and their results match across the two KV directories.

The notebook's context-fill section reads these figures; see the [KV cache section](../../../../ModelBehavior.md#a-q8_0-kv-cache-roughly-halves-the-kv-cache-and-moves-two-of-eight-full-window-scores).

| Model                      | `--num-ctx` | Allocated | Prompt tokens | Pass  | `size_vram` |
| -------------------------- | ----------- | --------- | ------------- | ----- | ----------- |
| `nemotron-3-nano:30b`      | 65536       | 65536     | 48611–48626   | 11/25 | 24.65 GB    |
| `qwen3.6:27b-coding-nvfp4` | 65536       | 65536     | 48535–48550   | 20/25 | 19.74 GB    |
| `qwen3.8:27b-nvfp4`        | 65536       | 65536     | 48539–48554   | 14/25 | 18.16 GB    |
