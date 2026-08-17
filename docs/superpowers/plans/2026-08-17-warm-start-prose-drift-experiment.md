# Warm-Start Prose Drift Experiment Implementation Plan

> **Amended 2026-08-17, after approval, before execution.** This plan had not
> been started when `shape_ab.dart` was built and full 25-case baselines were
> recorded for four models in `ModelBehavior.md`. Those baselines invalidated
> the screening model set and the screening metric in the spec this plan
> implements — see the amendment note at the top of
> [`2026-08-17-warm-start-prose-drift-experiment-design.md`](../specs/2026-08-17-warm-start-prose-drift-experiment-design.md).
> Every task below is updated to the amended model set — `qwen2.5-coder:7b`
> (decides), `granite4.1:8b`, `gpt-oss:20b`, `llama3-chatqa:8b` (inform) —
> replacing the original `qwen2.5-coder:7b` / `llama3-chatqa:8b` /
> `nemotron-3-nano:4b` trio. This is a deliberate revision made before any run,
> not drift discovered after one.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Measure five candidate fixes for models dropping to prose once a conversation has gone to Markdown, attribute any improvement to a specific mechanism, and either ship the winner or record a measured negative.

**Architecture:** Two code tasks then six measurement tasks. The code tasks add `--reinforce` and `--seed-card` to `shape_ab.dart`, which is all the two non-prompt candidates need — `probeOnce` already assembles messages exactly as `OllamaResponder` does, so both are testable probe-side with no server change. The three prompt candidates are `/tmp` copies of the shipped prompt, each measured by pointing `--baseline` at it (one prompt per run, rather than paying for two prompts per run via `--candidate`). Screening then runs one deciding model and three informing models, winners stack, survivors face the full case set and the two standing regression gates.

**Tech Stack:** Dart 3.12 (FVM-pinned), `package:test`, `package:args`, a local Ollama at `http://127.0.0.1:11434`, Prettier for Markdown.

**Spec:** [`2026-08-17-warm-start-prose-drift-experiment-design.md`](../specs/2026-08-17-warm-start-prose-drift-experiment-design.md)

## Hard dependency on Plan 1

**Do not start this plan until [`2026-08-17-shape-aware-model-probe.md`](./2026-08-17-shape-aware-model-probe.md) is complete and merged.** Two reasons, both blocking:

1. **The instrument does not exist otherwise.** Every measurement here runs through `shape_ab.dart`, `shape_cases.dart`, and `judgeShape`, all of which Plan 1 creates. Tasks 1 and 2 below modify `shape_ab.dart`.
2. **The numbers are uninterpretable otherwise.** Plan 1 Task 6 records `qwen2.5-coder:7b`'s baseline cold-start and with-history pass-sets. A shape that model never produces cold-start is a capability or palette gap, not drift — scoring it here would credit or blame a candidate for something it cannot affect. **This plan's amended screening set (Task 4) needs three more of these: `granite4.1:8b`, `gpt-oss:20b`, and `llama3-chatqa:8b` — all four now exist, dated 2026-08-17, in `ModelBehavior.md`.**

Before Task 1, confirm all four:

```bash
cd adaptive_chat_server_dart
ls tool/model_probes/shape_ab.dart tool/model_probes/shape_cases.dart
grep -n "Shape coverage — \`qwen2.5-coder:7b\`" ModelBehavior.md
grep -n "Shape coverage — \`granite4.1:8b\`" ModelBehavior.md
grep -n "Shape coverage — \`gpt-oss:20b\`" ModelBehavior.md
grep -n "Shape coverage — \`llama3-chatqa:8b\`" ModelBehavior.md
```

All must succeed. If any `ModelBehavior.md` grep finds nothing, that model's baseline has not run and Task 4 cannot be interpreted for it — stop and report that.

## Global Constraints

