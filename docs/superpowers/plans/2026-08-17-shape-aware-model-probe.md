# Shape-Aware Model Probe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `shape_ab.dart`, a probe that verifies which Adaptive Card element types a model actually emits — 25 cases with alternative accepted types, cold-start and with-history — so shape failures can be attributed instead of guessed at.

**Architecture:** Three new pure units plus one runner. A recursive type walker lands in `probe_support.dart` (shared, replacing `choiceset_ab.dart`'s private copy). A `shape_cases.dart` file owns the `ShapeCase` model, the 25-case table, and the seven-outcome classifier — all pure and unit-testable. `shape_ab.dart` is the CLI and run loop only. Every judgement still routes through the server's own `tryParseCardBody`, so a probe can never report a pass rate the running server disagrees with.

**Tech Stack:** Dart 3.12 (FVM-pinned), `package:test`, `package:args`, a local Ollama at `http://127.0.0.1:11434`, Prettier for Markdown.

**Spec:** [`2026-08-17-shape-aware-model-probe-design.md`](../specs/2026-08-17-shape-aware-model-probe-design.md)

## Global Constraints

- Prefix **every** `dart` and `flutter` command with `fvm`. Bare commands may resolve to a different SDK.
- Work from `adaptive_chat_server_dart/` unless a step says otherwise. It is **not** a pub workspace member — it resolves standalone via `fvm dart pub get`.
- **One Ollama model at a time.** Never run two probes concurrently, never interleave models. Unload with `curl -s http://127.0.0.1:11434/api/generate -d '{"model":"<tag>","keep_alive":0}' > /dev/null` before switching. Only Task 6 talks to a model, and it uses `qwen2.5-coder:7b` only.
- Every change under `adaptive_chat_server_dart/` needs a bullet in the `## [Unreleased]` section of `adaptive_chat_server_dart/CHANGELOG.md`.
- Markdown in this package is Prettier-governed. Run `npm run format:md:chat` from the repo root after editing any `.md`, and verify with `npm run check:md:chat`. **Prettier rewrites `*italic*` to `_italic_`** — this has broken the build twice.
- Analysis is `very_good_analysis`: single quotes, package imports for `lib/`, no `print` (use `stdout.writeln` in scripts, `dart:developer` `log` in library code).
- Gates before any task is complete: `fvm dart analyze` clean, `fvm dart test` all passing, `fvm dart format --output=none --set-exit-if-changed .` clean.
- Probe numbers are only meaningful with their condition attached. Always record **which model**, **which temperature**, and **cold-start vs with-history**.
- `choiceset_ab.dart` is the reproducer for thirteen models' recorded `N/6` scores in `ModelBehavior.md`. Its prompts, conditions, sample handling, and output format must not change. Task 1 refactors its internals only.

---

## File Structure

| File                                         | Responsibility                                                 | Tasks |
| -------------------------------------------- | -------------------------------------------------------------- | ----- |
| `tool/model_probes/probe_support.dart`       | Shared plumbing; gains the recursive element-type walker       | 1     |
| `test/probe_walker_test.dart`                | Walker behavior — the tests that make Task 1's refactor safe   | 1     |
| `tool/model_probes/choiceset_ab.dart`        | Refactored onto the shared walker; behavior unchanged          | 1     |
| `tool/model_probes/shape_cases.dart`         | `ShapeCase`, the 25-case table, `judgeShape` — pure, no I/O    | 2, 3  |
| `test/shape_cases_test.dart`                 | Case-table validity against the schema enum, plus sanity rules | 2     |
| `test/shape_judge_test.dart`                 | The seven-outcome classifier                                   | 3     |
| `tool/model_probes/shape_ab.dart`            | CLI, case selection, two-condition run loop, output            | 4, 5  |
| `tool/model_probes/README.md`                | Script table row and usage note                                | 5     |
| `adaptive_chat_server_dart/ModelBehavior.md` | Baseline result for `qwen2.5-coder:7b`                         | 6     |
| `adaptive_chat_server_dart/CHANGELOG.md`     | One bullet per task                                            | 1-6   |

**Deviation from the spec, flagged deliberately.** The spec says `shape_ab.dart` "owns the case table and the run loop." This plan splits those: the table and classifier go in `shape_cases.dart`, the runner stays in `shape_ab.dart`. Reason: the table and classifier are the parts that need unit tests, and importing a file whose `main()` builds an `HttpClient` into a test is worse than a two-file split. The spec's intent — one owner for the case data — is preserved.

---

### Task 1: Shared element-type walker, and refactor `choiceset_ab.dart` onto it

`choiceset_ab.dart` has a private `_hasChoiceSet` that walks a parsed card body looking for one type. The new probe needs the same walk for twenty-one types, and needs to report what it _found_ for diagnostics. Extract it, test it, and move the existing probe onto it — the tests are what make touching the reproducer safe.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/probe_support.dart`
- Create: `adaptive_chat_server_dart/test/probe_walker_test.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/choiceset_ab.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `tryParseCardBody` from `package:adaptive_chat_server_dart/src/card_detect.dart` (already imported by `probe_support.dart`).
- Produces:

  - `Set<String> collectElementTypes(List<Map<String, dynamic>> body)`
  - `bool cardContainsAnyType(List<Map<String, dynamic>> body, Set<String> wanted)`

  Tasks 3 and 4 both use these.

- [ ] **Step 1: Write the failing tests**

Create `adaptive_chat_server_dart/test/probe_walker_test.dart`:

```dart
import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:test/test.dart';

// Relative: probe_support lives outside lib/, so there is no package: URI.
import '../tool/model_probes/probe_support.dart';

/// Parses [raw] the way every probe does, failing the test if it is not a
/// card — so a broken fixture reads as a fixture bug, not a walker bug.
List<Map<String, dynamic>> body(String raw) {
  final parsed = tryParseCardBody(raw);
  expect(parsed, isNotNull, reason: 'fixture is not a parseable card: $raw');
  return parsed!;
}

void main() {
  group('collectElementTypes', () {
    test('finds types at the top level of a bare array', () {
      final types = collectElementTypes(
        body(
          '[{"type":"TextBlock","text":"hi","wrap":true},'
          '{"type":"Input.Date","id":"when"}]',
        ),
      );
      expect(types, containsAll(<String>['TextBlock', 'Input.Date']));
    });

    test('finds a type nested inside Carousel pages', () {
      final types = collectElementTypes(
        body(
          '{"type":"Carousel","pages":[{"type":"CarouselPage","items":'
          '[{"type":"Input.ChoiceSet","id":"x","choices":[]}]}]}',
        ),
      );
      expect(types, contains('Input.ChoiceSet'));
      expect(types, contains('Carousel'));
    });

    test('finds a type nested inside Table cells', () {
      final types = collectElementTypes(
        body(
          '{"type":"Table","columns":[{"width":1}],"rows":[{"type":"TableRow",'
          '"cells":[{"type":"TableCell","items":[{"type":"Badge",'
          '"text":"New"}]}]}]}',
        ),
      );
      expect(types, contains('Badge'));
      expect(types, contains('Table'));
    });

    test('finds a type nested inside ColumnSet columns', () {
      final types = collectElementTypes(
        body(
          '{"type":"ColumnSet","columns":[{"type":"Column","width":1,"items":'
          '[{"type":"Rating","value":4,"max":5}]}]}',
        ),
      );
      expect(types, contains('Rating'));
    });

    test('finds types inside the full AdaptiveCard wrapper', () {
      final types = collectElementTypes(
        body(
          '{"type":"AdaptiveCard","version":"1.5","body":'
          '[{"type":"Chart.Gauge","value":72,"min":0,"max":100}]}',
        ),
      );
      expect(types, contains('Chart.Gauge'));
    });

    test('a single bare element object yields its own type', () {
      final types = collectElementTypes(body('{"type":"Input.Time","id":"t"}'));
      expect(types, equals(<String>{'Input.Time'}));
    });
  });

  group('cardContainsAnyType', () {
    final twoElements = body(
      '[{"type":"TextBlock","text":"Pick one","wrap":true},'
      '{"type":"Input.ChoiceSet","id":"c","choices":[]}]',
    );

    test('true when the single wanted type is present', () {
      expect(cardContainsAnyType(twoElements, {'Input.ChoiceSet'}), isTrue);
    });

    test('true when ANY of several wanted types is present', () {
      // The alternatives rule: the model picks among acceptable shapes.
      expect(
        cardContainsAnyType(twoElements, {'Chart.Pie', 'Input.ChoiceSet'}),
        isTrue,
      );
    });

    test('false when none of the wanted types is present', () {
      expect(cardContainsAnyType(twoElements, {'Carousel', 'Table'}), isFalse);
    });

    test('false for an empty wanted set', () {
      expect(cardContainsAnyType(twoElements, <String>{}), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd adaptive_chat_server_dart && fvm dart test test/probe_walker_test.dart`

Expected: compile failure — `collectElementTypes` and `cardContainsAnyType` are not defined. A failure naming those two symbols confirms the test is reaching the right file; any other error means the relative import is wrong, so fix that rather than the test.

- [ ] **Step 3: Implement the walker**

Append to `adaptive_chat_server_dart/tool/model_probes/probe_support.dart`:

```dart
/// Every element `type` present anywhere in a parsed card [body], including
/// types nested inside `Carousel` pages, `Table` cells, and `Column` items.
///
/// Returns what the model actually emitted, which is what makes a shape
/// failure diagnosable: "carousel failed" and "carousel failed, it emitted
/// three TextBlocks" call for different fixes.
Set<String> collectElementTypes(List<Map<String, dynamic>> body) {
  final found = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      final type = node['type'];
      if (type is String && type.isNotEmpty) found.add(type);
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  body.forEach(walk);
  return found;
}

/// Whether any element in [body] has a type in [wanted].
///
/// [wanted] is a set rather than a single type because several shapes are
/// often equally correct — "summarize these specs" is defensibly a `FactSet`
/// or a `Table`, and forcing one would score a good reply as a failure.
bool cardContainsAnyType(
  List<Map<String, dynamic>> body,
  Set<String> wanted,
) => collectElementTypes(body).intersection(wanted).isNotEmpty;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd adaptive_chat_server_dart && fvm dart test test/probe_walker_test.dart`

Expected: PASS, 10 tests.

- [ ] **Step 5: Refactor `choiceset_ab.dart` onto the shared walker**

In `adaptive_chat_server_dart/tool/model_probes/choiceset_ab.dart`, delete the entire private `_hasChoiceSet` function (it starts `bool _hasChoiceSet(String reply) {` and ends with `return body.any(contains);` plus its closing brace) and replace it with:

```dart
bool _hasChoiceSet(String reply) {
  final body = tryParseCardBody(reply);
  return body != null && cardContainsAnyType(body, {'Input.ChoiceSet'});
}
```

Keep the function name and signature: its call site (`final ok = _hasChoiceSet(outcome.reply);`) and every other line of the file stay exactly as they are. The `tryParseCardBody` import is already present.

- [ ] **Step 6: Verify the refactor changed nothing observable**

Run: `cd adaptive_chat_server_dart && fvm dart analyze && fvm dart test`

Expected: analyze clean; all tests pass (179 before this task, plus the 10 new walker tests).

Then confirm the script still runs and still prints its unchanged output format, without contacting a model:

Run: `cd adaptive_chat_server_dart && fvm dart run tool/model_probes/choiceset_ab.dart --help`

Expected: usage text, exit 0, no network call. (If this starts a probe run instead of printing usage, the `--help` early-return has regressed — that was fixed in an earlier plan and must stay.)

- [ ] **Step 7: Changelog, gates, commit**

Add to the top of `## [Unreleased]` in `adaptive_chat_server_dart/CHANGELOG.md`:

```markdown
- Added: `collectElementTypes` and `cardContainsAnyType` in
  `probe_support.dart` — a recursive element-type walker shared by the
  probes, reporting every `type` present anywhere in a parsed card body
  including inside `Carousel` pages, `Table` cells, and `Column` items.
  `choiceset_ab.dart` now uses it instead of a private copy; its prompts,
  conditions, and output are unchanged, so the thirteen `N/6` scores in
  `ModelBehavior.md` remain reproducible. New unit tests pin the walker's
  behavior, which is what makes touching that reproducer safe.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/probe_support.dart \
        adaptive_chat_server_dart/tool/model_probes/choiceset_ab.dart \
        adaptive_chat_server_dart/test/probe_walker_test.dart \
        adaptive_chat_server_dart/CHANGELOG.md
git commit -m "refactor(chat-server): share the card element-type walker across probes"
```

---

### Task 2: `ShapeCase` and the 25-case table

The table is the crux of this probe: a wrong expectation silently fails every model and gets written into the durable record as a finding. Two tests guard it — one that every accepted type is a type the schema actually allows, one that the table is internally sane.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/shape_cases.dart`
- Create: `adaptive_chat_server_dart/test/shape_cases_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: nothing from Task 1 (this task is pure data).
- Produces:

  - `class ShapeCase` with `final String id`, `final String prompt`, `final Set<String> accepted`, `final bool requiresInput`
  - `const List<ShapeCase> shapeCases` — 25 entries
  - `const String shapeHistoryUser` and `const String shapeHistoryAssistant` — the two prose turns, copied verbatim from `choiceset_ab.dart` so both probes establish history identically

  Task 3 adds `judgeShape` to this same file. Task 4 consumes all of the above.

- [ ] **Step 1: Write the failing tests**

Create `adaptive_chat_server_dart/test/shape_cases_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: shape_cases lives outside lib/, so there is no package: URI.
import '../tool/model_probes/shape_cases.dart';

/// The element types `--json-format schema` will actually accept, read from
/// the shipped schema so this test tracks the schema rather than a copy.
Set<String> schemaElementTypes() {
  final schema =
      jsonDecode(File('assets/card_schema.json').readAsStringSync())
          as Map<String, dynamic>;
  final defs = schema[r'$defs'] as Map<String, dynamic>;
  final element = defs['Element'] as Map<String, dynamic>;
  final properties = element['properties'] as Map<String, dynamic>;
  final typeSchema = properties['type'] as Map<String, dynamic>;
  return (typeSchema['enum'] as List).cast<String>().toSet();
}

void main() {
  group('the shape case table', () {
    test('has 25 cases', () {
      expect(shapeCases, hasLength(25));
    });

    test('every accepted type is one the schema allows', () {
      final allowed = schemaElementTypes();
      final bad = <String>{};
      for (final c in shapeCases) {
        bad.addAll(c.accepted.difference(allowed));
      }
      expect(
        bad,
        isEmpty,
        reason:
            'These accepted types are not in card_schema.json\'s enum, so the '
            'probe would be asserting a shape the server itself rejects — a '
            'typo here silently fails every model: $bad',
      );
    });

    test('case ids are unique', () {
      final ids = shapeCases.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('no case has an empty id or prompt', () {
      for (final c in shapeCases) {
        expect(c.id, isNotEmpty);
        expect(c.prompt.trim(), isNotEmpty, reason: 'case ${c.id}');
      }
    });

    test('requiresInput is only set where every accepted type is an input', () {
      for (final c in shapeCases.where((c) => c.requiresInput)) {
        expect(
          c.accepted.every((t) => t.startsWith('Input.')),
          isTrue,
          reason:
              'case ${c.id} demands an input but accepts a non-input type '
              '(${c.accepted}) — it cannot sensibly require both',
        );
        expect(c.accepted, isNotEmpty, reason: 'case ${c.id}');
      }
    });

    test('exactly one case is the prose negative control', () {
      final controls = shapeCases.where((c) => c.accepted.isEmpty).toList();
      expect(controls, hasLength(1));
      expect(controls.single.id, 'prose');
      expect(controls.single.requiresInput, isFalse);
    });

    test('the six choice cases match choiceset_ab.dart verbatim', () {
      // Copied from choiceset_ab.dart's _prompts. If that list changes, the
      // two probes stop being comparable and this test should fail loudly.
      const expected = [
        'what are my options for deployment targets',
        'which log level should I use?',
        'what environments can I deploy to?',
        'what are my options for notification frequency',
        'help me pick a database engine',
        'what build modes can I choose from?',
      ];
      final choicePrompts = shapeCases
          .where((c) => c.id.startsWith('choice'))
          .map((c) => c.prompt)
          .toList();
      expect(choicePrompts, equals(expected));
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd adaptive_chat_server_dart && fvm dart test test/shape_cases_test.dart`

Expected: compile failure — `shape_cases.dart` does not exist. That is the expected RED state.

- [ ] **Step 3: Create the case table**

Create `adaptive_chat_server_dart/tool/model_probes/shape_cases.dart`:

```dart
/// The cases `shape_ab.dart` measures, and the rules for judging a reply
/// against one.
///
/// Kept separate from the runner so the table and the classifier can be unit
/// tested without constructing an `HttpClient`.
library;

/// One prompt, the element types that would answer it acceptably, and whether
/// it asks the user for a value.
///
/// [accepted] is a set because several shapes are often equally correct —
/// "summarize these specs" is defensibly a `FactSet` or a `Table`. An empty
/// [accepted] means the case is the negative control: the correct reply is
/// prose, and a card is the failure.
///
/// [requiresInput] separates "sent the wrong input widget" from "sent no
/// input at all", which are different bugs with different fixes.
class ShapeCase {
  /// Creates a case.
  const ShapeCase({
    required this.id,
    required this.prompt,
    required this.accepted,
    this.requiresInput = false,
  });

  /// Short stable identifier, used by `--only` and in output.
  final String id;

  /// The user turn sent to the model.
  final String prompt;

  /// Element types that count as a correct shape; empty means "expect prose".
  final Set<String> accepted;

  /// Whether the reply must contain some `Input.*` element.
  final bool requiresInput;
}

/// The two prose turns that establish Markdown as the conversation's format.
///
/// Copied verbatim from `choiceset_ab.dart` so the with-history condition is
/// identical across both probes and their numbers stay comparable.
const shapeHistoryUser = 'what is CI/CD?';

/// The assistant half of [shapeHistoryUser]'s exchange.
const shapeHistoryAssistant =
    'CI/CD is a practice where code changes are automatically built, tested, '
    'and deployed.\n\n- **CI** builds and tests every commit.\n'
    '- **CD** ships passing builds to production.';

/// Every case, covering 21 of the 24 element types the card system prompt
/// advertises.
///
/// `TextBlock` is exercised constantly but never asserted — it is the
/// ubiquitous fallback, so asserting it would pass trivially. `Icon` is
/// decorative, so its absence is not a failure. `Image` cannot be elicited
/// honestly because the prompt forbids inventing URLs.
const shapeCases = <ShapeCase>[
  // Inputs — each asks the user for a value.
  ShapeCase(
    id: 'date',
    prompt: 'Book me a meeting. Ask me for a date.',
    accepted: {'Input.Date'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'time',
    prompt: 'Ask me what time I want the standup.',
    accepted: {'Input.Time'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'toggle',
    prompt: 'Ask me whether to enable email notifications.',
    accepted: {'Input.Toggle', 'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'text',
    prompt: 'Ask me to describe the bug in a few sentences.',
    accepted: {'Input.Text'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'number',
    prompt: 'Ask me how many seats I need to license.',
    accepted: {'Input.Number', 'Input.Text'},
    requiresInput: true,
  ),

  // Pick-from-a-set — verbatim from choiceset_ab.dart.
  ShapeCase(
    id: 'choice1',
    prompt: 'what are my options for deployment targets',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice2',
    prompt: 'which log level should I use?',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice3',
    prompt: 'what environments can I deploy to?',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice4',
    prompt: 'what are my options for notification frequency',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice5',
    prompt: 'help me pick a database engine',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice6',
    prompt: 'what build modes can I choose from?',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),

  // Charts.
  ShapeCase(
    id: 'pie',
    prompt:
        'Show the market share of the top 5 phone vendors as parts of a whole.',
    accepted: {'Chart.Pie', 'Chart.Donut'},
  ),
  ShapeCase(
    id: 'bar',
    prompt: 'Compare signups for Mon-Fri as a bar chart.',
    accepted: {'Chart.VerticalBar', 'Chart.HorizontalBar'},
  ),
  ShapeCase(
    id: 'line',
    prompt: 'Show response time trending across the last 6 releases.',
    accepted: {'Chart.Line'},
  ),
  ShapeCase(
    id: 'gauge',
    prompt: 'Show disk usage at 72% against a 0-100 range.',
    accepted: {'Chart.Gauge'},
  ),

  // Rating — read-only display vs collecting a value from the user.
  ShapeCase(
    id: 'rating_show',
    prompt:
        "What's the average customer rating for the iPhone 15 Pro? "
        'Show it as stars.',
    accepted: {'Rating'},
  ),
  ShapeCase(
    id: 'rating_ask',
    prompt: 'Ask me to rate my support experience from 1 to 5.',
    accepted: {'Input.ChoiceSet', 'Input.Number'},
    requiresInput: true,
  ),

  // Display.
  ShapeCase(
    id: 'carousel',
    prompt: 'Walk me through setting up CI/CD in 3 steps, one step per page.',
    accepted: {'Carousel'},
  ),
  ShapeCase(
    id: 'table',
    prompt: 'Table of the 4 largest planets with diameter and moons.',
    accepted: {'Table'},
  ),
  ShapeCase(
    id: 'facts',
    prompt: 'Summarize the iPhone 15 Pro specs as labelled facts.',
    accepted: {'FactSet', 'Table'},
  ),
  ShapeCase(
    id: 'columnset',
    prompt: 'Compare SQLite and Postgres side by side.',
    accepted: {'ColumnSet', 'Table'},
  ),
  ShapeCase(
    id: 'codeblock',
    prompt:
        'Dart snippet that reads a JSON file and prints the "name" field, '
        'with a short explanation.',
    accepted: {'CodeBlock'},
  ),
  ShapeCase(
    id: 'progress',
    prompt: 'Show me the deployment is 72% complete.',
    accepted: {'ProgressBar', 'ProgressRing'},
  ),
  ShapeCase(
    id: 'badge',
    prompt: 'Show the current build status as a small status pill.',
    accepted: {'Badge'},
  ),

  // Negative control: the right answer is prose, and a card is the failure.
  ShapeCase(
    id: 'prose',
    prompt: 'In two sentences, why is the sky blue?',
    accepted: {},
  ),
];
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd adaptive_chat_server_dart && fvm dart test test/shape_cases_test.dart`

Expected: PASS, 7 tests.

If the schema test fails naming a type, **do not edit the test to accept it** — the type is either misspelled in the table or genuinely absent from `card_schema.json`, and both are real problems the test exists to catch. Report which.

- [ ] **Step 5: Changelog, gates, commit**

```markdown
- Added: `shape_cases.dart` — a 25-case table naming, for each prompt, the
  element types that would answer it acceptably. Expectations are sets rather
  than single types because several shapes are often equally correct
  ("summarize these specs" is defensibly a `FactSet` or a `Table`), and this
  file already records one case where a strict assertion was the bug rather
  than the model. Tests assert every accepted type exists in
  `card_schema.json`'s enum, so a typo cannot silently fail every model.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/shape_cases.dart \
        adaptive_chat_server_dart/test/shape_cases_test.dart \
        adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add the shape-probe case table"
```

---

### Task 3: `judgeShape` — the seven-outcome classifier

The existing `judgeReply` answers "card or prose". This adds the shape layer on top of it, and the outcome ordering matters: `no-input` must be decided before `wrong-shape`, or "sent a `TextBlock` when asked for a date" and "sent an `Input.Text` when asked for a date" collapse into the same label.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/shape_cases.dart`
- Create: `adaptive_chat_server_dart/test/shape_judge_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `collectElementTypes` from Task 1; `ShapeCase` from Task 2; `ProbeOutcome` and `judgeReply` from `probe_support.dart`; `tryParseCardBody` from `card_detect.dart`.
- Produces:

  - `class ShapeResult` with `final String caseId`, `final bool pass`, `final String label`, `final Set<String> found`, `final Set<String> wanted`, and `String describe()`
  - `ShapeResult judgeShape(ShapeCase c, ProbeOutcome outcome)`

  Task 4 consumes both.

- [ ] **Step 1: Write the failing tests**

Create `adaptive_chat_server_dart/test/shape_judge_test.dart`:

````dart
import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';
import '../tool/model_probes/shape_cases.dart';

/// Builds the outcome a real probe would produce for [reply], using the
/// server's own judgement — so these tests exercise the same path the probe
/// does rather than a hand-built stand-in.
ProbeOutcome outcomeFor(String reply) => judgeReply(reply, 0);

const dateCase = ShapeCase(
  id: 'date',
  prompt: 'Book me a meeting. Ask me for a date.',
  accepted: {'Input.Date'},
  requiresInput: true,
);

const tableCase = ShapeCase(
  id: 'table',
  prompt: 'Table of the 4 largest planets.',
  accepted: {'Table'},
);

const proseCase = ShapeCase(
  id: 'prose',
  prompt: 'In two sentences, why is the sky blue?',
  accepted: {},
);

void main() {
  group('judgeShape', () {
    test('ok when an accepted type is present', () {
      final r = judgeShape(
        dateCase,
        outcomeFor('{"type":"Input.Date","id":"when"}'),
      );
      expect(r.pass, isTrue);
      expect(r.label, 'ok');
      expect(r.found, contains('Input.Date'));
    });

    test('ok when ANY of several accepted types is present', () {
      const facts = ShapeCase(
        id: 'facts',
        prompt: 'Summarize the specs as labelled facts.',
        accepted: {'FactSet', 'Table'},
      );
      final r = judgeShape(
        facts,
        outcomeFor(
          '{"type":"Table","columns":[{"width":1}],"rows":[]}',
        ),
      );
      expect(r.pass, isTrue, reason: 'Table is an accepted alternative');
    });

    test('no-input when a card has content but no Input.* at all', () {
      final r = judgeShape(
        dateCase,
        outcomeFor('{"type":"TextBlock","text":"Sure, when?","wrap":true}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'no-input');
    });

    test('wrong-shape when an input is present but the wrong one', () {
      // This is the distinction no-input-before-wrong-shape buys us.
      final r = judgeShape(
        dateCase,
        outcomeFor('{"type":"Input.Text","id":"when"}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'wrong-shape');
      expect(r.found, contains('Input.Text'));
    });

    test('wrong-shape for a non-input case with the wrong element', () {
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"TextBlock","text":"Jupiter is big","wrap":true}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'wrong-shape');
    });

    test('prose when a card was expected and clean prose came back', () {
      final r = judgeShape(tableCase, outcomeFor('Jupiter is the largest.'));
      expect(r.pass, isFalse);
      expect(r.label, 'prose');
      expect(r.found, isEmpty);
    });

    test('broken when the reply is malformed JSON', () {
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"Table","rows":[{"type":"TableRow"'),
      );
      expect(r.pass, isFalse);
      expect(r.label, startsWith('broken'));
    });

    test('broken when prose wraps a card', () {
      final r = judgeShape(
        tableCase,
        outcomeFor(
          'Sure, here you go:\n\n```json\n'
          '{"type":"TextBlock","text":"hi","wrap":true}\n```',
        ),
      );
      expect(r.pass, isFalse);
      expect(
        r.label,
        startsWith('broken'),
        reason: 'the user sees raw JSON, so this is not a passing prose reply',
      );
    });

    test('prose-ok when the control case correctly returns prose', () {
      final r = judgeShape(
        proseCase,
        outcomeFor('Sunlight scatters off air molecules, and blue scatters '
            'most. That is why the sky looks blue.'),
      );
      expect(r.pass, isTrue);
      expect(r.label, 'prose-ok');
    });

    test('unwanted-card when the control case returns a card', () {
      final r = judgeShape(
        proseCase,
        outcomeFor('{"type":"TextBlock","text":"Blue scatters","wrap":true}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'unwanted-card');
    });

    test('describe() names what was found on a wrong-shape failure', () {
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"TextBlock","text":"x","wrap":true}'),
      );
      expect(r.describe(), contains('TextBlock'));
      expect(r.describe(), contains('Table'));
    });
  });
}
````

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd adaptive_chat_server_dart && fvm dart test test/shape_judge_test.dart`

Expected: compile failure — `judgeShape` and `ShapeResult` are not defined.

- [ ] **Step 3: Implement the classifier**

Add to `adaptive_chat_server_dart/tool/model_probes/shape_cases.dart`. The imports at the top of that file become:

```dart
import 'package:adaptive_chat_server_dart/src/card_detect.dart';

// Relative: probe_support lives outside lib/, beside this file.
import 'probe_support.dart';
```

Then append:

```dart
/// How one reply scored against one [ShapeCase].
class ShapeResult {
  /// Creates a result.
  const ShapeResult({
    required this.caseId,
    required this.pass,
    required this.label,
    required this.found,
    required this.wanted,
  });

  /// The case this judged.
  final String caseId;

  /// Whether the reply was the right shape.
  final bool pass;

  /// One of `ok`, `prose-ok`, `prose`, `no-input`, `wrong-shape`,
  /// `unwanted-card`, or `broken: <reason>`.
  final String label;

  /// Every element type the reply actually contained, empty when it was not
  /// a card.
  final Set<String> found;

  /// The case's accepted types, carried so a failure line can show both sides
  /// of the mismatch without the caller re-looking-up the case.
  final Set<String> wanted;

  /// A one-line explanation, naming both sides when the shape was wrong.
  ///
  /// "carousel failed" and "carousel failed, it emitted three TextBlocks"
  /// call for different fixes, so a wrong-shape line prints what came back
  /// next to what was acceptable.
  String describe() {
    if (pass) return label == 'ok' ? _sorted(found).join(', ') : label;
    if (label == 'wrong-shape' || label == 'no-input') {
      return '$label: got {${_sorted(found).join(', ')}} '
          'want {${_sorted(wanted).join(', ')}}';
    }
    if (label == 'unwanted-card') {
      return '$label: got {${_sorted(found).join(', ')}} want prose';
    }
    return label;
  }

  static List<String> _sorted(Set<String> types) => types.toList()..sort();
}

/// Judges [outcome] against [c], layering shape checks over the server's own
/// card/prose verdict.
///
/// `no-input` is decided before `wrong-shape` deliberately: "asked for a date
/// and got a bare TextBlock" and "asked for a date and got an Input.Text" are
/// different failures, and collapsing them loses the distinction that says
/// whether the model understood it needed to collect something at all.
ShapeResult judgeShape(ShapeCase c, ProbeOutcome outcome) {
  final body = tryParseCardBody(outcome.reply);

  // Negative control: prose is correct here and a card is the failure.
  if (c.accepted.isEmpty) {
    return body == null
        ? ShapeResult(
            caseId: c.id,
            pass: true,
            label: 'prose-ok',
            found: const {},
            wanted: c.accepted,
          )
        : ShapeResult(
            caseId: c.id,
            pass: false,
            label: 'unwanted-card',
            found: collectElementTypes(body),
            wanted: c.accepted,
          );
  }

  if (body == null) {
    // outcome.ok is true only for clean prose here, since a card would have
    // parsed; anything else is broken and carries the server's own reason.
    return ShapeResult(
      caseId: c.id,
      pass: false,
      label: outcome.ok ? 'prose' : 'broken: ${outcome.label}',
      found: const {},
      wanted: c.accepted,
    );
  }

  final found = collectElementTypes(body);
  if (c.requiresInput && !found.any((t) => t.startsWith('Input.'))) {
    return ShapeResult(
      caseId: c.id,
      pass: false,
      label: 'no-input',
      found: found,
      wanted: c.accepted,
    );
  }
  if (found.intersection(c.accepted).isEmpty) {
    return ShapeResult(
      caseId: c.id,
      pass: false,
      label: 'wrong-shape',
      found: found,
      wanted: c.accepted,
    );
  }
  return ShapeResult(
    caseId: c.id,
    pass: true,
    label: 'ok',
    found: found,
    wanted: c.accepted,
  );
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd adaptive_chat_server_dart && fvm dart test test/shape_judge_test.dart`

Expected: PASS, 11 tests.

- [ ] **Step 5: Changelog, gates, commit**

```markdown
- Added: `judgeShape` in `shape_cases.dart`, a seven-outcome classifier
  layered over the server's own card/prose verdict: `ok`, `prose-ok`,
  `prose`, `no-input`, `wrong-shape`, `unwanted-card`, `broken`. `no-input`
  is decided before `wrong-shape` so "asked for a date, got a bare
  TextBlock" stays distinguishable from "asked for a date, got an
  Input.Text" — different failures with different fixes.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/shape_cases.dart \
        adaptive_chat_server_dart/test/shape_judge_test.dart \
        adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add the shape-probe outcome classifier"
```

---

### Task 4: `shape_ab.dart` — the runner

Two conditions per case, an erosion delta between them, and case selection that rejects a typo'd id rather than silently running fewer cases.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `ShapeCase`, `shapeCases`, `shapeHistoryUser`, `shapeHistoryAssistant`, `judgeShape`, `ShapeResult` from Task 2/3; `probeOnce`, `parseProbeArgs`, `ProbeArgs` from `probe_support.dart`.
- Produces: the executable probe. Plan 2 consumes its CLI surface (`--only`, `--candidate`, and the flags it adds there).

- [ ] **Step 1: Write the runner**

Create `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart`:

````dart
/// Scores which Adaptive Card element types a model actually emits.
///
/// The other probes ask "did the model emit something broken?" — a question a
/// tidy Markdown answer passes while completely failing the user. This one
/// names, per prompt, the element types that would answer it acceptably, and
/// runs every case twice: cold-start, and after two prose turns. The gap
/// between those two runs is the shapes a model loses once a conversation has
/// gone to Markdown, which is the number a prompt fix has to move.
///
/// ```sh
/// fvm dart run tool/model_probes/shape_ab.dart --model qwen2.5-coder:7b
/// fvm dart run tool/model_probes/shape_ab.dart --only carousel,gauge
/// fvm dart run tool/model_probes/shape_ab.dart --candidate /tmp/candidate.txt
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
// Relative: these live outside lib/, beside this file.
import 'probe_support.dart';
import 'shape_cases.dart';

/// Resolves `--only` to a case list, rejecting unknown ids.
///
/// A typo'd id would otherwise silently shrink the run and produce a score
/// against a smaller denominator than the reader assumes.
List<ShapeCase> selectCases(String? only) {
  if (only == null) return shapeCases;
  final wanted = only
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
  final selected = shapeCases.where((c) => wanted.contains(c.id)).toList();
  final unknown = wanted.difference(selected.map((c) => c.id).toSet());
  if (unknown.isNotEmpty) {
    stderr
      ..writeln('Unknown case id(s): ${(unknown.toList()..sort()).join(', ')}')
      ..writeln('Known ids: ${shapeCases.map((c) => c.id).join(', ')}');
    exit(2);
  }
  return selected;
}

/// Runs every case under one condition, returning the ids that passed.
///
/// A case counts as passing only when **every** sample passed, so a score is
/// "cases that held up" rather than "trials that happened to succeed".
Future<Set<String>> runCondition({
  required String label,
  required String systemPrompt,
  required List<ShapeCase> cases,
  required bool withHistory,
  required ProbeArgs args,
  required HttpClient client,
}) async {
  stdout.writeln('\n########## $label ##########');
  final passing = <String>{};
  for (final c in cases) {
    var allPassed = true;
    for (var i = 0; i < args.samples; i++) {
      final outcome = await probeOnce(
        client: client,
        url: args.url,
        model: args.model,
        systemPrompt: systemPrompt,
        userPrompt: c.prompt,
        history: withHistory
            ? const [shapeHistoryUser, shapeHistoryAssistant]
            : const [],
        options: const {'temperature': 0.0},
      );
      final result = judgeShape(c, outcome);
      if (!result.pass) allPassed = false;
      stdout.writeln(
        '${result.pass ? "PASS" : "FAIL"}  ${c.id.padRight(13)} '
        '${result.describe()}',
      );
    }
    if (allPassed) passing.add(c.id);
  }
  stdout.writeln(
    '== ${label.padRight(14)} shapes ${passing.length}/${cases.length} ==',
  );
  return passing;
}

/// Runs both conditions for one system prompt and prints the erosion delta.
Future<void> runPrompt({
  required String label,
  required String systemPrompt,
  required List<ShapeCase> cases,
  required ProbeArgs args,
  required HttpClient client,
}) async {
  stdout.writeln('\n===== $label =====');
  final cold = await runCondition(
    label: 'cold-start',
    systemPrompt: systemPrompt,
    cases: cases,
    withHistory: false,
    args: args,
    client: client,
  );
  final warm = await runCondition(
    label: 'with-history',
    systemPrompt: systemPrompt,
    cases: cases,
    withHistory: true,
    args: args,
    client: client,
  );
  // Derived from the two sets, so the count can never disagree with the list.
  final eroded = (cold.difference(warm).toList())..sort();
  stdout.writeln(
    eroded.isEmpty
        ? '\n== eroded by history: none =='
        : '\n== eroded by history: ${eroded.join(', ')} (${eroded.length}) ==',
  );
}

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption(
      'baseline',
      defaultsTo: 'assets/card_system_prompt.txt',
      help: 'System prompt treated as the shipped one.',
    )
    ..addOption('candidate', help: 'A second system prompt to compare.')
    ..addOption('only', help: 'Comma-separated case ids to run.')
    ..addOption('model')
    ..addOption('url')
    ..addOption('samples')
    ..addFlag('help', abbr: 'h', negatable: false);
  final parsed = parser.parse(argv);
  if (parsed['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }
  final args = parseProbeArgs([
    for (final option in ['model', 'url', 'samples'])
      if (parsed[option] != null) ...['--$option', parsed[option] as String],
  ], defaultSamples: 1);

  final cases = selectCases(parsed['only'] as String?);
  final client = HttpClient()..idleTimeout = const Duration(minutes: 10);
  await runPrompt(
    label: 'baseline',
    systemPrompt: File(parsed['baseline'] as String).readAsStringSync().trim(),
    cases: cases,
    args: args,
    client: client,
  );
  final candidate = parsed['candidate'] as String?;
  if (candidate != null) {
    await runPrompt(
      label: 'candidate',
      systemPrompt: File(candidate).readAsStringSync().trim(),
      cases: cases,
      args: args,
      client: client,
    );
  }
  client.close();
}
````

- [ ] **Step 2: Verify `--help` exits without touching the network**

Run: `cd adaptive_chat_server_dart && fvm dart run tool/model_probes/shape_ab.dart --help`

Expected: usage text listing `--baseline`, `--candidate`, `--only`, `--model`, `--url`, `--samples`; exit 0; no probe output. The early return before `parseProbeArgs` is what makes this work — three sibling scripts shipped with a dead `--help` flag for exactly this reason.

- [ ] **Step 3: Verify unknown `--only` ids are rejected**

Run:

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/shape_ab.dart --only carousel,nosuchcase --url http://127.0.0.1:1
echo "exit: $?"
```

Expected: `Unknown case id(s): nosuchcase`, the known-id list, exit 2 — **before** any connection attempt. If it instead fails with a socket error, the validation is running too late.

- [ ] **Step 4: Verify case selection narrows the run**

Run (Ollama must be running, `qwen2.5-coder:7b` pulled):

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/shape_ab.dart --model qwen2.5-coder:7b --only prose
```

Expected: one case, both conditions, and `shapes 1/1` or `shapes 0/1` per condition. This is the cheapest possible live smoke test — one prompt, two calls.

- [ ] **Step 5: Changelog, gates, commit**

```markdown
- Added: `shape_ab.dart`, a shape-aware probe. It runs all 25 cases
  cold-start and again after two prose turns, then prints the shapes a model
  produces cold and loses with history — the number a prompt fix has to move.
  A case counts as passing only when every sample passed, and the erosion
  line is derived from the two pass-sets so its count can never disagree with
  its own list. `--only` rejects unknown case ids rather than silently
  shrinking the denominator; `--baseline`/`--candidate` A/B two prompts.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/shape_ab.dart \
        adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add the shape-aware model probe runner"
```

---

### Task 5: Document the probe

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/README.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: the finished probe from Task 4.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Add the script-table row**

In `adaptive_chat_server_dart/tool/model_probes/README.md`, add to the script table, directly beneath the `choiceset_ab.dart` row:

```markdown
| `shape_ab.dart` | Which element types does this model actually emit, cold vs with history? |
```

- [ ] **Step 2: Add the usage note**

Add below the existing `choiceset_ab.dart` note in the same README:

```markdown
`shape_ab.dart` is the shape-aware probe: 25 cases, each naming the element
types that would answer it acceptably (a set, not one type — "summarize these
specs" is defensibly a `FactSet` or a `Table`). It runs every case twice,
cold-start and after two prose turns, and prints which shapes were lost
between the two. Use `--only carousel,gauge` to re-check one shape without
paying for the other twenty-three, and `--candidate <file>` to A/B a prompt
change per shape.

Its failure labels distinguish four ways a card reply can be wrong:
`wrong-shape` (a card, but not an accepted type — the line names what came
back), `no-input` (a card with content but no `Input.*` where the prompt
asked the user for a value), `prose` (no card at all), and `broken` (invalid
JSON, or prose wrapping a card).
```

- [ ] **Step 3: Add the "What these found" bullet**

The README's "What these found" section holds probe-side findings. Add:

```markdown
- **Judging a reply as "renders or not" hides most of the palette.** Before
  `shape_ab.dart`, exactly one of the 24 element types the card prompt
  advertises was ever asserted (`Input.ChoiceSet`, by `choiceset_ab.dart`).
  The everyday set's `table` case passed on a `TextBlock`; its `chart` case
  passed on plain Markdown.
```

- [ ] **Step 4: Changelog, gates, commit**

```markdown
- Added: `tool/model_probes/README.md` documents `shape_ab.dart`, its four
  card-failure labels, and the finding that motivated it — that judging
  replies only as "renders or not" left 23 of 24 advertised element types
  unverified.
```

```bash
cd adaptive_chat_server_dart
fvm dart analyze && fvm dart test && fvm dart format --output=none --set-exit-if-changed .
cd .. && npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/tool/model_probes/README.md \
        adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): document the shape-aware probe"
```

---

### Task 6: Baseline `qwen2.5-coder:7b` and record it

The first real measurement. Plan 2 cannot be interpreted without it, because a shape a model never produces cold-start is not a warm-start problem.

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: the probe from Task 4.
- Produces: the baseline cold-start and with-history pass-sets for
  `qwen2.5-coder:7b` — Plan 2 Stage 1 compares against these.

- [ ] **Step 1: Run the full baseline**

Only `qwen2.5-coder:7b` is resident for this task. Confirm nothing else is loaded first:

```bash
curl -s http://127.0.0.1:11434/api/ps
```

Then:

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/shape_ab.dart --model qwen2.5-coder:7b --samples 1 2>&1 | tee /tmp/shape-baseline-qwen.txt
```

Expected: two condition blocks and an erosion line. 25 cases × 2 conditions = 50 calls; roughly 5-10 minutes on this model. Keep the full output — Step 3 quotes exact per-case labels from it.

- [ ] **Step 2: Unload the model**

```bash
curl -s http://127.0.0.1:11434/api/generate -d '{"model":"qwen2.5-coder:7b","keep_alive":0}' > /dev/null
curl -s http://127.0.0.1:11434/api/ps
```

Expected: `{"models":[]}`.

- [ ] **Step 3: Record the result in `ModelBehavior.md`**

Two edits.

**(a)** Add a `shapes` figure to `qwen2.5-coder:7b`'s row in the main model table, keeping its existing `With history` choice-set cell intact. The `With history` cell currently reads `⚠️ 3/6 choice-set — post escape-hatch fix (see §4)`; append the shape figure to it in the same terse style, e.g. `⚠️ 3/6 choice-set · shapes 11/25 (see §4)` — substitute the number you actually measured.

**(b)** Add a subsection to `### 4. Multi-turn set — history replay` recording the full result. Write it with the real numbers from Step 1, following the shape below. Every count must match its own itemized list — this file has had three separate review findings where a summary number disagreed with the detail beside it, so read back what you write before committing:

```markdown
#### Shape coverage — `qwen2.5-coder:7b`, 2026-08-17

First run of `shape_ab.dart` (25 cases, `t=0`, `--samples 1`, current shipped
prompt). Cold-start **N/25**, with-history **M/25**.

Shapes lost to history (produced cold, prose or wrong shape with two prior
prose turns): `<ids>`.

Shapes this model never produced under either condition: `<ids>` — these are
capability or palette gaps, not drift, and no anti-drift wording will move
them.

Notable per-case detail: `<the labels worth keeping — e.g. which cases failed
no-input vs wrong-shape, and what collectElementTypes reported instead>`.
```

If a shape failed under **both** conditions, say so explicitly in that second paragraph. That distinction is the whole reason both conditions are run, and Plan 2's screening subset depends on it.

- [ ] **Step 4: Verify the table survived the edit**

```bash
cd adaptive_chat_server_dart
awk -F'|' '/^\| / && / GB / && !/---/ && !/^\| Model/ {print NF-2}' ModelBehavior.md | sort -u
```

Expected: a single line reading `6` — every model row still has six columns.

- [ ] **Step 5: Changelog, format, commit**

```markdown
- Added: first `shape_ab.dart` baseline — `qwen2.5-coder:7b`, 25 cases,
  `t=0`, `--samples 1`, current shipped prompt: cold-start N/25,
  with-history M/25. Recorded in `ModelBehavior.md` alongside which shapes
  were lost to history and which the model never produced under either
  condition — the second group being capability gaps rather than drift, which
  no anti-drift wording will move.
```

Replace `N` and `M` with the measured figures.

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/.claude/worktrees/normalize-qwen-samples
npm run format:md:chat && npm run check:md:chat
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): baseline shape coverage for qwen2.5-coder:7b"
```

---

## Verification (full suite)

Run from the package directory after the final task:

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

Then confirm the refactor in Task 1 did not disturb the probe it touched, one model resident at a time:

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/choiceset_ab.dart --model qwen2.5-coder:7b --samples 1
curl -s http://127.0.0.1:11434/api/generate -d '{"model":"qwen2.5-coder:7b","keep_alive":0}' > /dev/null
```

Expected: `choice-set 3/6`, matching the figure recorded in `ModelBehavior.md`
for this model. A different number is not automatically a regression — the
same normalization run that produced 3/6 noted it reproduced prompt-for-prompt
— but it must be investigated and explained before this plan is called
complete, not waved through as variance.

Invoke **`superpowers:verification-before-completion`** and paste the command output — exit codes and pass/fail counts — before claiming this plan is complete.

## Out of scope

Recorded so the next person does not assume they were missed:

- **Sweeping all thirteen models.** Task 6 baselines the server default only. A wider sweep is roughly an hour per 30B model and is a separate decision, taken after seeing what the default's numbers look like.
- **Asserting `style` / `isMultiSelect` on `Input.ChoiceSet`.** Radios, checkboxes, and dropdowns are all `Input.ChoiceSet`; this probe checks the type, not the variant. Variant-level checking is its own exercise.
- **`Icon` and `Image` cases.** `Icon` is decorative, so absence is not failure. `Image` cannot be elicited honestly because the prompt forbids inventing URLs.
- **Retiring `choiceset_ab.dart`.** It stays as the reproducer for thirteen recorded scores.
- **Fixing any shape this probe finds broken.** That is Plan 2's subject.
