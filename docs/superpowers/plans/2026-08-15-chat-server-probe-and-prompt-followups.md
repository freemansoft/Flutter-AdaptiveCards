# Chat Server Probe and Prompt Follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the follow-ups left over from the 2026-08-14 card prompt investigation — a stale README palette, two probe-scoring blind spots, three missing probe capabilities, two measured-but-unapplied prompt rules, an invisible mode selection, an empty multi-turn column, and per-model measurements still sitting in scratch files — then make card replies the server's default.

**Architecture:** Four layers, fixed in order. First the **measurement layer** (scoring rubric, probe capabilities), because every later task's numbers are only as trustworthy as the rubric that produces them. Then the **prompt layer** (two wording rules already measured by earlier runs, re-measured here under the corrected rubric). Then the **behaviour layer** (startup announcement, then flipping the default to card replies — last among the code changes, so the prompt it promotes is already in its final state). Finally the **record layer** (`ModelBehavior.md`). Fixing the rubric last would invalidate anything measured before it; flipping the default first would promote a prompt still being edited.

**Tech Stack:** Dart 3.12 (FVM-pinned), `package:test`, `package:args`, a local Ollama at `http://127.0.0.1:11434`, Prettier for Markdown.

## Global Constraints

- Prefix **every** `dart` and `flutter` command with `fvm`. Bare commands may resolve to a different SDK.
- Work from `adaptive_chat_server_dart/` unless a step says otherwise. It is **not** a pub workspace member — it resolves standalone via `fvm dart pub get`.
- **One Ollama model at a time.** Never run two probes concurrently, and never interleave models — load one, run everything for it, then switch. Local RAM holds one mid-size model; interleaving costs ~20x the warm load time and distorts latency numbers. Every task except Task 9 uses `qwen2.5-coder:7b` only; Task 9 sweeps six models and says so explicitly, unloading each before the next.
- Every change under `adaptive_chat_server_dart/` needs a bullet in the `## [Unreleased]` section of `adaptive_chat_server_dart/CHANGELOG.md`.
- Markdown in this package is Prettier-governed. Run `npm run format:md:chat` from the repo root after editing any `.md`, and verify with `npm run check:md:chat`. Prettier rewrites `*italic*` to `_italic_`.
- Analysis is `very_good_analysis`: single quotes, package imports, no `print` (use `dart:developer` `log`).
- Gates before any task is complete: `fvm dart analyze` clean, `fvm dart test` all passing, `fvm dart format --output=none --set-exit-if-changed .` clean.
- Probe numbers are only meaningful with their condition attached. Always record **which model**, **which temperature**, and **cold-start vs with-history**.

---

## File Structure

| File                                   | Responsibility                                  | Tasks |
| -------------------------------------- | ----------------------------------------------- | ----- |
| `lib/src/card_detect.dart`             | Card detection + the new wrapped-card predicate | 2     |
| `test/card_detect_test.dart`           | Tests for the above                             | 2     |
| `test/card_schema_test.dart`           | Prompt ↔ schema ↔ README palette agreement    | 1     |
| `README.md`                            | The documented element palette                  | 1     |
| `tool/model_probes/probe_support.dart` | Shared probe plumbing, `judgeReply` verdicts    | 2, 4  |
| `tool/model_probes/dump_reply.dart`    | Single-reply dump, `--history` replay           | 3     |
| `tool/model_probes/prompt_ab.dart`     | Prompt A/B, external prompt sets                | 5     |
| `tool/model_probes/choiceset_ab.dart`  | **New.** Shape-aware ChoiceSet probe            | 4     |
| `assets/card_system_prompt.txt`        | The card palette and rules                      | 6, 7  |
| `bin/server.dart`, `lib/src/cli.dart`  | Startup announcement; card default, echo opt-in | 8, 10 |
| `test/cli_test.dart`                   | CLI defaults                                    | 10    |
| `ModelBehavior.md`                     | The durable per-model record                    | 9, 11 |

---

### Task 1: Make prompt, schema, and README agree — and keep them that way

The card system prompt names the element types the model may emit. Two other places must list the same set: `card_schema.json`'s enum (the grammar under `--json-format schema`) and the README palette (what humans read). PR #51 added `Input.Toggle` and `ColumnSet` to the prompt and schema but not the README, so the README is wrong on `main` right now. A test turns that class of drift into a build failure.

**Files:**

- Modify: `adaptive_chat_server_dart/README.md` (palette list, ~line 227)
- Modify: `adaptive_chat_server_dart/test/card_schema_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: nothing later tasks depend on. Independent — may be done first or last.

- [ ] **Step 1: Write the failing test**

Append this group to `test/card_schema_test.dart`. It parses element types out of the prompt's `- TypeName —` bullets and its `"type":"X"` examples, then asserts both the schema enum and the README mention each one.

```dart
  group('card prompt, schema, and README palette agree', () {
    // Plain relative paths, matching the existing groups in this file — tests
    // run from the package root, and `package:path` is not imported here.
    final prompt = File('assets/card_system_prompt.txt').readAsStringSync();
    final schema =
        jsonDecode(File('assets/card_schema.json').readAsStringSync())
            as Map<String, dynamic>;
    final readme = File('README.md').readAsStringSync();

    Set<String> promptTypes() {
      // A bullet heading alone is not proof of an element type — the prompt
      // uses headings like "- Charts —" to introduce a family. Require a
      // matching "type":"X" example, which every real palette entry has and
      // no section heading does. This keeps the filter self-maintaining
      // instead of growing a denylist of headings.
      final exampled = RegExp(r'"type":"([A-Za-z.]+)"')
          .allMatches(prompt)
          .map((m) => m.group(1)!)
          .toSet();
      final headings = RegExp(r'^- ([A-Z][A-Za-z.]+) —', multiLine: true)
          .allMatches(prompt)
          .map((m) => m.group(1)!)
          .toSet();
      // addAll keeps types demonstrated only in examples — those still need
      // to be in the schema and the README.
      final types = headings.intersection(exampled)..addAll(exampled);
      // Structural children and the card wrapper appear in examples but are
      // not standalone palette entries a user would look up.
      types.removeWhere(
        (t) =>
            t.startsWith('Chart.') ||
            const {
              'AdaptiveCard',
              'CarouselPage',
              'TableRow',
              'TableCell',
              'Column',
            }.contains(t),
      );
      return types;
    }

    test('every type the prompt advertises is allowed by the schema enum', () {
      final defs = schema[r'$defs'] as Map<String, dynamic>;
      final element = defs['Element'] as Map<String, dynamic>;
      final properties = element['properties'] as Map<String, dynamic>;
      final typeSchema = properties['type'] as Map<String, dynamic>;
      final allowed = (typeSchema['enum'] as List).cast<String>().toSet();
      final missing = promptTypes().difference(allowed);
      expect(
        missing,
        isEmpty,
        reason:
            'These types are advertised in card_system_prompt.txt but absent '
            'from card_schema.json, so --json-format schema would reject '
            'exactly what the prompt asks the model to produce: $missing',
      );
    });

    test('every type the prompt advertises is listed in the README palette',
        () {
      final missing =
          promptTypes().where((t) => !readme.contains('`$t`')).toSet();
      expect(
        missing,
        isEmpty,
        reason:
            'These types are advertised in card_system_prompt.txt but missing '
            'from the README palette list, so the documented palette is stale: '
            '$missing',
      );
    });
  });
