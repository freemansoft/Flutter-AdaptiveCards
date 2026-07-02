# P3 Spec-Compliance: Element & Feature Completeness Implementation Plan

> **Status: ✅ Complete** — shipped in PR #35. Archived 2026-07-02.
> Checkbox state below is historical and was not ticked at merge time.

---

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the P3 spec-compliance gaps from the [audit addendum](../specs/2026-06-17-spec-compliance-audit-addendum.md) and [main audit](../specs/2026-06-17-spec-compliance-audit.md): action overflow menu, Badge/CompoundButton/Carousel property completeness, `Image.backgroundColor`, `iconPlacement`, `Media.captionSources`, chart datetime axes, TextBlock markdown `maxLines`, and templating collection/date functions.

**Architecture:** Independent, mostly per-property additions across three packages. Each task is self-contained, TDD-first, and commits separately. Items are grouped into three phases by package so each phase is independently testable. Where rendering would balloon (Media VTT captions, lambda-based `select`/`where`), the task is scoped to the deterministic, well-bounded subset and the remainder explicitly deferred.

**Tech Stack:** Dart / Flutter, FVM (`fvm flutter ...`), Riverpod, `fl_chart`, `package:flutter_test`. All commands prefixed with `fvm`. Phase A runs from `packages/flutter_adaptive_cards_fs/`, Phase B from `packages/flutter_adaptive_charts_fs/`, Phase C from `packages/flutter_adaptive_template_fs/`.

**Commit gate:** This repo requires explicit user confirmation before every `git commit`. When executing, stop at each commit step and surface the diff for confirmation rather than committing automatically.

---

## File Structure

**Phase A — `flutter_adaptive_cards_fs`:**
- `lib/src/cards/elements/image.dart` — add `backgroundColor` behind the image.
- `lib/src/cards/actions/icon_button.dart` — honor `iconPlacement: aboveTitle`.
- `lib/src/cards/elements/action_set.dart` — split actions into inline + overflow menu by `mode`.
- `lib/src/cards/elements/badge.dart` — add `shape` (corner radius) support.
- `lib/src/cards/elements/compound_button.dart` — add `badge` label.
- `lib/src/cards/elements/carousel.dart` — add `timer` auto-advance, `orientation`, `loop`.
- `lib/src/cards/elements/text_block.dart` — clip markdown to `maxLines` height.
- `lib/src/utils/media_caption_source.dart` — **create**: typed `CaptionSource` model + parser.
- `lib/src/cards/elements/media.dart` — parse `captionSources` into the model.

**Phase B — `flutter_adaptive_charts_fs`:**
- `lib/src/charts/chart_x_value.dart` — **create**: pure `parseChartXValue` helper.
- `lib/src/charts/line_chart.dart` — use the helper for datetime X values.

**Phase C — `flutter_adaptive_template_fs`:**
- `lib/src/evaluator.dart` — add eager collection + date functions.

---

# Phase A — flutter_adaptive_cards_fs

All Phase A commands run from `packages/flutter_adaptive_cards_fs/`.

## Task A1: `Image.backgroundColor`

The spec `Image.backgroundColor` paints a solid color behind the image (visible through transparent PNGs). Currently ignored.

**Files:**
- Modify: `lib/src/cards/elements/image.dart` (in `build`, wrap the image)
- Test: `test/elements/image_background_color_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/elements/image_background_color_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Image renders a ColoredBox for backgroundColor', (
    WidgetTester tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Image',
          'url': 'https://example.com/x.png',
          'backgroundColor': '#FF0000',
          'altText': 'red-backed',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'image bg'),
    );
    await tester.pump();

    final coloredBox = tester.widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((b) => b.color == const Color(0xFFFF0000));
    expect(coloredBox, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/elements/image_background_color_test.dart`
Expected: FAIL — no red `ColoredBox` exists.

- [ ] **Step 3: Implement**

In `lib/src/cards/elements/image.dart` `build`, after the `image` widget is constructed (the `Widget image = AdaptiveTappable(...)` block) and before the `if (isPerson)` block, insert a background wrap:

```dart
    final bgColorString = adaptiveMap['backgroundColor']?.toString();
    final bgColor = parseColor(bgColorString);
    if (bgColor != null) {
      image = ColoredBox(color: bgColor, child: image);
    }
```

If `parseColor` is not already imported/available in this file, use the existing color parser used elsewhere in the package. Confirm the helper name first:

Run: `grep -rn "Color? parseColor\|Color parseColor\|parseColor(" lib/src/utils`

Use whatever the confirmed helper is (e.g. `parseColor`/`parseHexColor`). If it lives in `lib/src/utils/utils.dart`, it is already imported via `package:flutter_adaptive_cards_fs/src/utils/utils.dart` at the top of `image.dart` — verify and add the import only if missing.

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/elements/image_background_color_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit** (surface diff, await confirmation)

```bash
git add lib/src/cards/elements/image.dart test/elements/image_background_color_test.dart
git commit -m "feat(image): paint backgroundColor behind image"
```

---

## Task A2: Action `iconPlacement: aboveTitle`

