---
name: factset-widgetbook-knob-deviation
description: Deprecated alias — use widgetbook-overlay-page-review. FactSet details are in docs/widgetbook-overlay-demos.md registry row and the FactSet overlay spec/plan.
---

**Deprecated.** Use the **`widgetbook-overlay-page-review`** agent instead.

When reviewing FactSet specifically:

1. Invoke **`widgetbook-overlay-page-review`** (or follow `.agents/skills/widgetbook-overlay-demos/SKILL.md`).
2. Target **`widgetbook/lib/fact_set_overlay_page.dart`** and the **FactSet** registry row in [`docs/widgetbook-overlay-demos.md`](../../docs/widgetbook-overlay-demos.md).
3. For package overlay semantics, see [`docs/reactive-riverpod.md`](../../docs/reactive-riverpod.md). For the widgetbook example section, see [FactSet overlay spec](../../docs/superpowers/specs/2026-06-06-factset-facts-overlay-design.md#example-widgetbook-sample-factset-overlay-knob) and [plan Task 8](../../docs/superpowers/plans/2026-06-06-factset-facts-overlay.plan.md).

Do not maintain FactSet-only review logic in this file.
