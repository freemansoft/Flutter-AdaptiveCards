# Fit control, calibrated, under Ollama 0.34.0

Apple M1 Max / 64 GB, Ollama 0.34.0, `--samples 1`, measured 2026-09-19 with
per-model calibration on.

[`m1max-64gb-ollama0333-fitcontrol-calibrated/`](../m1max-64gb-ollama0333-fitcontrol-calibrated)
showed that every model given a filler that fits its allocated window keeps
it. Two questions were left open, and this directory answers both.

**The 8192-window models had never been given a filler that fits.**
`llama3-chatqa:8b` and `llama3-groq-tool-use:8b` only ever received the
28000-token filler, which no sizing fits into their trained window. Here they
get 2500 tokens under an 8192 request.

**The `nvfp4` builds' cost was not attributed.** Under 0.34.0 they score four
and two cases lower overrunning their allocation
([`m1max-64gb-ollama0340-fill28000/`](../m1max-64gb-ollama0340-fill28000))
than with an empty window
([`m1max-64gb-ollama0340-fill0/`](../m1max-64gb-ollama0340-fill0)). That
comparison cannot separate running past the allocation from a full window.
Here they get a full window that fits: about 48,500 tokens inside a 65536
allocation, the same parameters as the 0.33.3 control.

```sh
cd adaptive_chat_server_dart
FIT_CONTROL_RESULTS=tool/model_probes/context_fill_results/m1max-64gb-ollama0340-fitcontrol-calibrated \
  tool/model_probes/context_fill_fit_control.sh llama3-chatqa:8b \
  llama3-groq-tool-use:8b qwen3.8:27b-nvfp4 qwen3.6:27b-coding-nvfp4
```

| Model                      | `--fill-tokens` | `--num-ctx` | Allocated | chars/token | Prompt tokens | Pass  |
| -------------------------- | --------------- | ----------- | --------- | ----------- | ------------- | ----- |
| `llama3-chatqa:8b`         | 2500            | 8192        | 8192      | 4.60        | 6300–6313     | 2/25  |
| `llama3-groq-tool-use:8b`  | 2500            | 8192        | 8192      | 4.59        | 6303–6318     | 6/25  |
| `qwen3.8:27b-nvfp4`        | 42000           | 65536       | 65536     | 3.07        | 48539–48554   | 16/25 |
| `qwen3.6:27b-coding-nvfp4` | 42000           | 65536       | 65536     | 3.07        | 48535–48550   | 20/25 |

Both 8192-window models keep the filler: 6300 and 6303 prompt tokens against
3819 and 3825 when the 28000-token filler was dropped. Their pass counts say
little about context, since both answer most cases in prose with or without
history.

Both `nvfp4` builds reproduce the 0.33.3 control to the token and to the
verdict: 16 and 20 passes, with 7 and 5 `broken`. Set beside the other two
0.34.0 conditions:

| Model                      | Empty window | Overrun, 42,540 in 35851 | Full, 48,540 in 65536 |
| -------------------------- | ------------ | ------------------------ | --------------------- |
| `qwen3.8:27b-nvfp4`        | 21/25        | 17/25                    | 16/25                 |
| `qwen3.6:27b-coding-nvfp4` | 23/25        | 21/25                    | 20/25                 |

The overrun scores within one case of a full window that fits, so whatever
the lower score is, it goes with a full window rather than with running past
the allocation. Against the empty window the filled runs are four and five cases lower for `qwen3.8:27b-nvfp4` and two and three for `qwen3.6:27b-coding-nvfp4`. At `--samples 1` only the five-case drop reaches the size the notebook reads, on one run.

## 2026-09-24: the remaining six models of the 0.33.3 control

The four runs above left six of the 0.33.3 control's eight models without a
0.34.0 reading, which is what kept the full-window section's figures framed as
a 0.33.3 result. These six close that, at the same `--fill-tokens` and
`--num-ctx` each used in the 0.33.3 control, `--samples 1`, calibration on, one
model resident at a time.

```sh
cd adaptive_chat_server_dart
FIT_CONTROL_RESULTS=tool/model_probes/context_fill_results/m1max-64gb-ollama0340-fitcontrol-calibrated \
  tool/model_probes/context_fill_fit_control.sh nemotron-3-nano:30b \
  nemotron-3.5-lightning:30b nemotron-3-nano:4b qwen2.5-coder:7b \
  qwen3-coder:30b qwen3.5:9b
```

| Model                        | `--fill-tokens` | `--num-ctx` | chars/token | Prompt tokens | Pass (0.34.0) | Pass (0.33.3) |
| ---------------------------- | --------------- | ----------- | ----------- | ------------- | ------------- | ------------- |
| `nemotron-3-nano:30b`        | 42000           | 65536       | 3.07        | 48611–48626   | 12/25         | 12/25         |
| `nemotron-3.5-lightning:30b` | 42000           | 65536       | 3.07        | 48600–48615   | 13/25         | 13/25         |
| `nemotron-3-nano:4b`         | 42000           | 65536       | 2.81        | 48559–48575   | 6/25          | 6/25          |
| `qwen2.5-coder:7b`           | 20000           | 32768       | 3.08        | 24721–24736   | 19/25         | 19/25         |
| `qwen3-coder:30b`            | 42000           | 65536       | 3.08        | 48459–48474   | 20/25         | 20/25         |
| `qwen3.5:9b`                 | 42000           | 65536       | 3.07        | 48537–48552   | 16/25         | 16/25         |

Every model reproduces its 0.33.3 pass count, and every `promptEvalCountMin`
matches that run to the token. With the two `nvfp4` builds above, all eight
models of the 0.33.3 control now have a 0.34.0 reading, and the three large
losses the notebook reads from this condition are the same on both runtimes.
