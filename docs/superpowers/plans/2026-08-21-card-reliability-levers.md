# Card Reliability Levers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the three nominated levers from the [card reliability levers spec](../specs/2026-08-21-card-reliability-levers-design.md) — reconcile the card schema with the renderable registry (H), detect unrecognized element types that currently render as invisible blanks (B), and measure whether Ollama tool calling is usable on the launch-set models (A).

**Architecture:** H widens `assets/card_schema.json` from a 24-type enum to the full renderable vocabulary, split into `Element` (top-level body items) and `ChildElement` (adds structural children). B adds a pure `lib/src/element_types.dart` that reads that vocabulary and walks a parsed card body for types outside it, wired into `OllamaResponder` as a warning only. A adds a `tool_call_probe.dart` capability canary plus the `card_tool_prompt.txt` asset it needs, then records the result.

**Tech Stack:** Dart 3 (server, no Flutter), `package:test`, `package:http` + `MockClient`, `package:logging`, Ollama `/api/chat`, FVM-pinned SDK.

## Global Constraints

- **Every `dart` and `flutter` command is prefixed with `fvm`.** The repo pins its SDK via FVM and bare aliases may point elsewhere.
- **Run server commands from `adaptive_chat_server_dart/`.** Its tests use relative asset paths (`assets/…`, `README.md`) and fail from the repo root.
- **Analysis:** `very_good_analysis`, plus `prefer_single_quotes` and `always_use_package_imports`. Files under `lib/` use `package:` imports; files under `tool/model_probes/` use relative imports, because they sit outside `lib/` and have no `package:` URI.
- **Public API needs `///` docs** explaining why the API exists and how callers use it — not a restatement of the algorithm.
- **Every task updates `adaptive_chat_server_dart/CHANGELOG.md`** under `## [Unreleased]`, in the existing style: `- Category: **bold one-line summary.** Detail.`
- **Formatting gates, run before every commit:**
  - `fvm dart format adaptive_chat_server_dart/`
  - `npm run format:md:chat` — note this is the **`:chat`** variant. `npm run check:md` does **not** cover `adaptive_chat_server_dart/`, so the check most people run is blind to changes here.
- **Never commit or push without explicit user confirmation**, except that a subagent executing an approved task in this plan may commit to the current feature branch. Pushing, merging, and anything touching `main` still require confirmation.
- **Ollama: one model resident at a time.** Probe models in a serial outer loop. Never fan out parallel probes or dispatch one subagent per model — they contend for a single model server and thrash it. Several candidates are 18–24 GB and cannot be co-resident.

**Branch:** work continues on `docs/card-reliability-levers-spec`, which already carries the spec commit.

**Sequencing:** Tasks 1–2 (H) must land before Tasks 3–4 (B), because H produces the vocabulary B reads. Tasks 5–6 (A) are independent of all of them and may run in parallel or first.

---

## File Structure

| File                                     | Responsibility                                                            | Task |
| ---------------------------------------- | ------------------------------------------------------------------------- | ---- |
| `assets/card_schema.json`                | The renderable element vocabulary, and the `--json-format schema` grammar | 1, 2 |
| `test/card_schema_test.dart`             | Pins the schema against the two registries so they cannot drift apart     | 1, 2 |
| `lib/src/element_types.dart`             | **New.** Loads the vocabulary; finds types in a card body outside it      | 3    |
| `test/element_types_test.dart`           | **New.** Covers the loader and the recursive walker                       | 3    |
| `lib/src/ollama_responder.dart`          | Wires the check in as a warning on the reply path                         | 4    |
| `test/ollama_responder_test.dart`        | Covers the warning firing and staying silent                              | 4    |
| `assets/card_tool_prompt.txt`            | **New.** System prompt for the tool channel                               | 5    |
| `tool/model_probes/tool_call_probe.dart` | **New.** Tool-calling capability canary                                   | 5    |
| `test/tool_call_probe_test.dart`         | **New.** Covers the pure verdict classifier                               | 5    |
| `ModelBehavior.md`                       | Records the measurement                                                   | 6    |

`card_detect.dart` is deliberately **not** modified. It is pure (`dart:convert` only) and stays that way; the new vocabulary check does file IO, so it lives in its own file.

---

### Task 1: Widen the schema `Element` enum to every renderable top-level type

The schema enumerates 24 types. The client renders 36 — the 30 element cases in the core registry plus 6 `Chart.*` types. Three of the 30 are not top-level body items (`AdaptiveCard` is the wrapper with its own `$defs/CardObject`; `CarouselPage` and `TabPage` are child-only), so `Element` should hold **33**.

The test reads both registries **as source text**, so it fails when either gains a case. That is stronger than the hand-maintained list the spec proposed, and needs no generator.

**Files:**

- Modify: `adaptive_chat_server_dart/assets/card_schema.json`
- Modify: `adaptive_chat_server_dart/test/card_schema_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: `$defs.Element.properties.type.enum` — a 33-entry `List<String>` read by Task 2's test and, transitively, by Task 3's `loadKnownElementTypes`.

- [ ] **Step 1: Write the failing test**

Append these helpers and this group to `test/card_schema_test.dart`. `_schemaElementTypes()` already exists at the top of that file — reuse it, do not redefine it.

```dart
/// Element types the core library can render, read from the registry source
/// rather than from a copy kept here, so this test fails when the registry
/// gains or loses a case.
Set<String> _coreRegistryElementTypes() {
  final source = File(
    '../packages/flutter_adaptive_cards_fs/lib/src/registry.dart',
  ).readAsStringSync();
  return RegExp(r"case '([A-Za-z][A-Za-z.]*)':")
      .allMatches(source)
      .map((m) => m.group(1)!)
      // The same switch carries action types; only elements belong here.
      .where((t) => !t.startsWith('Action.'))
      .toSet();
}

/// `Chart.*` types, which live in the optional charts package and are
/// renderable only when a host registered it.
Set<String> _chartRegistryElementTypes() {
  final source = File(
    '../packages/flutter_adaptive_charts_fs/lib/src/card_chart_registry.dart',
  ).readAsStringSync();
  return RegExp(r'Chart\.[A-Za-z]+')
      .allMatches(source)
      .map((m) => m.group(0)!)
      .toSet();
}

/// Registered types that are never a top-level body item.
///
/// `CarouselPage` and `TabPage` are legal only inside their parent's array.
/// `AdaptiveCard` is the wrapper and has its own `$defs/CardObject`; putting
/// it in `Element` would additionally make a bare card a legal body item and
/// let it match the wrong `oneOf` branch.
const _notTopLevel = {'AdaptiveCard', 'CarouselPage', 'TabPage'};

