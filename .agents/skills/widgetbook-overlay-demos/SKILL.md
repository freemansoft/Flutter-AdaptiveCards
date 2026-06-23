---
name: widgetbook-overlay-demos
description: >
  Example/sample program only: patterns and registry for widgetbook host-overlay demo
  pages (widgetbook/lib/*_overlay_page.dart). Use when adding or reviewing widgetbook
  knob demos — not for package overlay architecture (see reactive-riverpod, form-inputs).
---

# Widgetbook overlay demo pages (sample program)

> **`widgetbook/`** is a demonstration app. Library overlay contracts live in [`docs/reactive-riverpod.md`](../../../docs/reactive-riverpod.md) and package tests. See [`docs/documentation-scope.md`](../../../docs/documentation-scope.md).

Canonical reference: [`docs/widgetbook-overlay-demos.md`](../../../docs/widgetbook-overlay-demos.md)

Use this skill for **Widgetbook demo plumbing** (GlobalKey, knob lifecycle, use-case registration). Library overlay APIs are covered by **`adaptive-cards-testing`** and [`docs/reactive-riverpod.md`](../../../docs/reactive-riverpod.md).

## When to use

- Adding or reviewing `widgetbook/lib/*_overlay_page.dart`
- Explaining why `textBlockOverlayPageKey` / `factSetOverlayPageKey` exist
- Choosing per-build vs change-only apply lifecycle for a new knob demo
- Auditing registry drift between code and docs

## Quick workflow

1. Read [`docs/widgetbook-overlay-demos.md`](../../../docs/widgetbook-overlay-demos.md) — shared checklist + **registry**.
2. If the user names a page, review only that file; otherwise glob `widgetbook/lib/*_overlay_page.dart` and check each registry row.
3. Load page-specific spec/plan from the registry **Spec / plan** column (if any).
4. Compare code vs shared checklist + page-specific docs.
5. If a new page is missing from the registry, recommend adding a row before claiming complete.

## Shared checklist (summary)

- Page-level `GlobalKey` passed from `adaptive_cards_use_cases.dart`
- `OverlayDemoPageState` mixin from `widgetbook/lib/overlay_demo_scaffold.dart`
- `widgetbookCardTypeRegistry` / `widgetbookChartOverlayCardTypeRegistry` from `widgetbook/lib/widgetbook_card_registry.dart`
- Knobs read at top of `build()` before early returns
- Per-page `_queue…` + mixin `scheduleOverlayApply` / `runWhenCardReady` (30-attempt retry)
- `_lastApplied…` dedup
- Prefer public `flutter_adaptive_cards_fs` imports

## Apply lifecycle

| Strategy | Use when | Example |
| -------- | -------- | ------- |
| Per-build queue | Cheap `setText`, string knobs | `text_block_overlay_page.dart` |
| Change-only sync | Heavy `setFacts`/`clearFacts`, dropdown presets | `fact_set_overlay_page.dart` |

## Registry (keep in sync with code)

| Page | GlobalKey | Host API | Target id | Lifecycle | Use case |
| ---- | --------- | -------- | --------- | --------- | -------- |
| `text_block_overlay_page.dart` | `textBlockOverlayPageKey` | `setText` | `bodyText` | per-build | Text overlay (knob) |
| `fact_set_overlay_page.dart` | `factSetOverlayPageKey` | `setFacts` / `clearFacts` | `demoFactSet` | change-only | Facts overlay (knob) |

Full columns (assets, knobs, spec links): see the doc registry table.

## Adding a new overlay page

Follow **Adding a new overlay demo** in [`docs/widgetbook-overlay-demos.md`](../../../docs/widgetbook-overlay-demos.md). Minimum deliverables:

1. `*_overlay_page.dart` + sample JSON with element `id`
2. Use case + `GlobalKey`
3. **Registry row** in the doc
4. Library tests for the host API (not Widgetbook-only)

## Review output template

```markdown
## Summary
Does `<page>.dart` match shared patterns and its registry entry?

## Shared pattern compliance
GlobalKey, knobs-before-early-return, queue/retry/dedup, imports, use case.

## Page-specific behavior
Host API, target id, knob type(s), lifecycle strategy, baseline/clear semantics.

## vs sibling pages
Justify lifecycle differences.

## Spec / plan alignment
Only if registry lists doc paths.

## Verdict
Matches / regression / registry update needed.
```

Do not propose refactors unless the user asks to change implementation.