```

The file already imports `dart:convert`, `dart:io`, and `package:test/test.dart` — no new imports are needed.

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd adaptive_chat_server_dart && fvm dart test test/card_schema_test.dart`

Expected: the schema test PASSES (PR #51 already added both types to the enum). The README test FAILS with `missing: {Input.Toggle, ColumnSet}`. A failure naming exactly those two confirms the test detects real drift rather than passing vacuously.

If a failure names anything else — a family heading, a structural child — the extractor is over-matching, not the palette drifting. Report that rather than editing the test until it looks right: a test tuned to pass is worth nothing.

- [ ] **Step 3: Fix the README palette**

In `adaptive_chat_server_dart/README.md`, replace the Inputs and Display bullets in the "The card prompt's palette is intentionally small" list:

```markdown
- **Inputs** — `Input.Date`, `Input.Toggle`, `Input.ChoiceSet` (`style: compact` /
  `expanded`, `isMultiSelect`), `Input.Text`, `Input.Number`, `Input.Time`.
- **Display** — `TextBlock`, `FactSet`, `Badge`, `Carousel`, `ColumnSet`, `Table`,
  `Rating`, `Icon`, `ProgressBar`, `ProgressRing`, `CodeBlock`, `Image`.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd adaptive_chat_server_dart && fvm dart test test/card_schema_test.dart`

Expected: PASS, all groups.

- [ ] **Step 5: Add the changelog entry**

Add to the top of `## [Unreleased]` in `adaptive_chat_server_dart/CHANGELOG.md`:

```markdown
- Fixed: the README's element palette listed neither `Input.Toggle` nor
  `ColumnSet` after both were added to the card system prompt and schema, so
  the documented palette disagreed with the shipped one. Added a test that
  asserts every type the prompt advertises appears in both the schema enum
  and the README, turning this drift into a build failure instead of a
  discrepancy someone has to notice.
```

- [ ] **Step 6: Run the gates and commit**

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/README.md adaptive_chat_server_dart/test/card_schema_test.dart adaptive_chat_server_dart/CHANGELOG.md
git commit -m "test(chat-server): assert prompt, schema, and README palettes agree"
```

---

### Task 2: Stop scoring a prose-wrapped card as a pass

`judgeReply` calls a reply `ok` if it is a renderable card **or** clean prose. A reply like `Sure, here you go:\n\n\`\`\`json\n{...}\n\`\`\``is neither: the server shows the user raw JSON inside a code block, which is the exact symptom users report. It currently scores`prose` = PASS, so probes report green on the failure they exist to catch.

**Files:**

- Modify: `adaptive_chat_server_dart/lib/src/card_detect.dart`
- Modify: `adaptive_chat_server_dart/test/card_detect_test.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/probe_support.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: nothing.
- Produces: `bool replyWrapsCardInProse(String raw)` exported from `lib/src/card_detect.dart`. Task 4 uses it; Tasks 6 and 7 rely on it being in place so their measurements score correctly.

- [ ] **Step 1: Write the failing tests**

Add to `test/card_detect_test.dart`, inside `main`:

````dart
  group('replyWrapsCardInProse', () {
    test('a preamble followed by a fenced card is flagged', () {
      const raw = 'Sure, here you go:\n\n'
          '```json\n{"type":"TextBlock","text":"hi","wrap":true}\n```';
      expect(replyWrapsCardInProse(raw), isTrue);
      // It is not a usable card either — that is the whole problem.
      expect(tryParseCardBody(raw), isNull);
    });

    test('a fenced card with nothing around it is not flagged', () {
      const raw = '```json\n{"type":"TextBlock","text":"hi","wrap":true}\n```';
      expect(replyWrapsCardInProse(raw), isFalse);
      expect(tryParseCardBody(raw), isNotNull);
    });

    test('genuine prose containing a non-card code fence is not flagged', () {
      const raw = 'Use dart:io:\n\n```dart\nvoid main() {}\n```';
      expect(replyWrapsCardInProse(raw), isFalse);
    });

    test('plain prose with no fence at all is not flagged', () {
      expect(replyWrapsCardInProse('Just a normal reply.'), isFalse);
    });
  });
````

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd adaptive_chat_server_dart && fvm dart test test/card_detect_test.dart`

Expected: FAIL with `Method not found: 'replyWrapsCardInProse'`.

- [ ] **Step 3: Implement the predicate**

Add to `lib/src/card_detect.dart`, after `cardParseFailureReason`:

````dart
/// Whether [raw] is prose that *contains* a card rather than being one.
///
/// This shape is why a probe can report a green pass rate on the failure
/// users actually report. The reply does not parse as a card, so the server
/// falls back to rendering it as Markdown — and the user sees raw JSON in a
/// code block. Scored as "prose" it looks like a legal Markdown answer, which
/// the card system prompt does permit, so nothing flags it.
///
/// Deliberately narrow: it only fires when a fenced block on its own would
/// have been a renderable card. A fenced Dart snippet inside an ordinary
/// prose answer is a legitimate Markdown reply and must not be flagged.
bool replyWrapsCardInProse(String raw) {
  if (tryParseCardBody(raw) != null) return false;
  final fence = RegExp(
    r'```(?:json)?\s*(.*?)\s*```',
    dotAll: true,
    caseSensitive: false,
  );
  for (final match in fence.allMatches(raw)) {
    if (tryParseCardBody(match.group(1)!) != null) return true;
  }
  return false;
}
````

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd adaptive_chat_server_dart && fvm dart test test/card_detect_test.dart`

Expected: PASS, including the pre-existing groups.

- [ ] **Step 5: Teach `judgeReply` the new verdict**

In `tool/model_probes/probe_support.dart`, inside `judgeReply`, insert this **before** the final `return why == null ? ... : ...` line:

```dart
  if (replyWrapsCardInProse(content)) {
    return outcome(
      ok: false,
      label: 'prose-with-card (user sees raw JSON)',
    );
  }
```

Update the doc comment on `ProbeOutcome.ok` to say prose counts as a pass **only** when it contains no card:

```dart
  /// Whether the reply was usable — a renderable card, or clean prose.
  ///
  /// Prose counts as a pass: the card system prompt explicitly allows a
  /// Markdown answer, so only a *broken* card is a failure. The exception is
  /// prose that wraps a card (see `replyWrapsCardInProse`) — that renders as
  /// raw JSON in a code block, which is a failure however tidy it looks.
  final bool ok;
```

- [ ] **Step 6: Verify the probe now fails the shape**

Create `tool/_verify_judge.dart` (temporary):

````dart
import 'package:adaptive_chat_server_dart/src/card_detect.dart';
// Relative: probe_support lives outside lib/.
import 'model_probes/probe_support.dart';

void main() {
  const wrapped = 'Sure, here you go:\n\n'
      '```json\n{"type":"TextBlock","text":"hi","wrap":true}\n```';
  const bare = '```json\n{"type":"TextBlock","text":"hi","wrap":true}\n```';
  print('wrapped -> ${judgeReply(wrapped, 0).label} '
      '(ok=${judgeReply(wrapped, 0).ok})');
  print('bare    -> ${judgeReply(bare, 0).label} '
      '(ok=${judgeReply(bare, 0).ok})');
  print('predicate on wrapped: ${replyWrapsCardInProse(wrapped)}');
}
````

Run: `cd adaptive_chat_server_dart && fvm dart run tool/_verify_judge.dart`

Expected:

```txt
wrapped -> prose-with-card (user sees raw JSON) (ok=false)
bare    -> card[1] (ok=true)
predicate on wrapped: true
```

Then delete it: `rm tool/_verify_judge.dart`

- [ ] **Step 7: Add the changelog entry, run gates, commit**

Changelog bullet:

```markdown
- Fixed: probes scored a prose-wrapped card as a passing `prose` reply. A
  model that writes "Sure, here you go:" before a fenced card produces a
  message the server renders as Markdown, so the user sees raw JSON in a code
  block — the exact symptom people report, scored green by every probe.
  `card_detect.dart` gained `replyWrapsCardInProse`, and `judgeReply` now
  returns `prose-with-card` as a failure. Prose that merely contains a
  non-card code fence is still a legitimate pass.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
git add lib/src/card_detect.dart test/card_detect_test.dart tool/model_probes/probe_support.dart CHANGELOG.md
git commit -m "fix(chat-server): score a prose-wrapped card as a failure, not prose"
```

---

### Task 3: Let `dump_reply` replay conversation history

The server sends prior turns on every request; every probe sends a single turn. That gap hid a whole failure class — one prior prose turn flips `qwen2.5-coder:7b` from `card[2]` to 867 characters of Markdown on an options question. Without history replay, no probe can reproduce a bug the user hits in a real conversation.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/dump_reply.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/README.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: nothing.
- Produces: `dump_reply.dart --history <file>` (repeatable). Each file's contents become one prior turn, alternating `user`, `assistant`, `user`, … in the order given. Task 7 uses this to measure the multi-turn case.

- [ ] **Step 1: Add the option and build the message list**

In `dump_reply.dart`, add to `promptParser`:

```dart
    ..addMultiOption(
      'history',
      help: 'File whose contents become one prior turn. Repeatable; turns '
          'alternate user, assistant, user, ... in the order given.',
    )
```

Replace the single-message body with a list built from history. The existing code sends `[system, user]`; it becomes:

```dart
  final history = parsed['history'] as List<String>;
  final messages = <Map<String, String>>[
    {'role': 'system', 'content': loadCardSystemPrompt()},
    for (final (i, turnFile) in history.indexed)
      {
        'role': i.isEven ? 'user' : 'assistant',
        'content': File(turnFile).readAsStringSync(),
      },
    {'role': 'user', 'content': userPrompt},
  ];
```

and the request body uses `'messages': messages`.

Add `'--history'` to the locally-parsed options so it is not forwarded to `parseProbeArgs`, which does not declare it — the same defect that made `--prompt` unusable:

```dart
  // Only this script accepts --prompt/--history; the shared parser rejects
  // options it does not declare, which is what broke --prompt.
  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);
