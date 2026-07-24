# FactSet Facts Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Status:** **Implemented** (shipped in **0.10.0**). `setFacts`/`clearFacts`, reactive `AdaptiveFactSet`, Widgetbook knob demo. Checkboxes marked complete; do not re-implement.

**Goal:** Enable runtime replacement of a `FactSet`'s `facts` array via Riverpod document overlays (full list replacement at FactSet id), reactive `AdaptiveFactSet` rendering, host APIs, tests, docs, and a Widgetbook knob demo.

**Architecture:** Store `List<Fact>?` on `ElementOverlay` (mirrors `choices`). Merge to resolved JSON in `resolvedElementProvider` via `factsToJsonList`. `AdaptiveFactSet` subscribes to `resolvedElementProvider(id)` like `AdaptiveTextBlock` does for `text`. Widgetbook demo calls `setFacts` / `clearFacts` from a non-nullable `object.dropdown` knob with a `baseline` enum preset and `_syncPresetKnob` (change-only apply lifecycle).

**Tech Stack:** Dart 3.12+, Flutter (FVM), `flutter_adaptive_cards_fs`, Riverpod 3.x, `package:flutter_test`, Widgetbook 3.22+, `very_good_analysis`.

**Spec:** [`docs/superpowers/specs/2026-06-06-factset-facts-overlay-design.md`](../specs/2026-06-06-factset-facts-overlay-design.md)

---

## File map

| File                                                                                         | Role                                            |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `packages/flutter_adaptive_cards_fs/lib/src/models/fact.dart`                                | Add `factsToJsonList`                           |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart`            | `ElementOverlay.facts` + `copyWith(clearFacts)` |
| `packages/flutter_adaptive_cards_fs/lib/src/models/adaptive_card_update.dart`                | `AdaptiveElementUpdate.facts` / `clearFacts`    |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart`   | `setFacts`, `clearFacts`, merge + patch parsing |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`                         | Resolved merge for `facts`                      |
| `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`                  | Host `setFacts` / `clearFacts` delegates        |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/fact_set.dart`                  | Reactive facts listener                         |
| `packages/flutter_adaptive_cards_fs/test/models/fact_test.dart`                              | `factsToJsonList` test                          |
| `packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart` | Notifier tests                                  |
| `packages/flutter_adaptive_cards_fs/test/containers/fact_set_overlay_test.dart`              | Widget tests (new)                              |
| `widgetbook/lib/fact_set_overlay_page.dart`                                                  | Knob demo page (new)                            |
| `widgetbook/lib/samples/fact_set/facts_overlay_demo.json`                                    | Demo card JSON (new)                            |
| `widgetbook/lib/adaptive_cards_use_cases.dart`                                               | Register use case                               |
| `docs/reactive-riverpod.md`                                                                  | Overlay docs                                    |
| `packages/flutter_adaptive_cards_fs/README.md`                                               | Host API table                                  |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md`                                            | Unreleased entry                                |

---

### Task 1: `factsToJsonList` helper

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/fact.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/models/fact_test.dart`

- [x] **Step 1: Write failing test**

Add to `fact_test.dart` inside the `Fact` group:

```dart
test('factsToJsonList round-trips', () {
  const facts = [
    Fact(title: 'Red', value: '#FF0000'),
    Fact(title: 'Blue', value: '#0000FF'),
  ];
  final json = factsToJsonList(facts);
  expect(factsFromJsonList(json), facts);
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/models/fact_test.dart --name "factsToJsonList"`

Expected: FAIL — `factsToJsonList` not defined

- [x] **Step 3: Implement helper**

Add after `factsFromJsonList` in `fact.dart`:

```dart
/// Serializes [facts] for resolved element JSON merge boundaries.
List<Map<String, dynamic>> factsToJsonList(List<Fact> facts) =>
    facts.map((f) => f.toJson()).toList();
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/models/fact_test.dart`

Expected: PASS

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/fact.dart \
        packages/flutter_adaptive_cards_fs/test/models/fact_test.dart
git commit -m "feat: add factsToJsonList helper for overlay merge"
```

---

### Task 2: Overlay model fields

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/adaptive_card_update.dart`

- [x] **Step 1: Extend `ElementOverlay`**

In `adaptive_card_document.dart`:

1. Add import: `import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';`
2. Add field to constructor and class:

```dart
/// Overrides baseline `"facts"` on `FactSet` when non-null.
final List<Fact>? facts;
```

1. Extend `copyWith`:

```dart
List<Fact>? facts,
bool clearFacts = false,
```

