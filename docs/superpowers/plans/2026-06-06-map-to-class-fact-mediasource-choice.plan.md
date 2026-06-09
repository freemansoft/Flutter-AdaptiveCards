# Fact / MediaSource / Input.Choice Map→Class Completion Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Status:** **Implemented** (shipped in **0.10.0**). Typed `Choice`/`Fact`/`MediaSource` overlays, public exports, `SearchModel` removed. Checkboxes marked complete; do not re-implement.

**Goal:** Finish the map→class migration for `Fact`, `MediaSource`, and `Input.Choice` — typed models already exist but overlays, widgets, and docs still treat them as raw maps in places. After this work, choice lists flow as `List<Choice>` end-to-end, duplicate `SearchModel` is removed, models are exported from the public API, and `Implementation-Status.md` reflects reality.

**Architecture:** Keep hand-rolled `@immutable` model classes (consistent with `TableCellModel`, `DataQuery`, and existing `lib/src/models/*.dart`). Do **not** introduce `json_serializable` for these three small types in this pass — HostConfig models in this package also use hand-rolled `fromJson`. Centralize list parsing in small helpers; store `List<Choice>` inside `ElementOverlay` with JSON conversion only at merge boundaries (`resolvedElementProvider` still emits maps for widget baseline compatibility).

**Tech Stack:** Dart 3.12+, Flutter (FVM), `flutter_adaptive_cards_fs`, `package:test`, `very_good_analysis`.

**Current state (post-implementation):**

| Type           | Model file                         | Status                                                                             |
| -------------- | ---------------------------------- | ---------------------------------------------------------------------------------- |
| `Fact`         | `lib/src/models/fact.dart`         | Typed; `factsFromJsonList`; exported                                               |
| `MediaSource`  | `lib/src/models/media_source.dart` | Typed; `mediaSourcesFromJsonList`; exported                                        |
| `Input.Choice` | `lib/src/models/choice.dart`       | Typed; `ElementOverlay.choices` is `List<Choice>`; `SearchModel` removed; exported |

---

## File map

