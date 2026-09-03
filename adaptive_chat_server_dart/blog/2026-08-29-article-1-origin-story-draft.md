# An SDUI demo that turned into a local-model benchmark

## None of this was needed to ship the demo

[`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards)
is a Flutter renderer for Adaptive Cards with a small Dart chat server behind
it. Ask the server a question and a local model running on Ollama answers with
Adaptive Card JSON, which the client renders as a date picker, a labelled fact
list, a table, or a chart — server-driven UI whose payload comes from a language
model rather than from a backend developer.

<!--
SCREENSHOT (to be added): a rendered card from the demo client in
`adaptive_chat_client/`, showing a model reply that came back as Adaptive Card
JSON and rendered as a real control rather than as text. An options question
answered with an `Input.ChoiceSet` is the best subject, because §3 turns on the
difference between a clickable control and a tidy Markdown list. Caption should
name the model and say the reply is unedited model output.
-->

None of what follows was needed to make that work. Pick a model, point the
server at it, and it answers in cards. The measurements below live in a lab
notebook inside that repository, and nothing in them gates the demo running.

The article exists for a different reason. The card path turned out to be a
discriminating test problem for local models, and the results transfer past this
demo to any workload that asks a local model for constrained, schema-shaped
JSON. The demo is the instrument, not the subject.

## Answering in cards applies four constraints at once

Producing an Adaptive Card imposes four requirements in a single reply: strict
JSON, a closed element vocabulary the model must not invent from, a shape chosen
to fit the question, and format stability across a multi-turn conversation. Miss
any one and the reply is not a card.

Each of the four has an unambiguous pass/fail. The JSON parses or it does not.
The element type is either in the palette or invented. The shape either answers
the question — a pick-from-a-set question wants a control the user can click —
or it does not. The format either survives the conversation's prior turns or drifts
back to Markdown. There is no rubric and no grader model in that chain.

Most chat benchmarks do not apply all four together. That combination is what
made this workload worth measuring.

## A model can sweep both cold-start sets and still miss nearly every shape case

`llama3-chatqa:8b` sweeps both cold-start sets: **21/21** on the everyday set
and **10/10** on the stress set. On the shape set it produces the element type
that answers the question on **4 of 25** cases cold-start, and on **1 of 25**
once two prose turns precede the question.

The gap needs an explanation before it reads as a contradiction, because a
21/21 does not usually sit next to a 1/25. The card system prompt explicitly
permits a plain Markdown answer when no element type fits, so the everyday and
stress sets score a reply as passing if it renders as a card **or** as clean
prose. Only a broken card fails. A model that answers everything in tidy
Markdown therefore clears both sets without ever being asked to build a card.

That is close to what this model does. Its 10/10 stress score is **0 cards and
10 prose**, and its everyday sweep is **2 cards to 19 prose** — it attempts a
card twice in the 21 everyday calls and not at all under stress.

The generalizable result is that renderable prose is not always a pass. An
options question answered as a tidy Markdown list renders perfectly and still
cannot be clicked, which fails the user in a way no JSON-validity check catches.
That is why the shape probe exists: it requires the element type that answers
the question, not merely a reply that parses.

## Three test sets, judged by the parser the server ships

The probes send fixed question sets to a model over Ollama's `/api/chat` and
judge each reply with the server's own card parser rather than with the probe's
own idea of what a card looks like. A probe applying its own definition could
report a pass rate the running server disagrees with, which is worse than no
measurement at all. The scripts are in
[`tool/model_probes`](https://github.com/freemansoft/Flutter-AdaptiveCards/tree/main/adaptive_chat_server_dart/tool/model_probes).

Everything here was measured in August 2026 against a local Ollama on an Apple
M1 Max with 64 GB. A latency or coverage figure that cannot name its machine is
not comparable to one from another box, which is a later article's subject.

Three sets produce the scores:

| Set      | How the denominator is built                                    | What it asks                                                                                                      | What it is for                               |
| -------- | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| Everyday | 7 requests × 3 temperatures (`0`, `0.2`, `0.6`) = **21**        | One ordinary request per common reply shape                                                                       | Is this model usable at all?                 |
| Stress   | 5 cases × 2 temperatures (`0`, `0.6`) = **10**                  | The five requests that actually break: code, big table, nested form, escaped strings, two structures in one reply | Which model or setting should we ship?       |
| Shape    | **25** cases, scored cold-start and with history, `--samples 2` | Did the reply use the element type that answers this question?                                                    | Does the card do the job the question asked? |

Sample counts differ between them, and it matters for how small differences
read: **shape figures are `--samples 2`; everyday and stress figures are
`--samples 1`.** A one-point difference between two models is noise rather than
a ranking. A re-measurement moved ten of twelve steady models by ±1 with nothing
about them changing.

Cold start and with history are separate conditions, not a framing choice. On
`qwen2.5-coder:7b` at `t=0`, "what are my options for deployment targets"
answers with an `Input.ChoiceSet` when it is the first turn. Put **one** prose
turn ahead of the same question and the reply is 867 characters of Markdown;
with two turns, 903 — no card either time. One prose turn is enough, which is
why every score below carries its condition.

A fourth set exists — a prompt A/B set that compares two system prompts rather
than two models — and it belongs to the tuning article.

## Strict-shaped output spreads fifteen models from 24/25 to 1/25

Before any score: these are all measured on the configuration the server ships
— `t=0`, `think: false`, and a synthetic two-turn card seed prepended to the
context. What that seed is worth varies by model, from +10 shapes to −2, and is
the tuning article's subject. Read the figures below as seeded figures.

With-history shape coverage across the fifteen models measured runs from
**24/25 to 1/25**. Five of them:

| Model               | Weights | Cold-start | With history |
| ------------------- | ------- | ---------- | ------------ |
| `qwen3.8:27b-nvfp4` | 16.9 GB | 24/25      | 24/25        |
| `granite4.1:8b`     | 5.0 GB  | 23/25      | 21/25        |
| `qwen2.5-coder:7b`  | 4.4 GB  | 20/25      | 18/25        |
| `llama3.2:latest`   | 1.9 GB  | 15/25      | 15/25        |
| `llama3-chatqa:8b`  | 4.3 GB  | 4/25       | 1/25         |

**Weight does not predict coverage.** `granite4.1:8b` at 5.0 GB scores 21/25
with history, matching two models four times its size. Weight does not predict
speed either, but that figure needs its host and its Ollama version named, so it
belongs to the two-host article.

**Cold start does not predict with-history performance, in either direction.**
Five of the fifteen score the same under both conditions, two gain a shape warm
(`hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` and
`nemotron-3.5-lightning:30b`), and three lose two (`granite4.1:8b`,
`qwen2.5-coder:7b`, and `nemotron-3-nano:4b`). Judge on the with-history column,
because that is the condition a user is in.

Tool calling splits the roster a fourth way, and it is worth stating because the
support is per-model and silent when absent — a model that cannot call a tool
returns an ordinary reply rather than an error. "Can call a tool" is also
separate from "uses it for a card." Of the fifteen models, **8** return a card
through Ollama's tool channel, **3** can call a tool but never reach for the
card tool, including a model fine-tuned specifically for tool use, **2** fire it
at a plain prose question with nothing to render, and **2** expose no
tool-calling path at all — one of them the server's own compiled-in default.

For the obvious question — which model should I run — the answer on ordinary
hardware is `granite4.1:8b`: 21/25 with history in 5.0 GB. Hardware is the
constraint behind that recommendation, since seven of the fifteen models do not
fit a 16 GB host at all; which seven, and what the smaller machine costs, is the
two-host article.

Knowing which models can do this is half the story. Getting the output reliable
from a model that can was a separate process, with its own ledger of what worked.

## A busy machine and a slow model look identical from the probe's side

The first version of one sweep omitted the step that unloads each model before
the next one loads. Probes send `keep_alive: 30m`, so the finished model stayed
resident while the next loaded, two models sat in memory together, and Ollama
thrashed between them. `granite4.1:3b` recorded **52 stalled calls** and scored
12/25 with history where an idle machine gives **17/25**. With the unload in
place the sweep took **7 minutes instead of 124**.

Nothing about the model changed between those two runs. The wrong measurement
looked exactly like a slow model, because from the probe's side a reply that
takes too long is a reply that takes too long, whatever the reason.

The obvious doubt that raises is worth answering here rather than leaving to
accumulate: every figure in this article was collected with **one model resident
at a time** — load a model, run all of its probes, record the result, unload,
move on.

The two-host artifacts belong to the next comparison article, and the remaining
harness lessons — assertions that were themselves wrong, and `system` messages
that never reach the model — to a measurement-hygiene article.

## What transfers

Four things generalize past this demo. Test the shape your workload actually
needs rather than a chat benchmark, because a model can sweep one and fail the
other. Judge replies with the parser you ship, not with a second definition of
correct. Measure with conversation history, not only cold start, since one prose
turn was enough to change the answer here. And state the test set and the
condition beside every score, because `18/25` without them is not interpretable.

Three articles follow: the tuning process — fourteen levers tried on this
workload, which shipped, and what is still open; the two-host comparison, the
same benchmark on a 64 GB M1 Max and a 16 GB M5; and then the tool channel and
measurement hygiene.

The project is at
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook every figure above is drawn from is at
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/ba02fd98/adaptive_chat_server_dart/ModelBehavior.md).
