# Empty window, `--samples 2`, flash attention on, f16 KV cache, Ollama 0.35.1

Apple M1 Max / 64 GB, Ollama 0.35.1 (Homebrew 0.35.1_1), measured 2026-10-24; the two MLX control rows 2026-10-25.

This directory is one cell of a four-way matrix: {empty, full} window by {f16, q8_0} KV cache, eight models, `context_fill_probe.dart --samples 2 --timeout 1800`, one model resident at a time. Each run is `--fill-tokens 0 --no-calibrate`, no history, at the same per-model `--num-ctx` as its full-window sibling (65536, or 32768 for `qwen2.5-coder:7b`), so the two windows differ only in the history they carry. The card system prompt hash is `8cbfde243266`. The server was a hand-started `ollama serve` with `OLLAMA_FLASH_ATTENTION=1` and `OLLAMA_KV_CACHE_TYPE=f16`, nothing else set (`llama-server` launched with `--flash-attn on --cache-type-k f16 --cache-type-v f16`). Flash attention is the same in all four cells, so the KV cache type is the only server setting that differs between [`m1max-64gb-ollama0351-fa1-kvq8-fill0-samples2/`](../m1max-64gb-ollama0351-fa1-kvq8-fill0-samples2) and this directory. Its window sibling is [`m1max-64gb-ollama0351-fa1-kvf16-full-samples2/`](../m1max-64gb-ollama0351-fa1-kvf16-full-samples2).

The 1800 s ceiling replaces the 180 s one earlier context-fill runs used. With one generation slot, a call the probe abandons keeps running on the server and every later call queues behind it, so under 180 s one slow first call was recorded as several timeouts. No call in this matrix timed out.

The two `nvfp4` builds load on Ollama's MLX runner rather than `llama-server`; the KV cache setting does not reach it. Driver and server-log excerpt: [`raw-captures/m1max_ollama0351_fa1_kv_matrix_2026_10_24.sh`](../../raw-captures/m1max_ollama0351_fa1_kv_matrix_2026_10_24.sh), [`raw-captures/m1max-64gb-ollama0351-fa1-kv-matrix-serverlog-2026-10-24.txt`](../../raw-captures/m1max-64gb-ollama0351-fa1-kv-matrix-serverlog-2026-10-24.txt).

Two MLX builds that are not `nvfp4` were added on 2026-10-25 as runner controls, same host, runtime and per-model inputs (65536 and 42000): `nemotron-3-nano-mlx:4b-bf16` (`bfloat16`, the same weights as `nemotron-3-nano:4b`) and `mvincig11/semif-qwen3.5-4b-mlx-4bit:latest` (`int4`). Both load on the MLX runner. Driver and server-log excerpt: [`raw-captures/m1max_ollama0351_fa1_kv_matrix_mlx_controls_2026_10_25.sh`](../../raw-captures/m1max_ollama0351_fa1_kv_matrix_mlx_controls_2026_10_25.sh), [`raw-captures/m1max-64gb-ollama0351-fa1-kv-matrix-mlx-controls-serverlog-2026-10-25.txt`](../../raw-captures/m1max-64gb-ollama0351-fa1-kv-matrix-mlx-controls-serverlog-2026-10-25.txt).

The notebook reads these figures in [the matched matrix section](../../../../ModelBehavior.md#with-flash-attention-and-the-window-held-constant-a-full-window-costs-two-nemotron-30b-builds-6-to-9-cases-and-no-call-stalls).

| Model                                        | `--num-ctx` | Allocated | Prompt tokens | Pass per sample | Longest call | `size_vram` |
| -------------------------------------------- | ----------- | --------- | ------------- | --------------- | ------------ | ----------- |
| `nemotron-3-nano:30b`                        | 65536       | 65536     | 4032–4047     | 19 / 19         | 19 s         | 25.18 GB    |
| `nemotron-3-nano:4b`                         | 65536       | 65536     | 4379–4395     | 9 / 9           | 10 s         | 4.40 GB     |
| `nemotron-3.5-lightning:30b`                 | 65536       | 65536     | 4032–4047     | 21 / 21         | 19 s         | 26.13 GB    |
| `qwen2.5-coder:7b`                           | 32768       | 32768     | 3855–3870     | 22 / 22         | 22 s         | 6.58 GB     |
| `qwen3-coder:30b`                            | 65536       | 65536     | 3855–3870     | 18 / 18         | 15 s         | 25.41 GB    |
| `qwen3.5:9b`                                 | 65536       | 65536     | 3970–3985     | 17 / 17         | 20 s         | 8.16 GB     |
| `qwen3.6:27b-coding-nvfp4`                   | 65536       | 65536     | 3968–3983     | 23 / 23         | 47 s         | 20.32 GB    |
| `qwen3.8:27b-nvfp4`                          | 65536       | 65536     | 3972–3987     | 21 / 22         | 146 s        | 18.76 GB    |
| `nemotron-3-nano-mlx:4b-bf16`                | 65536       | 65536     | 4031–4046     | 10 / 10         | 7 s          | 8.19 GB     |
| `mvincig11/semif-qwen3.5-4b-mlx-4bit:latest` | 65536       | 65536     | 3969–3984     | 18 / 20         | 8 s          | 2.60 GB     |
