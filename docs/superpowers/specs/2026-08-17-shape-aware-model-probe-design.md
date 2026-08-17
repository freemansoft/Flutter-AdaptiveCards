# Shape-aware model probe — design

**Status:** approved, ready for an implementation plan
**Package:** `adaptive_chat_server_dart`
**Date:** 2026-08-17

## The problem

Every probe in `tool/model_probes/` except one judges a reply with
`judgeReply`, which asks a single question: does this parse as a card, or as
clean prose? It never asks **which element types came back**. The consequences
are concrete:

- The everyday set's `table` case passes if the model replies with a
  `TextBlock`.
- Its `chart` case passes if the model replies with plain Markdown.
- The stress set's `nested` case — an expense form specified down to "a
  category dropdown with 6 categories" — passes on any renderable card at all.

`choiceset_ab.dart` is the sole exception: it requires a card _containing_ an
`Input.ChoiceSet`. That one shape-aware check is what exposed the history
erosion finding now recorded for thirteen models. Nothing equivalent exists
for the other twenty-three element types the card system prompt advertises.

Measured coverage against the 24 types in `assets/card_schema.json`'s enum:

| Coverage                                      | Types                                                                                                                                        |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Shape-verified (type actually asserted)       | `Input.ChoiceSet` — 1 of 24, with history only                                                                                               |
| Intended but unverified (a prompt aims at it) | `Input.Date`, `FactSet`, `Table`, `Chart.*`, `Rating`, `CodeBlock`                                                                           |
| Never exercised by any committed probe        | `Input.Toggle`, `Input.Text`, `Input.Number`, `Input.Time`, `Badge`, `Carousel`, `ColumnSet`, `Icon`, `ProgressBar`, `ProgressRing`, `Image` |

`Carousel` deserves a specific note: `ModelBehavior.md` cites Carousel results
for `llama3.2` (0/5) and `qwen3.5:9b` ("clean 4-page Carousel"), but no
committed probe elicits one today. Those numbers came from ad-hoc runs that
were never captured — exactly the loss `ModelBehavior.md` exists to prevent.

A latent defect this surfaced: the everyday set's `rating` prompt is _"Ask me
to rate my support experience from 1 to 5"_, which asks the **user** for a
value. But `Rating` is defined in the card system prompt as "a read-only star
rating (not an input; the user cannot change it)". That prompt is asking for
an input and would be satisfied by a `Rating` that cannot collect one — and
passes today because nothing checks. This design splits it into two cases.

## Goals

1. Verify which element types a model actually emits, per shape.
2. Let the model choose among **acceptable alternatives** rather than forcing
   one type where several are defensible.
3. Where a prompt asks the user for a value, assert that **some `Input.*`
   element is present** — and distinguish "wrong input type" from "no input at
   all".
4. Cover charts, `Rating`, and `Carousel`, none of which any committed probe
   exercises.
5. Report which shapes a model produces cold but loses once the conversation
   is in Markdown.

## Non-goals

- Running in CI. Like every script in this directory, it needs a live Ollama
  and produces evidence for a human decision, not a pass/fail gate.
- Replacing `choiceset_ab.dart`. Thirteen models' with-history scores in
  `ModelBehavior.md` cite it by name; it stays as their reproducer.
- Asserting `style` / `isMultiSelect` on `Input.ChoiceSet`. Radios,
  checkboxes, and dropdowns are all `Input.ChoiceSet` in Adaptive Cards; this
  probe checks the type, not which variant. Variant-level checking is a
  separate exercise.

## Architecture

Three pieces, each with one job.

### `probe_support.dart` — two new pure helpers

```dart
/// Every element "type" present anywhere in a parsed card body, including
/// inside Carousel pages, Table cells, and Column items.
Set<String> collectElementTypes(List<Map<String, dynamic>> body);

/// Whether any element in [body] has a type in [wanted].
bool cardContainsAnyType(List<Map<String, dynamic>> body, Set<String> wanted);
```

Both take the already-parsed body from `tryParseCardBody`, so they inherit the
server's own parsing rather than re-deciding what a card is — the standing
rule for every probe in this directory.

`collectElementTypes` exists so a `wrong-shape` failure can report what the
model _did_ emit. "Carousel failed" and "Carousel failed, it emitted three
TextBlocks" lead to different fixes.

**Placement:** these live in `tool/model_probes/probe_support.dart`, not in
`lib/src/card_detect.dart`. They answer a probe-only question — the server
never needs to ask whether a card contains a `ChoiceSet` — and putting them in
`lib/` would ship code the package does not use. Tests reach them by relative
import (`../tool/model_probes/probe_support.dart`).

### `shape_ab.dart` — the new probe

Owns the case table and the run loop. Delegates parsing to `tryParseCardBody`
and matching to the two helpers. The `_ab` suffix is literal, matching
`choiceset_ab.dart` and `prompt_ab.dart`: it takes `--baseline` and
`--candidate` prompt files so a wording change can be measured per shape.

