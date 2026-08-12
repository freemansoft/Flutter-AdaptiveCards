# Adaptive Chat Chart Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Adaptive Chat demo render `Chart.*` elements end to end — the Flutter client registers `flutter_adaptive_charts_fs`, and the Dart server's card system prompt and JSON schema advertise six flat-data chart types to the model.

**Architecture:** Three pieces. `flutter_adaptive_charts_fs` gains a second entrypoint naming the chart widget classes, leaving its existing barrel untouched. The client builds a `CardTypeRegistry` with `CardChartsRegistry.additionalChartElements` and passes it to the chat log's `AdaptiveCardsCanvas`. The server adds a Charts block to `assets/card_system_prompt.txt` and the matching type names to `assets/card_schema.json`, with a drift test that reads both files and fails if they disagree. No renderer, detection, or wire-format changes.

**Task order:** Task 1 → Task 2 (Task 2's test imports Task 1's barrel). Task 3 is independent of both and may run in parallel. The client and server halves must land together before the demo is usable — see the failure mode in the spec.

**Tech Stack:** Dart 3.12 / Flutter 3.44 (via `fvm`), `package:test` (server, standalone resolution), `flutter_test` + `MockClient` (client, root pub workspace member), Prettier for Markdown.

**Spec:** [`docs/superpowers/specs/2026-08-12-adaptive-chat-charts-design.md`](../specs/2026-08-12-adaptive-chat-charts-design.md)

## Global Constraints

- **Always prefix `flutter` and `dart` with `fvm`** in `adaptive_chat_client` and at the repo root. `adaptive_chat_server_dart` is **not** a pub workspace member and resolves standalone — its commands are plain `dart` from its own directory.
- **Analysis:** `very_good_analysis` — `prefer_single_quotes`, `always_use_package_imports` (no relative imports), `public_member_api_docs` on public members.
- **Public API docs:** every public Dart member gets a `///` comment saying why it exists and how callers use it — not what the code does.
- **Six chart types only**, spelled exactly: `Chart.Pie`, `Chart.Donut`, `Chart.VerticalBar`, `Chart.HorizontalBar`, `Chart.Line`, `Chart.Gauge`. Never add `Chart.VerticalBar.Grouped` or `Chart.HorizontalBar.Stacked` — deliberately excluded (nested multi-series data, highest malformed-JSON risk).
- **Exactly one file under `packages/` may be created:** `packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_widgets_fs.dart`, plus that package's `CHANGELOG.md`, `README.md`, and a new test. **Do not modify `flutter_adaptive_charts_fs.dart`** — keeping today's default import unchanged is the whole point of the second barrel. Any other `packages/` edit is scope creep: stop and ask.
- **Do not touch `tool/coverage_floors.yaml`.** The barrel is `export` directives only — no executable lines — so the `flutter_adaptive_charts_fs: 83` floor is unaffected.
- **Markdown** in `adaptive_chat_server_dart/` and `docs/` is Prettier-checked in CI. Run `node_modules/.bin/prettier --prose-wrap preserve --write <file>` after editing any `.md`.
- **Commit gate:** this plan is executed under the subagent-driven standing exception — each completed, verified task may be committed to the current feature branch without asking. Do **not** push, merge, or touch `main`.
- **Branch:** `feature/adaptive-chat-charts` (already created; the spec is committed there).

---

### Task 1: Charts package — second barrel for the chart widget classes

**Files:**

- Create: `packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_widgets_fs.dart`
- Create: `packages/flutter_adaptive_charts_fs/test/widgets_barrel_test.dart`
- Modify: `packages/flutter_adaptive_charts_fs/CHANGELOG.md`
- Modify: `packages/flutter_adaptive_charts_fs/README.md`
- **Unchanged:** `packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_fs.dart`

**Interfaces:**

- Consumes: nothing from other tasks.
- Produces: a new importable entrypoint `package:flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart` exposing exactly `AdaptivePieChart`, `AdaptivePieChartState`, `AdaptiveBarChart`, `AdaptiveBarChartState`, `BarChartType`, `AdaptiveLineChart`, `AdaptiveLineChartState`, `AdaptiveGaugeChart`, `AdaptiveGaugeChartState`. Task 2's client test imports it for `find.byType`.

**Background the implementer needs:**

The chart widgets are only reachable today through the `ElementCreator` closures in `CardChartsRegistry.additionalChartElements`, so no consumer can name the types. This barrel exposes them for `find.byType` assertions and direct embedding, while leaving the existing `flutter_adaptive_charts_fs.dart` import byte-identical.

`BarChartType` must be exported: it is a required parameter of `AdaptiveBarChart`'s constructor, so exporting the widget without it yields an unusable type. The `State` classes are included to match the core package's precedent (`show RawAdaptiveCard, RawAdaptiveCardState`).

This was trialed during design: exporting these four files analyzes clean under `very_good_analysis`, and `ChartChrome`, `ChartLegendEntry`, `GaugeSegment`, `GaugeValueFormat`, and `GaugePainter` do **not** leak through. The `show` clauses below keep it that way.

