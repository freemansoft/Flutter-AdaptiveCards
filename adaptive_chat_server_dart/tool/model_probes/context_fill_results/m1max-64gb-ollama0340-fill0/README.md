# Empty-window baseline for the two `nvfp4` builds

Apple M1 Max / 64 GB, Ollama 0.34.0, `--samples 1`, measured 2026-09-18.

`qwen3.8:27b-nvfp4` and `qwen3.6:27b-coding-nvfp4` never dropped the
28000-token filler: they evaluated about 6,700 tokens past their 35851-token
allocation instead. Until this run neither had an empty-window score, so
whether the overrun cost them anything was not measured. This directory is
that baseline, paired with
[`m1max-64gb-ollama0340-fill28000/`](../m1max-64gb-ollama0340-fill28000) on
the same host, runtime and system prompt. The window request is held at 35851
so the filler is the only input that differs:

```sh
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/context_fill_probe.dart --model <model> \
  --fill-tokens 0 --num-ctx 35851 --no-calibrate \
  --json tool/model_probes/context_fill_results/m1max-64gb-ollama0340-fill0/<slug>/context_fill_probe.json
```

`--fill-tokens 0` sends an empty user message where the filler would be,
still followed by the `Understood.` assistant turn, so the message structure
matches the filled run.

| Model                      | Empty: tokens | Empty: pass | Filled: tokens | Filled: pass |
| -------------------------- | ------------- | ----------- | -------------- | ------------ |
| `qwen3.8:27b-nvfp4`        | 3972–3987     | 21/25       | 42542–42557    | 17/25        |
| `qwen3.6:27b-coding-nvfp4` | 3968–3983     | 23/25       | 42538–42553    | 21/25        |

The filled runs lose four and two cases. By verdict, `qwen3.8:27b-nvfp4` goes
from 2 `prose`, 1 `wrong-shape` and 1 `unwanted-card` to 4 `prose` and 4
`broken`; `qwen3.6:27b-coding-nvfp4` goes from 2 `broken` to 4. At
`--samples 1` a two-case difference is within noise, and a four-case one is
below the five-case threshold the notebook's context-fill section reads.
