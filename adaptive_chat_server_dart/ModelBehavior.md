# Model behavior

Which local Ollama models produce renderable Adaptive Cards, what decoding settings they need, and what has already been measured about each.

## Why this file exists

Every finding here was originally recorded in a plan or a design spec. Those documents are dated records — they describe what was true during one piece of work and are archived when it ends. The _results_ outlive them: knowing that a model ignores `format`, or that its own recommended temperature scores worse than `0`, stays useful long after the plan that discovered it is history.

So results get copied here. When a plan or spec produces a model finding, copy it into this file before the plan is archived. Cite the source so the full context is still findable.

Findings are not opinions. Each one below names the model, the setting, and the measurement, because the whole point of the probes in [`tool/model_probes/`](tool/model_probes/README.md) is that reasoning about model behavior without measuring it has already produced wrong answers here more than once.

## The models we care about most

The **top three** are whichever models `.vscode/launch.json` currently launches the server with — those are the ones someone can start from the debugger, so they are the ones worth keeping working.

This set is expected to change. When `launch.json` changes, the priority set changes with it, and this section is describing a pointer rather than a fixed list. Re-derive it rather than trusting the names below:

```bash
grep -A1 '"--ollama-model"' ../.vscode/launch.json |
  grep -v -e 'ollama-model' -e '^--$' | tr -d ' ",' | sort -u
```

At the time of writing that yields `gpt-oss:20b`, `granite4.1:8b`, and `qwen2.5-coder:7b`. If you find that stale, the grep is right and this paragraph is wrong.

`qwen2.5-coder:7b` is additionally the server's compiled-in default (`defaultOllamaModel` in `lib/src/ollama_responder.dart`), which is a separate decision from what the debugger launches.

### Why these three, after the 25-case sweep

The set above is the outcome of the sweep, not a historical accident: `qwen3.5:9b` was swapped out for `granite4.1:8b` on 2026-08-19 and `launch.json` was edited to match.

