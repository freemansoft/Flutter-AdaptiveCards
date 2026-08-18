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

At the time of writing that yields `gpt-oss:20b`, `qwen2.5-coder:7b`, and `qwen3.5:9b`. If you find that stale, the grep is right and this paragraph is wrong.

`qwen2.5-coder:7b` is additionally the server's compiled-in default (`defaultOllamaModel` in `lib/src/ollama_responder.dart`), which is a separate decision from what the debugger launches.

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
| gpt-oss:20b                                       | 12.8 GB | ❌    | top 3 (`launch.json`)  | ⚠️ everyday 6/7 · stress 5/5 `t=0`, 4/5 `t=0.6`            | ✅ 6/6 choice-set · shapes 22/25 (see §4)                  |
| granite4.1:3b                                     | 2.0 GB  | ✅    | candidate              | ❌ everyday 4/7 · stress 4/5 `t=0`, 3/5 `t=0.6` — weakest  | ⚠️ 3/6 choice-set                                          |
| granite4.1:8b                                     | 5.0 GB  | ✅    | candidate              | ⚠️ everyday 6/7 · stress 5/5 `t=0`, 4/5 `t=0.6`            | ⚠️ 3/6 choice-set · shapes 15/25 (see §4)                  |
| hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest | 22.9 GB | ❌    | candidate              | ❌ everyday 7/7 · stress 3/5 `t=0`, 3/5 `t=0.6`            | ❌ 1/6 choice-set                                          |
| llama3-chatqa:8b                                  | 4.3 GB  | ✅    | candidate              | ✅ everyday 7/7 all temps · stress 5/5 both — clean sweep  | ❌ 0/6 — drops to prose · shapes 2/25 (see §4)             |
| llama3-groq-tool-use:8b                           | 4.3 GB  | ✅    | candidate              | ⚠️ everyday 6/7 · stress 5/5 `t=0` but **1/5** at `t=0.6`  | ❌ 0/6 — drops to prose                                    |
| llama3.2:latest                                   | 1.9 GB  | ✅    | candidate              | ❌ Retired as default — failed nested and multi-select     | — not yet probed                                           |
| nemotron-3-nano:4b                                | 2.6 GB  | ✅    | candidate              | ❌ everyday 6/7 but stress **2/5** `t=0`, 1/5 `t=0.6`      | ❌ 0/6 — drops to prose                                    |
| nemotron-3-nano:30b                               | 22.6 GB | ❌    | candidate              | ❌ everyday 7/7 · stress 2/5 `t=0`, 1/5 `t=0.6`            | ⚠️ 5/6 choice-set                                          |
| nemotron-3.5-lightning:30b                        | 23.7 GB | ❌    | candidate              | ❌ everyday 6/7 · stress 3/5 `t=0`, 4/5 `t=0.6`            | ❌ 0/6 — drops to prose                                    |
| qwen2.5-coder:7b                                  | 4.4 GB  | ✅    | server default + top 3 | ✅ Recommended — cleared every documented failure at `t=0` | ⚠️ 3/6 choice-set · shapes 18/25 (see §4)                  |
| qwen3-coder:30b                                   | 17.3 GB | ❌    | candidate              | ⚠️ everyday 7/7 · stress 5/5 `t=0`, 5/5 `t=0.6`            | ⚠️ 2/6 choice-set — bracket omission, not prose            |
| qwen3.5:9b                                        | 6.1 GB  | ⚠️    | top 3 (`launch.json`)  | ⚠️ Only with thinking off; no edge over the default        | ⚠️ 5/6 choice-set — one miss: TextBlock list, no ChoiceSet |
| qwen3.6:27b-coding-nvfp4                          | 18.4 GB | ❌    | candidate              | ⚠️ Ignores `format`; better at `t=0` than its own `0.6`    | ✅ 6/6 choice-set                                          |

**Cold start** is a single-turn probe. **With history** replays prior conversation turns the way the server actually does. These are different measurements and a model can pass one while failing the other — every result recorded before 2026-08-14 is a cold-start number, because no probe sent history at all.

