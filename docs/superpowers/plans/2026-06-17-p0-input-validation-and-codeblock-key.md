# P0 Remediation: Input min/max Validation + CodeBlock `codeSnippet` Key

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the two P0 spec-compliance findings from the [audit addendum](../specs/2026-06-17-spec-compliance-audit-addendum.md): (A2) `CodeBlock` renders nothing because it reads the wrong JSON key, and (A1) `Input.Number` / `Input.Date` / `Input.Time` submit out-of-range values silently because `validateInputs()` never checks `min`/`max`.

**Architecture:** Two independent changes in `packages/flutter_adaptive_cards_fs`. (A2) is a one-line key fix in `code_block.dart` (read spec `codeSnippet`, fall back to legacy `code`). (A1) adds a pure, unit-testable validation helper file (`input_range_validation.dart`) mirroring the existing `input_text_validation.dart`, then wires three type branches into `validateInputs()` in `action/default_actions.dart` — the single gate already fired before Submit/Execute.

**Tech Stack:** Dart / Flutter, FVM (`fvm flutter ...`), Riverpod, `package:flutter_test`. All shell commands run from `packages/flutter_adaptive_cards_fs/` unless noted, and every `flutter`/`dart` command is prefixed with `fvm`.

---

## File Structure

- `lib/src/cards/elements/code_block.dart` — **modify** `initState` to read `codeSnippet`.
- `lib/src/cards/inputs/input_range_validation.dart` — **create**: pure `numberInputValueIsValid` / `dateInputValueIsValid` / `timeInputValueIsValid` functions (no Flutter/Riverpod deps), peer to `input_text_validation.dart`.
- `lib/src/action/default_actions.dart` — **modify** `validateInputs()` to call the three new helpers for Number/Date/Time inputs.
- `test/elements/code_block_test.dart` — **create**: widget test that a `codeSnippet` CodeBlock renders its text.
- `test/inputs/input_range_validation_test.dart` — **create**: pure-function unit tests.
- `test/inputs/input_range_submit_test.dart` — **create**: widget test that an out-of-range Number blocks Submit.
- `CHANGELOG.md` — **modify**: add `[Unreleased]` bullets.

---

## Task 1: Fix CodeBlock to read spec `codeSnippet`

The official property is `codeSnippet` (verified against the Microsoft Teams `cards-format` schema). The code reads `adaptiveMap['code']`, so schema-correct cards render empty. Fix it; keep a `code` fallback so any legacy fixtures still work.

**Files:**
- Modify: `lib/src/cards/elements/code_block.dart:46`
- Test: `test/elements/code_block_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/elements/code_block_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('CodeBlock renders text from spec codeSnippet property', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[
        {
          'type': 'CodeBlock',
          'codeSnippet': 'final answer = 42;',
          'language': 'dart',
          'startLineNumber': 1,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'CodeBlock codeSnippet'),
    );
    await tester.pump();

    expect(find.textContaining('final answer = 42;'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/elements/code_block_test.dart`
Expected: FAIL — the CodeBlock reads `code`, so `codeSnippet` text is absent (`findsOneWidget` finds nothing).

- [ ] **Step 3: Make the minimal change**

In `lib/src/cards/elements/code_block.dart`, change the `initState` read (line ~46):

```dart
    codeSnippet =
        adaptiveMap['codeSnippet']?.toString() ??
        adaptiveMap['code']?.toString() ??
        '';
```

Also update the doc comment on the `codeSnippet` field (line ~34) to match:

```dart
  /// Source code from `codeSnippet` (spec property; legacy `code` accepted).
  late String codeSnippet;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/elements/code_block_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/cards/elements/code_block.dart test/elements/code_block_test.dart
git commit -m "fix(code-block): read spec codeSnippet key (legacy code fallback)"
```

---

## Task 2: Pure range-validation helpers

Add a Flutter-free helper file with one pure function per input type, mirroring `input_text_validation.dart`. Pure functions keep the logic unit-testable in isolation, separate from the Riverpod gate that calls them in Task 3.

**Files:**
- Create: `lib/src/cards/inputs/input_range_validation.dart`
- Test: `test/inputs/input_range_validation_test.dart` (create)

Validation contract (matches the spec and the existing `textInputValueIsValid`):
- Empty value: valid iff **not** required (range is not checked on empty).
- Non-empty but unparseable: **invalid** (cannot satisfy a range).
- Non-empty parseable: invalid iff below `min` or above `max` (each bound optional).

- [ ] **Step 1: Write the failing tests**