Read on the shipped configuration, all fourteen candidates rank by with-history shape coverage — the [full table](#shape-coverage--all-fourteen-models-as-shipped) carries the cold-start and erosion figures behind these:

`qwen3-coder:30b` 23/25 · `gpt-oss:20b` 23/25 · `qwen3.6:27b-coding-nvfp4` 23/25 · `granite4.1:8b` 22/25 · `nemotron-3.5-lightning:30b` 22/25 · `hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` 22/25 · `nemotron-3-nano:30b` 20/25 · `qwen2.5-coder:7b` 19/25 · `qwen3.5:9b` 19/25 · `granite4.1:3b` 17/25 · `nemotron-3-nano:4b` 17/25 · `llama3-groq-tool-use:8b` 16/25 · `llama3.2:latest` 14/25 · `llama3-chatqa:8b` 1/25.

**Among 16 GB-capable models the order is unchanged** — `granite4.1:8b` 22/25, then `qwen2.5-coder:7b` and `qwen3.5:9b` tied at 19/25 — so nothing here disturbs the two portable slots. Every model that outranks `granite4.1:8b` is 17 GB or larger.

- **`gpt-oss:20b` — kept, the strongest model measured.** Best on both axes (24/25 cold, 23/25 warm) and the only model with no measurable prose drift at all. Its weakness is a JSON-validity ceiling on deeply nested shapes, not conversation history. At 12.8 GB it stays a ❌ for a 16 GB host, so it earns a debugger slot without being a candidate for the compiled-in default.
- **`granite4.1:8b` — added.** 22/25 with history, second only to `gpt-oss:20b`, and it runs in 5.0 GB. It is the largest warm improvement of any 16 GB-capable model (15/25 → 22/25 under the seed) and it recovered every one of its baseline-eroded cases.
- **`qwen2.5-coder:7b` — kept.** Not the strongest anymore (19/25 warm, fourth), but it is the compiled-in default, the model every promotion decision in this file is gated on, and the smallest at 4.4 GB. Dropping it from the debugger would mean the default ships untested from the one place people launch by hand.
- **`qwen3.5:9b` — dropped, and the 2026-08-19 sweep confirms it.** The original reason was that it had never been run through `shape_ab.dart` at all. It has now: **19/25 with history**, an exact tie with `qwen2.5-coder:7b` — for 6.1 GB against 4.4 GB, more latency, and a thinking mode that has to be disabled to be usable at all (see its [per-model section](#qwen359b)). A tie at greater cost is not a case for the slot, so the decision stands on measurement rather than on absence of it.

**Is `nemotron-3.5-lightning:30b` the better large model? No — `gpt-oss:20b` keeps the slot.** The two tie on as-shipped warm coverage (22/25 vs. 23/25 is within the noise this file elsewhere refuses to read as a difference), so the tie has to be broken on everything else, and every other axis points the same way:

- **Half the weights.** 12.8 GB vs. 23.7 GB, for a better score.
- **It does not depend on the seed to get there.** `gpt-oss:20b` scored 22/25 warm _before_ `--seed-card` existed, with zero shapes eroded by history. `nemotron-3.5-lightning:30b` scored 13/25 — the most severe erosion recorded anywhere in this file, losing all six choice cases plus two more — and only reaches 22/25 because the seed recovers all eight. One model is robust; the other is being held up.
- **It is weaker cold, too.** Stress 3/5 at `t=0` against `gpt-oss:20b`'s 5/5, and a `table` case that fails at all three temperatures on the everyday set.

The one thing `nemotron-3.5-lightning:30b` is genuinely best at is being the **regression canary for the seed mechanism itself**: nothing else in the table swings +9 warm shapes on it, so if `--seed-card` ever silently stops working, this model shows it first and loudest. That is a reason to keep probing it, not a reason to launch it.

**Open question: `qwen3-coder:30b` has a real case against `gpt-oss:20b`'s slot.** The 2026-08-19 sweep put it at 24/25 cold and 23/25 warm — matching `gpt-oss:20b` on both axes — and it is the only model measured with no case it fails under both conditions. It also swept the stress set 5/5 at both temperatures, which `gpt-oss:20b` does not (4/5 at `t=0.6`). Against it: 17.3 GB vs. 12.8 GB, both ❌ for a 16 GB host, and — decisively for now — **its seed-dependence is unmeasured**. `gpt-oss:20b` scored 22/25 warm without the seed, so its rank is robustness rather than support; nobody has run `shape_ab.dart --no-seed-card` against `qwen3-coder:30b`, so the same cannot be said of it. That is the distinction that settled the `nemotron-3.5-lightning:30b` question above. **No slot changes until that baseline exists**; `launch.json` is untouched.

## Candidate models

Chat models worth probing when they happen to be installed. Check availability before assuming a result applies — the command lists everything Ollama has, so embedding models (`nomic-embed-text`, and anything else that cannot hold a conversation) will show up there and are deliberately absent from the table below:

```bash
curl -s http://127.0.0.1:11434/api/tags | python3 -c "import sys,json;[print(m['name']) for m in json.load(sys.stdin)['models']]"
```

**Role** says why the model is on the list. **Cold start** and **With history** are the short version of the [per-model results](#per-model-results) below — `—` means nobody has probed that condition yet, which is an invitation, not a judgement.

**16 GB** is a _portability_ signal, not a limit on what can be tested here. It answers "would this model run for someone on a 16 GB Mac or a 16 GB GPU?", which matters for what the server can reasonably recommend as a default. The current development machine is a **64 GB M1**, where every model in this table runs comfortably on its own — including the ❌ rows. A ❌ means "do not make this the recommended default", not "cannot be probed".

Sorted by model name, and within a family by parameter count ascending (so `nemotron-3-nano:4b` precedes `:30b`), which makes a tag quick to find. Role and verdict, not position, carry the meaning.

| Model                                             | Weights | 16 GB | Role                   | Cold start                                                 | With history        |
| ------------------------------------------------- | ------- | ----- | ---------------------- | ---------------------------------------------------------- | ------------------- |
| gpt-oss:20b                                       | 12.8 GB | ❌    | top 3 (`launch.json`)  | ⚠️ everyday 6/7 · stress 5/5 `t=0`, 4/5 `t=0.6`            | ✅ shapes **23/25** |
| granite4.1:3b                                     | 2.0 GB  | ✅    | candidate              | ❌ everyday 4/7 · stress 4/5 `t=0`, 3/5 `t=0.6` — weakest  | ⚠️ shapes **17/25** |
| granite4.1:8b                                     | 5.0 GB  | ✅    | top 3 (`launch.json`)  | ⚠️ everyday 6/7 · stress 5/5 `t=0`, 4/5 `t=0.6`            | ✅ shapes **22/25** |
| hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest | 22.9 GB | ❌    | candidate              | ❌ everyday 7/7 · stress 3/5 `t=0`, 3/5 `t=0.6`            | ✅ shapes **22/25** |
| llama3-chatqa:8b                                  | 4.3 GB  | ✅    | candidate              | ✅ everyday 7/7 all temps · stress 5/5 both — clean sweep  | ❌ shapes **1/25**  |
| llama3-groq-tool-use:8b                           | 4.3 GB  | ✅    | candidate              | ⚠️ everyday 6/7 · stress 5/5 `t=0` but **1/5** at `t=0.6`  | ⚠️ shapes **16/25** |
| llama3.2:latest                                   | 1.9 GB  | ✅    | candidate              | ❌ Retired as default — failed nested and multi-select     | ⚠️ shapes **14/25** |
| nemotron-3-nano:4b                                | 2.6 GB  | ✅    | candidate              | ❌ everyday 6/7 but stress **2/5** `t=0`, 1/5 `t=0.6`      | ⚠️ shapes **17/25** |
| nemotron-3-nano:30b                               | 22.6 GB | ❌    | candidate              | ❌ everyday 7/7 · stress 2/5 `t=0`, 1/5 `t=0.6`            | ✅ shapes **20/25** |
| nemotron-3.5-lightning:30b                        | 23.7 GB | ❌    | candidate              | ❌ everyday 6/7 · stress 3/5 `t=0`, 4/5 `t=0.6`            | ✅ shapes **22/25** |
| qwen2.5-coder:7b                                  | 4.4 GB  | ✅    | server default + top 3 | ✅ Recommended — cleared every documented failure at `t=0` | ⚠️ shapes **19/25** |
| qwen3-coder:30b                                   | 17.3 GB | ❌    | candidate              | ⚠️ everyday 7/7 · stress 5/5 `t=0`, 5/5 `t=0.6`            | ✅ shapes **23/25** |
| qwen3.5:9b                                        | 6.1 GB  | ⚠️    | candidate              | ⚠️ Only with thinking off; no edge over the default        | ⚠️ shapes **19/25** |
| qwen3.6:27b-coding-nvfp4                          | 18.4 GB | ❌    | candidate              | ⚠️ Ignores `format`; better at `t=0` than its own `0.6`    | ✅ shapes **23/25** |

**Cold start** is a single-turn probe. **With history** replays prior conversation turns the way the server actually does. These are different measurements and a model can pass one while failing the other — every result recorded before 2026-08-14 is a cold-start number, because no probe sent history at all.

**Read the `shapes N/25` figure first.** It is the model's with-history score **as the server ships today** — all 25 shapes, `t=0`, `--samples 2`, measured with the unconditional card seed in place (`--seed-card`, promoted 2026-08-18) — so it describes what a user actually gets. Every model carries one, all measured under identical conditions — see [the full table](#shape-coverage--all-fourteen-models-as-shipped) for cold-start, seed-dependence, and per-model erosion. The ✅/⚠️/❌ is set from this figure (✅ ≥ 20/25, ⚠️ 10-19, ❌ < 10).

The **16 GB** column is not a gate on what gets probed — it records what a constrained host could run. Probing a ❌ model on the 64 GB development machine is expected and useful; it is how this matrix gets filled in. What the column governs is what the server should _recommend_ as a default, since a default that only runs on a 64 GB box is not much of a default.

## Which system prompt produced the number

Every result in this file was measured with **`assets/card_system_prompt.txt`**. The server has no default prompt — every run names one with `--system-prompt-file` (or opts out of models entirely with `--echo`).

| File                               | Effect                                        |
| ---------------------------------- | --------------------------------------------- |
| `assets/card_system_prompt.txt`    | The card palette and rules                    |
| `assets/default_system_prompt.txt` | Markdown only — never mentions Adaptive Cards |

Measured on `qwen2.5-coder:7b` at `t=0`, same eight questions, only the prompt file differing: **0/8 cards** with the Markdown prompt, **8/8** with the card prompt. The gap between the two is the largest single effect recorded in this file — larger than any model or temperature difference — which is why the server stopped having a default at all on 2026-08-15 and now makes every run say which prompt it wants.

Its name is misleading: `default_system_prompt.txt` is not a default and never gets loaded unless you ask for it by name. It keeps the name because renaming an asset breaks every `--system-prompt-file` invocation already written down in docs, launch configs, and shell history.

When reading a bug report, still confirm which prompt was loaded — the server logs it at startup. "The model never sends cards" now means someone named the Markdown prompt, or is running a build from before 2026-08-15, when the prompt could be implicit.

Full result, `qwen2.5-coder:7b` at `t=0`, eight options questions, only the
prompt file differing: **0/8 cards / 8/8 prose** on the default prompt versus
**8/8 cards / 0/8 prose** on the card prompt, with zero broken cards either
way. Six of the eight card-prompt replies contained a real `Input.ChoiceSet`;
the other two chose a `FactSet` and a `TextBlock`, which are defensible for
those questions.

## The card test classes

Every score below is "n out of m" against one of three sets. The sets are not interchangeable and quoting a number without naming its set is how a model gets called good when it is not — a model has scored **7/7 on the everyday set while failing half the stress set**.

### 1. Everyday set — `temperature_matrix.dart`

Seven ordinary requests, one per common reply shape: a date+time ask (`Input.Date`), a size choice (`Input.ChoiceSet`), labelled specs (`FactSet`), a 4-row table, a 5-slice chart, a 1–5 rating, and a two-sentence prose answer. Run across three temperatures (`0`, `0.2`, `0.6`).

Use it to answer **"is this model usable at all?"** It is a smoke test. Any model being considered should pass it, and passing it proves very little — this is the set that does not discriminate.

### 2. Stress set — `temperature_stress.dart`

Five requests chosen because they are the ones that actually break, run at `t=0` and `t=0.6`:

| Case        | What it stresses                                                         |
| ----------- | ------------------------------------------------------------------------ |
| `codeblock` | Code plus an explanation — the shape that tempts a model to append prose |
| `bigtable`  | A 12-month table — long generation, where truncation shows up            |
| `nested`    | A full form: title, date, amount, 6-choice dropdown, notes, buttons      |
| `multiline` | Escaped `\n` and quoted text inside strings — the invalid-JSON classic   |
| `mixed`     | A table **then** a choice set — two structures in one reply              |

Use it to answer **"which model or setting should we ship?"** This is the set that separates candidates, and the one to re-run after any prompt change. It also counts distinct outputs per cell, which is how "temperature 0 is deterministic" was disproved.

### 3. Prompt A/B set — `prompt_ab.dart`

Eight code-flavoured prompts run against **two prompt files** — the shipped `card_system_prompt.txt` and an edited candidate — printing both pass rates.

Use it to answer **"did my wording change actually help?"** It is the only set that compares prompts rather than models, and it exists because a wording change that fixes the one case you were looking at can quietly break three others.

### 4. Multi-turn set — history replay

The server replays prior turns on every request (`OllamaResponder.reply()`), but sets 1–3 all send a **single turn**. That gap hid a whole failure class until 2026-08-14.

Measured on `qwen2.5-coder:7b` at `t=0`, asking "what are my options for deployment targets":

| History before the question | Result                           |
| --------------------------- | -------------------------------- |
| none                        | `card[2]` — an `Input.ChoiceSet` |
| 1 prose turn                | prose — 867 chars of Markdown    |
| 2 prose turns               | prose — 903 chars of Markdown    |

One prose turn is enough. Once a conversation is flowing in Markdown the model treats that as the established format. Two consequences worth internalising:

- **A cold-start pass proves less than it looks.** Reproduce with history before concluding a bug is fixed, and say which condition a number came from.
- **"Renderable prose" is not always a pass.** For an options question a tidy Markdown list renders perfectly and still fails the user, because it cannot be clicked. `shape_ab.dart` is the only probe that catches this — it requires the element type that answers the question, not merely a reply that parses.

Two changes were made in response, both still shipped. The card system prompt's escape hatch was re-keyed from _confidence_ ("if you are unsure whether a card helps") to _capability_ ("if no element type fits"), which is why it reads the way it does today. And the model's context now opens with a card-shaped exchange — see the seed below, which is what actually closed most of the gap.

#### Shape coverage — all fourteen models, as shipped

`shape_ab.dart` asks the narrow question the other probes cannot: for each of 25 cases, did the model emit an element type that actually answers it? It runs every case twice — cold-start and after two prose turns — and the difference is the shapes a model loses once a conversation has gone to Markdown.

**This is the current, as-shipped picture**, and the only model comparison in this file that is: all 25 cases, `t=0`, `--samples 2`, both conditions, with the unconditional card seed in place. Six models were measured 2026-08-18, the other eight 2026-08-19 under identical conditions. Sorted by with-history coverage, which is what a user actually experiences.

| Model                                               | Weights | Cold-start | With history | Warm, pre-seed | Eroded by history                            |
| --------------------------------------------------- | ------- | ---------- | ------------ | -------------- | -------------------------------------------- |
| `qwen3-coder:30b`                                   | 17.3 GB | **24/25**  | **23/25**    | —              | `rating_ask`, `time` (2)                     |
| `gpt-oss:20b`                                       | 12.8 GB | **24/25**  | **23/25**    | 22/25          | `gauge`, `table` (2)                         |
| `qwen3.6:27b-coding-nvfp4`                          | 18.4 GB | 23/25      | **23/25**    | —              | none                                         |
| `granite4.1:8b`                                     | 5.0 GB  | 21/25      | 22/25        | 15/25          | `carousel`, `table` (2)                      |
| `nemotron-3.5-lightning:30b`                        | 23.7 GB | 22/25      | 22/25        | 13/25          | `table` (1)                                  |
| `hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` | 22.9 GB | 21/25      | 22/25        | —              | none                                         |
| `nemotron-3-nano:30b`                               | 22.6 GB | 19/25      | 20/25        | —              | none                                         |
| `qwen2.5-coder:7b`                                  | 4.4 GB  | 21/25      | 19/25        | 18/25          | `carousel`, `table` (2)                      |
| `qwen3.5:9b`                                        | 6.1 GB  | 19/25      | 19/25        | —              | `badge`, `columnset` (2)                     |
| `granite4.1:3b`                                     | 2.0 GB  | 16/25      | 17/25        | —              | `number`, `text` (2)                         |
| `nemotron-3-nano:4b`                                | 2.6 GB  | 20/25      | 17/25        | —              | `codeblock`, `columnset`, `text`, `time` (4) |
| `llama3-groq-tool-use:8b`                           | 4.3 GB  | 15/25      | 16/25        | 9/25           | `progress`, `toggle` (2)                     |
| `llama3.2:latest`                                   | 1.9 GB  | 16/25      | 14/25        | —              | `badge`, `table` (2)                         |
| `llama3-chatqa:8b`                                  | 4.3 GB  | 3/25       | 1/25         | 2/25           | `gauge`, `progress` (2)                      |

**Warm, pre-seed** is the same measurement without the card seed, and it is the model's seed-dependence: `granite4.1:8b` and `nemotron-3.5-lightning:30b` gain 7 and 9 shapes from it, while `gpt-oss:20b` was already at 22/25 without it. A model that scores well only with the seed is being held up rather than being robust, which is the distinction the [top-three rationale](#why-these-three-after-the-25-case-sweep) turns on. The eight `—` cells were never measured pre-seed; `shape_ab.dart --no-seed-card` fills one in.

How to read the rest of it:

- **Weight class does not predict coverage.** `granite4.1:8b` at 5.0 GB scores 22/25, above four models of 22 GB or more. The two best 16 GB-capable models are `granite4.1:8b` (22/25) and then `qwen2.5-coder:7b` / `qwen3.5:9b` tied at 19/25.
- **Cold start does not predict with-history, in either direction.** `nemotron-3-nano:4b` drops three shapes warm while `nemotron-3-nano:30b` and `hf.co/unsloth/…` each gain one. Three models erode nothing at all. Judge on the with-history column.
- **`llama3-chatqa:8b` is why this probe exists.** It sweeps the everyday and stress sets — 7/7 at three temperatures, 5/5 stress at two — and produces a correct shape on 1 of 25 cases. Nothing about the model changed between those results; the measuring stick did.
- **Failure is concentrated in nested shapes.** `carousel`, `table`, and `columnset` account for most of what models never produce under either condition, almost always as invalid JSON rather than a wrong choice of element. `qwen3-coder:30b` is the only model measured with no case it fails under both conditions.
- **`rating_ask` is the most-failed case in the file.** Eight of the fourteen answer "ask me to rate this" with a read-only `Rating` display instead of an `Input.*` — the same show-versus-collect substitution, under both conditions, across unrelated model families. A failure that uniform is a prompt problem, and it is the clearest remaining lever in `assets/card_system_prompt.txt`.
- **`gauge` and `progress` never cross-contaminate**, on any model, despite sharing the "72%" wording.

#### The card seed, and what it costs

`OllamaResponder.reply()` prepends a synthetic card-shaped exchange — a short pick-from-a-set question and a bare card reply — ahead of the trimmed history on **every** request, so a card is the conversation's established format before any prose accumulates. Assembled order: system prompt, seed user turn, seed assistant turn, trimmed history, current user turn. There is no flag to disable it. The exchange lives in `assets/seed_card.json` and is read per request; `shape_ab.dart` reads the same asset and seeds by default, so a probe measures what the server sends.

It is the only mechanism that worked. Three prompt edits and one message-assembly alternative were screened against the drift alongside it and all four failed — restating the shape rule last, guarding the Markdown section's heading, narrowing the escape-hatch wording, and injecting a per-turn `system` reminder after the history. **Do not retry them**, and note the general shape of that result: changing _where the model's context starts_ moved behavior; changing _what the system prompt says_ did not, in either direction that mattered. (The per-turn reminder is additionally unmeasurable on some models — Ollama chat templates vary in whether a second `system` message placed after the history reaches the model at all, so a null result there means nothing.)

Four costs come with it and must not be read past:

1. **It costs tokens on every request, permanently.** This is few-shot priming prepended to each call, not one-time setup, and it counts toward `num_ctx` fill every time. Token cost was never measured directly; wall-clock across two runs showed the seed _faster_, which is uncontrolled and should be read as "not observed to be slower" rather than as evidence the tokens are free.
2. **`table` newly erodes with history on four of the six models it was A/B'd on.** The seed buys cold-start capability on nested shapes and then loses some of it warm.
3. **It over-cards the negative control.** A plain question that wants prose comes back as a card cold-start on five of fourteen models. Confirmed causal, not incidental, by re-running the single case both ways on `granite4.1:3b`: `--no-seed-card` passes it, the seed fails it. It costs at most 1/25 on any model's score, but it is the seed's one visible harm.
4. **It has never been measured above `t=0`.** Every shape run is greedy. `defaultCardTemperature` is `0.0` so an unconfigured server never leaves `t=0`, but this file records prompt fixes that held at `t=0` and failed at `t=0.6`, so the one is not a proxy for the other. Neither standing regression gate can cover this: `temperature_stress.dart` and `prompt_ab.dart` both send a single user turn and no seed history, so running them against the seed measures a file it never touches.

### Not a card test: the `format` canary

`json_format_probe.dart` asks a different question — does this model honour Ollama's `format` constraint at all? Some ignore it silently, with no error, which makes `--json-format json|schema` inert. Check it before trusting the constraint; it is a capability probe, not a quality score.

### What counts as a pass

A reply passes if it renders as a card **or** as clean prose. The card system prompt explicitly permits a Markdown answer, so only a _broken_ card is a failure. Verdicts come from the server's own detection, not the probe's opinion — see [How results are produced](#how-results-are-produced).

## Per-model results

### `qwen2.5-coder:7b` — recommended default (16 GB Mac)

Cleared every documented card failure mode at `temperature 0`, including the two that defeated `llama3.2`: checkbox `isMultiSelect:true` and the nested-array Carousel. ~9 s/call, non-thinking, 4.7 GB. Coder-tuned models are unusually strong at strict JSON syntax, which is exactly where the card path fails.

Honors Ollama's `format` constraint, so `--json-format json|schema` is meaningful for it.

Trade-off: coder models are terser on the plain-prose reply path. `qwen2.5:7b` (plain instruct, ~4.7 GB) is the better all-rounder if conversational answers matter more than maximal JSON reliability.

Measured on the code-explanation failure (August 2026): hard cases 6/10 → 15/15 at `t=0` and 7/10 → 14/15 at `t=0.6` after the card system prompt gave explanations a home inside the card.

**It fences its card almost every time.** Across two independent
investigations on 2026-08-14, the model wrapped its JSON in a ` ```json `
fence in 7/7 and 9/9 replies respectively, despite the prompt forbidding
fences in two places. This is currently harmless — `_stripFence` recovers a
reply that is _only_ a fence — but the detector is carrying a load the prompt
claims it should not have to, and fence-stripping has regressed here before
(see `a13808b`). Anything that follows the closing fence defeats the
recovery, which is why "nothing after the closing fence" is the load-bearing
rule rather than "no fence".

**A negative result, recorded so it isn't retried.** A candidate paragraph
teaching the prompt that a two-part request ("compare A and B, then tell me
which you'd pick") is still one message was measured on `qwen2.5-coder:7b` at
`t=0`. It tied baseline 10/10 on the compare-and-comment set (already at
ceiling under the corrected `judgeReply`, so there was no headroom left to
demonstrate an improvement) and it did improve the stress set's `t=0.6`
"mixed" compare-then-choice-set case (9/10 → 10/10, `t=0` unchanged at
10/10). But the built-in code A/B regression check (`prompt_ab.dart
--samples 1`, `t=0`) caught a real, reproducible regression the
compare-and-comment set could not see: "what is a closure? show an example"
went from a passing plain-Markdown reply to `prose-with-card` (raw JSON shown
to the user), 8/8 → 7/8, confirmed deterministic by repeating that one prompt
3 times against both prompt versions (baseline 3/3 pass, candidate 0/3 pass).
Per the promote-only-if-better rule the wording was reverted, not shipped —
`assets/card_system_prompt.txt` is unchanged (see `CHANGELOG.md`,
"Measured, not promoted").

The escape-hatch re-key that _was_ promoted (see [§4](#4-multi-turn-set--history-replay))
ran the same two regression checks clean — stress 10/10 at both `t=0` and
`t=0.6`, and the code A/B set 8/8 including the exact closure prompt the
compare-and-comment candidate above regressed.

### Six models probed 2026-08-14 (everyday + stress, `--samples 1`)

Run sequentially, one model resident at a time, card system prompt, on the 64 GB M1.

| Model                   | Everyday `t=0` / `0.2` / `0.6` | Stress `t=0` | Stress `t=0.6` |
| ----------------------- | ------------------------------ | ------------ | -------------- |
| llama3-chatqa:8b        | 7/7 · 7/7 · 7/7                | 5/5          | 5/5            |
| gpt-oss:20b             | 6/7 · 5/7 · 6/7                | 5/5          | 4/5            |
| granite4.1:8b           | 6/7 · 6/7 · 5/7                | 5/5          | 4/5            |
| llama3-groq-tool-use:8b | 6/7 · 6/7 · 6/7                | 5/5          | **1/5**        |
| nemotron-3-nano:4b      | 6/7 · 6/7 · 6/7                | **2/5**      | **1/5**        |
| granite4.1:3b           | 4/7 · 4/7 · 5/7                | 4/5          | 3/5            |

Three things this run showed:

- **`llama3-chatqa:8b` swept everything** — 7/7 at all three temperatures and 5/5 stress at both. At 4.3 GB it is the strongest cheap candidate measured so far and deserves a closer look against the default — but see the 2026-08-17 shape-coverage finding in [§4](#4-multi-turn-set--history-replay): on the broader 25-shape probe this model produces a correct card shape on only 1/25 cases cold-start, so this recommendation should not be acted on without reading that first.
- **The everyday set kept its reputation for not discriminating.** `nemotron-3-nano:4b` and `llama3-groq-tool-use:8b` both scored 6/7 everyday, then collapsed to 2/5 and 1/5 on the cases that matter. Judging either on the easy set alone would have been badly wrong.
- **`gpt-oss:20b`, a top-three model, had never been probed at all.** It is respectable but not better than models a third its size, which is worth knowing before recommending it.

All of these are **cold-start** numbers at `--samples 1`. None has been run with conversation history, and a single sample at `t=0.6` is noisy — treat the two 1/5 results as a flag to re-run, not a settled verdict.

### Large candidate models probed 2026-08-16 (everyday + stress, `--samples 1`)

Run one model resident at a time, card system prompt, on the 64 GB M1. This
table is the large-model (17-24 GB) counterpart to the 2026-08-14 table
above — same methodology, different date, extend it as more of these get
probed.

| Model                                             | Everyday `t=0` / `0.2` / `0.6` | Stress `t=0` | Stress `t=0.6` |
| ------------------------------------------------- | ------------------------------ | ------------ | -------------- |
| hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest | 7/7 · 7/7 · 6/7                | 3/5          | 3/5            |
| nemotron-3-nano:30b                               | 7/7 · 7/7 · 6/7                | 2/5          | 1/5            |
| nemotron-3.5-lightning:30b                        | 6/7 · 6/7 · 5/7                | 3/5          | 4/5            |
| qwen3-coder:30b                                   | 7/7 · 6/7 · 7/7                | 5/5          | 5/5            |

`hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` (22.9 GB) swept the
everyday set at `t=0`/`t=0.2` and only lost one case at `t=0.6` (a truncated
table — `Unexpected end of input`). The stress set is where it struggles:
3/5 at **both** temperatures, with `bigtable` and `mixed` failing at both
`t=0` and `t=0.6`. Those two failures share a pattern distinct from the
truncation above — an extra closing `]` after the last element (e.g.
`"wrap":true}]]}]`), as if the model occasionally double-wraps the final
item in an array. `codeblock`, `nested`, and `multiline` were clean at both
temperatures. Cold start alone would rank this model mid-pack — better than
`granite4.1:3b`, worse than the `llama3-chatqa:8b` / `gpt-oss:20b` /
`granite4.1:8b` tier — with the everyday set again failing to predict the
stress-set weakness, consistent with the 2026-08-14 finding above.

`nemotron-3-nano:30b` (22.6 GB) — the Ollama-library build, not the
`hf.co/unsloth` GGUF above — swept the everyday set identically: 7/7 at
`t=0`/`t=0.2`, and the same single `t=0.6` loss on the same case (`table`,
`Unexpected end of input` — a truncated response). The stress set is where
the two builds diverge: this one managed only 2/5 at `t=0` and 1/5 at
`t=0.6`, worse than the unsloth build's 3/5/3/5. The seven stress failures
do not reduce to one pattern. Two are outright truncation, with the parse
error landing exactly one character past the end of the response
(`bigtable` at `t=0`, `mixed` at `t=0.6`), both reported as `Unexpected end
of input`. A third (`nested` at `t=0.6`) also errors at the very last
character of a short, 171-character response, though the parser labels it
`Unexpected character` rather than `Unexpected end of input`. Three others
are mid-stream malformations inside otherwise-long, otherwise-plausible
responses — an extra closing bracket appears immediately before the comma
that starts the next sibling element (`nested` at `t=0`: `}] ,{`; `bigtable`
at `t=0.6`: `} },{`; `mixed` at `t=0` shows a similar bracket cluster ahead
of a comma, though less cleanly isolated than the other two). The seventh
(`codeblock` at `t=0.6`) is different again: the response opens with
`["TextBlock","text":...`, missing the `{"type":` wrapper on the first
array element entirely — a malformation none of the other six share.
`multiline` was the only stress case clean at both temperatures. Cold start
again fails to predict the with-history result below — and here it fails
in the opposite direction from the unsloth build (see there).

`nemotron-3.5-lightning:30b` (23.7 GB) is the weakest of the three large
candidates on the everyday set: 6/7 at `t=0`/`t=0.2` and 5/7 at `t=0.6`, one
notch below both `nemotron` 30B builds at every temperature. The `table`
case fails at all three temperatures (`Unexpected end of input`, a
truncated response), the only large candidate to lose it at `t=0` and
`t=0.2` as well as `t=0.6`; `t=0.6` adds a second loss on `date`, where the
response's second line switches to a Markdown checklist item
(`- [ ] 2025-01-18`) instead of continuing JSON, reported as `Unexpected
character (at line 2, character 1)`. The stress set inverts the ranking:
3/5 at `t=0` and 4/5 at `t=0.6`, the best stress result of the three large
candidates at either temperature. Of the three stress failures, two are
outright truncation reported as `Unexpected end of input` exactly one
character past the response's end (`bigtable` at both `t=0` and `t=0.6`);
the third (`nested` at `t=0`) is the same last-character variant already
seen in `nemotron-3-nano:30b`'s `nested`@`t=0.6` failure above — the parser
reports `Unexpected character` at the response's very last character rather
than past its end. `codeblock`, `multiline`, and `mixed` were clean at both
temperatures. So a weaker-than-both-siblings everyday score and a
better-than-both-siblings stress score, measured on the same model, land on
opposite sides of the large-candidate ranking — reinforcing rather than
resolving the everyday-set's-not-a-good-predictor finding above.

`qwen3-coder:30b` (17.3 GB, the smallest of the four large candidates by
weight) matches the two `nemotron` 30B builds' everyday total of 20/21
correct — 7/7 at `t=0` and `t=0.6`, with a single loss at `t=0.2` (`rating`,
`Unexpected character (at character 169)`: a `TextBlock` and an
`Input.ChoiceSet` concatenated on one line without the wrapping `[ ]`, the
same missing-array-brackets pattern documented in the with-history results
below) — and then posts a clean 5/5 stress sweep at both temperatures, a
result neither `nemotron` build reached (3/5 `t=0` and 3/5 `t=0.6` for the
unsloth GGUF, 2/5 `t=0` and 1/5 `t=0.6` for the Ollama-library build) and
the best large-candidate stress result on record — the only one of the four
large candidates to pass every stress case at both temperatures. Cold start
alone would rank it at or above every other large candidate.

### `qwen3.6:27b-coding-nvfp4`

**Scores worse at its own recommended temperature.** Its Modelfile ships `temperature 0.6`, but it passed 12/15 hard cases at `0` versus 9/15 at `0.6` — the extra failures being long card JSON truncated mid-generation. Both passed 7/7 easy cases, which is why the easy set alone is not a useful signal.

**Silently ignores `format`.** It answers the `format: json` canary with prose and no error, so `--json-format json|schema` is inert for it. Check the canary (`tool/model_probes/json_format_probe.dart`) before relying on the constraint.

It scores **23/25 cold and 23/25 with history** (2026-08-19, `--seed-card --samples 2`), eroding nothing — one of three in the 2026-08-19 sweep to erode no shape at all, alongside `hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` and `nemotron-3-nano:30b`. Its two permanent misses are `carousel` and `columnset`, both invalid JSON: the same deeply-nested ceiling as `gpt-oss:20b`, and consistent with the truncation-on-long-generations weakness recorded above.

### `qwen3.5:9b`

Usable **only with thinking disabled**, and even then offers no reliability edge over `qwen2.5-coder:7b` while costing more latency and memory. Its thinking capability is a liability for constrained-JSON output.

With server defaults of the time (temp 1, thinking on) it answered a checkbox request with a `CodeBlock` of raw HTML using invented keys (`codeLanguage`/`content` instead of `codeSnippet`), taking 77 s. The same model with `think:false` + `temperature:0` produced a clean `Input.ChoiceSet` and a clean 4-page Carousel in ~10 s.

On the shape set it scores **19/25 cold and 19/25 with history** — an exact tie with `qwen2.5-coder:7b` for 1.7 GB more weight, which is why it does not hold a `launch.json` slot. Probe runs send `think: false` unconditionally, so that figure is the thinking-off condition described above, not a thinking-on one.

Not recommended as the default for this workload, and no longer in `launch.json` — it was swapped out for `granite4.1:8b` on 2026-08-19.

### `llama3.2` (3.2B — the `llama3.2:latest` tag)

Retired as a default. Failed the shapes that matter: checkbox `isMultiSelect` 1/14, nested-array Carousel 0/5, table 1/4. FactSet and plain prose were reliable. The nested-array corruption family that motivated the duplicate-key guard reads as specific to this 3B model under hot sampling.

**Probed with history for the first time on 2026-08-19** (`shape_ab.dart --seed-card --samples 2`), having been retired before any multi-turn probe existed: **16/25 cold, 14/25 with history**, thirteenth of fourteen. It stays retired, but the retirement note above was written against a three-shape sample and reads harsher than the full picture — this is ordinary weakness, not the collapse `llama3-chatqa:8b`'s 1/25 represents. Nine shapes it never produces under either condition, including `date`, `text`, `codeblock`, and `rating_show`; `badge` and `table` additionally erode with history. It is also the only model that fails the `prose` negative control under **both** conditions, returning a card where the question wanted prose.

## Cross-model results

- **Decoding settings dominate model choice.** The single largest quality jump measured on this workload came from sending `temperature: 0` and `think: false`, not from changing model. A model that looks incapable at temp 1 with thinking on can be clean at temp 0.
- **Temperature 0 is not deterministic.** A ~3.5 K-character table produced two different outputs across three calls at `0`. Greedy decoding repeats short replies verbatim, but long generations still diverge. What `0` buys is a _stable failure mode_ — a card the model gets wrong at `0` is usually wrong the same way on retry, so a broken card never self-heals.
- **`format` support is per-model and silent when absent.** Some models ignore it with no error. Probe before relying on it.
- **Redirect a behavior rather than forbidding it.** Asked to explain code, `qwen2.5-coder:7b` emitted a card and then appended the explanation, which makes the whole reply raw text. Telling it harder not to append did **not** help — it scored the same and abandoned cards entirely, answering every code question as prose. Telling it where the explanation _goes_ (a `TextBlock` beside the `CodeBlock`) fixed it.
- **Wording moves the failure rate; only the detector makes a shape safe.** Each prompt fix exposes the next failure — once the model sent two elements it began dropping the `[ ]` around them. Prompt wording cut that to near zero at `t=0` but not at `t=0.6`, so `card_detect.dart` repairs the bracketless form as well.
- **Suspect the harness before the model.** A reply blamed on the model contained zero real newlines and 11 correctly escaped ones — valid JSON, corrupted by this server's own fence-stripping heuristic. Dump the bytes before theorising.
- **A failed assertion is sometimes a bad assertion.** One model's "0/3" on tables was a valid, complete, renderable Table laid out as a 2×2 grid; the `rows >= 3` success criterion wrongly penalized a legitimate layout.
- **A second `system` message is not universally delivered.** Ollama chat
  templates vary in whether a `system` message placed _after_ the conversation
  history reaches the model at all; some keep only the first. Checked
  2026-08-18 on the four screening models (`choice1`, cold-start) by injecting
  an additive reminder — "every card you send must also include a Badge
  element with the text 'OK'" — and reading `shape_ab.dart`'s printed type
  list with and without `--reinforce`. **Delivered** on `gpt-oss:20b` (`Badge`
  appears, both conditions). **Unconfirmed** on `qwen2.5-coder:7b` and
  `granite4.1:8b` — dropped-by-the-template and arrived-but-ignored are
  indistinguishable for them. **No suitable case** on `llama3-chatqa:8b`,
  whose only cold-start pass is the `prose` negative control. Consequence: a
  candidate that scores exactly at baseline on a delivery-unconfirmed model
  has not been meaningfully tested on it: "no effect" and "never arrived" are
  the same observation. Establish delivery before reading a null result from
  any candidate that relies on a second `system` message.
- **A delivery probe must not contradict the system prompt.** The first
  version of the check above asked the model to "disregard the question
  entirely, reply with only the single word BANANA" and produced a null on all
  four models — an uninformative null, because "the model resisted a
  contradiction" and "the message never arrived" produce the identical
  observation. An additive, prompt-compatible probe (add one harmless,
  checkable element) removes that confound and is the design to reach for
  first.

## How results are produced

All of the above come from [`tool/model_probes/`](tool/model_probes/README.md), whose scripts judge replies with the server's **own** `tryParseCardBody` / `cardParseFailureReason` / `checkNoDuplicateJsonKeys`. A probe that applied its own idea of "looks like a card" could report a pass rate the running server disagrees with, which is worse than no measurement.

A reply passes if it renders as a card **or** as clean prose — the card system prompt explicitly permits a Markdown answer, so only a _broken_ card is a failure.

Every figure here was collected with **one model resident at a time** — load a model, run all of its probes, record, then switch. Interleaving models or running probes concurrently distorts both pass rates and latencies, so a number collected that way is not comparable to anything in this file. The procedure and the reasoning behind it are in [`tool/model_probes/README.md`](tool/model_probes/README.md#run-one-model-at-a-time).

Measured on an M-series Mac against a local Ollama, August 2026. Latency figures include model load on a first call; re-run before trusting one.

## Sources

Full context for these findings, in the documents that produced them:

- [`tool/model_probes/README.md`](tool/model_probes/README.md) — the probe scripts and their "What these found" section
- `docs/archive/specs/2026-07-23-ollama-structured-json-output-design.md` — the `llama3.2` / `qwen3.5:9b` / `qwen2.5-coder:7b` comparison and the `format` findings
- `lib/src/ollama_responder.dart` — `defaultOllamaModel`, `defaultCardTemperature`, and `defaultKeepAlive` carry the reasoning for each default
- [`CHANGELOG.md`](CHANGELOG.md) — dated entries with the measurement that justified each change