| File                                                                                         | Role                                                        |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| `packages/flutter_adaptive_cards_fs/lib/src/models/choice.dart`                              | Add `choicesFromJsonList` / `choicesToJsonList` helpers     |
| `packages/flutter_adaptive_cards_fs/lib/src/models/fact.dart`                                | Add `factsFromJsonList` helper (optional `copyWith`)        |
| `packages/flutter_adaptive_cards_fs/lib/src/models/media_source.dart`                        | Add `mediaSourcesFromJsonList` helper                       |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart`            | `ElementOverlay.choices` → `List<Choice>?`                  |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart`   | Update overlay merge / `setChoices` / `_choicesFromPatch`   |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`                         | Merge `Choice` list into resolved JSON at provider boundary |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/choice_set.dart`                    | Remove `SearchModel`; use `Choice` in filtered modal        |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/choice_filter.dart`                 | Accept `List<Choice>` instead of `SearchModel`              |
| `packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart`                      | Export `Fact`, `MediaSource`, `Choice`                      |
| `packages/flutter_adaptive_cards_fs/test/models/*.dart`                                      | Extend list-helper tests                                    |
| `packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart` | Update for typed overlay choices                            |
| `docs/Implementation-Status.md`                                                              | Mark Fact / MediaSource / Input.Choice as typed models      |
| `packages/flutter_adaptive_cards_fs/README.md`                                               | Remove "implemented as map" notes                           |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md`                                            | Document typed models, exports, and ChoiceSet refactor      |

---

### Task 1: List parsing helpers on model classes

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/choice.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/fact.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/media_source.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/models/choice_test.dart` (and sibling model tests)

- [x] **Step 1: Write failing tests for list helpers**

Add to `choice_test.dart`:

```dart
test('choicesFromJsonList parses list of maps', () {
  final choices = choicesFromJsonList([
    {'title': 'A', 'value': 'a'},
    {'title': 'B', 'value': 'b'},
  ]);
  expect(choices, [
    const Choice(title: 'A', value: 'a'),
    const Choice(title: 'B', value: 'b'),
  ]);
});

test('choicesToJsonList round-trips', () {
  const choices = [
    Choice(title: 'A', value: 'a'),
  ];
  final json = choicesToJsonList(choices);
  expect(choicesFromJsonList(json), choices);
});
```

Add analogous tests in `fact_test.dart` and `media_source_test.dart` for `factsFromJsonList` and `mediaSourcesFromJsonList`.

- [x] **Step 2: Run tests to verify they fail**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/models/choice_test.dart test/models/fact_test.dart test/models/media_source_test.dart`

Expected: FAIL — helpers not defined

- [x] **Step 3: Implement helpers**

In `choice.dart`:

```dart
List<Choice> choicesFromJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Choice.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<Map<String, dynamic>> choicesToJsonList(List<Choice> choices) =>
    choices.map((c) => c.toJson()).toList();
```

In `fact.dart`:

```dart
List<Fact> factsFromJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Fact.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
```

In `media_source.dart`:

```dart
List<MediaSource> mediaSourcesFromJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => MediaSource.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
```

- [x] **Step 4: Run tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/models/`

Expected: PASS

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/choice.dart \
        packages/flutter_adaptive_cards_fs/lib/src/models/fact.dart \
        packages/flutter_adaptive_cards_fs/lib/src/models/media_source.dart \
        packages/flutter_adaptive_cards_fs/test/models/
git commit -m "refactor: add list parse helpers for Choice, Fact, MediaSource"
```

---

### Task 2: Typed choices in ElementOverlay

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart`

- [x] **Step 1: Write failing notifier test**

Add to `adaptive_card_document_notifier_test.dart`:

```dart
test('setChoices stores List<Choice> in overlay', () {
  final notifier = AdaptiveCardDocumentNotifier()
    ..initialize(baselineCardWithChoiceSetId('myChoice'));

  notifier.setChoices('myChoice', const [
    Choice(title: 'One', value: '1'),
    Choice(title: 'Two', value: '2'),
  ]);

  final overlay = notifier.state.overlaysById['myChoice'];
  expect(overlay?.choices, isA<List<Choice>>());
  expect(overlay!.choices!.first.value, '1');
});
```

Import `Choice` model in the test file.

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart --name "setChoices stores"`

Expected: FAIL — type mismatch or `isA<List<Choice>>()` false

- [x] **Step 3: Change ElementOverlay**

In `adaptive_card_document.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';

// In ElementOverlay:
final List<Choice>? choices;

// copyWith parameter:
List<Choice>? choices,
```

- [x] **Step 4: Update notifier**

In `adaptive_card_document_notifier.dart`:

1. `_choicesFromPatch` returns `List<Choice>?` using `choicesFromJsonList`.
2. `setChoices` stores `choices` directly (remove `.map((c) => c.toJson())`).
3. `appendChoices` merges `Choice` objects by `value`.
4. `_effectiveChoiceJson` becomes `_effectiveChoices` returning `List<Choice>`.
5. Where resolved merge writes `'choices'` into the output map, use `choicesToJsonList(choices)`.

- [x] **Step 5: Update resolved merge**

Find merge logic in `adaptive_card_document_notifier.dart` or `providers.dart` that copies overlay `choices` into resolved element maps — ensure it calls `choicesToJsonList` so widgets still read `List<Map>` from `resolvedElementProvider` JSON (no widget changes yet in this task).

- [x] **Step 6: Run notifier tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart`

Expected: PASS (fix any existing tests expecting raw maps in overlay)

- [x] **Step 7: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart \
        packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart \
        packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart \
        packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart
git commit -m "refactor: store Input.Choice overlays as List<Choice>"
```

---

### Task 3: Remove SearchModel; use Choice in ChoiceSet UI

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/choice_set.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/choice_filter.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/inputs/choice_set_test.dart`

- [x] **Step 1: Write failing grep-based check (manual)**

Confirm `SearchModel` is referenced in `choice_set.dart` and `choice_filter.dart`.

- [x] **Step 2: Refactor choice_set.dart**

1. Delete `SearchModel` class (lines 18–38 in current file).
2. Replace `_parseChoices` return type from `Map<String, String>` with `List<Choice>` using `choicesFromJsonList(input.map['choices'])`.
3. Add helpers:

```dart
Map<String, String> _titleToValueMap(List<Choice> choices) =>
    {for (final c in choices) c.title: c.value};

String _titleForStoredValue(String storedValue, List<Choice> choices) {
  for (final c in choices) {
    if (c.value == storedValue) return c.title;
  }
  return storedValue;
}
```

1. Update `_syncFilteredControllerText`, `_buildCompact`, `_buildExpandedMultiSelect`, `_buildFiltered` to take `List<Choice>`.
2. `RawAdaptiveCard.searchList` call: pass `choices` list to `ChoiceFilter`.

- [x] **Step 3: Refactor choice_filter.dart**

Change constructor from `List<SearchModel>` to `List<Choice> choices`. Display `choice.title`; on select return `choice.value`.

- [x] **Step 4: Run ChoiceSet tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/choice_set_test.dart test/inputs/choice_set_overlay_test.dart test/inputs/init_data_overlay_test.dart test/inputs/choice_set_data_query_test.dart`

Expected: PASS

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/choice_set.dart \
        packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/choice_filter.dart
git commit -m "refactor: replace SearchModel with Choice in ChoiceSet UI"
```

---

### Task 4: Use list helpers in FactSet and Media widgets

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/fact_set.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/media.dart`

- [x] **Step 1: FactSet — use `factsFromJsonList`**

Replace inline map in `initState`:

```dart
facts = factsFromJsonList(adaptiveMap['facts']);
```

No behavior change; cleaner single entry point.

- [x] **Step 2: Media — use `mediaSourcesFromJsonList`**

Replace:

```dart
final List<MediaSource> sources = mediaSourcesFromJsonList(adaptiveMap['sources']);
```

- [x] **Step 3: Run widget tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/models/ test/elements/ --exclude-tags=golden 2>&1 | tail -30`

Fix any Media/FactSet regressions if present.

- [x] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/containers/fact_set.dart \
        packages/flutter_adaptive_cards_fs/lib/src/cards/elements/media.dart
git commit -m "refactor: use typed list helpers in FactSet and Media widgets"
```

---

### Task 5: Public API exports and documentation

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart`
- Modify: `docs/Implementation-Status.md`
- Modify: `packages/flutter_adaptive_cards_fs/README.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [x] **Step 1: Export models**

Add to `flutter_adaptive_cards_fs.dart`:

```dart
export 'src/models/choice.dart';
export 'src/models/fact.dart';
export 'src/models/media_source.dart';
```

- [x] **Step 2: Update Implementation-Status.md**

Change rows:

| Fact | ⚠️ Map | → | ✅ Complete (typed `Fact` model) |
| MediaSource | ⚠️ Map | → | ✅ Complete (typed `MediaSource` model) |
| Input.Choice | ⚠️ Map | → | ✅ Complete (typed `Choice` model; overlay uses `List<Choice>`) |

Remove or update Medium Priority item "Convert Maps to Classes" for these three types.

- [x] **Step 3: Update README.md**

Remove notes under open issues:

- `MediaSource` currently implemented as a map in `Media`
- `Input.Choice` currently implemented as a map in `ChoiceSet`

- [x] **Step 4: Update CHANGELOG.md**

Under the current unreleased section at the top of `packages/flutter_adaptive_cards_fs/CHANGELOG.md` (e.g. `## [0.10.0]` or add `## [Unreleased]` if the version section is still a placeholder), add entries:

```markdown
### Added

- Public exports for **`Choice`**, **`Fact`**, and **`MediaSource`** from `flutter_adaptive_cards_fs.dart`.
- List parse helpers: `choicesFromJsonList` / `choicesToJsonList`, `factsFromJsonList`, `mediaSourcesFromJsonList`.

### Changed

- **`ElementOverlay.choices`** now stores `List<Choice>` internally; resolved element JSON still exposes `choices` as maps for widget compatibility.
- **`Input.ChoiceSet`** filtered modal uses **`Choice`** instead of internal **`SearchModel`**.
- **`AdaptiveFactSet`** and **`AdaptiveMedia`** parse child lists via shared typed helpers.
```

Remove any placeholder line such as `- no changes yet` from the target version section.

- [x] **Step 5: Run analyzer**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter analyze && fvm flutter test --exclude-tags=golden`

Expected: no errors; full non-golden suite PASS

- [x] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart \
        packages/flutter_adaptive_cards_fs/CHANGELOG.md \
        docs/Implementation-Status.md \
        packages/flutter_adaptive_cards_fs/README.md
git commit -m "docs: export Choice, Fact, MediaSource and update changelog"
```

---

## Verification (full suite)

```bash
cd packages/flutter_adaptive_cards_fs
fvm dart format lib/src/models/ lib/src/riverpod/ lib/src/cards/
fvm flutter analyze
fvm flutter test --exclude-tags=golden
```

Expected: analyzer clean; all non-golden tests PASS.

---

## Out of scope

- `json_serializable` codegen migration (HostConfig and existing models use hand-rolled `fromJson`; defer unless monorepo-wide model codegen is scheduled).
- `TableCell` inline→class extraction (separate item in Implementation-Status).
- Reactive FactSet overlays (`facts` runtime patches via `applyUpdates`) — not required for map→class completion.
- Changing `RawAdaptiveCard.loadInput` public signature (already accepts `List<Choice>` via notifier).

---

## Self-review checklist

| Requirement                                | Task      |
| ------------------------------------------ | --------- |
| `ElementOverlay` stores typed choices      | Task 2    |
| Remove duplicate `SearchModel`             | Task 3    |
| Fact / MediaSource use shared list parsers | Task 4    |
| Public exports                             | Task 5    |
| Docs reflect typed status                  | Task 5    |
| CHANGELOG updated                          | Task 5    |
| Tests for list helpers and overlay typing  | Tasks 1–2 |
