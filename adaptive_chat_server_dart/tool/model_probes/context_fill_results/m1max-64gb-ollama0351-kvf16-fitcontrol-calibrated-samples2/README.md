# Calibrated fit control, `--samples 2` under Ollama 0.35.1, f16 KV cache

Apple M1 Max / 64 GB, Ollama 0.35.1 (Homebrew 0.35.1_1), measured 2026-10-22.

This directory repeats the eight full-window models of [`m1max-64gb-ollama0340-fitcontrol-calibrated/`](../m1max-64gb-ollama0340-fitcontrol-calibrated) at the same per-model `--num-ctx` and `--fill-tokens`, run directly through `context_fill_probe.dart --samples 2`. The card system prompt hash is `8cbfde243266`. The server was a hand-started `ollama serve` with `OLLAMA_KV_CACHE_TYPE=f16`, `OLLAMA_CONTEXT_LENGTH=32768` and `OLLAMA_FLASH_ATTENTION` unset (`llama-server` launched with `--flash-attn auto --cache-type-k f16`), the 0.34.0 Ollama app's effective settings.

Its sibling with the other KV cache type is [`m1max-64gb-ollama0351-kvq8-fitcontrol-calibrated-samples2/`](../m1max-64gb-ollama0351-kvq8-fitcontrol-calibrated-samples2).

The two `nvfp4` builds load on Ollama's MLX runner rather than `llama-server`; the KV cache setting does not reach it, and their results match across the two KV directories.

The notebook's context-fill section reads these figures; see the [KV cache section](../../../../ModelBehavior.md#a-q8_0-kv-cache-roughly-halves-the-kv-cache-and-moves-two-of-eight-full-window-scores).

| Model                        | `--num-ctx` | Allocated | Prompt tokens | Pass per sample | `size_vram` |
| ---------------------------- | ----------- | --------- | ------------- | --------------- | ----------- |
| `nemotron-3-nano:30b`        | 65536       | 65536     | 48611–48626   | 11 / 11         | 24.65 GB    |
| `nemotron-3-nano:4b`         | 65536       | 65536     | 48559–48575   | 6 / 6           | 4.40 GB     |
| `nemotron-3.5-lightning:30b` | 65536       | 65536     | 48600–48615   | 13 / 13         | 25.58 GB    |
| `qwen2.5-coder:7b`           | 32768       | 32768     | 24721–24736   | 19 / 19         | 6.58 GB     |
| `qwen3-coder:30b`            | 65536       | 65536     | 48459–48474   | 19 / 20         | 25.18 GB    |
| `qwen3.5:9b`                 | 65536       | 65536     | 48537–48552   | 16 / 17         | 8.16 GB     |
| `qwen3.6:27b-coding-nvfp4`   | 65536       | 65536     | 48535–48550   | 21 / 22         | 19.74 GB    |
| `qwen3.8:27b-nvfp4`          | 65536       | 65536     | 48539–48554   | 16 / 19         | 18.16 GB    |
