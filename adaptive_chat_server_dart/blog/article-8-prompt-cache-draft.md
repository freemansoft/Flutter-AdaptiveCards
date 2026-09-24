# On Ollama, a model's memory type decides whether a new conversation reuses the cached prompt

In
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
a demonstration Dart chat server asks a local Ollama model for an answer as
Adaptive Card JSON. That is a strict, closed-vocabulary schema, which a Flutter
app renders as interactive UI. The card system prompt that describes the
element vocabulary is estimated at 3,755 tokens. The chat server replays up to
ten prior exchanges on every turn.

Ollama keeps a prefix cache, so a request whose opening tokens match an earlier
one does not have to process them again. Ollama 0.33.3 and later count the
prompt tokens each reply served from that cache, in
`prompt_eval_cached_count`, so a chat server can read what the cache saved it
and when it missed. Every reading below comes from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md),
the lab notebook in that repository.

**A new conversation reuses a cached system prompt on some models and not on
others.** The split follows how the model stores its context. A probe
measured fifteen local models on an Apple M1 Max under Ollama 0.34.0:

- Eight keep an attention entry per token. They reused the cached prompt on
  all but one of 120 new conversations.
- Five are recurrent builds on Ollama's `llama-server` runner. Four
  re-processed the last 1,024 or 1,025 tokens on every new conversation, and
  the unsloth Nemotron build did so on a third of them.
- Two are on Ollama's MLX runner, recurrent by that runner's model code. They re-processed the whole prompt on the first new conversation per system
  prompt, and almost none of it afterward.

The diagram sorts a request by what it shares with the runner's last call:

```mermaid
flowchart TD
  A[New /api/chat request] --> B{Identical to the<br/>runner's last call?}
  B -- yes --> C[Warm on all fifteen models]
  B -- no --> D{Does it extend the runner's last call<br/>with one new exchange?}
  D -- yes, a growing conversation --> E[Warm on all fifteen,<br/>pays only the new tokens]
  D -- no --> F{Same system prompt as<br/>an earlier cached request?}
  F -- no, a different prompt --> G[Cold on all fifteen]
  F -- yes: a new conversation, or a<br/>repeat after an interruption --> H{Model's memory type?}
  H -- attention-only or sliding window --> I[Warm on 119 of 120 new conversations.<br/>gpt-oss also rolls back after an interruption]
  H -- recurrent --> R{Which runner?}
  R -- llama-server --> S[Re-processes the tokens after the last<br/>checkpoint, about 1,025 on four of five builds]
  R -- MLX --> K{First new conversation<br/>on this system prompt?}
  K -- yes --> J[Cold: a second cold prefill]
  K -- no --> L[Warm]
```

## Terms used in this article

| Term                       | What it means here                                                                                                                                                                                                                     |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Runner**                 | The process Ollama starts to serve one loaded model: `llama-server` for the thirteen GGUF builds here, the MLX runner for the two safetensors builds. Ollama's server log names the one it starts, and the prefix cache belongs to it. |
| **Prefill**                | The pass in which the model processes the prompt, before it produces the first output token. Ollama reports its duration as `prompt_eval_duration`.                                                                                    |
| **Cold** and **warm**      | A cold request has almost none of its prompt served from the prefix cache, and pays a cold prefill. A warm request has nearly all of it.                                                                                               |
| **New conversation**       | A request carrying a system prompt the runner has already processed, followed by a question it has not seen. It is how a chat server opens a second conversation on the same system prompt.                                            |
| **Synthetic prompt**       | A system prompt the probe builds in place of the card one, as a glossary of numbered entries. The shared one carries most requests; the others differ from it by a tag word.                                                           |
| **Memory type**            | How a model's layers hold the context they have read: an attention entry per token, or a recurrent running state. `llama-server` prints which at load. Not the host's RAM.                                                             |
| **Attention-only memory**  | Layers that keep an entry per token, so a runner can reuse any leading run of a cached prompt. Eight models here, one of which, `gpt-oss:20b`, adds a sliding window.                                                                  |
| **Recurrent memory**       | Layers that carry a running state from token to token instead of keeping an entry per token. The state cannot be rewound to an arbitrary token. `llama-server` prints `llama_memory_recurrent` when it loads such a model.             |
| **Context checkpoint**     | A saved copy of that state at one token position. A runner can resume a recurrent model only from a checkpoint. `llama-server` logs each one it creates and restores; the MLX runner calls the same thing a snapshot.                  |
| **Batch**                  | The unit `llama-server` prefills a prompt in. Ollama starts it with `-b 1024 -ub 1024`, a 1,024-token batch and micro-batch, and the runner echoes `n_batch = 1024`.                                                                   |
| **Sliding window**         | Attention layers that see only the last few tokens, 128 in `gpt-oss:20b`. `llama-server` handles them with the same checkpoints.                                                                                                       |
| **First-divergence phase** | Three new conversations on each of two synthetic prompts no earlier call sent. Arm `delta` goes straight there from the first request; arm `echo` sends the same request twice first.                                                  |
| **Interleaved phase**      | Two three-turn conversations alternating on one system prompt, as when a chat server serves two users.                                                                                                                                 |
| **Second branch**          | Two divergences from one system prompt, then a return to the first.                                                                                                                                                                    |

