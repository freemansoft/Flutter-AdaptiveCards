# Model probes

Hand-run scripts that measure whether a local Ollama model, at given decoding
settings, produces Adaptive Cards this server can actually render.

They exist because the interesting questions here are **empirical**. "Is
temperature 0 right?", "will `--json-format schema` protect me?", and "is this
card broken because of the model or because of us?" are all answerable in
minutes with a real model, and are all easy to get wrong by reasoning alone —
each of these scripts was written after an assumption turned out to be false.

Nothing here runs in CI. They need a local Ollama with the model pulled, they
take minutes to tens of minutes, and their output is evidence for a human
decision, not a pass/fail gate.

## The scripts

| Script                    | Question it answers                                                                         |
| ------------------------- | ------------------------------------------------------------------------------------------- |
| `temperature_matrix.dart` | Does this model handle everyday card requests, across three temperatures?                   |
| `temperature_stress.dart` | Which temperature survives the hard cases, and is the output stable?                        |
| `json_format_probe.dart`  | Does this model honor Ollama's `format` constraint at all?                                  |
| `dump_reply.dart`         | What did the model _literally_ emit, byte for byte? (use `--history` to replay prior turns) |
| `prompt_ab.dart`          | Does an edited card system prompt beat the one we ship?                                     |
| `choiceset_ab.dart`       | Does a pick-from-a-set question yield a clickable card?                                     |
| `shape_ab.dart`           | Which element types does this model actually emit, cold vs with history?                    |
| `probe_support.dart`      | Shared plumbing — not a probe.                                                              |

All accept `--model`, `--url`, `--samples`, and `-h`. Defaults come from the
server's own constants, so a bare run probes the current default model.

`prompt_ab.dart --prompts <file>` runs your own set — one prompt per line.
The built-in set is code-flavoured and cannot exercise other shapes.

```sh
cd adaptive_chat_server_dart
ollama serve                                   # if not already running
fvm dart run tool/model_probes/temperature_matrix.dart --model qwen2.5-coder:7b
```

Use `127.0.0.1`, not `localhost` — Ollama binds IPv4 while macOS often
resolves `localhost` to IPv6 first. That is the default here.

`dump_reply.dart --history <file>` replays prior turns the way the server
does. Sets 1–3 are all single-turn, so a bug that only appears after a few
turns of conversation is invisible to them — reach for `--history` before
concluding a reported bug does not reproduce.