```

Report the turn count in the summary block:

```dart
    ..writeln('history turns      : ${history.length}')
```

- [ ] **Step 2: Verify cold start still works**

Run:

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/dump_reply.dart \
  --model qwen2.5-coder:7b \
  --prompt 'what are my options for deployment targets'
```

Expected: `history turns      : 0` and `verdict              : card[...]`.

- [ ] **Step 3: Verify history replay reproduces the failure**

```bash
cd adaptive_chat_server_dart
cat > /tmp/h1.txt <<'EOF'
what is CI/CD?
EOF
cat > /tmp/h2.txt <<'EOF'
CI/CD is a practice where code changes are automatically built, tested, and deployed.

- **CI** builds and tests every commit.
- **CD** ships passing builds to production.
EOF
fvm dart run tool/model_probes/dump_reply.dart \
  --model qwen2.5-coder:7b \
  --history /tmp/h1.txt --history /tmp/h2.txt \
  --prompt 'what are my options for deployment targets'
```

Expected: `history turns      : 2` and `verdict              : prose` — the same question that returns a card cold now returns Markdown. If it returns a card, record that and note it: the effect is model- and phrasing-dependent, and a non-reproduction is itself a finding worth writing down rather than a reason to abandon the flag.

- [ ] **Step 4: Document the flag**

In `tool/model_probes/README.md`, extend the `dump_reply.dart` row and add below the script table:

```markdown
`dump_reply.dart --history <file>` replays prior turns the way the server
does. Sets 1–3 are all single-turn, so a bug that only appears after a few
turns of conversation is invisible to them — reach for `--history` before
concluding a reported bug does not reproduce.
```

- [ ] **Step 5: Changelog, gates, commit**

```markdown
- Added: `dump_reply.dart --history <file>` (repeatable) replays prior
  conversation turns the way `OllamaResponder` does. Every probe was
  single-turn while the server always sends history, so any failure triggered
  by an ongoing conversation was structurally invisible to the whole suite.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/dump_reply.dart adaptive_chat_server_dart/tool/model_probes/README.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): replay conversation history in dump_reply"
```

---

### Task 4: A shape-aware probe for pick-from-a-set questions

