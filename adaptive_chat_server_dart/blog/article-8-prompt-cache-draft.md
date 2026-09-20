# Ollama's prompt cache reused a shared system prompt on one model and not on the other

In
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
a demonstration Dart chat server asks a local Ollama model for an answer as
Adaptive Card JSON. A Flutter app renders the reply. The request is expensive
before the model writes anything. The system prompt that describes the card
elements runs to a few thousand tokens, and the chat server replays the whole
conversation on every turn.

Ollama keeps a prefix cache, so a request that starts the same way as an
earlier one does not have to process those tokens again. How much does that
cache save a chat server, and when does it miss? Ollama 0.33.3 reports the
figure needed to measure it. Every reading below comes from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md),
the lab notebook in that repository.

## Terms used in this article

The article uses these words with a specific meaning. Field names are Ollama's
own.

| Term                           | What it means here                                                                                                                                  |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Prefill**                    | The pass in which the model processes the prompt, before it produces the first output token. Ollama reports its duration as `prompt_eval_duration`. |
| **Prefix cache**               | Prompt tokens the Ollama runner has already processed and kept. A new request reuses them as far as its opening tokens match.                       |
| **`prompt_eval_count`**        | The number of prompt tokens Ollama reports for a request.                                                                                           |
| **`prompt_eval_cached_count`** | How many of those tokens came from the prefix cache. Ollama 0.33.3 reports it on every reply.                                                       |
| **Cold prefill**               | A prefill with nothing useful in the cache. A **warm repeat** is the same request sent again.                                                       |
| **`num_ctx`**                  | The context window the request asks for, in tokens. Every run here asks for 8,192.                                                                  |

## The probe sends five request patterns a chat server produces