## The probe sends the request shapes a chat server produces, in nine phases

[`prefill_cache_probe.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/prefill_cache_probe.dart)
builds its own system prompts rather than sending the card one. Each is a
synthetic system prompt built as a glossary of 300 entries. An entry is one
clause, such as `alpha-term0 means concept0.`, pairing a numbered term with a
numbered concept, and each question, such as `Define alpha-term20.`, asks for
one entry. The synthetic prompts differ only in the tag word, `alpha` here,
that prefixes every entry:

```txt
You are a helpful assistant. Answer briefly. Reference glossary: alpha-term0
means concept0. alpha-term1 means concept7. alpha-term2 means concept14. ...
```

The `alpha` prompt is the shared synthetic prompt below. The probe sends them
to one model at a time, at temperature 0, recording each call's token counts,
prefill time and total time. A warmup call loads the model first, so a cold
prefill below is the cost of the prompt, not of the model load. The diagram
gives the nine phases in call order:

```mermaid
sequenceDiagram
  participant P as prefill_cache_probe
  participant O as Ollama runner, one model resident

  Note over P,O: the shared synthetic prompt, a second and a third are three<br/>300-entry prompts differing only by a tag word on every entry
  Note over P,O: every call returns prompt tokens, cached tokens, prefill time and total time

  P->>O: warmup, a short prompt that loads the model

  Note over P,O: 1. the same request twice
  P->>O: shared prompt, one question
  P->>O: the same request again

  Note over P,O: 2. the first new conversation
  P->>O: shared prompt, a different question

  Note over P,O: 3. a growing conversation, three calls
  P->>O: shared prompt, a third question<br/>(a second new conversation)
  P->>O: the whole history again, plus a second question
  P->>O: the whole history again, plus a third question

  Note over P,O: 4. an unrelated request between two identical ones,<br/>as when a server switches between two system prompts
  P->>O: a second synthetic prompt, sharing only the instruction prefix
  P->>O: shared prompt, the original request repeated

  Note over P,O: 5. a retry after an abort
  P-xO: a third synthetic prompt no earlier call sent,<br/>aborted by the probe 400 ms in
  Note over P: waits 5 s
  P->>O: the same request again

  Note over P,O: 6-9. four follow-up phases: seven new conversations, each after a different<br/>kind of call, then the first-divergence phase, the interleaved phase and a second branch
  P->>O: unload, which ends the run
```

The 300-entry shared prompt comes to 2,127 to 3,479 tokens depending on the
tokenizer, against the card system prompt's estimated 3,755. Four models then ran the
whole probe on that 15 KB card prompt: `llama3.2:latest`, `qwen3.5:9b`,
`nemotron-3-nano:4b` and `qwen3.8:27b-nvfp4`. Every figure held.
`llama3.2:latest` re-evaluated 7 to 8 tokens, the two recurrent `llama-server`
builds 1,025, and `qwen3.8:27b-nvfp4` paid one cold first new conversation per
prompt. The probe sizes each synthetic prompt to fit the 8,192-token context window
every run asks for. An earlier version overflowed it and every cache figure
read near zero, the mistake the [measurement-hygiene
article](https://joe.blog.freemansoft.com/2026/09/eight-measurement-rules-from-local.html)
covers.

All fifteen models ran the nine phases on 2026-09-23 and 2026-09-24, one
client, one request at a time. `llama3.2:latest`, `qwen3.5:9b`,
`nemotron-3-nano:4b` and `qwen3.8:27b-nvfp4` ran them twice, and `qwen3.5:9b`
at four more prompt lengths. Every token count in all nine phases repeated
between the two runs, except the retry's on `qwen3.8:27b-nvfp4`.

## Repeating the runner's last call reuses the cache on all fifteen models

An immediate exact repeat left 1 to 5 tokens uncached. Each turn that extends
the conversation re-evaluated only its new exchange, 10 to 40 tokens. The
length of the history does not set the per-turn cost.

## Eight models stay warm on a new conversation and seven do not, by memory type

Every row is one model's nine-phase run on the M1 Max under Ollama 0.34.0, and
each cell gives cached tokens, then the prefill time. Prompts ran 2,127 to
3,479 tokens, and a new conversation shares all but 5 to 17 of them with the
cached prompt. The probe opens fifteen new conversations per model over three
synthetic prompts. Three are the first divergence from their prompt, and
twelve follow one.

| Model                                  | Memory         | Runner         | Cold prefill, first request | First new conversation, 3 calls                | Later new conversations, 12                       |
| -------------------------------------- | -------------- | -------------- | --------------------------- | ---------------------------------------------- | ------------------------------------------------- |
| `llama3.2:latest`                      | attention      | `llama-server` | 1.9–3.1 s                   | 2,136, 42–46 ms                                | 2,136, 39–71 ms                                   |
| `qwen3-coder:30b`                      | attention      | `llama-server` | 4.1–5.9 s                   | 3,167, 76–103 ms                               | 3,167–3,168, 78–120 ms                            |
| `qwen2.5-coder:7b`                     | attention      | `llama-server` | 8.6–10.0 s                  | 3,167, 106–137 ms                              | 3,167–3,168, 99–142 ms                            |
| `llama3-chatqa:8b`                     | attention      | `llama-server` | 4.7–6.2 s                   | 2,121, 103–139 ms                              | 2,121, 76–106 ms                                  |
| `llama3-groq-tool-use:8b`              | attention      | `llama-server` | 4.7–6.1 s                   | 2,126, 120–136 ms                              | 2,126, 113–137 ms                                 |
| `granite4.1:3b`                        | attention      | `llama-server` | 2.2–3.3 s                   | 2,124, 49–58 ms                                | 2,124, 46–85 ms                                   |
| `granite4.1:8b`                        | attention      | `llama-server` | 7.1–8.4 s                   | 2,124, 137–180 ms                              | 2,124, 130–185 ms                                 |
| `gpt-oss:20b`                          | sliding window | `llama-server` | 2.4–3.4 s                   | 2,182, 67–86 ms                                | 2,182 on 11 (59–89 ms); 1,162 once (1.68 s)       |
| `qwen3.5:9b`                           | recurrent      | `llama-server` | 8.9–10.7 s                  | 2,154, 3.69–3.98 s                             | 2,154–2,155, 3.41–4.20 s                          |
| `nemotron-3-nano:4b`                   | recurrent      | `llama-server` | 5.8–6.4 s                   | 2,454, 1.95–1.99 s                             | 2,454–2,455, 1.94–2.12 s                          |
| `nemotron-3-nano:30b`                  | recurrent      | `llama-server` | 4.1–5.1 s                   | 2,153, 1.34–1.73 s                             | 2,153–2,154, 1.50–1.70 s                          |
| `nemotron-3.5-lightning:30b`           | recurrent      | `llama-server` | 4.2–5.4 s                   | 2,153, 1.39–1.79 s                             | 2,153–2,154, 1.72–1.80 s                          |
| `unsloth/Nemotron-3-Nano-30B-A3B-GGUF` | recurrent      | `llama-server` | 4.1–5.4 s                   | 3,162 once (157 ms); 2,154 twice (1.41–1.75 s) | 3,162 on 9 (154–183 ms); 2,154 on 3 (1.87–1.92 s) |
| `qwen3.8:27b-nvfp4`                    | recurrent      | MLX            | 35.2–36.0 s                 | 4–15, 35.5–37.1 s                              | 3,166–3,167, 376–415 ms                           |
| `qwen3.6:27b-coding-nvfp4`             | recurrent      | MLX            | 33.8–35.3 s                 | 5–16, 34.3–34.7 s                              | 3,167–3,168, 409–432 ms                           |

Source: the notebook's [recurrent-memory section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#recurrent-memory-models-lose-part-of-a-cached-prefix-on-llama-server-too-the-runner-sets-how-much), and the archived runs under
[`results-m1max-64gb-ollama0340/`](https://github.com/freemansoft/Flutter-AdaptiveCards/tree/main/adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama0340).

All seven attention-only models were warm on every new conversation.
`gpt-oss:20b` was warm on 14 of 15; once, after an exact repeat, `llama-server`
rolled it back to a checkpoint at 1,162 tokens. It restored the same
checkpoint after the unrelated request and once in the interleaved phase;
nothing here explains why.

Four of the recurrent builds reused 2,153 to 2,455 tokens on every new
conversation, the first included, and re-processed the last 1,024 or 1,025. On
these 3,177 to 3,479-token prompts that cost 1.34 to 4.20 s against 4.1 to 10.7
s cold, about a third. The fifth, the unsloth build, did so on a third of them;
a third checkpoint explains that below. The two `nvfp4` builds on Ollama's MLX
runner paid a cold prefill for the first new conversation on each synthetic
prompt. Later ones cost 376 to 432 ms.

## An unrelated request between two identical ones does not move the split

The probe sent an unrelated synthetic prompt between two identical requests. The repeat
came back warm on the seven attention-only builds and on the two MLX builds,
which reused 3,173 and 3,174 of 3,178 tokens. The five recurrent builds on
`llama-server` paid their new-conversation price again, `qwen3.5:9b` reusing
2,154 of 3,178, and `gpt-oss:20b` fell back to its 1,162-token checkpoint. The
unrelated prompt itself reused at most 28 tokens.

## `llama-server` resumes a recurrent model from a checkpoint one batch back

Processing the shared synthetic prompt on `qwen3.5:9b`, 3,178 tokens,
`llama-server` saved two checkpoints. One sits at 2,154 tokens, one batch
before the end, and one 4 tokens from the end. A new conversation shares 3,167
tokens with that prompt and diverges before the later checkpoint. Ollama's
server log shows `llama-server` trying it and falling back:

```
checking checkpoint with [3173, 3173] against 3167...
checking checkpoint with [2153, 2153] against 3167...
restored context checkpoint (pos_min = 2153, ..., n_tokens = 2154, ...)
```

The new conversation's 3,179-token request therefore re-processes 1,025 tokens.
An exact repeat or a growing-conversation turn restores the checkpoint at the
end of the previous call and stays warm. The attention-only builds log no
checkpoints at all. A request with nothing to restore, a first request or one
on an unrelated synthetic prompt, gets a different line:

```
forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory …)
```

The rollback is one batch, not a share of the prompt. `--entries` moved
`qwen3.5:9b`'s prompt from 1,008 to 4,812 tokens, and from 1,549 tokens up the
re-processed count stayed at 1,025. `nemotron-3-nano:4b` matches at 1,700 and
3,479 tokens. The card system prompt rolled back the same 1,025, which a
positional checkpoint predicts and a content-sensitive one does not. A
1,008-token prompt is shorter than one batch and holds no checkpoint before
the divergence. The model re-processes all of it, 3.57 s against the 2.23 s
its own cold prefill cost.

The unsloth Nemotron build saves a third checkpoint 16 tokens from the end.
An exact repeat or a growing-conversation turn drops it; after any other call
the build restores from there. Why `llama-server` places one there for this
build is not in its output.

## Ollama's MLX runner pays one extra cold prefill per system prompt

The MLX runner logs a `prefix_cache` line for each request. In it, `matched`
counts the leading tokens that agree with a cached request, and `cached` counts
the tokens the runner reused. On `qwen3.8:27b-nvfp4` the first new conversation
logs `total=3179 matched=3166 cached=4`: the runner found the shared prefix
and restored almost none of it. Later new conversations log `matched=3166
cached=3166`, and `qwen3.6:27b-coding-nvfp4` logs the same shape at 3167.

The runner's source says why. Its prefix cache, in
[`prefix_cache.go`](https://github.com/ollama/ollama/blob/v0.34.0/x/mlxrunner/prefix_cache.go)
at v0.34.0, is a trie of token runs. Attention layers keep an entry per token
and can be restored to any position. Recurrent layers keep a snapshot only at
the end of a trie node. A request that diverges inside a node has nothing to
restore, so the runner prefills from the start. During that prefill it
schedules a snapshot at the branch point, "so future requests diverging here
can restore instead of re-evaluating". The recurrence is in the runner's
[Qwen3.5 model
code](https://github.com/ollama/ollama/blob/v0.34.0/x/models/qwen3_5/qwen3_5.go)
as well: gated-delta recurrent layers interleaved with full-attention layers.
`ollama show` reports both `nvfp4` builds as that architecture.

The first-divergence phase compares the two runners side by side. Each cell
reads prompt / cached, prefill time in parentheses:

| Model               | Arm   | first request      | exact repeat | new conv 1          | new conv 2  | new conv 3  |
| ------------------- | ----- | ------------------ | ------------ | ------------------- | ----------- | ----------- |
| `llama3.2:latest`   | delta | 2143 / 28 (2.9 s)  |              | 2143 / 2136 (45 ms) | 2143 / 2136 | 2143 / 2136 |
| `llama3.2:latest`   | echo  | 2143 / 28 (3.1 s)  | 2143 / 2142  | 2143 / 2136 (46 ms) | 2143 / 2136 | 2143 / 2136 |
| `qwen3.5:9b`        | delta | 3178 / 0 (10.6 s)  |              | 3178 / 2154 (3.9 s) | 3178 / 2154 | 3179 / 2154 |
| `qwen3.5:9b`        | echo  | 3178 / 0 (10.7 s)  | 3178 / 3174  | 3178 / 2154 (4.0 s) | 3178 / 2154 | 3179 / 2154 |
| `qwen3.8:27b-nvfp4` | delta | 3178 / 15 (35.3 s) |              | 3178 / 15 (35.5 s)  | 3178 / 3166 | 3179 / 3166 |
| `qwen3.8:27b-nvfp4` | echo  | 3178 / 15 (35.2 s) | 3178 / 3173  | 3178 / 15 (36.1 s)  | 3178 / 3166 | 3179 / 3166 |

Source: the `first-divergence` phase of the archived nine-phase runs under
[`results-m1max-64gb-ollama0340/`](https://github.com/freemansoft/Flutter-AdaptiveCards/tree/main/adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama0340);
the notebook's earlier
[phase-7 table](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#ollama-0340-the-first-four-models-2026-09-21),
from superseded runs, shows the same shape.

`qwen3.8:27b-nvfp4` pays its cold prefill once per synthetic prompt, with or without an
exact repeat before it, and about 400 ms after. `qwen3.5:9b` falls back one
batch on all six new conversations, and `llama3.2:latest` is warm on all six.

A sixteenth model rules out the quantization.
`mvincig11/semif-qwen3.5-4b-mlx-4bit` is an `int4` safetensors build on the
same MLX runner. It repeats the shape. The exact repeat is warm at 3,174 of
3,178 tokens, the first new conversation cold at 5 of 3,179, and the second
warm at 3,167. The architecture is not ruled out. Two attention-only controls
failed to load: the MLX runner refused a safetensors `gpt-oss`, and `ollama
create` rejected an MLX 4-bit Llama.

## Two conversations on one system prompt pay per turn, on `llama-server`

A chat server with two users runs two conversations against one system prompt.
Each turn replays its own history, so each one diverges from the conversation
the runner served last. Re-evaluated tokens per call at 300 entries in the
interleaved and second-branch phases:

| Model                                 | Runner         | Memory    | Two conversations, six turns | Second branch, four calls |
| ------------------------------------- | -------------- | --------- | ---------------------------- | ------------------------- |
| `llama3.2:latest`                     | `llama-server` | attention | 7 to 58                      | 7 each                    |
| `qwen3-coder:30b`                     | `llama-server` | attention | 8 to 148                     | 8 each                    |
| `gpt-oss:20b`                         | `llama-server` | sliding   | 5 to 25, and one 1,025       | 5 each                    |
| `qwen3.5:9b`                          | `llama-server` | recurrent | 1,019 to 1,080 every turn    | 929 each                  |
| `nemotron-3-nano:4b`                  | `llama-server` | recurrent | 1,021 to 1,058 every turn    | 957 each                  |
| `nemotron-3-nano:30b`                 | `llama-server` | recurrent | 1,024 to 1,056 every turn    | 961 each                  |
| `nemotron-3.5-lightning:30b`          | `llama-server` | recurrent | 1,024 to 1,050 every turn    | 961 each                  |
| unsloth Nemotron GGUF                 | `llama-server` | recurrent | 17 to 80                     | 17 each                   |
| `qwen3.8:27b-nvfp4`                   | MLX            | recurrent | 13 to 22                     | 5 to 13                   |
| `mvincig11/semif-qwen3.5-4b-mlx-4bit` | MLX            | recurrent | 12 to 82                     | 4 to 12                   |

Source: the notebook's [interleaved-conversations
section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#the-rollback-is-one-batch-the-mlx-miss-is-not-the-nvfp4-quantization-and-interleaved-conversations-pay-per-turn).

Four of the five recurrent models on `llama-server` pay a batch on every turn
of the pair. The cost is per turn rather than per conversation. They pay most
of one again on every call of a second branch. The unsloth Nemotron build stays
within 80 tokens on both shapes, from the same checkpoint 16 tokens from the
end. The MLX builds stay warm throughout, and a revisited branch point is their
cheapest call.

## A retry's cost is the remainder of the abandoned call, not its own prefill

The retry sends a synthetic prompt no earlier call had sent, so only the aborted call
could have filled the cache. Nearly every retry reused almost the whole prompt.
The client's abort does not end the call on the server at once:

```mermaid
sequenceDiagram
  participant P as prefill_cache_probe
  participant O as Ollama runner
  participant C as Prefix cache
  P->>O: request on a synthetic prompt no earlier call sent
  P-xO: aborted by the probe at 0.4 s
  Note over O: the abandoned call keeps running
  Note over P: waits 5 s
  P->>O: the same request again
  Note over O: the retry waits for the abandoned call<br/>to finish or be cancelled
  alt the abandoned call ran to completion
    O->>C: holds the whole prompt
  else the MLX runner cancelled it at a chunk boundary, on two runs
    O->>C: holds 2,048 tokens of it
  end
  C-->>O: the retry reuses what is held
  O-->>P: reply, reporting only its own prefill
