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

Read on the shipped configuration (`--seed-card` is unconditional since 2026-08-18), the [full-set table](#warm-start-drift--full-set-confirmation-2026-08-18) ranks by with-history shape coverage: `gpt-oss:20b` 23/25, `granite4.1:8b` 22/25, `nemotron-3.5-lightning:30b` 22/25, `qwen2.5-coder:7b` 19/25, `llama3-groq-tool-use:8b` 16/25, `llama3-chatqa:8b` 1/25.

- **`gpt-oss:20b` — kept, the strongest model measured.** Best on both axes (24/25 cold, 23/25 warm) and the only model with no measurable prose drift at all. Its weakness is a JSON-validity ceiling on deeply nested shapes, not conversation history. At 12.8 GB it stays a ❌ for a 16 GB host, so it earns a debugger slot without being a candidate for the compiled-in default.
- **`granite4.1:8b` — added.** 22/25 with history, second only to `gpt-oss:20b`, and it runs in 5.0 GB. It is the largest warm improvement of any 16 GB-capable model (15/25 → 22/25 under the seed) and it recovered every one of its baseline-eroded cases.
- **`qwen2.5-coder:7b` — kept.** Not the strongest anymore (19/25 warm, fourth), but it is the compiled-in default, the model every promotion decision in this file is gated on, and the smallest at 4.4 GB. Dropping it from the debugger would mean the default ships untested from the one place people launch by hand.
- **`qwen3.5:9b` — dropped.** It has never been run through `shape_ab.dart` at all; its only with-history number is a `choiceset_ab.dart` 5/6 on six prompts, against 25 shapes for everything above. Its own [per-model section](#qwen359b) already records it as usable only with thinking disabled and offering no reliability edge over `qwen2.5-coder:7b` at more latency and memory. Nothing in the sweep argues for the slot; measure it with `shape_ab.dart` before reconsidering.

**Is `nemotron-3.5-lightning:30b` the better large model? No — `gpt-oss:20b` keeps the slot.** The two tie on as-shipped warm coverage (22/25 vs. 23/25 is within the noise this file elsewhere refuses to read as a difference), so the tie has to be broken on everything else, and every other axis points the same way:

- **Half the weights.** 12.8 GB vs. 23.7 GB, for a better score.
- **It does not depend on the seed to get there.** `gpt-oss:20b` scored 22/25 warm _before_ `--seed-card` existed, with zero shapes eroded by history. `nemotron-3.5-lightning:30b` scored 13/25 — the most severe erosion recorded anywhere in this file, losing all six choice cases plus two more — and only reaches 22/25 because the seed recovers all eight. One model is robust; the other is being held up.
- **Its narrower with-history record is a total collapse.** 0/6 on `choiceset_ab.dart` against `gpt-oss:20b`'s 6/6 — tied for the best of the thirteen models measured there.
- **It is weaker cold, too.** Stress 3/5 at `t=0` against `gpt-oss:20b`'s 5/5, and a `table` case that fails at all three temperatures on the everyday set.

The one thing `nemotron-3.5-lightning:30b` is genuinely best at is being the **regression canary for the seed mechanism itself**: nothing else in the table swings +9 warm shapes on it, so if `--seed-card` ever silently stops working, this model shows it first and loudest. That is a reason to keep probing it, not a reason to launch it.

## Candidate models

Chat models worth probing when they happen to be installed. Check availability before assuming a result applies — the command lists everything Ollama has, so embedding models (`nomic-embed-text`, and anything else that cannot hold a conversation) will show up there and are deliberately absent from the table below:

```bash
curl -s http://127.0.0.1:11434/api/tags | python3 -c "import sys,json;[print(m['name']) for m in json.load(sys.stdin)['models']]"
```

**Role** says why the model is on the list. **Cold start** and **With history** are the short version of the [per-model results](#per-model-results) below — `—` means nobody has probed that condition yet, which is an invitation, not a judgement.

**16 GB** is a _portability_ signal, not a limit on what can be tested here. It answers "would this model run for someone on a 16 GB Mac or a 16 GB GPU?", which matters for what the server can reasonably recommend as a default. The current development machine is a **64 GB M1**, where every model in this table runs comfortably on its own — including the ❌ rows. A ❌ means "do not make this the recommended default", not "cannot be probed".

Sorted by model name, and within a family by parameter count ascending (so `nemotron-3-nano:4b` precedes `:30b`), which makes a tag quick to find. Role and verdict, not position, carry the meaning.

| Model                                             | Weights | 16 GB | Role                   | Cold start                                                 | With history                                               |
| ------------------------------------------------- | ------- | ----- | ---------------------- | ---------------------------------------------------------- | ---------------------------------------------------------- |
| gpt-oss:20b                                       | 12.8 GB | ❌    | top 3 (`launch.json`)  | ⚠️ everyday 6/7 · stress 5/5 `t=0`, 4/5 `t=0.6`            | ✅ shapes **23/25** · 6/6 choice-set (pre-seed)            |
| granite4.1:3b                                     | 2.0 GB  | ✅    | candidate              | ❌ everyday 4/7 · stress 4/5 `t=0`, 3/5 `t=0.6` — weakest  | ⚠️ 3/6 choice-set                                          |
| granite4.1:8b                                     | 5.0 GB  | ✅    | top 3 (`launch.json`)  | ⚠️ everyday 6/7 · stress 5/5 `t=0`, 4/5 `t=0.6`            | ✅ shapes **22/25** · 3/6 choice-set (pre-seed)            |
| hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest | 22.9 GB | ❌    | candidate              | ❌ everyday 7/7 · stress 3/5 `t=0`, 3/5 `t=0.6`            | ❌ 1/6 choice-set                                          |
| llama3-chatqa:8b                                  | 4.3 GB  | ✅    | candidate              | ✅ everyday 7/7 all temps · stress 5/5 both — clean sweep  | ❌ shapes **1/25** · 0/6 choice-set (pre-seed)             |
| llama3-groq-tool-use:8b                           | 4.3 GB  | ✅    | candidate              | ⚠️ everyday 6/7 · stress 5/5 `t=0` but **1/5** at `t=0.6`  | ⚠️ shapes **16/25** · 0/6 choice-set (pre-seed)            |
| llama3.2:latest                                   | 1.9 GB  | ✅    | candidate              | ❌ Retired as default — failed nested and multi-select     | — not yet probed                                           |
| nemotron-3-nano:4b                                | 2.6 GB  | ✅    | candidate              | ❌ everyday 6/7 but stress **2/5** `t=0`, 1/5 `t=0.6`      | ❌ 0/6 — drops to prose                                    |
| nemotron-3-nano:30b                               | 22.6 GB | ❌    | candidate              | ❌ everyday 7/7 · stress 2/5 `t=0`, 1/5 `t=0.6`            | ⚠️ 5/6 choice-set                                          |
| nemotron-3.5-lightning:30b                        | 23.7 GB | ❌    | candidate              | ❌ everyday 6/7 · stress 3/5 `t=0`, 4/5 `t=0.6`            | ✅ shapes **22/25** · 0/6 choice-set (pre-seed)            |
| qwen2.5-coder:7b                                  | 4.4 GB  | ✅    | server default + top 3 | ✅ Recommended — cleared every documented failure at `t=0` | ⚠️ shapes **19/25** · 3/6 choice-set (pre-seed)            |
| qwen3-coder:30b                                   | 17.3 GB | ❌    | candidate              | ⚠️ everyday 7/7 · stress 5/5 `t=0`, 5/5 `t=0.6`            | ⚠️ 2/6 choice-set — bracket omission, not prose            |
| qwen3.5:9b                                        | 6.1 GB  | ⚠️    | candidate              | ⚠️ Only with thinking off; no edge over the default        | ⚠️ 5/6 choice-set — one miss: TextBlock list, no ChoiceSet |
| qwen3.6:27b-coding-nvfp4                          | 18.4 GB | ❌    | candidate              | ⚠️ Ignores `format`; better at `t=0` than its own `0.6`    | ✅ 6/6 choice-set                                          |

**Cold start** is a single-turn probe. **With history** replays prior conversation turns the way the server actually does. These are different measurements and a model can pass one while failing the other — every result recorded before 2026-08-14 is a cold-start number, because no probe sent history at all.

**Read the `shapes N/25` figure first where a cell has one.** It is the model's with-history score **as the server ships today** — all 25 shapes, `t=0`, `--samples 2`, measured with the unconditional card seed in place (`--seed-card`, promoted 2026-08-18) — so it describes what a user actually gets. The six models carrying one are the six in the [full-set table](#warm-start-drift--full-set-confirmation-2026-08-18); the ✅/⚠️/❌ on those rows is set from it (✅ ≥ 20/25, ⚠️ 10-19, ❌ < 10), not from the choice-set score beside it.

The `N/6` **choice-set** figure is a narrower, older measurement kept for the models that have nothing better: `choiceset_ab.dart`, six options prompts, `t=0`, `--samples 1`, two prior prose turns, against `assets/card_system_prompt.txt` after Task 7's escape-hatch re-key. Every one of them is **pre-seed** and none has been re-run since, which is why two rows now look self-contradictory — `nemotron-3.5-lightning:30b` and `llama3-groq-tool-use:8b` both scored 0/6 there and both recover their entire choice-set path once the seed is in front of them. Where the two disagree, the shape figure is the current one.

`qwen2.5-coder:7b`'s cell was the one exception until 2026-08-17: Task 7 had measured it at `--samples 2` (6 prompts × 2 = `6/12`), because that number gated a promote-or-revert decision and wanted two samples per prompt. It has since been re-run at `--samples 1` for comparability and scores **3/6** — the same three prompts passing and the same three failing as in the 12-trial run, so the normalization is a change of denominator, not of finding. The `2/12 → 6/12` before/after that justified the escape-hatch fix is preserved in §4.

## Test one model at a time

Local RAM holds one mid-size model. Load a model, run **all** of its tests, record the results, then switch — do not interleave models and do not run probes against several models concurrently.

Interleaving makes Ollama evict and reload weights between calls, and a reload costs roughly **20x** the warm load time (the reason `defaultKeepAlive` is 30 minutes rather than Ollama's 5). Concurrent runs are worse still: the calls queue regardless, the memory pressure makes the whole set slower than running it serially, and the contention distorts the latency numbers you were trying to collect.

This holds regardless of how much memory the host has. On the 64 GB development machine every model in the table fits **individually**, but the two largest together (≈24 GB each) would sit near the usable Metal budget, and Ollama would still evict and reload when the tag changes. The rule is about the reload cost and the measurement noise, not only about a hard ceiling.

The **16 GB** column is not a gate on what to probe here — it records what a constrained host could run. Probing a ❌ model on this machine is expected and useful; it is how the matrix gets filled in. What the column governs is what the server should _recommend_ as a default, since a default that only runs on a 64 GB box is not much of a default.

```bash
for m in qwen2.5-coder:7b granite4.1:8b; do
  fvm dart run tool/model_probes/temperature_stress.dart --model "$m" --samples 3
done
```

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

One prose turn is enough. Once the conversation is flowing in Markdown the model treats that as the established format, and the shipped prompt permitted it because its escape hatch was keyed on _confidence_ ("if you are unsure whether a card helps") rather than on capability.

Two consequences worth internalising:

- **A cold-start pass proves less than it looks.** Reproduce with history before concluding a bug is fixed, and say which condition a number came from.
- **"Renderable prose" is not always a pass.** For an options question a tidy Markdown list renders perfectly and still fails the user, because it cannot be clicked. The generic sets score it `prose` = pass; only a shape-aware check catches it. `choiceset_ab.dart` scores strictly — the reply must be a card _containing_ an `Input.ChoiceSet`.

Six more models were run through the same `choiceset_ab.dart` probe on 2026-08-16 (`t=0`, `--samples 1`, two prose turns before the question, against `assets/card_system_prompt.txt` _after_ Task 7's escape-hatch re-key below had already been promoted — these are post-fix numbers, not a "before" baseline for a fix still to come), to see whether the collapse above is specific to `qwen2.5-coder:7b` or a property of the workload. The result does not round into a tidy conclusion: `gpt-oss:20b` held up completely at ✅ 6/6, while `llama3-chatqa:8b` — the model that had swept the cold-start everyday and stress sets 7/7 and 5/5 — collapsed to ❌ 0/6, the same total-collapse pattern already on record for `qwen2.5-coder:7b`. `llama3-groq-tool-use:8b` and `nemotron-3-nano:4b` also collapsed to 0/6. `granite4.1:8b` and `granite4.1:3b` landed in between at ⚠️ 3/6, each losing half their cold-start options answers to prose. A ranking built only from cold-start numbers would have placed `llama3-chatqa:8b` above `gpt-oss:20b`; with history the order inverts. Sanity-checking the best performer, `gpt-oss:20b`, cold-start with `dump_reply.dart` confirmed the same question still returns `card[2]` with zero history — so its strength with history is a real property of the model, not an artifact of a weak cold-start baseline. History erosion is real and, across this run, the majority case: three of six models collapsed completely (0/6), two more were partially degraded (3/6), and only one of six (`gpt-oss:20b`) was unaffected — the failure mode is per-model, not a property of "local models" in general, and a model's cold-start score is not a reliable predictor of which side it lands on.

A seventh model, `hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` (22.9 GB), was run through the same `choiceset_ab.dart` probe separately on 2026-08-16, as part of a follow-up sweep of large models that had never been probed at all — same conditions (`t=0`, `--samples 1`, two prose turns before the question, `assets/card_system_prompt.txt` post-Task-7). It scored ❌ 1/6: one pass ("what are my options for deployment targets" → `card[2]`), two prose fails ("which log level should I use?", "what build modes can I choose from?"), one valid card that omitted the `Input.ChoiceSet` ("what are my options for notification frequency" → `card[1]`), and two broken-JSON fails ("what environments can I deploy to?", "help me pick a database engine"). Unlike `llama3-chatqa:8b`'s collapse from a strong cold start, this model's cold start already flagged fragility — it only managed 3/5 on the stress set at both temperatures (see the large-model table above) — so cold start and multi-turn behavior point the same direction here rather than diverging.

An eighth model, `nemotron-3-nano:30b` (22.6 GB, the Ollama-library build rather than the `hf.co/unsloth` GGUF above), was run through the identical `choiceset_ab.dart` conditions on 2026-08-16. It scored ⚠️ 5/6, missing only one prompt ("which log level should I use?" → prose); the other five all returned a card containing the `Input.ChoiceSet` ("what are my options for deployment targets" → `card[2]`, "what environments can I deploy to?" → `card[2]`, "what are my options for notification frequency" → `card[2]`, "help me pick a database engine" → `card[2]`, "what build modes can I choose from?" → `card[1]`). This complicates the cold-start-doesn't-predict-multi-turn finding rather than confirming it: this build's cold start was, if anything, weaker than the unsloth build's — identical everyday numbers but a worse stress result (2/5 `t=0`, 1/5 `t=0.6` versus 3/5/3/5) — yet its multi-turn score is the strongest of any candidate model probed with history except `gpt-oss:20b`'s clean 6/6. Two builds of the same nominal model, probed under identical conditions, land at opposite ends of the with-history scale: 1/6 for the unsloth GGUF, 5/6 for the Ollama-library build. That rules out treating "cold start predicts multi-turn" as even a same-model-family heuristic — it does not hold within one model name, let alone across models.

A ninth model, `nemotron-3.5-lightning:30b` (23.7 GB), was run through the identical `choiceset_ab.dart` conditions on 2026-08-16. It scored ❌ 0/6 — every one of the six prompts dropped to prose with no card attempted at all, the same total-collapse pattern already on record for `qwen2.5-coder:7b` (pre-fix), `llama3-chatqa:8b`, `llama3-groq-tool-use:8b`, and `nemotron-3-nano:4b`. Its cold start was, on the everyday and stress sets, the weakest of the three large candidates probed so far (everyday 6/7 · 6/7 · 5/7, versus 7/7 · 7/7 · 6/7 for both `nemotron` 30B builds), yet its stress-set score (3/5 `t=0`, 4/5 `t=0.6`) was actually the strongest large-candidate stress result on record — better than either `nemotron` 30B build's. So within this one model, a mediocre everyday score and a comparatively strong stress score both point away from the total with-history collapse that actually happened: neither cold-start measure predicted it, in either direction.

A tenth model, `qwen3-coder:30b` (17.3 GB), was run through the identical `choiceset_ab.dart` conditions on 2026-08-16. It scored ⚠️ 2/6, but its failure mode is unlike every model probed before it: none of the four failures dropped to prose — all four attempted a card and failed the same way, a `TextBlock` and an `Input.ChoiceSet` placed on separate lines and joined by a real newline instead of being wrapped in `[ ]` and joined by a comma (`invalid JSON: FormatException: Unexpected character (at line 2, character 1)`), the missing-array-brackets pattern already on record in the cross-model findings below. Three of those four failures — "what are my options for deployment targets", "what environments can I deploy to?", and, most tellingly, "help me pick a database engine" — returned identical content to each other, re-confirmed with a fresh `dump_reply.dart` run per prompt against the same two-turn history (full transcripts in the probe report). Stripped of the missing wrapping `[ ]` and with the connecting comma swapped for the model's real newline, all three replies are character-for-character identical to the worked example on line 28 of `assets/card_system_prompt.txt` — same `TextBlock` text, same `Input.ChoiceSet` `id: "target"`, same `Staging`/`Production` choice titles and values, confirmed by direct string comparison against the prompt file. That the database-engine question, with no lexical overlap with "deployment target", produced this exact reused example rather than any database-flavored content shows the model reciting the system prompt's own demonstration instead of generalizing from it. The fourth failure ("which log level should I use?") was topically on point (`id: "logLevel"`, choices `DEBUG`/`INFO`/`WARN`/`ERROR`) but shared the identical missing-bracket malformation. The two passes ("what are my options for notification frequency", "what build modes can I choose from?") each needed only a single element and so had no array to omit. This model's cold start was the strongest large-candidate result on record (see below), and its with-history score neither collapses to prose nor holds that strength — a third distinct with-history failure signature (echoed-example bracket omission) alongside the total-prose-collapse and choice-set-omission patterns already on record in this file.

An eleventh model, `qwen3.5:9b` (6.1 GB), was run through the identical `choiceset_ab.dart` conditions on 2026-08-16. Every probe in this directory sends `think: false` unconditionally — `probeOnce` in `tool/model_probes/probe_support.dart` hardcodes it into the request body, and `choiceset_ab.dart --help` offers no separate thinking flag to override that — which for this particular model is not incidental: its own per-model note below already records it as usable **only** with thinking disabled, so this run measures the same thinking-off condition as that finding, not a different, thinking-on one. It scored ⚠️ 5/6, missing only "what build modes can I choose from?": the reply was a valid single-element card (`card[1]`) whose element was a `TextBlock` holding a numbered Markdown list of three build modes (Debug/Release/Staging) rather than an `Input.ChoiceSet`, confirmed with `dump_reply.dart` — the same renderable-but-unclickable shape called out above, here packaged inside a card element instead of returned as bare Markdown. The other five prompts each returned a card containing the `Input.ChoiceSet` ("what are my options for deployment targets" → `card[2]`, "which log level should I use?" → `card[1]`, "what environments can I deploy to?" → `card[2]`, "what are my options for notification frequency" → `card[1]`, "help me pick a database engine" → `card[2]`). This ties `nemotron-3-nano:30b` for the second-best with-history score of any candidate model measured with `choiceset_ab.dart` — only `gpt-oss:20b`'s clean 6/6 is higher.

A twelfth and final model, `qwen3.6:27b-coding-nvfp4` (18.4 GB), was run through the identical `choiceset_ab.dart` conditions on 2026-08-16. It scored ✅ 6/6, a clean sweep matching `gpt-oss:20b`'s — every prompt returned a two-element card (`card[2]`) containing an `Input.ChoiceSet` ("what are my options for deployment targets", "which log level should I use?", "what environments can I deploy to?", "what are my options for notification frequency", "help me pick a database engine", "what build modes can I choose from?"), leaving none of the truncation its own per-model section below already flags as its weak spot at its Modelfile-recommended `t=0.6` — unsurprising, since this probe runs at `t=0`, the temperature where that same section records it doing better, not worse.

With this model, and with `qwen2.5-coder:7b`'s cell normalized to the same `--samples 1` denominator on 2026-08-17, thirteen models have now been measured under `choiceset_ab.dart`'s with-history condition (`t=0`, `--samples 1`, two prior prose turns, `assets/card_system_prompt.txt` post-Task-7). The thirteen scores do not cluster around a single outcome, and they also don't spread evenly — the actual distribution has real gaps in it: four collapsed completely to 0/6 prose (`llama3-chatqa:8b`, `llama3-groq-tool-use:8b`, `nemotron-3-nano:4b`, `nemotron-3.5-lightning:30b`), five landed in a partial band of 1/6-3/6 (`hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest` 1/6, `qwen3-coder:30b` 2/6, `granite4.1:3b` 3/6, `granite4.1:8b` 3/6, `qwen2.5-coder:7b` 3/6), and four held up strongly at 5/6 or 6/6 (`nemotron-3-nano:30b` 5/6, `qwen3.5:9b` 5/6, `gpt-oss:20b` 6/6, `qwen3.6:27b-coding-nvfp4` 6/6) — no model scored 4/6 at all, so the three bands are a property of the actual scores, not an arbitrary cut. That is a 4/5/4 split: close to even, with the partial band the largest by one, and emphatically not the "mostly collapses" picture the first few models in this sweep suggested. Weight class doesn't sort into the bands either: the five large (17-24 GB) candidates measured with history split across all three themselves — one collapse (`nemotron-3.5-lightning:30b`), two partial (`hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest`, `qwen3-coder:30b`), two strong (`nemotron-3-nano:30b`, `qwen3.6:27b-coding-nvfp4`). Family is a more mixed picture, and the two same-family pairs in this table point different ways: the three models carrying the `nemotron-3-nano` name land in three different bands (`nemotron-3-nano:4b` collapse, the `hf.co/unsloth` 30B build partial, the Ollama-library 30B build strong), but `granite4.1`'s two sizes do the opposite — `granite4.1:3b` and `granite4.1:8b` land in the identical partial band at the identical 3/6 score, clustering rather than spreading. Cold-start performance was already shown above not to predict with-history robustness for individual models; across the full thirteen, weight class still doesn't either — family sends a genuinely mixed signal, spreading a model apart in one case and clustering it in the other, so it isn't a reliable predictor in either direction.

Re-keying the escape hatch from confidence to capability moved
`qwen2.5-coder:7b` from **2/12 to 6/12** on the options set with prior prose
turns (`choiceset_ab.dart --samples 2`, `t=0`) — 3 of 6 prompts now pass both
samples ("what are my options for deployment targets", "what environments
can I deploy to?", "what are my options for notification frequency") while
the other 3 still fail both samples ("which log level should I use?", "help
me pick a database engine", "what build modes can I choose from?"). The
2/12 baseline is this run's own live measurement, not the original
2026-08-14 investigation's 0/6 — the same order of magnitude but not
identical, ordinary run-to-run variance rather than a discrepancy in method.
The fix clearly helps but does not close the gap for every phrasing tested;
regression checks on this same prompt change (stress and code A/B) were
clean — see the `qwen2.5-coder:7b` section above.

That `6/12` was re-measured at `--samples 1` on 2026-08-17 so the table cell
would share a denominator with every other model, and scored **3/6** — the
same three prompts passing ("what are my options for deployment targets",
"what environments can I deploy to?", "what are my options for notification
frequency") and the same three failing ("which log level should I use?",
"help me pick a database engine", "what build modes can I choose from?") as
in the 12-trial run. The two runs agree prompt-for-prompt, so the `--samples
2` figure and the `--samples 1` figure are the same finding at different
resolutions; the `2/12 → 6/12` pair above is kept because it is the
before/after that actually justified promoting the escape-hatch change.

#### Shape coverage — all 25 shapes, `shape_ab.dart`

The probes above judge a reply as "renders or not". That left 23 of the 24
advertised element types unverified, and it credits a tidy Markdown answer to
"what are my options" as a pass. `shape_ab.dart` asks the narrower question:
for each of 25 cases, did the model emit an element type that actually answers
it? It runs every case twice — cold-start and after two prose turns — and
derives the shapes a model produces cold and then loses with history.

All six models, shipped prompt, `t=0`, no seed. **Eroded** = passed cold,
failed with history; **never produced** = failed both conditions.

| Model                        | Samples | Cold-start | With history | Eroded by history                                                           | Never produced                                                        |
| ---------------------------- | ------- | ---------- | ------------ | --------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `gpt-oss:20b`                | 1       | 20/25      | 22/25        | none                                                                        | `carousel`, `table`, `columnset` (3, all broken JSON)                 |
| `nemotron-3.5-lightning:30b` | 2       | 21/25      | 13/25        | `choice1`-`choice6`, `facts`, `time` (8)                                    | 4, incl. `table` (broken JSON both)                                   |
| `qwen2.5-coder:7b`           | 1       | 19/25      | 18/25        | `choice2`, `choice5`, `choice6` (3, all to prose)                           | `carousel`, `columnset`, `rating_ask`, `text` (4)                     |
| `granite4.1:8b`              | 1       | 18/25      | 15/25        | `choice1`, `choice5`, `number` (to prose), `columnset` (to wrong shape) (4) | `text`, `choice2`, `rating_ask`, `carousel`, `table`, `codeblock` (6) |
| `llama3-groq-tool-use:8b`    | 2       | 10/25      | 9/25         | `columnset` (1)                                                             | 15, incl. all six `choice*` cases                                     |
| `llama3-chatqa:8b`           | 1       | 1/25       | 2/25         | none                                                                        | 23 of 25 (22 scored flat `prose` under both conditions)               |

The four `--samples 1` rows were measured 2026-08-17; the two `--samples 2`
rows 2026-08-18, when `nemotron-3.5-lightning:30b` and
`llama3-groq-tool-use:8b` were baselined alongside the N2 run below.

**Four different mechanisms, not one spectrum.** `gpt-oss:20b` sweeps nearly
everything under both conditions and erodes nothing; all 8 of its failing
instances are malformed JSON on the three most deeply nested shapes — a
JSON-validity ceiling on long generations, present cold and unchanged warm.
`nemotron-3.5-lightning:30b` is the most severe erosion recorded anywhere in
this file: a cold-start score matching `qwen2.5-coder:7b`'s that loses every
choice case plus two more to history. `qwen2.5-coder:7b` and `granite4.1:8b`
are the textbook prose-drift shape — cold-strong, warm-weaker, tied at 3
shapes eroded specifically to prose. `llama3-chatqa:8b` is none of these: at
1/25 cold there is essentially no card path to erode.

**`llama3-chatqa:8b` is the case that justifies this probe existing.** The
same model scored a clean 7/7 everyday · 5/5 stress sweep on the narrower sets
(2026-08-14) and 1/25 here. Nothing changed about the model — the measuring
stick did. Under [What counts as a pass](#what-counts-as-a-pass) a well-formed
prose reply is credited, and 24 of its 25 cold-start replies were exactly
that; `shape_ab.dart` additionally requires the requested element. This is the
first probe here that can tell "produces good cards" apart from "answers in
prose and gets credited for it".

Cross-model per-case findings:

- **Show-a-rating vs. collect-a-rating is a systematic confusion.**
  `rating_ask` drew a read-only `Rating` display instead of an
  `Input.ChoiceSet`/`Input.Number` under both conditions on both
  `qwen2.5-coder:7b` and `granite4.1:8b` — not history-related drift.
- **`gauge` and `progress` never cross-contaminated**, on any model, despite
  sharing the "72%" wording — the two shapes land in their own buckets
  wherever a valid card came back at all.
- **Failure modes shift without passing.** `qwen2.5-coder:7b`'s `text` went
  `no-input` cold to `prose` warm; `granite4.1:8b`'s `codeblock` went broken
  JSON cold to `prose-with-card` warm; `llama3-chatqa:8b`'s `progress` went
  `prose` cold to `prose-with-card` warm. A case can get worse under history
  without ever having worked.
- **Six cases inverted — failing cold, passing warm** (`qwen2.5-coder:7b`:
  `number`, `table`; `gpt-oss:20b`: `gauge`, `rating_show`; `granite4.1:8b`
  and `llama3-chatqa:8b`: `pie`). At `--samples 1` these may be call-to-call
  variance rather than a real history effect; they are recorded rather than
  forced into either bucket, and they matter below because one of them
  (`table`) turns out to decide a promotion reading.

#### Warm-start prose drift — five candidates, one survivor

The drift is the failure §4 above records: once a conversation is flowing in
Markdown, models keep answering in Markdown even when the current question
wants a card. Five mechanisms were screened against it on 2026-08-17 — three
prompt edits and two message-assembly changes — over a six-case subset
(`choice1`, `choice2`, `date`, `table`, `carousel`, `gauge`) at `t=0`, both
conditions, via `shape_ab.dart`. `qwen2.5-coder:7b` at `--samples 2` decides
(it is the server default); `granite4.1:8b` (a second erosion data point),
`gpt-oss:20b` (harm control), and `llama3-chatqa:8b` (absolute-improvement
floor) inform at `--samples 1`. Full text of every candidate is in
`docs/superpowers/specs/2026-08-17-warm-start-prose-drift-experiment-design.md`.

**P1 · Recency** — a prompt edit appending a new final section ("Before you
answer: pick the shape") so the shape rule is the last thing read before
generation, on the hypothesis that the rule loses to distance. Deliberately
not an extra pre-send checklist item: that checklist is on the card path only,
so a model that has already drifted to Markdown never reaches it. **Failed.**
Flat on the deciding model (`choice2` still fails both samples) and the worst
of the five on harm control — `gpt-oss:20b` dropped with-history 5/6 → 3/6 and
cold-start 3/6 → 2/6, including a `choice1` cold-start `HTTP 500` seen under
no other config. Appending another section to an already-long prompt degrades
the strongest model without fixing the weak one.

**P2 · Guard the destination** — a prompt edit inserting a "do NOT use this
shape when the current question asks the user to choose, pick, enter,
schedule, or rate something … even when every earlier turn was Markdown"
clause directly beneath the `## Reply shape 2: Plain Markdown` heading, on the
hypothesis that the Markdown section is an attractor read last and read
invitingly. **Failed.** Flat on both erosion models; its only movement was a
single `gauge` pass on the floor model. A guard placed immediately after the
heading did not stop the model choosing that heading's shape once history
existed.

**P3 · Close the rationalization route** — a prompt edit extending the escape
hatch to say it is an escape for shapes the element list cannot express, not a
preference ("a Markdown bullet list is never the fitting answer to _what are
my options_"), on the hypothesis that "if no element type fits" is
rationalizable. **Failed, but harmlessly.** Flat on both erosion models and
the only prompt candidate that left `gpt-oss:20b`'s with-history score
untouched (its cold-start even rose). Safe but inert on the case that matters;
if the escape-hatch wording is revisited it should be paired with a mechanism
that actually moves `choice2`, not run solo.

**N1 · Per-turn reinforcement** (`shape_ab.dart --reinforce`) — a message
assembly change injecting a `role: system` reminder after the replayed history
and immediately before the current user turn, so the rule sits adjacent to
generation rather than behind N turns. **Failed on the deciding model, but the
null is unreadable there**: `qwen2.5-coder:7b` is one of the models where a
second `system` message is not confirmed to be delivered at all (see
[Cross-model results](#cross-model-results)), so "no measured effect" and
"never arrived" are indistinguishable. It produced the strongest clean result
of any candidate on `granite4.1:8b` — valid-subset with-history 2/3 → 3/3,
`choice1` recovering fully, cold-start unchanged — which is itself evidence
the reminder _is_ delivered there. Worth revisiting only if `granite4.1:8b`
becomes a target model in its own right.

**N2 · Card-shaped history seed** (`shape_ab.dart --seed-card`) — a message
assembly change prepending one synthetic exchange (a short pick-from-a-set
question and a bare card-shaped assistant reply) ahead of the real history, so
a card is the conversation's established format before any prose accumulates.
The seed's subject is unrelated to every case prompt, so a pass cannot come
from copying its content — only its format transfers. **The only candidate
that moved the deciding model**, and it held at full scale. Server-side it is
few-shot priming prepended to every request, so it costs tokens permanently.
**Promoted** — see below.

**What worked and what didn't, in one line.** Changing _where the model's
context starts_ moved behavior; changing _what the system prompt says_ —
restated (P1), repositioned (P2), or narrowed (P3) — did not, on any model, in
either direction that mattered. That is the same shape as the
"[redirect a behavior rather than forbidding it](#cross-model-results)"
finding already on record here.

Six-case screen, every cell with-history/cold-start, raw counts out of 6:

| Candidate | `qwen2.5-coder:7b` (decides, n=2) | `granite4.1:8b` (informs) | `gpt-oss:20b` (informs) | `llama3-chatqa:8b` (informs) |
| --------- | --------------------------------- | ------------------------- | ----------------------- | ---------------------------- |
| baseline  | 4/4                               | 2/3                       | 5/3                     | 0/0                          |
| P1        | 3/5                               | 2/4                       | 3/2                     | 0/0                          |
| P2        | 3/4                               | 2/4                       | 4/4                     | 1/0                          |
| P3        | 3/4                               | 2/3                       | 5/4                     | 1/0                          |
| N1        | 3/4                               | 4/3                       | 4/2                     | 1/1                          |
| N2        | 4/6                               | 4/6                       | 4/5                     | 0/1                          |

**Read the raw six on a corrected denominator.** A case a model cannot produce
cold-start is not a drift case — it never worked, so it cannot be eroded.
Checked against each model's 25-case baseline above: `carousel` is excluded
for `qwen2.5-coder:7b`, and `choice2`/`table`/`carousel` for `granite4.1:8b`.
On `granite4.1:8b`'s valid-3 subset (`choice1`, `date`, `gauge`), baseline and
all three prompt candidates sit at 2/3 while **N1 and N2 both reach 3/3**,
with cold-start unchanged — `choice1`, that model's clearest prose erosion,
recovers under both. On `qwen2.5-coder:7b` the reading depends on one
contested case:

- **valid-4** (`choice1`, `choice2`, `date`, `gauge` — the screen's own
  applied rule, excluding any case that failed cold-start): baseline 3/4, all
  of P1/P2/P3/N1 3/4, **N2 4/4**, cold-start 4/4 throughout. N2 clears the
  promotion bar.
- **valid-5** (adding `table` — the spec's narrower "cannot produce" wording):
  baseline 4/5 warm, **N2 4/5 warm** with cold-start rising 4/5 → 5/5. N2 ties
  rather than clears.

`table` is contested because the 25-case baseline recorded it as an _inverted_
case (cold `wrong-shape`, warm a real `Table`) and explicitly declined to
bucket it; this screen reproduced that inversion at `--samples 2`, and `table`
additionally passed cold under both P1 and N2. A model that has produced a
real `Table` cold, warm, and under two candidates is not showing a capability
gap. The dispute changes the read on N2 alone — P1, P2, P3, and N1 are losers
under both readings, each dropping with-history from baseline's 4/5 to 3/5.

**Two caveats on the numbers themselves.** (a) At `t=0` decoding is close to
deterministic here — 71 of 72 same-config-same-case sample pairs agreed — so
"passed both samples" carries roughly the weight of "passed once", not double
it, and exact reproduction across two runs shows the _measurement_ repeats,
not that the _effect_ is large. (b) N2's cost direction was not what was
expected: wall-clock across two full runs each showed N2 **27-28% faster**
(`qwen2.5-coder:7b` 149.85s → 109.19s; `gpt-oss:20b` 167.16s → 120.92s). That
is uncontrolled wall-clock, and run order (baseline paid the cold model load
N2 did not), prompt-prefix KV cache reuse, and N2's shorter/cleaner replies
each plausibly explain it. Read it as "N2 was not observed to be slower", not
as proof the added tokens are free. Token cost was never measured directly.

#### Warm-start drift — full-set confirmation, 2026-08-18

Stage 2 ("stack the winners") produced nothing: exactly one candidate
advanced, so there was nothing to stack. N2 went to the full set — all 25
cases, `t=0`, `--samples 2`, both conditions, six models. There is no
candidate prompt file anywhere in this stage; the shipped
`assets/card_system_prompt.txt` is the baseline _and_ the candidate, with
`--seed-card` the only difference.

| Model                        | Cold-start (base → N2) | With history (base → N2) | Eroded by history (N2)   |
| ---------------------------- | ---------------------- | ------------------------ | ------------------------ |
| `qwen2.5-coder:7b`           | 19/25 → 21/25          | 18/25 → 19/25            | `carousel`, `table` (2)  |
| `granite4.1:8b`              | 18/25 → 21/25          | 15/25 → 22/25            | `carousel`, `table` (2)  |
| `gpt-oss:20b`                | 20/25 → 24/25          | 22/25 → 23/25            | `gauge`, `table` (2)     |
| `llama3-chatqa:8b`           | 1/25 → 3/25            | 2/25 → 1/25              | `gauge`, `progress` (2)  |
| `llama3-groq-tool-use:8b`    | 10/25 → 15/25          | 9/25 → 16/25             | `progress`, `toggle` (2) |
| `nemotron-3.5-lightning:30b` | 21/25 → 22/25          | 13/25 → 22/25            | `table` (1)              |

What held, what strengthened, and what did not:

- **Cold-start rose on all six models, with no drop on any.** The Stage 1
  claim generalizes to the two models the screen never saw.
- **Every baseline-eroded case recovered on both erosion-metric models** — not
  just the one case each the six-case subset happened to include. All three of
  `qwen2.5-coder:7b`'s (`choice2`, `choice5`, `choice6`) and all four of
  `granite4.1:8b`'s (`choice1`, `choice5`, `columnset`, `number`) pass both
  conditions under N2. `nemotron-3.5-lightning:30b` recovered all eight of
  its, the largest single with-history gain in this file (13/25 → 22/25).
  `llama3-groq-tool-use:8b`'s known `Input.ChoiceSet` blind spot — all six
  choice cases failing under both conditions — flipped to six PASS/PASS.
- **The harm-control finding inverted.** Stage 1 flagged `gpt-oss:20b` trading
  warm for cold (5/6 → 4/6); at full scale both axes rose (22/25 → 23/25 and
  20/25 → 24/25). The aggregate harm the small screen flagged is not there.
- **The mechanism behind that flag survived anyway, as nested-shape
  fragility.** `table` newly erodes with history on four of the six models
  (`qwen2.5-coder:7b`, `granite4.1:8b`, `gpt-oss:20b`,
  `nemotron-3.5-lightning:30b`); only the two models that never produce a real
  `Table` at all are exempt. N2 gains cold-start capability on nested shapes
  and then loses it warm — a real, reproducible cost most models' net numbers
  are large enough to absorb.
- **The deciding model's +1 is not +3.** `qwen2.5-coder:7b`'s 18/25 → 19/25 is
  +3 recovered (`choice2`, `choice5`, `choice6`) and +1 new capability
  (`columnset`, previously never produced) against **−3 regressed**: `table`
  (a clean 2/2 warm pass under baseline, a 1/2 split under N2), `number`
  (baseline-inverted, now failing both conditions), and `time` (a stable pass
  under both conditions at baseline, now `no-input` on both, both samples).
  Excluding a case withholds credit; it never withholds scrutiny of harm.
  Caveat on the comparison: the baseline half is the `--samples 1` run from
  2026-08-17, the N2 half `--samples 2` from 2026-08-18.
- **Two regressions the four-model screen could not catch.**
  `llama3-chatqa:8b`'s with-history dropped 2/25 → 1/25 (its one non-prose
  warm pass, `pie`, is gone) even as cold-start rose — the one model that got
  worse on the warm axis. And `llama3-groq-tool-use:8b` picked up an
  over-carding failure: its `prose` case (a plain question with no structured
  answer) now returns a card cold-start, both samples, on no other model.

#### Regression gates against the warm-start survivor, 2026-08-18

**Neither standing gate can exercise N2.** `temperature_stress.dart` and
`prompt_ab.dart` both send a system prompt and a single user turn; neither
accepts seed history, and N2 is not a prompt edit — so running them against it
measures a file the candidate never touches. Their baselines were run anyway
for a same-session reference point on `qwen2.5-coder:7b`: stress **10/10** at
`t=0` and **10/10** at `t=0.6`, code A/B **8/8**, including _"what is a
closure? show an example"_ — the exact prompt the rejected compare-and-comment
wording regressed. Clean, but that is a fact about the shipped prompt, not
evidence about N2.

**What does cover the risk** is Stage 3's own `codeblock` case, whose prompt
is the same code-plus-explanation shape as that precedent regression. Across
all six models, both conditions, 24 samples under N2, zero produced the
`broken:` / raw-JSON-leak verdict; where a baseline comparison exists, N2 held
`codeblock`'s pass or improved it. **The qualifier:** every Stage 3 run was at
`t=0`, while `temperature_stress.dart` also covers `t=0.6`, and
`--ollama-temperature` puts a real deployment there. **N2 under sampling
(`t>0`) was never measured.** Low severity — `defaultCardTemperature` is `0.0`
so an unconfigured server never leaves `t=0` — but this file records wording
fixes that held at `t=0` and failed at `t=0.6`, so the one is not a proxy for
the other.

#### Promoted: N2 (`--seed-card`) shipped, 2026-08-18

N2 is now in `OllamaResponder.reply()`, which prepends the seed pair
**unconditionally** — immediately after the system message and before the
trimmed real history, so the assembled order is: system prompt,
`seedCardUser`, `seedCardAssistant`, trimmed history, current user turn. There
is no flag to disable it, because nothing in the evidence pointed at a case
where it should be withheld. This is a code change, not a prompt edit:
`assets/card_system_prompt.txt` is unmodified. The constants live in
`lib/src/seed_card.dart` (shipped code; `lib/` cannot depend on `tool/`) and
`shape_cases.dart` re-exports them, so the probe and the server provably send
the same bytes. `test/ollama_responder_test.dart` pins that role and content
order end to end.

It is a **broad** result, not a narrow one: cold-start shape coverage rose on
all six measured models and with-history on five of six. Four trade-offs come
with it and must not be read past:

1. **`table` newly erodes with history on 4 of 6 models** — nested-shape
   fragility the six-case screen was too small to catch.
2. **The deciding model's with-history +1 is built from +3 recovered, +1 new,
   and −3 regressed** (`table`, `number`, `time`) — not +3 alone.
3. **`llama3-chatqa:8b` regressed with-history, 2/25 → 1/25** — the one model
   worse on the warm axis. Non-gating, but recorded rather than folded into
   the six-model headline.
4. **N2 costs tokens on every request, permanently**, and the latency evidence
   is thin — uncontrolled wall-clock showing N2 _faster_, never a per-token
   benchmark, never measured on four of the six models. Token cost was not
   measured at all.

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

The escape-hatch re-key that _was_ promoted (§4, `choiceset_ab.dart
--samples 2`, `t=0`: 2/12 → 6/12 with history) ran the same two regression
checks clean — stress 10/10 at both `t=0` and `t=0.6`, and the code A/B set
8/8 including the exact closure prompt the compare-and-comment candidate
above regressed. The post-fix half of that pair re-measures as **3/6** at
`--samples 1`, which is the figure the model table carries so it compares
with every other row; both runs pass and fail the same three prompts each.

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

With history (`choiceset_ab.dart`, two prior prose turns, `t=0`, `--samples 1`), it scored ✅ 6/6 — a clean sweep, every prompt returning a two-element card containing an `Input.ChoiceSet`, tying `gpt-oss:20b` for the best with-history result on record. This probe runs at `t=0`, the temperature where the Modelfile-recommended-temperature finding above already shows this model doing better, not worse, so the clean sweep is consistent with that finding rather than in tension with it. See [§4](#4-multi-turn-set--history-replay) for the full per-prompt breakdown and where this result sits among all thirteen models probed with history.

### `qwen3.5:9b`

Usable **only with thinking disabled**, and even then offers no reliability edge over `qwen2.5-coder:7b` while costing more latency and memory. Its thinking capability is a liability for constrained-JSON output.

With server defaults of the time (temp 1, thinking on) it answered a checkbox request with a `CodeBlock` of raw HTML using invented keys (`codeLanguage`/`content` instead of `codeSnippet`), taking 77 s. The same model with `think:false` + `temperature:0` produced a clean `Input.ChoiceSet` and a clean 4-page Carousel in ~10 s.

With history (`choiceset_ab.dart`, two prior prose turns, `t=0`, `think:false` — the probe tooling hardcodes `think: false` unconditionally, so this measurement is the same thinking-off condition as the finding above, not a thinking-on one), it scored ⚠️ 5/6: one miss ("what build modes can I choose from?") where it returned a valid card whose only element was a `TextBlock` listing the three modes in Markdown rather than an `Input.ChoiceSet`. See [§4](#4-multi-turn-set--history-replay) for the full per-prompt breakdown.

Not recommended as the default for this workload. Listed in `launch.json`; installed locally (`ollama list` / `curl http://127.0.0.1:11434/api/tags` confirms `qwen3.5:9b` present).

### `llama3.2` (3.2B — the `llama3.2:latest` tag)

Retired as a default. Failed the shapes that matter: checkbox `isMultiSelect` 1/14, nested-array Carousel 0/5, table 1/4. FactSet and plain prose were reliable. The nested-array corruption family that motivated the duplicate-key guard reads as specific to this 3B model under hot sampling.

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
  has not been meaningfully tested on it — which is why N1's null on
  `qwen2.5-coder:7b` decided nothing.
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

Measured on an M-series Mac against a local Ollama, August 2026. Latency figures include model load on a first call; re-run before trusting one.

## Sources

Full context for these findings, in the documents that produced them:

- [`tool/model_probes/README.md`](tool/model_probes/README.md) — the probe scripts and their "What these found" section
- `docs/archive/specs/2026-07-23-ollama-structured-json-output-design.md` — the `llama3.2` / `qwen3.5:9b` / `qwen2.5-coder:7b` comparison and the `format` findings
- `lib/src/ollama_responder.dart` — `defaultOllamaModel`, `defaultCardTemperature`, and `defaultKeepAlive` carry the reasoning for each default
- [`CHANGELOG.md`](CHANGELOG.md) — dated entries with the measurement that justified each change