HostConfig `actions.iconPlacement` (`aboveTitle` | `leftOfTitle`) is parsed (`actions_config.dart:53`, default `aboveTitle`) but `IconButtonAction` always renders icon left of the label. Honor `aboveTitle` by stacking icon over label.

**Files:**
- Modify: `lib/src/cards/actions/icon_button.dart`
- Test: `test/actions/icon_placement_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/actions/icon_placement_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_configs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('aboveTitle places action icon above the label in a Column', (
    WidgetTester tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [],
      'actions': [
        {
          'type': 'Action.Submit',
          'title': 'Go',
          'iconUrl': 'https://example.com/i.png',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'icon above',
        hostConfigs: HostConfigs.fromConfigMaps(
          lightConfigMap: {
            'actions': {'iconPlacement': 'aboveTitle'},
          },
        ),
      ),
    );
    await tester.pump();

    // The action button uses a Column when iconPlacement is aboveTitle.
    final buttonColumn = find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.byType(Column),
    );
    expect(buttonColumn, findsOneWidget);
  });
}
```

> Before writing the test, confirm the `HostConfigs` test constructor. Run:
> `grep -rn "HostConfigs.fromConfigMaps\|factory HostConfigs\|HostConfigs(" lib/src/hostconfig/host_configs.dart`
> If the constructor differs, adapt the `hostConfigs:` argument to the confirmed factory (the test harness `getTestWidgetFromMap` accepts a `HostConfigs? hostConfigs` parameter — see `test_widget_helpers.dart`).

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/actions/icon_placement_test.dart`
Expected: FAIL — current code uses `ElevatedButton.icon` (a Row), so no descendant `Column`.

- [ ] **Step 3: Implement**

In `lib/src/cards/actions/icon_button.dart` `build`, replace the `final theButton = (resolvedIconUrl != null) ? ElevatedButton.icon(...) : ElevatedButton(...)` block with placement-aware construction:

```dart
    final iconPlacement =
        resolver.getActionsConfig()?.iconPlacement ?? 'aboveTitle';

    Widget theButton;
    if (resolvedIconUrl == null) {
      theButton = ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Text(title),
      );
    } else if (iconPlacement == 'aboveTitle') {
      theButton = ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdaptiveImageUtils.getImage(
              resolvedIconUrl,
              height: 24,
              semanticsLabel: title,
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      );
    } else {
      theButton = ElevatedButton.icon(
        onPressed: onPressed,
        style: buttonStyle,
        icon: AdaptiveImageUtils.getImage(
          resolvedIconUrl,
          height: 36,
          semanticsLabel: title,
        ),
        label: Text(title),
      );
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/actions/icon_placement_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit** (surface diff, await confirmation)

```bash
git add lib/src/cards/actions/icon_button.dart test/actions/icon_placement_test.dart
git commit -m "feat(actions): honor iconPlacement aboveTitle for action buttons"
```

---

## Task A3: Action `mode` + overflow menu

`action_set.dart` truncates to `maxActions` with `.take()`, silently dropping extras, and never reads action `mode`. Per spec, `mode: secondary` actions (and any beyond `maxActions`) belong in an overflow "•••" `PopupMenuButton`; `primary` actions render inline.

**Files:**
- Modify: `lib/src/cards/elements/action_set.dart`
- Test: `test/elements/action_set_overflow_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/elements/action_set_overflow_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('secondary-mode action moves to an overflow PopupMenuButton', (
    WidgetTester tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [],
      'actions': [
        {'type': 'Action.Submit', 'title': 'Primary'},
        {'type': 'Action.Submit', 'title': 'Hidden', 'mode': 'secondary'},
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'overflow'),
    );
    await tester.pump();

    // Primary renders inline; secondary is in the overflow menu (not visible
    // until opened), so an overflow button exists and 'Hidden' is not inline.
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
    expect(find.byType(PopupMenuButton<int>), findsOneWidget);

    // Opening the overflow menu reveals the secondary action.
    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();
    expect(find.text('Hidden'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/elements/action_set_overflow_test.dart`
Expected: FAIL — no `PopupMenuButton`; 'Hidden' is either inline or dropped.

- [ ] **Step 3: Implement the action split**

In `lib/src/cards/elements/action_set.dart`, replace the action-building block (the `// Limit actions by maxActions` section) with a primary/overflow split. Read the current `didChangeDependencies`/init method that builds `activeActions`, and change it so it computes two lists:

```dart
    final resolver = styleResolver;
    final actionsConfig = resolver.getActionsConfig();

    activeActions.clear();
    overflowActionMaps.clear();
    final List actionMaps = adaptiveMap['actions'] as List<dynamic>? ?? [];
    final int maxActions = actionsConfig?.maxActions ?? 10;

    final List<Map<String, dynamic>> primary = [];
    final List<Map<String, dynamic>> overflow = [];
    for (final raw in actionMaps) {
      final map = Map<String, dynamic>.from(raw as Map);
      final isSecondary =
          map['mode']?.toString().toLowerCase() == 'secondary';
      if (isSecondary || primary.length >= maxActions) {
        overflow.add(map);
      } else {
        primary.add(map);
      }
    }

    overflowActionMaps.addAll(overflow);
    activeActions.addAll(
      primary.map((map) => cardTypeRegistry.getAction(map: map)),
    );
```

Add the `overflowActionMaps` field next to `activeActions`:

```dart
  /// Action JSON maps routed to the overflow "•••" menu (secondary mode or
  /// beyond `maxActions`).
  final List<Map<String, dynamic>> overflowActionMaps = [];
```

- [ ] **Step 4: Render the overflow menu**

In `build`, inside the `Wrap` children, after the inline actions, add the overflow button when `overflowActionMaps` is non-empty. Locate the `Wrap(... children: ...)` that renders `activeActions` and append:

```dart
            if (overflowActionMaps.isNotEmpty)
              PopupMenuButton<int>(
                key: const Key('action_set_overflow'),
                icon: const Icon(Icons.more_horiz),
                itemBuilder: (context) => [
                  for (var i = 0; i < overflowActionMaps.length; i++)
                    PopupMenuItem<int>(
                      value: i,
                      child: Text(
                        overflowActionMaps[i]['title']?.toString() ?? '',
                      ),
                    ),
                ],
                onSelected: (i) {
                  final action =
                      cardTypeRegistry.getAction(map: overflowActionMaps[i]);
                  action.onTapped(context);
                },
              ),
```

> Before finalizing, confirm how an inline action is invoked so the overflow `onSelected` mirrors it. Run:
> `grep -rn "onTapped\|\.tap(\|getAction" lib/src/cards/elements/action_set.dart lib/src/registry.dart`
> If actions are invoked via `.tap(context: ..., rawAdaptiveCardState: ..., adaptiveMap: ...)` rather than `onTapped(context)`, adapt the `onSelected` body to call the same entry point the inline buttons use (reuse the exact invocation the inline `IconButtonAction.onTapped` wires up).

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/elements/action_set_overflow_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the existing action_set tests to check for regressions**

Run: `fvm flutter test test/elements/ test/actions/`
Expected: PASS (no regressions in existing action rendering).

- [ ] **Step 7: Commit** (surface diff, await confirmation)

```bash
git add lib/src/cards/elements/action_set.dart test/elements/action_set_overflow_test.dart
git commit -m "feat(actions): route secondary/overflow actions to a '...' menu"
```

---

## Task A4: Badge `shape`

Badge currently always renders a pill (`BorderRadius.circular(12)`). The hub `shape` property is `square` | `rounded` | `circular` (default per host; treat absent as the current pill). Map `shape` to corner radius. (`icon` already renders via `iconUrl`; color `style` is already wired via the mixin — only `shape` is missing.)

**Files:**
- Modify: `lib/src/cards/elements/badge.dart`
- Test: `test/elements/badge_shape_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/elements/badge_shape_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

BoxDecoration _badgeDecoration(WidgetTester tester) {
  final container = tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (c) => c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).borderRadius != null,
      );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('square shape uses a small corner radius', (tester) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {'type': 'Badge', 'text': 'New', 'shape': 'square'},
      ],
    };
    await tester.pumpWidget(getTestWidgetFromMap(map: card, title: 'sq'));
    await tester.pump();

    expect(
      _badgeDecoration(tester).borderRadius,
      BorderRadius.circular(2),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/elements/badge_shape_test.dart`
Expected: FAIL — radius is hardcoded to `circular(12)`.

- [ ] **Step 3: Implement**

In `lib/src/cards/elements/badge.dart` `build`, after reading `size`, add:

```dart
    final shape = adaptiveMap['shape']?.toString().toLowerCase() ?? 'circular';
    final BorderRadius borderRadius = switch (shape) {
      'square' => BorderRadius.circular(2),
      'rounded' => BorderRadius.circular(6),
      _ => BorderRadius.circular(12),
    };
```

Then change the `Container`'s decoration from `borderRadius: BorderRadius.circular(12), // Pill shape` to:

```dart
        borderRadius: borderRadius,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/elements/badge_shape_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit** (surface diff, await confirmation)

```bash
git add lib/src/cards/elements/badge.dart test/elements/badge_shape_test.dart
git commit -m "feat(badge): map shape (square/rounded/circular) to corner radius"
```

---

## Task A5: CompoundButton `badge`

CompoundButton reads `title`, `description`, `iconUrl` but not the hub `badge` property (a short label shown as a badge/pill on the button). Render it when present.

**Files:**
- Modify: `lib/src/cards/elements/compound_button.dart`
- Test: `test/elements/compound_button_badge_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/elements/compound_button_badge_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('CompoundButton renders its badge label', (tester) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'CompoundButton',
          'title': 'Inbox',
          'description': 'Your mail',
          'badge': '3',
        },
      ],
    };
    await tester.pumpWidget(getTestWidgetFromMap(map: card, title: 'cb'));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/elements/compound_button_badge_test.dart`
Expected: FAIL — `'3'` is never rendered.

- [ ] **Step 3: Implement**

In `lib/src/cards/elements/compound_button.dart`, add a field and parse it (next to `description`):

```dart
  /// Optional short badge label from `badge`.
  late String? badge;