1. In `copyWith` body:

```dart
facts: clearFacts ? null : (facts ?? this.facts),
```

- [x] **Step 2: Extend `AdaptiveElementUpdate`**

In `adaptive_card_update.dart`:

1. Add import for `Fact`.
2. Add constructor params and fields:

```dart
this.facts,
this.clearFacts = false,
```

```dart
/// Replaces `FactSet` `"facts"`.
final List<Fact>? facts;

/// Clears the `facts` overlay.
final bool clearFacts;
```

- [x] **Step 3: Run analyzer**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter analyze lib/src/riverpod/adaptive_card_document.dart lib/src/models/adaptive_card_update.dart`

Expected: no errors (tests may not compile until Task 3)

- [x] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart \
        packages/flutter_adaptive_cards_fs/lib/src/models/adaptive_card_update.dart
git commit -m "feat: add facts field to ElementOverlay and AdaptiveElementUpdate"
```

---

### Task 3: Notifier — `setFacts`, `clearFacts`, merge, patch map

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart`

- [x] **Step 1: Write failing notifier tests**

Add import: `import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';`

Add helper near other baseline card helpers:

```dart
Map<String, dynamic> baselineCardWithFactSetId(String factSetId) {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'FactSet',
        'id': factSetId,
        'facts': [
          {'title': 'Baseline A', 'value': '1'},
          {'title': 'Baseline B', 'value': '2'},
        ],
      },
    ],
  };
}
```

Add tests in a new nested `group('facts overlay', () { ... })` using `_createContainer(baselineCardWithFactSetId('summary'))` and local `setUp`/`tearDown` (same pattern as the `text overlay` group ~line 591):

```dart
group('facts overlay', () {
  late ProviderContainer factContainer;

  setUp(() {
    factContainer = _createContainer(baselineCardWithFactSetId('summary'));
  });

  tearDown(() {
    factContainer.dispose();
  });

  test('setFacts stores List<Fact> in overlay', () {
    factContainer.read(adaptiveCardDocumentProvider.notifier).setFacts(
          'summary',
          const [
            Fact(title: 'Status', value: 'Shipped'),
          ],
        );

    final overlay =
        factContainer.read(adaptiveCardDocumentProvider).overlaysById['summary'];
    expect(overlay?.facts, isA<List<Fact>>());
    expect(overlay!.facts!.first.value, 'Shipped');
  });

  test('setFacts merges into resolvedElementProvider', () {
    factContainer.read(adaptiveCardDocumentProvider.notifier).setFacts(
          'summary',
          const [Fact(title: 'Status', value: 'Shipped')],
        );

    final resolved = factContainer.read(resolvedElementProvider('summary'));
    final facts = resolved?['facts'] as List<dynamic>?;
    expect(facts, hasLength(1));
    expect(facts!.first['title'], 'Status');
  });

  test('clearFacts restores baseline facts', () {
    final notifier = factContainer.read(adaptiveCardDocumentProvider.notifier)
      ..setFacts('summary', const [Fact(title: 'Overlay', value: 'x')])
      ..clearFacts('summary');

    expect(notifier.state.overlaysById['summary']?.facts, isNull);

    final resolved = factContainer.read(resolvedElementProvider('summary'));
    final facts = resolved?['facts'] as List<dynamic>?;
    expect(facts, hasLength(2));
    expect(facts!.first['title'], 'Baseline A');
  });

  test('applyUpdates clearFacts flag clears overlay', () {
    final notifier = factContainer.read(adaptiveCardDocumentProvider.notifier)
      ..setFacts('summary', const [Fact(title: 'Overlay', value: 'x')])
      ..applyUpdates(
        elements: [
          const AdaptiveElementUpdate(id: 'summary', clearFacts: true),
        ],
      );

    expect(notifier.state.overlaysById['summary']?.facts, isNull);
  });
});
```

Add standalone test outside the group for patch-map parsing (static method, no container):

```dart
test('updatesFromPatchMap parses facts array', () {
  final parsed = AdaptiveCardDocumentNotifier.updatesFromPatchMapWithNodes(
    {
      'summary': {
        'facts': [
          {'title': 'Red', 'value': '#FF0000'},
        ],
      },
    },
    nodesById: {
      'summary': {'type': 'FactSet', 'id': 'summary', 'facts': []},
    },
  );
  expect(parsed.elements.single.facts, [
    const Fact(title: 'Red', value: '#FF0000'),
  ]);
});
```