- [ ] **Step 1: Write the failing barrel test**

Create `packages/flutter_adaptive_charts_fs/test/widgets_barrel_test.dart`:

```dart
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the widgets barrel exposes every chart widget class', () {
    // A compile-time guard, not a behavioral one: if a `show` clause is
    // narrowed or a class renamed, this file fails to build instead of
    // silently breaking a downstream consumer's find.byType.
    expect(
      <Type>[
        AdaptivePieChart,
        AdaptivePieChartState,
        AdaptiveBarChart,
        AdaptiveBarChartState,
        BarChartType,
        AdaptiveLineChart,
        AdaptiveLineChartState,
        AdaptiveGaugeChart,
        AdaptiveGaugeChartState,
      ],
      hasLength(9),
    );
  });

  test('BarChartType covers the four bar layouts', () {
    // BarChartType is exported because AdaptiveBarChart's constructor
    // requires it; assert the values a caller would pass.
    expect(BarChartType.values, hasLength(4));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd packages/flutter_adaptive_charts_fs
fvm flutter test test/widgets_barrel_test.dart
```

Expected: FAIL at compile time — `Error: Couldn't resolve the package 'flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart'`.

- [ ] **Step 3: Create the widgets barrel**

Create `packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_widgets_fs.dart`:

```dart
/// Direct access to the `Chart.*` widget classes.
///
/// Import this **in addition to** `flutter_adaptive_charts_fs.dart` when you
/// need to name a chart widget type rather than just register it — most often
/// in a host's widget tests, where `find.byType(AdaptivePieChart)` is a more
/// direct assertion than matching the chart's rendered title text. It also
/// lets a host embed a chart widget outside a card.
///
/// Rendering a chart inside a card needs none of this: register
/// `CardChartsRegistry.additionalChartElements` from the main barrel and the
/// renderer builds these widgets for you.
///
/// Kept separate from `flutter_adaptive_charts_fs.dart` so the default import
/// stays narrow — the same split as `flutter_adaptive_cards_fs.dart` versus
/// `flutter_adaptive_cards_extend_fs.dart`. The `show` clauses are deliberate:
/// the chart chrome (`ChartChrome`, `GaugePainter`, …) stays private.
library;

export 'package:flutter_adaptive_charts_fs/src/charts/bar_chart.dart'
    show AdaptiveBarChart, AdaptiveBarChartState, BarChartType;
export 'package:flutter_adaptive_charts_fs/src/charts/gauge_chart.dart'
    show AdaptiveGaugeChart, AdaptiveGaugeChartState;
export 'package:flutter_adaptive_charts_fs/src/charts/line_chart.dart'
    show AdaptiveLineChart, AdaptiveLineChartState;
export 'package:flutter_adaptive_charts_fs/src/charts/pie_donut_chart.dart'
    show AdaptivePieChart, AdaptivePieChartState;
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd packages/flutter_adaptive_charts_fs
fvm flutter test test/widgets_barrel_test.dart
```

Expected: PASS, 2 tests. If `BarChartType.values` is not length 4, read `lib/src/charts/bar_chart.dart` and correct the expected count in the test — do not change the enum.

- [ ] **Step 5: Document the entrypoint in the package README**

In `packages/flutter_adaptive_charts_fs/README.md`, immediately after the `## Getting started` code block (the one showing `AdaptiveCardsCanvas.map` with `CardTypeRegistry`), add:

````markdown
### Naming the chart widgets directly

Rendering charts in a card needs only the registry above. If you also need to
_name_ a chart widget type — typically to assert on it in a widget test —
import the widgets entrypoint alongside the main one:

```dart
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart';

expect(find.byType(AdaptivePieChart), findsOneWidget);
```

It exposes `AdaptivePieChart`, `AdaptiveBarChart` (with `BarChartType`),
`AdaptiveLineChart`, `AdaptiveGaugeChart`, and their `State` classes. It is a
separate entrypoint so the default import stays narrow; the chart chrome and
painters remain private.
````

Then format:

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && \
  node_modules/.bin/prettier --prose-wrap preserve --write \
  packages/flutter_adaptive_charts_fs/README.md
```

- [ ] **Step 6: Add the changelog entry**

The repo requires a changelog bullet whenever any file under a `packages/<name>/` directory changes. Add to the `## [Unreleased]` section of `packages/flutter_adaptive_charts_fs/CHANGELOG.md` (create the section directly under the title if it does not exist yet — check the file's existing heading style first and match it):

```markdown
- Added: `flutter_adaptive_charts_widgets_fs.dart`, a second entrypoint
  exposing the chart widget classes (`AdaptivePieChart`, `AdaptiveBarChart` +
  `BarChartType`, `AdaptiveLineChart`, `AdaptiveGaugeChart`, and their `State`
  classes) so hosts can assert `find.byType(...)` in widget tests or embed a
  chart outside a card. The existing `flutter_adaptive_charts_fs.dart`
  entrypoint is unchanged.
```

