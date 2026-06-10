# RichTextBlock, TextRun, and TextBlock fixes — Design

**Date:** 2026-06-08  
**Plan:** [2026-06-08-refresh-icon-charts-text-features.plan.md](../plans/2026-06-08-refresh-icon-charts-text-features.plan.md) (workstream G)

## Goals

1. Implement standard **`RichTextBlock`** + **`TextRun`** (Adaptive Cards v1.2+).
2. Fix highest-impact **`TextBlock`** gaps without rewriting the markdown stack.

## RichTextBlock rendering

- Parse root `inlines` as a list of **`TextRun`** maps (`type` must be `TextRun`; unknown inline types are skipped).
- Render with **`Text.rich`** and one **`TextSpan`** per run (no markdown).
- Block-level **`horizontalAlignment`** maps to `TextAlign` (same resolver as `TextBlock`).
- Wrap with **`SeparatorElement`**, **`AdaptiveVisibilityMixin`**, and block **`style: heading`** semantics when applicable.

### Per-run styling

Each **`TextRun`** uses **`ReferenceResolver.resolveTextBlockStyle()`** with run-level `size`, `weight`, `color`, `fontType`, and `isSubtle`, then:

| Property        | Flutter mapping                                      |
| --------------- | ---------------------------------------------------- |
| `italic`        | `FontStyle.italic`                                   |
| `strikethrough` | `TextDecoration.lineThrough`                         |
| `underline`     | `TextDecoration.underline`                           |
| `highlight`     | `TextSpan.style.backgroundColor` (theme highlight)   |
| `selectAction`  | `TapGestureRecognizer` → action registry `tap()`     |

Run text passes through **`parseTextString`** + **`DateTimeUtils.formatText`** (same as `TextBlock`).

### selectAction on TextRun

- Resolve handler via **`ActionTypeRegistry.getActionForType`** on the run's `selectAction` map.
- On tap, call **`action.tap(...)`** with `rawAdaptiveCardState` and the run's action map.
- Recognizers are owned by widget state and disposed in **`dispose()`**.

## TextBlock scope (fixes only)

Keep existing **`supportMarkdown`** path and **`MarkdownBody`** link handling.

| Property    | Plain `Text` path (`supportMarkdown: false`)                         |
| ----------- | --------------------------------------------------------------------- |
| `maxLines`  | Honor `maxLines` / `wrap` via `resolveMaxLines`; `TextOverflow.ellipsis` |
| `color`     | Apply `resolveContainerForegroundColor` from resolved appearance    |
| `isSubtle`  | Same color path as markdown                                           |
| `weight`    | Already resolved; ensure plain `Text` uses merged appearance          |

Markdown path limitations remain documented (no `maxLines` in `MarkdownBody`).

## Explicit non-goals

- **Full HTML markdown** in `TextBlock` or `RichTextBlock`.
- **Teams-only text features**, including:
  - `<at>…</at>` mention markup and root **`msteams.entities`** mention wiring
  - Teams-specific HTML in connector/hero/thumbnail cards
  - Any Teams-only **`{{…}}`** macro beyond standard **`{{DATE}}`** / **`{{TIME}}`** already supported on `TextBlock` / `FactSet`

Standard **`{{DATE}}`** / **`{{TIME}}`** macros continue to work on **`TextRun`** text the same as on **`TextBlock`**.

## Tests

- Unit: **`TextRunModel.fromJson`**
- Widget: bold run, colored run, **`selectAction` → Action.OpenUrl**
- Golden: mixed-style paragraph (`test/samples/v1.2/rich_text_block_demo.json`)
- TextBlock: plain path `maxLines`, `color`, `isSubtle` with `supportMarkdown: false`

## Widgetbook

- Sample: `widgetbook/lib/samples/v1.2/rich_text_block_demo.json`
- Register **`lib/samples/v1.2/`** in `widgetbook/pubspec.yaml` assets
- Use case under **TextBlock** category
