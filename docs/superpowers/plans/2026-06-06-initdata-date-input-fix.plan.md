# initData on Input.Date Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Status:** **Implemented** (shipped in **0.10.0**). `date_input_utils.dart`, overlay tests, README/CHANGELOG updated. Checkboxes marked complete; do not re-implement.

**Goal:** Fix `initData` / `initInput` seeding for `Input.Date` so host-provided dates appear in the field, survive submit/validation, and match other inputs' overlay semantics (Widgetbook `ac-qv-faqs.json` `bookingdate` scenario).

**Architecture:** Keep the Riverpod overlay path (`applyUpdatesFromMap` → `resolvedElementProvider` → `listenForResolvedValueChanges`). Fix `AdaptiveDateInput` local state sync: stop writing placeholder text into the controller, parse AC date strings via shared helpers (ISO uses calendar date portion only — Behavior A), call `setState` when the document value changes (same pattern as `AdaptiveTimeInput`), and submit `yyyy-MM-dd` per the Adaptive Cards spec instead of full ISO-8601 datetimes.

**Tech Stack:** Dart 3.12+, Flutter (FVM), `flutter_adaptive_cards_fs`, `intl` (`DateFormat`), `package:test` / `flutter_test`, `very_good_analysis`.

**Design spec:** [`docs/superpowers/specs/2026-06-07-initdata-date-input-fix-design.md`](../specs/2026-06-07-initdata-date-input-fix-design.md)

**Symptom reference (resolved):** Widgetbook use case `Form with initData` seeds `'bookingdate': '2023-05-08'` against `widgetbook/assets/ac-qv-faqs.json`. README open-issue note removed in 0.10.0.

---

## File map

| File                                                                         | Role                                                             |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------  |
| `packages/flutter_adaptive_cards_fs/lib/src/utils/date_input_utils.dart`     | **Create** — shared parse/format for AC date strings             |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/date.dart`          | Fix controller sync, `appendInput`, `onTap`, `setState`          |
| `packages/flutter_adaptive_cards_fs/test/utils/date_input_utils_test.dart`   | **Create** — unit tests for parse/format                         |
| `packages/flutter_adaptive_cards_fs/test/inputs/init_data_overlay_test.dart` | Add Date overlay + programmatic `initInput` cases                |
| `packages/flutter_adaptive_cards_fs/test/inputs/date_input_test.dart`        | Assert exact `yyyy-MM-dd` in `appendInput`                       |
| `packages/flutter_adaptive_cards_fs/test/inputs/date_edgecases_test.dart`    | Empty controller, required-validation, appendInput format        |
| `packages/flutter_adaptive_cards_fs/README.md`                               | Remove open issue once fixed                                     |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md`                            | Bugfix entry for initData / submit format                        |
| `docs/Implementation-Status.md`                                              | Short note under Inputs (no status change — already ✅ Complete) |

---