Then format:

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && \
  node_modules/.bin/prettier --prose-wrap preserve --write \
  packages/flutter_adaptive_charts_fs/CHANGELOG.md
```

- [ ] **Step 7: Verify the main barrel is untouched**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
git diff --stat -- packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_fs.dart
```

Expected: **empty output**. Any diff means the default consumer API changed, which this design explicitly forbids.

- [ ] **Step 8: Run the charts package suite and the analyzer**

```bash
cd packages/flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && fvm flutter analyze
```

Expected: all charts tests pass; analyzer reports **No issues found**.

- [ ] **Step 9: Commit**

```bash
git add packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_widgets_fs.dart \
        packages/flutter_adaptive_charts_fs/test/widgets_barrel_test.dart \
        packages/flutter_adaptive_charts_fs/CHANGELOG.md \
        packages/flutter_adaptive_charts_fs/README.md
git commit -m "feat(charts): add a widgets entrypoint for the chart classes

flutter_adaptive_charts_widgets_fs.dart exposes AdaptivePieChart,
AdaptiveBarChart (+ BarChartType), AdaptiveLineChart, AdaptiveGaugeChart
and their State classes, so hosts can name them in find.byType assertions.
Separate from the main barrel so the default import is unchanged; show
clauses keep ChartChrome and the painters private."
```

---

### Task 2: Client renders `Chart.*` in assistant bubbles

**Files:**