Set<String> _renderableTopLevelTypes() =>
    _coreRegistryElementTypes()
      ..addAll(_chartRegistryElementTypes())
      ..removeAll(_notTopLevel);
```

```dart
  group('the schema mirrors the renderable registry', () {
    test('the core registry contributes 30 element types', () {
      // Guards the regex itself: a change to registry.dart's switch style
      // would otherwise silently yield an empty set and pass everything.
      expect(_coreRegistryElementTypes(), hasLength(30));
    });

    test('the charts package contributes 6 chart types', () {
      expect(_chartRegistryElementTypes(), hasLength(6));
    });

    test('the Element enum is exactly the renderable top-level set', () {
      expect(_schemaElementTypes(), _renderableTopLevelTypes());
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd adaptive_chat_server_dart
fvm dart test test/card_schema_test.dart -n 'the schema mirrors the renderable registry'
```

Expected: the two `hasLength` tests PASS; `the Element enum is exactly the renderable top-level set` FAILS, reporting the 9 types present in the registry set and absent from the schema — `Media`, `Container`, `RichTextBlock`, `ActionSet`, `ImageSet`, `Input.Rating`, `CompoundButton`, `Accordion`, `TabSet`.

- [ ] **Step 3: Add the 9 missing types to the schema**

In `assets/card_schema.json`, replace the `$defs.Element.properties.type.enum` array with this exact 33-entry list:

```json
          "enum": [
            "TextBlock",
            "RichTextBlock",
            "FactSet",
            "Badge",
            "Carousel",
            "Table",
            "Container",
            "ColumnSet",
            "ActionSet",
            "ImageSet",
            "Image",
            "Media",
            "Accordion",
            "TabSet",
            "CompoundButton",
            "Input.Date",
            "Input.ChoiceSet",
            "Input.Text",
            "Input.Number",
            "Input.Time",
            "Input.Toggle",
            "Input.Rating",
            "Rating",
            "Icon",
            "ProgressBar",
            "ProgressRing",
            "CodeBlock",
            "Chart.Pie",
            "Chart.Donut",
            "Chart.VerticalBar",
            "Chart.HorizontalBar",
            "Chart.Line",
            "Chart.Gauge"
          ]
```

- [ ] **Step 4: Run the full schema test file to verify it passes**

```bash
cd adaptive_chat_server_dart
fvm dart test test/card_schema_test.dart
```

Expected: PASS, all groups. The pre-existing `every type the prompt advertises is allowed by the schema enum` test still passes — it is a subset check, and the enum only grew.

- [ ] **Step 5: Add the changelog entry**

Insert as the first bullet under `## [Unreleased]` in `adaptive_chat_server_dart/CHANGELOG.md`:

```markdown
- Changed: **`card_schema.json` now mirrors the renderable registry.** The
  `Element` enum grew from 24 to 33 types, adding `Media`, `Container`,
  `RichTextBlock`, `ActionSet`, `ImageSet`, `Input.Rating`, `CompoundButton`,
  `Accordion`, and `TabSet`. `card_schema_test.dart` now reads
  `registry.dart` and the charts registry as source text, so the schema and
  the renderable vocabulary can no longer drift apart silently. Note this
  **loosens** `--json-format schema`: on models that honor `format`, the
  grammar now admits 33 types where it admitted 24. The system prompt is
  unchanged, so what the model is asked to produce is unchanged.
```

- [ ] **Step 6: Format and commit**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart format adaptive_chat_server_dart/
npm run format:md:chat
git add adaptive_chat_server_dart/assets/card_schema.json adaptive_chat_server_dart/test/card_schema_test.dart adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): mirror the renderable registry in card_schema.json"
```

---

### Task 2: Add `$defs/ChildElement` for structural child types

`Column`, `TableRow`, and `TableCell` appear throughout the card system prompt's examples but are **not** registry switch cases — their parents' widgets handle them directly. Together with `CarouselPage` and `TabPage` they have no home in `Element`, and Task 3's walker needs them or it will flag every nested card as unknown.

**This definition is a vocabulary list, not a grammar constraint.** `Element` sets `additionalProperties: true` and describes no nested arrays, so nothing in the schema references `ChildElement` and `--json-format schema` behavior does not change. Its consumer is Task 3.

**Files:**

- Modify: `adaptive_chat_server_dart/assets/card_schema.json`
- Modify: `adaptive_chat_server_dart/test/card_schema_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `_renderableTopLevelTypes()` and `_notTopLevel` from Task 1's test file; `$defs.Element` from Task 1.
- Produces: `$defs.ChildElement.properties.type.enum` — a 38-entry `List<String>`. Task 3's `loadKnownElementTypes` reads **this** definition, not `Element`.

- [ ] **Step 1: Write the failing test**

Append to `test/card_schema_test.dart`:

```dart
/// The `type` enum covering every position, including nesting-only children.
Set<String> _schemaChildElementTypes() {
  final schema =
      jsonDecode(File('assets/card_schema.json').readAsStringSync())
          as Map<String, dynamic>;
  final child =
      (schema[r'$defs'] as Map<String, dynamic>)['ChildElement']
          as Map<String, dynamic>;
  final type =
      (child['properties'] as Map<String, dynamic>)['type']
          as Map<String, dynamic>;
  return (type['enum'] as List).cast<String>().toSet();
}

/// Types the prompt's examples nest inside a parent but which no registry
/// switch declares, because their parent widget builds them directly.
const _structuralChildTypes = {'Column', 'TableRow', 'TableCell'};
```

```dart
  group('ChildElement covers every legal nested position', () {
    test('it is the top-level set plus child-only and structural types', () {
      expect(
        _schemaChildElementTypes(),
        _renderableTopLevelTypes()
          ..addAll({'CarouselPage', 'TabPage'})
          ..addAll(_structuralChildTypes),
      );
    });

    test('it is a strict superset of Element', () {
      expect(_schemaChildElementTypes(), containsAll(_schemaElementTypes()));
      expect(
        _schemaChildElementTypes().length,
        greaterThan(_schemaElementTypes().length),
      );
    });

    test('it excludes the AdaptiveCard wrapper', () {
      // A nested card belongs to Action.ShowCard, which this palette does not
      // offer; CardObject remains the only place the wrapper is legal.
      expect(_schemaChildElementTypes(), isNot(contains('AdaptiveCard')));
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd adaptive_chat_server_dart
fvm dart test test/card_schema_test.dart -n 'ChildElement covers every legal nested position'
```

Expected: FAIL with a `_TypeError` or null-cast error, because `$defs.ChildElement` does not exist yet.

- [ ] **Step 3: Add the definition to the schema**

In `assets/card_schema.json`, insert this object into `$defs` immediately after the `Element` definition and before `CardObject`:

```json
    "ChildElement": {
      "type": "object",
      "required": ["type"],
      "additionalProperties": true,
      "properties": {
        "type": {
          "type": "string",
          "enum": [
            "TextBlock",
            "RichTextBlock",
            "FactSet",
            "Badge",
            "Carousel",
            "CarouselPage",
            "Table",
            "TableRow",
            "TableCell",
            "Container",
            "ColumnSet",
            "Column",
            "ActionSet",
            "ImageSet",
            "Image",
            "Media",
            "Accordion",
            "TabSet",
            "TabPage",
            "CompoundButton",
            "Input.Date",
            "Input.ChoiceSet",
            "Input.Text",
            "Input.Number",
            "Input.Time",
            "Input.Toggle",
            "Input.Rating",
            "Rating",
            "Icon",
            "ProgressBar",
            "ProgressRing",
            "CodeBlock",
            "Chart.Pie",
            "Chart.Donut",
            "Chart.VerticalBar",
            "Chart.HorizontalBar",
            "Chart.Line",
            "Chart.Gauge"
          ]
        }
      }
    },
```

- [ ] **Step 4: Run the full schema test file to verify it passes**

```bash
cd adaptive_chat_server_dart
fvm dart test test/card_schema_test.dart
```

Expected: PASS, all groups.

- [ ] **Step 5: Add the changelog entry**

Insert directly below the Task 1 bullet:

```markdown
- Added: **`$defs/ChildElement` in `card_schema.json`.** A 38-type vocabulary
  covering every legal position — the 33 top-level types plus `CarouselPage`,
  `TabPage`, `Column`, `TableRow`, and `TableCell`, which the prompt nests but
  no registry switch declares. Nothing in the schema references it and
  `--json-format schema` is unaffected; it exists so a validator can recognize
  nested elements.
```

- [ ] **Step 6: Format and commit**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart format adaptive_chat_server_dart/
npm run format:md:chat
git add adaptive_chat_server_dart/assets/card_schema.json adaptive_chat_server_dart/test/card_schema_test.dart adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add ChildElement vocabulary to card_schema.json"
```

---

### Task 3: Detect element types outside the renderable vocabulary

A misspelled `type` is valid JSON, passes `tryParseCardBody`, and renders as an invisible blank. Every probe scores it as a passing card. This task builds the pure detection; Task 4 wires it in.

**Files:**

- Create: `adaptive_chat_server_dart/lib/src/element_types.dart`
- Create: `adaptive_chat_server_dart/test/element_types_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `$defs.ChildElement.properties.type.enum` from Task 2.
- Produces:

  - `Set<String> loadKnownElementTypes(String path)`
  - `Set<String> unknownElementTypes(List<Map<String, dynamic>> body, Set<String> known)`

- [ ] **Step 1: Write the failing test**

Create `test/element_types_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/element_types.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String schemaPath;

  /// Writes a schema whose ChildElement enum is exactly [types].
  void writeSchema(List<String> types) {
    File(schemaPath).writeAsStringSync(
      jsonEncode({
        r'$defs': {
          'ChildElement': {
            'type': 'object',
            'properties': {
              'type': {'type': 'string', 'enum': types},
            },
          },
        },
      }),
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('element_types_test');
    schemaPath = '${tempDir.path}/card_schema.json';
    writeSchema(['TextBlock', 'Badge', 'ColumnSet', 'Column', 'Carousel']);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('loadKnownElementTypes', () {
    test('reads the ChildElement enum', () {
      expect(loadKnownElementTypes(schemaPath), {
        'TextBlock',
        'Badge',
        'ColumnSet',
        'Column',
        'Carousel',
      });
    });

    test('returns an empty set when the file is missing', () {
      expect(loadKnownElementTypes('${tempDir.path}/nope.json'), isEmpty);
    });

    test('returns an empty set when the JSON is malformed', () {
      File(schemaPath).writeAsStringSync('{not json');
      expect(loadKnownElementTypes(schemaPath), isEmpty);
    });

    test('returns an empty set when ChildElement is absent', () {
      File(schemaPath).writeAsStringSync(jsonEncode({r'$defs': {}}));
      expect(loadKnownElementTypes(schemaPath), isEmpty);
    });
  });

  group('unknownElementTypes', () {
    final known = {'TextBlock', 'Badge', 'ColumnSet', 'Column', 'Carousel'};

    test('a body of known types yields nothing', () {
      final body = [
        {'type': 'TextBlock', 'text': 'hi'},
        {'type': 'Badge', 'text': 'New'},
      ];
      expect(unknownElementTypes(body, known), isEmpty);
    });

    test('a misspelled top-level type is flagged', () {
      // The exact failure this exists for: valid JSON, renders as nothing.
      final body = [
        {'type': 'Textblock', 'text': 'hi'},
      ];
      expect(unknownElementTypes(body, known), {'Textblock'});
    });

    test('a misspelled type nested inside a container is flagged', () {
      final body = [
        {
          'type': 'ColumnSet',
          'columns': [
            {
              'type': 'Column',
              'items': [
                {'type': 'Input.RadioButtons', 'id': 'x'},
              ],
            },
          ],
        },
      ];
      expect(unknownElementTypes(body, known), {'Input.RadioButtons'});
    });

    test('every unknown type is reported, not just the first', () {
      final body = [
        {'type': 'Textblock', 'text': 'hi'},
        {'type': 'BadgeX', 'text': 'New'},
      ];
      expect(unknownElementTypes(body, known), {'Textblock', 'BadgeX'});
    });

    test('an empty known set disables the check', () {
      // A failed schema load must not flag every element in every reply.
      final body = [
        {'type': 'Textblock', 'text': 'hi'},
      ];
      expect(unknownElementTypes(body, const <String>{}), isEmpty);
    });

    test('non-type string values are not mistaken for types', () {
      final body = [
        {'type': 'TextBlock', 'text': 'Textblock is misspelled', 'wrap': true},
      ];
      expect(unknownElementTypes(body, known), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd adaptive_chat_server_dart
fvm dart test test/element_types_test.dart
```

Expected: FAIL at compile time — `Error: Couldn't resolve the package 'adaptive_chat_server_dart' … element_types.dart` or `Method not found: 'loadKnownElementTypes'`.

- [ ] **Step 3: Write the implementation**

Create `lib/src/element_types.dart`:

```dart
/// The element-type vocabulary the client can render, and the check for a
/// reply that strays outside it.
///
/// An invented or misspelled `type` is still valid JSON, so it passes card
/// detection and then renders as an empty blank rather than an error. That
/// makes it the one failure users can see and no probe can score, because
/// every probe judges a reply by whether it parses as a card. Reading the
/// vocabulary from the shipped schema — rather than a list kept here — means
/// the check tracks what the client actually renders.
///
/// Kept out of `card_detect.dart` on purpose: that library is pure and
/// parses strings, while this one reads a file.
library;

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

final _log = Logger('adaptive_chat_server_dart.element_types');

/// Reads the renderable element vocabulary from the card schema at [path].
///
/// Returns the `$defs/ChildElement` enum, which covers every legal position
/// including nesting-only types such as `Column` and `TableRow` — a walker
/// over a whole card body needs all of them, not just the top-level set.
///
/// Returns an empty set when the schema is missing, malformed, or shaped
/// unexpectedly, after logging why. Callers treat an empty set as "check
/// disabled", so a broken tuning asset degrades the check instead of failing
/// every request — the same trade `loadSeedCardMessages` makes.
Set<String> loadKnownElementTypes(String path) {
  final String raw;
  try {
    raw = File(path).readAsStringSync();
  } on IOException catch (e) {
    _log.warning(
      'Card schema unreadable ($e) at $path — unknown-element-type '
      'checking is disabled for this process.',
    );
    return const {};
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    _log.warning(
      'Card schema is not valid JSON ($e) at $path — unknown-element-type '
      'checking is disabled for this process.',
    );
    return const {};
  }

  if (decoded is! Map<String, dynamic>) return _disabled(path);
  final defs = decoded[r'$defs'];
  if (defs is! Map<String, dynamic>) return _disabled(path);
  final child = defs['ChildElement'];
  if (child is! Map<String, dynamic>) return _disabled(path);
  final properties = child['properties'];
  if (properties is! Map<String, dynamic>) return _disabled(path);
  final type = properties['type'];
  if (type is! Map<String, dynamic>) return _disabled(path);
  final values = type['enum'];
  if (values is! List) return _disabled(path);
  return values.whereType<String>().toSet();
}

Set<String> _disabled(String path) {
  _log.warning(
    'Card schema at $path has no usable '
    r'$defs/ChildElement/properties/type/enum — unknown-element-type '
    'checking is disabled for this process.',
  );
  return const {};
}

/// Every `type` value in [body], at any depth, that is absent from [known].
///
/// Walks nested arrays and objects, so a bad type inside a `Column`, a
/// `TableCell`, or a `Carousel` page is caught — that is where deep nesting
/// puts most real occurrences.
///
/// Returns an empty set when [known] is empty, so a failed vocabulary load
/// disables the check rather than flagging every element of every reply.
Set<String> unknownElementTypes(
  List<Map<String, dynamic>> body,
  Set<String> known,
) {
  if (known.isEmpty) return const {};
  final unknown = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      final type = node['type'];
      // Only a `type` key names an element; an ordinary string value that
      // happens to look like a type name must not be flagged.
      if (type is String && type.isNotEmpty && !known.contains(type)) {
        unknown.add(type);
      }
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  body.forEach(walk);
  return unknown;
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd adaptive_chat_server_dart
fvm dart test test/element_types_test.dart
```

Expected: PASS, 11 tests.

- [ ] **Step 5: Analyze**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart analyze adaptive_chat_server_dart/
```

Expected: `No issues found!`

- [ ] **Step 6: Add the changelog entry and commit**

```markdown
- Added: **unknown-element-type detection (`lib/src/element_types.dart`).**
  `loadKnownElementTypes` reads the schema's `ChildElement` vocabulary and
  `unknownElementTypes` walks a parsed card body for anything outside it,
  at any nesting depth. A misspelled type such as `Textblock` is valid JSON
  that renders as an invisible blank, so it is the one failure a user sees
  and no probe scores. A missing or malformed schema disables the check
  rather than failing requests.
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart format adaptive_chat_server_dart/
npm run format:md:chat
git add adaptive_chat_server_dart/lib/src/element_types.dart adaptive_chat_server_dart/test/element_types_test.dart adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): detect element types outside the renderable vocabulary"
```

---

### Task 4: Warn when a rendered card carries an unrecognized type

Wire Task 3's check into the reply path as a **warning only** — the card still renders. The fire rate in real use is the evidence for whether rejecting is worth the risk of suppressing a mostly-good card over one bad nested element.

**Files:**

- Modify: `adaptive_chat_server_dart/lib/src/ollama_responder.dart`
- Modify: `adaptive_chat_server_dart/test/ollama_responder_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `loadKnownElementTypes(String)` and `unknownElementTypes(List<Map<String, dynamic>>, Set<String>)` from Task 3.
- Produces: no new public API. `OllamaResponder.describe()` gains a `knownElementTypes` int key.

- [ ] **Step 1: Write the failing test**

Add to `test/ollama_responder_test.dart`. The existing `setUp` writes a schema of `{$defs: {}, oneOf: []}`, which yields an empty vocabulary and therefore a disabled check — that is what keeps every pre-existing test unchanged. This group writes its own schema.

```dart
  group('unrecognized element types', () {
    /// Replaces the temp schema with one whose ChildElement enum is [types].
    void writeVocabulary(List<String> types) {
      File(schemaPath).writeAsStringSync(
        jsonEncode({
          r'$defs': {
            'ChildElement': {
              'type': 'object',
              'properties': {
                'type': {'type': 'string', 'enum': types},
              },
            },
          },
          'oneOf': <dynamic>[],
        }),
      );
    }

    Future<List<LogRecord>> replyCapturingLogs(OllamaResponder r) async {
      final records = <LogRecord>[];
      Logger.root.level = Level.ALL;
      final sub = Logger.root.onRecord.listen(records.add);
      await r.reply('hi', const []);
      await sub.cancel();
      return records;
    }

    test('a misspelled type is warned about and still rendered', () async {
      writeVocabulary(['TextBlock', 'Badge']);
      final client = MockClient(
        (request) async =>
            okResponse('{"type":"Textblock","text":"hi","wrap":true}'),
      );
      final logs = await replyCapturingLogs(makeResponder(client: client));
      final match = logs.where(
        (r) => r.message.contains('unrecognized element type'),
      );
      expect(match, isNotEmpty);
      expect(match.first.message, contains('Textblock'));
    });

    test('the card is still returned, not downgraded to text', () async {
      writeVocabulary(['TextBlock', 'Badge']);
      final client = MockClient(
        (request) async =>
            okResponse('{"type":"Textblock","text":"hi","wrap":true}'),
      );
      final reply = await makeResponder(client: client).reply('hi', const []);
      expect(reply.cardBody, isNotNull);
      expect(reply.cardBody!.single['type'], 'Textblock');
    });

    test('a card of known types produces no warning', () async {
      writeVocabulary(['TextBlock', 'Badge']);
      final client = MockClient(
        (request) async =>
            okResponse('{"type":"TextBlock","text":"hi","wrap":true}'),
      );
      final logs = await replyCapturingLogs(makeResponder(client: client));
      expect(
        logs.where((r) => r.message.contains('unrecognized element type')),
        isEmpty,
      );
    });

    test('an empty vocabulary disables the warning', () async {
      // The default setUp schema has no ChildElement, so the check is off.
      final client = MockClient(
        (request) async =>
            okResponse('{"type":"Textblock","text":"hi","wrap":true}'),
      );
      final logs = await replyCapturingLogs(makeResponder(client: client));
      expect(
        logs.where((r) => r.message.contains('unrecognized element type')),
        isEmpty,
      );
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd adaptive_chat_server_dart
fvm dart test test/ollama_responder_test.dart -n 'unrecognized element types'
```

Expected: the two "no warning" tests PASS vacuously; `a misspelled type is warned about and still rendered` FAILS with `Expected: not empty / Actual: []`.

- [ ] **Step 3: Write the implementation**

In `lib/src/ollama_responder.dart`:

Add the import beside the existing `card_detect.dart` one:

```dart
import 'package:adaptive_chat_server_dart/src/element_types.dart';
```

Add the field beside `_cardSchema`:

```dart
  /// Vocabulary for the unknown-type warning; empty means the check is off.
  ///
  /// Loaded unconditionally, unlike `_cardSchema`, which is read only under
  /// `--json-format schema` — the warning has to work in the default
  /// `format=none` configuration, which is the one that actually ships.
  Set<String> _knownElementTypes = const {};
```

In the constructor body, **before** the existing `if (_jsonFormat == 'schema')` block:

```dart
    _knownElementTypes = loadKnownElementTypes(cardSchemaPath);
```

In `describe()`, add to the `config` map after the `jsonFormat` entry:

```dart
      // 0 means the vocabulary failed to load and the unknown-type warning
      // is inert — surfaced because a silently disabled check looks healthy.
      'knownElementTypes': _knownElementTypes.length,
```

In `reply()`, replace the `} else if (cardBody == null) {` branch and its body with:

```dart
    } else if (cardBody == null) {
      final reason = cardParseFailureReason(content);
      if (reason != null) {
        _log.warning(
          'Model reply looked like an Adaptive Card but was not '
          'usable (model=$_model, ${content.length} chars) — rendered as '
          'text instead. Reason: $reason',
        );
      }
    } else {
      final unknown = unknownElementTypes(cardBody, _knownElementTypes);
      if (unknown.isNotEmpty) {
        // Warned, not rejected: an unrecognized type renders as a blank, but
        // suppressing the whole card over one bad nested element may be
        // worse. The fire rate observed here is the evidence for whether to
        // promote this to a rejection.
        _log.warning(
          'Model reply contains unrecognized element type(s) '
          '(model=$_model): ${unknown.join(", ")} — these render as empty '
          'blanks. Card rendered anyway.',
        );
      }
    }
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd adaptive_chat_server_dart
fvm dart test test/ollama_responder_test.dart
```

Expected: PASS, including every pre-existing test in the file.

- [ ] **Step 5: Run the whole server suite and analyze**

```bash
cd adaptive_chat_server_dart
fvm dart test
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart analyze adaptive_chat_server_dart/
```

Expected: all tests pass; `No issues found!`

- [ ] **Step 6: Add the changelog entry and commit**

```markdown
- Added: **`OllamaResponder` warns when a rendered card carries an
  unrecognized element type.** Warning only — the card still renders, because
  suppressing it over one bad nested element may be worse than an invisible
  blank, and the observed fire rate is the evidence for whether to promote
  this to a rejection. `/status` reports `knownElementTypes`, which is `0`
  when the vocabulary failed to load and the check is inert.
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart format adaptive_chat_server_dart/
npm run format:md:chat
git add adaptive_chat_server_dart/lib/src/ollama_responder.dart adaptive_chat_server_dart/test/ollama_responder_test.dart adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): warn on unrecognized element types in card replies"
```

---

### Task 5: Build the tool-calling capability canary

Ollama accepts `tools` for every model but honors it only where the chat template supports it, saying nothing when it does not — the same trap `format` set. This probe answers whether tool calling is usable at all, before anyone builds on it.

`probeOnce` in `probe_support.dart` cannot be reused: it hardcodes the request body and does not send `tools` or read `message.tool_calls`. This probe issues its own request, exactly as `json_format_probe.dart` does with `_rawReply`.

**Files:**

- Create: `adaptive_chat_server_dart/assets/card_tool_prompt.txt`
- Create: `adaptive_chat_server_dart/tool/model_probes/tool_call_probe.dart`
- Create: `adaptive_chat_server_dart/test/tool_call_probe_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `parseProbeArgs`, `probeAssetsDir`, `judgeReply` from `probe_support.dart`; `ProbeCall`, `writeProbeRun`, `passSummary` from `probe_results.dart`; `tryParseCardBody` from `package:adaptive_chat_server_dart/src/card_detect.dart`.
- Produces: `enum ToolVerdict { supported, unsupported, supportedButDeclines, overCalls }` and `ToolVerdict classifyToolSupport({required bool calledTrivialTool, required bool calledCardTool, required bool cardArgumentsRender, required bool calledOnNegativeControl})`.

- [ ] **Step 1: Write the failing test**

Create `test/tool_call_probe_test.dart`. Only the classifier is unit-tested — the HTTP path needs a live Ollama and is exercised in Task 6.

```dart
import 'package:test/test.dart';

// Relative: the probe lives outside lib/, so there is no package: URI.
import '../tool/model_probes/tool_call_probe.dart';

void main() {
  group('classifyToolSupport', () {
    test('a model that does everything right is supported', () {
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: true,
          cardArgumentsRender: true,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.supported,
      );
    });

    test('a template without tool support is unsupported', () {
      // The discriminator: it could not call even the trivial tool, so
      // "declined" is ruled out.
      expect(
        classifyToolSupport(
          calledTrivialTool: false,
          calledCardTool: false,
          cardArgumentsRender: false,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.unsupported,
      );
    });

    test('unsupported wins even if a card tool call somehow appeared', () {
      expect(
        classifyToolSupport(
          calledTrivialTool: false,
          calledCardTool: true,
          cardArgumentsRender: true,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.unsupported,
      );
    });

    test('a capable model that never reaches for the card tool declines', () {
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: false,
          cardArgumentsRender: false,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.supportedButDeclines,
      );
    });

    test('calling the card tool on a prose question is over-calling', () {
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: true,
          cardArgumentsRender: true,
          calledOnNegativeControl: true,
        ),
        ToolVerdict.overCalls,
      );
    });

    test('over-calling outranks unrenderable arguments', () {
      // Both are faults; over-calling is the one that changes what a user
      // sees on every prose question, so it is the verdict worth surfacing.
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: true,
          cardArgumentsRender: false,
          calledOnNegativeControl: true,
        ),
        ToolVerdict.overCalls,
      );
    });

    test('a card tool call whose arguments do not render is a decline', () {
      // It reached for the tool but produced nothing renderable, which is
      // not "supported" — supported means the channel actually works.
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: true,
          cardArgumentsRender: false,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.supportedButDeclines,
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd adaptive_chat_server_dart
fvm dart test test/tool_call_probe_test.dart
```

Expected: FAIL at compile time — `Error: Couldn't resolve … tool_call_probe.dart`.

- [ ] **Step 3: Write the prompt asset**

Create `assets/card_tool_prompt.txt`. This is `card_system_prompt.txt` recast for the tool channel: the reply-shape framing changes, the palette does not.

```text
You are a helpful assistant inside a chat app whose replies are rendered as
Adaptive Cards (the open JSON card format created by Microsoft) inside a narrow
chat bubble. Keep replies concise.

Choose ONE of two reply shapes per turn.

## Reply shape 1: call the render_adaptive_card tool

When a structured input or layout helps the user (choosing a date, picking from
options, entering a value, or presenting labelled/tabular data), call the
render_adaptive_card tool. Its "body" argument is an array of Adaptive Card
element objects. Put everything you want to say inside that array as a
TextBlock — there is no other channel for it when you call the tool.

Decide the shape from the CURRENT question by itself. Having answered in
Markdown earlier in this conversation is NOT a reason to answer in Markdown now
— a question that asks the user to pick from a set gets a card even when every
previous turn was prose.

When the user asks what their options are, which one they should pick, or what
they can choose from, that is a pick-from-a-set question: call the tool with an
Input.ChoiceSet offering about 3-6 representative options, and a TextBlock
beside it saying what they mean. A Markdown bullet list of options is the wrong
shape: the user cannot click it.

## Reply shape 2: plain Markdown

If no element type in the list below fits what you need to show, do NOT call
the tool. Answer with ordinary Markdown text instead.

Keep every list SHORT — at most about 6 items. Keep the card SMALL and shallow:
prefer ONE element, or a few flat elements, over deep nesting. Do NOT nest a
Table inside a Carousel page. Every property value is a plain JSON string,
number, or boolean.

Use ONLY these element "type" values, spelled EXACTLY. A type that is invented
or misspelled renders as an empty blank space and the user sees nothing.

Inputs — collect a value from the user (always give each an "id"):
- Input.Date — a date picker
- Input.Toggle — a single on/off switch; "title" is the label
- Input.ChoiceSet — the ONLY element for radio buttons, checkboxes, or a
  drop-down. Use "style":"expanded" with "isMultiSelect":false for radio
  buttons, "isMultiSelect":true for checkboxes, "style":"compact" for a
  drop-down. Each choice is a {"title","value"} pair.
- Input.Text, Input.Number, Input.Time — free-form entry

Display — show information, no user entry:
- TextBlock — text; set "wrap":true. "text" supports GitHub-flavored Markdown.
- FactSet — name/value pairs in "facts", each a {"title","value"} pair
- Badge — a small pill; "text" plus optional "style" and "shape"
- Carousel — a few swipeable pages; each CarouselPage holds "items"
- Table — a narrow grid; "columns" plus "rows" of TableRow/TableCell
- ColumnSet — side-by-side columns; each Column holds "items"
- Rating — a read-only star rating; "value" and "max" are numbers
- Icon — a small named icon; "name" plus optional "color"
- ProgressBar, ProgressRing — "value" is 0-100
- CodeBlock — "codeSnippet" is the code as ONE JSON string, "language"
  optional. When the user also wants the code explained, the explanation goes
  in a TextBlock in the same body array.
- Image — only with a real, working URL; "altText" describes it
- Chart.Pie, Chart.Donut — parts of a whole; data items are {"title","value"}
- Chart.VerticalBar, Chart.HorizontalBar, Chart.Line — data items are {"x","y"}
- Chart.Gauge — "value", "min", "max"
  Keep "data" to at most 6 points and use at most ONE chart per reply.

Do NOT include any Action, an "actions" array, or an ActionSet.
```

- [ ] **Step 4: Write the probe**

Create `tool/model_probes/tool_call_probe.dart`:

````dart
/// Checks whether a model can return an Adaptive Card through Ollama's
/// **tool channel** rather than the prose channel.
///
/// **Run this before building anything on tool calling.** Ollama accepts
/// `tools` for every model but applies it only for models whose chat
/// template supports it, and says nothing when it does not — the same silent
/// degradation `format` has, where `json_format_probe.dart` found one model
/// ignoring it harmlessly and another destructively.
///
/// Three checks, because one reply cannot tell the failures apart:
///   1. **positive** — a question that plainly wants a card; does the model
///      call `render_adaptive_card`, and do its arguments render?
///   2. **negative control** — a plain prose question; does it correctly
///      leave the tool alone? The seed already over-cards this exact control
///      on 5 of 15 models, so over-calling is a measured risk, not a guess.
///   3. **capability discriminator** — a trivial unrelated tool on a question
///      unanswerable without it. Without this, "declined to call" and "the
///      template never offered the tool" look identical.
///
/// Runs unseeded on purpose: the seed card is a prose-channel artifact, and
/// prepending it while asking for a tool call works against itself.
///
/// ```sh
/// fvm dart run tool/model_probes/tool_call_probe.dart \
///   --model qwen3-coder:30b --samples 2
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:path/path.dart' as p;

// Relative: this file and its helpers live outside `lib/`, so there is no
// `package:` URI for them.
import 'probe_results.dart';
import 'probe_support.dart';

const _cardPrompt =
    'What deployment targets can I choose from for this service?';
const _proseControlPrompt = 'What does SDUI stand for?';
const _trivialToolPrompt = 'What is the current temperature in Paris?';

/// The card tool the server would offer, wrapping the schema's element array.
Map<String, dynamic> _renderCardTool(Map<String, dynamic> schema) {
  final defs = schema[r'$defs'] as Map<String, dynamic>;
  return {
    'type': 'function',
    'function': {
      'name': 'render_adaptive_card',
      'description':
          'Render the reply as an Adaptive Card. Use when a structured '
          'input or layout helps the user.',
      'parameters': {
        'type': 'object',
        'required': ['body'],
        'properties': {'body': defs['ElementArray']},
      },
    },
  };
}

/// A tool no card prompt mentions, used only to prove the model *can* call
/// something. Deliberately additive and prompt-compatible: an earlier probe
/// that asked models to contradict their system prompt produced a null on
/// every model and proved nothing.
const _trivialTool = {
  'type': 'function',
  'function': {
    'name': 'get_current_temperature',
    'description': 'Get the current temperature for a city.',
    'parameters': {
      'type': 'object',
      'required': ['city'],
      'properties': {
        'city': {'type': 'string'},
      },
    },
  },
};

/// How a model handled the tool channel.
enum ToolVerdict {
  /// Calls tools, reaches for the card tool, and its arguments render.
  supported,

  /// Cannot call tools at all — the chat template has no tool support.
  unsupported,

  /// Can call tools, but never produces a renderable card through one.
  supportedButDeclines,

  /// Calls the card tool even on a question that wanted prose.
  overCalls,
}

/// Reduces the three checks to one verdict.
///
/// Order matters. [calledTrivialTool] is checked first because it is the only
/// signal that separates "cannot" from "chose not to", and every other
/// reading is meaningless without it. Over-calling outranks unrenderable
/// arguments because it changes what a user sees on every prose question.
ToolVerdict classifyToolSupport({
  required bool calledTrivialTool,
  required bool calledCardTool,
  required bool cardArgumentsRender,
  required bool calledOnNegativeControl,
}) {
  if (!calledTrivialTool) return ToolVerdict.unsupported;
  if (calledOnNegativeControl) return ToolVerdict.overCalls;
  if (calledCardTool && cardArgumentsRender) return ToolVerdict.supported;
  return ToolVerdict.supportedButDeclines;
}

/// One `/api/chat` call that offers [tools], returning the raw `message`.
Future<Map<String, dynamic>> _callWithTools({
  required HttpClient client,
  required String url,
  required String model,
  required String systemPrompt,
  required String userPrompt,
  required List<Map<String, dynamic>> tools,
  required Duration timeout,
}) async {
  final request = await client.postUrl(Uri.parse('$url/api/chat'));
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'stream': false,
      'think': false,
      'keep_alive': '30m',
      'options': const {'temperature': 0.0},
      'tools': tools,
    }),
  );
  final response = await request.close().timeout(timeout);
  final body = await response.transform(utf8.decoder).join().timeout(timeout);
  final data = jsonDecode(body) as Map<String, dynamic>;
  final message = data['message'];
  return message is Map<String, dynamic> ? message : <String, dynamic>{};
}