### Task 1: Shared date parse/format helper

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/utils/date_input_utils.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/utils/date_input_utils_test.dart`

> **Note:** `date_time_utils.dart` handles TextBlock `{{DATE}}` / `{{TIME}}` macros only. Do not merge into that file — `date_input_utils.dart` is for `Input.Date` parse/format.

- [x] **Step 1: Write failing unit tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/date_input_utils.dart';

void main() {
  group('parseAdaptiveDateValue', () {
    test('parses yyyy-MM-dd', () {
      final dt = parseAdaptiveDateValue('2023-05-08');
      expect(dt, isNotNull);
      expect(dt!.year, 2023);
      expect(dt.month, 5);
      expect(dt.day, 8);
    });

    test('parses ISO datetime using calendar date portion only (Behavior A)', () {
      final midnightUtc = parseAdaptiveDateValue('2023-05-08T00:00:00Z');
      expect(midnightUtc, isNotNull);
      expect(midnightUtc!.year, 2023);
      expect(midnightUtc.month, 5);
      expect(midnightUtc.day, 8);

      // Late UTC must still be May 8 — timezone must not shift calendar date.
      final lateUtc = parseAdaptiveDateValue('2023-05-08T23:00:00.000Z');
      expect(lateUtc, isNotNull);
      expect(lateUtc!.year, 2023);
      expect(lateUtc.month, 5);
      expect(lateUtc.day, 8);
    });

    test('parses space-separated datetime using date portion only', () {
      final dt = parseAdaptiveDateValue('2023-05-08 14:30:00');
      expect(dt, isNotNull);
      expect(dt!.year, 2023);
      expect(dt.month, 5);
      expect(dt.day, 8);
    });

    test('returns null for invalid string', () {
      expect(parseAdaptiveDateValue('not-a-date'), isNull);
    });

    test('returns null for empty string', () {
      expect(parseAdaptiveDateValue(''), isNull);
      expect(parseAdaptiveDateValue(null), isNull);
    });
  });

  group('formatAdaptiveDateValue', () {
    test('formats as yyyy-MM-dd', () {
      expect(
        formatAdaptiveDateValue(DateTime(2023, 5, 8)),
        '2023-05-08',
      );
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/utils/date_input_utils_test.dart`

Expected: FAIL — `parseAdaptiveDateValue` not defined

- [x] **Step 3: Implement helper**

```dart
import 'package:intl/intl.dart';

final DateFormat _adaptiveDateFormat = DateFormat('yyyy-MM-dd');

/// Extracts the calendar date portion from [text] for ISO-style datetimes.
///
/// Behavior A: time and timezone are ignored; only `yyyy-MM-dd` matters.
String _datePortion(String text) {
  if (text.contains('T')) {
    return text.split('T').first;
  }
  if (text.contains(' ')) {
    return text.split(' ').first;
  }
  return text;
}

/// Parses an Adaptive Card [Input.Date] value from host `initData` or JSON.
///
/// Accepts `yyyy-MM-dd` (spec) and ISO-8601 datetimes. For datetimes, only
/// the calendar date portion is used; time and timezone offsets are ignored.
DateTime? parseAdaptiveDateValue(Object? raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  try {
    return _adaptiveDateFormat.parseStrict(_datePortion(text));
  } on FormatException {
    return null;
  }
}

/// Formats a [DateTime] for Adaptive Card [Input.Date] submit / display.
String formatAdaptiveDateValue(DateTime date) =>
    _adaptiveDateFormat.format(date);
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/utils/date_input_utils_test.dart`

Expected: All tests PASS

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/utils/date_input_utils.dart \
        packages/flutter_adaptive_cards_fs/test/utils/date_input_utils_test.dart
git commit -m "feat: add shared Adaptive Card date parse/format helpers"
```

---

### Task 2: Fix AdaptiveDateInput local state sync (TDD — tests first)

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/date.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/inputs/date_edgecases_test.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/inputs/init_data_overlay_test.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/inputs/date_input_test.dart`

All widget tests and assertion updates below (Steps 1a–1d) are done **before** editing `date.dart` so the targeted cases go red, then green after Step 3.

- [x] **Step 1: Write failing widget tests**

**1a.** Add to `date_edgecases_test.dart` — empty controller (not placeholder):

```dart
testWidgets('DateInput empty state keeps controller empty (placeholder via hintText)', (
  WidgetTester tester,
) async {
  final Map<String, dynamic> map = {
    'type': 'AdaptiveCard',
    'body': [
      {
        'type': 'Input.Date',
        'id': 'emptyDate',
        'label': 'Date',
        'placeholder': 'Pick a date',
      },
    ],
  };

  await tester.pumpWidget(
    getTestWidgetFromMap(map: map, title: 'Date empty controller'),
  );
  await tester.pumpAndSettle();

  final dateMap = map['body'][0] as Map<String, dynamic>;
  final field = tester.widget<TextFormField>(
    find.byKey(generateWidgetKey(dateMap)),
  );

  expect(field.controller!.text, isEmpty);
  expect(field.decoration!.hintText, 'Pick a date');

  final state = tester.state<AdaptiveDateInputState>(
    find.byType(AdaptiveDateInput),
  );
  expect(state.selectedDateTime, isNull);

  final out = <String, dynamic>{};
  state.appendInput(out);
  expect(out.containsKey('emptyDate'), isFalse);
});
```

