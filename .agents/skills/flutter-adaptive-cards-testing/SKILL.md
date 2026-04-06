---
name: flutter-adaptive-cards-testing
description: >
  Testing patterns, utilities, and golden image workflows for the
  flutter_adaptive_cards_plus library. Use this before writing or modifying
  any test in packages/flutter_adaptive_cards_plus/test/.
---

# Flutter Adaptive Cards Testing Skill

## Overview

All library tests live under:
```
packages/flutter_adaptive_cards_plus/test/
```

Tests are run **from that package directory**, not the monorepo root:
```bash
cd packages/flutter_adaptive_cards_plus
flutter test                        # all tests
flutter test test/golden_sample_test.dart  # specific file
flutter test --tags golden          # only golden image tests
flutter test --update-goldens       # regenerate golden images
```

---

## Core Test Utilities — `test/utils/test_utils.dart`

Import this in every test file:
```dart
import 'utils/test_utils.dart';
```

### `getTestWidgetFromPath` — The Primary Test Helper

Loads an Adaptive Card JSON file from `test/samples/<path>` and returns a
fully-wrapped `MaterialApp` ready for `tester.pumpWidget()`.

```dart
Widget getTestWidgetFromPath({
  required String path,           // relative to test/samples/
  Key? key,                       // used for golden RepaintBoundary targeting
  Function(String)? onOpenUrl,
  Function(String)? onOpenUrlDialog,
  Function(Map<dynamic, dynamic>)? onSubmit,
  Function(Map<dynamic, dynamic>)? onExecute,
  Function(
    String id,
    dynamic value,
    DataQuery? dataQuery,
    RawAdaptiveCardState cardState,
  )? onChange,
})
```

**Usage — basic rendering:**
```dart
testWidgets('renders badge card', (tester) async {
  await tester.pumpWidget(getTestWidgetFromPath(path: 'badge_test.json'));
  await tester.pumpAndSettle();
  expect(find.byType(AdaptiveBadge), findsOneWidget);
});
```

**Usage — with action callbacks:**
```dart
testWidgets('calls onChange on input change', (tester) async {
  String? changedId;
  await tester.pumpWidget(
    getTestWidgetFromPath(
      path: 'inputs/text_input.json',
      onChange: (id, value, dataQuery, cardState) {
        changedId = id;
      },
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('myInput')), 'hello');
  expect(changedId, equals('myInput'));
});
```

### `getTestWidgetFromMap` — Build from a Map Directly

Use when you need to construct the JSON programmatically in the test:
```dart
final map = {'type': 'AdaptiveCard', 'version': '1.5', 'body': [...]};
await tester.pumpWidget(getTestWidgetFromMap(map: map, title: 'Test'));
```

### `getTestWidgetFromString` — Build from a JSON String

Use for small inline test cards:
```dart
const json = '{"type":"AdaptiveCard","version":"1.5","body":[...]}';
await tester.pumpWidget(getTestWidgetFromString(jsonString: json));
```

---

## Widget Key Generation

All Adaptive Card widgets use deterministic `ValueKey`s derived from the
element's `id` JSON property. Use these functions to locate widgets in tests:

```dart
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';

// Key for the StatefulWidget wrapper (outer layer):
ValueKey generateAdaptiveWidgetKey(Map adaptiveMap);
// Produces: ValueKey('${id}_adaptive')

// Key for the inner input/content widget:
ValueKey generateWidgetKey(Map adaptiveMap, {String? suffix});
// Produces: ValueKey('$id') or ValueKey('${id}_$suffix')

// Key from a known id string:
ValueKey generateWidgetKeyFromId(String id, {String? suffix});
```

**Finding a widget by ID in a test:**
```dart
// Given JSON id: "myTextField"
final inputFinder = find.byKey(const ValueKey('myTextField'));
final wrapperFinder = find.byKey(const ValueKey('myTextField_adaptive'));
```

---

## Test Configuration — `test/flutter_test_config.dart`

This file runs automatically before all tests. It:
1. Installs `MyTestHttpOverrides` to intercept all network image requests and
   return a transparent 1×1 PNG — **never make real network calls in tests**.
2. Loads Roboto and RobotoMono font assets from
   `assets/fonts/Roboto/` so golden images render consistently.

You do **not** need to set up fonts or HTTP overrides manually in test files.

---

## Golden Image Tests

### File Locations
- Test files: `test/golden_*_test.dart`, `test/v6_agenda_test.dart`
- Gold images: `test/gold_files/*.png`
- Sample JSON: `test/samples/*.json`

### Standard Golden Test Pattern

```dart
testWidgets('My Card Golden', (tester) async {
  // 1. Fix the viewport to a predictable size
  RendererBinding.instance.renderViews.first.configuration =
      TestViewConfiguration.fromView(
        size: const Size(500, 700),    // standard size used throughout
        view: PlatformDispatcher.instance.implicitView!,
      );

  // 2. A stable ValueKey to target the RepaintBoundary
  const key = ValueKey('paint');

  // 3. Load and pump
  await tester.pumpWidget(getTestWidgetFromPath(path: 'my_card.json', key: key));
  await tester.pumpAndSettle();

  // 4. Compare to golden
  await expectLater(
    find.byKey(key),
    matchesGoldenFile('gold_files/my_card-base.png'),
  );
}, tags: ['golden']);   // <-- always tag golden tests
```

### Updating Goldens

Only update goldens on **your development machine** (not CI), after verifying
the rendered output looks correct visually:
```bash
cd packages/flutter_adaptive_cards_plus
flutter test --update-goldens --tags golden
```

> **Warning:** Golden image pixels are platform-specific. macOS-generated
> goldens may not match Linux CI exactly. The project uses `dart_test.yaml`
> to manage this. Check `test/analysis_options.yaml` for any tag restrictions.

### Running Only Non-Golden Tests (Faster Iteration)
```bash
flutter test --exclude-tags golden
```

---

## Test Sample Files

Sample JSON cards live in `test/samples/`. Subdirectories organize by element
type (e.g., `test/samples/inputs/`, `test/samples/containers/`).

When adding a new test:
1. Create your JSON sample in the appropriate `test/samples/` subdirectory.
2. Validate it at [adaptivecards.io/designer](https://adaptivecards.io/designer/) first.
3. Reference it via `getTestWidgetFromPath(path: 'subdirectory/my_card.json')`.

---

## Running Tests for the Full Monorepo

From the repo root, run tests for all packages:
```bash
flutter test packages/flutter_adaptive_cards_plus
flutter test adaptive_explorer
flutter test widgetbook
```

Or run a single package's tests using the Dart MCP tool with the package root:
```
root: file:///path/to/Flutter-AdaptiveCards/packages/flutter_adaptive_cards_plus
```
