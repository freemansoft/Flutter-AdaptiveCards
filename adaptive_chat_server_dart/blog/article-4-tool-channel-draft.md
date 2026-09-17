# Ollama's tool channel produces better cards, when the model remembers to use it

In
[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
a demonstration Dart chat server hands a question to a local Ollama model. It
asks for the answer as Adaptive Card JSON, a tree of typed UI components called
elements (`TextBlock`, `Table`, `Input.ChoiceSet`). A Flutter client renders
that card as interactive UI rather than as text. By default, the card comes back
in the model's message body, as JSON text inside `message.content`, which the
chat server parses to recover the card.

Ollama also offers a second route, the tool channel. The request body declares
a `render_adaptive_card` function and a schema for its arguments, in the
standard tool-calling format. Nothing ever runs that function. It exists only
to give the model a schema to answer into. When the model uses it, the card
arrives in `message.tool_calls[0].function.arguments`, already decoded into a
JSON object rather than as text the server has to parse.

Two measurements follow. One asks whether the tool channel is worth anything
on its own. A card that never has to survive being written as text should fail
less often. The probe puts the same 25 questions down each route and scores
both runs the same way.

The other asks whether the tool channel can rescue what the prose channel
got wrong. It tries a two-pass shape a server could actually run. Ask in the message body
as usual, then reach for the tool only when that reply fails to parse. The second pass fires on about one call in fourteen, so most
questions never cost a second round trip.

Every figure below comes from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md),
a lab notebook in that repository.

## Terms used in this article

| Term                             | What it means here                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Channel**                      | Where the model's reply travels. `prose` puts card JSON as text in `message.content`. `tool` puts it in the arguments of a `render_adaptive_card` call. The name comes from the `--channel` flag of the probe `shape_ab.dart`.                                                                                                                                                                                                                                                                                                |
| **Arm**                          | One complete run of the 25 cases in one configuration, and the unit this comparison is built from. That is 100 calls: 25 cases × 2 samples × 2 conditions, so every question is asked twice cold and twice with history. The prose arm asks for the card in the message body; the tool arm offers `render_adaptive_card`. An arm is not the same as a channel: an arm is a whole run, a channel is where one reply travelled, which is why the tool arm turns out to contain replies that came back through the message body. |
| **Roster**                       | The 15 local models this series measures, chosen for what they are rather than for how they score. Only some of them can use the tool channel at all, which is why this article's tables carry 7 rows and the retry's carries 10.                                                                                                                                                                                                                                                                                             |
| **Shape case**, `n/25`           | 25 questions, each paired with the Adaptive Card element types that would answer it. A case passes when the reply uses one of them, so the score measures shape coverage rather than accuracy.                                                                                                                                                                                                                                                                                                                                |
| **`--samples 2`**                | Every case runs twice and passes only if both runs passed, so one borderline call takes the whole case. The notebook's noise floor is ±1.                                                                                                                                                                                                                                                                                                                                                                                     |
| **Cold-start**, **with-history** | The question asked first, or asked with two ordinary conversational turns already in the conversation.                                                                                                                                                                                                                                                                                                                                                                                                                        |
| **Adoption**                     | How often a model actually called the tool when one was offered, out of 100 calls. Recorded per call by `shape_ab.dart`.                                                                                                                                                                                                                                                                                                                                                                                                      |

## How the probes build both measurements

