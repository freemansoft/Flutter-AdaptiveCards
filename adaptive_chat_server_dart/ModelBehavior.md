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

| Model                                             | Weights | 16 GB | Role                   | Cold start                                                 | With history                                      |
| ------------------------------------------------- | ------- | ----- | ---------------------- | ---------------------------------------------------------- | ------------------------------------------------- |
| gpt-oss:20b                                       | 12.8 GB | ❌    | top 3 (`launch.json`)  | ⚠️ everyday 6/7 · stress 5/5 `t=0`, 4/5 `t=0.6`            | ✅ 6/6 choice-set                                 |
| granite4.1:3b                                     | 2.0 GB  | ✅    | candidate              | ❌ everyday 4/7 · stress 4/5 `t=0`, 3/5 `t=0.6` — weakest  | ⚠️ 3/6 choice-set                                 |
| granite4.1:8b                                     | 5.0 GB  | ✅    | candidate              | ⚠️ everyday 6/7 · stress 5/5 `t=0`, 4/5 `t=0.6`            | ⚠️ 3/6 choice-set                                 |
| hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest | 22.9 GB | ❌    | candidate              | — not yet probed                                           | — not yet probed                                  |
| llama3-chatqa:8b                                  | 4.3 GB  | ✅    | candidate              | ✅ everyday 7/7 all temps · stress 5/5 both — clean sweep  | ❌ 0/6 — drops to prose                           |
| llama3-groq-tool-use:8b                           | 4.3 GB  | ✅    | candidate              | ⚠️ everyday 6/7 · stress 5/5 `t=0` but **1/5** at `t=0.6`  | ❌ 0/6 — drops to prose                           |
| llama3.2:latest                                   | 1.9 GB  | ✅    | candidate              | ❌ Retired as default — failed nested and multi-select     | — not yet probed                                  |
| nemotron-3-nano:4b                                | 2.6 GB  | ✅    | candidate              | ❌ everyday 6/7 but stress **2/5** `t=0`, 1/5 `t=0.6`      | ❌ 0/6 — drops to prose                           |
| nemotron-3-nano:30b                               | 22.6 GB | ❌    | candidate              | — not yet probed                                           | — not yet probed                                  |
| nemotron-3.5-lightning:30b                        | 23.7 GB | ❌    | candidate              | — not yet probed                                           | — not yet probed                                  |
| qwen2.5-coder:7b                                  | 4.4 GB  | ✅    | server default + top 3 | ✅ Recommended — cleared every documented failure at `t=0` | ⚠️ 6/12 after escape-hatch fix (was 2/12, see §4) |
| qwen3-coder:30b                                   | 17.3 GB | ❌    | candidate              | — not yet probed                                           | — not yet probed                                  |
| qwen3.5:9b                                        | 6.1 GB  | ⚠️    | top 3 (`launch.json`)  | ⚠️ Only with thinking off; no edge over the default        | — not yet probed                                  |
| qwen3.6:27b-coding-nvfp4                          | 18.4 GB | ❌    | candidate              | ⚠️ Ignores `format`; better at `t=0` than its own `0.6`    | — not yet probed                                  |

**Cold start** is a single-turn probe. **With history** replays prior conversation turns the way the server actually does. These are different measurements and a model can pass one while failing the other — every result recorded before 2026-08-14 is a cold-start number, because no probe sent history at all.

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

Six more models were run through the same `choiceset_ab.dart` probe on 2026-08-16 (`t=0`, `--samples 1`, two prose turns before the question), to see whether the collapse above is specific to `qwen2.5-coder:7b` or a property of the workload. The result does not round into a tidy conclusion: `gpt-oss:20b` held up completely at ✅ 6/6, while `llama3-chatqa:8b` — the model that had swept the cold-start everyday and stress sets 7/7 and 5/5 — collapsed to ❌ 0/6, the same total-collapse pattern already on record for `qwen2.5-coder:7b`. `llama3-groq-tool-use:8b` and `nemotron-3-nano:4b` also collapsed to 0/6. `granite4.1:8b` and `granite4.1:3b` landed in between at ⚠️ 3/6, each losing half their cold-start options answers to prose. A ranking built only from cold-start numbers would have placed `llama3-chatqa:8b` above `gpt-oss:20b`; with history the order inverts. Sanity-checking the best performer, `gpt-oss:20b`, cold-start with `dump_reply.dart` confirmed the same question still returns `card[2]` with zero history — so its strength with history is a real property of the model, not an artifact of a weak cold-start baseline. History erosion is real and, across this run, the majority case: three of six models collapsed completely (0/6), two more were partially degraded (3/6), and only one of six (`gpt-oss:20b`) was unaffected — the failure mode is per-model, not a property of "local models" in general, and a model's cold-start score is not a reliable predictor of which side it lands on.

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
above regressed.

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

- **`llama3-chatqa:8b` swept everything** — 7/7 at all three temperatures and 5/5 stress at both. At 4.3 GB it is the strongest cheap candidate measured so far and deserves a closer look against the default.
- **The everyday set kept its reputation for not discriminating.** `nemotron-3-nano:4b` and `llama3-groq-tool-use:8b` both scored 6/7 everyday, then collapsed to 2/5 and 1/5 on the cases that matter. Judging either on the easy set alone would have been badly wrong.
- **`gpt-oss:20b`, a top-three model, had never been probed at all.** It is respectable but not better than models a third its size, which is worth knowing before recommending it.

All of these are **cold-start** numbers at `--samples 1`. None has been run with conversation history, and a single sample at `t=0.6` is noisy — treat the two 1/5 results as a flag to re-run, not a settled verdict.

### `qwen3.6:27b-coding-nvfp4`

**Scores worse at its own recommended temperature.** Its Modelfile ships `temperature 0.6`, but it passed 12/15 hard cases at `0` versus 9/15 at `0.6` — the extra failures being long card JSON truncated mid-generation. Both passed 7/7 easy cases, which is why the easy set alone is not a useful signal.

**Silently ignores `format`.** It answers the `format: json` canary with prose and no error, so `--json-format json|schema` is inert for it. Check the canary (`tool/model_probes/json_format_probe.dart`) before relying on the constraint.

### `qwen3.5:9b`

Usable **only with thinking disabled**, and even then offers no reliability edge over `qwen2.5-coder:7b` while costing more latency and memory. Its thinking capability is a liability for constrained-JSON output.

With server defaults of the time (temp 1, thinking on) it answered a checkbox request with a `CodeBlock` of raw HTML using invented keys (`codeLanguage`/`content` instead of `codeSnippet`), taking 77 s. The same model with `think:false` + `temperature:0` produced a clean `Input.ChoiceSet` and a clean 4-page Carousel in ~10 s.

Not recommended as the default for this workload. Listed in `launch.json`; not currently installed locally.

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