Create `test/inputs/input_range_validation_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/input_range_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('numberInputValueIsValid', () {
    test('value within bounds passes', () {
      expect(
        numberInputValueIsValid(
          value: '3',
          isRequired: false,
          min: 1,
          max: 5,
        ),
        isTrue,
      );
    });

    test('value above max fails', () {
      expect(
        numberInputValueIsValid(
          value: '99',
          isRequired: false,
          min: 1,
          max: 5,
        ),
        isFalse,
      );
    });

    test('value below min fails', () {
      expect(
        numberInputValueIsValid(
          value: '0',
          isRequired: false,
          min: 1,
          max: 5,
        ),
        isFalse,
      );
    });

    test('empty optional value passes', () {
      expect(
        numberInputValueIsValid(
          value: '',
          isRequired: false,
          min: 1,
          max: 5,
        ),
        isTrue,
      );
    });

    test('empty required value fails', () {
      expect(
        numberInputValueIsValid(
          value: '',
          isRequired: true,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });

    test('non-numeric value fails', () {
      expect(
        numberInputValueIsValid(
          value: 'abc',
          isRequired: false,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });
  });

  group('dateInputValueIsValid', () {
    test('value within bounds passes', () {
      expect(
        dateInputValueIsValid(
          value: '2026-06-17',
          isRequired: false,
          min: '2026-01-01',
          max: '2026-12-31',
        ),
        isTrue,
      );
    });

    test('value after max fails', () {
      expect(
        dateInputValueIsValid(
          value: '2027-01-01',
          isRequired: false,
          min: '2026-01-01',
          max: '2026-12-31',
        ),
        isFalse,
      );
    });

    test('value before min fails', () {
      expect(
        dateInputValueIsValid(
          value: '2025-12-31',
          isRequired: false,
          min: '2026-01-01',
          max: '2026-12-31',
        ),
        isFalse,
      );
    });

    test('empty optional value passes', () {
      expect(
        dateInputValueIsValid(
          value: '',
          isRequired: false,
          min: '2026-01-01',
          max: null,
        ),
        isTrue,
      );
    });
  });

  group('timeInputValueIsValid', () {
    test('value within bounds passes', () {
      expect(
        timeInputValueIsValid(
          value: '12:30',
          isRequired: false,
          min: '09:00',
          max: '17:00',
        ),
        isTrue,
      );
    });

    test('value after max fails', () {
      expect(
        timeInputValueIsValid(
          value: '18:00',
          isRequired: false,
          min: '09:00',
          max: '17:00',
        ),
        isFalse,
      );
    });

    test('value before min fails', () {
      expect(
        timeInputValueIsValid(
          value: '08:00',
          isRequired: false,
          min: '09:00',
          max: '17:00',
        ),
        isFalse,
      );
    });

    test('malformed time fails', () {
      expect(
        timeInputValueIsValid(
          value: '99:99',
          isRequired: false,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/inputs/input_range_validation_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'input_range_validation.dart'` (file not created yet).

- [ ] **Step 3: Create the implementation**

Create `lib/src/cards/inputs/input_range_validation.dart`:

```dart
/// Pure validation helpers for `Input.Number`, `Input.Date`, and `Input.Time`,
/// enforcing `isRequired` plus optional `min`/`max` bounds. These mirror
/// `input_text_validation.dart` and are called by the submit/execute gate in
/// `action/default_actions.dart`. Kept Flutter-free so they can be unit-tested
/// in isolation.
library;

/// Validates an `Input.Number` [value] against [isRequired] and optional
/// numeric [min]/[max] bounds. [value] is the raw input string.
bool numberInputValueIsValid({
  required String? value,
  required bool isRequired,
  required num? min,
  required num? max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return !isRequired;
  final parsed = num.tryParse(text);
  if (parsed == null) return false;
  if (min != null && parsed < min) return false;
  if (max != null && parsed > max) return false;
  return true;
}

/// Validates an `Input.Date` [value] (ISO `yyyy-MM-dd`) against [isRequired]
/// and optional [min]/[max] date strings.
bool dateInputValueIsValid({
  required String? value,
  required bool isRequired,
  required String? min,
  required String? max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return !isRequired;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return false;
  final lower = (min == null || min.isEmpty) ? null : DateTime.tryParse(min);
  final upper = (max == null || max.isEmpty) ? null : DateTime.tryParse(max);
  if (lower != null && parsed.isBefore(lower)) return false;
  if (upper != null && parsed.isAfter(upper)) return false;
  return true;
}

/// Validates an `Input.Time` [value] (`HH:mm`) against [isRequired] and
/// optional [min]/[max] time strings.
bool timeInputValueIsValid({
  required String? value,
  required bool isRequired,
  required String? min,
  required String? max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return !isRequired;
  final minutes = _timeToMinutes(text);
  if (minutes == null) return false;
  final lower = _timeToMinutes(min);
  final upper = _timeToMinutes(max);
  if (lower != null && minutes < lower) return false;
  if (upper != null && minutes > upper) return false;
  return true;
}

/// Parses an `HH:mm` (or `H:mm`) string to minutes-since-midnight, or `null`
/// when malformed / out of range.
int? _timeToMinutes(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  if (hours > 23 || minutes > 59) return null;
  return hours * 60 + minutes;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `fvm flutter test test/inputs/input_range_validation_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/src/cards/inputs/input_range_validation.dart test/inputs/input_range_validation_test.dart
