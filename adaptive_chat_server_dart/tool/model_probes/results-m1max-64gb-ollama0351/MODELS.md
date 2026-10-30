# Models measured on Apple M1 Max / 64 GB

Ollama 0.35.1, macOS 26.6.2, `MacBookPro18,4`, 64 GiB unified memory. The
eight tags were pulled at different times — `ollama list`'s age column shows
a range from 7 weeks to 10 months before this sweep — and their digests were
re-checked against `results-m5-16gb-ollama0331/MODELS.md` on 2026-10-03,
rather than re-pulled.

These are the eight models the [roster](../../../ModelBehavior.md#candidate-models)
marks 16 GB-capable.

Digests are recorded because a tag can be re-published. A latency difference
against the Apple M5 / 16 GB figures means something different if the
weights also changed; every digest below matches the digests
`results-m5-16gb-ollama0331/MODELS.md` recorded from its 2026-08-28 pull, so
the weights behind each tag were byte-identical on both hosts as of the
M5's 2026-08-28 pull; the M5 sweep re-checks at sweep time, so a later M5
run is the record to trust for its current state.

```
granite4.1:3b            6fd349357287  Q4_K_M   2.0 GiB  3.4B
granite4.1:8b            444af1c4b2fe  Q4_K_M   5.0 GiB  8.8B
llama3-chatqa:8b         b37a98d204b2  Q4_0     4.3 GiB  8B
llama3-groq-tool-use:8b  36211dad2b15  Q4_0     4.3 GiB  8.0B
llama3.2:latest          a80c4f17acd5  Q4_K_M   1.9 GiB  3.2B
nemotron-3-nano:4b       6cc467f05439  Q4_K_M   2.6 GiB  4.0B
qwen2.5-coder:7b         dae161e27b0e  Q4_K_M   4.4 GiB  7.6B
qwen3.5:9b               6488c96fa5fa  Q4_K_M   6.1 GiB  9.7B
```

The GiB figures above are the ones `results-m5-16gb-ollama0331/MODELS.md`
already recorded for the same digests, not a re-derivation from this host's
own reading. `ollama list`'s column here reports decimal GB instead — for
example 5.3 GB for `granite4.1:8b` — which is a display difference, not a
different file.

Two of the eight ship at `Q4_0` rather than `Q4_K_M` -- `llama3-chatqa:8b` and
`llama3-groq-tool-use:8b`. That is how those tags are published, not a pull
that went wrong, but it sits underneath any latency comparison between them
and the other six.

The prompt is `assets/card_system_prompt.txt`, at digest `8cbfde243266`
(first 12 hex of its SHA-256; the run files record it).

## Additional models for the 2026-10-27 prompt-cache runs

`prefill_cache_probe.dart` ran the eight models above and nine more, read
from `ollama list` and `ollama show` on 2026-10-27. Each GGUF build's weight
blob in the 0.35.1 server log matches the one in its 0.34.0 log
(`results-m1max-64gb-ollama0340/*/server-log-*.txt`), so the weights did not
change between the two prompt-cache matrices. The four safetensors builds
are served by the MLX runner.

```
qwen3-coder:30b                                    06c1097efce0  qwen3moe        Q4_K_M    30.5B
gpt-oss:20b                                        17052f91a42e  gptoss          MXFP4     20.9B
nemotron-3-nano:30b                                b725f1117407  nemotron_h_moe  Q4_K_M    31.6B
nemotron-3.5-lightning:30b                         e7a64ff15fb1  nemotron_h_moe  Q4_K_M    32.9B
hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest  a963e5a505e0  nemotron_h_moe  Q4_K_M    31.6B
qwen3.8:27b-nvfp4                                  5642e97495e1  qwen3_5         nvfp4     27.8B
qwen3.6:27b-coding-nvfp4                           42a2d9de99b0  qwen3_5         nvfp4     27.4B
mvincig11/semif-qwen3.5-4b-mlx-4bit                f9b520d56c1e  qwen3_5         int4      4.2B
nemotron-3-nano-mlx:4b-bf16                        e1d6029081fd  nemotron_h      bfloat16  4.0B
```