- Modify: `adaptive_chat_client/pubspec.yaml` (dependencies block)
- Create: `adaptive_chat_client/lib/src/chat_card_registry.dart`
- Modify: `adaptive_chat_client/lib/src/chat_page.dart:171-175` (`_buildLog`'s `AdaptiveCardsCanvas.map`)
- Create: `adaptive_chat_client/test/chart_reply_render_test.dart`
- Modify: `adaptive_chat_client/test/chat_page_test.dart` (add one end-to-end test)
- Modify: `pubspec.lock` (repo root, tracked — regenerated by Step 2)
- Unchanged: `adaptive_chat_client/lib/src/chat_host_config.dart` — chart sizing and colors stay at library defaults, per the spec's Decisions table. Do not add `chartColors` or `chartsLayout`.

**Interfaces:**

- Consumes: `CardChartsRegistry.additionalChartElements` (a `Map<String, ElementCreator>`) from `package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart`; `AdaptivePieChart` and `AdaptiveBarChart` from `package:flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart` (Task 1); `CardTypeRegistry` and `AdaptiveCardsCanvas` from `package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart`.
- Produces: `chatCardTypeRegistry`, a top-level `final CardTypeRegistry` in `package:adaptive_chat_client/src/chat_card_registry.dart`. Nothing in Task 3 depends on it.

**Background the implementer needs:**

`AdaptiveCardsCanvas.map` takes `cardTypeRegistry:` and defaults it to `const CardTypeRegistry()`, which has no `Chart.*` builders. An element type with no builder does **not** render blank — `CardTypeRegistry.getElement` falls through to `AdaptiveUnknown`, which renders a broken-image icon plus the text `Type Chart.Pie not found. …` in the theme's error color. The negative test below depends on that exact string.

Task 1's widgets barrel makes `find.byType(AdaptivePieChart)` available; use it for the positive assertions. The placeholder half of the negative case still goes through text: `AdaptiveErrorPlaceholder` lives under `flutter_adaptive_cards_fs/lib/src/` and is not exported by that package's barrel. Do **not** export it — that is a different package and out of scope.

**Ordering:** Task 1 must be complete, or the widgets-barrel import will not resolve.

- [ ] **Step 1: Add the charts dependency**

In `adaptive_chat_client/pubspec.yaml`, add to `dependencies:` (keeping the block alphabetical, immediately after `flutter_adaptive_cards_host_fs`):

```yaml
flutter_adaptive_charts_fs:
  path: ../packages/flutter_adaptive_charts_fs
```

- [ ] **Step 2: Resolve dependencies**

Run from the **repo root** (the client is a pub workspace member, so it resolves there, not in its own directory):

```bash
fvm flutter pub get
```

Expected: exits 0, `flutter_adaptive_charts_fs` resolved from path.

- [ ] **Step 3: Write the failing canvas-level test**

Create `adaptive_chat_client/test/chart_reply_render_test.dart`:

```dart
import 'package:adaptive_chat_client/src/chat_card_registry.dart';
import 'package:adaptive_chat_client/src/chat_host_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shape `assistantCardBubble` sends for a card reply: a single styled
/// Container, no ColumnSet. See `adaptive_chat_server_dart/lib/src/cards.dart`.
Map<String, dynamic> _fullWidthCardBubble(List<Map<String, dynamic>> body) => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': [
    {
      'type': 'Container',
      'style': 'emphasis',
      'roundedCorners': true,
      'items': body,
    },
  ],
};

List<Map<String, dynamic>> _pieFragment() => [
  {
    'type': 'Chart.Pie',
    'title': 'Sales by region',
    'data': [
      {'title': 'North', 'value': 30},
      {'title': 'South', 'value': 45},
      {'title': 'West', 'value': 25},
    ],
  },
];

List<Map<String, dynamic>> _barFragment() => [
  {
    'type': 'Chart.VerticalBar',
    'title': 'Weekly signups',
    'data': [
      {'x': 'Mon', 'y': 12},
      {'x': 'Tue', 'y': 19},
      {'x': 'Wed', 'y': 7},
    ],
  },
];

Future<void> _pumpBubble(
  WidgetTester tester,
  List<Map<String, dynamic>> body, {
  required CardTypeRegistry registry,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdaptiveCardsCanvas.map(
          content: _fullWidthCardBubble(body),
          hostConfigs: chatHostConfigs(),
          cardTypeRegistry: registry,
          showDebugJson: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pie chart reply renders with the chat registry', (tester) async {
    await _pumpBubble(tester, _pieFragment(), registry: chatCardTypeRegistry);

    // find.byType names the widget the registry was supposed to build, via
    // the widgets barrel added in Task 1.
    expect(find.byType(AdaptivePieChart), findsOneWidget);
    expect(find.text('Sales by region'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical bar chart reply renders with the chat registry', (
    tester,
  ) async {
    await _pumpBubble(tester, _barFragment(), registry: chatCardTypeRegistry);

    expect(find.byType(AdaptiveBarChart), findsOneWidget);
    expect(find.text('Weekly signups'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the same card without the chart registry renders the '
      'unknown-type placeholder', (tester) async {
    await _pumpBubble(
      tester,
      _pieFragment(),
      registry: const CardTypeRegistry(),
    );

    // Pins the before/after difference this feature creates: with the default
    // registry there is no Chart.Pie builder, so AdaptiveUnknown renders an
    // error placeholder instead of a chart. Without this case the two tests
    // above could pass for the wrong reason.
    //
    // The placeholder is matched by message text, not by type:
    // AdaptiveErrorPlaceholder is not exported from flutter_adaptive_cards_fs.
    expect(find.byType(AdaptivePieChart), findsNothing);
    expect(find.textContaining('Type Chart.Pie not found'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run the test to verify it fails**

```bash
cd adaptive_chat_client && fvm flutter test test/chart_reply_render_test.dart
```

Expected: FAIL at compile time — `Error: Couldn't resolve the package 'adaptive_chat_client/src/chat_card_registry.dart'` (the file does not exist yet).

- [ ] **Step 5: Create the registry**

Create `adaptive_chat_client/lib/src/chat_card_registry.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';

/// [CardTypeRegistry] used for every server-authored bubble in the chat log.
///
/// Adds the `Chart.*` element builders on top of the core element set, so a
/// model reply containing a chart renders as a chart instead of the
/// unknown-type error placeholder. Pass it to the log's
/// `AdaptiveCardsCanvas`; the compose card keeps the default registry because
/// it is a fixed local card that never contains a chart.
///
/// Chart *overlay* extensions are deliberately omitted: they exist for hosts
/// that patch chart data at runtime, and the chat client renders each server
/// card once and never mutates it.
final CardTypeRegistry chatCardTypeRegistry = CardTypeRegistry(
  addedElements: CardChartsRegistry.additionalChartElements,
);
```

- [ ] **Step 6: Run the test to verify it passes**

```bash
cd adaptive_chat_client && fvm flutter test test/chart_reply_render_test.dart
```

Expected: PASS, 3 tests.

- [ ] **Step 7: Commit the registry**

```bash
git add adaptive_chat_client/pubspec.yaml \
        adaptive_chat_client/lib/src/chat_card_registry.dart \
        adaptive_chat_client/test/chart_reply_render_test.dart \
        pubspec.lock
git commit -m "feat(chat-client): register Chart.* element builders

Adds flutter_adaptive_charts_fs and a chatCardTypeRegistry that merges
CardChartsRegistry.additionalChartElements into the core element set.
Overlay extensions are omitted -- the client never patches chart data."
```

`pubspec.lock` at the repo root is tracked; include it if Step 2 changed it.

- [ ] **Step 8: Write the failing end-to-end ChatPage test**

`chat_card_registry.dart` existing is not the same as `ChatPage` using it. Add this test to `adaptive_chat_client/test/chat_page_test.dart`.

Add the widgets-barrel import to the file's import block first (it is
alphabetically after `flutter_adaptive_cards_fs`):

```dart
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart';
```

Then add a mock client that answers with a chart card. Insert after the existing `_clientWithStartFailing` helper, before `Future<void> _pumpPage`:

