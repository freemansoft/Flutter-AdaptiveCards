---
name: adaptive-cards-chat-prompt-tuning
description: >
  Diagnose and fix bad Adaptive Card replies from a local Ollama model in
  adaptive_chat_server_dart — raw JSON shown as text, blank/invisible elements,
  truncated or malformed card JSON, a card the model wrapped in prose, or a
  model answering in Markdown when a card was wanted. Also use when editing
  assets/card_system_prompt.txt or card_schema.json, when adding a new element
  type the model needs to know about, or when choosing/tuning a model or its
  temperature. Use this skill whenever someone reports a card "not rendering",
  "showing as JSON", "coming out blank", or asks why the chat server's model
  is emitting the wrong thing — even if they have already guessed at the cause
  and just want a prompt edit.
---

# Tuning the chat server's card system prompt

The chat server asks a local model to answer either with an Adaptive Card fragment or with Markdown. When a reply renders wrong, the fix is almost always in one of three places, and picking the wrong one wastes a lot of time:

| Where | Symptom it explains |
| --- | --- |
| `assets/card_system_prompt.txt` | The model produced a shape nobody asked for — prose around a card, an invented element type, a missing wrapper |
| `lib/src/card_detect.dart` | The model produced something reasonable and the server refused or corrupted it |
| Decoding settings (`--ollama-temperature`, `--json-format`, model choice) | The model is capable but sampling too hot, or ignoring a constraint you assumed it honored |

The rest of this skill is about telling those apart before editing anything, then measuring whatever you change.

## Check this before anything else: which prompt is even loaded?

The server ships **two** system prompts and they produce entirely different replies:

| File | What it tells the model |
| --- | --- |
| `assets/card_system_prompt.txt` | The card palette and rules. |
| `assets/default_system_prompt.txt` | Your reply renders in a TextBlock; use Markdown. Never mentions Adaptive Cards. Its name is a leftover — it is not a default and is never loaded unless named. |

Measured on `qwen2.5-coder:7b` at `t=0` over the same eight questions: **8/8 cards** on the card prompt, **0/8** on the Markdown one. That is a larger effect than any model or temperature difference recorded in [`ModelBehavior.md`](../../../adaptive_chat_server_dart/ModelBehavior.md), which is why the server has **no default** — it refuses to start unless the invocation names `--system-prompt-file` or `--echo`.

So when the report is "it answers in Markdown" or "it never sends cards", confirm which prompt was named **first** — the server logs it at startup:

```
INFO: System prompt: assets/card_system_prompt.txt
```

One glance invalidates every other hypothesis. Since the default was removed on 2026-08-15 this is rarer, but it still happens two ways: someone named the Markdown prompt, or they are running a build from before that date, when the prompt could be implicit.

This does not apply when the complaint is a *broken* card — raw JSON, blank elements, truncation. Those prove the card prompt is already active, so skip ahead.

## The one rule that saves the most time

**Never edit the prompt from a description of the failure.** Get the literal bytes of the reply first. A reply that "obviously" contains a stray newline has, on inspection, contained zero real newlines and eleven correctly escaped ones — the corruption was in the server's own fence-stripping, and every minute spent rewording the prompt was wasted. This is recorded in [`ModelBehavior.md`](../../../adaptive_chat_server_dart/ModelBehavior.md) because it has happened more than once.

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/dump_reply.dart \
  --model <tag> --prompt '<the user message that failed>'