Every _measured_ **With history** cell in this table is now an `N/6` score from the same probe under the same conditions — `choiceset_ab.dart`, `t=0`, `--samples 1`, two prior prose turns — measured against `assets/card_system_prompt.txt` _after_ Task 7's escape-hatch re-key had already been promoted. None of these numbers is a "before" baseline for a fix still to come; read them as the current, fixed-prompt state of each model, and comparable to each other cell-for-cell.

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

#### Shape coverage — `qwen2.5-coder:7b`, 2026-08-17

First run of `shape_ab.dart` (25 cases, `t=0`, `--samples 1`, current shipped
prompt). Cold-start **19/25**, with-history **18/25**.

Shapes lost to history (produced cold, prose or wrong shape with two prior
prose turns): `choice2`, `choice5`, `choice6` — all three passed cold as a
card containing `Input.ChoiceSet` and regressed to bare `prose` with history
present, matching the `eroded by history` set the probe itself derives from
the two condition runs.

Shapes this model never produced under either condition: `carousel`,
`columnset`, `rating_ask`, `text` — these are capability or palette gaps, not
drift, and no anti-drift wording will move them.

Notable per-case detail:

- `text` ("ask me to describe the bug"): cold-start scored `no-input` — it
  answered with a bare `TextBlock` instead of `Input.Text`; with-history
  degraded further to plain `prose`, no card at all. Failed both conditions,
  but the failure mode changed shape rather than staying constant.
- `rating_ask` ("ask me to rate my support experience 1 to 5"): identical
  `no-input` failure under both conditions — the model returned a read-only
  `Rating` display instead of an `Input.ChoiceSet`/`Input.Number`. This is a
  systematic confusion between "show a rating" and "collect a rating," not
  history-related drift.
- `carousel`: `wrong-shape` cold (a bare `TextBlock` instead of `Carousel`),
  degrading to bare `prose` with history. `Carousel` was never emitted under
  either condition in this run.
- `columnset`: `wrong-shape` under both conditions unchanged — a bare
  `TextBlock` instead of `ColumnSet`/`Table` both times. The only
  never-produced shape whose failure did not get worse with history.
- Two cases inverted the expected direction, failing cold-start but passing
  with-history: `number` (cold `no-input`, a bare `TextBlock`; warm passed
  with `Input.Number`) and `table` (cold `wrong-shape`, a bare `TextBlock`;
  warm passed with a real `Table`). At `--samples 1` this may be
  call-to-call variance rather than a real history effect; it fits neither
  "lost to history" nor "never produced" and is recorded here rather than
  forced into either bucket.
- `codeblock` passed cleanly under both conditions (`CodeBlock, TextBlock`)
  — the model always emitted a real `CodeBlock` rather than a
  Markdown-fenced `TextBlock`, so the case-design caveat about that
  alternative being defensible did not come up in this run.
- `gauge` and `progress` also passed cleanly and distinctly under both
  conditions (`Chart.Gauge` and `ProgressBar` respectively) despite sharing
  the "72%" wording — no cross-contamination between the two buckets was
  observed.

#### Shape coverage — `gpt-oss:20b`, 2026-08-17

First run of `shape_ab.dart` (25 cases, `t=0`, `--samples 1`, current shipped
prompt). Cold-start **20/25**, with-history **22/25**.

Shapes lost to history (produced cold, prose or wrong shape with two prior
prose turns): **none**. The probe's own derived set agrees:
`eroded by history: none`.

Shapes this model never produced under either condition: `carousel`,
`table`, `columnset` — the three most deeply nested shapes in the case set
(a `CarouselPage` array, a `Table` with row/cell nesting, and a `ColumnSet`
with a `Column` array). Unlike every model recorded in the subsection above,
none of these three are prose drops or a wrong element type: all three
failed both conditions with the server's own `broken: invalid JSON` verdict
— a mismatched or missing closing bracket/brace, or (twice) output that
stopped mid-structure. These read as a JSON-validity ceiling on long, nested
generations rather than a shape the model doesn't know how to produce.

