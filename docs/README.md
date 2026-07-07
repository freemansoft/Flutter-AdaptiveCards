# Documentation Index

This directory contains design documents, implementation guides, and architectural documentation for the Flutter Adaptive Cards **library packages**. See **[documentation-scope.md](./documentation-scope.md)** for what `docs/` covers vs sample apps (**widgetbook**, **adaptive_explorer**).

## Quick Links

- **Documentation scope** (packages vs widgetbook samples): [documentation-scope.md](./documentation-scope.md)
- **Widgetbook overlay demos** (sample program): [widgetbook-overlay-demos.md](./widgetbook-overlay-demos.md)
- **Cursor and Antigravity created plans** copied from ~/.cursor/plans : [plans](/docs/plans/) (superseded duplicates in [archive/plans](/docs/archive/plans/))
- **Copilot created plans** _no documentation exists at this time_
- **Superpowers created specs** [specs](/docs/superpowers/specs/) (implemented duplicates in [archive/specs](/docs/archive/specs/))
- **AI / LLM agents**: [AI-Agent-Support.md](/docs/AI-Agent-Support.md)
- **Main Project**: [Repository README](/README.md)
- **Library README**: [flutter_adaptive_cards_fs README](/packages/flutter_adaptive_cards_fs/README.md)
- **Microsoft Standards**:
  - [Adaptive Cards Hub](https://adaptivecards.microsoft.com/)
  - [Legacy Site & Schema Explorer](https://adaptivecards.io/)
  - [GitHub - Schemas](https://github.com/microsoft/AdaptiveCards/tree/main/schemas/1.6.0)
  - [GitHub - Samples](https://github.com/microsoft/AdaptiveCards/tree/main/samples/v1.5/Scenarios)

---

## Implementation Status

### [Implementation-Status.md](./Implementation-Status.md)

**Status**: ✅ Current | **Category**: Status Matrix

Comprehensive matrix tracking implementation status of all Adaptive Cards elements, containers, inputs, actions, HostConfig, and templating against the Microsoft v1.6 specification. Includes custom/extended elements, known gaps, priority recommendations, and a **Recently completed** rollup for the [June 2026 feature plan](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md).

### [2026-06-08-refresh-icon-charts-text-features.plan.md](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md)

**Status**: ✅ Complete (workstreams A–G) | **Category**: Implementation Plan

End-to-end plan for `refresh`, hub **`Icon`**, chart chrome/colors/**`Chart.Gauge`**, and **`RichTextBlock`** / **`TextRun`** + TextBlock fixes. Links to [text features design spec](./superpowers/specs/2026-06-08-rich-text-and-text-features-design.md) (workstream G).

---

## AI & Agent Configuration

### [documentation-scope.md](./documentation-scope.md)

**Status**: ✅ Current | **Category**: Reference

Defines what `docs/` describes (published packages under `packages/`) vs sample apps (`widgetbook`, `adaptive_explorer`). Rules for tagging **Example (widgetbook sample)** in canonical docs and **`widgetbook` in filenames** for widgetbook-only guides.

### [AI-Agent-Support.md](./AI-Agent-Support.md)

**Status**: ✅ Current | **Category**: Explanation (`doc_type: explanation`)

Explains how LLM agents are configured for this repo: `AGENTS.md`, the two-layer `.agents/skills/` model, skill sources ([dart-lang/skills](https://github.com/dart-lang/skills), [flutter/skills](https://github.com/flutter/skills), [obra/superpowers](https://github.com/obra/superpowers)), and how agents load skills. Install / update commands: [ai-agent-skills-install.md](./ai-agent-skills-install.md).

### [ai-agent-skills-install.md](./ai-agent-skills-install.md)

**Status**: ✅ Current | **Category**: How-to (`doc_type: how-to`)

Install and update commands for the vendored agent skills (Dart / Flutter / Superpowers, project + user-level, Cursor plugin, restore-from-lock). Extracted from [AI-Agent-Support.md](./AI-Agent-Support.md).

---

## Architecture & Design

### [actions-architecture.md](./actions-architecture.md)

**Status**: ✅ Current | **Category**: Architecture

Describes the action system architecture using Generic interfaces, Default implementations, and ActionTypeRegistry pattern. Essential reading for understanding action handling.

### [adaptive-style.md](./adaptive-style.md)

**Status**: ✅ Current | **Category**: Architecture

Style pipeline: `ReferenceResolver` facade, container style inheritance via `ChildStyler`, TextBlock/Image style resolution, and canonical diagrams. Model parsing and theme fallbacks: [hostconfig.md](./hostconfig.md).

### [Architecture-Overview.md](./Architecture-Overview.md)

**Status**: ✅ Current | **Category**: Architecture

High-level system architecture: monorepo layout, **core component model** diagram (registries, overlays, style, handlers), widget hierarchy, state management, and [diagram canon](./Architecture-Overview.md#diagram-canon).

### [optional-packages-and-extensions.md](./optional-packages-and-extensions.md)

**Status**: ✅ Current | **Category**: Architecture

Why charts, templating, and **backend invoke** are separate packages, how to opt in via registries or `AdaptiveCardBackendHandlers`, and rules for future optional extension packages.

### [backend-host-integration.md](./backend-host-integration.md)

**Status**: ✅ Current | **Category**: How-to (`doc_type: how-to`)

Integration guide for **`flutter_adaptive_cards_host_fs`** — wiring `AdaptiveCardBackendHandlers`, quick start, refresh, sign-in, custom transport, consumer checklist. Wire protocol details: [backend-invoke-reference.md](./backend-invoke-reference.md).

### [backend-invoke-reference.md](./backend-invoke-reference.md)

**Status**: ✅ Current | **Category**: Reference (`doc_type: reference`)

Wire-level reference: `associatedInputs` request payloads, PlainJson/Teams adapters, the `adaptiveCard.invokeResponse` contract, effect apply order, and the error table. Extracted from [backend-host-integration.md](./backend-host-integration.md).

### [reactive-riverpod.md](./reactive-riverpod.md)

**Status**: ✅ Current | **Category**: Architecture

Riverpod scopes, document notifier, cached baseline on rebuild, **baseline + overlay** model, visibility, submit/reset without mutating host JSON. Per-type patch keys: [overlay-properties-by-type.md](./overlay-properties-by-type.md).

---

### [overlay-properties-by-type.md](./overlay-properties-by-type.md)

**Status**: ✅ Current | **Category**: Reference

Host index of runtime patch keys (`applyUpdates`, `applyUpdatesFromMap`) by JSON `type` — which overlays affect UI, typed helpers, and contract tests.

---

## Implementation Guides

### [AdaptiveWidget-Key-Generation.md](./AdaptiveWidget-Key-Generation.md)

**Status**: ✅ Current | **Category**: Implementation Guide

Widget key generation pattern using `generateWidgetKey()` for all AdaptiveElementWidget classes. Shows constructor pattern for reliable state binding.

### [form-inputs.md](./form-inputs.md)

**Status**: ✅ Current | **Category**: Reference (`doc_type: reference`)

Reference for Flutter Form-based inputs and the input hub. Documents runtime **baseline + overlay** value flow ([input overlay architecture diagram](./form-inputs.md#input-overlay-architecture)), reset semantics, ChoiceSet styles, dependent ChoiceSet, host validation APIs, and test requirements. Widget key generation: [AdaptiveWidget-Key-Generation.md](./AdaptiveWidget-Key-Generation.md).

### [input-text-recipes.md](./input-text-recipes.md)

**Status**: ✅ Current | **Category**: How-to (`doc_type: how-to`)

Task recipes for `Input.Text`: phone-style character filtering and password masking / reveal toggle. Extracted from [form-inputs.md](./form-inputs.md).

### [custom-action-recipe.md](./custom-action-recipe.md)

**Status**: ✅ Current | **Category**: How-to (`doc_type: how-to`)

Step-by-step recipe for implementing a custom action (`Generic*` interface + custom `ActionTypeRegistry`). Extracted from [actions-architecture.md](./actions-architecture.md).

### [backgroundImage.md](./backgroundImage.md)

**Status**: ✅ Current | **Category**: Implementation Guide

Describes support for `backgroundImage` in both string (URL) and object (URL + fillMode) forms. Both forms are implemented (`resolveBackgroundImage` in `adaptive_mixins.dart`) and tested (`test/elements/background_image_test.dart`).

---

## Feature Specifications

### [backend-host-integration.md](./backend-host-integration.md)

**Status**: ✅ Current | **Category**: How-to (`doc_type: how-to`)

Integration guide for optional **`flutter_adaptive_cards_host_fs`**: `AdaptiveCardBackendHandlers`, quick start, refresh, and sign-in round-trips. Wire protocol (serialization, adapters, response effects, error table): [backend-invoke-reference.md](./backend-invoke-reference.md).

### [adaptive-template-design.md](./adaptive-template-design.md)

**Status**: ✅ Current | **Category**: Feature Spec

Design specification for the Dart templating engine in `flutter_adaptive_template_fs` package. Documents:

- `$data`, `$root`, `$index` scoping
- Array binding
- Conditional rendering with `$when`
- `json()` function for embedded JSON
- Based on [Microsoft Templating Language](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)

### [2026-06-08-rich-text-and-text-features-design.md](./superpowers/specs/2026-06-08-rich-text-and-text-features-design.md)

**Status**: ✅ Current | **Category**: Feature Spec

Design for **`RichTextBlock`** / **`TextRun`** rendering and targeted **`TextBlock`** plain-path fixes (workstream G of the [June 2026 plan](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md)).

### [Encoded-Image-Support.md](./Encoded-Image-Support.md)

**Status**: ✅ Current | **Category**: Feature Spec

Specification for base64 encoded inline image support using `Image.memory`. Includes JSON examples and implementation requirements.

---

## HostConfig

### [hostconfig.md](./hostconfig.md)

**Status**: ✅ Current | **Category**: Explanation (`doc_type: explanation`)

HostConfig architecture: JSON model parsing, theme-derived color fallbacks (`ThemeColorFallbacks`), `ReferenceResolver` pipeline, brightness selection, Widgetbook notes. Style inheritance diagrams: [adaptive-style.md](./adaptive-style.md). Serialization testing: [hostconfig-testing.md](./hostconfig-testing.md).

### [hostconfig-testing.md](./hostconfig-testing.md)

**Status**: ✅ Current | **Category**: How-to (`doc_type: how-to`)

How to write/run HostConfig serialization tests (one fixture per entity, conventions) and the theme-fallback verification checklist. Extracted from [hostconfig.md](./hostconfig.md).

### Overlay / document notifier tests

**Status**: ✅ Current | **Category**: Test Requirements

Riverpod document **overlay** tests (notifier unit tests + widget integration) are catalogued in [reactive-riverpod.md — Overlay test coverage](./reactive-riverpod.md#overlay-test-coverage). Run from `packages/flutter_adaptive_cards_fs` with `fvm flutter test` on the listed paths.

---

## Known Issues & Future Work

### [Column-ColumnSet-Fill-Vertical-Height.md](./archive/specs/Column-ColumnSet-Fill-Vertical-Height.md) _(archived)_

**Status**: 🗄️ Historical (documents fixed bug) | **Category**: Known Issue (historical)

Documents a now-**fixed** bug where AdaptiveColumns in an AdaptiveColumnSet had inconsistent heights instead of matching the tallest column. Fix (`IntrinsicHeight` + `CrossAxisAlignment.stretch`) verified by `test/column_height_test.dart`; kept for historical reference in [`archive/specs/`](./archive/specs/).

---

## Reference Material

### [Adaptive-expressions-and-prebuilt-functions.md](./Adaptive-expressions-and-prebuilt-functions.md)

**Status**: ⚠️ Future Reference Only | **Category**: Reference

**NOT part of the standard Adaptive Cards specification.** Documents Azure Bot Service expression functions for potential future integration. For standard templating, see [adaptive-template-design.md](./adaptive-template-design.md).

---

## Diagram canon

Architecture diagrams are maintained in **canonical** docs (not duplicated from every plan/spec). See [Architecture-Overview.md — Diagram canon](./Architecture-Overview.md#diagram-canon) for which plan/spec Mermaid blocks are promoted vs kept as design history. Each published package README includes a **Package structure** diagram.

## Missing/Recommended Documentation

Based on the current state of the codebase, the following documents would be valuable additions:

- **Custom-Extensions.md**: Reference for all non-spec elements and actions (Rating, CodeBlock, CompoundButton, Carousel, Accordion, Badge, ProgressBar, ProgressRing, TabSet, Action.ResetInputs, Action.Popover, Action.InsertImage, Action.OpenUrlDialog) with JSON type strings, required properties, and behavior

---

## Contributing to Documentation

When adding or updating documentation:

1. **File Naming**: Use kebab-case with `.md` extension
2. **Status Indicators**: Use emoji in this README: ✅ Current, ⚠️ Needs Update, ❌ Obsolete
3. **Categories**: Architecture, Implementation Guide, Feature Spec, Test Requirements, Known Issue, Reference
4. **Link to Code**: Include links to relevant implementation files
5. **Link to Standard**: Reference Microsoft specification where applicable
6. **Examples**: Include JSON examples for clarity
7. **Update This Index**: Add new documents to the appropriate section

---

Last Updated: 2026-06-14