```

In `didChangeDependencies`/`initState` (wherever `description` is read, ~line 46):

```dart
    badge = adaptiveMap['badge']?.toString();
```

In `build`, add the badge as a trailing pill. Locate the `Row` that lays out icon + title/description and append a trailing widget:

```dart
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
```

> Confirm the exact `Row`/`children` structure before editing. Run:
> `sed -n '60,100p' lib/src/cards/elements/compound_button.dart`
> Append the badge widget to the outermost horizontal `children` list so it sits to the right of the title/description block.

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/elements/compound_button_badge_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit** (surface diff, await confirmation)

```bash
git add lib/src/cards/elements/compound_button.dart test/elements/compound_button_badge_test.dart
git commit -m "feat(compound-button): render badge label"
```

---

## Task A6: Carousel `timer`, `orientation`, `loop`

Carousel reads only `pages` and `initialPage`. Add: `timer` (ms auto-advance), `orientation` (`horizontal` default | `vertical`), `loop` (wrap past the last page).

**Files:**
- Modify: `lib/src/cards/elements/carousel.dart`
- Test: `test/elements/carousel_behavior_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/elements/carousel_behavior_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('vertical orientation sets PageView scrollDirection', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Carousel',
          'orientation': 'vertical',
          'pages': [
            {'type': 'CarouselPage', 'items': [
              {'type': 'TextBlock', 'text': 'A'},
            ]},
            {'type': 'CarouselPage', 'items': [
              {'type': 'TextBlock', 'text': 'B'},
            ]},
          ],
        },
      ],
    };
    await tester.pumpWidget(getTestWidgetFromMap(map: card, title: 'carousel'));
    await tester.pump();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.scrollDirection, Axis.vertical);
  });

  testWidgets('timer auto-advances to the next page', (tester) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Carousel',
          'timer': 1000,
          'pages': [
            {'type': 'CarouselPage', 'items': [
              {'type': 'TextBlock', 'text': 'A'},
            ]},
            {'type': 'CarouselPage', 'items': [
              {'type': 'TextBlock', 'text': 'B'},
            ]},
          ],
        },
      ],
    };
    await tester.pumpWidget(getTestWidgetFromMap(map: card, title: 'timer'));
    await tester.pump();

    final controller = tester.widget<PageView>(find.byType(PageView)).controller;
    expect(controller!.page?.round() ?? controller.initialPage, 0);

    // Advance past the timer interval and let the animation settle.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page?.round(), 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/elements/carousel_behavior_test.dart`