```dart
/// A client whose reply is a full-width bubble containing a `Chart.Pie`,
/// matching what `assistantCardBubble` sends for a model card reply.
ChatBackendClient _clientReplyingWithChart() {
  return ChatBackendClient(
    baseUrl: Uri.parse('http://localhost:8000'),
    client: MockClient((req) async {
      if (req.url.path == '/conversations') {
        return http.Response(
          jsonEncode({
            'conversationId': 'c_1',
            'links': {'postNext': '/conversations/c_1/interactions'},
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'conversationId': 'c_1',
          'interactionId': req.headers['X-Interaction-Id'],
          'messages': [
            {
              'type': 'AdaptiveCard',
              'version': '1.5',
              'body': [
                {
                  'type': 'Container',
                  'style': 'emphasis',
                  'roundedCorners': true,
                  'items': [
                    {
                      'type': 'Chart.Pie',
                      'title': 'Sales by region',
                      'data': [
                        {'title': 'North', 'value': 30},
                        {'title': 'South', 'value': 45},
                      ],
                    },
                  ],
                },
              ],
            },
          ],
          'links': {
            'self': '/conversations/c_1/interactions/x',
            'postNext': '/conversations/c_1/interactions',
          },
        }),
        200,
      );
    }),
  );
}
```

Then add this test inside `void main() { … }`, after the existing
`'sent message appears as a bubble in the log'` test:

```dart
  testWidgets('a Chart.* reply renders as a chart in the log', (tester) async {
    final c = ConversationController(client: _clientReplyingWithChart());
    await c.startConversation();
    await _pumpPage(tester, c);

    await c.send('chart my sales');
    await tester.pumpAndSettle();

    // Guards the wiring, not just the registry: ChatPage's log canvas must
    // pass chatCardTypeRegistry, or Chart.Pie falls through to the
    // unknown-type error placeholder.
    expect(find.byType(AdaptivePieChart), findsOneWidget);
    expect(find.textContaining('Type Chart.Pie not found'), findsNothing);
  });
```

- [ ] **Step 9: Run the test to verify it fails**

```bash
cd adaptive_chat_client && fvm flutter test test/chat_page_test.dart
```

Expected: FAIL on the new test — `Expected: exactly one matching candidate / Actual: _WidgetTypeFinder:<zero widgets with type "AdaptivePieChart">`, because `_buildLog` still uses the default registry and rendered `Type Chart.Pie not found…` instead.

- [ ] **Step 10: Wire the registry into the chat log**

In `adaptive_chat_client/lib/src/chat_page.dart`, add the import alongside the existing `package:adaptive_chat_client/src/...` imports (alphabetical — before `compose_card.dart`):

```dart
import 'package:adaptive_chat_client/src/chat_card_registry.dart';
```

Then in `_buildLog`, add `cardTypeRegistry:` to the canvas. Change:

```dart
              child: AdaptiveCardsCanvas.map(
                content: card,
                hostConfigs: widget.hostConfigs,
                showDebugJson: false,
              ),
```

to:

```dart
              child: AdaptiveCardsCanvas.map(
                content: card,
                hostConfigs: widget.hostConfigs,
                cardTypeRegistry: chatCardTypeRegistry,
                showDebugJson: false,
              ),
```

Leave `_buildCompose`'s canvas alone — the compose card is a fixed local `Input.Text` + `Action.Submit` card and never contains a chart.

- [ ] **Step 11: Run the test to verify it passes**

```bash
cd adaptive_chat_client && fvm flutter test test/chat_page_test.dart
```

Expected: PASS, all tests in the file.

- [ ] **Step 12: Run the full client suite and analyzer**

```bash
cd adaptive_chat_client && fvm flutter test
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && fvm flutter analyze
```

Expected: all client tests pass; analyzer reports **No issues found**.

- [ ] **Step 13: Commit the wiring**

```bash
git add adaptive_chat_client/lib/src/chat_page.dart \
        adaptive_chat_client/test/chat_page_test.dart
git commit -m "feat(chat-client): render chart replies in the chat log

Passes chatCardTypeRegistry to the log canvas so a Chart.* element in a
server reply renders as a chart. The compose card keeps the default
registry. Covered end to end via a MockClient chart reply."
```

---

### Task 3: Server advertises the six flat-data chart types

**Files:**

- Modify: `adaptive_chat_server_dart/assets/card_system_prompt.txt` (insert after line 115, before the `Do NOT include any Action` paragraph)
- Modify: `adaptive_chat_server_dart/assets/card_schema.json` (`$defs.Element.properties.type.enum`)
- Create: `adaptive_chat_server_dart/test/card_schema_test.dart`
- Modify: `adaptive_chat_server_dart/test/card_detect_test.dart`
- Modify: `adaptive_chat_server_dart/README.md:225-235`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `tryParseCardBody` from `package:adaptive_chat_server_dart/src/card_detect.dart` (signature: `List<Map<String, dynamic>>? tryParseCardBody(String raw)`). Nothing from Tasks 1 or 2 — this task is independent and may run in parallel with them.
- Produces: nothing importable — this task changes assets, docs, and tests only. No Dart source under `lib/` is modified.

**Background the implementer needs:**

