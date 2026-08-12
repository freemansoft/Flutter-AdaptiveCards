# Chart support for the Adaptive Chat demo

**Date:** 2026-08-12
**Components:** `adaptive_chat_server_dart/` and `adaptive_chat_client/` (both
top-level demo apps; neither is a published package under `packages/`)

## Problem

`flutter_adaptive_charts_fs` renders eight `Chart.*` element types, but the
Adaptive Chat demo cannot show any of them. Two independent gaps:

- **The client cannot render them.** `adaptive_chat_client` does not depend on
  `flutter_adaptive_charts_fs` and calls `AdaptiveCardsCanvas.map` with the
  default `CardTypeRegistry`, so no `Chart.*` type has a builder.
- **The server never suggests them.** `assets/card_system_prompt.txt` — the
  bundled card prompt, selected via `--system-prompt-file` — advertises a
  fixed palette of inputs and display elements that contains no chart types,
  and instructs the model to use _only_ the listed types. With
  `--json-format schema`, `assets/card_schema.json` additionally
  grammar-forbids any type outside its enum.

The result is that the demo showcases the core card library but not the charts
package, even though the charts package is a first-class part of this
ecosystem and the chat bubble is a natural place to show a small chart.

## Goals

- The chat client renders `Chart.*` elements sent by the server, in the same
  assistant bubble chrome as any other card reply.
- The card system prompt advertises a curated set of chart types with correct
  data shapes, so a local model can answer a "chart this" question with a
  chart instead of a Markdown table.
- `--json-format schema` keeps working: the schema does not forbid the types
  the prompt now advertises.
- The prompt/schema/client coupling is documented, so the failure mode below
  is not rediscovered.

## Non-goals

- **Not interactive.** Chart replies stay display-only, like every other card
  reply today. The card prompt continues to forbid `Action`/`ActionSet`, and
  nothing posts back to the server.
- **Not chart overlays.** Runtime chart-data patching
  (`CardChartsRegistry.overlayExtensions`) is out of scope — see Decisions.
- **Not `adaptive_explorer`.** Explorer has no chart wiring today; adding it is
  a separate change (confirmed with the user during design).
- **Not a HostConfig redesign.** No `chartColors` / `chartsLayout` tuning — see
  Decisions.

## Background: what already works

Three things need no change, and knowing why saves rediscovering them:

- **`card_detect.dart`** accepts any JSON object carrying a non-empty `type`
  string as a single-element card body, so `{"type":"Chart.Pie", …}` and a
  full `AdaptiveCard` wrapping one both already pass `tryParseCardBody`. (This
  permissiveness is a known gap recorded in the server README; it happens to
  work in our favor here.)
- **`cards.dart`** already routes card replies through `_fullWidthBubble`,
  which omits the `ColumnSet` used by text bubbles. That shape was adopted for
  `Carousel`, whose `LayoutBuilder` cannot answer the `IntrinsicHeight` pass
  that `ColumnSet` imposes. Charts are not affected either way — each chart
  widget wraps its plot in a fixed `SizedBox(height: layout.height)` sourced
  from `HostConfig.chartsLayout` — but they inherit the full-width shape for
  free, which is also the better shape for a chart.
- **`AdaptiveCardsCanvas.map`** already accepts `cardTypeRegistry:`, so the
  client change is registry construction plus one argument.

## Design

### Failure mode that drives the shape of this change

An unregistered element type renders as a **visible error placeholder**.
`CardTypeRegistry.getElement` falls through to `AdaptiveUnknown`, which renders
`AdaptiveErrorPlaceholder`: a broken-image icon plus
`Type Chart.Pie not found. … a portion of the tree was dropped: {…}` in the
theme's error color, in every build mode, with the message in a `liveRegion`
for screen readers.

That makes the server and client changes a matched pair. A server advertising
`Chart.*` to a client without the charts package fills the assistant bubble
with red error text and the raw element JSON — diagnosable, but user-visible
and ugly. The two halves must ship together, and the server README must state
the client-side requirement.

> [!NOTE] > `card_system_prompt.txt` currently tells the model that a misspelled type
> "renders as an empty blank space and the user sees nothing." That is
> inaccurate for the same reason — a wrong type takes the identical
> `AdaptiveUnknown` path and is loudly visible. The claim is pre-existing and
> only strengthens the prompt's "copy each type exactly" instruction, so this
> change leaves it alone rather than widening scope; it is recorded here so
> the next reader does not take it as fact.

