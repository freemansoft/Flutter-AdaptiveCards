# Ollama drops an oversized history message whole, and nothing tells you

In
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
a demonstration Dart chat server hands a question to a local Ollama model and
asks for the answer as Adaptive Card JSON, a strict, closed-vocabulary schema
that a Flutter client renders as interactive UI rather than as text. A directory
of probes measures which local models manage that and how well. Every one of
those probes had been asking its question into a nearly empty window: a system
prompt, one question, and at most a short seed exchange. This article asks what
changes when the window is actually full, which is what a real conversation
does to it.

Two findings, all on an Apple M1 Max with 64 GB and an Apple M5 with 16 GB,
both running Ollama 0.33.3. What the runner allocates follows one rule with no
counterexample in thirty-one runs, and it is often not what was asked for. A
model handed more history than its window holds does not get a trimmed version
of it, it gets none of it, and no error says so.

Both are properties of the runtime rather than of any model. What a full window
does to a model's own behavior is a separate question with a separate answer,
and a companion article measures it: three of eight models lose about a third of
their shape coverage, and the two worst fail in opposite ways.

Every figure is transcribed from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md),
the lab notebook in that repository.

## Terms used in this article

| Term                    | What it means here                                                                                                                                                                                                                                                                        |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`num_ctx`**           | The context window an Ollama request asks for, in tokens. It is a request, not a guarantee.                                                                                                                                                                                               |
| **Trained window**      | The context length a model was trained at, reported by `ollama show`. `llama3-chatqa:8b` is 8192; `qwen3.5:9b` is 262144.                                                                                                                                                                 |
| **`prompt_eval_count`** | The token count Ollama reports for the prompt it actually evaluated. It is the only way to find out what the model really received, and this article turns on it.                                                                                                                         |
| **Shape score**, `n/25` | 25 test cases, one question each, paired with the Adaptive Card element types that would answer it. Scored on one thing: did the reply use one of them? This is shape coverage, not accuracy, and a model can be entirely correct in prose and score low. Figures here are `--samples 1`. |
| **Filler**              | A block of deterministic nonsense the probe prepends as conversation history, sized to a token target, so a run can ask what a model does with a window that is mostly used.                                                                                                              |

## The allocated window is `min(requested, trained window)`

The probe asks for a window large enough to hold its filler plus the card
system prompt, and then reads Ollama's `/api/ps` to find out what the runner
actually gave it. Requested was 35851 tokens in every row below.

| Model                     | Trained window | Allocated | Clamped |
| ------------------------- | -------------- | --------- | ------- |
| `llama3.2:latest`         | 131072         | 35851     | no      |
| `granite4.1:8b`           | 131072         | 35851     | no      |
| `granite4.1:3b`           | 131072         | 35851     | no      |
| `nemotron-3-nano:4b`      | 262144         | 35851     | no      |
| `qwen3.5:9b`              | 262144         | 35851     | no      |
| `qwen2.5-coder:7b`        | 32768          | **32768** | yes     |
| `llama3-groq-tool-use:8b` | 8192           | **8192**  | yes     |
| `llama3-chatqa:8b`        | 8192           | **8192**  | yes     |

Every clamp lands exactly on that model's own trained window, none at an
intermediate value, and no model was given less than its window could hold.
Thirty-one runs across both hosts produced no counterexample, including six
models too large for the 16 GB machine, which asked for 35851 against windows
of 131072 and above and received exactly that.

Host memory does not enter into it, which is measured rather than inferred. The
16 GB M5 and the 64 GB M1 Max return identical allocations for all eight models,
the three clamps included. The M5 also allocated a full **65536**-token window
on request for a 9B model, which is the reading that retires the idea that a
clamp might be a memory ceiling in disguise.

The practical form of the rule: if you ask for more context than the model was
trained for, you silently get the trained window. Checking `ollama ps` after the
first call is how you find out.

## A message that does not fit is removed, not trimmed

What happens to history that exceeds the allocated window is the finding a
developer is most likely to be bitten by. The probe sent the same filler to
every model under a 35851-token window.

| Model                     | Allocated | Prompt tokens evaluated | History |
| ------------------------- | --------- | ----------------------- | ------- |
| `llama3.2:latest`         | 35851     | 29546                   | kept    |
| `granite4.1:8b`           | 35851     | 29536                   | kept    |
| `granite4.1:3b`           | 35851     | 29536                   | kept    |
| `nemotron-3-nano:4b`      | 35851     | **4374**                | dropped |
| `qwen3.5:9b`              | 35851     | **3965**                | dropped |
| `qwen2.5-coder:7b`        | 32768     | **3850**                | dropped |
| `llama3-groq-tool-use:8b` | 8192      | **3825**                | dropped |
| `llama3-chatqa:8b`        | 8192      | **3819**                | dropped |