`adaptive_chat_server_dart` is **not** a pub workspace member. Run its commands as plain `dart` from `adaptive_chat_server_dart/`, and run `dart pub get` there first if `.dart_tool/` is absent. `dart test` runs with the package root as the working directory, so tests read assets via relative paths like `assets/card_schema.json` (see `test/cli_test.dart` for precedent).

The prompt and the schema are two files with no compiler to keep them in agreement. The test below derives the expected type list _from the prompt_ and checks it against the schema, so it fails until both are updated — and keeps failing if either drifts later.

- [ ] **Step 1: Write the failing drift test**

Create `adaptive_chat_server_dart/test/card_schema_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Every `Chart.*` type named anywhere in the card system prompt, read from
/// the prompt itself so this test tracks the prompt rather than a hardcoded
/// copy.
///
/// Matches prose mentions as well as JSON examples: the prompt introduces
/// `Chart.Donut` and `Chart.HorizontalBar` in prose beside a sibling type's
/// example, and a type the model is told about is advertised whether or not
/// it got its own example. The trailing-segment group stops at a sentence
/// period, so `use Chart.Pie.` yields `Chart.Pie`.
Set<String> _chartTypesInPrompt() {
  final text = File('assets/card_system_prompt.txt').readAsStringSync();
  return RegExp(r'Chart\.[A-Za-z]+(?:\.[A-Za-z]+)*')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toSet();
}

/// The `type` enum the `--json-format schema` grammar constrains replies to.
Set<String> _schemaElementTypes() {
  final schema =
      jsonDecode(File('assets/card_schema.json').readAsStringSync())
          as Map<String, dynamic>;
  final element = (schema[r'$defs'] as Map<String, dynamic>)['Element']
      as Map<String, dynamic>;
  final type = (element['properties'] as Map<String, dynamic>)['type']
      as Map<String, dynamic>;
  return (type['enum'] as List).cast<String>().toSet();
}

void main() {
  group('card prompt and card schema agree on chart types', () {
    test('the prompt advertises the six flat-data chart types', () {
      expect(_chartTypesInPrompt(), {
        'Chart.Pie',
        'Chart.Donut',
        'Chart.VerticalBar',
        'Chart.HorizontalBar',
        'Chart.Line',
        'Chart.Gauge',
      });
    });

    test('every chart type in the prompt is allowed by the schema enum', () {
      // Without this, `--json-format schema` grammar-forbids exactly the
      // types the prompt just told the model to use.
      expect(_schemaElementTypes(), containsAll(_chartTypesInPrompt()));
    });

    test('the schema does not allow multi-series chart types', () {
      // Grouped/stacked need a nested {legend, values:[{x,y}]} shape and are
      // deliberately out of the advertised palette.
      expect(
        _schemaElementTypes(),
        isNot(contains('Chart.VerticalBar.Grouped')),
      );
      expect(
        _schemaElementTypes(),
        isNot(contains('Chart.HorizontalBar.Stacked')),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd adaptive_chat_server_dart && dart test test/card_schema_test.dart
```

Expected: FAIL — the first test reports `Expected: {'Chart.Pie', …} Actual: <{}>` because the prompt advertises no chart types yet. The third test passes already.

- [ ] **Step 3: Add the Charts block to the card system prompt**

In `adaptive_chat_server_dart/assets/card_system_prompt.txt`, insert the following **after** the `Image` bullet (the line ending `"altText":"A photo of the Golden Gate Bridge"}`) and **before** the blank line preceding `Do NOT include any Action`:

```text
Charts — small data visualizations. Keep "data" to at most 6 points: a long
series will not fit the narrow bubble. Use at most ONE chart per reply, and
never put a chart inside a Table or a Carousel. Every "x", "y", and "value" is
a plain number or string, never a nested object. Every chart accepts an
optional "title" (shown above the plot) and "showLegend" (true/false); bar and
line charts also accept "xAxisTitle" and "yAxisTitle".
- Chart.Pie and Chart.Donut — parts of a whole. Each data item is a
  {"title","value"} pair:
  {"type":"Chart.Pie","title":"Sales by region","data":[{"title":"North","value":30},{"title":"South","value":45},{"title":"West","value":25}]}
- Chart.VerticalBar and Chart.HorizontalBar — compare a value across
  categories. Each data item is an {"x","y"} pair, where "x" is the category
  label and "y" is the number. Prefer Chart.HorizontalBar when the category
  labels are long:
  {"type":"Chart.VerticalBar","title":"Weekly signups","xAxisTitle":"Day","yAxisTitle":"Signups","data":[{"x":"Mon","y":12},{"x":"Tue","y":19},{"x":"Wed","y":7}]}
- Chart.Line — a trend across an ordered axis. Same {"x","y"} items; "x" may
  be a number or an ISO date string:
  {"type":"Chart.Line","title":"Response time (ms)","data":[{"x":1,"y":120},{"x":2,"y":95},{"x":3,"y":110}]}
- Chart.Gauge — one number against a range. "value", "min", and "max" are
  numbers; the optional "segments" array colors the arc:
  {"type":"Chart.Gauge","title":"Disk used","min":0,"max":100,"value":72,"showLegend":true,"segments":[{"color":"categoricalGreen","value":60,"legend":"OK"},{"color":"categoricalRed","value":40,"legend":"High"}]}
There are no other chart types. In particular there is no grouped or stacked
chart here: to compare two series, send two separate charts or a Table.
```