- Prefix **every** `dart` and `flutter` command with `fvm`. Bare commands may resolve to a different SDK.
- Work from `adaptive_chat_server_dart/` unless a step says otherwise. It is **not** a pub workspace member — it resolves standalone via `fvm dart pub get`.
- **One Ollama model at a time.** Never run two probes concurrently, never interleave models. Unload with `curl -s http://127.0.0.1:11434/api/generate -d '{"model":"<tag>","keep_alive":0}' > /dev/null` and confirm with `curl -s http://127.0.0.1:11434/api/ps` returning `{"models":[]}` before loading the next. Tasks 3-7 each name their model explicitly.
- Every change under `adaptive_chat_server_dart/` needs a bullet in the `## [Unreleased]` section of `adaptive_chat_server_dart/CHANGELOG.md`.
- Markdown in this package is Prettier-governed. Run `npm run format:md:chat` from the repo root after editing any `.md`, and verify with `npm run check:md:chat`. **Prettier rewrites `*italic*` to `_italic_`** — this has broken the build twice.
- Analysis is `very_good_analysis`: single quotes, package imports for `lib/`, no `print` (use `stdout.writeln` in scripts).
- Gates before any task is complete: `fvm dart analyze` clean, `fvm dart test` all passing, `fvm dart format --output=none --set-exit-if-changed .` clean.
- Probe numbers are only meaningful with their condition attached. Always record **which model**, **which temperature**, **cold-start vs with-history**, **sample count**, and **which candidate**.
- **Promotion turns on `qwen2.5-coder:7b` alone.** `granite4.1:8b`, `gpt-oss:20b`, and `llama3-chatqa:8b` inform how a result is described and surface harm; they do not vote. See Task 8.
- **Nothing shipping is an allowed outcome.** Four models (a broader set than this plan's screening subset) sit at 0/6 on `choiceset_ab.dart` with the current anti-drift wording already in place. If no candidate improves the default model, the deliverable is a recorded negative — Task 8 covers that path explicitly.

---

## File Structure

| File                                   | Responsibility                                   | Tasks |
| -------------------------------------- | ------------------------------------------------ | ----- |
| `tool/model_probes/probe_support.dart` | Gains an optional trailing-reminder parameter    | 1     |
| `test/probe_reinforce_test.dart`       | That parameter's message-assembly behavior       | 1     |
| `tool/model_probes/shape_cases.dart`   | Gains the card-shaped seed history constants     | 2     |
| `tool/model_probes/shape_ab.dart`      | Gains `--reinforce` and `--seed-card`            | 1, 2  |
| `assets/card_system_prompt.txt`        | Only if a prompt candidate is promoted           | 8     |
| `ModelBehavior.md`                     | Delivery check, screening results, final outcome | 3-8   |
| `CHANGELOG.md`                         | One bullet per task                              | 1-8   |

---

### Task 1: `--reinforce` — a system reminder after the history

N1's hypothesis is that the shape rule loses to distance. This adds the ability to place it adjacent to generation instead, and a unit test that proves the message actually lands in the right position — separate from Task 3, which checks whether the model _receives_ it.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/probe_support.dart`
- Create: `adaptive_chat_server_dart/test/probe_reinforce_test.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `probeOnce` from `probe_support.dart` (Plan 1 left it with parameters `client`, `url`, `model`, `systemPrompt`, `userPrompt`, `history`, `options`, `format`).
- Produces:

  - `List<Map<String, String>> buildProbeMessages({required String systemPrompt, required String userPrompt, List<String> history, String? reminder})` — extracted so the ordering is testable without HTTP.
  - `probeOnce` gains `String? reminder`.
  - `const String reinforceReminder` in `shape_cases.dart` is added in this task too, since both `shape_ab.dart` and Task 3's delivery check need the exact text.
  - `shape_ab.dart` gains `--reinforce`.

  Task 2 adds `--seed-card` beside it; Task 3 uses `reinforceReminder`.

- [ ] **Step 1: Write the failing test**

Create `adaptive_chat_server_dart/test/probe_reinforce_test.dart`:

```dart
import 'package:test/test.dart';

// Relative: probe_support lives outside lib/.
import '../tool/model_probes/probe_support.dart';

void main() {
  group('buildProbeMessages', () {
    test('without a reminder: system, history, user', () {
      final messages = buildProbeMessages(
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        history: const ['u1', 'a1'],
      );
      expect(
        messages.map((m) => '${m['role']}:${m['content']}').toList(),
        equals(['system:SYS', 'user:u1', 'assistant:a1', 'user:NOW']),
      );
    });

    test('with a reminder: it lands AFTER history, BEFORE the user turn', () {
      // The whole point of N1 is adjacency to generation. If the reminder
      // drifts before the history, this candidate is not being tested.
      final messages = buildProbeMessages(
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        history: const ['u1', 'a1'],
        reminder: 'REMIND',
      );
      expect(
        messages.map((m) => '${m['role']}:${m['content']}').toList(),
        equals([
          'system:SYS',
          'user:u1',
          'assistant:a1',
          'system:REMIND',
          'user:NOW',
        ]),
      );
    });

    test('a reminder with empty history still precedes the user turn', () {
      final messages = buildProbeMessages(
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        reminder: 'REMIND',
      );
      expect(
        messages.map((m) => '${m['role']}:${m['content']}').toList(),
        equals(['system:SYS', 'system:REMIND', 'user:NOW']),
      );
    });

    test('history alternates user/assistant from index 0', () {
      final messages = buildProbeMessages(
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        history: const ['a', 'b', 'c'],
      );
      expect(
        messages.map((m) => m['role']).toList(),
        equals(['system', 'user', 'assistant', 'user', 'user']),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd adaptive_chat_server_dart && fvm dart test test/probe_reinforce_test.dart`

Expected: compile failure — `buildProbeMessages` is not defined.

- [ ] **Step 3: Extract the message builder and add the parameter**

In `adaptive_chat_server_dart/tool/model_probes/probe_support.dart`, add above `probeOnce`:

```dart
/// Builds the `/api/chat` message list, mirroring `OllamaResponder`.
///
/// Extracted so the ordering is testable without an HTTP round trip. When
/// [reminder] is given it is inserted as a second `system` message **after**
/// the history and immediately before [userPrompt] — adjacency to generation
/// is the entire hypothesis it exists to test, so its position is asserted in
/// `test/probe_reinforce_test.dart` rather than left to inspection.
List<Map<String, String>> buildProbeMessages({
  required String systemPrompt,
  required String userPrompt,
  List<String> history = const [],
  String? reminder,
}) => [
  {'role': 'system', 'content': systemPrompt},
  for (final (i, turn) in history.indexed)
    {'role': i.isEven ? 'user' : 'assistant', 'content': turn},
  if (reminder != null) {'role': 'system', 'content': reminder},
  {'role': 'user', 'content': userPrompt},
];
```

Then in `probeOnce`, add the parameter to its signature, directly after `history`:

```dart
  String? reminder,
```

and replace the inline `'messages': [...]` list in its `jsonEncode` call with:

```dart
      'messages': buildProbeMessages(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        history: history,
        reminder: reminder,
      ),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd adaptive_chat_server_dart && fvm dart test`

Expected: PASS — the 4 new tests plus everything Plan 1 left green. The other probes call `probeOnce` with named arguments only and never pass `reminder`, so its `null` default leaves their message lists byte-identical.

- [ ] **Step 5: Add the reminder text and the flag**

In `adaptive_chat_server_dart/tool/model_probes/shape_cases.dart`, append:

```dart
/// N1's reminder, injected after the history by `shape_ab.dart --reinforce`.
///
/// Lives here rather than in the runner because Task 3's delivery check and
/// the experiment itself must use the same bytes.
const reinforceReminder =
    'Reminder: decide the reply shape from the question you are about to '
    'answer, not from the format of earlier turns. If it asks the user to '
    'choose, enter, schedule, or rate something, or to see a table or chart, '
    'reply with a card.';
```

In `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart`:

Add to the parser, after `--only`:

```dart
    ..addFlag(
      'reinforce',
      negatable: false,
      help: 'N1: inject a shape reminder as a system message after the '
          'history, immediately before the current user turn.',
    )
```

Thread it through. `runCondition` gains a parameter:

```dart
  required bool reinforce,
```

and its `probeOnce` call gains:

```dart
        reminder: reinforce ? reinforceReminder : null,
```

`runPrompt` gains the same `required bool reinforce` parameter and passes it to both `runCondition` calls. `main` reads `parsed['reinforce'] as bool` and passes it to both `runPrompt` calls.

Also extend the run header in `runPrompt` so the output records which candidate produced it — a transcript that does not say what it was measuring is not evidence:

```dart
  stdout.writeln('\n===== $label =====');
```

becomes:

```dart
  final flags = [
    if (reinforce) 'reinforce',
  ];
  stdout.writeln(
    '\n===== $label${flags.isEmpty ? '' : ' [${flags.join(', ')}]'} =====',
  );
```

- [ ] **Step 6: Verify the flag is wired and inert by default**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/shape_ab.dart --help | grep -A2 reinforce
fvm dart run tool/model_probes/shape_ab.dart --model qwen2.5-coder:7b --only prose --reinforce
```

Expected: help text lists `--reinforce`; the run prints `===== baseline [reinforce] =====`. Then unload:

```bash
curl -s http://127.0.0.1:11434/api/generate -d '{"model":"qwen2.5-coder:7b","keep_alive":0}' > /dev/null
```

- [ ] **Step 7: Changelog, gates, commit**

```markdown
- Added: `shape_ab.dart --reinforce` (candidate N1) injects a shape reminder
  as a `system` message after the replayed history and immediately before the
  current user turn. `probeOnce` gained an optional `reminder`, and its
  message assembly moved into a testable `buildProbeMessages` — the
  reminder's position is the whole hypothesis, so a unit test asserts it lands
  after history rather than leaving that to inspection. Every other probe
  passes no reminder, so their requests are unchanged.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/probe_support.dart \
        adaptive_chat_server_dart/tool/model_probes/shape_cases.dart \
        adaptive_chat_server_dart/tool/model_probes/shape_ab.dart \
        adaptive_chat_server_dart/test/probe_reinforce_test.dart \
        adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add --reinforce for the N1 drift candidate"
```

---

### Task 2: `--seed-card` — a card-shaped history seed

N2's hypothesis is that the conversation's established format is what the model imitates. This prepends a synthetic exchange in which the assistant already answered with a card.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/shape_cases.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `shapeHistoryUser`, `shapeHistoryAssistant` from Plan 1 Task 2; the `reinforce` threading from Task 1.
- Produces: `const String seedCardUser`, `const String seedCardAssistant` in `shape_cases.dart`; `shape_ab.dart` gains `--seed-card`.

- [ ] **Step 1: Add the seed exchange**

In `adaptive_chat_server_dart/tool/model_probes/shape_cases.dart`, append:

```dart
/// N2's synthetic leading user turn, prepended by `--seed-card`.
///
/// Deliberately unrelated to every case prompt in [shapeCases], so a pass
/// cannot come from the model copying this exchange's subject matter. It is
/// the *format* that is being seeded, not the content.
const seedCardUser = 'what timezone should I use for the nightly build?';

/// The card-shaped assistant half of [seedCardUser]'s exchange.
///
/// A bare element array — the shape the card system prompt tells the model to
/// prefer — so the seed models good output as well as the card habit.
const seedCardAssistant =
    '[{"type":"TextBlock","text":"Pick a timezone for the nightly build:",'
    '"wrap":true},{"type":"Input.ChoiceSet","id":"tz","style":"compact",'
    '"choices":[{"title":"UTC","value":"+0000"},'
    '{"title":"CET","value":"+0100"}]}]';
```

- [ ] **Step 2: Wire the flag**

In `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart`, add to the parser after `--reinforce`:

```dart
    ..addFlag(
      'seed-card',
      negatable: false,
      help: 'N2: prepend a synthetic card-shaped exchange ahead of the '
          'replayed history, so a card is the established format.',
    )
```

`runCondition` gains `required bool seedCard`, and its history argument becomes:

```dart
        history: [
          if (seedCard) ...[seedCardUser, seedCardAssistant],
          if (withHistory) ...[shapeHistoryUser, shapeHistoryAssistant],
        ],
```

Note this replaces the previous `const` list with a computed one, so drop the `const` keyword there.

`runPrompt` gains `required bool seedCard`, passes it to both `runCondition` calls, and adds it to the flags label:

```dart
  final flags = [
    if (reinforce) 'reinforce',
    if (seedCard) 'seed-card',
  ];
```

`main` reads `parsed['seed-card'] as bool` and passes it to both `runPrompt` calls.

- [ ] **Step 3: Verify the seed lands and alternation is preserved**

`--seed-card` prepends two turns, so the real history must still start on a `user` role. Confirm with the cheapest possible live check:

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/shape_ab.dart --model qwen2.5-coder:7b --only choice1 --seed-card
```

Expected: `===== baseline [seed-card] =====`, both conditions run, no crash. The alternation is `user, assistant, user, assistant` for the with-history condition (seed pair then prose pair), which `buildProbeMessages` produces because both are even-length. Then unload the model.

For a byte-level confirmation of what was sent, dump one reply with matching history:

```bash
cd adaptive_chat_server_dart
cat > /tmp/seed_u.txt <<'EOF'
what timezone should I use for the nightly build?
EOF
cat > /tmp/seed_a.txt <<'EOF'
[{"type":"TextBlock","text":"Pick a timezone for the nightly build:","wrap":true},{"type":"Input.ChoiceSet","id":"tz","style":"compact","choices":[{"title":"UTC","value":"+0000"},{"title":"CET","value":"+0100"}]}]
EOF
cat > /tmp/hist_u.txt <<'EOF'
what is CI/CD?
EOF
cat > /tmp/hist_a.txt <<'EOF'
CI/CD is a practice where code changes are automatically built, tested, and deployed.

- **CI** builds and tests every commit.
- **CD** ships passing builds to production.
EOF
fvm dart run tool/model_probes/dump_reply.dart --model qwen2.5-coder:7b \
  --history /tmp/seed_u.txt --history /tmp/seed_a.txt \
  --history /tmp/hist_u.txt --history /tmp/hist_a.txt \
  --prompt 'what are my options for deployment targets'
curl -s http://127.0.0.1:11434/api/generate -d '{"model":"qwen2.5-coder:7b","keep_alive":0}' > /dev/null
```

Expected: `history turns : 4` and a verdict. Record it — it is a preview of N2's effect on this prompt, though not a substitute for Task 4's screening run.

- [ ] **Step 4: Changelog, gates, commit**

```markdown
- Added: `shape_ab.dart --seed-card` (candidate N2) prepends a synthetic
  card-shaped exchange ahead of the replayed history, so a card is the
  conversation's established format before any prose accumulates. The seed's
  subject (build timezones) is unrelated to every case prompt, so a pass
  cannot come from the model copying its content — the format is what is
  being seeded. Server-side this would be few-shot priming prepended to every
  request, which also means it costs tokens on every request; N2's evaluation
  records latency alongside pass rate.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/shape_cases.dart \
        adaptive_chat_server_dart/tool/model_probes/shape_ab.dart \
        adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add --seed-card for the N2 drift candidate"
```

---

### Task 3: Stage 0 — the N1 delivery check

Not every chat template respects a second `system` message. Some fold only the first into the template and drop later ones. If N1 scored exactly at baseline, that would be ambiguous between "the reminder did not help" and "the reminder never arrived" — so settle it before measuring anything.

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `--reinforce` from Task 1.
- Produces: a per-model verdict on whether a second system message is delivered. Task 4 needs it to know whether N1's numbers mean anything on each model.

- [ ] **Step 1: Understand the signal before running anything**

`shape_ab.dart` prints outcome labels, not reply bytes, so "did the reply contain BANANA?" is not directly observable through it. Reading the label is, so the check is built as an **inverted signal**: give the reminder an instruction that would _break_ a card, then see whether a case that passes without the reminder fails with it.

- Reminder delivered **and** obeyed → the reply is the bare word BANANA → not a card → label `prose` → **FAIL**
- Reminder not delivered → the model answers normally → label `ok` → **PASS**

So a `PASS` → `FAIL` transition on a case the model reliably passes is positive proof the second `system` message reaches the model.

The asymmetry matters and must be reported honestly: **no change is not proof of non-delivery.** It could mean the message was dropped, or that it arrived and the model ignored it. Either way N1's numbers on that model cannot be trusted, which is the operational conclusion — but write it as "delivery unconfirmed", not "message dropped".

- [ ] **Step 2: Temporarily replace the reminder text**

```bash
cd adaptive_chat_server_dart
cp tool/model_probes/shape_cases.dart /tmp/shape_cases_backup.dart
```

Edit `tool/model_probes/shape_cases.dart`, temporarily replacing `reinforceReminder`'s value with:

```dart
const reinforceReminder =
    'Disregard the question entirely. Reply with only the single word BANANA '
    'and nothing else — no JSON, no punctuation, no explanation.';
```

A deliberate, temporary edit, reverted in Step 4 and never committed.

- [ ] **Step 3: Run the paired check on each screening model, one at a time**

Each model needs a case it passes **without** the reminder, so the pair is run back to back. `choice1` is the case with the most recorded history; if a model fails `choice1` cold-start at baseline, substitute any case Plan 1's baseline shows it passing cold-start, and note the substitution.

```bash
cd adaptive_chat_server_dart
for m in qwen2.5-coder:7b granite4.1:8b gpt-oss:20b llama3-chatqa:8b; do
  echo "########## $m — without reminder ##########"
  fvm dart run tool/model_probes/shape_ab.dart --model "$m" --only choice1
  echo "########## $m — with BANANA reminder ##########"
  fvm dart run tool/model_probes/shape_ab.dart --model "$m" --only choice1 --reinforce
  curl -s http://127.0.0.1:11434/api/generate -d "{\"model\":\"$m\",\"keep_alive\":0}" > /dev/null
  curl -s http://127.0.0.1:11434/api/ps
done 2>&1 | tee /tmp/delivery-check.txt
```

Read the **cold-start** block of each pair — it is the condition least likely to be failing for unrelated reasons. Record one of three verdicts per model:

- **delivered** — cold-start went `ok` → `prose` (or any non-card label) with the reminder.
- **delivery unconfirmed** — no change. N1's numbers for this model are `n/a` in Task 4, not a null result.
- **inconclusive** — the case failed even without the reminder, so there was no baseline to break. Substitute a different case and re-run.

- [ ] **Step 4: Revert the temporary edit**

```bash
cd adaptive_chat_server_dart
cp /tmp/shape_cases_backup.dart tool/model_probes/shape_cases.dart
git diff --stat tool/model_probes/shape_cases.dart
```

Expected: no output from `git diff --stat` — the file is byte-identical to the committed version. **Do not proceed until this is clean**; measuring the experiment with the BANANA text in place would invalidate every N1 number.

- [ ] **Step 5: Record the delivery-check result**

Add to `adaptive_chat_server_dart/ModelBehavior.md`, in the `## Cross-model results` section:

```markdown
- **A second `system` message is not universally delivered.** Ollama chat
  templates vary in whether a `system` message placed after the conversation
  history reaches the model at all; some keep only the first. Checked
  2026-08-17 by setting the injected reminder to "always begin your reply with
  the word BANANA" and reading the reply: `<per-model results>`. This matters
  before interpreting any mid-conversation reinforcement result — a candidate
  that scores exactly at baseline on a model that silently drops the message
  has not been tested on it.
```

Replace `<per-model results>` with the three actual verdicts.

- [ ] **Step 6: Changelog, format, commit**

```markdown
- Added: a delivery check for mid-conversation `system` messages, recorded in
  `ModelBehavior.md`. Ollama chat templates differ in whether a `system`
  message placed after the history reaches the model; measured per screening
  model on 2026-08-17 by making the injected reminder demand the word BANANA.
  Without this, a candidate scoring at baseline is ambiguous between "did not
  help" and "never arrived".
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/.claude/worktrees/normalize-qwen-samples
npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): record which models receive a mid-conversation system message"
```

---

### Task 4: Stage 1 — screen all five candidates

Six configurations per model. The deciding model runs at `--samples 2`; the three informing models at `--samples 1`.

**Files:**

- Create (temporary, never committed): `/tmp/p1.txt`, `/tmp/p2.txt`, `/tmp/p3.txt`
- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `--reinforce` (Task 1), `--seed-card` (Task 2), the delivery-check verdicts (Task 3), Plan 1's baseline, the four `#### Shape coverage — …` baselines already in `ModelBehavior.md`.
- Produces: per-candidate with-history and cold-start scores for four models. Task 5 stacks whatever won.

- [ ] **Step 1: Build the three candidate prompt files**

```bash
cd adaptive_chat_server_dart
cp assets/card_system_prompt.txt /tmp/p1.txt
cp assets/card_system_prompt.txt /tmp/p2.txt
cp assets/card_system_prompt.txt /tmp/p3.txt
```

**P1** — append this to the very end of `/tmp/p1.txt`, after the `### Structured-output mode` section, so it is the last thing the model reads:

```txt

## Before you answer: pick the shape

Look only at the CURRENT question. If it asks the user to choose, pick, enter,
schedule, or rate something — or asks to see data as a table, a chart, or
labelled facts — answer with reply shape 1 (a card). Answer with reply shape 2
only when none of those apply. What shape you used in earlier turns is not
evidence about this turn: a conversation that has been plain Markdown for five
turns still gets a card the moment the user asks to pick something.
```

**P2** — in `/tmp/p2.txt`, find the line `## Reply shape 2: Plain Markdown (no structured input)` and insert this as a new paragraph immediately after it (before the existing "When no structured input or layout is useful" paragraph):

```txt

Do NOT use this shape when the current question asks the user to choose, pick,
enter, schedule, or rate something, or asks to see data as a table or chart —
those get reply shape 1, even when every earlier turn in this conversation was
Markdown.
```

**P3** — in `/tmp/p3.txt`, find the paragraph that currently reads:

```txt
If no element type in the list below fits what you need to show, use reply
shape 2 (plain Markdown) instead — a malformed card is shown to the user as raw
JSON text, which is far worse than a plain Markdown answer.
```

and append to it, in the same paragraph:

```txt
 This is an escape for shapes the list cannot express, NOT a preference: if the
question asks the user to choose, enter, schedule, or rate something, or to see
a table or chart, the list does fit it and shape 1 is required. A Markdown
bullet list is never the fitting answer to "what are my options".
```

Verify each file differs from the shipped prompt in exactly one place:

```bash
cd adaptive_chat_server_dart
for f in /tmp/p1.txt /tmp/p2.txt /tmp/p3.txt; do
  echo "=== $f ==="
  diff assets/card_system_prompt.txt "$f" | head -30
done
```

Expected: each diff shows one added block and nothing else.

- [ ] **Step 2: Pick the screening subset**

The subset spans the failure surface: two ChoiceSet cases, another input, two display shapes, one chart.

```
choice1,choice2,date,table,carousel,gauge
```

Before running, check these against each model's recorded 25-case baseline in
`ModelBehavior.md` (`#### Shape coverage — …`). **Any case that failed
cold-start under the baseline prompt is not a drift case for that model** — it
cannot be eroded because it never worked. If one of the six is in that group
for a given model, note it and read that model's numbers over the remaining
cases; do not silently keep a 6-case denominator that includes a case the
model never passes.

This distinction reads differently depending on which of the two per-spec
metrics applies to the model (see the spec's "The screening metric depends on
the model's baseline"):

- **`qwen2.5-coder:7b` and `granite4.1:8b`** — erosion reduction. Read
  with-history rising toward that model's own cold-start score on the subset.
- **`llama3-chatqa:8b`** — absolute improvement. All six subset cases
  (`choice1`, `choice2`, `date`, `table`, `carousel`, `gauge`) sit outside its
  one 25-case cold-start pass (its `prose` case is not in the subset), so its
  baseline on this subset is 0/6 cold **and** 0/6 warm. That is the expected,
  correctly-recorded floor for this model on this metric — not a run to
  discard — and any nonzero score under a candidate, cold or warm, is the
  signal this model exists in the screen to catch.
- **`gpt-oss:20b`** — harm control. Read whether either score drops from its
  own baseline on the subset; a drop is the flag this model exists to catch,
  not evidence for or against the candidate's mechanism.

- [ ] **Step 3: Screen the deciding model at `--samples 2`**

```bash
cd adaptive_chat_server_dart
SUB=choice1,choice2,date,table,carousel,gauge
M=qwen2.5-coder:7b
for cfg in "baseline" "p1" "p2" "p3" "reinforce" "seed-card"; do
  echo "########## $M / $cfg ##########"
  case "$cfg" in
    baseline)   fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 2 --only "$SUB" ;;
    p1)         fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 2 --only "$SUB" --baseline /tmp/p1.txt ;;
    p2)         fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 2 --only "$SUB" --baseline /tmp/p2.txt ;;
    p3)         fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 2 --only "$SUB" --baseline /tmp/p3.txt ;;
    reinforce)  fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 2 --only "$SUB" --reinforce ;;
    seed-card)  fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 2 --only "$SUB" --seed-card ;;
  esac
done 2>&1 | tee /tmp/screen-qwen.txt
curl -s http://127.0.0.1:11434/api/generate -d "{\"model\":\"$M\",\"keep_alive\":0}" > /dev/null
curl -s http://127.0.0.1:11434/api/ps
```

Note the prompt candidates are passed via `--baseline`, not `--candidate`: each run measures one prompt, and using `--baseline` keeps the output's single `===== baseline =====` block per run rather than doubling every run's cost.

Expected: 6 blocks, each with cold-start, with-history, and an erosion line. Confirm `{"models":[]}` at the end.

- [ ] **Step 4: Screen the three informing models at `--samples 1`**

Same loop, one model at a time, `--samples 1`:

```bash
cd adaptive_chat_server_dart
SUB=choice1,choice2,date,table,carousel,gauge
for M in granite4.1:8b gpt-oss:20b llama3-chatqa:8b; do
  for cfg in "baseline" "p1" "p2" "p3" "reinforce" "seed-card"; do
    echo "########## $M / $cfg ##########"
    case "$cfg" in
      baseline)   fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 1 --only "$SUB" ;;
      p1)         fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 1 --only "$SUB" --baseline /tmp/p1.txt ;;
      p2)         fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 1 --only "$SUB" --baseline /tmp/p2.txt ;;
      p3)         fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 1 --only "$SUB" --baseline /tmp/p3.txt ;;
      reinforce)  fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 1 --only "$SUB" --reinforce ;;
      seed-card)  fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 1 --only "$SUB" --seed-card ;;
    esac
  done
  curl -s http://127.0.0.1:11434/api/generate -d "{\"model\":\"$M\",\"keep_alive\":0}" > /dev/null
  curl -s http://127.0.0.1:11434/api/ps
done 2>&1 | tee /tmp/screen-informing.txt
```

For any model where Task 3 found the reminder is not delivered, the `reinforce` run's numbers are `n/a`, not a result. Say so in the write-up.

- [ ] **Step 5: Tabulate**

Build this table from the two transcripts (`/tmp/screen-qwen.txt`, `/tmp/screen-informing.txt`). Every cell is with-history / cold-start for the six-case subset:

| Candidate | `qwen2.5-coder:7b` (decides, n=2) | `granite4.1:8b` (informs) | `gpt-oss:20b` (informs) | `llama3-chatqa:8b` (informs) |
| --------- | --------------------------------- | ------------------------- | ----------------------- | ---------------------------- |
| baseline  |                                   |                           |                         |                              |
| P1        |                                   |                           |                         |                              |
| P2        |                                   |                           |                         |                              |
| P3        |                                   |                           |                         |                              |
| N1        |                                   |                           |                         |                              |
| N2        |                                   |                           |                         |                              |

Also record N2's average latency against baseline's, since N2 costs tokens on every request.

- [ ] **Step 6: Apply the promotion bar and record**

A candidate advances when **both** hold on `qwen2.5-coder:7b`:

1. with-history passes **increase** over baseline, and
2. cold-start passes **do not decrease** (so it cannot win by dragging cold start down to meet with-history).

The informing models do not gate; they determine wording. Write the results into `ModelBehavior.md` under `### 4. Multi-turn set — history replay`:

```markdown
#### Warm-start drift candidates screened 2026-08-17

Six configurations — baseline plus five candidates — over a six-case subset
(`choice1`, `choice2`, `date`, `table`, `carousel`, `gauge`) at `t=0`, both
conditions, via `shape_ab.dart`. `qwen2.5-coder:7b` at `--samples 2` decides;
`granite4.1:8b`, `gpt-oss:20b`, and `llama3-chatqa:8b` at `--samples 1`
inform — `granite4.1:8b` as a second drift data point (erosion-reduction
metric), `gpt-oss:20b` as harm control, `llama3-chatqa:8b` as the
absolute-improvement floor.

<the table from Step 5>

Advancing to the stacked run: `<ids, or "none">`.

<One paragraph per candidate that lost, saying what it scored and that it is
not worth retrying. A measured negative is the point of recording losers.>
```

- [ ] **Step 7: Changelog, format, commit**

```markdown
- Added: screening results for five warm-start drift candidates (P1 recency,
  P2 Markdown-section guard, P3 escape-hatch narrowing, N1 mid-conversation
  reminder, N2 card-shaped history seed), measured 2026-08-17 over a six-case
  subset at `t=0` with `shape_ab.dart`. `qwen2.5-coder:7b` at `--samples 2`
  decided; three informing models at `--samples 1` (`granite4.1:8b`,
  `gpt-oss:20b`, `llama3-chatqa:8b`) informed the wording and surfaced harm.
  Advancing: `<ids or none>`. Losers are recorded with their numbers so they
  are not retried.
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/.claude/worktrees/normalize-qwen-samples
npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): screen five warm-start drift candidates"
```

**If no candidate advanced, skip Tasks 5-7 and go straight to Task 8's negative-result path.**

---

### Task 5: Stage 2 — stack the winners

Attribution came from Task 4. This measures whether the winners compose or interfere.

**Files:**

- Create (temporary): `/tmp/stack.txt`
- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: Task 4's advancing set.
- Produces: the configuration Task 6 confirms.

- [ ] **Step 1: Build the stacked configuration**

If two or more prompt candidates advanced, build one file carrying all their edits:

```bash
cd adaptive_chat_server_dart
cp assets/card_system_prompt.txt /tmp/stack.txt
```

Apply each advancing prompt candidate's edit to `/tmp/stack.txt` using the exact text from Task 4 Step 1. Then confirm it carries every intended edit and nothing else:

```bash
cd adaptive_chat_server_dart
diff assets/card_system_prompt.txt /tmp/stack.txt
```

Expected: one added block per advancing prompt candidate.

If only one prompt candidate advanced, `/tmp/stack.txt` is just that candidate's file — note that and skip ahead. If only N-candidates advanced, there is no stacked prompt file; the stack is the flag combination.

- [ ] **Step 2: Run the stack on all four screening models**

```bash
cd adaptive_chat_server_dart
SUB=choice1,choice2,date,table,carousel,gauge
# Add --reinforce and/or --seed-card below only for N-candidates that advanced.
# Use --baseline /tmp/stack.txt only if a prompt candidate advanced.
for M in qwen2.5-coder:7b granite4.1:8b gpt-oss:20b llama3-chatqa:8b; do
  N=1; [ "$M" = "qwen2.5-coder:7b" ] && N=2
  echo "########## $M / stack ##########"
  fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples "$N" --only "$SUB" --baseline /tmp/stack.txt
  curl -s http://127.0.0.1:11434/api/generate -d "{\"model\":\"$M\",\"keep_alive\":0}" > /dev/null
done 2>&1 | tee /tmp/stack-run.txt
curl -s http://127.0.0.1:11434/api/ps
```

- [ ] **Step 3: Compare against the best single candidate**

The stack advances only if it beats the **best single candidate** on `qwen2.5-coder:7b`'s with-history score, not merely baseline. A stack that ties its best member is worse than that member, because it carries more prompt text and more risk for no gain — in that case carry the single candidate forward to Task 6 and record that stacking did not compose.

- [ ] **Step 4: Record, changelog, gates, commit**

Append to the `#### Warm-start drift candidates screened 2026-08-17` subsection in `ModelBehavior.md`:

```markdown
Stacked run (`<which candidates>`): `qwen2.5-coder:7b` with-history
`<score>` versus `<best single candidate>`'s `<score>`. `<Whether stacking
composed, interfered, or tied — and which configuration goes to
confirmation.>`
```

```markdown
- Added: stacked-configuration result for the warm-start drift candidates
  that individually beat baseline. Measured 2026-08-17 on the same six-case
  subset and four models. `<Composed / tied / interfered>`; the
  configuration carried into full confirmation is `<...>`.
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/.claude/worktrees/normalize-qwen-samples
npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): measure the stacked warm-start drift configuration"
```

---

### Task 6: Stage 3 — confirm on the full case set and a wider model set

A six-case subset chosen to span the failure surface may not represent all 25. This is where that gets checked.

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: Task 5's surviving configuration.
- Produces: the full-set evidence Task 8's promotion decision rests on.

- [ ] **Step 1: Run the survivor on the full 25 cases**

Models, one at a time: the four screening models plus the two remaining
total-collapse models (`llama3-groq-tool-use:8b`, `nemotron-3.5-lightning:30b`)
— six models total. The "at least one strong model" check the original design
required is already satisfied by `gpt-oss:20b`'s presence in the screening
set (see the spec's Stage 3 section); `qwen3.6:27b-coding-nvfp4` is not run
here by default.

```bash
cd adaptive_chat_server_dart
# Substitute the surviving configuration's flags/prompt file for CONFIG below.
for M in qwen2.5-coder:7b granite4.1:8b gpt-oss:20b llama3-chatqa:8b \
         llama3-groq-tool-use:8b nemotron-3.5-lightning:30b; do
  echo "########## $M / survivor ##########"
  fvm dart run tool/model_probes/shape_ab.dart --model "$M" --samples 2 --baseline /tmp/stack.txt
  curl -s http://127.0.0.1:11434/api/generate -d "{\"model\":\"$M\",\"keep_alive\":0}" > /dev/null
  curl -s http://127.0.0.1:11434/api/ps
done 2>&1 | tee /tmp/confirm-run.txt
```

`nemotron-3.5-lightning:30b` is 23.7 GB and `gpt-oss:20b` is 12.8 GB — the
lightning model is the one to expect hours from; confirm `{"models":[]}`
between every model and never let two of these be resident at once.

- [ ] **Step 2: Compare against recorded baselines**

For each model, compare the survivor's cold-start and with-history figures against that model's baseline. Four of the six already have a full 25-case `shape_ab.dart` baseline recorded in `ModelBehavior.md` (`qwen2.5-coder:7b` from Plan 1 Task 6; `granite4.1:8b`, `gpt-oss:20b`, `llama3-chatqa:8b` from the 2026-08-17 baselines this amendment is built on). For `llama3-groq-tool-use:8b` and `nemotron-3.5-lightning:30b`, no `shape_ab.dart` baseline exists yet (only their `choiceset_ab.dart` 0/6 collapse figure) — run baseline for these two on the same case set first, one model at a time.

Flag, without treating as automatic vetoes: any model whose with-history score **drops**, and any model whose cold-start score drops. Per the spec, harm to a non-default model is a trade for the human to weigh with numbers in view — record both movements and say plainly that it is a trade.

- [ ] **Step 3: Record and commit**

Add to `ModelBehavior.md`:

```markdown
#### Warm-start drift — full-set confirmation, 2026-08-17

`<Surviving configuration>` on all 25 cases, `t=0`, `--samples 2`, both
conditions.

| Model | Cold-start (base → cand) | With-history (base → cand) |
| ----- | ------------------------ | -------------------------- |

<Then: whether the subset result held on the full set, which shapes moved,
and any model that regressed — stated as a trade rather than buried.>
```

```markdown
- Added: full-set confirmation of `<surviving configuration>` across six
  models, all 25 cases, `t=0`, `--samples 2`. `<Held / did not hold>` versus
  the six-case screening result. `<Any regression, named as a trade.>`
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/.claude/worktrees/normalize-qwen-samples
npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): confirm the warm-start survivor on the full case set"
```

---

### Task 7: Stage 4 — the two standing regression gates

Task 6 measured whether the change helps the shapes it targets. This measures whether it broke something else. Task 6 of the earlier probe-followups plan is the precedent: a candidate that tied on its target set and silently turned _"what is a closure? show an example"_ from a passing Markdown reply into raw JSON on screen, 8/8 → 7/8, deterministic across three repeats.

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: Task 6's confirmed configuration.
- Produces: the pass/fail that decides whether Task 8 promotes or reverts.

- [ ] **Step 1: Run both gates on the shipped prompt first, for a same-session baseline**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/temperature_stress.dart --model qwen2.5-coder:7b --samples 2
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 1
```

Record both. Measuring the baseline in the same session removes "was it always like that?" from the later comparison.

- [ ] **Step 2: Run both gates against the candidate**

`temperature_stress.dart` reads the shipped prompt file directly and has no `--candidate` flag, so it must be run with the candidate temporarily in place:

```bash
cd adaptive_chat_server_dart
cp assets/card_system_prompt.txt /tmp/shipped_backup.txt
cp /tmp/stack.txt assets/card_system_prompt.txt
fvm dart run tool/model_probes/temperature_stress.dart --model qwen2.5-coder:7b --samples 2
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 1 \
  --baseline /tmp/shipped_backup.txt --candidate /tmp/stack.txt
cp /tmp/shipped_backup.txt assets/card_system_prompt.txt
git diff --stat assets/card_system_prompt.txt
curl -s http://127.0.0.1:11434/api/generate -d '{"model":"qwen2.5-coder:7b","keep_alive":0}' > /dev/null
```

Expected: `git diff --stat` prints nothing — the shipped prompt is restored. **Verify this before continuing**; leaving a candidate in place would silently change every later measurement and could be committed by accident.

If a non-prompt candidate is the survivor, these gates cannot exercise it — neither `temperature_stress.dart` nor `prompt_ab.dart` sends a reminder or a seed. Say so explicitly rather than reporting a clean gate that did not test the change: the honest statement is "the standing gates do not cover message-assembly changes," and the full-set confirmation in Task 6 is the evidence that has to carry that weight.

- [ ] **Step 3: Judge and record**

Both gates must be at or above their Step 1 figures. A drop on either is treated as caused by this change until proven otherwise — re-run the affected case against the unmodified prompt to attribute it rather than dismissing it as temperature noise.

Add to `ModelBehavior.md`'s confirmation subsection:

```markdown
Regression gates, `qwen2.5-coder:7b`, same session: stress `<base>` → `<cand>`
at `t=0` and `<base>` → `<cand>` at `t=0.6`; code A/B `<base>` → `<cand>`.
`<Clean, or which case regressed and how it was attributed.>`
```

- [ ] **Step 4: Changelog, format, commit**

```markdown
- Added: regression-gate results for the warm-start drift survivor —
  `temperature_stress.dart` at both temperatures and `prompt_ab.dart`'s code
  set, each measured against a same-session baseline on `qwen2.5-coder:7b`.
  `<Clean / regressed on X.>`
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/.claude/worktrees/normalize-qwen-samples
npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): regression-gate the warm-start survivor"
```

---

### Task 8: Promote, or record the negative

Exactly one of the three paths below applies. Read all three before choosing, and state in the commit message which one and why.

**Files:**

- Modify: `adaptive_chat_server_dart/assets/card_system_prompt.txt` (promotion path only)
- Modify: `adaptive_chat_server_dart/lib/src/ollama_responder.dart` (only if an N-candidate is promoted)
- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: every prior task's results.
- Produces: the shipped state, or a recorded negative.

- [ ] **Step 1: Choose the path**

**Path A — a prompt candidate is promoted.** Requires: `qwen2.5-coder:7b` with-history up, its cold-start not down, Task 6 confirming on the full set, Task 7's gates clean.

**Path B — an N-candidate is promoted.** Same bar, but shipping means a code change in `OllamaResponder`, not a prompt edit. For N1, insert the `reinforceReminder` text as a `system` message after `_trimHistory(history)` and before the current user turn (`ollama_responder.dart` around lines 392-400). For N2, prepend `seedCardUser`/`seedCardAssistant` as the first two history turns. Either needs its own unit test asserting the assembled message order, mirroring `test/probe_reinforce_test.dart`. **Only ship N1 on models where Task 3 confirmed delivery** — note that constraint in the changelog, since the server does not know which model it is talking to.

**Path C — nothing is promoted.** The spec distinguishes two negatives, and which one applies changes what gets written:

- **No candidate improved the default model.** The shipping-relevant negative: none of these five mechanisms is worth adopting.
- **Candidates improved the default but none rescued a 0/6 model.** A narrower claim, specifically about total-collapse models.

- [ ] **Step 2 (Path A): Promote the prompt**

```bash
cd adaptive_chat_server_dart
cp /tmp/stack.txt assets/card_system_prompt.txt
fvm dart test test/card_schema_test.dart
```

That test asserts the prompt, schema, and README palettes agree. It matters here because P1, P2, and P3 all mention element types in prose, and `card_schema_test.dart` extracts advertised types from the prompt — a candidate that names a type not in the schema enum will fail it. Expected: PASS.

Then run the full suite and describe the result honestly in `ModelBehavior.md`. **Use the narrow-win wording if it applies**: a candidate that lifted only `qwen2.5-coder:7b` is recorded as _"improves the default model by N shapes"_, **not** as _"fixes warm-start prose drift"_. A candidate that also rescued a 0/6 model earns the stronger claim.

- [ ] **Step 3 (Path C): Record the negative**

Add to `ModelBehavior.md` under `### 4. Multi-turn set — history replay`:

```markdown
#### Warm-start drift — measured negative, 2026-08-17

Five mechanisms were measured and none shipped: P1 (a shape-decision section
appended last, testing recency), P2 (a guard at the top of the Markdown reply
section), P3 (narrowing the "if no element type fits" escape hatch), N1 (a
`system` reminder injected after the history), N2 (a card-shaped history
seed). Screening conditions, scores, and per-candidate detail are in the
subsection above.

This is worth knowing because the shipped prompt **already** carries a direct
anti-drift instruction, added when the escape hatch was re-keyed from
confidence to capability, and four models were measured at 0/6 with it in
place. These five candidates were the plausible next moves — position,
destination-guard, rationalization-route, adjacency, and few-shot format
priming. `<Which of the two negatives applies, stated plainly.>`

Do not retry these five without a materially different mechanism.
```

- [ ] **Step 4: Changelog, gates, commit**

Path A or B:

```markdown
- Fixed: `<candidate>` promoted after measurement. On `qwen2.5-coder:7b` at
  `t=0`, with-history shape coverage `<before>` → `<after>` on the full
  25-case set at `--samples 2`, cold-start `<before>` → `<after>`; regression
  gates clean (stress `<n>` at both temperatures, code A/B `<n>`).
  `<Narrow-win or general-fix framing, matching what was measured.>`
```

Path C:

```markdown
- Measured, not promoted: five warm-start prose-drift candidates (P1 recency,
  P2 Markdown-section guard, P3 escape-hatch narrowing, N1 mid-conversation
  reminder, N2 card-shaped history seed) were screened on 2026-08-17 and none
  met the promotion bar. `assets/card_system_prompt.txt` and
  `OllamaResponder` are unchanged. Full numbers and the reason each lost are
  in `ModelBehavior.md`; recorded so these five are not retried.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/
git commit -m "<see Step 1 — name the path taken and why>"
```

---

## Verification (full suite)

```bash
cd adaptive_chat_server_dart
fvm dart pub get
fvm dart analyze
fvm dart test
fvm dart format --output=none --set-exit-if-changed .
cd ..
npm run check:md
npm run check:md:chat
```

Then confirm the working tree carries only what was intended:

```bash
cd adaptive_chat_server_dart
git status --short
git diff origin/main --stat -- assets/card_system_prompt.txt
```

On Path C, `assets/card_system_prompt.txt` must show **no** diff — a candidate left in place is the single worst failure mode of this plan, because every subsequent measurement in the repository would be against an unshipped prompt.

Invoke **`superpowers:verification-before-completion`** and paste the command output — exit codes and pass/fail counts — before claiming this plan is complete.

## Out of scope

- **Rescuing models that fail cold-start.** A shape a model never produces is a capability or palette gap, not drift.
- **The other seven models in `ModelBehavior.md`.** Task 6 confirms on six; a full sweep is a separate decision.
- **Combining more than the winners.** No full factorial. Individual attribution plus one stacked run is the design.
- **Detector-side repair.** Making the drift harmless by parsing prose into cards is a different approach with its own risks, already recorded as out of scope in the earlier probe-followups plan.
- **`--json-format schema` as a fix.** Several models silently ignore `format`, and it constrains JSON validity rather than shape choice.
