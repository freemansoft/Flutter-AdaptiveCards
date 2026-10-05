# Models measured on Apple M5 / 16 GB

Ollama 0.35.1, macOS 26.6.2, `Mac17,3` (MacBook Air, fanless), 16 GiB unified
memory. Digests re-checked on 2026-10-03 against this host's own
`results-m5-16gb-ollama0331/MODELS.md` (pulled 2026-08-28); all eight match.

These are the eight models the [roster](../../../ModelBehavior.md#candidate-models)
marks 16 GB-capable. `gpt-oss:20b` is excluded despite being the exception that
column exists to flag: 12.8 GB of weights plus KV cache sits above the default
Metal budget on a 16 GiB unified-memory host, so it is not a model this box can
measure honestly.

Digests are recorded because a tag can be re-published. A latency difference
against the Apple M1 Max / 64 GB figures means something different if the
weights also changed; every digest below matches
`results-m1max-64gb-ollama0351/MODELS.md`, so the weights behind each tag are
byte-identical on both hosts.

```
granite4.1:3b            6fd349357287  Q4_K_M   2.1 GB  3.4B
granite4.1:8b            444af1c4b2fe  Q4_K_M   5.3 GB  8.8B
llama3-chatqa:8b         b37a98d204b2  Q4_0     4.7 GB  8B
llama3-groq-tool-use:8b  36211dad2b15  Q4_0     4.7 GB  8.0B
llama3.2:latest          a80c4f17acd5  Q4_K_M   2.0 GB  3.2B
nemotron-3-nano:4b       6cc467f05439  Q4_K_M   2.8 GB  4.0B
qwen2.5-coder:7b         dae161e27b0e  Q4_K_M   4.7 GB  7.6B
qwen3.5:9b               6488c96fa5fa  Q4_K_M   6.6 GB  9.7B
```

`ollama list` here reports decimal GB; `results-m1max-64gb-ollama0351/MODELS.md`
records the same digests in GiB, which is a display difference, not a
different file.

Two of the eight ship at `Q4_0` rather than `Q4_K_M` -- `llama3-chatqa:8b` and
`llama3-groq-tool-use:8b`. That is how those tags are published, not a pull
that went wrong, but it sits underneath any latency comparison between them
and the other six.

The prompt is `assets/card_system_prompt.txt`, at digest `8cbfde243266`
(first 12 hex of its SHA-256; the run files record it).
