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
the weights behind each tag are byte-identical on both hosts.

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