Do not reformat or reflow any existing line in the file.

- [ ] **Step 4: Run the test to confirm the second failure**

```bash
cd adaptive_chat_server_dart && dart test test/card_schema_test.dart
```

Expected: the first test now PASSES; the second FAILS — `Expected: contains all of {'Chart.Pie', …} Actual: <{TextBlock, FactSet, …}>` because the schema enum has not been updated.

- [ ] **Step 5: Add the six types to the schema enum**

In `adaptive_chat_server_dart/assets/card_schema.json`, extend `$defs.Element.properties.type.enum`. Change:

```json
            "CodeBlock",
            "Image"
          ]
```

to:

```json
            "CodeBlock",
            "Image",
            "Chart.Pie",
            "Chart.Donut",
            "Chart.VerticalBar",
            "Chart.HorizontalBar",
            "Chart.Line",
            "Chart.Gauge"
          ]
```

- [ ] **Step 6: Run the test to verify it passes**

```bash
cd adaptive_chat_server_dart && dart test test/card_schema_test.dart
```

Expected: PASS, 3 tests.

- [ ] **Step 7: Add chart cases to the card-detection tests**

`card_detect.dart` needs **no change** — it already accepts any object with a non-empty `type` string. These are characterization tests that lock that in for charts specifically; they are expected to pass on first run.

Add to `adaptive_chat_server_dart/test/card_detect_test.dart`, inside the existing `group('tryParseCardBody — accepted shapes', …)`:

```dart
    test('a bare Chart.Pie element is wrapped as a one-item body', () {
      const raw =
          '{"type":"Chart.Pie","data":[{"title":"North","value":30}]}';
      expect(tryParseCardBody(raw), [
        {
          'type': 'Chart.Pie',
          'data': [
            {'title': 'North', 'value': 30},
          ],
        },
      ]);
    });

    test('a full AdaptiveCard wrapping a chart returns its body', () {
      const raw =
          '{"type":"AdaptiveCard","body":[{"type":"Chart.VerticalBar",'
          '"data":[{"x":"Mon","y":12}]}]}';
      expect(tryParseCardBody(raw), [
        {
          'type': 'Chart.VerticalBar',
          'data': [
            {'x': 'Mon', 'y': 12},
          ],
        },
      ]);
    });
```

- [ ] **Step 8: Run the detection tests**

```bash
cd adaptive_chat_server_dart && dart test test/card_detect_test.dart
```

Expected: PASS, including the two new tests.

- [ ] **Step 9: Update the server README**

In `adaptive_chat_server_dart/README.md`, find the palette list under **Card replies (display-only)**:

```markdown
- **Inputs** — `Input.Date`, `Input.ChoiceSet` (`style: compact` /
  `expanded`, `isMultiSelect`), `Input.Text`, `Input.Number`, `Input.Time`.
- **Display** — `TextBlock`, `FactSet`, `Badge`, `Carousel`, `Table`,
  `Rating`, `Icon`, `ProgressBar`, `ProgressRing`, `CodeBlock`, `Image`.
```

Add a third bullet:

```markdown
- **Charts** — `Chart.Pie`, `Chart.Donut`, `Chart.VerticalBar`,
  `Chart.HorizontalBar`, `Chart.Line`, `Chart.Gauge`. The two multi-series
  types (`Chart.VerticalBar.Grouped`, `Chart.HorizontalBar.Stacked`) are
  deliberately not advertised: they need a nested
  `{legend, values:[{x,y}]}` shape, the most error-prone JSON in the palette.
```

Then, immediately after the existing `**Display-only.**` paragraph, add:

```markdown
**Charts need a chart-aware client.** `Chart.*` elements render only if the
client registered `flutter_adaptive_charts_fs` — `adaptive_chat_client` does
this in `lib/src/chat_card_registry.dart`. A client without it renders each
chart as a broken-image icon and a `Type Chart.Pie not found` message, not a
blank space, so the failure is visible but ugly.
```

Then format:

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && \
  node_modules/.bin/prettier --prose-wrap preserve --write \
  adaptive_chat_server_dart/README.md
```

- [ ] **Step 10: Add the changelog entry**

Add to the top of the `## [Unreleased]` list in `adaptive_chat_server_dart/CHANGELOG.md`:

