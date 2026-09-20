# Fixed 28000-token filler under Ollama 0.34.0: identical to 0.33.3

Apple M1 Max / 64 GB, Ollama 0.34.0, `--samples 1`, measured 2026-09-18.

This directory repeats
[`m1max-64gb-ollama0333-fill28000/`](../m1max-64gb-ollama0333-fill28000) on
a newer runtime, to test whether the allocation rule, the whole-message drop
and the two `nvfp4` overruns recorded under 0.33.3 still hold. The card system
prompt is the same file (hash `8cbfde243266`) and the host is the same.

**The filler is sized the same way as the 0.33.3 sibling.** Both use the fixed
`fillerCharsPerToken = 4.0`: a 112,005-character filler, a 35851-token request.
The probe now calibrates by default, so this run passed `--no-calibrate`
through `context_fill_sweep.sh`:

```sh
cd adaptive_chat_server_dart
CONTEXT_FILL_RESULTS=tool/model_probes/context_fill_results/m1max-64gb-ollama0340-fill28000 \
CONTEXT_FILL_NO_CALIBRATE=1 \
  tool/model_probes/context_fill_sweep.sh llama3.2:latest nemotron-3-nano:4b \
  llama3-groq-tool-use:8b llama3-chatqa:8b granite4.1:8b granite4.1:3b \
  qwen2.5-coder:7b qwen3.5:9b gpt-oss:20b qwen3.8:27b-nvfp4 \
  qwen3.6:27b-coding-nvfp4 qwen3-coder:30b nemotron-3-nano:30b \
  nemotron-3.5-lightning:30b
```

All fourteen models return the same allocated window, the same prompt token
range and the same pass count as under 0.33.3:

| Model                        | Allocated | Prompt tokens | History | Pass  |
| ---------------------------- | --------- | ------------- | ------- | ----- |
| `llama3.2:latest`            | 35851     | 29546–29561   | kept    | 9/25  |
| `granite4.1:8b`              | 35851     | 29536–29551   | kept    | 8/25  |
| `granite4.1:3b`              | 35851     | 29536–29551   | kept    | 3/25  |
| `gpt-oss:20b`                | 35851     | 29616–29631   | kept    | 24/25 |
| `nemotron-3-nano:4b`         | 35851     | 4374–4390     | dropped | 8/25  |
| `qwen3.5:9b`                 | 35851     | 3965–3980     | dropped | 18/25 |
| `qwen2.5-coder:7b`           | 32768     | 3850–3865     | dropped | 22/25 |
| `llama3-groq-tool-use:8b`    | 8192      | 3825–3840     | dropped | 10/25 |
| `llama3-chatqa:8b`           | 8192      | 3819–3832     | dropped | 2/25  |
| `qwen3-coder:30b`            | 35851     | 3850–3865     | dropped | 18/25 |
| `nemotron-3-nano:30b`        | 35851     | 4027–4042     | dropped | 17/25 |
| `nemotron-3.5-lightning:30b` | 35851     | 4027–4042     | dropped | 20/25 |
| `qwen3.8:27b-nvfp4`          | 35851     | 42542–42557   | overran | 17/25 |
| `qwen3.6:27b-coding-nvfp4`   | 35851     | 42538–42553   | overran | 21/25 |

The pass counts are `--samples 1` at temperature 0, so agreement to the case
says the runtime change did not change which cases pass. It says nothing about
run-to-run variance.