It also shapes the client test: a negative case pinning what the default
registry renders is a far stronger guard than asserting on the absence of
exceptions. See Testing.

### Server: `adaptive_chat_server_dart`

#### Prompt palette

`assets/card_system_prompt.txt` gains a **Charts** block inside the existing
`Display — show information, no user entry` section, in the established format
of that file: type name, one-line description, one-line raw-JSON example.

Six types are advertised — the flat-data set:

| Types                                                    | Data shape                                                                                |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `Chart.Pie`, `Chart.Donut`                               | `"data":[{"title":"Cat A","value":30}]`                                                   |
| `Chart.VerticalBar`, `Chart.HorizontalBar`, `Chart.Line` | `"data":[{"x":"Mon","y":59}]`                                                             |
| `Chart.Gauge`                                            | `"value"`, `"min"`, `"max"`, and optional `"segments":[{"color":…,"value":…,"legend":…}]` |

`Chart.VerticalBar.Grouped` and `Chart.HorizontalBar.Stacked` are deliberately
**not** advertised — see Decisions. They remain renderable from hand-authored
JSON; only the prompt omits them.

Guidance added alongside, consistent with the constraints already in the file:

- At most about 6 data points per chart, matching the existing "keep every list
  SHORT" rule.
- One chart per reply; do not nest a chart inside a `Table` or a `Carousel`
  (the file already forbids `Table`-inside-`Carousel` for the same reason).
- `x`, `y`, and `value` are plain JSON numbers or strings, never nested
  objects — the file already states this rule generally; charts are where a
  model is most likely to break it.
- Optional chrome (`title`, `xAxisTitle`, `yAxisTitle`, `showLegend`) is
  mentioned once for the group rather than repeated per type, to keep the added
  length near ~50 lines.

#### Schema

`assets/card_schema.json` gains the same six names in the
`$defs.Element.properties.type.enum` array. Without this,
`--json-format schema` constrains the model's grammar to a type set that
excludes exactly what the prompt just asked for. The `none` and `json` formats
need no change.

The prompt and the schema enum are two files that must agree, with no compiler
to enforce it — hence the drift test below.

#### Docs

- `README.md`: add a Charts bullet to the palette list under **Card replies
  (display-only)**, and a note that chart replies require the client to
  register `flutter_adaptive_charts_fs` or the bubble fills with unknown-type
  error placeholders.
- `CHANGELOG.md`: one bullet under `## [Unreleased]`.

#### Unchanged on the server

`card_detect.dart`, `cards.dart`, `app.dart`, `cli.dart`,
`ollama_responder.dart`. No new CLI flag: charts are part of the card prompt,
which is already opt-in via `--system-prompt-file`.

### Client: `adaptive_chat_client`

#### Dependency

`pubspec.yaml` gains:

```yaml
flutter_adaptive_charts_fs:
  path: ../packages/flutter_adaptive_charts_fs
```

matching how the client already declares `flutter_adaptive_cards_fs` and
`flutter_adaptive_cards_host_fs`. Both the client and the charts package are
root pub-workspace members, so this resolves with the existing root
`flutter pub get`.

#### Registry

New `lib/src/chat_card_registry.dart`, mirroring
`widgetbook/lib/widgetbook_card_registry.dart`:

```dart
/// [CardTypeRegistry] for chat bubbles: core elements plus `Chart.*`.
final CardTypeRegistry chatCardTypeRegistry = CardTypeRegistry(
  addedElements: CardChartsRegistry.additionalChartElements,
);
```

`addedElements` only, **not** `overlayExtensions` — see Decisions.

#### Wiring

`lib/src/chat_page.dart`: `_buildLog`'s `AdaptiveCardsCanvas.map` gains
`cardTypeRegistry: chatCardTypeRegistry`.

`_buildCompose`'s canvas keeps the default registry. The compose card is a
fixed local `Input.Text` + `Action.Submit` card built by `compose_card.dart`
and will never contain a chart.

#### Unchanged on the client

`chat_host_config.dart` keeps `HostConfig(cornerRadius: 16)` for both themes —
see Decisions.

## Decisions