```

Each row gives a model's retry beside two yardsticks. One is its cold prefill.
The other is an exact repeat's total.

| Model                      | Cold prefill | Warm call, total | Retry: prefill, total                     |
| -------------------------- | ------------ | ---------------- | ----------------------------------------- |
| `llama3.2:latest`          | 1.9–3.1 s    | 0.12 s           | 24 ms, 153 ms                             |
| `granite4.1:3b`            | 2.2–3.3 s    | 0.13 s           | 27 ms, 175 ms                             |
| `gpt-oss:20b`              | 2.4–3.4 s    | 1.27 s           | 22 ms, 1.24 s                             |
| `nemotron-3-nano:30b`      | 4.1–5.1 s    | 0.14 s           | 49 ms, 0.27 s                             |
| `nemotron-3-nano:4b`       | 5.8–6.4 s    | 0.27 s           | 54 ms, 2.20 s                             |
| `granite4.1:8b`            | 7.1–8.4 s    | 0.29 s           | 36 ms, 4.76 s                             |
| `qwen2.5-coder:7b`         | 8.6–10.0 s   | 0.28 s           | 27 ms, 5.72 s                             |
| `qwen3.5:9b`               | 8.9–10.7 s   | 0.76 s           | 76 ms, 8.12 s                             |
| `qwen3.6:27b-coding-nvfp4` | 33.8–35.3 s  | 0.91 s           | 175 ms, 34.4 s                            |
| `qwen3.8:27b-nvfp4`        | 35.2–36.0 s  | 0.80 s           | 152 ms, 35.2 s; 16.3 s, 34.3 s on one run |

Source: the notebook's [retry account](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#recurrent-memory-models-lose-part-of-a-cached-prefix-on-llama-server-too-the-runner-sets-how-much).

A retry with nothing in its way costs what a warm call costs, so the wait is
the retry's total minus the warm call's total. On four of the ten that
difference is under 0.2 s. The probe sends the retry 5.4 s after the abandoned
call started, its 0.4 s abort plus the 5 s pause. Those four models' cold
prefills of 1.9 to 5.1 s had finished by then. The other six wait, from 1.9 s
on `nemotron-3-nano:4b` to 34.4 s on `qwen3.8:27b-nvfp4`, whose own cold
prefill takes 35.2 to 36.0 s. On the tabulated run no retry's own prefill
exceeds 175 ms, so the prefill field reports none of the wait. `gpt-oss:20b`'s
warm call runs to 1.27 s because it spends the reply cap on thinking.

No `llama-server` log records a termination of the abandoned call. On those
models the retry's total runs long by about what the abandoned prefill had left
to do. Two MLX logs record `Request terminated error="context canceled"` part
way through it. The retry that followed reported 2,063 and 2,064 cached tokens:
the 2,048-token chunk the MLX runner prefills in, plus the tokens the request
already shared. `prefillChunkSize` in the runner's
[`pipeline.go`](https://github.com/ollama/ollama/blob/v0.34.0/x/mlxrunner/pipeline.go)
sets that chunk. `qwen3.8:27b-nvfp4`'s retry is the one figure that differed
between runs. It read 3,474 cached on the tabulated run, where nothing was
terminated, and 2,063 on the other, with 16.3 s of prefill. The runner checks
for a cancelled request only between chunks and keeps the chunks it has
finished for the retry. Why the cancellation reached it on one run and not the
other is not in the log.

## Four checks for a chat server on a shared system prompt

The runs above imply four checks for whoever builds the chat server.

| Check                                                                                                         | Why                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Read the model's memory type from Ollama's server log before relying on the cache                             | `llama-server` prints `llama_memory_recurrent` when it loads a recurrent model, and the same log records `using llama-server for model` or `mlx runner is ready` for each request. An attention-only build on `llama-server` paid nothing for a new conversation on 119 of 120, so the memory type is a selection criterion.                                                                                                |
| Budget a recurrent model's new-conversation cost by runner, and do not shorten the system prompt to reduce it | On `llama-server` the charge is one 1,024-token batch per divergence, from 1,549 to 4,812 prompt tokens: a fifth of a 4,800-token prompt and all of a 1,000-token one, and a prompt under one batch holds no checkpoint and costs more than its cold prefill. On the MLX builds the charge is one extra cold prefill per system prompt. A throwaway request with a different question absorbs it; an exact repeat does not. |
| Expect two active conversations to pay per turn on a recurrent `llama-server` build                           | Alternating turns re-evaluated 1,019 to 1,080 tokens each on four of the five, against 18 to 40 for consecutive turns of one conversation. A server that serves several users at once from one of those four pays a batch on every turn; an attention-only build does not.                                                                                                                                                  |
| Log `prompt_eval_cached_count` and `total_duration` on every reply, not `prompt_eval_duration` alone          | The cached count is the only field that separates a served prefix from a re-evaluated one. A retry's own prefill read 175 ms or less while its total waited up to 34.4 s behind the abandoned call, so a client timeout shorter than the model's cold request buys nothing on a retry. The inference is to set the timeout past that cost.                                                                                  |

The probe did not measure how many cached prefixes a runner keeps, or what it
evicts under memory pressure. It did not measure concurrent clients, or
replies longer than its 60-token cap or with thinking on. Every figure is one
host, one Ollama version and one batch size.

The repository is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook every figure above comes from is at
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md).
