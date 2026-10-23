# Fixed 28000-token filler under Ollama 0.35.1, q8_0 KV cache

Apple M1 Max / 64 GB, Ollama 0.35.1 (Homebrew 0.35.1_1), measured 2026-10-22.

This directory repeats the fixed-filler sweep of [`m1max-64gb-ollama0340-fill28000/`](../m1max-64gb-ollama0340-fill28000), same `--no-calibrate` 4.0 characters-per-token sizing and 35851-token request. The card system prompt hash is `8cbfde243266`. The server was the Homebrew service (`~/Library/LaunchAgents/sh.brew.ollama.plist`: `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0`, `llama-server` launched with `--flash-attn on --cache-type-k q8_0 --cache-type-v q8_0`).

Its sibling with the other KV cache type is [`m1max-64gb-ollama0351-kvf16-fill28000/`](../m1max-64gb-ollama0351-kvf16-fill28000).

The two `nvfp4` builds load on Ollama's MLX runner rather than `llama-server`; the KV cache setting does not reach it, and their results match across the two KV directories.

Two MLX-runner control builds without `nvfp4` quantization, `nemotron-3-nano-mlx:4b-bf16` and `mvincig11/semif-qwen3.5-4b-mlx-4bit:latest`, were added the same evening (21:20 to 21:28) to test whether the overrun follows the runner or the quantization. The server log extract is [`m1max-64gb-ollama0351-mlx-runner-controls-serverlog-2026-10-22.txt`](../../raw-captures/m1max-64gb-ollama0351-mlx-runner-controls-serverlog-2026-10-22.txt).

The notebook's context-fill section reads these figures; see the [KV cache section](../../../../ModelBehavior.md#a-q8_0-kv-cache-roughly-halves-the-kv-cache-and-moves-two-of-eight-full-window-scores).

| Model                                        | `--num-ctx` | Allocated | Prompt tokens | Pass  | `size_vram` |
| -------------------------------------------- | ----------- | --------- | ------------- | ----- | ----------- |
| `gpt-oss:20b`                                | 35851       | 35851     | 29616–29631   | 23/25 | 13.14 GB    |
| `granite4.1:3b`                              | 35851       | 35851     | 29536–29551   | 3/25  | 4.08 GB     |
| `granite4.1:8b`                              | 35851       | 35851     | 29536–29551   | 8/25  | 9.05 GB     |
| `llama3-chatqa:8b`                           | 35851       | 8192      | 3819–3832     | 2/25  | 5.17 GB     |
| `llama3-groq-tool-use:8b`                    | 35851       | 8192      | 3825–3840     | 10/25 | 5.47 GB     |
| `llama3.2:latest`                            | 35851       | 35851     | 29546–29561   | 11/25 | 4.64 GB     |
| `nemotron-3-nano:30b`                        | 35851       | 35851     | 4027–4042     | 18/25 | 24.80 GB    |
| `nemotron-3-nano:4b`                         | 35851       | 35851     | 4374–4390     | 9/25  | 3.49 GB     |
| `nemotron-3.5-lightning:30b`                 | 35851       | 35851     | 4027–4042     | 21/25 | 25.95 GB    |
| `qwen2.5-coder:7b`                           | 35851       | 32768     | 3850–3865     | 22/25 | 5.71 GB     |
| `qwen3-coder:30b`                            | 35851       | 35851     | 3850–3865     | 18/25 | 20.76 GB    |
| `qwen3.5:9b`                                 | 35851       | 35851     | 3965–3980     | 17/25 | 6.47 GB     |
| `qwen3.6:27b-coding-nvfp4`                   | 35851       | 35851     | 42538–42553   | 20/25 | 19.74 GB    |
| `qwen3.8:27b-nvfp4`                          | 35851       | 35851     | 42542–42557   | 16/25 | 18.16 GB    |
| `nemotron-3-nano-mlx:4b-bf16`                | 35851       | 35851     | 42601–42616   | 6/25  | 9.25 GB     |
| `mvincig11/semif-qwen3.5-4b-mlx-4bit:latest` | 35851       | 35851     | 42539–42554   | 20/25 | 4.13 GB     |