Two cases moved the opposite direction — failing cold-start and passing
with-history: `gauge` (cold: `broken: invalid JSON`, a stray trailing quote
after the numeric `value`; warm: passed cleanly with `Chart.Gauge`) and
`rating_show` (cold: the identical stray-trailing-quote malformation after a
numeric field; warm: passed cleanly with `Rating`). At `--samples 1` this
may be call-to-call noise rather than a real history effect — the same
caveat the `qwen2.5-coder:7b` write-up above applies to its own two inverted
cases (`number`, `table`) — so it is recorded here rather than folded into
either the "lost to history" or "never produced" buckets.

Notable per-case detail:

- `carousel`: `broken: invalid JSON` under both conditions — cold-start
  truncated mid-structure (`Unexpected end of input`); with-history
  produced a full-length reply but with an extra unmatched `}` at the very
  end (`Unexpected character` at the last byte). Never scored
  `wrong-shape` — the model always attempted a real `Carousel`, it just
  didn't close the JSON cleanly.
- `table`: `broken: invalid JSON` under both conditions — cold-start had an
  extra stray `]` before the closing braces; with-history had an extra
  stray `}` in the same position. Same failure signature as `carousel`,
  different shape.
- `columnset`: `broken: invalid JSON` under both conditions — cold-start
  had a stray character mid-array; with-history truncated mid-structure
  (`Unexpected end of input`). Same signature family as the other two
  never-produced shapes.
- `codeblock` passed cleanly under both conditions (`CodeBlock, TextBlock`)
  — the model always emitted a real `CodeBlock` rather than a
  Markdown-fenced `TextBlock`, so the case-design caveat about that
  alternative being defensible did not come up in this run, same as the
  `qwen2.5-coder:7b` result.
- `gauge` and `progress` landed in their own distinct, correct buckets
  wherever a valid card came back (`Chart.Gauge` and `ProgressBar`
  respectively) — no cross-contamination between the two buckets was
  observed, though `gauge`'s cold-start reply never reached that check at
  all because it failed to parse first (see above).

**Transcript caveat.** The raw probe output backing this section shows
every JSON failure printed as `broken: broken: invalid JSON: ...` — a
doubled prefix, `judgeShape` re-prefixing a label `judgeReply` had already
prefixed. Fixed in this same change (see `CHANGELOG.md`); it is cosmetic
only — `pass` was `false` either way and the bucket classification above is
unaffected — but the captured transcript predates the fix and still shows
the doubled form.

**Comparison against `qwen2.5-coder:7b`.** qwen's baseline (above) went
19/25 cold to 18/25 warm, losing three choice-set shapes to prose
(`choice2`, `choice5`, `choice6`). `gpt-oss:20b` moves the opposite
direction — 20/25 cold to **22/25** warm, with zero shapes eroded — and its
failures are a different class entirely: not one of its 8 failing instances
(5 cold, 3 warm) was a prose drop or a wrong element type; all 8 were
malformed JSON on the three most structurally nested shapes. This answers
the question this run was designed for: `gpt-oss:20b`'s choice-set
resilience on `choiceset_ab.dart` (✅ 6/6 with history, tied with
`qwen3.6:27b-coding-nvfp4` for the best of the thirteen models measured
there — see §4) **does generalize** across the other 19 shapes — not merely
to more prose-drift questions, but to a model with no measurable
warm-start prose-drift problem at all under this probe. That reframes what
its weakness actually is: not fragility under conversation history, but a
JSON-validity ceiling on long/nested generations that is present cold and
stays exactly as present warm. Practical consequence: `gpt-oss:20b` would
be a poor screening subject for a future prose-drift fix — it has none to
fix here — and a fix aimed at nested-JSON validity on
`Carousel`/`Table`/`ColumnSet` would need a different model, one that
actually exhibits the failure, as its regression canary.

#### Shape coverage — `llama3-chatqa:8b`, 2026-08-17

First run of `shape_ab.dart` (25 cases, `t=0`, `--samples 1`, current
shipped prompt). Cold-start **1/25**, with-history **2/25**.

