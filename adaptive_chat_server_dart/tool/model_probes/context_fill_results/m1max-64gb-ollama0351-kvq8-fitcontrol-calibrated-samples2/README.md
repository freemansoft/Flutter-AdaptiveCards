# Calibrated fit control, `--samples 2` under Ollama 0.35.1, q8_0 KV cache

Apple M1 Max / 64 GB, Ollama 0.35.1 (Homebrew 0.35.1_1), measured 2026-10-22.

This directory repeats the eight full-window models of [`m1max-64gb-ollama0340-fitcontrol-calibrated/`](../m1max-64gb-ollama0340-fitcontrol-calibrated) at the same per-model `--num-ctx` and `--fill-tokens`, run directly through `context_fill_probe.dart --samples 2`. The card system prompt hash is `8cbfde243266`. The server was the Homebrew service (`~/Library/LaunchAgents/sh.brew.ollama.plist`: `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0`, `llama-server` launched with `--flash-attn on --cache-type-k q8_0 --cache-type-v q8_0`).

Its sibling with the other KV cache type is [`m1max-64gb-ollama0351-kvf16-fitcontrol-calibrated-samples2/`](../m1max-64gb-ollama0351-kvf16-fitcontrol-calibrated-samples2).

The two `nvfp4` builds load on Ollama's MLX runner rather than `llama-server`; the KV cache setting does not reach it, and their results match across the two KV directories.

The notebook's context-fill section reads these figures; see the [KV cache section](../../../../ModelBehavior.md#a-q8_0-kv-cache-roughly-halves-the-kv-cache-and-moves-two-of-eight-full-window-scores).

| Model                        | `--num-ctx` | Allocated | Prompt tokens | Pass per sample | `size_vram` |
| ---------------------------- | ----------- | --------- | ------------- | --------------- | ----------- |
| `nemotron-3-nano:30b`        | 65536       | 65536     | 48611–48626   | 8 / 8           | 24.47 GB    |
| `nemotron-3-nano:4b`         | 65536       | 65536     | 48559–48575   | 6 / 6           | 3.96 GB     |
| `nemotron-3.5-lightning:30b` | 65536       | 65536     | 48600–48615   | 15 / 15         | 25.82 GB    |
| `qwen2.5-coder:7b`           | 32768       | 32768     | 24721–24736   | 19 / 19         | 5.71 GB     |
| `qwen3-coder:30b`            | 65536       | 65536     | 48459–48474   | 19 / 21         | 22.13 GB    |
| `qwen3.5:9b`                 | 65536       | 65536     | 48537–48552   | 16 / 17         | 7.19 GB     |
| `qwen3.6:27b-coding-nvfp4`   | 65536       | 65536     | 48535–48550   | 21 / 22         | 19.74 GB    |
| `qwen3.8:27b-nvfp4`          | 65536       | 65536     | 48539–48554   | 16 / 18         | 18.16 GB    |