[`prefill_cache_probe.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/prefill_cache_probe.dart)
builds its own system prompt, a synthetic glossary of 300 entries. It sends
that prompt to one model in five patterns and records both token counts and
the prefill time for each call. Every run is at temperature 0 with one model
resident. The patterns are the ones a chat server sends:

- the same request twice;
- the same system prompt with a different first question, which is what a new
  conversation looks like;
- a conversation that grows by one turn at a time, with the history replayed;
- an unrelated request between two identical ones, as when two users share a
  server;
- a retry after the client aborts a call 400 ms in, waits 5 s, and sends it
  again.

The glossary is sized to fit the window on purpose. A first version of the
probe sent a prompt larger than `num_ctx`. Ollama cut it short without an
error, and every cache figure read near zero. The
[measurement-hygiene article](https://joe.blog.freemansoft.com/2026/09/eight-measurement-rules-from-local.html)
in this series covers that mistake. The check is that `prompt_eval_count`
matches the size of the prompt that was sent.

## On `llama3.2:latest` every pattern but the unrelated request reused the cache

The readings below show how much of each request the prefix cache served, and
the prefill time that was left. They are from an Apple M5 / 16 GB under Ollama
0.33.3. Compare each cached count with its prompt count, and each prefill with
the cold 2017 ms in the first row.

| Pattern, M5, `llama3.2:latest`                          | prompt tokens | cached      | prefill         |
| ------------------------------------------------------- | ------------- | ----------- | --------------- |
| identical request repeated                              | 2143          | 2142        | 2017 ms → 18 ms |
| same system prompt, different question                  | 2144          | 2136        | 60 ms           |
| growing conversation, turns 2–3                         | 2166 / 2188   | 2150 / 2173 | ~94 ms per turn |
| identical request after an interleaved different prompt | 2143          | 2136        | 55 ms           |
| retry after aborting mid-prefill (400 ms in, 5 s wait)  | 2444          | 2443        | 29 ms           |

The run is from 2026-09-03. It is a spot measurement transcribed from terminal
output, taken before the probe could archive a run.

A conversation turn pays prefill for its new tokens only. Turns 2 and 3
re-evaluated about 15 tokens each, so history size does not set the per-turn
cost. A new conversation re-evaluated about 8 tokens. On this model the cost
of a large system prompt is paid once per loaded model, not once per
conversation.

The retry used a system prompt no earlier call had sent, so only the aborted
call could have filled the cache. It cost 29 ms against about 2,000 ms cold.
The probe cannot tell whether the runner kept the partial work or the
abandoned request finished server-side during the 5 s wait. The price of the
retry is the same either way.

## On a second host, `qwen3.8:27b-nvfp4` missed the cache on a new conversation

The next readings test whether those savings hold on another machine and on a
much larger model. Both models ran on an Apple M1 Max / 64 GB under the same
Ollama 0.33.3. The first table is `llama3.2:latest` again, so it changes only
the host. The second is `qwen3.8:27b-nvfp4`, a build Ollama reports as `nvfp4`
quantization. At about 18 GB it is too large for the M5. Where a cell holds
three figures, they are three runs of the full probe.

| Pattern, M1 Max, `llama3.2:latest`                     | prompt / cached          | prefill         |
| ------------------------------------------------------ | ------------------------ | --------------- |
| identical request repeated                             | 2143 / 2142              | 2079 ms → 12 ms |
| same system prompt, different question                 | 2144 / 2136              | 87 ms           |
| growing conversation, turns 2–3                        | 2166 / 2150, 2188 / 2173 | 54 ms, 53 ms    |
| interleaved: the unrelated request itself              | 2444 / 28                | 2170 ms         |
| interleaved: the original request repeated after it    | 2143 / 2136              | 39 ms           |
| retry after aborting mid-prefill (400 ms in, 5 s wait) | 2444 / 2443              | 30 ms           |

The larger model on the same host follows. Its new-conversation row and its
retry row are where it departs from the smaller model.

| Pattern, M1 Max, `qwen3.8:27b-nvfp4`                   | prompt / cached                       | prefill                      |
| ------------------------------------------------------ | ------------------------------------- | ---------------------------- |
| identical request repeated                             | 3176 / 3171                           | 37779 ms → 133 ms, 158 ms    |
| same system prompt, different question                 | 3177 / 4, 3177 / 4, 3177 / 4          | 40426 ms, 40377 ms, 37615 ms |
| growing conversation, turns 2–3                        | 3207 / 3172, 3237 / 3202              | 812 ms, 804 ms               |
| interleaved: the unrelated request itself              | 3176 / 4, 3176 / 4, 3176 / 4          | 40381 ms, 40604 ms, 37815 ms |
| interleaved: the original request repeated after it    | 3176 / 3171, 3176 / 3171, 3176 / 3171 | 215 ms, 205 ms, 198 ms       |
| retry after aborting mid-prefill (400 ms in, 5 s wait) | 3477 / 3472, 3477 / 2063, 3477 / 3472 | 148 ms, 18154 ms, 142 ms     |

All the M1 Max runs are from 2026-09-04 and 2026-09-05. The
`qwen3.8:27b-nvfp4` probe was repeated on an idle machine after its first
misses, to rule out a one-off contention artifact. The same glossary is 3,176
tokens to this model's tokenizer and 2,143 to `llama3.2:latest`'s.

`llama3.2:latest` reproduced the M5 pattern on every row. Three readings also
hold for the larger model. An identical repeat drops from about 38 seconds to
under 200 ms. A growing conversation pays about 800 ms per turn, far below its
own cold prefill. The original request stays cached after an unrelated one.

The unrelated request itself is a near-total miss on both models, 28 cached
tokens on `llama3.2:latest` and 4 on `qwen3.8:27b-nvfp4`. That is expected.
Its glossary shares only a short instruction prefix with the cached one, so
there is little to reuse.

The new-conversation row is the miss that is not expected. The system prompt
is byte-identical and only the short question differs. `llama3.2:latest`
reused 2,136 of 2,144 tokens. `qwen3.8:27b-nvfp4` reused 4 of 3,177 on three
independent runs and paid a full cold prefill each time, about 40 seconds. An
unarchived fourth run read the same.

The retry is unstable on the larger model. Two counted runs read 148 ms and
142 ms with nearly the whole prompt cached. One read 18,154 ms with 2,063 of
3,477 tokens cached. Three readings are not a rate. A plausible reason is that
the amount of prefill finished before the abort lands varies from run to run.
The probe does not observe server-side progress, so that is not confirmed.

## For a chat server, the cost of a new conversation depends on the model

On `llama3.2:latest` a new conversation costs 60 to 87 ms of prefill once the
system prompt is cached. On `qwen3.8:27b-nvfp4` it costs about 40 seconds, the
same as the first request after a model load. A server that starts many short
conversations on that model pays the full system prompt every time. Within one
conversation, both models reuse the cache on every turn.

The cause of the miss is not established. The probe reports
`prompt_eval_cached_count`, not the runner's matching rule. A model-specific
or quantization-specific rule, an effect of prompt length past about 3,000
tokens, and a limit on cached sequences are each consistent with it. None is
confirmed.

These readings cover one model on two hosts and a second model on one host,
all under one Ollama version. How many sequences the runner keeps, and what it
evicts under memory pressure, were not probed. The notebook's
[prompt-cache section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#prompt-cache-reuse-and-retry-cost-measured-with-prompt_eval_cached_count)
has every run.

The repository is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook every figure above comes from is at
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md).