A model that trimmed the history to fit would report a prompt count near its
window. The five report between 3819 and 4374 tokens, which is the system prompt
and the question and nothing else. The history message was removed in full.

Nothing errors and nothing warns. The reply comes back looking like a perfectly
good answer to a question asked with no history, because that is exactly what it
is. A chat application built on this would lose its conversation at some length
and carry on answering, and the only visible symptom would be a model that
suddenly seems to have forgotten what it was told.

`prompt_eval_count` is the detection method, and it is cheap: it arrives on every
reply. A count that stays flat while the conversation grows is the tell.

## The measurement that produced this was wrong first

The five drops above look like they split into two groups: two models with an
8192 window that could not have held the history under any policy, and three
with windows of 32768 and above that appear to have had room and discarded it
anyway. That second group was written up as an unexplained behavior, and it was
wrong. The probe caused it.

The filler is sized in **characters**, against an assumed 4.0 characters per
token. Measured against the same 127,020 characters, that constant turns out to
describe some tokenizers and not others.

| Model                      | Tokens for the same text | Characters per token |
| -------------------------- | ------------------------ | -------------------- |
| `llama3.2:latest`          | 29546                    | 4.30                 |
| `granite4.1:8b`            | 29536                    | 4.30                 |
| `gpt-oss:20b`              | 29616                    | 4.29                 |
| `qwen3.8:27b-nvfp4`        | 42542                    | 2.99                 |
| `qwen3.6:27b-coding-nvfp4` | 42538                    | 2.99                 |
| `nemotron-3-nano:4b`       | 46287                    | 2.74                 |

Three unrelated model families agree at about 4.30. Two Qwen builds render the
identical text 44% denser, and `nemotron-3-nano:4b` denser still. The filler
reads `filler-term123 means concept456.`, which is heavy on digits, and
tokenizers split digit strings very differently.

So wherever the constant under-counted, the probe sized a window too small for
its own filler, the prompt overflowed, the message was dropped, and the archive
recorded a model discarding history it appeared to have room for. The control
that settled it gave each model a filler that fits the window it is actually
allocated. All of them kept it. There was never a model that dropped a message
it had room for.

Two habits come out of that, and both are cheaper than the mistake. Size context
in tokens the model reports rather than in a proxy you chose. And when a
measurement produces a behavior with no mechanism, suspect the instrument before
the subject, which is a rule the measurement-hygiene article in this series
arrived at independently.

## Two builds ignore the limit entirely

`qwen3.8:27b-nvfp4` and `qwen3.6:27b-coding-nvfp4` never dropped the filler. Under
the same 35851-token allocation as everything else, they evaluated 42542 and
42538 tokens, roughly 6,700 past what `/api/ps` reported allocating, and scored
17/25 and 21/25 rather than collapsing the way an overflow would predict.

Every other model measured loses the whole message at that boundary. These two
crossed it at no cost. So the allocation rule describes what the runner
allocates and not what it enforces, and on these builds the two come apart. No
mechanism is established here. Both are `nvfp4` builds, which the notebook
already records as changing their behavior under Ollama's `format` constraint
between runtime versions, so a runner-specific difference is consistent with the
readings without being shown.

## What to take from this

Four things, in the order a developer hits them.

| Check                                                    | Why                                                                                                                                 |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Read `prompt_eval_count` on every reply                  | It is the only signal that history was dropped, and a count flat across a growing conversation is the tell.                         |
| Compare `ollama ps` against the `num_ctx` you asked for  | You get `min(requested, trained window)`, silently, and a model's trained window is often far below what you assumed.               |
| Measure a model at the context length you will run it at | A full window costs three of eight models measured about a third of their coverage, which the companion article decomposes.         |
| Size context in tokens, not in characters or bytes       | The same text is 4.30 characters per token on one tokenizer and 2.74 on another, which is enough to overflow a window sized for it. |

None of this is a criticism of Ollama's defaults. Dropping a message that cannot
fit is a defensible choice, and trimming one has its own failure mode, in which
a model answers confidently from the back half of an instruction it never saw
the front of. What is worth changing is that the choice is invisible from the
client side unless you go looking for it in a token count.

The repository is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook these figures are read from is
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md).