[`tool/model_probes/shape_ab.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/shape_ab.dart)
`--channel tool` runs the 25 shape cases through a `render_adaptive_card`
function. Every scoring rule in the probe directory is written against a reply string.
The tool arm's JSON arguments are converted back to a string before scoring.
That way a single judge scores both arms, rather than two sets of rules that
could drift apart.

The two arms also share a system prompt, as far as they can. The tool arm's
prompt is the prose prompt with a byte-identical element catalogue. Only the
raw-JSON-emission rules are rewritten, the ones a tool call makes false. Every
instruction about which Adaptive Card element answers which question is
word for word the same. Any gap between the arms is a property of the
channel rather than of two differently written prompts.

Measured 2026-09-16 on an Apple M1 Max with 64 GB under Ollama 0.34.0,
`--samples 2` at
`t=0`. The 7 models are those a capability probe rates as able to use the tool
channel at all, which the first article covers.

Neither arm is seeded. The seed is a synthetic assistant turn holding raw card
JSON, so the tool arm cannot carry it. Shape figures elsewhere in this series
are seeded; none below is.

Declaring a function does not remove the message body, so a model can ignore
the tool and write card JSON into `message.content` as before. Both routes
then meet that same judge. A reply that arrived in the message
body is scored by the same rules and can pass. It counts toward the tool
arm's score exactly as a tool call would.

A tool-arm score is therefore a blend of two channels unless something records
which route each reply took. `shape_ab.dart` records it per call as `toolUsed`, and
every result below is read through that field.

The retry is measured separately, by a second probe with a different shape. It
asks every card case in prose first, then retries only the replies that fail
to parse. The retry offers `render_adaptive_card` and discards the broken
reply. Showing the model its own bad output would measure self-correction as
well as the tool channel, which is a second variable. That probe covers fourteen of
the fifteen models. One wedged its runner mid-run and was abandoned rather
than recorded as failures.

```mermaid
flowchart TD
  Q["Card-shaped question"] --> P["ask in prose\ncard_system_prompt.txt"]
  P --> D{"does the reply parse\nas a card?"}
  D -- yes --> DONE["card rendered,\nno second call made"]
  D -- "invalid JSON" --> R["retry: same question,\nrender_adaptive_card offered"]
  R --> D2{"did the model\ncall the tool?"}
  D2 -- yes --> T["tool arguments,\ncannot be malformed JSON"]
  D2 -- no --> C["message.content again"]
  T --> J{"one judge"}
  C --> J
  J -- recovered --> OK["card recovered"]
  J -- "still broken" --> BAD["not recovered"]
  style DONE fill:#6c6,stroke:#060,color:#000
  style OK fill:#6c6,stroke:#060,color:#000
  style BAD fill:#f66,stroke:#900,color:#000
```

Only the `invalid JSON` branch reaches the retry, so only those calls cost a
second round trip. A reply that parses the first time is done at the `card
rendered` node. That is why the retry cannot depress the success rate of calls
that already worked: it never sees them.

## The tool wins on every model that calls it

Per-call pass rate on the 96 card-asking calls in each arm, from
[the tool-channel section](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md#the-tool-channel-measured-against-prose)
of the notebook.

| Model                        | Prose arm | Tool arm, all calls | Tool arm, via tool | Tool arm, via message body | Adoption |
| ---------------------------- | --------: | ------------------: | -----------------: | -------------------------: | -------: |
| `qwen3.6:27b-coding-nvfp4`   |       92% |                100% |    **100%** (n=96) |                          — |   96/100 |
| `qwen3.8:27b-nvfp4`          |       94% |                 94% |     **98%** (n=92) |                   0% (n=4) |   92/100 |
| `gpt-oss:20b`                |       80% |                 80% |     **96%** (n=80) |                  0% (n=16) |   80/100 |
| `granite4.1:8b`              |       67% |                 82% |     **88%** (n=90) |                   0% (n=6) |   90/100 |
| `qwen3-coder:30b`            |       67% |                 78% |     **92%** (n=76) |                 25% (n=20) |   78/100 |
| `nemotron-3.5-lightning:30b` |       62% |                 69% |     **91%** (n=68) |                 14% (n=28) |   68/100 |
| `nemotron-3-nano:30b`        |       62% |                 58% |     **79%** (n=66) |                 13% (n=30) |   66/100 |

The third column is what a comparison that ignores the route reports. It is
level with prose on `qwen3.8:27b-nvfp4` and `gpt-oss:20b`, and below it on
`nemotron-3-nano:30b`. The fourth column is the same runs, counting only the
calls that used the tool.

**Where the tool is actually used, it wins on every model**, 79% to 100%
against 62% to 94% on prose. What the blended column measures is adoption.
Between 4 and 34 calls per 100 never used the tool, and those calls drag the
arm back toward its prose score.

One caution on the fifth column. Those are the calls where the model judged
that no card was wanted. A low score there is largely the decline itself being
counted as a failure, not evidence that the fallback path is broken.

## A retry on parse failure recovers 43 of 99 broken cards

That 43 of 99 is an average, and it hides the useful part. Ten of the fourteen
models had parse failures at all, and among those the retry splits in two. Five of them recover
half or more, **33 of their 45** between them. That group holds the three
models that recover every failure they have. It also holds `qwen3-coder:30b`,
which recovers 12 of 18 and had the worst prose serialization in the set. The other
five recover 10 of 54.

| Model                        | Canary                 | Parse failures | Recovered |
| ---------------------------- | ---------------------- | -------------: | --------: |
| `qwen3.6:27b-coding-nvfp4`   | `supported`            |              7 |     **7** |
| `granite4.1:8b`              | `supported`            |              4 |     **4** |
| `gpt-oss:20b`                | `supported`            |              2 |     **2** |
| `qwen3-coder:30b`            | `supported`            |             18 |    **12** |
| `qwen3.5:9b`                 | `overCalls`            |             14 |     **8** |
| `nemotron-3-nano:4b`         | `supportedButDeclines` |              6 |         2 |
| `granite4.1:3b`              | `overCalls`            |             14 |         4 |
| `nemotron-3-nano:30b`        | `supported`            |             14 |         4 |
| unsloth Nemotron             | `supportedButDeclines` |             12 |         0 |
| `nemotron-3.5-lightning:30b` | `supported`            |              8 |         0 |

What separates the halves is adoption again. Of the 99 retries,
63 went through the tool and succeeded 62% of the time. The 36 where the model
ignored the tool a second time succeeded 11% of the time, recovering 4 cards.

Even a tool-answered retry can fail, and 24 did. In 18 of those the model
called the function with no card in it at all. A tool call cannot carry
malformed JSON, but it can carry nothing.

## Malformed JSON accounts for most of the gain

Failed calls per 100, card cases only. `infra` covers HTTP 500s and timeouts
and is not attributable to either channel.

| Arm   | malformed | declined | wrong element | infra |
| ----- | --------: | -------: | ------------: | ----: |
| prose |    **50** |       53 |            45 |    21 |
| tool  |     **7** |       81 |            34 |    11 |

Ollama returns tool arguments already decoded, so a tool call cannot carry
malformed JSON. Across the 570 calls that went through the tool, none did. All
7 in the tool arm are `qwen3-coder:30b` message-body fallbacks. Re-issuing one
of those calls by hand shows what happened. The model ignored the tool and
wrote two top-level JSON objects separated by a newline, which is not valid
JSON. The prose prompt has a rule against exactly that. The tool prompt
drops it, because it reads as an emission mechanic.

Valid JSON is not a valid card. An invented element type parses, clears the
detector, and renders as an invisible blank that no pass-or-fail score catches.
The chat server has always checked replies against its element vocabulary for
exactly this. No probe did, so that check now runs inside `shape_ab.dart` too. Counting these runs from the
element types each judged reply recorded, unrenderable types are **absent from
both arms** across all 1,400 calls.

The failure that remains is picking the wrong element for the question, 45 on
prose against 34 on tool. That is a prompt-quality problem rather than a
channel one.

## Two conversational turns make a model forget the tool

Excluding the negative control, one case whose right answer is prose, the
calls where a model declined the tool split sharply by condition.

| Model                        | Declines | Cold | With history |
| ---------------------------- | -------: | ---: | -----------: |
| `nemotron-3-nano:30b`        |       30 |   14 |           20 |
| `nemotron-3.5-lightning:30b` |       28 |    4 |       **28** |
| `qwen3-coder:30b`            |       20 |    2 |       **20** |
| `gpt-oss:20b`                |       16 |   12 |            8 |
| `granite4.1:8b`              |        6 |    8 |            2 |
| `qwen3.8:27b-nvfp4`          |        4 |    2 |            6 |
| `qwen3.6:27b-coding-nvfp4`   |        0 |    2 |            2 |

`qwen3-coder:30b` goes from 2 non-tool calls cold to 20 with history, while
its prose score moves by a single case, 16 to 17. Two ordinary
conversational turns are enough to stop a model from reaching for a function it
used reliably on turn one.

This series has already documented that history erodes card shape on the
prose channel. That is what the seed card exists to counter. The tool channel
has the same weakness, and on some models a worse one. The seed cannot be used
against it, being a prose-channel artifact.

The cases that lose the tool most are the ones whose natural answer is text.
`number`, `codeblock`, and `text` each go 10 of 24 calls, against 2 for
`carousel` and `badge`.

## The repository chat server does not implement the tool channel

This tool channel is not implemented in the code.
The chat server runs exactly as it did before this work. It asks for card JSON
in the message body, parses what comes back, and falls back to Markdown when
that fails. There is no flag to turn the tool channel on, and the retry needs
the tool channel. Today, neither is in the implemented reply loop.

The measurement favors the tool channel, but what it favors is bounded by
adoption. Four of seven models decline on 16 to 30 calls per 100, and
history makes it worse. A second code path through the reply loop is hard to
justify on a benefit that fades two turns into a conversation.

The retry is the narrower change, short of switching the whole reply loop. It
does pay, on a model that both breaks on prose and answers a tool when offered
one. Those are properties you can measure
before deciding. `qwen2.5-coder:7b`, the model this chat server ships, has
neither: no parse failures in 96 calls, and no tool calls at all. That argues
for a per-model setting rather than a default, and it bears on the choice of
model rather than on the reply loop.

The probe scripts are in the repo, ready to point at the next model worth
considering.
[`tool_channel_arms.sh`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/tool_channel_arms.sh)
runs the capability probe over all 15 models. It then runs both shape arms
over the models that probe rated `supported`.
[`retry_sweep.sh`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/retry_sweep.sh)
runs the retry. Re-run them when the roster of models changes, when a model's tool
support changes, or when the tool prompt changes, because the capability
verdicts move with the prompt. Between them, it is roughly 2,700 serial model
calls.

One variable stays untested. Every probe in the notebook sends `think: false`,
so all of the above is thinking turned off.

The repo is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook every figure above came from is
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md).