git commit -m "feat(inputs): add pure min/max validation helpers for number/date/time"
```

---

## Task 3: Wire range validation into the submit gate

`validateInputs()` in `action/default_actions.dart` is the gate fired before Submit (`:90`) and Execute (`:134`). It currently checks only `isRequired` (all inputs) and `regex` (Text). Add Number/Date/Time branches that call the Task 2 helpers, mirroring the existing `Input.Text` branch.

**Files:**
- Modify: `lib/src/action/default_actions.dart` (import + `validateInputs` branches)
- Test: `test/inputs/input_range_submit_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/inputs/input_range_submit_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _numberCard() => <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[
        {
          'type': 'Input.Number',
          'id': 'qty',
          'min': 1,
          'max': 5,
        },
      ],
      'actions': <Map<String, dynamic>>[
        {'type': 'Action.Submit', 'title': 'OK'},
      ],
    };

void main() {
  testWidgets('out-of-range number blocks Submit and marks input invalid', (
    WidgetTester tester,
  ) async {
    var submitCount = 0;

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _numberCard(),
        title: 'number range',
        onSubmit: (_) => submitCount++,
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('qty')).first,
      '99',
    );
    await tester.pump();

    await tester.tap(find.text('OK'));
    await tester.pump();

    expect(submitCount, 0);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(generateWidgetKeyFromId('qty')).first),
    );
    expect(container.read(resolvedElementProvider('qty'))?['isInvalid'], isTrue);
  });

  testWidgets('in-range number allows Submit', (WidgetTester tester) async {
    var submitCount = 0;

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _numberCard(),
        title: 'number range ok',
        onSubmit: (_) => submitCount++,
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('qty')).first,
      '3',
    );
    await tester.pump();

    await tester.tap(find.text('OK'));
    await tester.pump();

    expect(submitCount, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/inputs/input_range_submit_test.dart`
Expected: FAIL on the first test — without range validation, `99` submits, so `submitCount` is `1` (expected `0`) and `isInvalid` is not set.

- [ ] **Step 3: Add the import**

In `lib/src/action/default_actions.dart`, add this import next to the existing
`input_text_validation.dart` import (keep imports alphabetically ordered):

```dart
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/input_range_validation.dart';
```

- [ ] **Step 4: Add the validation branches**

In `validateInputs()`, immediately after the existing `Input.Text` branch (the block ending `continue;` right before `if (!isRequired) continue;`), insert:

```dart
    if (type == 'Input.Number') {
      if (!numberInputValueIsValid(
        value: value?.toString(),
        isRequired: isRequired,
        min: node['min'] as num?,
        max: node['max'] as num?,
      )) {
        valid = false;
        notifier.setInputError(entry.key, isInvalid: true);
      }
      continue;
    }

    if (type == 'Input.Date') {
      if (!dateInputValueIsValid(
        value: value?.toString(),
        isRequired: isRequired,
        min: node['min'] as String?,
        max: node['max'] as String?,
      )) {
        valid = false;
        notifier.setInputError(entry.key, isInvalid: true);
      }
      continue;
    }

    if (type == 'Input.Time') {
      if (!timeInputValueIsValid(
        value: value?.toString(),
        isRequired: isRequired,
        min: node['min'] as String?,
        max: node['max'] as String?,
      )) {
        valid = false;
        notifier.setInputError(entry.key, isInvalid: true);
      }
      continue;
    }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/inputs/input_range_submit_test.dart`
Expected: PASS (both tests).

- [ ] **Step 6: Commit**

```bash
git add lib/src/action/default_actions.dart test/inputs/input_range_submit_test.dart
git commit -m "feat(inputs): enforce min/max on submit for number/date/time inputs"
```

---

## Task 4: Changelog

Per repo policy, any change under `packages/<name>/` needs a `[Unreleased]` CHANGELOG bullet.

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [ ] **Step 1: Add bullets under `## [Unreleased]`**

```markdown
### Fixed

- `CodeBlock` now reads the spec `codeSnippet` property (legacy `code` still accepted); schema-correct code blocks previously rendered empty.

### Changed

- `Input.Number`, `Input.Date`, and `Input.Time` now validate `min`/`max` bounds on Submit/Execute; out-of-range values block the action and mark the input invalid instead of submitting silently.
```

(If `## [Unreleased]` lacks `### Fixed` / `### Changed` subheadings, add them under it; if they exist, append the bullets.)

- [ ] **Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): note CodeBlock key fix and input min/max validation"
```

---

## Final Task: Full verification

- [ ] **Step 1: Static analysis (repo root)**

Run: `cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && fvm flutter analyze`
Expected: no new issues introduced by these changes.

- [ ] **Step 2: Full non-golden suite for the main library**

Run:
```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden
```
Expected: all tests pass (prior baseline was 466 passing / 2 skipped; the new tests add to the pass count). Record the exact pass/skip/fail counts.

- [ ] **Step 3: Invoke `verification-before-completion`**

Paste the analyze exit status and the test pass/fail/skip counts before claiming completion. Do not report the plan complete until the full suite passes.