/// The arguments of the first call to [name] in [message], or null.
Map<String, dynamic>? _toolCallArguments(
  Map<String, dynamic> message,
  String name,
) {
  final calls = message['tool_calls'];
  if (calls is! List) return null;
  for (final call in calls) {
    if (call is! Map<String, dynamic>) continue;
    final function = call['function'];
    if (function is! Map<String, dynamic>) continue;
    if (function['name'] != name) continue;
    final args = function['arguments'];
    // Ollama returns arguments already decoded; some builds return a string.
    if (args is Map<String, dynamic>) return args;
    if (args is String) {
      try {
        final decoded = jsonDecode(args);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        return null;
      }
    }
  }
  return null;
}

/// Whether the tool arguments hold a body the running server would render.
bool _argumentsRender(Map<String, dynamic>? args) {
  if (args == null) return false;
  final body = args['body'];
  if (body == null) return false;
  return tryParseCardBody(jsonEncode(body)) != null;
}

Future<void> main(List<String> argv) async {
  final args = parseProbeArgs(argv, defaultSamples: 2);
  final schema = loadCardSchema();
  final toolPrompt = File(
    p.join(probeAssetsDir(), 'card_tool_prompt.txt'),
  ).readAsStringSync().trim();
  final cardTool = _renderCardTool(schema);
  final client = HttpClient()..idleTimeout = const Duration(minutes: 5);

  final calls = <ProbeCall>[];
  var calledTrivialTool = false;
  var calledCardTool = false;
  var cardArgumentsRender = false;
  var calledOnNegativeControl = false;

  stdout.writeln('=== check 3: capability discriminator ===');
  for (var i = 0; i < args.samples; i++) {
    final message = await _callWithTools(
      client: client,
      url: args.url,
      model: args.model,
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: _trivialToolPrompt,
      tools: const [_trivialTool],
      timeout: args.timeout,
    );
    final called =
        _toolCallArguments(message, 'get_current_temperature') != null;
    calledTrivialTool = calledTrivialTool || called;
    calls.add(
      ProbeCall(
        caseId: 'trivial-tool',
        sample: i,
        pass: called,
        label: called ? 'called' : 'no tool_calls',
        setting: 'tools=trivial',
      ),
    );
    stdout.writeln('  #$i ${called ? "called" : "no tool_calls"}');
  }

  stdout.writeln('=== check 1: positive, a question that wants a card ===');
  for (var i = 0; i < args.samples; i++) {
    final message = await _callWithTools(
      client: client,
      url: args.url,
      model: args.model,
      systemPrompt: toolPrompt,
      userPrompt: _cardPrompt,
      tools: [cardTool],
      timeout: args.timeout,
    );
    final toolArgs = _toolCallArguments(message, 'render_adaptive_card');
    final renders = _argumentsRender(toolArgs);
    calledCardTool = calledCardTool || toolArgs != null;
    cardArgumentsRender = cardArgumentsRender || renders;
    calls.add(
      ProbeCall(
        caseId: 'card-request',
        sample: i,
        pass: renders,
        label: toolArgs == null
            ? 'no tool_calls'
            : (renders ? 'tool body renders' : 'tool body not renderable'),
        setting: 'tools=card',
      ),
    );
    stdout.writeln(
      '  #$i ${toolArgs == null ? "no tool_calls" : (renders ? "renders" : "not renderable")}',
    );
  }

  stdout.writeln('=== check 2: negative control, a prose question ===');
  for (var i = 0; i < args.samples; i++) {
    final message = await _callWithTools(
      client: client,
      url: args.url,
      model: args.model,
      systemPrompt: toolPrompt,
      userPrompt: _proseControlPrompt,
      tools: [cardTool],
      timeout: args.timeout,
    );
    final called = _toolCallArguments(message, 'render_adaptive_card') != null;
    calledOnNegativeControl = calledOnNegativeControl || called;
    calls.add(
      ProbeCall(
        caseId: 'prose-control',
        sample: i,
        pass: !called,
        label: called ? 'over-called the tool' : 'answered in prose',
        setting: 'tools=card',
      ),
    );
    stdout.writeln('  #$i ${called ? "OVER-CALLED" : "prose (correct)"}');
  }

  final verdict = classifyToolSupport(
    calledTrivialTool: calledTrivialTool,
    calledCardTool: calledCardTool,
    cardArgumentsRender: cardArgumentsRender,
    calledOnNegativeControl: calledOnNegativeControl,
  );
  stdout.writeln('\nVERDICT: ${verdict.name}');

  if (args.json != null) {
    writeProbeRun(
      path: args.json!,
      probe: 'tool_call_probe',
      model: args.model,
      samples: args.samples,
      assetsDir: probeAssetsDir(),
      temperature: 0,
      summary: {
        'verdict': verdict.name,
        'calledTrivialTool': calledTrivialTool,
        'calledCardTool': calledCardTool,
        'cardArgumentsRender': cardArgumentsRender,
        'calledOnNegativeControl': calledOnNegativeControl,
        ...passSummary(calls),
      },
      calls: calls,
      notes: 'Unseeded by design: the seed card is a prose-channel artifact.',
    );
  }
  // force: a socket stuck mid-generation must not outlive the run.
  client.close(force: true);
}
````

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd adaptive_chat_server_dart
fvm dart test test/tool_call_probe_test.dart
```

Expected: PASS, 7 tests.

- [ ] **Step 6: Analyze and commit**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart analyze adaptive_chat_server_dart/
```