```

That prints the reply with real newlines marked, counts real vs escaped newlines, says whether a fence is present, and — most importantly — prints the verdict from the server's **own** detection (`card[3]`, `prose`, `broken: …`). Believe that verdict over your own reading of the JSON.

**If it does not reproduce, add conversation history before concluding the report was wrong.** The server replays prior turns on every request, but the probes default to a single turn, so a cold-start probe is a different experiment from what the user actually hit. One prior prose turn is enough to flip `qwen2.5-coder:7b` out of cards entirely on an options question — measured `card[2]` cold, prose after one turn. Pass `--history <file>` to replay turns.

This cuts both ways: a fix validated only cold-start is only proven cold-start. Say which condition every number came from.

## Diagnosing from the verdict

**`card[n]`** — the server would render this. If the user still says it looks wrong, the problem is downstream: element types that don't exist render as invisible blanks rather than errors, so check every `"type"` against the registry. A misspelled `Textblock` is valid JSON and silently renders nothing.

**`prose`** — the model chose Markdown. That is a legal reply, not a bug. The question is why it declined the card, and the usual answer is that the card shape it wanted had no legal expression in the prompt.

**`broken: …`** — the interesting case. Read what follows:

- _invalid JSON_ with the error pointing at the end of the reply → the model appended something after the card. See "Redirect, don't forbid".
- _invalid JSON_ pointing at a `,` between two top-level `{}` → the model sent multiple elements without the enclosing `[ ]`.
- _valid JSON but not a renderable card_ → the shape parsed but isn't a card: empty body, missing `type`, mixed array.
- _duplicate key_ → the model re-emitted an object key per item instead of appending to one array. Seen under schema-constrained decoding.

## Redirect, don't forbid

This is the highest-leverage thing known about this prompt, and it is counterintuitive enough to be worth stating plainly.

When a model does something unwanted, the instinct is to add a prohibition. On this workload that has been measured and it does not work. Asked to explain a code snippet, `qwen2.5-coder:7b` emitted a card and then appended the explanation — which makes the entire reply raw text. Adding "NEVER mix", a checklist item, and an escape hatch to Markdown scored **exactly the same** (14/16 → 14/16) and made things qualitatively worse: the model stopped emitting cards at all and answered every code question as prose.

What fixed it was giving the behavior somewhere to live. The model wanted to explain the code; the prompt offered no legal place for an explanation, so it went after the JSON. Telling it the explanation belongs in a `TextBlock` beside the `CodeBlock` took hard cases from 6/10 to 15/15 at `t=0`.

So when you catch yourself writing another **NEVER**, ask what the model was trying to accomplish and whether the prompt gives it a way to do that. A prohibition removes an option; it does not answer the need that produced it.

## Wording moves the rate; only the detector makes a shape safe

Expect each prompt fix to expose the next failure. Once the model started sending two elements, it began dropping the `[ ]` around them — right intent, invalid JSON. More wording got that to near zero at `t=0` but not at `t=0.6`.

That is the signal to stop tuning and change `card_detect.dart` instead. A repair belongs in the detector when the model's output is **unambiguously** recoverable — an array missing its brackets is an array missing its brackets, there is nothing to guess. Follow the existing pattern: repair only a reply that has already failed to parse, keep the repair only if it makes the reply parse, and add a test proving it does **not** rescue a genuinely mixed reply.

Prompt wording is probabilistic and varies by model and temperature. A detector repair is deterministic. Prefer the detector for anything you need to actually hold.

## Measure every wording change

Prompt edits are not self-evidently improvements, and the failure mode is fixing your one test case while breaking three others. `prompt_ab.dart` runs the shipped prompt and an edited copy over the same user prompts and prints both pass rates:

```bash
cd adaptive_chat_server_dart
cp assets/card_system_prompt.txt /tmp/candidate.txt
# edit /tmp/candidate.txt
fvm dart run tool/model_probes/prompt_ab.dart \
  --model <tag> --candidate /tmp/candidate.txt --samples 2
```

Only promote the candidate into `assets/` once it wins. Then re-run the hard cases:

```bash
fvm dart run tool/model_probes/temperature_stress.dart --model <tag> --samples 3
```

Both judge replies with the server's own detection, so a pass here is a reply the running server would render.

### Which cases to test against

Quoting a pass rate without naming the set it came from is misleading — a model has scored **7/7 on everyday prompts while failing half the stress set**. Three sets exist, for three different questions:

| Set                    | Script                    | Answers                              |
| ---------------------- | ------------------------- | ------------------------------------ |
| Everyday (7 prompts)   | `temperature_matrix.dart` | Is this model usable at all?         |
| Stress (5 prompts)     | `temperature_stress.dart` | Which model/setting should we ship?  |
| Prompt A/B (8 prompts) | `prompt_ab.dart`          | Did my wording change actually help? |
| Multi-turn             | `--history` / `choiceset_ab.dart` | Does it survive a real conversation? |

Only the stress and A/B sets discriminate. A wording change needs A/B **and** a stress re-run — A/B proves the target case improved, stress proves you didn't break the others.

Sets 1–3 are all **single-turn**, so none of them can see a history-triggered failure. If the reported bug involves an ongoing conversation, none of these three will reproduce it no matter how many samples you run.

One more trap in how passes are scored: a reply counts as a pass if it is a renderable card **or** clean prose. That is right for "did the model emit something broken?" and wrong when the *shape* is the defect — an options question answered as a tidy Markdown list scores `prose` = pass while completely failing the user, because it renders fine and cannot be clicked. When the complaint is "it should have been a card", score strictly for the element you expect rather than trusting a green pass rate.

The card shapes that have historically broken, and so are worth checking after any prompt edit:

- **CodeBlock with an explanation** — the shape that tempts a model to append prose after the JSON, or repeat the code in a second fence
- **Carousel** — nested `pages`, historically emitted with the array keyed once per item instead of appended
- **Table** — nested `rows`/`cells`, plus long tables that truncate mid-generation
- **Input.ChoiceSet with `isMultiSelect`** — the checkbox form, which weaker models silently turn into raw HTML or an invented type
- **Multi-line text** — escaped `\n` and quoted strings, the classic invalid-JSON source
- **Mixed replies** — a table *then* a choice set, i.e. two structures in one card
- **Deep nesting generally** — a Table inside a Carousel is where JSON most often ends up malformed

[`ModelBehavior.md`](../../../adaptive_chat_server_dart/ModelBehavior.md) documents each set case by case, and records which models have already failed which shape — check there before concluding a failure is new.

### One model at a time — this one bites

Load **one model, run all of its tests, then switch**. Never interleave models, and never fan out parallel runs against the same Ollama.

The machine holds one mid-size model at a time. Several candidates are 18–24 GB and cannot be co-resident with anything at all. Interleaving forces Ollama to evict and reload weights between calls — a reload costs roughly **20x** the warm load time, which is why the server sets a long `keep_alive` in the first place. Running probes concurrently is worse than useless: the calls queue anyway, and the memory pressure makes the whole set slower than doing it serially, on top of skewing the latency numbers you were trying to measure.

So comparing models is an **outer loop over models**, not a parallel dispatch:

```bash
for m in qwen2.5-coder:7b granite4.1:8b; do
  fvm dart run tool/model_probes/temperature_stress.dart --model "$m" --samples 3