- [x] **Step 2: Run tests to verify they fail**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart --name "facts overlay"`

Expected: FAIL — `setFacts` / `clearFacts` not defined

- [x] **Step 3: Implement notifier methods**

Add import for `fact.dart` if not present.

Add static helper (mirror `_choicesFromPatch`):

```dart
static List<Fact>? _factsFromPatch(Object? raw) {
  if (raw is! List) return null;
  return factsFromJsonList(raw);
}
```

Add public methods after `clearText`:

```dart
/// Replaces effective `"facts"` for `FactSet` [id].
void setFacts(String id, List<Fact> facts) {
  _updateOverlay(
    id,
    (current) => (current ?? const ElementOverlay()).copyWith(facts: facts),
  );
}

/// Clears facts overlay for [id]; effective facts revert to baseline JSON.
void clearFacts(String id) {
  _updateOverlay(
    id,
    (current) => (current ?? const ElementOverlay()).copyWith(clearFacts: true),
  );
}
```

In `_mergeElementUpdate`, after `clearPlaceholder` block add:

```dart
if (update.clearFacts) {
  overlay = overlay.copyWith(clearFacts: true);
}
```

Before `if (update.choices != null)` add:

```dart
if (update.facts != null) {
  overlay = overlay.copyWith(facts: update.facts);
}
```

In `updatesFromPatchMapWithNodes` element branch, add to `AdaptiveElementUpdate(...)`:

```dart
facts: _factsFromPatch(patch['facts']),
clearFacts: patch['clearFacts'] == true,
```

- [x] **Step 4: Run tests to verify they pass**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart --name "facts overlay"`

Expected: PASS

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart \
        packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart
git commit -m "feat: add setFacts and clearFacts to document notifier"
```

---

### Task 4: Resolved merge in `providers.dart`

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`

- [x] **Step 1: Add merge**

Add import: `import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';`

After the `choices` merge block:

```dart
if (overlay?.facts != null) {
  merged['facts'] = factsToJsonList(overlay!.facts!);
}
```

- [x] **Step 2: Run notifier tests (resolved merge covered)**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart --name "setFacts merges"`

Expected: PASS

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart
git commit -m "feat: merge facts overlay in resolvedElementProvider"
```

---

### Task 5: Host API on `RawAdaptiveCardState`

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`

- [x] **Step 1: Add delegates**

Add import for `Fact` model if not re-exported via main barrel (use `src/models/fact.dart` or public export).

After `clearText`:

```dart
/// Replaces effective `"facts"` for `FactSet` [id].
void setFacts(String id, List<Fact> facts) {
  final container = documentContainer;
  if (container == null) return;
  container.read(adaptiveCardDocumentProvider.notifier).setFacts(id, facts);
}

/// Clears facts overlay for [id].
void clearFacts(String id) {
  final container = documentContainer;
  if (container == null) return;
  container.read(adaptiveCardDocumentProvider.notifier).clearFacts(id);
}
```

- [x] **Step 2: Run analyzer**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter analyze lib/src/flutter_raw_adaptive_card.dart`

Expected: no errors

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart
git commit -m "feat: expose setFacts and clearFacts on RawAdaptiveCardState"
```

---

### Task 6: Reactive `AdaptiveFactSet`

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/fact_set.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/containers/fact_set_overlay_test.dart` (created in Task 7 — run widget test after both tasks)

- [x] **Step 1: Refactor widget**

Add imports:

```dart
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

Replace `initState` facts parsing with empty list init:

```dart
List<Fact> facts = const [];

ProviderSubscription<Map<String, dynamic>?>? _factsSubscription;
```

Remove facts assignment from `initState` (keep `super.initState()` only).

In `didChangeDependencies`, after `super.didChangeDependencies()` and existing `backgroundColor` logic, add subscription (mirror `AdaptiveTextBlock`):

```dart
_factsSubscription?.close();
final container = ProviderScope.containerOf(context);
_factsSubscription = container.listen<Map<String, dynamic>?>(
  resolvedElementProvider(id),
  (previous, next) {
    if (next == null) return;
    final nextFacts = factsFromJsonList(next['facts']);
    if (listEquals(nextFacts, facts)) return;
    setState(() => facts = nextFacts);
  },
  fireImmediately: true,
);
```

Add `import 'package:flutter/foundation.dart';` for `listEquals`.

In `dispose`:

```dart
_factsSubscription?.close();
_factsSubscription = null;
super.dispose();
```

Ensure `dispose` override exists (add if missing).

- [x] **Step 2: Run analyzer**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter analyze lib/src/cards/containers/fact_set.dart`