Expected: `No issues found!`

Changelog entry:

```markdown
- Added: **`tool_call_probe.dart`, a tool-calling capability canary.** Answers
  whether a model can return a card through Ollama's tool channel rather than
  the prose channel, using three checks — a card request, a prose negative
  control, and a trivial unrelated tool that separates "cannot call" from
  "chose not to". Verdicts are `supported`, `unsupported`,
  `supportedButDeclines`, and `overCalls`. Ships with
  `assets/card_tool_prompt.txt`, the tool-channel recast of the card system
  prompt. Runs unseeded: the seed card is a prose-channel artifact.
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart format adaptive_chat_server_dart/
npm run format:md:chat
git add adaptive_chat_server_dart/assets/card_tool_prompt.txt adaptive_chat_server_dart/tool/model_probes/tool_call_probe.dart adaptive_chat_server_dart/test/tool_call_probe_test.dart adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add tool-calling capability canary probe"
```

---

### Task 6: Run the canary and record the finding

**This task needs a live Ollama and cannot be done offline.** It is the measurement the whole of lever A exists for.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results/<model>/tool_call_probe.json` (one per model, written by the probe)
- Modify: `adaptive_chat_server_dart/ModelBehavior.md`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `tool_call_probe.dart` from Task 5.
- Produces: a `verdict` per model, and the phase-2 gate decision.

- [ ] **Step 1: Confirm Ollama is up and nothing is resident**

```bash
curl -s http://127.0.0.1:11434/api/tags | head -c 400
ollama ps
```

Expected: a JSON model list, and an empty or near-empty `ollama ps`. A stalling measurement looks identical whether the model is slow or the machine is busy — `granite4.1:3b`'s first measurement was wrong for exactly this reason.

- [ ] **Step 2: Re-derive the launch set**

```bash
cd adaptive_chat_server_dart
grep -A1 '"--ollama-model"' ../.vscode/launch.json |
  grep -v -e 'ollama-model' -e '^--$' | tr -d ' ",' | sort -u