done
```

This applies to subagents too. Dispatching one agent per test case, each hitting the same Ollama, is the anti-pattern — they contend for a single model server and thrash it.

[`ModelBehavior.md`](../../../adaptive_chat_server_dart/ModelBehavior.md) records each model's weights and whether it fits a 16 GB host, so check there before queuing up a run you do not have the RAM for.

### Which models to test against

The models worth keeping working are whichever ones `.vscode/launch.json` currently launches — that set is expected to change, so read it rather than assuming:

```bash
grep -A1 '"--ollama-model"' ../.vscode/launch.json |
  grep -v -e 'ollama-model' -e '^--$' | tr -d ' ",' | sort -u
```

Cross-check against what is actually installed (`/api/tags`) and against [`ModelBehavior.md`](../../../adaptive_chat_server_dart/ModelBehavior.md), which records what each model has already been measured doing — including two traps: a model whose own recommended temperature scores **worse** than `0`, and models that ignore `--json-format` silently, with no error.

A wording change that helps one model can hurt another, so test at minimum the server default (`defaultOllamaModel`) plus one other installed model from that list.

## Adding a new element type

An element registered in `CardTypeRegistry` but absent from the card system prompt will never appear in a reply — the model only emits what the prompt shows it. The prompt is a closed list on purpose: it tells the model to use **only** the listed types, because an invented or misspelled type is still valid JSON and renders as an invisible blank rather than an error.

To add one:

1. Add an entry under the matching section (Inputs, or Display) with a one-line description and a complete, valid, **single-line** example. The examples are what the model actually copies, so an example carrying a property you don't want is how that property spreads.
2. Keep the example minimal. Every optional property shown is one the model will imitate.
3. If the element nests (pages, rows, cells), show one level of nesting exactly once — deep examples produce deep cards, which is where the JSON most often ends up malformed.
4. Verify the model will actually emit it, with a prompt that should elicit it:

   ```bash
   fvm dart run tool/model_probes/dump_reply.dart \
     --model <tag> --prompt '<something that should produce the new element>'
   ```

   Absence of the new type in the reply is the common outcome and means the entry is not pulling its weight yet — usually because the description doesn't say when to reach for it.

5. Add the type to `assets/card_schema.json` too if `--json-format schema` should be able to constrain it.

## Editing conventions for the prompt file

- The prompt tells the model to emit JSON on a **single line**, and its own examples model that. Multi-line examples teach multi-line output, which is where literal newlines get into strings and break the JSON.
- Keep the pre-send checklist near the end short and mechanical. It is the last thing the model reads before answering, and it is where the highest-value invariants belong.
- The checklist currently starts at `0.` because that is the wording that was measured. Renumbering is untested against any model — harmless-looking edits to this file are exactly the kind that need `prompt_ab.dart` before they land.

## Recording what you learn

A measurement that stays in a plan or a PR description gets lost when that work is archived. Copy anything durable into [`ModelBehavior.md`](../../../adaptive_chat_server_dart/ModelBehavior.md) — model name, setting, and the number — and add a `CHANGELOG.md` bullet under `## [Unreleased]` for the package.

The findings worth writing down are the ones that would change what the next person tries: a model that ignores a constraint, a setting that beats the vendor's recommendation, an approach that sounded right and measured flat.