Expected: no errors

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/containers/fact_set.dart
git commit -m "feat: watch resolved facts in AdaptiveFactSet"
```

---

### Task 7: Widget tests for FactSet overlay

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/test/containers/fact_set_overlay_test.dart`

- [x] **Step 1: Write widget tests**

```dart
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Map<String, dynamic> factSetOverlayTestCard() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'FactSet',
        'id': 'demoFactSet',
        'facts': [
          {'title': 'Fact 1', 'value': 'Value 1'},
          {'title': 'Fact 2', 'value': 'Value 2'},
        ],
      },
    ],
  };
}

void main() {
  testWidgets('setFacts replaces FactSet UI via overlay', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: factSetOverlayTestCard(),
        title: 'FactSet overlay test',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fact 1'), findsOneWidget);
    expect(find.text('Red'), findsNothing);

    _cardState(tester).setFacts('demoFactSet', const [
      Fact(title: 'Red', value: '#FF0000'),
      Fact(title: 'Blue', value: '#0000FF'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Fact 1'), findsNothing);
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('#FF0000'), findsOneWidget);
  });

  testWidgets('clearFacts restores baseline FactSet UI', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: factSetOverlayTestCard(),
        title: 'FactSet clearFacts test',
      ),
    );
    await tester.pumpAndSettle();

    _cardState(tester).setFacts('demoFactSet', const [
      Fact(title: 'Red', value: '#FF0000'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Red'), findsOneWidget);

    _cardState(tester).clearFacts('demoFactSet');
    await tester.pumpAndSettle();

    expect(find.text('Red'), findsNothing);
    expect(find.text('Fact 1'), findsOneWidget);
    expect(find.text('Value 1'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run widget tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/containers/fact_set_overlay_test.dart`

Expected: PASS (requires Tasks 3–6 complete)

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/test/containers/fact_set_overlay_test.dart
git commit -m "test: FactSet overlay widget tests for setFacts and clearFacts"
```

---

### Task 8: Widgetbook demo

**Files:**

- Create: `widgetbook/lib/samples/fact_set/facts_overlay_demo.json`
- Create: `widgetbook/lib/fact_set_overlay_page.dart`
- Modify: `widgetbook/lib/adaptive_cards_use_cases.dart`

- [x] **Step 1: Add demo JSON**

Create `widgetbook/lib/samples/fact_set/facts_overlay_demo.json`:

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.5",
  "body": [
    {
      "type": "TextBlock",
      "text": "FactSet facts overlay",
      "weight": "Bolder",
      "size": "Medium",
      "wrap": true
    },
    {
      "type": "TextBlock",
      "text": "Use the knob to replace facts at runtime or clear the overlay.",
      "isSubtle": true,
      "wrap": true,
      "spacing": "Small"
    },
    {
      "type": "FactSet",
      "id": "demoFactSet",
      "spacing": "Medium",
      "facts": [
        { "title": "Fact 1", "value": "Value 1" },
        { "title": "Fact 2", "value": "Value 2" },
        { "title": "Fact 3", "value": "Value 3" },
        { "title": "Fact 4", "value": "Value 4" }
      ]
    }
  ]
}
```

- [x] **Step 2: Create overlay page**

Create `widgetbook/lib/fact_set_overlay_page.dart` following `text_block_overlay_page.dart` overlay-queue patterns, with `_syncPresetKnob` so preset overlays apply only on knob **change** (not every Widgetbook rebuild). Uses `object.dropdown` with an explicit `baseline` enum value instead of `objectOrNull`:

```dart
// Host-only demo: calls [RawAdaptiveCardState.setFacts] on the rendered card.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:widgetbook/widgetbook.dart';

enum FactSetOverlayPreset { baseline, colors, cities, foods }

const _factSetId = 'demoFactSet';

const _colorsFacts = [
  Fact(title: 'Red', value: '#FF0000'),
  Fact(title: 'Blue', value: '#0000FF'),
  Fact(title: 'Green', value: '#00FF00'),
  Fact(title: 'Yellow', value: '#FFFF00'),
];

const _citiesFacts = [
  Fact(title: 'New York', value: 'USA'),
  Fact(title: 'Paris', value: 'France'),
  Fact(title: 'Tokyo', value: 'Japan'),
  Fact(title: 'Sydney', value: 'Australia'),
];

const _foodsFacts = [
  Fact(title: 'Pizza', value: 'Italy'),
  Fact(title: 'Sushi', value: 'Japan'),
  Fact(title: 'Tacos', value: 'Mexico'),
  Fact(title: 'Pasta', value: 'Italy'),
];

List<Fact>? factsForPreset(FactSetOverlayPreset preset) {
  return switch (preset) {
    FactSetOverlayPreset.baseline => null,
    FactSetOverlayPreset.colors => _colorsFacts,
    FactSetOverlayPreset.cities => _citiesFacts,
    FactSetOverlayPreset.foods => _foodsFacts,
  };
}

final factSetOverlayPageKey = GlobalKey<State<FactSetOverlayPage>>();

class FactSetOverlayPage extends StatefulWidget {
  const FactSetOverlayPage({super.key});

  @override
  State<FactSetOverlayPage> createState() => _FactSetOverlayPageState();
}

class _FactSetOverlayPageState extends State<FactSetOverlayPage> {
  static const _assetPath = 'lib/samples/fact_set/facts_overlay_demo.json';
  static const _maxApplyAttempts = 30;

  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();
  late final CardTypeRegistry _cardTypeRegistry = CardTypeRegistry(
    addedElements: CardChartsRegistry.additionalChartElements,
  );

  Map<String, dynamic>? _cardMap;
  FactSetOverlayPreset? _lastAppliedPreset;
  FactSetOverlayPreset? _pendingPreset;
  FactSetOverlayPreset? _lastSeenPresetKnob;
  bool _knobsInitialized = false;
  int _applyAttempts = 0;
  bool _applyScheduled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCard());
  }

  Future<void> _loadCard() async {
    final json = await rootBundle.loadString(_assetPath);
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() => _cardMap = map);
  }

  void _queueFactsOverlay(FactSetOverlayPreset preset) {
    _pendingPreset = preset;
    if (_lastAppliedPreset == preset) return;
    _scheduleApplyOverlay();
  }

  void _scheduleApplyOverlay() {
    if (_applyScheduled) return;
    _applyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyScheduled = false;
      _flushPendingOverlay();
    });
  }

  void _flushPendingOverlay() {
    final preset = _pendingPreset;
    if (!mounted || _cardMap == null || preset == null) return;

    final cardState = _cardKey.currentState;
    if (cardState == null || cardState.documentContainer == null) {
      if (_applyAttempts < _maxApplyAttempts) {
        _applyAttempts++;
        _scheduleApplyOverlay();
      }
      return;
    }

    _applyAttempts = 0;
    if (_lastAppliedPreset == preset) return;

    if (preset == FactSetOverlayPreset.baseline) {
      cardState.clearFacts(_factSetId);
    } else {
      cardState.setFacts(_factSetId, factsForPreset(preset)!);
    }
    _lastAppliedPreset = preset;
  }

  void _syncPresetKnob(FactSetOverlayPreset preset) {
    if (!_knobsInitialized) {
      _knobsInitialized = true;
      _lastSeenPresetKnob = preset;
      return;
    }

    if (preset == _lastSeenPresetKnob) return;
    _lastSeenPresetKnob = preset;
    _queueFactsOverlay(preset);
  }

  @override
  Widget build(BuildContext context) {
    final preset = context.knobs.object.dropdown<FactSetOverlayPreset>(
      label: 'Baseline restores to preset',
      options: FactSetOverlayPreset.values,
      initialOption: FactSetOverlayPreset.baseline,
      labelBuilder: (value) => switch (value) {
        FactSetOverlayPreset.baseline => 'Baseline',
        FactSetOverlayPreset.colors => 'Colors',
        FactSetOverlayPreset.cities => 'Cities',
        FactSetOverlayPreset.foods => 'Foods',
      },
    );
    _syncPresetKnob(preset);

    final cardMap = _cardMap;
    if (cardMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: RawAdaptiveCard.fromMap(
          key: _cardKey,
          map: cardMap,
          cardTypeRegistry: _cardTypeRegistry,
          hostConfigs: HostConfigs(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
```

**Knob behavior:**

| Knob value | Host action                             | Effective facts                 |
| ---------- | --------------------------------------- | ------------------------------- |
| `baseline` | `clearFacts('demoFactSet')`             | Baseline JSON (4 generic facts) |
| `colors`   | `setFacts('demoFactSet', _colorsFacts)` | 4 color facts                   |
| `cities`   | `setFacts('demoFactSet', _citiesFacts)` | 4 city facts                    |
| `foods`    | `setFacts('demoFactSet', _foodsFacts)`  | 4 food facts                    |

- [x] **Step 3: Register use case**