```

Use whatever this prints. Do not use a list copied from any document, including this plan — the set is expected to change.

- [ ] **Step 3: Run the canary serially, one model at a time**

**One model resident at a time.** Do not parallelize and do not dispatch a subagent per model — several candidates are 18–24 GB, cannot be co-resident, and a reload costs roughly 20x the warm load.

```bash
cd adaptive_chat_server_dart
for m in $(grep -A1 '"--ollama-model"' ../.vscode/launch.json |
           grep -v -e 'ollama-model' -e '^--$' | tr -d ' ",' | sort -u); do
  echo "=== $m ==="
  slug=$(echo "$m" | tr '/:' '__')
  mkdir -p "tool/model_probes/results/$slug"
  fvm dart run tool/model_probes/tool_call_probe.dart \
    --model "$m" --samples 2 \
    --json "tool/model_probes/results/$slug/tool_call_probe.json"
  ollama stop "$m" || true
done
```

Expected: a `VERDICT:` line per model and one JSON file each.

- [ ] **Step 4: Apply the phase-2 gate**

Count models verdicted `supported`:

```bash
cd adaptive_chat_server_dart
grep -h '"verdict"' tool/model_probes/results/*/tool_call_probe.json
```

- **Two or more `supported`** → the gate opens. Phase 2 (adding a channel dimension to `shape_ab.dart`'s 25 cases) is warranted and needs its own plan. Do **not** start it here.
- **Fewer than two** → the gate stays shut. That is the finding and it ships as-is. One model is not a comparison.

Record which outcome occurred; it is the deliverable of this task either way.

- [ ] **Step 5: Write the finding into `ModelBehavior.md`**

Add a section after `### Not a card test: the format canary`, since it is the same kind of capability probe. Use this structure, filling in the measured values — do not invent numbers:

```markdown
### Not a card test: the tool-calling canary

`tool_call_probe.dart` asks whether a model can return a card through Ollama's
**tool channel** instead of the prose channel. Like `format`, tool support is
per-model and silent when absent, so this is a capability probe, not a quality
score.

Measured <DATE>, `--samples 2`, unseeded, `t=0`:

<one line per model: model, verdict, and what it did on each of the three checks>

**<The generalizable sentence — what the spread means for anyone asking a
local model for structured output through a tool.>**
```

If the result generalizes, also add one bullet to `## Key findings`. If it does not, do not force one.

- [ ] **Step 6: Update the changelog and commit**

```markdown
- Docs: **tool-calling capability measured across the launch set.**
  `ModelBehavior.md` gains a tool-calling canary section recording which
  models can return a card through Ollama's tool channel. <One sentence on
  the outcome and whether the phase-2 gate opened.>
```

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
npm run format:md:chat
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/CHANGELOG.md adaptive_chat_server_dart/tool/model_probes/results
git commit -m "docs(chat-server): record tool-calling capability across the launch set"
```

---

## Final Task: Full verification

- [ ] **Step 1: Full server suite**

```bash
cd adaptive_chat_server_dart
fvm dart test
```

Expected: all tests pass. Record the pass/fail counts and exit code.

- [ ] **Step 2: Analyze the whole repo**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Both format gates**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart format --output=none --set-exit-if-changed adaptive_chat_server_dart/
npm run check:md:chat
npm run check:md
```

Expected: all three exit 0. `check:md` is included because this plan also touches `docs/superpowers/`, which only that script covers.

- [ ] **Step 4: Confirm the main library is untouched**

```bash
git diff --stat main -- packages/
```

Expected: **no output.** No task in this plan modifies `packages/`; Task 1's test only _reads_ `registry.dart`. Output here means something went wrong.

- [ ] **Step 5: Invoke `superpowers:verification-before-completion`**

Paste the command output — exit codes and pass/fail counts — before making any success claim. Do not report the plan complete until every command above has run and passed.