```dart
class ShapeCase {
  final String id;            // 'carousel'
  final String prompt;        // the user turn
  final Set<String> accepted; // {'Carousel'}; empty means "expect prose"
  final bool requiresInput;   // assert some Input.* is present
}
```

An empty `accepted` set expresses the negative control: passing means the
model correctly _declined_ to send a card. This keeps one uniform case shape
rather than special-casing the control.

Each case runs under two conditions: cold-start, and with the same two prose
turns `choiceset_ab.dart` sends (`_historyUser` / `_historyAssistant`), so
with-history numbers stay comparable to the existing choice-set column.

### `choiceset_ab.dart` — refactored, behavior preserved

Its private `_hasChoiceSet` is replaced by
`cardContainsAnyType(body, {'Input.ChoiceSet'})`. Prompts, conditions, sample
handling, and output format are untouched, so the thirteen recorded scores
remain reproducible. The walker unit tests below are what make this refactor
provably safe.

## Matching rules

Order matters: `no-input` is checked **before** `wrong-shape`, because that is
the distinction between "sent the wrong input widget" and "sent no input at
all".

| Condition                                               | Label           | Pass |
| ------------------------------------------------------- | --------------- | ---- |
| `accepted` empty and reply is prose                     | `prose-ok`      | ✅   |
| `accepted` empty but reply is a card                    | `unwanted-card` | ❌   |
| Invalid JSON, duplicate keys, or prose wrapping a card  | `broken`        | ❌   |
| Reply is clean prose, a card was expected               | `prose`         | ❌   |
| Card parsed, `requiresInput` and zero `Input.*` present | `no-input`      | ❌   |
| Card parsed, no accepted type present                   | `wrong-shape`   | ❌   |
| Card parsed, an accepted type present                   | `ok`            | ✅   |

`prose-with-card` folds into `broken` rather than getting its own column: the
user-visible outcome is identical (raw JSON on screen), and `judgeReply`'s own
label still distinguishes it in the printed detail.

## Output

One block per condition, matching the existing probes' style:

```text
########## cold-start ##########
PASS  date          Input.Date
PASS  facts         FactSet
FAIL  carousel      wrong-shape: got {TextBlock} want {Carousel}
FAIL  gauge         prose
== cold-start    shapes 18/25 ==

########## with-history ##########
...
== with-history  shapes 11/25 ==

== eroded by history: bar, carousel, gauge, line, progress, rating_show, table (7) ==
```

The final line is the payoff — the shapes a model produces cold and loses once
the conversation is in Markdown. It is the direct input to any prompt fix, and
no existing probe can produce it.

**Flags:** the standard `--model`, `--url`, `--samples` (default 1), `-h`,
plus:

- `--only date,carousel` — run a subset. This earns its place because a full
  run on a 30B model takes about an hour; iterating on one shape should not
  cost the other twenty-four.
- `--baseline <file>` (defaults to `assets/card_system_prompt.txt`) and
  `--candidate <file>` — the same A/B interface `choiceset_ab.dart` and
  `prompt_ab.dart` expose. When `--candidate` is given, the whole case set
  runs twice more and prints both prompts' per-shape results.

The A/B pair is not optional decoration: the purpose of measuring shape
coverage is to fix the shapes that fail, and every prompt change in this
package is gated on measuring the candidate against the shipped prompt.
Without `--candidate` this probe could diagnose a problem it could not then
verify a fix for, and the fix would have to be measured by a different script
with a different case set.

## The case table (25 cases)

| id            | Prompt                                                                                     | Accepted                                   | Input? |
| ------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------ | ------ |
| `date`        | Book me a meeting. Ask me for a date.                                                      | `Input.Date`                               | ✅     |
| `time`        | Ask me what time I want the standup.                                                       | `Input.Time`                               | ✅     |
| `toggle`      | Ask me whether to enable email notifications.                                              | `Input.Toggle`, `Input.ChoiceSet`          | ✅     |
| `text`        | Ask me to describe the bug in a few sentences.                                             | `Input.Text`                               | ✅     |
| `number`      | Ask me how many seats I need to license.                                                   | `Input.Number`, `Input.Text`               | ✅     |
| `choice1`     | what are my options for deployment targets                                                 | `Input.ChoiceSet`                          | ✅     |
| `choice2`     | which log level should I use?                                                              | `Input.ChoiceSet`                          | ✅     |
| `choice3`     | what environments can I deploy to?                                                         | `Input.ChoiceSet`                          | ✅     |
| `choice4`     | what are my options for notification frequency                                             | `Input.ChoiceSet`                          | ✅     |
| `choice5`     | help me pick a database engine                                                             | `Input.ChoiceSet`                          | ✅     |
| `choice6`     | what build modes can I choose from?                                                        | `Input.ChoiceSet`                          | ✅     |
| `pie`         | Show the market share of the top 5 phone vendors as parts of a whole.                      | `Chart.Pie`, `Chart.Donut`                 | —      |
| `bar`         | Compare signups for Mon-Fri as a bar chart.                                                | `Chart.VerticalBar`, `Chart.HorizontalBar` | —      |
| `line`        | Show response time trending across the last 6 releases.                                    | `Chart.Line`                               | —      |
| `gauge`       | Show disk usage at 72% against a 0-100 range.                                              | `Chart.Gauge`                              | —      |
| `rating_show` | What's the average customer rating for the iPhone 15 Pro? Show it as stars.                | `Rating`                                   | —      |
| `rating_ask`  | Ask me to rate my support experience from 1 to 5.                                          | `Input.ChoiceSet`, `Input.Number`          | ✅     |
| `carousel`    | Walk me through setting up CI/CD in 3 steps, one step per page.                            | `Carousel`                                 | —      |
| `table`       | Table of the 4 largest planets with diameter and moons.                                    | `Table`                                    | —      |
| `facts`       | Summarize the iPhone 15 Pro specs as labelled facts.                                       | `FactSet`, `Table`                         | —      |
| `columnset`   | Compare SQLite and Postgres side by side.                                                  | `ColumnSet`, `Table`                       | —      |
| `codeblock`   | Dart snippet that reads a JSON file and prints the `name` field, with a short explanation. | `CodeBlock`                                | —      |
| `progress`    | Show me the deployment is 72% complete.                                                    | `ProgressBar`, `ProgressRing`              | —      |
| `badge`       | Show the current build status as a small status pill.                                      | `Badge`                                    | —      |
| `prose`       | In two sentences, why is the sky blue?                                                     | _(none — expect prose)_                    | —      |