Expected: FAIL — `scrollDirection` defaults to horizontal; no auto-advance.

- [ ] **Step 3: Add the fields and parsing**

In `lib/src/cards/elements/carousel.dart` `AdaptiveCarouselState`, add fields next to `initialPage`:

```dart
  /// Auto-advance interval in milliseconds from `timer`; null disables it.
  int? autoAdvanceMs;

  /// Scroll axis from `orientation` (`vertical` → [Axis.vertical]).
  Axis scrollAxis = Axis.horizontal;

  /// Whether to wrap past the last page from `loop`.
  bool loop = false;

  Timer? _autoAdvanceTimer;
```

In `initState`, after `pageController = ...`:

```dart
    autoAdvanceMs = adaptiveMap['timer'] as int?;
    scrollAxis = adaptiveMap['orientation']?.toString().toLowerCase() == 'vertical'
        ? Axis.vertical
        : Axis.horizontal;
    loop = adaptiveMap['loop'] == true;
    _startAutoAdvance();
```

Add the timer methods (anywhere in the State class):

```dart
  void _startAutoAdvance() {
    final ms = autoAdvanceMs;
    if (ms == null || ms <= 0 || pages.length < 2) return;
    _autoAdvanceTimer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted) return;
      var next = _currentIndex + 1;
      if (next >= pages.length) {
        if (!loop) {
          _autoAdvanceTimer?.cancel();
          return;
        }
        next = 0;
      }
      _goToPage(next);
    });
  }
```

In `dispose`, before `pageController.dispose()`:

```dart
    _autoAdvanceTimer?.cancel();
```

- [ ] **Step 4: Wire orientation into the PageView**

In `build`, change `PageView.builder(controller: pageController, ...)` to include:

```dart
              child: PageView.builder(
                controller: pageController,
                scrollDirection: scrollAxis,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final pageContent = pages[index];
                  return cardTypeRegistry.getElement(map: pageContent);
                },
              ),
```