The generic sets ask "did the model emit something broken?" For an options question that is the wrong question — a tidy Markdown bullet list renders perfectly and still fails the user, because it cannot be clicked. This probe scores strictly: the reply must be a card _containing_ an `Input.ChoiceSet`.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/choiceset_ab.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/README.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `probeOnce`, `ProbeOutcome`, `loadCardSystemPrompt`, `parseProbeArgs` from `probe_support.dart`; `tryParseCardBody` from `lib/src/card_detect.dart`.
- Produces: `choiceset_ab.dart --candidate <file>` printing pass rates for baseline and candidate prompts. Task 7 uses it to measure its prompt change.

- [ ] **Step 1: Create the probe**

````dart
/// Scores whether a pick-from-a-set question actually yields a clickable card.
///
/// The other probes ask "did the model emit something broken?" and a tidy
/// Markdown list of options passes that bar while completely failing the
/// user — it renders fine and cannot be clicked. This one requires a
/// renderable card that *contains* an `Input.ChoiceSet`, and it sends prior
/// prose turns first, because that is the condition under which the failure
/// actually appears.
///
/// ```sh
/// fvm dart run tool/model_probes/choiceset_ab.dart \
///   --model qwen2.5-coder:7b --candidate /tmp/candidate.txt
/// ```
library;

import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:args/args.dart';
// Relative: this file and its helper both live outside `lib/`.
import 'probe_support.dart';

/// Questions whose right answer is a set the user can pick from.
const _prompts = [
  'what are my options for deployment targets',
  'which log level should I use?',
  'what environments can I deploy to?',
  'what are my options for notification frequency',
  'help me pick a database engine',
  'what build modes can I choose from?',
];

/// Two prose turns, to establish Markdown as the conversation's format.
const _historyUser = 'what is CI/CD?';
const _historyAssistant =
    'CI/CD is a practice where code changes are automatically built, tested, '
    'and deployed.\n\n- **CI** builds and tests every commit.\n'
    '- **CD** ships passing builds to production.';

bool _hasChoiceSet(String reply) {
  final body = tryParseCardBody(reply);
  if (body == null) return false;
  bool contains(Object? node) {
    if (node is Map) {
      if (node['type'] == 'Input.ChoiceSet') return true;
      return node.values.any(contains);
    }
    if (node is List) return node.any(contains);
    return false;
  }

  return body.any(contains);
}

Future<int> _run(
  String label,
  String systemPrompt,
  ProbeArgs args,
  HttpClient client,
) async {
  var pass = 0;
  var total = 0;
  stdout.writeln('\n########## $label ##########');
  for (final prompt in _prompts) {
    for (var i = 0; i < args.samples; i++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: prompt,
        history: const [_historyUser, _historyAssistant],
        options: const {'temperature': 0.0},
      );
      final ok = _hasChoiceSet(outcome.reply);
      total++;
      if (ok) pass++;
      stdout.writeln(
        '${ok ? "PASS" : "FAIL"}  ${outcome.label.padRight(28)} $prompt',
      );
    }
  }
  stdout.writeln('== ${label.padRight(12)} choice-set $pass/$total ==');
  return pass;
}

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('baseline', defaultsTo: 'assets/card_system_prompt.txt')
    ..addOption('candidate')
    ..addOption('model')
    ..addOption('url')
    ..addOption('samples')
    ..addFlag('help', abbr: 'h', negatable: false);
  final parsed = parser.parse(argv);
  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);

  final client = HttpClient()..idleTimeout = const Duration(minutes: 5);
  await _run(
    'baseline',
    File(parsed['baseline'] as String).readAsStringSync().trim(),
    args,
    client,
  );
  final candidate = parsed['candidate'] as String?;
  if (candidate != null) {
    await _run(
      'candidate',
      File(candidate).readAsStringSync().trim(),
      args,
      client,
    );
  }
  client.close();
}
````

- [ ] **Step 2: Extend `probeOnce` to accept history and return the reply**

This probe needs two things `probeOnce` does not yet provide: prior turns, and the raw reply text (to inspect for `Input.ChoiceSet`). In `probe_support.dart`:

Add a field to `ProbeOutcome` — declare it `final String reply;`, add `required this.reply` to the constructor, and document it:

```dart
  /// The raw reply text, so a caller can score for a specific element rather
  /// than only for "is it broken?".
  final String reply;
```

Update `judgeReply` to pass `reply: content` into every `ProbeOutcome` it builds, and the HTTP-error path in `probeOnce` to pass `reply: body`.

Add an optional history parameter to `probeOnce`:

```dart
  List<String> history = const [],
```

and build its messages the same way Task 3 does:

```dart
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        for (final (i, turn) in history.indexed)
          {'role': i.isEven ? 'user' : 'assistant', 'content': turn},
        {'role': 'user', 'content': userPrompt},
      ],
```

- [ ] **Step 3: Verify the probe reproduces the failure against the shipped prompt**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/choiceset_ab.dart --model qwen2.5-coder:7b --samples 1
```

Expected: a low baseline score — the shipped prompt scored **0/6** on this set when measured on 2026-08-14. Any score is a valid baseline; record the actual number. A high baseline would mean the earlier finding does not reproduce, which is worth recording rather than explaining away.

- [ ] **Step 4: Document it**

Add to the script table in `tool/model_probes/README.md`:

```markdown
| `choiceset_ab.dart` | Does a pick-from-a-set question yield a clickable card? |
```

- [ ] **Step 5: Changelog, gates, commit**

```markdown
- Added: `choiceset_ab.dart`, a shape-aware probe for pick-from-a-set
  questions. It sends prior prose turns and requires a card containing an
  `Input.ChoiceSet`, because the generic sets score a tidy Markdown list of
  options as a passing `prose` reply while the user is left with something
  they cannot click. `probeOnce` gained an optional `history` parameter and
  `ProbeOutcome` now carries the raw `reply`.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/ adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add a shape-aware ChoiceSet probe"
```

---

### Task 5: Let `prompt_ab` take its prompts from a file

`prompt_ab.dart`'s prompt list is hardcoded and entirely code-flavoured. Every agent that touched it during the 2026-08-14 investigation independently worked around that, because no built-in set could express the shape they were testing.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/prompt_ab.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/README.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: nothing.
- Produces: `prompt_ab.dart --prompts <file>` — one user prompt per line, `#` comments and blank lines ignored. Task 6 uses it.

- [ ] **Step 1: Add the option**

In `prompt_ab.dart`, add to the parser:

```dart
    ..addOption(
      'prompts',
      help: 'File of user prompts, one per line. Lines starting with # and '
          'blank lines are ignored. Defaults to the built-in code set.',
    )
```

Rename the existing `_userPrompts` to `_defaultUserPrompts`, document why it is code-flavoured, and resolve the set at startup:

```dart
/// The built-in set is code-flavoured because it was written for the
/// code-explanation investigation. It cannot express other shapes — pass
/// `--prompts` rather than editing this list.
const _defaultUserPrompts = [ /* unchanged contents */ ];

List<String> _loadPrompts(String? path) {
  if (path == null) return _defaultUserPrompts;
  return File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toList();
}
```

Thread the resolved list into `_run` as a parameter instead of reading the top-level constant.

- [ ] **Step 2: Verify both paths**

```bash
cd adaptive_chat_server_dart
cat > /tmp/set.txt <<'EOF'
# comparison shapes
Compare SQLite and Postgres side by side
Show me Flutter vs React Native side by side
EOF
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 1 --prompts /tmp/set.txt
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 1
```

Expected: the first runs exactly 2 prompts, the second runs the built-in 8. Record both pass rates.

- [ ] **Step 3: Document, changelog, gates, commit**

README note:

```markdown
`prompt_ab.dart --prompts <file>` runs your own set — one prompt per line.
The built-in set is code-flavoured and cannot exercise other shapes.
```

Changelog:

```markdown
- Added: `prompt_ab.dart --prompts <file>` runs an external prompt set. The
  built-in list is code-flavoured and could not express the comparison or
  options shapes, so every investigation had to work around it.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/ adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): let prompt_ab take an external prompt set"
```

---

### Task 6: Teach the prompt that a two-part request is still one message

Measured on 2026-08-14: plain comparisons are fine (26/26), but a request that asks to compare **and** comment ("…then tell me which you'd pick") makes the model emit a fenced card followed by a loose paragraph. That defeats fence recovery, `jsonDecode` dies on the stray fence marker, and the user sees the whole raw reply. The earlier run measured 8/10 → 10/10 with this wording; re-measure here, because Task 2 changed the rubric.

**Files:**

- Modify: `adaptive_chat_server_dart/assets/card_system_prompt.txt`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `prompt_ab.dart --prompts` from Task 5; the corrected `judgeReply` from Task 2.
- Produces: nothing later tasks consume.

- [ ] **Step 1: Capture the baseline before editing**

```bash
cd adaptive_chat_server_dart
cat > /tmp/compare_set.txt <<'EOF'
Compare SQLite and Postgres side by side, then tell me which you would pick
Show me Flutter vs React Native side by side and say which one you'd choose
Compare REST and GraphQL, then explain your reasoning
Put Redis and Memcached side by side, then recommend one
Compare npm and pnpm in a table, then summarize
EOF
cp assets/card_system_prompt.txt /tmp/candidate.txt
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 2 --prompts /tmp/compare_set.txt
```

Record the baseline number. Expect failures of the form `invalid JSON ... at the surviving closing fence`, or `prose-with-card` now that Task 2 can see that shape.

- [ ] **Step 2: Edit the candidate prompt**

In `/tmp/candidate.txt`, add this paragraph immediately after the opening "Choose ONE of two reply shapes per turn…" block:

````txt
This is easiest to get wrong when one request asks for two things — "compare A
and B, then tell me which to pick", "show the table, then explain your
reasoning", "summarize first, then show them side by side". That is still ONE
message. Your summary, recommendation, or conclusion is a TextBlock element in
the SAME array as the comparison — first or last, wherever it reads best. A
paragraph written after the closing ] (or after a closing ``` fence) destroys
the card and the user sees the JSON.
````

Extend pre-send check `0.` so it names this case. Change the sentence beginning "second code block, no "This card shows…"" to end:

```txt
   second code block, no "This card shows…", and no closing paragraph of
   recommendation, reasoning, or summary. If you have written the JSON and
   still have something to say, do not append it: move it into a TextBlock
   element inside the same card. If the request asked you to compare AND to
   comment, the comment is the last TextBlock in the array, not a paragraph
   after it.
```

- [ ] **Step 3: Measure the candidate**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 2 \
  --prompts /tmp/compare_set.txt --candidate /tmp/candidate.txt
```

Expected: candidate ≥ baseline. **If it is not better, stop and do not promote it** — record the numbers in the changelog as a measured negative result and move to the next task. A wording change that does not measure better is not an improvement, and this exact approach has scored flat before.

- [ ] **Step 4: Promote and check for regression**

Only if Step 3 improved:

```bash
cd adaptive_chat_server_dart
cp /tmp/candidate.txt assets/card_system_prompt.txt
fvm dart run tool/model_probes/temperature_stress.dart --model qwen2.5-coder:7b --samples 2
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 1
```

Expected: stress at or above its pre-change level at both temperatures, and the built-in code set unchanged. A stress regression means the new wording broke something else — revert and record that.

- [ ] **Step 5: Changelog, gates, commit**

```markdown
- Fixed: a request that asks to compare **and** comment ("…then tell me which
  you'd pick") made the model emit a card followed by a loose paragraph, which
  the user sees as raw JSON. Plain comparisons were never affected — measured
  26/26 — so the trigger is the second clause, not the comparison. The prompt
  now says a two-part request is still one message and the verdict belongs in
  a TextBlock in the same array. Measured on `qwen2.5-coder:7b` at `t=0`:
  <baseline> → <candidate> on the compare-and-comment set, with the stress set
  and the code A/B set unregressed.
```

Replace `<baseline>` and `<candidate>` with the actual figures.

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
git add assets/card_system_prompt.txt CHANGELOG.md
git commit -m "fix(chat-server): keep compare-and-comment replies inside one card"
```

---

### Task 7: Re-key the escape hatch from confidence to capability

The prompt's escape hatch reads "if you are **unsure whether a card helps**, use reply shape 2". Two prose turns are enough to make the model unsure, so an ongoing Markdown conversation talks it out of cards entirely — measured 0/6 on options questions with history. Re-keying the hatch to capability ("if no element type **fits**") and naming the pick-from-a-set case gives it a rule that does not erode with conversation.

**Files:**

- Modify: `adaptive_chat_server_dart/assets/card_system_prompt.txt`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `choiceset_ab.dart` from Task 4; `--history` from Task 3.
- Produces: nothing later tasks consume.

- [ ] **Step 1: Capture the baseline**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/choiceset_ab.dart --model qwen2.5-coder:7b --samples 2
```

Record the baseline choice-set score.

- [ ] **Step 2: Edit the candidate**

```bash
cd adaptive_chat_server_dart && cp assets/card_system_prompt.txt /tmp/candidate7.txt
```

In `/tmp/candidate7.txt`, **replace** the existing paragraph:

```txt
If you are unsure whether a card helps, use reply shape 2 (plain Markdown)
instead — a malformed card is shown to the user as raw JSON text, which is far
worse than a plain Markdown answer.
```

with:

```txt
Decide the shape from the CURRENT question by itself. Having answered in
Markdown earlier in this conversation is NOT a reason to answer in Markdown now
— a question that asks the user to pick from a set gets a card even when every
previous turn was prose.

When the user asks what their options are, which one they should pick, or what
they can choose from, that is a pick-from-a-set question: answer with an
Input.ChoiceSet offering about 3-6 representative options. Anything you want to
say about them — what they mean, how to choose between them — goes in a
TextBlock beside the ChoiceSet in the SAME card:
  [{"type":"TextBlock","text":"Pick the environment to deploy to:","wrap":true},{"type":"Input.ChoiceSet","id":"target","style":"expanded","isMultiSelect":false,"choices":[{"title":"Staging","value":"staging"},{"title":"Production","value":"production"}]}]
A Markdown bullet list of options is the wrong shape for these: the user cannot
click it. If there are more options than fit, still send a ChoiceSet of the most
common ones and cover the rest in the TextBlock.

If no element type in the list below fits what you need to show, use reply
shape 2 (plain Markdown) instead — a malformed card is shown to the user as raw
JSON text, which is far worse than a plain Markdown answer.
```

- [ ] **Step 3: Measure**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/choiceset_ab.dart --model qwen2.5-coder:7b --samples 2 --candidate /tmp/candidate7.txt
```

Expected: candidate well above baseline (0/6 → 5/6 when measured on 2026-08-14). If not better, do not promote — record the negative result.

- [ ] **Step 4: Promote and check for regression**

```bash
cd adaptive_chat_server_dart
cp /tmp/candidate7.txt assets/card_system_prompt.txt
fvm dart run tool/model_probes/temperature_stress.dart --model qwen2.5-coder:7b --samples 2
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 1
```

Expected: no regression on either. This prompt has a history of one added clause costing a stress case, so treat any drop as caused by this change until proven otherwise — re-run the _unmodified_ prompt through the stress set to attribute it rather than dismissing it as temperature noise.

- [ ] **Step 5: Changelog, gates, commit**

```markdown
- Fixed: an ongoing Markdown conversation talked the model out of cards
  entirely. The escape hatch was keyed on confidence ("if you are unsure
  whether a card helps"), and two prose turns are enough to make it unsure —
  measured 0/6 on options questions with prior prose turns, against `card[2]`
  for the same question cold. The hatch is now keyed on capability ("if no
  element type fits"), the prompt says to judge the current question on its
  own, and pick-from-a-set questions are named explicitly as ChoiceSet
  questions. Measured on `qwen2.5-coder:7b` at `t=0`: <baseline> → <candidate>
  with history, stress and code A/B unregressed.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
git add assets/card_system_prompt.txt CHANGELOG.md
git commit -m "fix(chat-server): decide reply shape per question, not per conversation"
```

---

### Task 8: Announce which system prompt is in force

The server ships two system prompts and defaults to the one that never mentions Adaptive Cards. Started without `--system-prompt-file`, it answers "what are my options?" with bullet points — 0/8 cards versus 8/8 with the card prompt — and no rephrasing helps. That reads as a model or wording failure when it is a launch-flag failure, and nothing at startup says which mode is active.

**Files:**

- Modify: `adaptive_chat_server_dart/bin/server.dart`
- Modify: `adaptive_chat_server_dart/lib/src/cli.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: nothing.
- Produces: nothing.

- [ ] **Step 1: Add the announcement**

In `bin/server.dart`, add above `main`:

```dart
/// Announces which system prompt is in force, because the wrong one is
/// otherwise invisible.
///
/// Card replies are opt-in: the bundled default prompt tells the model to
/// answer in Markdown and never mentions Adaptive Cards, so a server started
/// without `--system-prompt-file` answers "what are my options?" with bullet
/// points and no amount of rephrasing produces a choice set. That reads as a
/// model or prompt-wording failure when it is a launch-flag failure, so name
/// the file at startup and spell out the flag that switches modes.
void _logSystemPromptChoice(Logger log, String? systemPromptFile) {
  if (systemPromptFile != null) {
    log.info('System prompt: $systemPromptFile');
    return;
  }
  log.info(
    'System prompt: bundled assets/default_system_prompt.txt (Markdown '
    'replies only — no Adaptive Cards). For card replies restart with '
    '--system-prompt-file assets/card_system_prompt.txt',
  );
}
```

Call it during startup, after the logger is configured and before `shelf_io.serve`, passing the parsed `--system-prompt-file` value (`null` when the flag was not given).

- [ ] **Step 2: Make `--help` mention card mode**

In `lib/src/cli.dart`, extend the `system-prompt-file` help text so the flag names the file that turns cards on:

```dart
      help: 'Path to a system prompt file. Defaults to the bundled '
          'assets/default_system_prompt.txt, which produces Markdown replies '
          'only. Pass assets/card_system_prompt.txt for Adaptive Card replies.',
```

- [ ] **Step 3: Verify both modes announce correctly**

```bash
cd adaptive_chat_server_dart
fvm dart run bin/server.dart --help | grep -A3 "system-prompt-file"
timeout 5 fvm dart run bin/server.dart --port 8099 2>&1 | grep "System prompt" || true
timeout 5 fvm dart run bin/server.dart --port 8099 --system-prompt-file assets/card_system_prompt.txt 2>&1 | grep "System prompt" || true
```

Expected: help text names `card_system_prompt.txt`; the first server logs the Markdown-only warning; the second names the card prompt file.

- [ ] **Step 4: Changelog, gates, commit**

```markdown
- Added: the server logs which system prompt is active at startup, and says
  how to switch. Card replies are opt-in via `--system-prompt-file`, and the
  default prompt never mentions Adaptive Cards — measured 0/8 cards on the
  default versus 8/8 on the card prompt, same model and temperature. Nothing
  previously indicated which mode was running, so "the model never sends
  cards" looked like a model problem. `--help` now names the card prompt file.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
git add bin/server.dart lib/src/cli.dart CHANGELOG.md
git commit -m "feat(chat-server): announce the active system prompt at startup"
```

---

### Task 9: Measure the multi-turn condition across the probed models

`ModelBehavior.md` has a `With history` column and exactly one model has a value in it. Every other cell is empty, so the table silently implies cold-start numbers describe real conversations — and for at least one model they demonstrably do not. This task fills the column for the models that already have cold-start data.

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `choiceset_ab.dart` from Task 4 (it sends prior prose turns by construction) and the promoted prompt from Task 7.
- Produces: a `With history` value for each model measured. Task 11 records them alongside the rest.

- [ ] **Step 1: Run the multi-turn probe, one model at a time**

These six already have cold-start numbers, so a history result makes their rows comparable. Run them **strictly sequentially** — each `for` iteration loads one model and the explicit unload releases it before the next:

```bash
cd adaptive_chat_server_dart
for m in llama3-chatqa:8b gpt-oss:20b granite4.1:8b llama3-groq-tool-use:8b nemotron-3-nano:4b granite4.1:3b; do
  echo "===== $m ====="
  fvm dart run tool/model_probes/choiceset_ab.dart --model "$m" --samples 1
  curl -s http://127.0.0.1:11434/api/generate -d "{\"model\":\"$m\",\"keep_alive\":0}" > /dev/null
done
```

Record each model's `choice-set N/6` line. Expect this to take roughly 15-30 minutes total; the models are small and the set is six prompts.

- [ ] **Step 2: Sanity-check one result against a cold-start run**

A history number only means something next to its cold-start counterpart. For the single best performer from Step 1:

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/dump_reply.dart --model <best-model> \
  --prompt 'what are my options for deployment targets'
```

Expected: a `card[...]` verdict cold. If the model scored poorly with history but produces a card cold, that is the same history-erosion effect already recorded for `qwen2.5-coder:7b` and it now has a second data point. If it fails cold too, the cause is not history — say so rather than filing it under the multi-turn finding.

- [ ] **Step 3: Fill in the `With history` column**

For each model measured, replace `— not yet probed` in the **With history** column with its score, using the same terse form as the existing row, e.g. `✅ 5/6 choice-set` or `❌ 1/6 — drops to prose`. Leave the four unprobed models and `llama3.2:latest` as `— not yet probed`; do not infer a value for a model you did not run.

- [ ] **Step 4: Record what the spread shows**

Append to `### 4. Multi-turn set — history replay` a short paragraph naming which models held up and which collapsed, with the numbers. If every model degrades, say that — it makes history erosion a property of the workload rather than of one model, which is a stronger and more useful claim. If results vary widely, say that instead; do not round a mixed picture into a tidy conclusion.

- [ ] **Step 5: Changelog, format, commit**

```markdown
- Added: multi-turn (`With history`) results for the six models that already
  had cold-start numbers. The column previously had one value out of fourteen,
  which let cold-start figures read as though they described real
  conversations. Measured with `choiceset_ab.dart` at `t=0`, `--samples 1`,
  one model resident at a time.
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): measure the multi-turn condition across probed models"
```

---

### Task 10: Make card replies the default and echo opt-in

Card mode is currently opt-in twice over: the server picks `default_system_prompt.txt` unless told otherwise, and it runs the echo demo unless `--ollama-url` is given. That ordering is backwards for a card-rendering chat server — the interesting behaviour requires two flags and the trivial behaviour is free. Flip both.

**Files:**

- Modify: `adaptive_chat_server_dart/bin/server.dart`
- Modify: `adaptive_chat_server_dart/lib/src/cli.dart`
- Modify: `adaptive_chat_server_dart/test/cli_test.dart`
- Modify: `adaptive_chat_server_dart/README.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: the startup announcement from Task 8 — its wording assumes the Markdown prompt is the default and **must** be updated here, or the server will log advice that is no longer true.
- Produces: `--echo` flag; `--ollama-url` defaulting to `http://127.0.0.1:11434`.

- [ ] **Step 1: Write the failing tests**

Add to `test/cli_test.dart`:

```dart
    test('the card system prompt is the default', () {
      final args = parseServerArgs([]);
      expect(args['system-prompt-file'], isNull,
          reason: 'no flag needed for card mode');
      // The default path is resolved in bin/server.dart; assert the CLI does
      // not force the Markdown prompt.
      expect(args['echo'], isFalse);
    });

    test('--echo opts into the echo demo', () {
      final args = parseServerArgs(['--echo']);
      expect(args['echo'], isTrue);
    });

    test('--ollama-url defaults to the local Ollama', () {
      final args = parseServerArgs([]);
      expect(args['ollama-url'], 'http://127.0.0.1:11434');
    });
```

Match the existing tests' helper name and import style in that file — if the file parses args differently, follow its established pattern rather than introducing `parseServerArgs`.

- [ ] **Step 2: Run to verify they fail**

Run: `cd adaptive_chat_server_dart && fvm dart test test/cli_test.dart`

Expected: FAIL — there is no `echo` option, and `ollama-url` has no default.

- [ ] **Step 3: Flip the defaults**

In `lib/src/cli.dart`:

```dart
    ..addFlag(
      'echo',
      negatable: false,
      help: 'Run the echo demo instead of calling a model. The server '
          'otherwise talks to Ollama at --ollama-url.',
    )
```

Give `ollama-url` a default of `'http://127.0.0.1:11434'` and update its help text — it no longer means "omit to run the echo demo":

```dart
      help: 'Base URL of the Ollama server. Pass --echo to skip Ollama '
          'entirely and run the echo demo.',
```

Update the `system-prompt-file` help so it names the new default:

```dart
      help: 'Path to a text file whose contents become the system prompt. '
          'Re-read per request, so edits apply without restart. Defaults to '
          'the bundled assets/card_system_prompt.txt (Adaptive Card replies). '
          'Pass assets/default_system_prompt.txt for Markdown-only replies.',
```

In `bin/server.dart`, change the default prompt path and honour `--echo`:

```dart
    defaultSystemPromptPath: p.join(assetsDir, 'card_system_prompt.txt'),
```

```dart
    // --echo forces the demo responder; otherwise we talk to Ollama.
    ollamaUrl: (args['echo'] as bool) ? null : args['ollama-url'] as String,
```

- [ ] **Step 4: Update Task 8's startup announcement**

Task 8's message tells the operator the default is Markdown-only and how to switch to cards. After this task that is false. Rewrite `_logSystemPromptChoice` so the default branch reads:

```dart
  log.info(
    'System prompt: bundled assets/card_system_prompt.txt (Adaptive Card '
    'replies). For Markdown-only replies restart with --system-prompt-file '
    'assets/default_system_prompt.txt',
  );
```

Leave the doc comment's explanation of _why_ the announcement exists, but correct any sentence that names the Markdown prompt as the default.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd adaptive_chat_server_dart && fvm dart test`

Expected: PASS, including the pre-existing `existing flags keep their documented defaults` test. **If that test fails, read it before changing it** — it exists to catch exactly this kind of default change. Update it deliberately to the new expected defaults and note the change in its comment; do not delete it.

- [ ] **Step 6: Verify both modes start correctly**

```bash
cd adaptive_chat_server_dart
timeout 5 fvm dart run bin/server.dart --port 8099 --echo 2>&1 | head -5
timeout 8 fvm dart run bin/server.dart --port 8099 2>&1 | head -5
```

Expected: the first starts the echo demo without contacting Ollama; the second announces the card prompt and runs the Ollama preflight against `127.0.0.1:11434`. If Ollama is not running, the second must fail with the existing clear preflight message ("Ollama unreachable … is `ollama serve` running?") rather than a stack trace — that message is now on the default path, so confirm it reads well.

- [ ] **Step 7: Update the README**

The README describes echo as the default and card mode as opt-in. Correct every such statement — including the quick-start command — so the documented behaviour matches. Search it:

```bash
cd adaptive_chat_server_dart && grep -n "echo\|--system-prompt-file\|--ollama-url" README.md
```

- [ ] **Step 8: Changelog, gates, commit**

```markdown
- **Breaking:** card replies are now the default and the echo demo is opt-in
  via `--echo`. `--ollama-url` defaults to `http://127.0.0.1:11434`, and the
  bundled system prompt is `card_system_prompt.txt`. Previously a
  card-rendering chat server needed two flags to render cards and none to do
  nothing interesting; starting it plainly produced Markdown bullet points
  that no rephrasing could turn into a card. A server started without Ollama
  running now fails the startup preflight with its existing diagnostic
  instead of silently echoing.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/bin/server.dart adaptive_chat_server_dart/lib/src/cli.dart adaptive_chat_server_dart/test/cli_test.dart adaptive_chat_server_dart/README.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server)!: default to card replies, make echo opt-in"
```

---

### Task 11: Move the per-model measurements into the durable record

Measurements from the 2026-08-14 runs live in scratch reports and in this plan's task output. `ModelBehavior.md` exists precisely so results outlive the work that produced them. Anything not transferred is lost when the scratch directory is cleared.

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: the numbers produced by Tasks 4, 6, 7, and 9.
- Produces: nothing.

- [ ] **Step 1: Add the fence-rate finding to the `qwen2.5-coder:7b` section**

Append to the `### \`qwen2.5-coder:7b\`` section:

````markdown
**It fences its card almost every time.** Across two independent
investigations on 2026-08-14, the model wrapped its JSON in a ` ```json `
fence in 7/7 and 9/9 replies respectively, despite the prompt forbidding
fences in two places. This is currently harmless — `_stripFence` recovers a
reply that is _only_ a fence — but the detector is carrying a load the prompt
claims it should not have to, and fence-stripping has regressed here before
(see `a13808b`). Anything that follows the closing fence defeats the
recovery, which is why "nothing after the closing fence" is the load-bearing
rule rather than "no fence".
````

- [ ] **Step 2: Record the multi-turn result in full**

The table currently records only the failing half. In `### 4. Multi-turn set — history replay`, append:

```markdown
Re-keying the escape hatch from confidence to capability moved this from
**0/6 to 5/6** on the options set with prior prose turns (`choiceset_ab.dart`,
`t=0`). The one holdout is "which build mode should I use?" — a recommendation
rather than an enumeration, where prose is defensible — and it failed
consistently across samples rather than intermittently, so it was left rather
than overfitted.
```

Update the `With history` cell for `qwen2.5-coder:7b` in the model table to reflect the post-fix state:

```markdown
| ✅ 5/6 after the escape-hatch fix (was 0/6) |
```

- [ ] **Step 3: Record the two-prompt comparison**

In `## Which system prompt produced the number`, append:

```markdown
Full result, `qwen2.5-coder:7b` at `t=0`, eight options questions, only the
prompt file differing: **0/8 cards / 8/8 prose** on the default prompt versus
**8/8 cards / 0/8 prose** on the card prompt, with zero broken cards either
way. Six of the eight card-prompt replies contained a real `Input.ChoiceSet`;
the other two chose a `FactSet` and a `TextBlock`, which are defensible for
those questions.
```

- [ ] **Step 4: Record whatever Tasks 6 and 7 measured**

Add the compare-and-comment and options-with-history figures from Tasks 6 and 7 to the `qwen2.5-coder:7b` section, each with its model, temperature, and condition. If either task recorded a negative result — a candidate that did not beat baseline — record that too. A measured negative is more valuable than silence, because it stops the next person retrying the same idea.

- [ ] **Step 5: Verify the table stays consistent**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
python3 - <<'PY'
rows=[l for l in open('adaptive_chat_server_dart/ModelBehavior.md')
      if l.startswith('| ') and ' GB ' in l and '---' not in l and not l.startswith('| Model')]
cols={len(l.split('|'))-2 for l in rows}
print(f"model rows: {len(rows)}, column counts: {cols}")
assert cols=={6}, 'every model row must still have 6 columns'
print("OK")
PY
npm run format:md:chat && npm run check:md:chat
```

Expected: 14 rows, 6 columns, Prettier clean.

- [ ] **Step 6: Changelog and commit**

```markdown
- Added: `ModelBehavior.md` now records the fence rate, the full multi-turn
  before/after, and the default-vs-card prompt comparison for
  `qwen2.5-coder:7b`. These were measured on 2026-08-14 but lived only in
  scratch reports, which is exactly the loss this file exists to prevent.
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): move the 2026-08-14 measurements into ModelBehavior.md"
```

---

## Verification (full suite)

Run from the repo root after the final task:

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

All must pass: analyze clean, every test passing, format clean, both Markdown checks clean.

Then confirm the prompt changes did not regress the shipped behaviour, one model at a time:

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/temperature_stress.dart --model qwen2.5-coder:7b --samples 2
fvm dart run tool/model_probes/prompt_ab.dart --model qwen2.5-coder:7b --samples 1
fvm dart run tool/model_probes/choiceset_ab.dart --model qwen2.5-coder:7b --samples 2
```

Expected: stress at or above its pre-plan level at both temperatures, the code A/B set unchanged, and the choice-set score improved over the pre-plan baseline.

Invoke **`superpowers:verification-before-completion`** and paste the command output — exit codes and pass/fail counts — before claiming this plan is complete.

## Out of scope

Recorded so the next person does not assume these were missed:

- **A detector-side fence repair.** Both investigations proposed stripping a fence whose closer is followed only by prose, the way bracket repair handled the missing-`[ ]` shape. That would make the shape safe regardless of wording, but it risks discarding user-facing prose, and there is an explicit test (`bracket repair does not rescue trailing prose`) establishing that mixed replies stay text. Changing that is a deliberate design decision, not a follow-up.
- **The four unprobed models** (`qwen3-coder:30b` and the three ~24 GB Nemotrons). Task 9 fills the multi-turn column only for models that already have cold-start numbers; these four have neither and are a separate exercise.
- **`llama3.2:latest`'s multi-turn result.** It is retired as a default on cold-start evidence alone, so a history number would not change any decision.