**1b.** Add to `date_edgecases_test.dart` — required validation must fail when no real date:

```dart
testWidgets('DateInput required validation fails when only placeholder would show', (
  WidgetTester tester,
) async {
  final Map<String, dynamic> map = {
    'type': 'AdaptiveCard',
    'body': [
      {
        'type': 'Input.Date',
        'id': 'reqDate',
        'label': 'Required Date',
        'isRequired': true,
        'placeholder': 'Pick a date',
      },
    ],
  };

  await tester.pumpWidget(
    getTestWidgetFromMap(map: map, title: 'Date required validation'),
  );
  await tester.pumpAndSettle();

  final state = tester.state<AdaptiveDateInputState>(
    find.byType(AdaptiveDateInput),
  );
  expect(state.checkRequired(), isFalse);
});
```

**1c.** Add to `init_data_overlay_test.dart` — overlay parity with Text/Toggle (mirrors Widgetbook `bookingdate`).

Add this import at the **top** of the file (with the other imports):

```dart
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/date.dart';
```

Add these tests in `main()`:

```dart
testWidgets('initData seeds date overlay visible in resolvedElementProvider', (
  WidgetTester tester,
) async {
  final Map<String, dynamic> map = {
    'type': 'AdaptiveCard',
    'body': [
      {
        'type': 'Input.Date',
        'id': 'bookingdate',
        'label': 'Booking Date',
        'placeholder': 'Enter your booking date',
      },
    ],
  };

  await tester.pumpWidget(
    getTestWidgetFromMap(
      map: map,
      title: 'initData date overlay',
      initData: const {'bookingdate': '2023-05-08'},
    ),
  );
  await tester.pumpAndSettle();

  final dateMap = map['body'][0] as Map<String, dynamic>;
  final inputFinder = find.byKey(generateWidgetKey(dateMap));
  final container = _documentContainer(tester, inputFinder);

  expect(
    container.read(resolvedElementProvider('bookingdate'))?['value'],
    '2023-05-08',
  );

  final field = tester.widget<TextFormField>(inputFinder);
  expect(field.controller!.text, '2023-05-08');

  final state = tester.state<AdaptiveDateInputState>(
    find.byType(AdaptiveDateInput),
  );
  expect(state.selectedDateTime, isNotNull);
  expect(state.selectedDateTime!.year, 2023);
  expect(state.selectedDateTime!.month, 5);
  expect(state.selectedDateTime!.day, 8);

  final out = <String, dynamic>{};
  state.appendInput(out);
  expect(out['bookingdate'], '2023-05-08');
});

testWidgets('programmatic initInput updates date field after mount', (
  WidgetTester tester,
) async {
  final Map<String, dynamic> map = {
    'type': 'AdaptiveCard',
    'body': [
      {
        'type': 'Input.Date',
        'id': 'lateDate',
        'label': 'Late',
      },
    ],
  };

  await tester.pumpWidget(
    getTestWidgetFromMap(map: map, title: 'programmatic initInput date'),
  );
  await tester.pumpAndSettle();

  _cardState(tester).initInput({'lateDate': '2024-06-15'});
  await tester.pumpAndSettle();

  final dateMap = map['body'][0] as Map<String, dynamic>;
  final inputFinder = find.byKey(generateWidgetKey(dateMap));
  final container = _documentContainer(tester, inputFinder);

  expect(
    container.read(resolvedElementProvider('lateDate'))?['value'],
    '2024-06-15',
  );

  final field = tester.widget<TextFormField>(inputFinder);
  expect(field.controller!.text, '2024-06-15');

  final state = tester.state<AdaptiveDateInputState>(
    find.byType(AdaptiveDateInput),
  );
  expect(state.selectedDateTime, isNotNull);
});
```

