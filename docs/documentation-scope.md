# Documentation scope

**Status**: ✅ Current | **Category**: Reference

Rules for what belongs in `docs/`, how published packages are documented, and how the **widgetbook** sample app is referenced.

## What `docs/` describes

Canonical design and implementation documentation in `docs/` describes the **published library packages**:

| Package | Role |
| ------- | ---- |
| [`flutter_adaptive_cards_fs`](../packages/flutter_adaptive_cards_fs/) | Core renderer, overlays, actions, HostConfig |
| [`flutter_adaptive_charts_fs`](../packages/flutter_adaptive_charts_fs/) | `Chart.*` extension elements |
| [`flutter_adaptive_template_fs`](../packages/flutter_adaptive_template_fs/) | Adaptive Cards templating |
| [`flutter_adaptive_cards_host_fs`](../packages/flutter_adaptive_cards_host_fs/) | Optional backend invoke bridge |

Package READMEs, [`Architecture-Overview.md`](Architecture-Overview.md), [`reactive-riverpod.md`](reactive-riverpod.md), [`form-inputs.md`](form-inputs.md), and related guides document **library contracts** (APIs, overlay merge, theming, actions).

## Sample apps (not package architecture)

| App | Role in docs |
| --- | ------------ |
| **`widgetbook/`** | **Demonstration / sample program** — interactive gallery of card JSON and host-callback demos. Illustrates usage; does not define package behavior. |
| **`adaptive_explorer/`** | Template + card editor sample (desktop). |

When a canonical doc mentions widgetbook paths, knobs, or use cases, label that material as an **example** (see [Tagging examples](#tagging-examples-in-canonical-docs)).

## Widgetbook-specific documentation

- **Filename rule:** Any doc whose primary subject is widgetbook setup, use cases, overlay demo pages, or manual smoke tests MUST include **`widgetbook`** in the filename (e.g. [`widgetbook-overlay-demos.md`](widgetbook-overlay-demos.md)).
- **Location:** Prefer `docs/*widgetbook*.md` for cross-repo widgetbook guides; operational detail may also live in [`widgetbook/README.md`](../widgetbook/README.md).
- **Do not** embed widgetbook-only checklists in package architecture sections without an **Example** label — link to a `*widgetbook*` doc instead.

## Tagging examples in canonical docs

In package-focused docs (`form-inputs.md`, `reactive-riverpod.md`, `actions-architecture.md`, specs under `docs/superpowers/specs/`, …):

1. **Section titles** that rely on widgetbook → prefix or suffix with **Example (widgetbook sample)**.
2. **Diagrams** that include widgetbook participants → note in prose: *Example flow; widgetbook sample implements the host `onChange` handler.*
3. **Manual verification** → **Example (widgetbook sample):** manual verification — not a substitute for package tests.
4. **Tables** listing widgetbook use cases → column or section header **Example (widgetbook)**.

Package tests under `packages/*/test/` remain the authoritative verification for library behavior.

## Diagram canon

Architecture diagrams in canonical docs depict **package runtime** (baseline, overlays, registries, handlers). See [Architecture-Overview.md — Diagram canon](Architecture-Overview.md#diagram-canon).

- Monorepo layout may show widgetbook under **sample apps** (not published packages).
- Do not draw widgetbook-specific knob lifecycle in package overlay diagrams — that belongs in [`widgetbook-overlay-demos.md`](widgetbook-overlay-demos.md).

## For agents and skills

When authoring or updating documentation or skills:

- Describe **host APIs and notifier behavior** from package sources and `docs/reactive-riverpod.md`.
- Point **widgetbook demo plumbing** to [`widgetbook-overlay-demos.md`](widgetbook-overlay-demos.md) and the **`widgetbook-overlay-demos`** skill.
- New widgetbook-only guides → `docs/<topic>-widgetbook.md` or `docs/widgetbook-<topic>.md`.

See also [AI-Agent-Support.md](AI-Agent-Support.md) and [`.agents/skills/writing-skills/anthropic-best-practices.md`](../.agents/skills/writing-skills/anthropic-best-practices.md#flutter-adaptivecards-project-conventions-this-monorepo).