`shape_ab.dart` is the shape-aware probe: 25 cases, each naming the element
types that would answer it acceptably (a set, not one type — "summarize these
specs" is defensibly a `FactSet` or a `Table`). It runs every case twice,
cold-start and after two prose turns, and prints which shapes were lost
between the two. Use `--only carousel,gauge` to re-check one shape without
paying for the other twenty-three, and `--candidate <file>` to A/B a prompt
change per shape.

Its failure labels distinguish five ways a card reply can be wrong:
`wrong-shape` (a card, but not an accepted type — the line names what came
back), `no-input` (a card with content but no `Input.*` where the prompt
asked the user for a value), `prose` (no card at all), `unwanted-card` (the
`prose` control case got a card back instead of the prose it expects), and
`broken` (invalid JSON, duplicate keys, or prose wrapping a card).

`choiceset_ab.dart`'s `_hasChoiceSet` deliberately judges differently: it
checks only whether a parsed card contains an `Input.ChoiceSet`, ignoring
`outcome.ok`. A duplicate-key-corrupted card containing a `ChoiceSet` counts
as a pass there but scores `broken` in `shape_ab.dart`. This is not a bug in
either script — the older reproducer stays frozen so its numbers stay
comparable over time, and `shape_ab.dart`'s stricter rule (agreeing with the
server's own verdict) is the one new probes should follow. If the two
probes' choice-set numbers ever diverge, this is the first place to look.

## How a reply is judged

Every probe judges replies with the server's **own** `tryParseCardBody`,
`cardParseFailureReason`, and `checkNoDuplicateJsonKeys`. A probe that applied
its own idea of "looks like a card" could report a pass rate the running
server disagrees with, which would be worse than no measurement.

A reply passes if it renders as a card **or** as clean prose — the card system
prompt explicitly permits a Markdown answer, so only a _broken_ card counts as
a failure.

## Reading the output

Each line is one call: setting, prompt, sample index, PASS/FAIL, latency,
reply length, an 8-character digest of the reply, and the verdict. The digest
is how you spot a model repeating itself exactly; `temperature_stress.dart`
counts distinct digests per cell for that reason.

Latency includes a cold model load on the first call. Re-run rather than
trusting a first-call number.

## What these found

Recorded so the next person can tell a new result from a known one. Measured
on an M-series Mac against Ollama, August 2026.

The durable, per-model record lives in [`../../ModelBehavior.md`](../../ModelBehavior.md) —
which model to reach for, which ones ignore `format`, and which settings beat
their own vendor defaults. Add findings there as well as here: this section is
about the probes, that file is about the models.

- **Judging a reply as "renders or not" hides most of the palette.** Before
  `shape_ab.dart`, exactly one of the 24 element types the card prompt
  advertises was ever asserted (`Input.ChoiceSet`, by `choiceset_ab.dart`).
  The everyday set's `table` case passed on a `TextBlock`; its `chart` case
  passed on plain Markdown.
- **`qwen3.6:27b-coding-nvfp4` scored worse at its own recommended
  temperature.** Its Modelfile ships `temperature 0.6`, but it passed 12/15
  hard cases at `0` versus 9/15 at `0.6`, the extra failures being long card
  JSON truncated mid-generation. Both passed 7/7 easy cases — the easy set
  does not discriminate, which is why the stress set exists. `0` remains the
  server default.
- **Temperature 0 is not deterministic.** A ~3.5K-character table produced
  two different outputs across three calls at `0`. Greedy decoding repeats
  short replies verbatim, but long generations still diverge. What `0` buys
  is a _stable failure mode_, not reproducible output.
- **`format` is silently ignored by some models.** `qwen3.6:27b-coding-nvfp4`
  answers the `format: json` canary with prose and no error, so
  `--json-format json|schema` is inert for it. `qwen2.5-coder:7b` honors it.
  Check the canary before relying on the constraint.
- **Forbidding a behavior moved it; giving it a home fixed it.** Asked to
  explain code, `qwen2.5-coder:7b` emitted a card and then appended the
  explanation, which makes the whole reply raw text. Telling it harder not to
  append (and to prefer Markdown when it wanted to) did **not** help — it
  scored the same and abandoned cards entirely, answering every code question
  as prose. Telling it where the explanation _goes_ — a `TextBlock` beside the
  `CodeBlock` in the same array — fixed it: hard cases went 6/10 → 15/15 at
  `t=0` and 7/10 → 14/15 at `t=0.6`. Prefer redirecting a model's behavior
  over prohibiting it.
- **Each prompt fix exposes the next failure.** Once the model started sending
  two elements, it began dropping the `[ ]` around them — valid intent,
  invalid JSON. Prompt wording cut that to near zero at `t=0` but not at
  `t=0.6`, so `card_detect.dart` also repairs the bracketless form. Wording
  moves the rate; only the detector makes a shape safe.
- **A "broken card" was our bug, not the model's.** `dump_reply.dart` showed
  a reply blamed on the model contained zero real newlines and 11 correctly
  escaped ones — valid JSON. The corruption came from this server's
  fence-stripping heuristic. Dump the bytes before theorising.
- **A cold-start pass predicts nothing about multi-turn behavior.** Sets
  1–3 are all single-turn, and that gap hid a whole failure class until
  `dump_reply.dart --history` and `choiceset_ab.dart` existed to replay
  prior turns the way the server actually does. Reach for one of them before
  trusting a cold-start number for a bug reported mid-conversation.
- **History erosion is per-model, not universal.** Running six models
  through `choiceset_ab.dart` with two prior prose turns collapsed three of
  six to 0/6, dropped two more to 3/6, and left one untouched at 6/6 — a
  model's cold-start score did not predict which side it landed on. See
  `ModelBehavior.md` for the per-model breakdown.

## Adding a probe

Keep one question per script and reuse `probe_support.dart` for the round
trip and the verdict. If a probe needs its own notion of success, that is a
signal the server's detection is what should change.
