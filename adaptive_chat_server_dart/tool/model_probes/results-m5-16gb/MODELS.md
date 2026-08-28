# Models measured on Apple M5 / 16 GB

Ollama 0.33.1, macOS 26.6.2, `Mac17,3` (MacBook Air, fanless), 16 GiB unified
memory. Pulled 2026-08-28.

These are the eight models the [roster](../../../ModelBehavior.md#candidate-models)
marks 16 GB-capable. `gpt-oss:20b` is excluded despite being the exception that
column exists to flag: 12.8 GB of weights plus KV cache sits above the default
Metal budget on a 16 GiB unified-memory host, so it is not a model this box can
measure honestly.

Digests are recorded because a tag can be re-published. A latency difference
against the Apple M1 Max / 64 GB figures means something different if the
weights also changed; every size below is within 0.3 GiB of what
`ModelBehavior.md` records, so none of these tags appears to have moved.

```
granite4.1:3b              6fd349357287  Q4_K_M   2.0 GiB  3.4B
granite4.1:8b              444af1c4b2fe  Q4_K_M   5.0 GiB  8.8B
llama3-chatqa:8b           b37a98d204b2  Q4_0     4.3 GiB  8B
llama3-groq-tool-use:8b    36211dad2b15  Q4_0     4.3 GiB  8.0B
llama3.2:latest            a80c4f17acd5  Q4_K_M   1.9 GiB  3.2B
nemotron-3-nano:4b         6cc467f05439  Q4_K_M   2.6 GiB  4.0B
qwen2.5-coder:7b           dae161e27b0e  Q4_K_M   4.4 GiB  7.6B
qwen3.5:9b                 6488c96fa5fa  Q4_K_M   6.1 GiB  9.7B
```

Two of the eight ship at `Q4_0` rather than `Q4_K_M` -- `llama3-chatqa:8b` and
`llama3-groq-tool-use:8b`. That is how those tags are published, not a pull that
went wrong, but it sits underneath any latency comparison between them and the
other six.

The Apple M1 Max / 64 GB runs in [`../results/`](../results/) do not record the
Ollama version they were taken against, so a ratio between the two hosts spans
an unknown runtime change as well as a hardware one.