```markdown
- Added: the card system prompt and `assets/card_schema.json` now advertise six
  flat-data `Chart.*` types (`Chart.Pie`, `Chart.Donut`, `Chart.VerticalBar`,
  `Chart.HorizontalBar`, `Chart.Line`, `Chart.Gauge`), so a model can answer
  with a chart instead of a Markdown table. Multi-series grouped/stacked charts
  are deliberately excluded. A new `test/card_schema_test.dart` reads the chart
  types out of the prompt and fails if the schema enum disagrees.
```

Format it:

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && \
  node_modules/.bin/prettier --prose-wrap preserve --write \
  adaptive_chat_server_dart/CHANGELOG.md
```

- [ ] **Step 11: Run the full server suite and analyzer**

```bash
cd adaptive_chat_server_dart && dart test && dart analyze
```

Expected: all tests pass; `dart analyze` reports **No issues found**.

- [ ] **Step 12: Commit**

```bash
git add adaptive_chat_server_dart/assets/card_system_prompt.txt \
        adaptive_chat_server_dart/assets/card_schema.json \
        adaptive_chat_server_dart/test/card_schema_test.dart \
        adaptive_chat_server_dart/test/card_detect_test.dart \
        adaptive_chat_server_dart/README.md \
        adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): advertise six flat-data Chart.* types

Adds a Charts block to the card system prompt and the matching names to
the card_schema.json type enum, so --json-format schema does not forbid
what the prompt asks for. Grouped/stacked charts stay out: nested
multi-series JSON is the most error-prone shape in the palette.

card_schema_test.dart derives the expected types from the prompt text, so
prompt/schema drift fails the build."
```

---

### Final Task: Full verification

**Files:** none modified — this task only runs and reports.

Per the repo's plan completion gate, run the whole suite, not just the per-task tests, and paste real output before claiming completion.

- [ ] **Step 1: Invoke the verification skill**

Use `superpowers:verification-before-completion`. Every claim below needs pasted command output including the exit code.

- [ ] **Step 2: Analyzer across the workspace**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm flutter analyze; echo "ANALYZE EXIT: $?"
```

Expected: `No issues found!`, exit 0.

- [ ] **Step 3: Client test suite**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/adaptive_chat_client
fvm flutter test -r expanded; echo "CLIENT EXIT: $?"
```

Expected: all tests pass, exit 0. Matches the `client:` job in `.github/workflows/adaptive_chat.yml`.

- [ ] **Step 4: Server test suite**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/adaptive_chat_server_dart
dart pub get && dart test; echo "SERVER EXIT: $?"
```

Expected: all tests pass, exit 0. Matches the `dart-server:` job.

- [ ] **Step 5: Markdown formatting**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
npm run check:md:chat; echo "MD CHAT EXIT: $?"
npm run check:md; echo "MD DOCS EXIT: $?"
```

Expected: both report all files use Prettier style, exit 0. `check:md:chat` matches the `markdown-format:` job; `check:md` covers the spec and this plan under `docs/`.

- [ ] **Step 6: Charts package test suite**

The widgets barrel puts this published package in scope, so its own suite must pass.

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/packages/flutter_adaptive_charts_fs
fvm flutter test --exclude-tags=golden; echo "CHARTS EXIT: $?"
```

Expected: all tests pass, exit 0.

- [ ] **Step 7: Confirm the `packages/` blast radius is exactly four files**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
git diff --stat main...HEAD -- packages/
```

Expected: exactly these four, and nothing else:

```text
packages/flutter_adaptive_charts_fs/CHANGELOG.md
packages/flutter_adaptive_charts_fs/README.md
packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_widgets_fs.dart
packages/flutter_adaptive_charts_fs/test/widgets_barrel_test.dart
```

In particular `flutter_adaptive_charts_fs.dart` must **not** appear — the whole point of the second barrel is that today's default import is unchanged. Also confirm `tool/coverage_floors.yaml` is untouched:

```bash
git diff --stat main...HEAD -- tool/coverage_floors.yaml
```

Expected: **empty output**. If a floor appears to need lowering, that is a signal to add tests, not to edit the file — stop and report.

- [ ] **Step 8: Manual smoke check (report, do not automate)**

This is the only check that proves a chart actually appears. Requires a running Ollama with the model pulled.

```bash
# Terminal 1
cd adaptive_chat_server_dart
dart run bin/server.dart --ollama-url http://127.0.0.1:11434 \
  --system-prompt-file assets/card_system_prompt.txt

# Terminal 2
cd adaptive_chat_client && fvm flutter run
```

Ask: `show me a pie chart of sales by region: north 30, south 45, west 25`.

Expected: a pie chart in the assistant bubble. A broken-image icon with `Type Chart.Pie not found` means the client registry is not wired; raw JSON text in the bubble means the model emitted something `tryParseCardBody` rejected — check `--log-level debug` for the card-detection reason.

If Ollama is unavailable, say so explicitly rather than claiming the check passed.

- [ ] **Step 9: Report**

Summarize: what shipped, the pasted exit codes from Steps 2-7, and the smoke-check result (or an explicit note that it was not run). Do not invoke `superpowers:finishing-a-development-branch` until Steps 2-7 are green.