Shapes lost to history (produced cold, prose or wrong shape with two prior
prose turns): **none**. The probe's own derived set agrees: `eroded by
history: none`.

One case moved the opposite direction — failing cold-start and passing
with-history: `pie` (cold: `prose`, a clean conversational reply with no
card attempted at all; warm: passed cleanly with `Chart.Pie`). At
`--samples 1` this may be call-to-call noise rather than a real history
effect — the same caveat the `qwen2.5-coder:7b` write-up (`number`,
`table`) and the `gpt-oss:20b` write-up (`gauge`, `rating_show`) above
apply to their own inverted cases — so it is recorded here rather than
folded into either the "lost to history" or "never produced" buckets.

Shapes this model never produced under either condition: the remaining 23
of 25 cases — `date`, `time`, `toggle`, `text`, `number`, `choice1` through
`choice6` (6 cases), `bar`, `line`, `gauge`, `rating_show`, `rating_ask`,
`carousel`, `table`, `facts`, `columnset`, `codeblock`, `progress`, and
`badge`. Unlike either model above, this is not a JSON-validity gap: 22 of
these 23 scored a flat `prose` verdict under both conditions — the server's
own "ok, clean prose" bucket for a well-formed conversational answer that
never attempted card JSON at all, failing the shape probe only because it
supplied no `Input.*`/chart/table element to grade. This model did not try
and fail to produce these shapes; on this run it essentially never tried,
cold or warm alike.

The one exception is `progress`, whose failure changed character between
conditions without ever passing: cold-start scored plain `prose` (no card
attempted), but with-history scored `broken: prose-with-card (user sees
raw JSON)` — the server's label for a reply that wraps card JSON inside
surrounding prose text, so the JSON leaks to the user instead of rendering.
That is a shift from "no attempt" to "attempted and leaked," the same kind
of failure-changed-shape-without-passing already on record for
`qwen2.5-coder:7b`'s `text` case above, only moving the opposite direction
(worse under history, not better).

Notable per-case detail:

- Every case except `pie` and `progress` (with-history) produced the
  byte-for-byte same verdict, `prose`, under both conditions — there is no
  further per-case pattern to report beyond the aggregate: this model
  answers in plain conversational text almost regardless of what shape a
  case asks for.
- `codeblock` scored `prose` under both conditions, not the `CodeBlock,
TextBlock` pass recorded for both `qwen2.5-coder:7b` and `gpt-oss:20b`
  above. Whether the prose reply happened to contain a defensible
  Markdown-fenced block cannot be confirmed or ruled out from the summary
  label alone — the verdict line does not record that — so this failure is
  noted rather than read as a clean capability gap; the case-design caveat
  may apply here too.
- `gauge` and `progress` never crossed into each other's bucket — both
  scored `prose` under both conditions (aside from `progress`'s
  with-history shift to `prose-with-card` above) — so the shapes' shared
  "72%" wording caused no observed cross-contamination, but only because
  neither shape was ever actually produced for the two to be confused.

**Comparison across all three baselines.** The three shape-coverage runs on
record describe three different mechanisms, not one spectrum with this
model at an extreme end. `qwen2.5-coder:7b` swept most of the set cold
(19/25) and lost three choice-set shapes to prose with history (18/25) —
cold-strong, warm-weaker. `gpt-oss:20b` swept nearly all of it in both
conditions (20/25 → 22/25, zero eroded), its only failures being
JSON-validity breaks on the three most nested shapes, present and
unchanged across both conditions. `llama3-chatqa:8b` matches neither
shape: it is not cold-strong (1/25 is the weakest cold-start score of the
three by a wide margin) and it is not meaningfully different warm (2/25)
— it is close to a uniform, near-total failure under both conditions, and
the one point of movement (`pie`) is hedged above as possible sampling
noise rather than a demonstrated effect.

**What this means for validating a drift fix.** The task's hypothesis
rested on this model's own earlier record: a clean 7/7 everyday · 5/5
stress cold-start sweep on the narrower everyday/stress probe
(2026-08-14), followed by a 0/6 collapse with history on the narrower
`choiceset_ab.dart` options probe. That pairing looked like the textbook
cold-strong/warm-weak shape a drift fix could be validated against. It
does not hold on the broader 25-shape set: `shape_ab.dart` shows a
cold-start score of 1/25, not 19-20/25 like the other two baselines, so
there is essentially no cold-start card-producing behavior here to erode
in the first place — the model mostly answers in prose from the very
first, unhistoried turn. The 0/6 choice-set collapse did **not** generalize
into broad shape erosion, because "erosion" implies something was working
that stopped; on `shape_ab.dart`'s broader palette, it was barely working
to begin with. That makes `llama3-chatqa:8b` a **weaker** drift-fix
validation subject than the hypothesis assumed, not a stronger one: a fix
aimed at "conversation history erodes an otherwise-working card path" has
almost no working card path to erode here, cold or warm.

The two numbers are not actually in tension — they are two different pass
criteria applied to the same underlying, strongly prose-preferring
behavior. The everyday/stress probe's rule, per [What counts as a
pass](#what-counts-as-a-pass), is that a reply passes if it renders as a
card **or** as clean prose. This transcript shows why that mattered here:
24 of this run's 25 cold-start replies scored the server's own `prose`
verdict — a well-formed, non-broken conversational answer with no card
attempted at all. Under the everyday/stress probe's lenient either/or
rule, replies shaped like that are credited as passes; `shape_ab.dart`
additionally requires the specific requested element (an `Input.*`, a
chart type, a table), so the same prose-preferring behavior that scored
7/7 · 5/5 under one rule scores 1/25 under the other. Nothing changed
about the model between the two probes — the measuring stick changed. Read
that way, this run is arguably the first evidence in this file that
`shape_ab.dart` earns its keep as a separate instrument: it is the first
probe here that can tell "produces good cards" apart from "answers in
prose and gets credited for it," and this model is the clearest
demonstration on record of a case where those two things were being
conflated.

#### Shape coverage — `granite4.1:8b`, 2026-08-17

Preceded by a cheap five-case screen (`date`, `table`, `pie`, `carousel`,
`choice1`, `--samples 1`) run first as a go/no-go check against the
`llama3-chatqa:8b` failure mode (near-zero cold-start card production). The
screen returned cold-start 2/5 with two clean card passes (`date` →
`Input.Date, TextBlock`; `choice1` → `Input.ChoiceSet, TextBlock`), which
ruled out a total collapse and cleared the model for the full run.

First full run of `shape_ab.dart` (25 cases, `t=0`, `--samples 1`, current
shipped prompt). Cold-start **18/25**, with-history **15/25**.

Shapes lost to history (produced cold, prose or wrong shape with two prior
prose turns): `choice1`, `choice5`, `columnset`, `number` (4) — the probe's
own derived set agrees: `eroded by history: choice1, choice5, columnset,
number (4)`. Three of the four eroded to bare `prose` (`choice1`, `choice5`,
`number`, each a clean cold pass — `Input.ChoiceSet, TextBlock`,
`Input.ChoiceSet`, `Input.Number` respectively — replaced by conversational
text with no card attempted). The fourth, `columnset`, eroded differently: it
passed cold as `Column, ColumnSet, TextBlock` and regressed with history not
to prose but to a bare `TextBlock` (`wrong-shape: got {TextBlock} want
{ColumnSet, Table}`) — a demoted card, not an abandoned one, the same
distinction `qwen2.5-coder:7b`'s write-up above draws for its own `text`
case.

Shapes this model never produced under either condition (6): `text`,
`choice2`, `rating_ask`, `carousel`, `table`, `codeblock`. These are not one
failure mode:

- `text` and `table` scored flat `prose` under both conditions — no card
  attempted, cold or warm.
- `choice2` shifted shape without ever passing: cold scored `no-input` (`got
{TextBlock} want {Input.ChoiceSet}` — a card attempted, wrong element
  type), warm dropped further to plain `prose` — an abandoned attempt, not
  a repeated one.
- `rating_ask` scored the identical `no-input` verdict under both conditions
  (`got {Rating} want {Input.ChoiceSet, Input.Number}`) — the same
  show-a-rating/collect-a-rating confusion already on record for
  `qwen2.5-coder:7b`'s `rating_ask` case, evidently not specific to one
  model.
- `carousel` scored the identical `broken: prose-with-card (user sees raw
JSON)` verdict under both conditions — the model attempts real card JSON
  every time but wraps it in surrounding prose, so it leaks to the user
  instead of rendering; never a JSON-validity break and never a wrong
  element type.
- `codeblock` changed failure character between conditions without ever
  passing: cold scored `broken: invalid JSON` — the reply broke mid-generation
  while narrating a Dart snippet (`FormatException: Unexpected character (at
line 4, character 253)`, trailing text `...**Dart snippet:**`) — while
  warm scored `broken: prose-with-card (user sees raw JSON)`, the same
  leaking pattern as `carousel`. Neither cold nor warm failure is the
  TextBlock-with-a-fenced-block shape the case-design caveat warns is
  defensible-but-scored-as-a-miss; both are broken or leaked JSON, not a
  clean prose substitute.

One case moved the opposite direction — failing cold-start and passing
with-history: `pie` (cold: `broken: invalid JSON`, the response breaking on
a trailing sentence appended after the JSON — `*Values are approximate
percentages based on recent market data.` — `FormatException: Unexpected
character (at line 3, character 1)`; warm: passed cleanly with
`Chart.Pie`). At `--samples 1` this may be call-to-call noise rather than a
real history effect, the same caveat the three baselines above apply to
their own inverted cases (`qwen2.5-coder:7b`'s `number`/`table`,
`gpt-oss:20b`'s `gauge`/`rating_show`, `llama3-chatqa:8b`'s `pie`) — so it is
recorded here rather than folded into either the "lost to history" or
"never produced" buckets.

Bucket arithmetic: 14 shapes passed both conditions (`date`, `time`,
`toggle`, `choice3`, `choice4`, `choice6`, `bar`, `line`, `gauge`,
`rating_show`, `facts`, `progress`, `badge`, `prose`) + 4 lost to history +
6 never produced + 1 failed-cold-passed-warm = 25. 14 + 4 = 18 (the cold
figure); 14 + 1 = 15 (the warm figure).

Notable per-case detail not already covered above:

- `gauge` and `progress` again landed in their own distinct, correct
  buckets under both conditions (`Chart.Gauge` and `ProgressBar`
  respectively) despite sharing the "72%" wording — no cross-contamination
  between the two, matching every prior baseline.
- `choice3`, `choice4`, and `choice6` held cleanly under both conditions
  (`Input.ChoiceSet` variants both times); only `choice1`, `choice2`, and
  `choice5` failed to hold — three of six choice cases are unaffected by
  history, three are not.

**Four-way comparison across all baselines on record.** `qwen2.5-coder:7b`
went 19/25 cold to 18/25 warm, three eroded, all three to prose.
`gpt-oss:20b` went 20/25 cold to 22/25 warm, zero eroded, its only failures
JSON-validity breaks on the three most nested shapes. `llama3-chatqa:8b`
went 1/25 cold to 2/25 warm — essentially no cold-start card path to erode.
`granite4.1:8b` sits closest to `qwen2.5-coder:7b`'s shape: 18/25 cold —
third of the four baselines, one below `qwen2.5-coder:7b`, two below
`gpt-oss:20b`, seventeen above `llama3-chatqa:8b` — to 15/25 warm, with 4
eroded overall. Of those 4, only 3 eroded to prose, the same count as
`qwen2.5-coder:7b`'s 3 — the two models are tied on the like-for-like,
prose-specific comparison. The fourth (`columnset`) eroded to a wrong
element type rather than to prose, a different failure mechanism kept
separate from that tied count rather than added to it (see the verdict
below). Restricted
to just the six choice-shape cases (`choice1`-`choice6`, the closest
`shape_ab.dart` analogue to the narrower `choiceset_ab.dart` options probe
that produced the original "loses half its cold-start options answers to
prose" reading), cold-start passed 5 of 6 (all but `choice2`, which failed
cold on a wrong element type rather than passing) and with-history held only
3 of those 5 (`choice3`, `choice4`, `choice6`) — 2 of 5 cold-passing choice
cases lost, 40%, close to but not exactly the earlier "half" figure, and
measured on a different, broader probe than the one that produced the
original number. The direction of the original characterization holds; the
exact fraction does not reproduce precisely on this instrument.

**Verdict: a viable drift-fix validation subject, comparable to
`qwen2.5-coder:7b` rather than clearly better than it.** The like-for-like
comparison is shapes eroded specifically to prose — the failure mode an
anti-prose-drift fix actually targets — and on that count `granite4.1:8b`
and `qwen2.5-coder:7b` are **tied at 3 apiece**. `granite4.1:8b`'s fourth
eroded shape, `columnset`, went to a wrong element type instead
(`wrong-shape: got {TextBlock} want {ColumnSet, Table}`), a different
failure mechanism a prose-preserving wording fix may not touch at all, so
it belongs beside the tied count as a separate, uncertain data point rather
than folded into a "4 vs 3, more signal" headline. Even the tied 3-3 count
should carry the same `--samples 1` noise caveat this file applies
elsewhere to single-count movements (`qwen2.5-coder:7b`'s own
`number`/`table` inversion, `gpt-oss:20b`'s `gauge`/`rating_show`,
`granite4.1:8b`'s own `pie` inversion above) — a one-shape difference in
aggregate erosion is the same order of magnitude as those, so "tied" is
better read as "no demonstrated difference" than as a precise measurement.

What does qualify `granite4.1:8b` as viable: a real cold-start card path
(18/25, third of the four baselines on record — behind `gpt-oss:20b`'s 20
and `qwen2.5-coder:7b`'s 19, far ahead of `llama3-chatqa:8b`'s 1 — not a
near-zero starting point) and real prose erosion under history (unlike
`gpt-oss:20b`'s zero), which is exactly what a prose-drift fix needs
something to move. If there is a distinguishing angle at all, it is that
`granite4.1:8b`'s lower absolute scores (18/15 vs. `qwen2.5-coder:7b`'s
19/18, and 6 shapes never produced under either condition versus
`qwen2.5-coder:7b`'s 4) leave more numerical room for a fix to demonstrate
movement — but the same gap cuts the other way: a lower, more failure-prone
baseline is also a noisier floor to measure a fix against, with more
confounding failure modes (`no-input`, `broken`, `wrong-shape`) in the mix
alongside the prose drops a fix is meant to address. Read together, the
data supports "`granite4.1:8b` is a viable drift-fix subject on a similar
footing to `qwen2.5-coder:7b`," not "`granite4.1:8b` is the better choice."
A validation pass on this model should track `columnset` separately from
the three prose erosions rather than assuming all four eroded cases share
one mechanism.

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
  templates vary in whether a `system` message placed after the conversation
  history reaches the model at all; some keep only the first. Checked
  2026-08-18 by setting the injected reminder to "always begin your reply with
  the word BANANA" and reading the reply: `qwen2.5-coder:7b` — delivery
  unconfirmed (`choice1` cold-start stayed `PASS` with the reminder in
  place); `gpt-oss:20b` — delivery unconfirmed (`choice1` cold-start stayed
  `PASS`); `granite4.1:8b` — delivery unconfirmed (`choice1` cold-start
  stayed `PASS`); `llama3-chatqa:8b` — no case exists that could answer this.
  Its only recorded cold-start pass among the 25 `shape_ab.dart` cases is the
  `prose` negative control, whose own pass criterion (a non-card,
  non-broken reply) is satisfied by a bare "BANANA" reply exactly as it
  would be by a normal answer, so a `PASS` → `FAIL` transition is
  structurally impossible on that case regardless of whether the reminder
  arrives; every other case already fails this model cold-start (1/25
  overall), leaving no baseline to break. This matters before interpreting
  any mid-conversation reinforcement result — a candidate that scores
  exactly at baseline on a model that silently drops the message has not
  been tested on it, and on none of the four screening models did this check
  produce positive proof of delivery, so N1's numbers should be read as
  unverified-delivery on all four rather than confirmed on any.

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