(`dart:async` is already imported at the top of `carousel.dart` — `Timer` is available.)

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/elements/carousel_behavior_test.dart`
Expected: PASS (both tests).

- [ ] **Step 6: Commit** (surface diff, await confirmation)

```bash
git add lib/src/cards/elements/carousel.dart test/elements/carousel_behavior_test.dart
git commit -m "feat(carousel): add timer auto-advance, orientation, and loop"
```

---

## Task A7: Media `captionSources` parsing

Media reads `sources`/`poster`/`altText` but ignores `captionSources` (closed-caption track descriptors: `{mimeType, label, url}`). **Scope:** parse `captionSources` into a typed model and expose it on the state (mirroring `MediaSource`). Actual VTT track rendering on `video_player` is out of scope and noted as a follow-up.

**Files:**
- Create: `lib/src/utils/media_caption_source.dart`
- Modify: `lib/src/cards/elements/media.dart` (parse into the model)
- Test: `test/utils/media_caption_source_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/utils/media_caption_source_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/utils/media_caption_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('captionSourcesFromJsonList', () {
    test('parses a list of caption descriptors', () {
      final result = captionSourcesFromJsonList([
        {'mimeType': 'vtt', 'label': 'English', 'url': 'https://x/en.vtt'},
        {'mimeType': 'vtt', 'label': 'French', 'url': 'https://x/fr.vtt'},
      ]);
      expect(result, hasLength(2));
      expect(result[0].label, 'English');
      expect(result[0].url, 'https://x/en.vtt');
      expect(result[0].mimeType, 'vtt');
    });

    test('returns empty list for null or non-list input', () {
      expect(captionSourcesFromJsonList(null), isEmpty);
      expect(captionSourcesFromJsonList('nope'), isEmpty);
    });

    test('skips entries without a url', () {
      final result = captionSourcesFromJsonList([
        {'mimeType': 'vtt', 'label': 'NoUrl'},
        {'mimeType': 'vtt', 'label': 'Ok', 'url': 'https://x/a.vtt'},
      ]);
      expect(result, hasLength(1));
      expect(result[0].label, 'Ok');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/utils/media_caption_source_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create the model**

Create `lib/src/utils/media_caption_source.dart`:

```dart
/// A single closed-caption track descriptor for a `Media` element, parsed
/// from a `captionSources` entry. Hosts that support caption rendering read
/// [url] and [mimeType]; [label] is the human-readable track name.
class CaptionSource {
  /// Creates a caption source from its parsed fields.
  const CaptionSource({
    required this.mimeType,
    required this.url,
    required this.label,
  });

  /// MIME type of the caption track (e.g. `vtt`).
  final String mimeType;

  /// Absolute or data URL of the caption track.
  final String url;

  /// Human-readable track label shown in caption selectors.
  final String label;
}

/// Parses a `captionSources` JSON array into [CaptionSource]s, skipping any
/// entry without a `url`. Returns an empty list for null or non-list input.
List<CaptionSource> captionSourcesFromJsonList(dynamic raw) {
  if (raw is! List) return const [];
  final result = <CaptionSource>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final url = entry['url']?.toString();
    if (url == null || url.isEmpty) continue;
    result.add(
      CaptionSource(
        mimeType: entry['mimeType']?.toString() ?? '',
        url: url,
        label: entry['label']?.toString() ?? '',
      ),
    );
  }
  return result;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/utils/media_caption_source_test.dart`
Expected: PASS.

- [ ] **Step 5: Parse captionSources in Media**

In `lib/src/cards/elements/media.dart`, add an import:

```dart
import 'package:flutter_adaptive_cards_fs/src/utils/media_caption_source.dart';
```

Add a field on the Media state (next to the `sources`/`altText` fields):

```dart
  /// Caption tracks parsed from `captionSources` (rendering is host-dependent).
  late List<CaptionSource> captionSources;
```

Where `sources` is parsed in the init method (~line 64), add:

```dart
    captionSources = captionSourcesFromJsonList(adaptiveMap['captionSources']);
```

> This wires parsing only; no UI consumes `captionSources` yet. That is intentional and bounded — leave a one-line `// TODO` referencing VTT rendering as a follow-up so the field's purpose is clear.

- [ ] **Step 6: Run the Media tests for regressions**

Run: `fvm flutter test test/utils/media_caption_source_test.dart && fvm flutter analyze lib/src/cards/elements/media.dart`
Expected: tests PASS; analyze reports no new issues.

- [ ] **Step 7: Commit** (surface diff, await confirmation)

```bash
git add lib/src/utils/media_caption_source.dart lib/src/cards/elements/media.dart test/utils/media_caption_source_test.dart
git commit -m "feat(media): parse captionSources into typed model"
```

---

## Task A8: TextBlock markdown `maxLines` (height clip)

The plain-text path honors `maxLines`; the markdown path (`getMarkdownText`) ignores it because `MarkdownBody` has no `maxLines`. Apply a height clip: constrain the markdown to approximately `maxLines` line-heights and clip the overflow. This is a partial implementation (clip, not ellipsis) — the only feasible option with the markdown library.

**Files:**
- Modify: `lib/src/cards/elements/text_block.dart` (`getMarkdownText`)
- Test: `test/elements/text_block_markdown_maxlines_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/elements/text_block_markdown_maxlines_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('markdown TextBlock with maxLines is height-clipped', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'line one\n\nline two\n\nline three\n\nline four',
          'wrap': true,
          'maxLines': 2,
        },
      ],
    };
    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'md maxlines'),
    );
    await tester.pump();

    // A maxLines clip wraps the markdown in a ConstrainedBox with a bounded
    // maxHeight (keyed for the test).
    expect(find.byKey(const Key('markdown_maxlines_clip')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/elements/text_block_markdown_maxlines_test.dart`
Expected: FAIL — no clip widget.

- [ ] **Step 3: Implement the clip**

In `lib/src/cards/elements/text_block.dart` `getMarkdownText`, wrap the returned `MarkdownBody` so that when `maxLines` is a positive, finite limit (not the "unbounded" sentinel used for `wrap`), it is clipped. First confirm the sentinel `resolveMaxLines` returns for "no limit":

Run: `grep -rn "resolveMaxLines" lib/src` and read the resolver to see what value means "unbounded" (commonly a large int or a specific constant).

Then change `getMarkdownText` to:

```dart
  Widget getMarkdownText({required BuildContext context}) {
    final markdown = MarkdownBody(
      key: generateWidgetKey(adaptiveMap),
      data: text,
      styleSheet: loadMarkdownStyleSheet(context),
      onTapLink: (text, href, title) {
        if (href != null) {
          action.tap(
            context: context,
            rawAdaptiveCardState: rawRootCardWidgetState,
            adaptiveMap: adaptiveMap,
            altUrl: href,
          );
        }
      },
    );

    // The markdown library cannot enforce maxLines; approximate it by
    // clipping to maxLines line-heights when an explicit limit is set.
    final hasExplicitLimit =
        adaptiveMap['maxLines'] != null && maxLines > 0 && maxLines < 1000000;
    if (!hasExplicitLimit) return markdown;

    final fontSize = loadMarkdownStyleSheet(context).p?.fontSize ?? 14.0;
    final maxHeight = fontSize * 1.5 * maxLines;
    return ClipRect(
      key: const Key('markdown_maxlines_clip'),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: markdown,
      ),
    );
  }
```

> Adjust the `maxLines < 1000000` guard to match the actual unbounded sentinel found via the `resolveMaxLines` grep. If `resolveMaxLines` returns `null`-equivalent or a named constant for "no limit", gate on `adaptiveMap['maxLines'] != null` alone and the resolved positive value.

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/elements/text_block_markdown_maxlines_test.dart`
Expected: PASS.

- [ ] **Step 5: Run existing text_block tests for regressions**

Run: `fvm flutter test test/elements/text_block_test.dart test/elements/rich_text_block_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit** (surface diff, await confirmation)

```bash
git add lib/src/cards/elements/text_block.dart test/elements/text_block_markdown_maxlines_test.dart
git commit -m "feat(text-block): height-clip markdown to maxLines"
```

---

## Task A9: Phase A changelog

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [ ] **Step 1: Add bullets under `## [Unreleased]`**

Under the existing `### Added` / add a `### Changed` if needed:

```markdown
- **`Image.backgroundColor`** painted behind the image.
- **Action `iconPlacement: aboveTitle`** stacks the icon over the action label.
- **Action `mode: secondary` + overflow menu:** secondary actions and any beyond `maxActions` move to a "•••" `PopupMenuButton` instead of being dropped.
- **Badge `shape`** (`square`/`rounded`/`circular`) mapped to corner radius.
- **CompoundButton `badge`** label rendered.
- **Carousel `timer` (auto-advance), `orientation`, `loop`** supported.
- **Media `captionSources`** parsed into a typed `CaptionSource` model (rendering host-dependent).
- **TextBlock markdown `maxLines`** now height-clips the rendered markdown.
```

- [ ] **Step 2: Commit** (surface diff, await confirmation)

```bash
git add packages/flutter_adaptive_cards_fs/CHANGELOG.md
git commit -m "docs(changelog): note P3 element-completeness additions"
```

- [ ] **Step 3: Phase A full verification**

Run:
```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter analyze
fvm flutter test --exclude-tags=golden
```
Expected: analyze clean; all tests pass. Record pass/skip/fail counts.

---

# Phase B — flutter_adaptive_charts_fs

All Phase B commands run from `packages/flutter_adaptive_charts_fs/`.

## Task B1: Chart datetime X axis

`line_chart.dart` collapses any non-numeric `x` (e.g. an ISO datetime string) to `0.0`, so time-series points stack at the origin. Extract a pure `parseChartXValue` helper that maps ISO datetime strings to epoch-milliseconds doubles, and use it.

**Files:**
- Create: `lib/src/charts/chart_x_value.dart`
- Modify: `lib/src/charts/line_chart.dart`
- Test: `test/charts/chart_x_value_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/charts/chart_x_value_test.dart`:

```dart
import 'package:flutter_adaptive_charts_fs/src/charts/chart_x_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseChartXValue', () {
    test('passes numeric values through', () {
      expect(parseChartXValue(3), 3.0);
      expect(parseChartXValue(2.5), 2.5);
    });

    test('parses ISO datetime to epoch milliseconds', () {
      final expected =
          DateTime.parse('2026-06-17T00:00:00Z').millisecondsSinceEpoch.toDouble();
      expect(parseChartXValue('2026-06-17T00:00:00Z'), expected);
    });

    test('parses ISO date to epoch milliseconds', () {
      final expected =
          DateTime.parse('2026-06-17').millisecondsSinceEpoch.toDouble();
      expect(parseChartXValue('2026-06-17'), expected);
    });

    test('returns 0.0 for unparseable values', () {
      expect(parseChartXValue('not-a-date'), 0.0);
      expect(parseChartXValue(null), 0.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/charts/chart_x_value_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create the helper**

Create `lib/src/charts/chart_x_value.dart`:

```dart
/// Converts a chart data point's `x` field to a plottable double.
///
/// Numbers pass through. ISO-8601 date/datetime strings are converted to
/// epoch milliseconds so time-series points plot in correct order and spacing.
/// Anything unparseable yields `0.0`.
double parseChartXValue(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.millisecondsSinceEpoch.toDouble();
  }
  return 0.0;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/charts/chart_x_value_test.dart`
Expected: PASS.

- [ ] **Step 5: Use the helper in line_chart**

In `lib/src/charts/line_chart.dart`, add the import:

```dart
import 'package:flutter_adaptive_charts_fs/src/charts/chart_x_value.dart';
```

Replace the X parse line:

```dart
      final dynamic rawX = item['x'] ?? 0;
      final double x = (rawX is num) ? rawX.toDouble() : 0.0;
```

with:

```dart
      final double x = parseChartXValue(item['x']);
```

- [ ] **Step 6: Run the chart tests for regressions**

Run: `fvm flutter test test/charts/`
Expected: PASS.

- [ ] **Step 7: Update the charts changelog**

In `packages/flutter_adaptive_charts_fs/CHANGELOG.md`, under `## [Unreleased]`:

```markdown
- **`Chart.Line` datetime X axis:** ISO date/datetime `x` values now convert to epoch milliseconds instead of collapsing to 0, so time-series points plot correctly.
```

- [ ] **Step 8: Commit** (surface diff, await confirmation)

```bash
git add lib/src/charts/chart_x_value.dart lib/src/charts/line_chart.dart test/charts/chart_x_value_test.dart CHANGELOG.md
git commit -m "fix(charts): parse datetime x values on line charts"
```

- [ ] **Step 9: Phase B full verification**

Run:
```bash
fvm flutter analyze
fvm flutter test --exclude-tags=golden
```
Expected: analyze clean; tests pass. Record counts.

---

# Phase C — flutter_adaptive_template_fs

All Phase C commands run from `packages/flutter_adaptive_template_fs/`.

## Task C1: Eager collection + date functions

The evaluator already implements `utcNow`, `formatDateTime`, `date`, `year`/`month`/`dayOfMonth`, `addDays`/`addHours`/`addMinutes`/`addSeconds`. Add the missing **eager** functions that fit the existing pre-evaluated-args dispatch: collection `join`/`first`/`last`/`sum`/`average` and date `formatEpoch`/`getPastTime`/`getFutureTime`.

**Deferred (out of scope, documented):** `select`/`where` require per-item lambda evaluation, which the current eager-args evaluator cannot express without parser-level lazy-evaluation support. Track as a separate plan.

**Files:**
- Modify: `lib/src/evaluator.dart` (add function branches before `// Unknown function`)
- Test: `test/unit/evaluator_collection_functions_test.dart` (create)

- [ ] **Step 1: Write the failing tests**

First confirm how to invoke the evaluator in a test. Run:
`ls test/unit && sed -n '1,40p' test/unit/$(ls test/unit | grep -i eval | head -1)`
to copy the existing evaluator test harness (constructor + `evaluate`/`expand` entry point).

Create `test/unit/evaluator_collection_functions_test.dart` using the same harness. The exact harness call mirrors the existing evaluator unit tests; the assertions are:

```dart
import 'package:flutter_adaptive_template_fs/flutter_adaptive_template_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Replace `expandExpression` with the project's evaluator entry point
  // confirmed from the existing evaluator unit test harness.
  String eval(String expr, Map<String, dynamic> data) {
    final template = {'type': 'TextBlock', 'text': '\${$expr}'};
    final result = AdaptiveCardTemplate(template).expand(data)
        as Map<String, dynamic>;
    return result['text'].toString();
  }

  group('collection functions', () {
    test('join concatenates with a separator', () {
      expect(eval("join(items, ', ')", {'items': ['a', 'b', 'c']}), 'a, b, c');
    });
    test('first returns the first element', () {
      expect(eval('first(items)', {'items': [10, 20]}), '10');
    });
    test('last returns the last element', () {
      expect(eval('last(items)', {'items': [10, 20]}), '20');
    });
    test('sum adds numeric elements', () {
      expect(eval('sum(items)', {'items': [1, 2, 3]}), '6');
    });
    test('average averages numeric elements', () {
      expect(eval('average(items)', {'items': [2, 4]}), '3');
    });
  });

  group('date functions', () {
    test('formatEpoch formats seconds since epoch', () {
      // 2021-01-01T00:00:00Z = 1609459200 seconds
      expect(
        eval("formatEpoch(1609459200, 'yyyy')", <String, dynamic>{}),
        '2021',
      );
    });
  });
}
```

> Adapt `eval`/the import to the confirmed harness from the existing evaluator tests. The behavioral assertions above are the contract regardless of harness shape.

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/unit/evaluator_collection_functions_test.dart`
Expected: FAIL — functions return null (unknown function), so output is empty/unchanged.

- [ ] **Step 3: Implement the collection functions**

In `lib/src/evaluator.dart`, immediately before the `// Unknown function` / `return null;` at the end of the function-dispatch chain (after the `addDays`/`addSeconds` block ~line 466), add:

```dart
      // Collection functions (eager)
      if (name == 'join') {
        if (args.isEmpty || args[0] is! List) return null;
        final sep = args.length > 1 ? args[1]?.toString() ?? '' : '';
        return (args[0] as List).map((e) => e?.toString() ?? '').join(sep);
      }
      if (name == 'first') {
        if (args.isEmpty || args[0] is! List) return null;
        final list = args[0] as List;
        return list.isEmpty ? null : list.first;
      }
      if (name == 'last') {
        if (args.isEmpty || args[0] is! List) return null;
        final list = args[0] as List;
        return list.isEmpty ? null : list.last;
      }
      if (name == 'sum') {
        if (args.isEmpty || args[0] is! List) return null;
        num total = 0;
        for (final e in args[0] as List) {
          if (e is num) total += e;
        }
        return total;
      }
      if (name == 'average') {
        if (args.isEmpty || args[0] is! List) return null;
        final list = (args[0] as List).whereType<num>().toList();
        if (list.isEmpty) return null;
        return list.reduce((a, b) => a + b) / list.length;
      }
```

- [ ] **Step 4: Implement the date functions**

Immediately after the collection functions, add:

```dart
      // Additional date functions
      if (name == 'formatEpoch') {
        if (args.isEmpty || args[0] is! num) return null;
        final date = DateTime.fromMillisecondsSinceEpoch(
          (args[0] as num).toInt() * 1000,
          isUtc: true,
        ).toLocal();
        final format = args.length > 1
            ? args[1]?.toString() ?? "yyyy-MM-dd'T'HH:mm:ss"
            : "yyyy-MM-dd'T'HH:mm:ss";
        return DateFormat(format).format(date);
      }
      if (name == 'getPastTime' || name == 'getFutureTime') {
        if (args.isEmpty || args[0] is! num) return null;
        final amount = (args[0] as num).toInt();
        final unit = args.length > 1 ? args[1]?.toString() ?? 'D' : 'D';
        final duration = switch (unit.toUpperCase()) {
          'D' => Duration(days: amount),
          'H' => Duration(hours: amount),
          'M' => Duration(minutes: amount),
          _ => Duration(days: amount),
        };
        final now = DateTime.now();
        final result =
            name == 'getPastTime' ? now.subtract(duration) : now.add(duration);
        final format = args.length > 2
            ? args[2]?.toString() ?? "yyyy-MM-dd'T'HH:mm:ss"
            : "yyyy-MM-dd'T'HH:mm:ss";
        return DateFormat(format).format(result);
      }
```

(`DateFormat` is already imported in `evaluator.dart` — it is used by the existing `formatDateTime`.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `fvm flutter test test/unit/evaluator_collection_functions_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the full template suite for regressions**

Run: `fvm flutter test`
Expected: PASS (no regressions in existing template/evaluator tests).

- [ ] **Step 7: Update the templating changelog**

In `packages/flutter_adaptive_template_fs/CHANGELOG.md`, under `## [Unreleased]`:

```markdown
- **Collection functions** `join`, `first`, `last`, `sum`, `average` and **date functions** `formatEpoch`, `getPastTime`, `getFutureTime` added to the expression evaluator. (`select`/`where` remain unimplemented — they require lazy lambda evaluation.)
```

- [ ] **Step 8: Commit** (surface diff, await confirmation)

```bash
git add lib/src/evaluator.dart test/unit/evaluator_collection_functions_test.dart CHANGELOG.md
git commit -m "feat(templating): add eager collection and date functions"
```

- [ ] **Step 9: Phase C full verification**

Run:
```bash
fvm flutter analyze
fvm flutter test
```
Expected: analyze clean; tests pass. Record counts.

---

## Final Task: Cross-package verification + doc update

- [ ] **Step 1: Repo-wide analyze**

Run: `cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && fvm flutter analyze`
Expected: no issues.

- [ ] **Step 2: Run all three affected package test suites**

Run:
```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden
cd ../flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden
cd ../flutter_adaptive_template_fs && fvm flutter test
```
Expected: all pass. Record pass/skip/fail counts per package.

- [ ] **Step 3: Update Implementation-Status.md**

Upgrade the rows closed by this plan from ⚠️ Partial toward ✅ (Badge `shape`, CompoundButton `badge`, Carousel `timer`/`orientation`/`loop`, ActionSet overflow), note `Image.backgroundColor` and `iconPlacement` now supported, mark chart datetime axes fixed, and update the templating function list. Leave `select`/`where` and Media VTT rendering as remaining gaps with a pointer to the deferred items.

- [ ] **Step 4: Invoke `verification-before-completion`**

Paste analyze exit status and per-package test counts before claiming completion. Do not report complete until all three suites pass.

---

## Deferred (explicitly out of scope for this plan)

- **Templating `select` / `where`** — require per-item lambda evaluation (lazy args); a parser-level change. Separate plan.
- **Media VTT caption rendering** — `captionSources` are parsed and exposed (Task A7) but not rendered onto the `video_player` surface. Separate plan.
- **TextBlock markdown `maxLines` (Task A8) — DEFERRED/SKIPPED (2026-06-18).** Not implemented. The markdown library has no `maxLines`; the only option is a height-clip hack (clip without ellipsis), which the team chose not to land. The plain-text TextBlock path continues to honor `maxLines`. Revisit if/when a markdown renderer with line-limit support is adopted.
- **Badge `icon` as Fluent name** — Badge renders `iconUrl` images; mapping the hub `icon` (Fluent icon name) token is a separate enhancement tied to the Icon element's name catalog.