**1d.** Tighten existing assertions so they fail before the fix (same Step 1, before editing `date.dart`):

In `date_edgecases_test.dart`, rename the appendInput test and change the assertion:

```dart
testWidgets(
  'DateInput appendInput returns yyyy-MM-dd when a date is selected',
  (WidgetTester tester) async {
    // ... existing setup unchanged ...
    expect(out['initDate'], '2025-01-15');
  },
);
```

In `date_input_test.dart`, change the appendInput assertion from `startsWith` to exact match:

```dart
expect(out['initDate'], '2024-01-02');
```

- [x] **Step 2: Run tests to verify they fail**

Run:

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test \
  test/inputs/date_edgecases_test.dart \
  test/inputs/init_data_overlay_test.dart \
  test/inputs/date_input_test.dart
```

Expected failures **before** the fix:

| Test                                         | Expected                                                                   |
| -------------------------------------------- | -------------------------------------------------------------------------- |
| 1a empty controller                          | **FAIL** — `controller.text` is placeholder, not `''`                      |
| 1b required validation                       | **FAIL** — `checkRequired()` returns `true` (placeholder passes validator) |
| 1c initData overlay — `appendInput`          | **FAIL** — emits ISO-8601, not `'2023-05-08'`                              |
| 1c initData overlay — `selectedDateTime`     | May **FAIL** if placeholder path left `selectedDateTime` null              |
| 1d `date_input_test` / edgecases appendInput | **FAIL** — ISO-8601 vs exact `yyyy-MM-dd`                                  |

- [x] **Step 3: Update `date.dart`**

Changes:

1. Import `date_input_utils.dart`.
2. **Keep** the existing `inputFormat` field for `min` / `max` parsing in `initState` only (card JSON attributes are always `yyyy-MM-dd` per spec). Use `parseAdaptiveDateValue` / `formatAdaptiveDateValue` everywhere else (display, overlay sync, submit, picker commit).
3. In `onDocumentValueChanged`:
   - On empty/null: set `selectedDateTime = null`, `controller.text = ''` (never placeholder).
   - On valid value: parse with `parseAdaptiveDateValue`, set `selectedDateTime`, format controller.
   - Wrap mutations in `setState(() { ... })` (mirror `time.dart`).
4. In `appendInput`: emit `formatAdaptiveDateValue(selectedDateTime!)` instead of `toIso8601String()`.
5. In `onTap` after picker: always format with `formatAdaptiveDateValue`; write `yyyy-MM-dd` into overlay and host callbacks (never placeholder).

```dart
@override
void onDocumentValueChanged(Object? valueFromDocument) {
  final parsed = parseAdaptiveDateValue(valueFromDocument);
  if (parsed == null) {
    if (selectedDateTime == null && controller.text.isEmpty) return;
    setState(() {
      selectedDateTime = null;
      controller.text = '';
    });
    return;
  }
  final formatted = formatAdaptiveDateValue(parsed);
  if (selectedDateTime?.year == parsed.year &&
      selectedDateTime?.month == parsed.month &&
      selectedDateTime?.day == parsed.day &&
      controller.text == formatted) {
    return;
  }
  setState(() {
    selectedDateTime = parsed;
    controller.text = formatted;
  });
}

@override
void appendInput(Map map) {
  if (selectedDateTime != null) {
    map[id] = formatAdaptiveDateValue(selectedDateTime!);
  }
}

