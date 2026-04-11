---
name: flutter-adaptive-cards-testing
description: >
  Testing patterns, utilities, and golden image workflows for the
  flutter_adaptive_cards_fs library. Use this before writing or modifying
  any test in packages/flutter_adaptive_cards_fs/test/.
---

# Flutter Adaptive Cards Testing Skill

## Overview

All library tests live under:

```
packages/flutter_adaptive_cards_fs/test/
```

Tests are run **from that package directory**, not the monorepo root:

```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter test                        # all tests
fvm flutter test test/golden_sample_test.dart  # specific file
fvm flutter test --tags golden          # only golden image tests
fvm flutter test --update-goldens       # regenerate golden images
```

---

## Key-First Testing (Mandatory)

To ensure tests are resilient to UI refactoring and font rendering differences, **always prioritize finding widgets by Key** over finding by text or type.

```dart
// [GOOD] Precise and stable
expect(find.byKey(const ValueKey('submitButton')), findsOneWidget);

// [AVOID] Brittle and easily broken by text changes
expect(find.text('Submit'), findsOneWidget);

// [AVOID] Ambiguous in large cards
expect(find.byType(ElevatedButton), findsOneWidget);
```

---

## Core Test Utilities — `test/utils/test_utils.dart`

Import this in every test file:

```dart
import 'utils/test_utils.dart';
```

### `getTestWidgetFromPath` — The Primary Test Helper

Loads an Adaptive Card JSON file from `test/samples/<path>` and returns a fully-wrapped `MaterialApp`.

**Architecture Note**: This helper automatically wraps the card in:

1.  **MaterialApp & Scaffold**: Providing necessary theme and layout context.
2.  **RepaintBoundary**: With an optional `key`, used to target specific regions for golden images.
3.  **InheritedAdaptiveCardHandlers**: Injects mock handlers for `onSubmit`, `onExecute`, `onChange`, etc., if provided as arguments.

```dart
Widget getTestWidgetFromPath({
  required String path,           // relative to test/samples/
  Key? key,                       // targets the RepaintBoundary for Goldens
  Function(String)? onOpenUrl,
  Function(Map<dynamic, dynamic>)? onSubmit,
  Function(Map<dynamic, dynamic>)? onExecute,
  Function(String id, dynamic value, DataQuery? query, RawAdaptiveCardState state)? onChange,
})
```

---

## Widget Key Generation Patterns

All widgets use deterministic `ValueKey`s. Use these patterns to locate them:

| Widget Type        | Key Path        | Example                                          |
| ------------------ | --------------- | ------------------------------------------------ |
| **Card Wrapper**   | `{id}_adaptive` | `find.byKey(const ValueKey('myField_adaptive'))` |
| **Input Content**  | `{id}`          | `find.byKey(const ValueKey('myField'))`          |
| **ChoiceSet Item** | `{id}_{value}`  | `find.byKey(const ValueKey('myChoice_red'))`     |
| **Modal Search**   | `{id}`          | Filtered ChoiceSet search fields use the same ID |

> **Utility Functions**: Use `generateAdaptiveWidgetKey(map)` for the wrapper and `generateWidgetKey(map)` for contents.

---

## Golden Image Tests

### Canonical Environment (Linux)

> [!WARNING]
> **Golden image pixels are platform-specific.** This project uses **Linux (CI)** as the ground truth for golden images.
>
> - **Updating Goldens**: Should primarily be done via CI or on a Linux environment.
> - **Local Verification**: macOS/Windows goldens may show subtle antialiasing differences. If a golden fails locally on Mac but passes on CI, the CI result is correct.

### Standard Golden Pattern

```dart
testWidgets('My Card Golden', (tester) async {
  // 1. Fixed viewport
  RendererBinding.instance.renderViews.first.configuration =
      TestViewConfiguration.fromView(
        size: const Size(500, 700),
        view: PlatformDispatcher.instance.implicitView!,
      );

  const key = ValueKey('paint');

  // 2. Load and Pump
  await tester.pumpWidget(getTestWidgetFromPath(path: 'my_card.json', key: key));
  await tester.pumpAndSettle();

  // 3. Compare (Note: targets the key, not the whole screen)
  await expectLater(
    find.byKey(key),
    matchesGoldenFile('gold_files/my_card-base.png'),
  );
}, tags: ['golden']);
```

### Local Golden Generation for Visual Verifications

You can generate goldens on your local machine for visual verification purposes, but they will not be used for CI testing and they should not be comitted to the repository.

```bash
cd packages/flutter_adaptive_cards_fs
flutter test --update-goldens --tags golden
```

> **Warning:** Golden image pixels are platform-specific. macOS-generated
> goldens may not match Linux CI exactly. The project uses `dart_test.yaml`
> to manage this. Check `test/analysis_options.yaml` for any tag restrictions.

### Running Only Non-Golden Tests (Faster Iteration)

The local AI agents should always run the tests with the `--exclude-tags golden` flag to speed up the test execution and because local execution of golden tests will fail due to the platform aliasing issues.

```bash
flutter test --exclude-tags golden
```

---

## Test Sample Files

Sample JSON cards live in `test/samples/`.
Always add a new sample JSON when implementing a feature or fixing a bug to enable regression testing and designer validation.

1. Create `test/samples/feature_name.json`.
2. Reference via `getTestWidgetFromPath(path: 'feature_name.json')`.
