# Full window, calibrated filler, `--samples 2`, flash attention on, f16 KV cache, Ollama 0.35.1

Apple M1 Max / 64 GB, Ollama 0.35.1 (Homebrew 0.35.1_1), measured 2026-10-24.

This directory is one cell of a four-way matrix: {empty, full} window by {f16, q8_0} KV cache, eight models, `context_fill_probe.dart --samples 2 --timeout 1800`, one model resident at a time. Each run is the calibrated fit control's per-model `--num-ctx` and `--fill-tokens` (65536 and 42000, or 32768 and 20000 for `qwen2.5-coder:7b`), a filler sized to this model's own measured characters per token. The card system prompt hash is `8cbfde243266`. The server was a hand-started `ollama serve` with `OLLAMA_FLASH_ATTENTION=1` and `OLLAMA_KV_CACHE_TYPE=f16`, nothing else set (`llama-server` launched with `--flash-attn on --cache-type-k f16 --cache-type-v f16`). Flash attention is the same in all four cells, so the KV cache type is the only server setting that differs between [`m1max-64gb-ollama0351-fa1-kvq8-full-samples2/`](../m1max-64gb-ollama0351-fa1-kvq8-full-samples2) and this directory. Its window sibling is [`m1max-64gb-ollama0351-fa1-kvf16-fill0-samples2/`](../m1max-64gb-ollama0351-fa1-kvf16-fill0-samples2).

The 1800 s ceiling replaces the 180 s one earlier context-fill runs used. With one generation slot, a call the probe abandons keeps running on the server and every later call queues behind it, so under 180 s one slow first call was recorded as several timeouts. No call in this matrix timed out.

The two `nvfp4` builds load on Ollama's MLX runner rather than `llama-server`; the KV cache setting does not reach it. Driver and server-log excerpt: [`raw-captures/m1max_ollama0351_fa1_kv_matrix_2026_10_24.sh`](../../raw-captures/m1max_ollama0351_fa1_kv_matrix_2026_10_24.sh), [`raw-captures/m1max-64gb-ollama0351-fa1-kv-matrix-serverlog-2026-10-24.txt`](../../raw-captures/m1max-64gb-ollama0351-fa1-kv-matrix-serverlog-2026-10-24.txt).

The notebook reads these figures in [the matched matrix section](../../../../ModelBehavior.md#with-flash-attention-and-the-window-held-constant-a-full-window-costs-two-nemotron-30b-builds-6-to-9-cases-and-no-call-stalls).

| Model                        | `--num-ctx` | Allocated | Prompt tokens | Pass per sample | Longest call | `size_vram` |
| ---------------------------- | ----------- | --------- | ------------- | --------------- | ------------ | ----------- |
| `nemotron-3-nano:30b`        | 65536       | 65536     | 48611–48626   | 11 / 11         | 115 s        | 24.65 GB    |
| `nemotron-3-nano:4b`         | 65536       | 65536     | 48559–48575   | 6 / 6           | 119 s        | 4.40 GB     |
| `nemotron-3.5-lightning:30b` | 65536       | 65536     | 48600–48615   | 13 / 13         | 122 s        | 25.58 GB    |
| `qwen2.5-coder:7b`           | 32768       | 32768     | 24721–24736   | 19 / 19         | 101 s        | 6.58 GB     |
| `qwen3-coder:30b`            | 65536       | 65536     | 48459–48474   | 20 / 20         | 320 s        | 25.07 GB    |
| `qwen3.5:9b`                 | 65536       | 65536     | 48537–48552   | 17 / 17         | 197 s        | 8.16 GB     |
| `qwen3.6:27b-coding-nvfp4`   | 65536       | 65536     | 48535–48550   | 23 / 23         | 637 s        | 24.01 GB    |
| `qwen3.8:27b-nvfp4`          | 65536       | 65536     | 48539–48554   | 18 / 21         | 640 s        | 22.64 GB    |