In `widgetbook/lib/adaptive_cards_use_cases.dart`:

1. Add import: `import 'package:widgetbook_workspace/fact_set_overlay_page.dart';`
2. After `buildFactSetExample1`, add:

```dart
@widgetbook.UseCase(
  name: 'Facts overlay (knob)',
  type: widget_types.FactSet,
  path: '[Components]',
)
Widget buildFactSetFactsOverlay(BuildContext context) {
  return FactSetOverlayPage(key: factSetOverlayPageKey);
}
```

- [x] **Step 4: Regenerate Widgetbook directories**

Run: `cd widgetbook && fvm dart run build_runner build --delete-conflicting-outputs`

Expected: `main.directories.g.dart` updated with new use case

- [x] **Step 5: Run analyzer on widgetbook**

Run: `cd widgetbook && fvm flutter analyze`

Expected: no errors

- [x] **Step 6: Commit**

```bash
git add widgetbook/lib/fact_set_overlay_page.dart \
        widgetbook/lib/samples/fact_set/facts_overlay_demo.json \
        widgetbook/lib/adaptive_cards_use_cases.dart \
        widgetbook/lib/main.directories.g.dart
git commit -m "feat(widgetbook): FactSet facts overlay knob demo"
```

---

### Task 9: Documentation and changelog

**Files:**

- Modify: `docs/reactive-riverpod.md`
- Modify: `packages/flutter_adaptive_cards_fs/README.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [x] **Step 1: Update `reactive-riverpod.md`**

In the overlay field list / merge rules section, add:

- `facts` — overrides baseline `"facts"` on `FactSet`
- `clearFacts` via `AdaptiveElementUpdate` or patch `{ clearFacts: true }`

In the runtime-writes table, add row:

| Replace FactSet facts | `setFacts(id, facts)` / `clearFacts(id)` / `applyUpdates` | `facts` |

Reference Widgetbook **FactSet → Facts overlay (knob)** for manual verification.

- [x] **Step 2: Update README host API table**

Add:

| `setFacts(id, facts)` / `clearFacts(id)` | Replace or clear `FactSet` facts overlay |

- [x] **Step 3: Update CHANGELOG**

Under unreleased / current version section:

```markdown
### Added

- Runtime **`facts`** overlay on `FactSet` elements (`setFacts`, `clearFacts`, `applyUpdates` / `applyUpdatesFromMap`).
- Widgetbook **FactSet → Facts overlay (knob)** demo for interactive overlay testing.
```

- [x] **Step 4: Commit**

```bash
git add docs/reactive-riverpod.md \
        packages/flutter_adaptive_cards_fs/README.md \
        packages/flutter_adaptive_cards_fs/CHANGELOG.md
git commit -m "docs: document FactSet facts overlay APIs"
```

---

### Task 10: Full verification

- [x] **Step 1: Format**

Run: `cd packages/flutter_adaptive_cards_fs && fvm dart format lib/ test/`

Run: `cd widgetbook && fvm dart format lib/`

- [x] **Step 2: Analyze**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter analyze`

Expected: no issues

- [x] **Step 3: Test suite (non-golden)**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`

Expected: all PASS

- [x] **Step 4: Manual Widgetbook check**

Run: `cd widgetbook && fvm flutter run -d macos` (or available device)

Verify:

1. **FactSet → Facts overlay (knob)** shows 4 baseline facts
2. **Colors** / **Cities** / **Foods** each show 4 replacement facts
3. **Baseline** restores JSON facts (clears overlay)

---

## Spec coverage (self-review)

| Spec requirement                             | Task   |
| -------------------------------------------- | ------ |
| `List<Fact>?` on `ElementOverlay`            | Task 2 |
| `AdaptiveElementUpdate.facts` / `clearFacts` | Task 2 |
| `factsToJsonList`                            | Task 1 |
| `setFacts` / `clearFacts` notifier           | Task 3 |
| `applyUpdates` / patch map                   | Task 3 |
| `resolvedElementProvider` merge              | Task 4 |
| `RawAdaptiveCardState` delegates             | Task 5 |
| Reactive `AdaptiveFactSet`                   | Task 6 |
| Notifier tests                               | Task 3 |
| Widget tests                                 | Task 7 |
| Widgetbook knob demo                         | Task 8 |
| Docs + changelog                             | Task 9 |

## Out of scope (unchanged)

- Per-fact sparse patches, `appendFacts`, fact-level visibility
- `resetAllInputs` clearing `facts` (explicitly not required per spec)
