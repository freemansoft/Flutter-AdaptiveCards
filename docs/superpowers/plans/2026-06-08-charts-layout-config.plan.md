# ChartsLayoutConfig Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add a `chartsLayout` HostConfig section (`ChartsLayoutConfig`) to `flutter_adaptive_cards_fs` and replace every hardcoded chart layout/styling literal in `flutter_adaptive_charts_fs` with values resolved from that config (with `FallbackConfigs` defaults matching today's behavior).

**Status:** ✅ **Complete** — merged in [#18](https://github.com/freemansoft/Flutter-AdaptiveCards/pull/18) (`8cb6425`). Checkboxes updated 2026-06-16 after full verification. **No open work items.**

**Architecture:** Follow the existing `progressSizes` / `chartColors` precedent: typed config class under `lib/src/hostconfig/`, wire into `HostConfig.fromJson`, add `FallbackConfigs` defaults, expose via `ReferenceResolver`, consume from chart widgets through `styleResolver`. `ChartsLayoutConfig` holds four nested sections (`line`, `bar`, `pie`, `donut`) and exposes one static resolver per chart family: `resolveLineLayout`, `resolveBarLayout`, `resolvePieLayout`, `resolveDonutLayout`. Grouped/stacked bar variants and `Chart.Gauge` reuse `resolveBarLayout` / `resolveDonutLayout` respectively.

**Tech Stack:** Dart 3.12+, Flutter (FVM), `flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, `fl_chart`, `very_good_analysis`.

---

## Hardcoded value inventory (baseline defaults)

These are the values to preserve as `FallbackConfigs` defaults so golden tests stay pixel-identical unless HostConfig overrides them.

### Line (`line_chart.dart`)

| Property                  | Current literal | Notes                            |
| ------------------------- | --------------- | -------------------------------- |
| `height`                  | `250`           | `SizedBox` around chart          |
| `emptyMinX` / `emptyMaxX` | `0` / `10`      | No-data axis bounds              |
| `emptyMinY` / `emptyMaxY` | `0` / `10`      | No-data axis bounds              |
| `degenerateRangeBump`     | `1`             | Added when `max == min`          |
| `zeroRangeFallback`       | `10`            | Y-range when computed range is 0 |
| `yAxisPaddingFactor`      | `0.1`           | 10% vertical headroom            |
| `isCurved`                | `true`          | Line stroke style                |
| `barWidth`                | `3`             | Stroke width                     |
| `isStrokeCapRound`        | `true`          | Line cap                         |
| `showDots`                | `false`         | `FlDotData.show`                 |
| `showAreaBelow`           | `false`         | `BarAreaData.show`               |
| `showTitles`              | `true`          | Axis titles master switch        |
| `showRightTitles`         | `false`         | Right axis labels                |
| `showTopTitles`           | `false`         | Top axis labels                  |
| `showGrid`                | `true`          | Grid lines                       |
| `showBorder`              | `true`          | Chart border                     |
| `borderColor`             | `#37434d`       | `Color(0xff37434d)`              |
| `borderWidth`             | `1`             | Border stroke width              |

### Bar — vertical, horizontal, grouped, stacked (`bar_chart.dart`)

| Property                   | Current literal | Notes                           |
| -------------------------- | --------------- | ------------------------------- |
| `height`                   | `250`           | `SizedBox` around chart         |
| `emptyMaxY`                | `10`            | Safety when no data             |
| `maxYPaddingFactor`        | `1.2`           | 20% value-axis headroom         |
| `barWidth`                 | `16`            | Rod width (all variants)        |
| `barsSpace`                | `4`             | Space between rods in a group   |
| `barBorderRadius`          | `2`             | `BorderRadius.circular(2)`      |
| `stackedBarBorderRadius`   | `0`             | Stacked outer rod               |
| `alignment`                | `spaceAround`   | `BarChartAlignment.spaceAround` |
| `categoryAxisReservedSize` | `32`            | Label axis space                |
| `categoryLabelFontSize`    | `10`            | Category label `TextStyle`      |
| `showCategoryTitles`       | `true`          | Bottom/category axis labels     |

### Pie (`pie_donut_chart.dart`, `isDonut: false`)

| Property            | Current literal | Notes                   |
| ------------------- | --------------- | ----------------------- |
| `height`            | `200`           | `SizedBox` around chart |
| `centerSpaceRadius` | `0`             | Full pie                |
| `sectionsSpace`     | `2`             | Gap between slices      |
| `sectionRadius`     | `100`           | Slice outer radius      |
| `titleFontSize`     | `12`            | On-slice label          |
| `titleFontWeight`   | `bold`          | On-slice label          |
| `titleColor`        | `#FFFFFF`       | `Colors.white`          |

### Donut / Gauge (`pie_donut_chart.dart`, `isDonut: true`)

| Property            | Current literal | Notes                 |
| ------------------- | --------------- | --------------------- |
| `height`            | `200`           | Same container as pie |
| `centerSpaceRadius` | `40`            | Hole radius           |
| `sectionsSpace`     | `2`             | Gap between slices    |
| `sectionRadius`     | `50`            | Slice outer radius    |
| `titleFontSize`     | `12`            | Same as pie           |
| `titleFontWeight`   | `bold`          | Same as pie           |
| `titleColor`        | `#FFFFFF`       | Same as pie           |

**Out of scope (keep as logic, not config):** `rotationQuarterTurns` for horizontal bars (derived from chart type), color palette resolution (`chartColors` — already HostConfig-driven), `SeparatorElement` spacing.

---

## File map

| File                                                                                | Role                                                                          |
| ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/charts_layout_config.dart`   | **Create** — `ChartsLayoutConfig` + nested section classes + static resolvers |
| `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config.dart`            | Add `chartsLayout` field + `fromJson` parse                                   |
| `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart`       | Add `chartsLayoutConfig` defaults                                             |
| `packages/flutter_adaptive_cards_fs/lib/src/reference_resolver.dart`                | `getChartsLayoutConfig()` + convenience `resolve*Layout()` delegates          |
| `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config_schema.json`     | Add `ChartsLayoutConfig` schema definitions                                   |
| `packages/flutter_adaptive_cards_fs/test/hostconfig/charts_layout_config.json`      | **Create** — fixture for parsing test                                         |
| `packages/flutter_adaptive_cards_fs/test/hostconfig/charts_layout_config_test.dart` | **Create** — unit tests                                                       |
| `packages/flutter_adaptive_cards_fs/test/host_config_test.dart`                     | Add `chartsLayout` round-trip via `HostConfig.fromJson`                       |
| `packages/flutter_adaptive_charts_fs/lib/src/charts/line_chart.dart`                | Replace literals with resolver                                                |
| `packages/flutter_adaptive_charts_fs/lib/src/charts/bar_chart.dart`                 | Replace literals with resolver                                                |
| `packages/flutter_adaptive_charts_fs/lib/src/charts/pie_donut_chart.dart`           | Replace literals with resolver                                                |
| `.agents/skills/adaptive-cards-hostconfig-theme/SKILL.md`                           | Document `chartsLayout` section                                               |

---

### Task 1: `ChartsLayoutConfig` config classes

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/charts_layout_config.dart`

- [x] **Step 1: Write failing test**

Create `packages/flutter_adaptive_cards_fs/test/hostconfig/charts_layout_config_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartsLayoutConfig', () {
    test('deserializes from JSON fixture', () {
      final file = File('test/hostconfig/charts_layout_config.json');
      final jsonMap =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final config = ChartsLayoutConfig.fromJson(jsonMap);

      expect(config.line.height, 300);
      expect(config.line.barWidth, 4);
      expect(config.bar.height, 260);
      expect(config.bar.barWidth, 20);
      expect(config.pie.sectionRadius, 90);
      expect(config.donut.centerSpaceRadius, 35);
    });

    test('resolveLineLayout falls back when config is null', () {
      final layout = ChartsLayoutConfig.resolveLineLayout(null);
      final fallback = FallbackConfigs.chartsLayoutConfig.line;
      expect(layout.height, fallback.height);
      expect(layout.borderColor, fallback.borderColor);
    });

    test('resolveBarLayout returns HostConfig values', () {
      final config = ChartsLayoutConfig.fromJson({
        'bar': {'height': 400, 'barWidth': 24, 'barsSpace': 8},
      });
      final layout = ChartsLayoutConfig.resolveBarLayout(config);
      expect(layout.height, 400);
      expect(layout.barWidth, 24);
      expect(layout.barsSpace, 8);
    });

    test('resolvePieLayout and resolveDonutLayout are independent', () {
      final config = ChartsLayoutConfig.fromJson({
        'pie': {'sectionRadius': 110},
        'donut': {'sectionRadius': 55},
      });
      expect(ChartsLayoutConfig.resolvePieLayout(config).sectionRadius, 110);
      expect(ChartsLayoutConfig.resolveDonutLayout(config).sectionRadius, 55);
    });
  });
}
```

Create `packages/flutter_adaptive_cards_fs/test/hostconfig/charts_layout_config.json`:

```json
{
  "line": {
    "height": 300,
    "barWidth": 4,
    "borderColor": "#FF112233"
  },
  "bar": {
    "height": 260,
    "barWidth": 20
  },
  "pie": {
    "sectionRadius": 90
  },
  "donut": {
    "centerSpaceRadius": 35
  }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/hostconfig/charts_layout_config_test.dart`

Expected: FAIL — `charts_layout_config.dart` not found

- [x] **Step 3: Implement config classes**

Create `charts_layout_config.dart` with four immutable section value types and the aggregator:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// Resolved layout values for [Chart.Line] rendering.
class LineChartLayout {
  const LineChartLayout({
    required this.height,
    required this.emptyMinX,
    required this.emptyMaxX,
    required this.emptyMinY,
    required this.emptyMaxY,
    required this.degenerateRangeBump,
    required this.zeroRangeFallback,
    required this.yAxisPaddingFactor,
    required this.isCurved,
    required this.barWidth,
    required this.isStrokeCapRound,
    required this.showDots,
    required this.showAreaBelow,
    required this.showTitles,
    required this.showRightTitles,
    required this.showTopTitles,
    required this.showGrid,
    required this.showBorder,
    required this.borderColor,
    required this.borderWidth,
  });

  final double height;
  final double emptyMinX;
  final double emptyMaxX;
  final double emptyMinY;
  final double emptyMaxY;
  final double degenerateRangeBump;
  final double zeroRangeFallback;
  final double yAxisPaddingFactor;
  final bool isCurved;
  final double barWidth;
  final bool isStrokeCapRound;
  final bool showDots;
  final bool showAreaBelow;
  final bool showTitles;
  final bool showRightTitles;
  final bool showTopTitles;
  final bool showGrid;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;
}

/// Resolved layout values for bar chart types (vertical, horizontal, grouped, stacked).
class BarChartLayout {
  const BarChartLayout({
    required this.height,
    required this.emptyMaxY,
    required this.maxYPaddingFactor,
    required this.barWidth,
    required this.barsSpace,
    required this.barBorderRadius,
    required this.stackedBarBorderRadius,
    required this.alignment,
    required this.categoryAxisReservedSize,
    required this.categoryLabelFontSize,
    required this.showCategoryTitles,
  });

  final double height;
  final double emptyMaxY;
  final double maxYPaddingFactor;
  final double barWidth;
  final double barsSpace;
  final double barBorderRadius;
  final double stackedBarBorderRadius;
  final BarChartAlignmentToken alignment;
  final double categoryAxisReservedSize;
  final double categoryLabelFontSize;
  final bool showCategoryTitles;
}

/// Token for bar group alignment (maps to fl_chart `BarChartAlignment`).
enum BarChartAlignmentToken { spaceAround, spaceBetween, spaceEvenly, start, end }

/// Resolved layout values for [Chart.Pie].
class PieChartLayout {
  const PieChartLayout({
    required this.height,
    required this.centerSpaceRadius,
    required this.sectionsSpace,
    required this.sectionRadius,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.titleColor,
  });

  final double height;
  final double centerSpaceRadius;
  final double sectionsSpace;
  final double sectionRadius;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final Color titleColor;
}

/// Resolved layout values for [Chart.Donut] and [Chart.Gauge].
typedef DonutChartLayout = PieChartLayout;

/// HostConfig `chartsLayout` section for chart element dimensions and chrome.
class ChartsLayoutConfig {
  const ChartsLayoutConfig({
    required this.line,
    required this.bar,
    required this.pie,
    required this.donut,
  });

  factory ChartsLayoutConfig.fromJson(Map<String, dynamic> json) {
    return ChartsLayoutConfig(
      line: _LineChartLayoutSection.fromJson(
        json['line'] as Map<String, dynamic>? ?? {},
      ),
      bar: _BarChartLayoutSection.fromJson(
        json['bar'] as Map<String, dynamic>? ?? {},
      ),
      pie: _PieChartLayoutSection.fromJson(
        json['pie'] as Map<String, dynamic>? ?? {},
      ),
      donut: _PieChartLayoutSection.fromJson(
        json['donut'] as Map<String, dynamic>? ?? {},
        defaults: FallbackConfigs.chartsLayoutConfig.donut,
      ),
    );
  }

  final _LineChartLayoutSection line;
  final _BarChartLayoutSection bar;
  final _PieChartLayoutSection pie;
  final _PieChartLayoutSection donut;

  /// Layout for `Chart.Line`.
  static LineChartLayout resolveLineLayout(ChartsLayoutConfig? config) =>
      (config?.line ?? FallbackConfigs.chartsLayoutConfig.line).toLayout();

  /// Layout for `Chart.VerticalBar`, `Chart.HorizontalBar`, grouped, and stacked.
  static BarChartLayout resolveBarLayout(ChartsLayoutConfig? config) =>
      (config?.bar ?? FallbackConfigs.chartsLayoutConfig.bar).toLayout();

  /// Layout for `Chart.Pie`.
  static PieChartLayout resolvePieLayout(ChartsLayoutConfig? config) =>
      (config?.pie ?? FallbackConfigs.chartsLayoutConfig.pie).toLayout();

  /// Layout for `Chart.Donut` and `Chart.Gauge`.
  static DonutChartLayout resolveDonutLayout(ChartsLayoutConfig? config) =>
      (config?.donut ?? FallbackConfigs.chartsLayoutConfig.donut).toLayout();
}
```

Implement private `_LineChartLayoutSection`, `_BarChartLayoutSection`, `_PieChartLayoutSection` in the same file. Each section:

- Has a `const` constructor with all fields (used by `FallbackConfigs`).
- `factory fromJson(Map<String, dynamic> json, {_Section? defaults})` — each key optional; missing keys inherit from `defaults` or hardcoded factory defaults matching the inventory table.
- `toLayout()` returns the public resolved type.

Parsing helpers:

```dart
FontWeight _parseFontWeight(String? value, FontWeight fallback) {
  switch (value?.toLowerCase()) {
    case 'bold':
    case 'bolder':
      return FontWeight.bold;
    case 'normal':
    case 'default':
    case 'lighter':
      return FontWeight.normal;
    default:
      return fallback;
  }
}

BarChartAlignmentToken _parseBarAlignment(String? value, BarChartAlignmentToken fallback) {
  switch (value?.toLowerCase()) {
    case 'spacebetween':
      return BarChartAlignmentToken.spaceBetween;
    case 'spaceevenly':
      return BarChartAlignmentToken.spaceEvenly;
    case 'start':
      return BarChartAlignmentToken.start;
    case 'end':
      return BarChartAlignmentToken.end;
    default:
      return fallback;
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/hostconfig/charts_layout_config_test.dart`

Expected: FAIL until Task 2 adds `FallbackConfigs.chartsLayoutConfig` — proceed to Task 2, then re-run.

- [x] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/hostconfig/charts_layout_config.dart \
        packages/flutter_adaptive_cards_fs/test/hostconfig/charts_layout_config_test.dart \
        packages/flutter_adaptive_cards_fs/test/hostconfig/charts_layout_config.json
git commit -m "feat: add ChartsLayoutConfig hostconfig section"
```

---

### Task 2: Wire into HostConfig and FallbackConfigs

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/reference_resolver.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/host_config_test.dart`

- [x] **Step 1: Add fallback defaults**

In `fallback_configs.dart`, import `charts_layout_config.dart` and add:

```dart
static const chartsLayoutConfig = ChartsLayoutConfig(
  line: _LineChartLayoutSection(
    height: 250,
    emptyMinX: 0,
    emptyMaxX: 10,
    emptyMinY: 0,
    emptyMaxY: 10,
    degenerateRangeBump: 1,
    zeroRangeFallback: 10,
    yAxisPaddingFactor: 0.1,
    isCurved: true,
    barWidth: 3,
    isStrokeCapRound: true,
    showDots: false,
    showAreaBelow: false,
    showTitles: true,
    showRightTitles: false,
    showTopTitles: false,
    showGrid: true,
    showBorder: true,
    borderColor: Color(0xff37434d),
    borderWidth: 1,
  ),
  bar: _BarChartLayoutSection(
    height: 250,
    emptyMaxY: 10,
    maxYPaddingFactor: 1.2,
    barWidth: 16,
    barsSpace: 4,
    barBorderRadius: 2,
    stackedBarBorderRadius: 0,
    alignment: BarChartAlignmentToken.spaceAround,
    categoryAxisReservedSize: 32,
    categoryLabelFontSize: 10,
    showCategoryTitles: true,
  ),
  pie: _PieChartLayoutSection(
    height: 200,
    centerSpaceRadius: 0,
    sectionsSpace: 2,
    sectionRadius: 100,
    titleFontSize: 12,
    titleFontWeight: FontWeight.bold,
    titleColor: Colors.white,
  ),
  donut: _PieChartLayoutSection(
    height: 200,
    centerSpaceRadius: 40,
    sectionsSpace: 2,
    sectionRadius: 50,
    titleFontSize: 12,
    titleFontWeight: FontWeight.bold,
    titleColor: Colors.white,
  ),
);
```

> **Note:** Export the `_LineChartLayoutSection` etc. classes from `charts_layout_config.dart` (remove leading underscore or add `export`/`@visibleForTesting`) so `FallbackConfigs` can construct them. Prefer renaming to public `LineChartLayoutSection` / `BarChartLayoutSection` / `PieChartLayoutSection` since they are part of the config model.

- [x] **Step 2: Wire `HostConfig`**

In `host_config.dart`:

1. Import `charts_layout_config.dart`.
2. Add `this.chartsLayout` to `HostConfig` constructor.
3. Add field: `final ChartsLayoutConfig? chartsLayout;`
4. Parse in `fromJson`:

```dart
chartsLayout: (json['chartsLayout'] != null)
    ? ChartsLayoutConfig.fromJson(json['chartsLayout'])
    : null,
```

- [x] **Step 3: Expose via ReferenceResolver**

In `reference_resolver.dart`:

```dart
ChartsLayoutConfig? getChartsLayoutConfig() => hostConfigs.current.chartsLayout;

LineChartLayout resolveLineChartLayout() =>
    ChartsLayoutConfig.resolveLineLayout(getChartsLayoutConfig());

BarChartLayout resolveBarChartLayout() =>
    ChartsLayoutConfig.resolveBarLayout(getChartsLayoutConfig());

PieChartLayout resolvePieChartLayout() =>
    ChartsLayoutConfig.resolvePieLayout(getChartsLayoutConfig());

DonutChartLayout resolveDonutChartLayout() =>
    ChartsLayoutConfig.resolveDonutLayout(getChartsLayoutConfig());
```

- [x] **Step 4: Add HostConfig round-trip test**

In `host_config_test.dart`, add:

```dart
test('chartsLayout parses from top-level HostConfig JSON', () {
  final config = HostConfig.fromJson({
    'chartsLayout': {
      'line': {'height': 280},
      'bar': {'barWidth': 18},
    },
  });
  expect(config.chartsLayout?.line.height, 280);
  expect(config.chartsLayout?.bar.barWidth, 18);
  // Unspecified fields fall back inside section fromJson
  expect(config.chartsLayout?.pie.sectionRadius, 100);
});
```

- [x] **Step 5: Run tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/hostconfig/charts_layout_config_test.dart test/host_config_test.dart`

Expected: PASS

- [x] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart \
        packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config.dart \
        packages/flutter_adaptive_cards_fs/lib/src/reference_resolver.dart \
        packages/flutter_adaptive_cards_fs/test/host_config_test.dart
git commit -m "feat: wire chartsLayout into HostConfig and ReferenceResolver"
```

---

### Task 3: Update line chart to use layout config

**Files:**

- Modify: `packages/flutter_adaptive_charts_fs/lib/src/charts/line_chart.dart`

- [x] **Step 1: Replace hardcoded values**

At the start of `_parseData()` and `build()`, read layout once:

```dart
final layout = styleResolver.resolveLineChartLayout();
```

Replace literals:

| Before                                     | After                                                                     |
| ------------------------------------------ | ------------------------------------------------------------------------- |
| `minY = 0; maxY = 10; minX = 0; maxX = 10` | `layout.emptyMinY`, etc.                                                  |
| `maxX += 1` / `maxY += 1`                  | `+= layout.degenerateRangeBump`                                           |
| `yRange = 10`                              | `layout.zeroRangeFallback`                                                |
| `maxY += yRange * 0.1`                     | `* layout.yAxisPaddingFactor`                                             |
| `isCurved: true`                           | `layout.isCurved`                                                         |
| `barWidth: 3`                              | `layout.barWidth`                                                         |
| `isStrokeCapRound: true`                   | `layout.isStrokeCapRound`                                                 |
| `FlDotData(show: false)`                   | `FlDotData(show: layout.showDots)`                                        |
| `BarAreaData(show: false)`                 | `BarAreaData(show: layout.showAreaBelow)`                                 |
| `height: 250`                              | `layout.height`                                                           |
| `FlTitlesData(...)` const fields           | Use `layout.showTitles`, `layout.showRightTitles`, `layout.showTopTitles` |
| `FlGridData(show: true)`                   | `FlGridData(show: layout.showGrid)`                                       |
| `FlBorderData` color/width                 | `layout.showBorder`, `layout.borderColor`, `layout.borderWidth`           |

- [x] **Step 2: Run chart golden tests (non-update)**

Run: `cd packages/flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden`

Expected: PASS (no golden pixel comparison yet)

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_charts_fs/lib/src/charts/line_chart.dart
git commit -m "refactor: line chart reads layout from ChartsLayoutConfig"
```

---

### Task 4: Update bar chart to use layout config

**Files:**

- Modify: `packages/flutter_adaptive_charts_fs/lib/src/charts/bar_chart.dart`

- [x] **Step 1: Add alignment mapper**

In `bar_chart.dart` (charts package), add a local helper:

```dart
BarChartAlignment _toFlChartAlignment(BarChartAlignmentToken token) {
  switch (token) {
    case BarChartAlignmentToken.spaceBetween:
      return BarChartAlignment.spaceBetween;
    case BarChartAlignmentToken.spaceEvenly:
      return BarChartAlignment.spaceEvenly;
    case BarChartAlignmentToken.start:
      return BarChartAlignment.start;
    case BarChartAlignmentToken.end:
      return BarChartAlignment.end;
    case BarChartAlignmentToken.spaceAround:
      return BarChartAlignment.spaceAround;
  }
}
```

Import `charts_layout_config.dart` via deep import:

```dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
```

- [x] **Step 2: Replace hardcoded values**

```dart
final layout = styleResolver.resolveBarChartLayout();
```

| Before                          | After                                                  |
| ------------------------------- | ------------------------------------------------------ |
| `maxY = 10` (safety)            | `layout.emptyMaxY`                                     |
| `width: 16`                     | `layout.barWidth`                                      |
| `barsSpace: 4`                  | `layout.barsSpace`                                     |
| `BorderRadius.circular(2)`      | `BorderRadius.circular(layout.barBorderRadius)`        |
| `BorderRadius.zero` (stacked)   | `BorderRadius.circular(layout.stackedBarBorderRadius)` |
| `maxY *= 1.2`                   | `maxY *= layout.maxYPaddingFactor`                     |
| `height: 250`                   | `layout.height`                                        |
| `BarChartAlignment.spaceAround` | `_toFlChartAlignment(layout.alignment)`                |
| `reservedSize: 32`              | `layout.categoryAxisReservedSize`                      |
| `fontSize: 10`                  | `layout.categoryLabelFontSize`                         |
| `showTitles: true`              | `layout.showCategoryTitles`                            |

Remove the `// TODO(username): make configurable` comment on bar width.

- [x] **Step 3: Run tests**

Run: `cd packages/flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden`

Expected: PASS

- [x] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_charts_fs/lib/src/charts/bar_chart.dart
git commit -m "refactor: bar chart reads layout from ChartsLayoutConfig"
```

---

### Task 5: Update pie/donut chart to use layout config

**Files:**

- Modify: `packages/flutter_adaptive_charts_fs/lib/src/charts/pie_donut_chart.dart`

- [x] **Step 1: Replace hardcoded values**

In `_parseData()` and `build()`:

```dart
final layout = widget.isDonut
    ? styleResolver.resolveDonutChartLayout()
    : styleResolver.resolvePieChartLayout();
```

| Before                                           | After                                                                                                     |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `radius: widget.isDonut ? 50 : 100`              | `layout.sectionRadius`                                                                                    |
| `titleStyle: const TextStyle(fontSize: 12, ...)` | `TextStyle(fontSize: layout.titleFontSize, fontWeight: layout.titleFontWeight, color: layout.titleColor)` |
| `height: 200`                                    | `layout.height`                                                                                           |
| `centerSpaceRadius: widget.isDonut ? 40 : 0`     | `layout.centerSpaceRadius`                                                                                |
| `sectionsSpace: 2`                               | `layout.sectionsSpace`                                                                                    |

- [x] **Step 2: Run tests**

Run: `cd packages/flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden`

Expected: PASS

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_charts_fs/lib/src/charts/pie_donut_chart.dart
git commit -m "refactor: pie/donut chart reads layout from ChartsLayoutConfig"
```

---

### Task 6: JSON schema and skill doc

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config_schema.json`
- Modify: `.agents/skills/adaptive-cards-hostconfig-theme/SKILL.md`

- [x] **Step 1: Add schema definitions**

Add to `host_config_schema.json` (after `chartColors` if present, else after `progressColors`):

```json
"ChartsLayoutConfig": {
  "type": "object",
  "properties": {
    "line": { "$ref": "#/definitions/LineChartLayoutSection" },
    "bar": { "$ref": "#/definitions/BarChartLayoutSection" },
    "pie": { "$ref": "#/definitions/PieChartLayoutSection" },
    "donut": { "$ref": "#/definitions/PieChartLayoutSection" }
  }
}
```

Add subsection definitions with all properties from the inventory table (numbers for dimensions, booleans for show/hide flags, hex strings for colors, string enum for `alignment` and `titleFontWeight`).

Add top-level HostConfig property:

```json
"chartsLayout": { "$ref": "#/definitions/ChartsLayoutConfig" }
```

- [x] **Step 2: Update hostconfig skill**

In `adaptive-cards-hostconfig-theme/SKILL.md`, under the Charts section, add:

````markdown
### Chart layout (`chartsLayout`)

```dart
final layout = resolver.resolveLineChartLayout();
// Also: resolveBarChartLayout(), resolvePieChartLayout(), resolveDonutChartLayout()
```
````

JSON example:

```json
{
  "chartsLayout": {
    "line": { "height": 250, "barWidth": 3, "borderColor": "#37434d" },
    "bar": { "height": 250, "barWidth": 16, "barsSpace": 4 },
    "pie": { "height": 200, "sectionRadius": 100 },
    "donut": { "centerSpaceRadius": 40, "sectionRadius": 50 }
  }
}
```

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config_schema.json \
        .agents/skills/adaptive-cards-hostconfig-theme/SKILL.md
git commit -m "docs: add chartsLayout to HostConfig schema and skill"
```

---

### Task 7: Golden verification and HostConfig override test

**Files:**

- Create: `packages/flutter_adaptive_charts_fs/test/charts_layout_config_test.dart`

- [x] **Step 1: Add widget test proving HostConfig overrides work**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('custom chartsLayout height is applied to line chart', (tester) async {
    const key = ValueKey('line');
    final hostConfigs = HostConfigs(
      light: HostConfig(
        chartsLayout: ChartsLayoutConfig.fromJson({
          'line': {'height': 400},
        }),
      ),
    );
    await tester.pumpWidget(
      getTestWidgetFromPath(
        path: 'v1.6/chart_line.json',
        key: key,
        hostConfigs: hostConfigs,
      ),
    );
    await tester.pumpAndSettle();

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(LineChart),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(sizedBox.height, 400);
  });
}
```

Adjust finder if `SizedBox` wraps `LineChart` (parent, not descendant) — use `find.ancestor` if needed.

- [x] **Step 2: Run golden tests with default config**

Run: `cd packages/flutter_adaptive_charts_fs && fvm flutter test --tags=golden`

Expected: PASS with **no** golden file updates (defaults match previous literals). If any golden fails, fix default values in `FallbackConfigs` — do **not** update goldens unless intentional visual change.

- [x] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_charts_fs/test/charts_layout_config_test.dart
git commit -m "test: verify chartsLayout HostConfig overrides chart rendering"
```

---

## Final Task: Full verification

- [x] **Step 1: Repo analyze**

Run: `fvm flutter analyze`

Expected: No issues found

- [x] **Step 2: Main library tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`

Expected: All tests passed

- [x] **Step 3: Charts package tests**

Run: `cd packages/flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden`

Expected: All tests passed

- [x] **Step 4: Charts golden suite (optional CI parity)**

Run: `cd packages/flutter_adaptive_charts_fs && fvm flutter test --tags=golden`

Expected: All tests passed, no `--update-goldens` needed

---

## Completion notes

Delivered as a single squashed commit in PR #18 rather than the per-task commits listed above. Verification run when updating this plan (2026-06-16):

| Step         | Command                                                                            | Result           |
| ------------ | ---------------------------------------------------------------------------------- | ---------------- |
| Analyze      | `fvm flutter analyze`                                                              | No issues found  |
| Cards tests  | `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`  | All passed (432) |
| Charts tests | `cd packages/flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden` | All passed (13)  |
| Golden suite | `cd packages/flutter_adaptive_charts_fs && fvm flutter test --tags=golden`         | All passed (8)   |

### Open work items

**None.** All tasks (1–7) and final verification are complete.

---

## Example HostConfig JSON (host apps)

```json
{
  "chartColors": {
    "defaultPalette": ["#0078D4", "#107C10", "#FF8C00"],
    "defaultColor": "#0078D4"
  },
  "chartsLayout": {
    "line": {
      "height": 250,
      "barWidth": 3,
      "isCurved": true,
      "borderColor": "#37434d",
      "yAxisPaddingFactor": 0.1
    },
    "bar": {
      "height": 250,
      "barWidth": 16,
      "barsSpace": 4,
      "maxYPaddingFactor": 1.2,
      "categoryLabelFontSize": 10
    },
    "pie": {
      "height": 200,
      "sectionRadius": 100,
      "sectionsSpace": 2
    },
    "donut": {
      "height": 200,
      "centerSpaceRadius": 40,
      "sectionRadius": 50
    }
  }
}
```
