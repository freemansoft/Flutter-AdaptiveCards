# Empty-window baseline for the two `nvfp4` builds and two MLX controls under Ollama 0.35.1, q8_0 KV cache

Apple M1 Max / 64 GB, Ollama 0.35.1 (Homebrew 0.35.1_1), measured 2026-10-22.

This directory repeats [`m1max-64gb-ollama0340-fill0/`](../m1max-64gb-ollama0340-fill0): `--fill-tokens 0 --num-ctx 35851 --no-calibrate`. The card system prompt hash is `8cbfde243266`. The server was the Homebrew service (`~/Library/LaunchAgents/sh.brew.ollama.plist`: `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0`, `llama-server` launched with `--flash-attn on --cache-type-k q8_0 --cache-type-v q8_0`).

Its sibling with the other KV cache type is [`m1max-64gb-ollama0351-kvf16-fill0/`](../m1max-64gb-ollama0351-kvf16-fill0).

The two `nvfp4` builds load on Ollama's MLX runner rather than `llama-server`; the KV cache setting does not reach it, and their results match across the two KV directories.

Two MLX-runner control builds without `nvfp4` quantization, `nemotron-3-nano-mlx:4b-bf16` and `mvincig11/semif-qwen3.5-4b-mlx-4bit:latest`, were added the same evening (21:20 to 21:28) to test whether the overrun follows the runner or the quantization. The server log extract is [`m1max-64gb-ollama0351-mlx-runner-controls-serverlog-2026-10-22.txt`](../../raw-captures/m1max-64gb-ollama0351-mlx-runner-controls-serverlog-2026-10-22.txt).

The notebook's context-fill section reads these figures; see the [KV cache section](../../../../ModelBehavior.md#a-q8_0-kv-cache-roughly-halves-the-kv-cache-and-moves-two-of-eight-full-window-scores).

| Model                                        | `--num-ctx` | Allocated | Prompt tokens | Pass  | `size_vram` |
| -------------------------------------------- | ----------- | --------- | ------------- | ----- | ----------- |
| `qwen3.6:27b-coding-nvfp4`                   | 35851       | 35851     | 3968–3983     | 23/25 | 20.32 GB    |
| `qwen3.8:27b-nvfp4`                          | 35851       | 35851     | 3972–3987     | 21/25 | 18.76 GB    |
| `nemotron-3-nano-mlx:4b-bf16`                | 35851       | 35851     | 4031–4046     | 10/25 | 8.19 GB     |
| `mvincig11/semif-qwen3.5-4b-mlx-4bit:latest` | 35851       | 35851     | 3969–3984     | 18/25 | 2.60 GB     |
