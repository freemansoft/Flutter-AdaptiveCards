# Responsive Layout (`targetWidth` + `Layout.Flow`) Implementation Plan

> **Status: ✅ Complete (superseded). Archived 2026-07-02.** Core plan (Tasks 1–12 +
> Final verification) shipped in commit `533fd1a` (PR #36). The post-implementation
> follow-ups (FW1–FW5) are now resolved or reassigned: **FW2** returned to the Riverpod
> `cardWidthBucketProvider` (2026-06-19); **FW1** (`IntrinsicWidth` removal) was
> **rejected** as resting on a false premise and **FW3** (relational precedence) was
> **resolved**, both in the 2026-06-27 finish-`Layout.Flow` work. The remaining
> **FW4/FW5** remnants (unbounded / margin-inclusive width measurement, nested
> `Action.ShowCard` width, `listView` body path) are tracked in
> [Implementation-Status → Low priority "Flow follow-ups"](../../Implementation-Status.md#low-priority).
> Checkbox state below is historical.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Adaptive Cards adapt to render width — `targetWidth` show/hide on every element, and `Layout.Flow` wrapping on `Container` + the card root body — without changing any existing card's rendering.

**Architecture:** A single `LayoutBuilder` near the card root computes the current width bucket (`veryNarrow`/`narrow`/`standard`/`wide`) from HostConfig breakpoints and publishes it via a scoped Riverpod `Provider`. Elements fold a `targetWidth` match into their existing `isVisible` gate; `Container` and the root body pick a layout (stack vs. flow) for the current bucket via a pure selector and render `Layout.Flow` with a `Wrap`. The two logic-heavy pieces (bucket matching, layout selection) are pure, dependency-free functions tested without pumping widgets.

**Tech Stack:** Dart, Flutter, Riverpod v3, `flutter_test`. All work in `packages/flutter_adaptive_cards_fs`. All commands use `fvm`. Spec: `docs/superpowers/specs/2026-06-18-responsive-layout-targetwidth-flow-design.md`.

**Branch:** `feat/responsive-layout-targetwidth-flow` (already created; the design spec commit lives here).

**Conventions to honor (very_good_analysis):** `prefer_single_quotes`, `always_use_package_imports` (import via `package:flutter_adaptive_cards_fs/src/...`, never relative), `///` docs on public members, log via `dart:developer` `log` (never `print`).

---

## File Structure

**New files:**
- `lib/src/responsive/width_bucket.dart` — `WidthBucket` enum + pure `targetWidthMatches()` / `isExactBucketMatch()` matchers.
- `lib/src/responsive/layout_selection.dart` — pure `selectLayout()` choosing the best layout map for a bucket.
- `lib/src/responsive/adaptive_flow_layout.dart` — `AdaptiveFlowLayout` `Wrap`-based renderer for `Layout.Flow`.
- `lib/src/hostconfig/host_widths_config.dart` — `HostWidthsConfig` (breakpoints + spec defaults + `resolveBucket`).
- `test/responsive/width_bucket_test.dart`
- `test/responsive/layout_selection_test.dart`
- `test/responsive/adaptive_flow_layout_test.dart`
- `test/responsive/responsive_widget_test.dart` — pumped-card targetWidth + Flow behavior.
- `test/responsive/host_widths_config_test.dart`
- `test/golden/responsive_flow_golden_test.dart` (tagged `golden`)

**Modified files:**
- `lib/src/hostconfig/host_config.dart` — add `hostWidthBreakpoints` field + constructor param + `fromJson` parse.
- `lib/src/hostconfig/fallback_configs.dart` — add `hostWidthsConfig` default.
- `lib/src/reference_resolver.dart` — add `getHostWidthsConfig()` + `resolveWidthBucket(double)`.
- `lib/src/riverpod/providers.dart` — add `cardWidthBucketProvider`.
- `lib/src/adaptive_mixins.dart` — fold `targetWidth` into `AdaptiveVisibilityMixin.isVisible`.
- `lib/src/cards/containers/container.dart` — layout selection for `items`.
- `lib/src/cards/adaptive_card_element.dart` — root `LayoutBuilder` + bucket override + body layout selection.
- `docs/Implementation-Status.md`, `CHANGELOG.md` — docs.

---

## Task 1: Width bucket enum + pure matchers

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/lib/src/responsive/width_bucket.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/width_bucket_test.dart`

- [x] **Step 1: Write the failing test**

```dart
// test/responsive/width_bucket_test.dart
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('targetWidthMatches', () {
    test('absent/empty targetWidth always matches', () {
      expect(targetWidthMatches(null, WidthBucket.narrow), isTrue);
      expect(targetWidthMatches('', WidthBucket.wide), isTrue);
    });

    test('bare bucket matches only that bucket', () {
      expect(targetWidthMatches('narrow', WidthBucket.narrow), isTrue);
      expect(targetWidthMatches('narrow', WidthBucket.wide), isFalse);
      expect(targetWidthMatches('veryNarrow', WidthBucket.veryNarrow), isTrue);
    });

    test('atLeast matches that bucket and wider', () {
      expect(targetWidthMatches('atLeast:standard', WidthBucket.standard), isTrue);
      expect(targetWidthMatches('atLeast:standard', WidthBucket.wide), isTrue);
      expect(targetWidthMatches('atLeast:standard', WidthBucket.narrow), isFalse);
    });

    test('atMost matches that bucket and narrower', () {
      expect(targetWidthMatches('atMost:narrow', WidthBucket.narrow), isTrue);
      expect(targetWidthMatches('atMost:narrow', WidthBucket.veryNarrow), isTrue);
      expect(targetWidthMatches('atMost:narrow', WidthBucket.standard), isFalse);
    });

    test('malformed targetWidth fails open (matches)', () {
      expect(targetWidthMatches('atleast:bogus', WidthBucket.narrow), isTrue);
      expect(targetWidthMatches('nonsense', WidthBucket.wide), isTrue);
      expect(targetWidthMatches('atLeast:', WidthBucket.wide), isTrue);
    });

    test('case-insensitive parsing', () {
      expect(targetWidthMatches('atleast:WIDE', WidthBucket.wide), isTrue);
    });
  });

  group('isExactBucketMatch', () {
    test('true only for bare bucket equal to current', () {
      expect(isExactBucketMatch('narrow', WidthBucket.narrow), isTrue);
      expect(isExactBucketMatch('atLeast:narrow', WidthBucket.narrow), isFalse);
      expect(isExactBucketMatch(null, WidthBucket.narrow), isFalse);
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/width_bucket_test.dart`
Expected: FAIL — `width_bucket.dart` does not exist / `targetWidthMatches` undefined.

- [x] **Step 3: Write minimal implementation**

```dart
// lib/src/responsive/width_bucket.dart
import 'dart:developer';

/// Card render-width bucket used by responsive layout (`targetWidth`, `layouts`).
///
/// Ordered narrowest → widest; the enum index doubles as the comparison rank
/// for `atLeast:` / `atMost:` relational matching.
enum WidthBucket {
  /// Narrowest bucket (e.g. compact phone width).
  veryNarrow,

  /// Narrow bucket.
  narrow,

  /// Standard bucket (default desktop card width).
  standard,

  /// Widest bucket.
  wide,
}

/// Whether [targetWidth] applies at the given [bucket].
///
/// Card authors set `targetWidth` on an element to gate it by card width.
/// Accepts a bare bucket name (`'narrow'`), or the relational forms
/// `'atLeast:<bucket>'` / `'atMost:<bucket>'`. A `null`/empty value always
/// matches. Parsing is case-insensitive and **fails open**: any unrecognized
/// value matches (and logs), so an authoring typo never silently hides content.
bool targetWidthMatches(String? targetWidth, WidthBucket bucket) {
  if (targetWidth == null || targetWidth.trim().isEmpty) return true;
  final raw = targetWidth.trim();

  if (raw.contains(':')) {
    final parts = raw.split(':');
    if (parts.length != 2) return _failOpen(raw);
    final op = parts[0].trim().toLowerCase();
    final target = _parseBucket(parts[1]);
    if (target == null) return _failOpen(raw);
    switch (op) {
      case 'atleast':
        return bucket.index >= target.index;
      case 'atmost':
        return bucket.index <= target.index;
      default:
        return _failOpen(raw);
    }
  }

  final target = _parseBucket(raw);
  if (target == null) return _failOpen(raw);
  return bucket == target;
}

/// Whether [targetWidth] is a bare bucket name exactly equal to [bucket].
///
/// Used by layout selection to prefer an exact-bucket layout over a relational
/// or default one.
bool isExactBucketMatch(String? targetWidth, WidthBucket bucket) {
  if (targetWidth == null || targetWidth.contains(':')) return false;
  return _parseBucket(targetWidth) == bucket;
}

WidthBucket? _parseBucket(String value) {
  switch (value.trim().toLowerCase()) {
    case 'verynarrow':
      return WidthBucket.veryNarrow;
    case 'narrow':
      return WidthBucket.narrow;
    case 'standard':
      return WidthBucket.standard;
    case 'wide':
      return WidthBucket.wide;
    default:
      return null;
  }
}

bool _failOpen(String raw) {
  log('Unrecognized targetWidth "$raw"; treating as always-visible',
      name: 'responsive.width_bucket');
  return true;
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/width_bucket_test.dart`
Expected: PASS (all groups green).

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/width_bucket.dart \
        packages/flutter_adaptive_cards_fs/test/responsive/width_bucket_test.dart
git commit -m "feat(responsive): WidthBucket enum + targetWidth matchers

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: HostWidthsConfig (breakpoints + spec defaults)

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_widths_config.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/host_widths_config_test.dart`

- [x] **Step 1: Write the failing test**

```dart
// test/responsive/host_widths_config_test.dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_widths_config.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostWidthsConfig.resolveBucket (defaults)', () {
    test('maps widths to buckets at and around boundaries', () {
      expect(HostWidthsConfig.resolveBucket(null, 100), WidthBucket.veryNarrow);
      expect(HostWidthsConfig.resolveBucket(null, 164), WidthBucket.veryNarrow);
      expect(HostWidthsConfig.resolveBucket(null, 165), WidthBucket.narrow);
      expect(HostWidthsConfig.resolveBucket(null, 349), WidthBucket.narrow);
      expect(HostWidthsConfig.resolveBucket(null, 350), WidthBucket.standard);
      expect(HostWidthsConfig.resolveBucket(null, 767), WidthBucket.standard);
      expect(HostWidthsConfig.resolveBucket(null, 768), WidthBucket.wide);
      expect(HostWidthsConfig.resolveBucket(null, 2000), WidthBucket.wide);
    });
  });

  group('HostWidthsConfig.fromJson', () {
    test('honors host overrides', () {
      final config = HostWidthsConfig.fromJson(
        const {'veryNarrow': 100, 'narrow': 200, 'standard': 300},
      );
      expect(HostWidthsConfig.resolveBucket(config, 150), WidthBucket.narrow);
      expect(HostWidthsConfig.resolveBucket(config, 250), WidthBucket.standard);
      expect(HostWidthsConfig.resolveBucket(config, 350), WidthBucket.wide);
    });

    test('falls back to defaults for missing keys', () {
      final config = HostWidthsConfig.fromJson(const {'narrow': 200});
      expect(config.veryNarrowMax, 165);
      expect(config.narrowMax, 200);
      expect(config.standardMax, 768);
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/host_widths_config_test.dart`
Expected: FAIL — `host_widths_config.dart` does not exist.

- [x] **Step 3: Write minimal implementation**

Create `lib/src/hostconfig/host_widths_config.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// HostConfig `hostWidthBreakpoints` section: the pixel upper bounds that
/// separate the responsive [WidthBucket]s.
///
/// Each value is the exclusive upper bound of a bucket (`width < veryNarrowMax`
/// is `veryNarrow`, and so on). Hosts may override these; absent values fall
/// back to the Adaptive Cards spec defaults.
class HostWidthsConfig {
  /// Creates breakpoints from explicit pixel upper bounds.
  HostWidthsConfig({
    required this.veryNarrowMax,
    required this.narrowMax,
    required this.standardMax,
  });

  /// Parses `hostWidthBreakpoints` from HostConfig JSON, defaulting any missing
  /// key to the spec default.
  factory HostWidthsConfig.fromJson(Map<String, dynamic> json) {
    return HostWidthsConfig(
      veryNarrowMax: (json['veryNarrow'] as num?)?.toInt() ?? 165,
      narrowMax: (json['narrow'] as num?)?.toInt() ?? 350,
      standardMax: (json['standard'] as num?)?.toInt() ?? 768,
    );
  }

  /// Upper bound (exclusive) of the `veryNarrow` bucket.
  final int veryNarrowMax;

  /// Upper bound (exclusive) of the `narrow` bucket.
  final int narrowMax;

  /// Upper bound (exclusive) of the `standard` bucket; at or above is `wide`.
  final int standardMax;

  /// Resolves a [WidthBucket] for [width] using [config] (or spec defaults when
  /// [config] is null).
  static WidthBucket resolveBucket(HostWidthsConfig? config, double width) {
    final c = config ?? FallbackConfigs.hostWidthsConfig;
    if (width < c.veryNarrowMax) return WidthBucket.veryNarrow;
    if (width < c.narrowMax) return WidthBucket.narrow;
    if (width < c.standardMax) return WidthBucket.standard;
    return WidthBucket.wide;
  }
}
```

In `lib/src/hostconfig/fallback_configs.dart`, add the import at the top:

```dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_widths_config.dart';
```

and add this static inside the `FallbackConfigs` class (next to `spacingsConfig`):

```dart
  /// Default responsive width breakpoints (Adaptive Cards spec defaults).
  static final HostWidthsConfig hostWidthsConfig = HostWidthsConfig(
    veryNarrowMax: 165,
    narrowMax: 350,
    standardMax: 768,
  );
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/host_widths_config_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_widths_config.dart \
        packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart \
        packages/flutter_adaptive_cards_fs/test/responsive/host_widths_config_test.dart
git commit -m "feat(responsive): HostWidthsConfig breakpoints + spec defaults

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Wire breakpoints into HostConfig + ReferenceResolver

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/reference_resolver.dart`
- Test: append to `packages/flutter_adaptive_cards_fs/test/responsive/host_widths_config_test.dart`

- [x] **Step 1: Write the failing test**

Append this group to `test/responsive/host_widths_config_test.dart` (add imports for `host_config.dart` and `reference_resolver.dart`):

```dart
// add to imports:
// import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
// import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';

  group('ReferenceResolver.resolveWidthBucket', () {
    test('parses hostWidthBreakpoints from HostConfig JSON and resolves', () {
      final hostConfig = HostConfig.fromJson(const {
        'hostWidthBreakpoints': {'veryNarrow': 100, 'narrow': 200, 'standard': 300},
      });
      final resolver = ReferenceResolver(
        hostConfigs: HostConfigs(light: hostConfig, dark: hostConfig),
      );
      expect(resolver.resolveWidthBucket(150), WidthBucket.narrow);
      expect(resolver.resolveWidthBucket(350), WidthBucket.wide);
    });

    test('uses spec defaults when section absent', () {
      final resolver = ReferenceResolver(
        hostConfigs: HostConfigs(),
      );
      expect(resolver.resolveWidthBucket(100), WidthBucket.veryNarrow);
      expect(resolver.resolveWidthBucket(800), WidthBucket.wide);
    });
  });
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/host_widths_config_test.dart`
Expected: FAIL — `hostWidthBreakpoints` param and `resolveWidthBucket` undefined.

- [x] **Step 3: Write minimal implementation**

In `lib/src/hostconfig/host_config.dart`:

1. Add the import near the other hostconfig imports:
```dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_widths_config.dart';
```
2. Add the constructor parameter inside the `const HostConfig({...})` parameter list (after `this.chartsLayout,`):
```dart
    this.hostWidthBreakpoints,
```
3. In `factory HostConfig.fromJson`, add this entry inside the returned `HostConfig(...)` (after the `chartsLayout:` entry):
```dart
      hostWidthBreakpoints: (json['hostWidthBreakpoints'] != null)
          ? HostWidthsConfig.fromJson(
              json['hostWidthBreakpoints'] as Map<String, dynamic>,
            )
          : null,
```
4. Add the field declaration (next to the other `final ...Config?` fields):
```dart
  /// Responsive width breakpoints separating veryNarrow/narrow/standard/wide.
  final HostWidthsConfig? hostWidthBreakpoints;
```

In `lib/src/reference_resolver.dart`:

1. Add imports near the top:
```dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_widths_config.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
```
2. Add these methods next to `resolveSpacing`:
```dart
  /// Responsive width breakpoints from HostConfig (null → spec defaults).
  HostWidthsConfig? getHostWidthsConfig() =>
      hostConfigs.current.hostWidthBreakpoints;

  /// Resolves the [WidthBucket] for a card render [width] in logical pixels.
  WidthBucket resolveWidthBucket(double width) =>
      HostWidthsConfig.resolveBucket(getHostWidthsConfig(), width);
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/host_widths_config_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config.dart \
        packages/flutter_adaptive_cards_fs/lib/src/reference_resolver.dart \
        packages/flutter_adaptive_cards_fs/test/responsive/host_widths_config_test.dart
git commit -m "feat(responsive): HostConfig hostWidthBreakpoints + resolveWidthBucket

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: cardWidthBucketProvider

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`

> No standalone test — this is a one-line provider declaration exercised by Tasks 6, 9, 10. It uses a safe default (`WidthBucket.wide`) rather than throwing, so any subtree built without the root override degrades to "everything visible / wide layout" (fail-open), consistent with the spec.

- [x] **Step 1: Add the provider**

In `lib/src/riverpod/providers.dart`, add the import near the top:
```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
```
Add the declaration near the other `Provider<...>` declarations:
```dart
/// Current card render-width bucket for the surrounding card subtree.
///
/// Overridden by the root `LayoutBuilder` in `AdaptiveCardElement`. Defaults to
/// [WidthBucket.wide] when no override is present so isolated subtrees degrade
/// to showing everything (fail-open), matching responsive-layout semantics.
final cardWidthBucketProvider = Provider<WidthBucket>(
  (ref) => WidthBucket.wide,
);
```

- [x] **Step 2: Verify it compiles**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter analyze lib/src/riverpod/providers.dart`
Expected: No issues found.

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart
git commit -m "feat(responsive): cardWidthBucketProvider (fail-open default wide)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Pure layout selection

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_selection.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/layout_selection_test.dart`

- [x] **Step 1: Write the failing test**

```dart
// test/responsive/layout_selection_test.dart
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectLayout', () {
    test('null/empty layouts → null (stack default)', () {
      expect(selectLayout(null, WidthBucket.wide), isNull);
      expect(selectLayout(const [], WidthBucket.wide), isNull);
    });

    test('returns the layout whose targetWidth matches', () {
      final layouts = [
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
      ];
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
      expect(selectLayout(layouts, WidthBucket.narrow), isNull);
    });

    test('exact-bucket layout wins over relational', () {
      final layouts = [
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:narrow'},
        {'type': 'Layout.Stack', 'targetWidth': 'standard'},
      ];
      expect(selectLayout(layouts, WidthBucket.standard)?['type'], 'Layout.Stack');
    });

    test('relational match preferred over no-targetWidth default', () {
      final layouts = [
        {'type': 'Layout.Stack'},
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
      ];
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
    });

    test('falls back to no-targetWidth default when nothing else matches', () {
      final layouts = [
        {'type': 'Layout.Flow'},
        {'type': 'Layout.Stack', 'targetWidth': 'wide'},
      ];
      expect(selectLayout(layouts, WidthBucket.narrow)?['type'], 'Layout.Flow');
    });

    test('ignores non-map entries', () {
      final layouts = ['nonsense', {'type': 'Layout.Flow', 'targetWidth': 'wide'}];
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/layout_selection_test.dart`
Expected: FAIL — `layout_selection.dart` does not exist.

- [x] **Step 3: Write minimal implementation**

```dart
// lib/src/responsive/layout_selection.dart
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// Selects the best `layouts` entry for the current [bucket], or `null` to use
/// the implicit `Layout.Stack` default.
///
/// Containers and the card root body carry an optional `layouts` array (each
/// entry a layout object with a `type` and optional `targetWidth`). This picks
/// the most specific entry that applies at [bucket]:
/// exact-bucket `targetWidth` wins, then a matching relational `targetWidth`,
/// then a layout with no `targetWidth` (applies to all widths). Non-map entries
/// are ignored. Returns `null` when nothing applies so callers render a stack.
Map<String, dynamic>? selectLayout(List<dynamic>? layouts, WidthBucket bucket) {
  if (layouts == null || layouts.isEmpty) return null;

  Map<String, dynamic>? relationalMatch;
  Map<String, dynamic>? defaultMatch;

  for (final raw in layouts) {
    if (raw is! Map) continue;
    final layout = Map<String, dynamic>.from(raw);
    final targetWidth = layout['targetWidth'] as String?;
    if (!targetWidthMatches(targetWidth, bucket)) continue;

    if (isExactBucketMatch(targetWidth, bucket)) {
      return layout;
    }
    if (targetWidth == null || targetWidth.trim().isEmpty) {
      defaultMatch ??= layout;
    } else {
      relationalMatch ??= layout;
    }
  }

  return relationalMatch ?? defaultMatch;
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/layout_selection_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/layout_selection.dart \
        packages/flutter_adaptive_cards_fs/test/responsive/layout_selection_test.dart
git commit -m "feat(responsive): pure selectLayout for layouts array

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Fold targetWidth into element visibility

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart:373-389`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart`

> Every element that uses `AdaptiveVisibilityMixin` wraps itself in
> `Visibility(visible: isVisible)`. Folding the `targetWidth` match into
> `isVisible` gives `targetWidth` gating to all such elements with no per-element
> edits, and makes effective visibility `baselineVisible && matchesTargetWidth`.

- [x] **Step 1: Write the failing test**

```dart
// test/responsive/responsive_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

/// Renders [card] via the canonical test harness at a controlled card width.
///
/// The harness centers the card with loose constraints, so the card's measured
/// width equals the test surface width. We pin devicePixelRatio to 1.0 so the
/// logical width equals the value passed here, and reset both in tearDown.
Future<void> _pumpCardAtWidth(
  WidgetTester tester,
  Map<String, dynamic> card,
  double width,
) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(Size(width, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    getTestWidgetFromMap(map: card, title: 'responsive test'),
  );
  await tester.pumpAndSettle();
}

void main() {
  final card = {
    'type': 'AdaptiveCard',
    'version': '1.6',
    'body': [
      {'type': 'TextBlock', 'text': 'always', 'id': 'always'},
      {
        'type': 'TextBlock',
        'text': 'wide-only',
        'id': 'wideOnly',
        'targetWidth': 'atLeast:standard',
      },
    ],
  };

  testWidgets('targetWidth hides element when card is narrow', (tester) async {
    await _pumpCardAtWidth(tester, card, 150);
    expect(find.text('always'), findsOneWidget);
    expect(find.text('wide-only'), findsNothing);
  });

  testWidgets('targetWidth shows element when card is wide', (tester) async {
    await _pumpCardAtWidth(tester, card, 1000);
    expect(find.text('always'), findsOneWidget);
    expect(find.text('wide-only'), findsOneWidget);
  });
}
```

> **Entry point (resolved):** Use `getTestWidgetFromMap(map:, title:)` from
> `test/utils/test_utils.dart` (re-exported from
> `flutter_adaptive_cards_test_support`) — this is the pattern every existing
> widget test uses. The card root finder is `find.byType(RawAdaptiveCard)`. The
> harness centers the card with loose constraints, so width is controlled via the
> test surface size (see `_pumpCardAtWidth` above). If `setSurfaceSize` does not
> flip the bucket as expected, verify the card actually receives the surface
> width at its root `LayoutBuilder` (Task 7) and report as DONE_WITH_CONCERNS.

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: FAIL — `wide-only` is found at width 150 (targetWidth not yet applied).

- [x] **Step 3: Write minimal implementation**

In `lib/src/adaptive_mixins.dart`, add the import near the other `package:flutter_adaptive_cards_fs/src/...` imports:
```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
```
Replace the `isVisible` getter (currently lines ~380-381) with:
```dart
  /// Effective visibility: baseline JSON + runtime overlays, ANDed with the
  /// element's `targetWidth` match against the current card width bucket.
  ///
  /// `isVisible` and `targetWidth` are independent gates — a runtime
  /// `setIsVisible(visible: true)` overlay cannot override a `targetWidth` miss.
  bool get isVisible {
    final resolved = ref.watch(resolvedElementProvider(id));
    final baselineVisible = parseIsVisible(resolved?['isVisible']);
    final bucket = ref.watch(cardWidthBucketProvider);
    final matchesWidth =
        targetWidthMatches(resolved?['targetWidth'] as String?, bucket);
    return baselineVisible && matchesWidth;
  }
```

> `cardWidthBucketProvider` is already imported transitively via providers; if analyze reports it undefined, add `import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';` (the file already references other providers from there, so it is likely present).

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: PASS (both tests).

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart \
        packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart
git commit -m "feat(responsive): apply targetWidth to element visibility

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: Root LayoutBuilder publishes the width bucket

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart:324-332`
- Test: reuse `test/responsive/responsive_widget_test.dart` (Task 6 tests now exercise the real override end-to-end).

> Task 6's tests pass against the fail-open default (`wide`) only at width 1000; at width 150 the element is hidden **only if** the real bucket is published. This task wires the actual measurement so the narrow test reflects a real `narrow`/`veryNarrow` bucket rather than the default. Verify by re-running Task 6's tests after this change.

- [x] **Step 1: Wrap the card body in a LayoutBuilder + bucket override**

In `lib/src/cards/adaptive_card_element.dart`, add the import near the other `package:flutter_adaptive_cards_fs/src/...` imports:
```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
```
Replace the final `return ProviderScope(...)` block (lines ~324-332) with:
```dart
    return LayoutBuilder(
      builder: (context, constraints) {
        final WidthBucket bucket = ref
            .read(styleReferenceResolverProvider)
            .resolveWidthBucket(constraints.maxWidth);
        return ProviderScope(
          overrides: [
            adaptiveCardElementStateProvider.overrideWithValue(this),
            cardWidthBucketProvider.overrideWithValue(bucket),
          ],
          child: AdaptiveTappable(
            adaptiveMap: adaptiveMap,
            child: Form(key: formKey, child: result),
          ),
        );
      },
    );
```

> `styleReferenceResolverProvider` and `cardWidthBucketProvider` come from
> `riverpod/providers.dart`, already imported here (the file reads
> `adaptiveCardElementStateProvider`). If analyze flags `cardWidthBucketProvider`
> as undefined, the import is already present — only `width_bucket.dart` (for the
> `WidthBucket` type) is new.

- [x] **Step 2: Run Task 6 tests to verify they still pass with real measurement**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: PASS (narrow test now passes because the real bucket is `veryNarrow`, not the `wide` default).

- [x] **Step 3: Sanity-check no regression in card rendering**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`
Expected: PASS (no existing card test regressions from the LayoutBuilder wrap).

- [x] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart
git commit -m "feat(responsive): root LayoutBuilder publishes width bucket

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 8: AdaptiveFlowLayout widget

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/lib/src/responsive/adaptive_flow_layout.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/responsive/adaptive_flow_layout_test.dart`

- [x] **Step 1: Write the failing test**

```dart
// test/responsive/adaptive_flow_layout_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resolver = ReferenceResolver(hostConfigs: HostConfigs());

  testWidgets('renders children inside a Wrap with resolved spacing/alignment',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {
              'type': 'Layout.Flow',
              'columnSpacing': 'small',
              'rowSpacing': 'large',
              'horizontalItemsAlignment': 'center',
            },
            styleResolver: resolver,
            children: const [Text('a'), Text('b')],
          ),
        ),
      ),
    );

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.alignment, WrapAlignment.center);
    expect(wrap.spacing, 3); // 'small' default
    expect(wrap.runSpacing, 30); // 'large' default
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/adaptive_flow_layout_test.dart`
Expected: FAIL — `adaptive_flow_layout.dart` does not exist.

- [x] **Step 3: Write minimal implementation**

```dart
// lib/src/responsive/adaptive_flow_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';

/// Renders a container's items as a wrapping `Layout.Flow` arrangement.
///
/// Items flow left-to-right and wrap to new rows as width allows, instead of
/// stacking vertically. `columnSpacing` / `rowSpacing` resolve through the same
/// HostConfig spacing tokens as other elements; `horizontalItemsAlignment` and
/// `verticalItemsAlignment` map to [Wrap] alignment. Advanced item sizing
/// (`itemFit`, `minItemWidth`, `maxItemWidth`) is intentionally not handled in
/// this pass — items take their natural size.
class AdaptiveFlowLayout extends StatelessWidget {
  /// Creates a flow layout from a parsed `Layout.Flow` [layoutMap].
  const AdaptiveFlowLayout({
    required this.layoutMap,
    required this.styleResolver,
    required this.children,
    super.key,
  });

  /// The selected `Layout.Flow` object from the container's `layouts` array.
  final Map<String, dynamic> layoutMap;

  /// Resolver used to map spacing tokens to pixel gaps.
  final ReferenceResolver styleResolver;

  /// The container's item widgets to arrange.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: styleResolver.resolveSpacing(layoutMap['columnSpacing'] as String?),
      runSpacing: styleResolver.resolveSpacing(layoutMap['rowSpacing'] as String?),
      alignment: _wrapAlignment(layoutMap['horizontalItemsAlignment'] as String?),
      crossAxisAlignment:
          _wrapCrossAlignment(layoutMap['verticalItemsAlignment'] as String?),
      children: children,
    );
  }

  WrapAlignment _wrapAlignment(String? value) {
    switch (value) {
      case 'center':
        return WrapAlignment.center;
      case 'right':
        return WrapAlignment.end;
      default:
        return WrapAlignment.start;
    }
  }

  WrapCrossAlignment _wrapCrossAlignment(String? value) {
    switch (value) {
      case 'center':
        return WrapCrossAlignment.center;
      case 'bottom':
        return WrapCrossAlignment.end;
      default:
        return WrapCrossAlignment.start;
    }
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/adaptive_flow_layout_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/responsive/adaptive_flow_layout.dart \
        packages/flutter_adaptive_cards_fs/test/responsive/adaptive_flow_layout_test.dart
git commit -m "feat(responsive): AdaptiveFlowLayout Wrap renderer

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 9: Layout selection in Container

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/containers/container.dart:82-103`
- Test: append to `packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart`

- [x] **Step 1: Write the failing test**

Append to `test/responsive/responsive_widget_test.dart` (reusing `_pumpCardAtWidth`):

```dart
  final flowCard = {
    'type': 'AdaptiveCard',
    'version': '1.6',
    'body': [
      {
        'type': 'Container',
        'layouts': [
          {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
        ],
        'items': [
          {'type': 'TextBlock', 'text': 'one'},
          {'type': 'TextBlock', 'text': 'two'},
        ],
      },
    ],
  };

  testWidgets('Container uses Flow (Wrap) when wide', (tester) async {
    await _pumpCardAtWidth(tester, flowCard, 1000);
    expect(find.byType(Wrap), findsWidgets);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('Container stays a stack (no Flow Wrap) when narrow',
      (tester) async {
    await _pumpCardAtWidth(tester, flowCard, 150);
    // The action-area Wrap may exist; assert the container items are NOT in a
    // Wrap by checking they render under a Column instead.
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    // No Flow applied → items share a Column ancestor.
    expect(
      find.ancestor(of: find.text('one'), matching: find.byType(Column)),
      findsWidgets,
    );
  });
```

Add this import at the top of the file:
```dart
import 'package:flutter/material.dart';
```
(already present from Task 6 — keep one copy).

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: FAIL — wide case finds no Flow `Wrap` around the container items.

- [x] **Step 3: Write minimal implementation**

In `lib/src/cards/containers/container.dart`, add imports near the other `package:flutter_adaptive_cards_fs/src/...` imports:
```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
```
In `build`, replace the `else` branch that builds `containerChild` (currently the `Padding(... child: Column(...))` at lines ~91-102) with:
```dart
    } else {
      final selected = selectLayout(
        adaptiveMap['layouts'] as List<dynamic>?,
        ref.watch(cardWidthBucketProvider),
      );
      final bool useFlow = selected != null && selected['type'] == 'Layout.Flow';
      final Widget itemsLayout = useFlow
          ? AdaptiveFlowLayout(
              layoutMap: selected,
              styleResolver: styleResolver,
              children: children,
            )
          : Column(
              mainAxisAlignment: verticalContentAlignment,
              children: children.toList(),
            );
      containerChild = Padding(
        padding: EdgeInsets.symmetric(
          vertical: spacing,
          horizontal: spacing,
        ),
        child: itemsLayout,
      );
    }
```

> `styleResolver` is provided by `AdaptiveElementMixin`; `ref` is available on
> `ConsumerState`. Using `ref.watch(cardWidthBucketProvider)` in `build` makes
> the container re-pick its layout when the card is resized across a boundary.

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: PASS (all tests).

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/containers/container.dart \
        packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart
git commit -m "feat(responsive): Layout.Flow selection in Container

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 10: Layout selection for the card root body

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart:233-292`
- Test: append to `packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart`

> The root body (`adaptiveMap['layouts']`) applies Flow to the **body items
> only** (`bodyChildren`); the action strip and show-card consumer stay in the
> outer column. `Layout.Flow` is applied only on the non-`listView` path; when
> `listView` is true the body keeps the `ListView` (documented limitation).

- [x] **Step 1: Write the failing test**

Append to `test/responsive/responsive_widget_test.dart`:

```dart
  final rootFlowCard = {
    'type': 'AdaptiveCard',
    'version': '1.6',
    'layouts': [
      {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
    ],
    'body': [
      {'type': 'TextBlock', 'text': 'rootOne'},
      {'type': 'TextBlock', 'text': 'rootTwo'},
    ],
  };

  testWidgets('root body uses Flow (Wrap) when wide', (tester) async {
    await _pumpCardAtWidth(tester, rootFlowCard, 1000);
    expect(find.byType(Wrap), findsWidgets);
    expect(find.text('rootOne'), findsOneWidget);
    expect(find.text('rootTwo'), findsOneWidget);
  });
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/responsive_widget_test.dart -n "root body uses Flow"`
Expected: FAIL — body items are not wrapped in a Flow `Wrap`.

- [x] **Step 3: Write minimal implementation**

In `lib/src/cards/adaptive_card_element.dart`, add imports near the other `package:flutter_adaptive_cards_fs/src/...` imports (if not already present from Task 7):
```dart
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
```
Inside `build`, the non-listView path currently builds:
```dart
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgetChildren,
            ),
```
where `widgetChildren = bodyChildren + actionWidget + showCardConsumer`. Restructure so body items get the selected layout while actions stay below. Replace the construction of `widgetChildren` and the `result` `Column`/`ListView` as follows.

First, keep `bodyChildren` separate from the appended action/show-card widgets. Change the two `widgetChildren..add(...)` calls so the appended widgets go into a new list:
```dart
    final List<Widget> trailingWidgets = [
      actionWidget,
      Consumer(
        builder: (context, ref, _) {
          final expandedId = ref.watch(expandedShowCardIdProvider);
          if (expandedId == null) return const SizedBox.shrink();
          final target = showCardTargetElements.where(
            (c) => c.id == expandedId,
          );
          if (target.isEmpty) return const SizedBox.shrink();
          return target.first;
        },
      ),
    ];

    final selectedBodyLayout = selectLayout(
      adaptiveMap['layouts'] as List<dynamic>?,
      ref.watch(cardWidthBucketProvider),
    );
    final bool bodyUsesFlow =
        selectedBodyLayout != null && selectedBodyLayout['type'] == 'Layout.Flow';

    final Widget bodyLayout = bodyUsesFlow
        ? AdaptiveFlowLayout(
            layoutMap: selectedBodyLayout,
            styleResolver: styleResolver,
            children: widgetChildren,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgetChildren,
          );
```
Then build `result` so the body layout precedes the trailing widgets:
```dart
    Widget result = Container(
      margin: const EdgeInsets.all(8),
      child: widget.listView
          ? ListView(
              shrinkWrap: true,
              children: [...widgetChildren, ...trailingWidgets],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bodyLayout, ...trailingWidgets],
            ),
    );
```

> Remove the original `widgetChildren..add(actionWidget)..add(Consumer(...))`
> block (replaced by `trailingWidgets`). `widgetChildren` now holds only the
> body elements. Confirm `styleResolver` is available on the state (via
> `AdaptiveElementMixin`); if not, use `ref.read(styleReferenceResolverProvider)`.

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/responsive/responsive_widget_test.dart`
Expected: PASS (all tests).

- [x] **Step 5: Run the full non-golden suite (no regressions)**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`
Expected: PASS — body restructure must not break existing card/action/show-card tests.

- [x] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart \
        packages/flutter_adaptive_cards_fs/test/responsive/responsive_widget_test.dart
git commit -m "feat(responsive): Layout.Flow selection for card root body

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 11: Golden tests (narrow vs wide Flow)

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/test/golden/responsive_flow_golden_test.dart`

> Follow the existing golden conventions in this repo (tag `golden`, platform
> subdirectory under `gold_files/`). Before writing, read one existing golden
> test (grep `test/` for `@Tags(['golden'])` or `matchesGoldenFile`) and mirror
> its setup, tag, and file-path layout exactly.

- [x] **Step 1: Write the golden test**

```dart
// test/golden/responsive_flow_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  final card = {
    'type': 'AdaptiveCard',
    'version': '1.6',
    'body': [
      {
        'type': 'Container',
        'layouts': [
          {
            'type': 'Layout.Flow',
            'targetWidth': 'atLeast:standard',
            'columnSpacing': 'small',
            'rowSpacing': 'small',
          },
        ],
        'items': [
          {'type': 'TextBlock', 'text': 'Alpha'},
          {'type': 'TextBlock', 'text': 'Beta'},
          {'type': 'TextBlock', 'text': 'Gamma'},
        ],
      },
    ],
  };

  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(Size(width, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'responsive flow golden'),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Flow card golden — narrow (stacks)', (tester) async {
    await pumpAt(tester, 150);
    await expectLater(
      find.byType(RawAdaptiveCard),
      matchesGoldenFile('gold_files/responsive_flow_narrow.png'),
    );
  });

  testWidgets('Flow card golden — wide (wraps)', (tester) async {
    await pumpAt(tester, 1000);
    await expectLater(
      find.byType(RawAdaptiveCard),
      matchesGoldenFile('gold_files/responsive_flow_wide.png'),
    );
  });
}
```

> Before writing, read one existing golden test to confirm the tag style,
> `gold_files/` path layout (platform subdirectory, e.g. `gold_files/linux/` or
> `gold_files/macos/`), and the golden filename convention; mirror it exactly.
> Adjust the `matchesGoldenFile` path to match.

- [x] **Step 2: Generate the golden baselines**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --update-goldens --tags=golden test/golden/responsive_flow_golden_test.dart`
Expected: PASS; two new `.png` baselines created.

- [x] **Step 3: Verify goldens pass without regeneration**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --tags=golden test/golden/responsive_flow_golden_test.dart`
Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/test/golden/responsive_flow_golden_test.dart \
        packages/flutter_adaptive_cards_fs/test/golden/gold_files/responsive_flow_narrow.png \
        packages/flutter_adaptive_cards_fs/test/golden/gold_files/responsive_flow_wide.png
git commit -m "test(responsive): golden tests for narrow vs wide Flow

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 12: Documentation

**Files:**
- Modify: `docs/Implementation-Status.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [x] **Step 1: Update Implementation-Status.md**

In `docs/Implementation-Status.md`:
- In the **Common Properties** table, change the `targetWidth` row from `❌ Missing` to `⚠️ Partial` with note: `targetWidth visibility (named buckets + atLeast:/atMost:) implemented on all elements; Layout.AreaGrid / grid.area still deferred.`
- In the **Known Gaps** "Responsive layout" row, change to: `targetWidth ✅ (visibility); Layout.Flow ✅ (Container + root body); Layout.AreaGrid / grid.area + advanced Flow sizing (itemFit/min/maxItemWidth) deferred.`
- In **Priority Recommendations → High priority**, update item 1 to note `targetWidth` + `Layout.Flow` done; `AreaGrid` remaining.
- Update the `_Last Updated_` line to `2026-06-18`.

- [x] **Step 2: Update the CHANGELOG**

In `packages/flutter_adaptive_cards_fs/CHANGELOG.md`, under `## [Unreleased]`, add:
```markdown
- Added responsive layout: `targetWidth` element visibility (named width buckets plus `atLeast:`/`atMost:`) and `Layout.Flow` wrapping on `Container` and the card root body, driven by HostConfig `hostWidthBreakpoints` (spec defaults when absent). `Layout.AreaGrid` and advanced Flow sizing remain deferred.
```

- [x] **Step 3: Commit**

```bash
git add docs/Implementation-Status.md packages/flutter_adaptive_cards_fs/CHANGELOG.md
git commit -m "docs(responsive): record targetWidth + Layout.Flow status

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Final Task: Full verification

- [x] **Step 1: Analyze the whole repo**

Run (from repo root): `fvm flutter analyze`
Expected: No issues found (clean, including `public_member_api_docs`).

- [x] **Step 2: Run the full non-golden suite**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`
Expected: PASS — all existing tests plus the new `test/responsive/` tests; 0 failures.

- [x] **Step 3: Run golden tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --tags=golden`
Expected: PASS.

- [x] **Step 4: Invoke `verification-before-completion`**

Paste the analyze + test command output (exit codes, pass/fail counts) before claiming completion. Do not report "plan complete" until the full suite passes.

---

## Follow-up tasks: post-implementation review

> Added 2026-06-18 after the first slice landed (commit `533fd1a`, PR #36). A review
> of the shipped code surfaced five weaknesses. Design rationale and the full
> Riverpod remediation for FW2 live in the spec:
> `docs/superpowers/specs/2026-06-18-responsive-layout-targetwidth-flow-design.md`,
> section "Post-implementation review — known weaknesses". Tackle in priority order
> FW1 → FW2 → FW3 → FW4 → FW5.

### FW1 — Remove the `IntrinsicWidth` hazard in `AdaptiveFlowLayout` (highest priority)

**File:** `lib/src/responsive/adaptive_flow_layout.dart`; tests
`test/responsive/adaptive_flow_layout_test.dart`.

`_sizedItem` wraps every child in `IntrinsicWidth`. This (a) throws on children that
do not support intrinsic dimensions (unbounded `Image`, nested flex/`Expanded`,
some custom render objects) and (b) adds O(n) speculative layout passes re-run on
every resize.

- [ ] **Step 1 (failing test):** Add a widget test that puts an `Image`-bearing or
  `Expanded`-bearing element into a `Layout.Flow` container and pumps it. Confirm it
  currently throws / misbehaves.
- [ ] **Step 2 (fix):** Drop `IntrinsicWidth` for the no-constraint case (let `Wrap`
  size children to content). Apply width constraints only when `minItemWidth` /
  `maxItemWidth` are present, via `ConstrainedBox` alone — without `IntrinsicWidth`.
  Re-evaluate whether intrinsic sizing is ever actually needed; if a specific child
  type needs it, guard it rather than wrapping all children.
- [ ] **Step 3:** Re-run `test/responsive/` + the Flow golden; regenerate goldens only
  if the intended visual is unchanged-or-better.

### FW2 — Reconcile width-bucket reactivity: Riverpod provider vs. `CardWidthScope` ✅ DONE

> **Resolved via option (b): returned to the Riverpod provider.** Implemented
> 2026-06-19. `CardWidthScope` deleted; `cardWidthBucketProvider` restored;
> `isVisible`, `Container`, and the root body read it via `ref.watch`. Analyze
> clean, all `test/responsive/` tests pass (27/27), full non-golden suite passes
> (531, 2 skipped), Flow goldens pass without regeneration (behavior-preserving).

**Files touched:** `lib/src/riverpod/providers.dart` (added `cardWidthBucketProvider`),
`lib/src/cards/adaptive_card_element.dart` (two-scope pattern + `_AdaptiveCardBody`
→ `ConsumerWidget`), `lib/src/adaptive_mixins.dart` (`isVisible` reads provider),
`lib/src/cards/containers/container.dart` (reads provider), deleted
`lib/src/responsive/card_width_scope.dart`; docs `…/specs/…-design.md` (W2 marked
resolved), `CHANGELOG.md`.

- [x] **Chosen: (b) Return to Riverpod** using the **two-scope, hoisted-`child`**
  pattern (single stable outer `ProviderScope`; thin nested `ProviderScope` inside the
  `LayoutBuilder` whose `child` is a hoisted stable reference). The outer scope is not
  rebuilt on layout passes — the inner scope re-supplies the same `bucket` via
  `overrideWithValue` (a no-op unless it changed) while the captured `cardBody` is
  preserved by element reuse, so the subtree is **not** rebuilt and there is no
  post-frame write / frame lag. `card_width_scope.dart` deleted;
  `cardWidthBucketProvider` restored; `isVisible` / `container.dart` /
  `_AdaptiveCardBody` switched back to `ref.watch(cardWidthBucketProvider)`.
- [x] **Verified:** `test/responsive/` + `--exclude-tags=golden` green; Flow goldens
  unchanged. Resize across a boundary still reflows (responsive widget tests).
- [x] **Docs reconciled:** `docs/Implementation-Status.md` updated to cite
  `cardWidthBucketProvider` instead of `CardWidthScope`.
- [ ] **Follow-up (optional):** add an explicit regression test asserting document /
  input overlay state survives a resize across a width boundary (proves the outer
  `ProviderScope` is not rebuilt per layout pass).

### FW3 — Fix `selectLayout` relational precedence

**File:** `lib/src/responsive/layout_selection.dart`; tests
`test/responsive/layout_selection_test.dart`.

`relationalMatch ??= layout` keeps the **first** relational match in array order, not
the most specific.

- [ ] **Step 1 (failing test):** `[{atLeast:narrow}, {atLeast:standard}]` at
  `WidthBucket.wide` should select `atLeast:standard` (most specific), not
  `atLeast:narrow`.
- [ ] **Step 2 (fix):** Among matching relationals, pick the one whose target bucket
  is closest to the current bucket (smallest `|bucket.index - target.index|`), with a
  documented tiebreak (e.g. later array entry wins) cross-checked against the AC spec
  / another SDK.

### FW4 — Harden width measurement

**Files:** `lib/src/hostconfig/host_widths_config.dart` (or the resolver),
`lib/src/cards/adaptive_card_element.dart`.

- [ ] **Unbounded width:** when `constraints.maxWidth` is not finite, choose a defined
  behavior (document it — likely keep `wide` as fail-open) and **log via
  `dart:developer`** so it is debuggable instead of silent.
- [ ] **Margin/padding:** decide whether the bucket should be measured on the content
  width (inside the card `margin` + container padding) rather than the outer width;
  document the decision either way.
- [ ] **Nested `Action.ShowCard`:** decide and document whether a nested card's
  `targetWidth` is relative to the nested card or the host card; add a test pinning
  the chosen behavior.

### FW5 — Close documentation/scope drift

**Files:** `lib/src/responsive/adaptive_flow_layout.dart` (doc comment),
`docs/Implementation-Status.md`, this plan's "Deferred" note.

- [ ] Record that `minItemWidth` / `maxItemWidth` **ship** while `itemFit` does **not**
  (the original spec listed all three as deferred).
- [ ] Keep the remaining gaps explicit: no `layouts` on `ColumnSet` / `Column` /
  `TableCell`, no `Layout.AreaGrid`, and `Layout.Flow` not applied on the `listView`
  body path.

---

## Notes / open items carried from the spec

- **Default breakpoint values** (165 / 350 / 768): if the published Adaptive Cards
  host-config schema specifies different defaults, the schema wins — update
  `HostWidthsConfig.fromJson`, `FallbackConfigs.hostWidthsConfig`, and the Task 2
  test boundaries together.
- **Public entry widget (resolved):** tests use `getTestWidgetFromMap(map:, title:)`
  from `test/utils/test_utils.dart`; card-root finder is
  `find.byType(RawAdaptiveCard)`; width controlled via `setSurfaceSize` +
  pinned `devicePixelRatio = 1.0`.
- **listView body + Flow**: `Layout.Flow` on the root body is honored only on the
  non-`listView` path; documented limitation, acceptable for this slice.
- **Deferred** (separate specs): `Layout.AreaGrid` + `grid.area`; Flow `itemFit` /
  `minItemWidth` / `maxItemWidth`; `layouts` on `ColumnSet` / `Column` / `TableCell`.