| Decision                                       | Choice                                     | Rationale                                                                                                                                                                                                                                                                                                                                                                          |
| ---------------------------------------------- | ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Where chart instructions live                  | Extended `card_system_prompt.txt` in place | One prompt file, no new CLI flag, no duplicated text. Considered and rejected: a `--charts` flag composing a separate fragment (extra machinery for a demo), and a third standalone prompt file (~153 duplicated lines to keep in sync by hand).                                                                                                                                   |
| Which chart types the prompt advertises        | The six flat-data types                    | Covers every chart widget in the package (pie/donut, gauge, line, bar) and all the visual variety, with three data shapes. The two multi-series types need a fourth, deeply nested shape (`{legend, values:[{x,y},…]}`) — the heaviest JSON in the palette, and exactly the nesting the prompt already warns against. A malformed chart falls back to raw JSON text in the bubble. |
| Chart overlay extensions on the client         | Omitted                                    | `overlayExtensions` exists for hosts that patch chart data at runtime. The chat client renders each server card once and never mutates it. Widgetbook makes the same split: its default registry omits them and only the overlay demo page adds them.                                                                                                                              |
| Chart sizing / colors in the client HostConfig | Left at library defaults                   | Defaults are 250px (bar, line) and 200px (pie, gauge) inside a full-width bubble, and the default chart palette is already theme-aware. Tuning before seeing it render would be guesswork; the demo showing library defaults is also the more honest demo.                                                                                                                         |
| `adaptive_explorer`                            | Out of scope                               | Confirmed with the user. Explorer has no chart wiring today; the request's premise that it already had some was incorrect.                                                                                                                                                                                                                                                         |

## Testing

| Where                                                          | Test                                                                                                                                                                                                                                                                             |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `adaptive_chat_server_dart/test/card_schema_test.dart` (new)   | `assets/card_schema.json`'s `Element.type` enum contains all six advertised `Chart.*` names — guards the prompt/schema drift that silently breaks `--json-format schema`                                                                                                         |
| `adaptive_chat_server_dart/test/card_detect_test.dart`         | A bare `Chart.Pie` element object and a full `AdaptiveCard` wrapping one both survive `tryParseCardBody`                                                                                                                                                                         |
| `adaptive_chat_client/test/chart_reply_render_test.dart` (new) | Widget test: a full-width assistant bubble containing a `Chart.Pie` and one containing a `Chart.VerticalBar` each render with `chatCardTypeRegistry`; plus a negative case proving the default `CardTypeRegistry()` renders the unknown-type error placeholder for the same card |

**What the client test asserts on — and why not on widget types.** Neither
class the test would naturally reach for is importable from the client:

- The chart widgets (`AdaptivePieChart`, `AdaptiveBarChart`, …) live under
  `flutter_adaptive_charts_fs/lib/src/charts/` and are **not** re-exported by
  the package barrel, which exports only `card_chart_registry.dart` and
  `chart_element_overlay_extension.dart`.
- `AdaptiveErrorPlaceholder` lives under `flutter_adaptive_cards_fs/lib/src/`
  and is likewise not exported by that package's barrel.

So both assertions go through rendered text, which needs no import:

- **Positive:** `find.text('<chart title>')`. `ChartChrome` emits the
  element's `title` as a `Text` above the plot, and an unregistered type never
  reaches `ChartChrome` — so the title is present exactly when the registry
  did its job.
- **Negative:** pump the same card with `const CardTypeRegistry()` and expect
  `find.text('<chart title>')` to be `findsNothing` while
  `find.textContaining('Type Chart.Pie not found')` — the `AdaptiveUnknown`
  message — is `findsOneWidget`.

The negative case is what stops the suite passing trivially: it pins the exact
before/after difference this change creates.

## Verification

Matching the three jobs in `.github/workflows/adaptive_chat.yml`:

```bash
# Repo root
fvm flutter analyze
npm run check:md:chat

# Client (root pub workspace member)
cd adaptive_chat_client && fvm flutter test

# Server (resolves standalone, no Flutter needed)
cd adaptive_chat_server_dart && dart pub get && dart test
```

No files under `packages/` change, so no package `CHANGELOG.md` entries and no
coverage floors are in play.

## Manual smoke check

Not automatable — the point of the change is a chart appearing in a bubble:

```bash
cd adaptive_chat_server_dart
dart run bin/server.dart --ollama-url http://127.0.0.1:11434 \
  --system-prompt-file assets/card_system_prompt.txt

cd adaptive_chat_client && fvm flutter run
```

Ask something like "show me a pie chart of 2024 sales by region" and confirm a
chart renders rather than an empty bubble or raw JSON.