// Inside onTap, after result != null:
setState(() {
  selectedDateTime = result;
  controller.text = formatAdaptiveDateValue(result);
});
final formatted = formatAdaptiveDateValue(result);
setDocumentInputValue(formatted);
rawRootCardWidgetState.changeValue(id, formatted);
notifyUserInputValueChanged(formatted, committed: true);
```

- [x] **Step 4: Run tests to verify they pass**

Run:

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test \
  test/inputs/date_edgecases_test.dart \
  test/inputs/init_data_overlay_test.dart \
  test/inputs/date_input_test.dart
```

Expected: All PASS

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/date.dart \
        packages/flutter_adaptive_cards_fs/test/inputs/date_edgecases_test.dart \
        packages/flutter_adaptive_cards_fs/test/inputs/init_data_overlay_test.dart \
        packages/flutter_adaptive_cards_fs/test/inputs/date_input_test.dart
git commit -m "fix: sync Input.Date controller from initData without placeholder bleed"
```

---

### Task 3: Widgetbook FAQ regression check and docs

**Files:**

- `packages/flutter_adaptive_cards_fs/README.md`
- `packages/flutter_adaptive_cards_fs/CHANGELOG.md`
- `docs/Implementation-Status.md`

- [x] **Step 1: Run widgetbook or integration smoke**

Run Widgetbook locally and open **Forms → Form with initData**. Confirm `Booking Date` shows `2023-05-08`, not placeholder text.

Alternative without Widgetbook UI:

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test \
  test/inputs/init_data_overlay_test.dart \
  test/inputs/date_input_test.dart \
  test/inputs/date_edgecases_test.dart \
  test/inputs/date_picker_integration_test.dart
```

Expected: All PASS

- [x] **Step 2: Update docs and changelog**

**README** — remove or strike through:

> `initData` does not appear to be working on date fields.

Add one line under the seeding section:

> `Input.Date` accepts `yyyy-MM-dd` or ISO-8601 datetimes in `initData`. Datetime values use the calendar date portion only; time and timezone are ignored. Display and submit use `yyyy-MM-dd`.

**CHANGELOG** — the file has no `[Unreleased]` section today (latest is `[0.10.0]`). Add a new `## [Unreleased]` heading **above** `[0.10.0]`, then:

```markdown
## [Unreleased]

### Fixed

- `Input.Date` `initData` / `initInput` seeding: controller no longer receives placeholder text; submit and overlay values use `yyyy-MM-dd` per spec. Hosts that relied on ISO-8601 in `onChange` callbacks should expect `yyyy-MM-dd` instead.
```

**Implementation-Status** — add a one-line note under Inputs that initData seeding for `Input.Date` is fixed (no status emoji change).

```bash
git add packages/flutter_adaptive_cards_fs/README.md \
        packages/flutter_adaptive_cards_fs/CHANGELOG.md \
        docs/Implementation-Status.md
git commit -m "docs: mark Input.Date initData seeding as fixed"
```

---

## Verification (full suite)

```bash
cd packages/flutter_adaptive_cards_fs
fvm dart format lib/src/utils/date_input_utils.dart lib/src/cards/inputs/date.dart
fvm flutter analyze
fvm flutter test test/utils/date_input_utils_test.dart \
  test/inputs/date_input_test.dart \
  test/inputs/date_edgecases_test.dart \
  test/inputs/init_data_overlay_test.dart \
  test/inputs/date_picker_integration_test.dart \
  test/inputs/date_picker_interactive_test.dart
```

Expected: no analyzer errors; all listed tests PASS.

---

## Out of scope

- Locale-aware date **display** in the picker field (separate README item: "Inject locale behavior into money, time and dates").
- `Input.Time` initData changes (already works; only align if same placeholder-in-controller pattern exists — verify separately).
- Changing `initData` seed timing in `_AdaptiveCardDocumentLifecycle` (not required once Date widget sync is correct).
- Overlay assertion after picker in `date_picker_integration_test.dart` (optional follow-up: assert `resolvedElementProvider` holds `yyyy-MM-dd` after OK).