The six `choice*` prompts are copied verbatim from `choiceset_ab.dart` so the
two probes' choice-set results stay directly comparable.

### Coverage against the 24-type schema enum

21 types asserted directly. Three are deliberately not asserted:

- **`TextBlock`** — exercised constantly but never asserted; it is the
  ubiquitous fallback, so asserting it would pass trivially.
- **`Icon`** — decorative. A model that omits an icon is not wrong.
- **`Image`** — the card system prompt forbids inventing image URLs, so an
  `Image` cannot be elicited honestly without supplying a real one.

## Testing

Three groups, all pure and CI-safe — no Ollama required.

1. **Walker behavior.** The tests that make the `choiceset_ab.dart` refactor
   provably safe. `collectElementTypes` finds a type at the top level of a
   bare array; nested inside `Carousel` → `pages` → `items`; inside `Table` →
   `rows` → `cells` → `items`; inside `ColumnSet` → `columns` → `items`; and
   in the full `{"type":"AdaptiveCard","body":[…]}` shape.
   `cardContainsAnyType` returns true when **any** accepted type is present
   (the alternatives rule) and false when none is.
2. **Case-table validity.** Every type in every `accepted` set is one of the
   24 in `card_schema.json`'s enum. This catches `Chart.Bar` (does not exist)
   or `Input.Toggl` before it silently fails every model and gets written into
   the durable record as a finding.
3. **Case-table sanity.** Ids unique; no empty prompts; `requiresInput` is
   true only where every accepted type is an `Input.*` — a case cannot
   sensibly demand an input while accepting `Table`.

The run loop itself stays untested, like every other script here: it needs a
live model, and its output is evidence for a human rather than a gate.

## Recording results

`ModelBehavior.md`'s main table gains a compact **`shapes N/25`** figure
alongside the existing choice-set score, and a new section carries the
per-model breakdown listing only the shapes that failed. This keeps the table
scannable while putting the detail where someone debugging a shape will look.

Per this file's standing rule, every recorded number names its model,
temperature, and condition (cold-start vs with-history).

## Rollout

Baseline on `qwen2.5-coder:7b` — the server default, fast, and the model with
the most existing history in the record. Decide from those results whether a
wider sweep is justified; a full 25-case, two-condition run on a 30B model is
roughly an hour, so a thirteen-model sweep is a separate decision, not an
automatic follow-on.

## Constraints inherited from the package

- Prefix every `dart` command with `fvm`.
- Work from `adaptive_chat_server_dart/`; it resolves standalone.
- Every change needs a `## [Unreleased]` bullet in `CHANGELOG.md`.
- Markdown is Prettier-governed (`npm run format:md:chat` / `check:md:chat`);
  Prettier rewrites `*italic*` to `_italic_`.
- `very_good_analysis`: single quotes, package imports, no `print`.
- Gates: `fvm dart analyze` clean, `fvm dart test` passing,
  `fvm dart format --output=none --set-exit-if-changed .` clean.
- One Ollama model resident at a time; never interleave models.

## Open risks

- **A wrong expectation poisons every number it produces.** This file has
  recorded one case already where a strict assertion was the bug rather than
  the model (`rows >= 3` failing a legitimate 2×2 `Table`). The alternatives
  design is the mitigation; the case-table validity test is the backstop.
- **`badge` and `progress` may be unelicitable in practice.** If no model
  produces them from these prompts, that is a finding about the prompt's
  palette section rather than about the models — record it as such rather than
  scoring every model down.
