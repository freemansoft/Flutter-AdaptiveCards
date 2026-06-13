# Documentation Index

This directory contains design documents, implementation guides, and architectural documentation for the Flutter Adaptive Cards **library packages**. See **[documentation-scope.md](./documentation-scope.md)** for what `docs/` covers vs sample apps (**widgetbook**, **adaptive_explorer**).

## Quick Links

- **Documentation scope** (packages vs widgetbook samples): [documentation-scope.md](./documentation-scope.md)
- **Widgetbook overlay demos** (sample program): [widgetbook-overlay-demos.md](./widgetbook-overlay-demos.md)
- **Cursor and Antigravity created plans** copied from ~/.cursor/plans : [plans](/docs/plans/)
- **Superpowers created specs** [specs](/docs/superpowers/specs/)
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

**Status**: ✅ Current | **Category**: Reference

Describes how LLM agents are configured for this repo: `AGENTS.md`, `.agents/skills/`, `skills-lock.json`, installation commands for [dart-lang/skills](https://github.com/dart-lang/skills), [flutter/skills](https://github.com/flutter/skills), and [obra/superpowers](https://github.com/obra/superpowers), plus project-specific skills and update procedures.

---

## Architecture & Design

### [actions-architecture.md](./actions-architecture.md)

**Status**: ✅ Current | **Category**: Architecture

Describes the action system architecture using Generic interfaces, Default implementations, and ActionTypeRegistry pattern. Essential reading for understanding action handling.

### [adaptive-style.md](./adaptive-style.md)

**Status**: ✅ Current | **Category**: Architecture

Comprehensive specification for HostConfig implementation and mapping to Flutter themes. Documents all configuration classes based on Microsoft's host-config.json schema.

### [Architecture-Overview.md](./Architecture-Overview.md)

**Status**: ✅ Current | **Category**: Architecture

High-level system architecture: monorepo layout, **core component model** diagram (registries, overlays, style, handlers), widget hierarchy, state management, and [diagram canon](./Architecture-Overview.md#diagram-canon).

### [optional-packages-and-extensions.md](./optional-packages-and-extensions.md)

**Status**: ✅ Current | **Category**: Architecture

Why charts, templating, and **backend invoke** are separate packages, how to opt in via registries or `AdaptiveCardBackendHandlers`, and rules for future optional extension packages.

### [backend-host-integration.md](./backend-host-integration.md)

**Status**: ✅ Current | **Category**: Feature Spec

Invoke round-trips with **`flutter_adaptive_cards_host_fs`** — request/response contract, effect ordering, Teams adapter, and consumer checklist.

### [reactive-riverpod.md](./reactive-riverpod.md)

**Status**: ✅ Current | **Category**: Architecture

Riverpod scopes, document notifier, cached baseline on rebuild, **baseline + overlay** model, [overlay test coverage](./reactive-riverpod.md#overlay-test-coverage), and reactive inputs, visibility, TextBlock text, validation, action `isEnabled`, show-card UI, and submit/reset without mutating host JSON.

---

## Implementation Guides

### [AdaptiveWidget-Key-Generation.md](./AdaptiveWidget-Key-Generation.md)

**Status**: ✅ Current | **Category**: Implementation Guide

Widget key generation pattern using `generateWidgetKey()` for all AdaptiveElementWidget classes. Shows constructor pattern for reliable state binding.

### [form-inputs.md](./form-inputs.md)

**Status**: ✅ Current | **Category**: Implementation Guide

Guide for Flutter Form-based input implementation. Documents runtime **baseline + overlay** value flow ([input overlay architecture diagram](./form-inputs.md#input-overlay-architecture)), key naming conventions:

- Card widget: `{id}_adaptive`
- Input field: `{id}`
- Test requirements for validation, JSON loading, value changes

### [Implementing-IsVisible.md](./Implementing-IsVisible.md)

**Status**: ✅ Current | **Category**: Implementation Guide

Implementation of `isVisible` for show/hide. Runtime toggles use document overlays and `resolvedElementProvider`; see also [`reactive-riverpod.md`](reactive-riverpod.md).

### [backgroundImage.md](./backgroundImage.md)

**Status**: ⚠️ Needs Verification | **Category**: Implementation Guide

Describes support for `backgroundImage` in both string (URL) and object (URL + fillMode) forms. Needs verification that both forms are implemented.

---

## Feature Specifications

### [backend-host-integration.md](./backend-host-integration.md)

**Status**: ✅ Current | **Category**: Feature Spec

Canonical guide for optional **`flutter_adaptive_cards_host_fs`**: invoke serialization, PlainJson/Teams adapters, response effects, `AdaptiveCardBackendHandlers`, error handling, and refresh round-trips.

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

**Status**: ✅ Current | **Category**: Architecture & Testing

HostConfig architecture: theme-derived color fallbacks (`ThemeColorFallbacks`), `ReferenceResolver` pipeline, brightness selection, Widgetbook notes, and serialization test conventions (JSON fixtures per entity under `test/hostconfig/`).

### Overlay / document notifier tests

**Status**: ✅ Current | **Category**: Test Requirements

Riverpod document **overlay** tests (notifier unit tests + widget integration) are catalogued in [reactive-riverpod.md — Overlay test coverage](./reactive-riverpod.md#overlay-test-coverage). Run from `packages/flutter_adaptive_cards_fs` with `fvm flutter test` on the listed paths.

---

## Known Issues & Future Work

### [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md)

**Status**: ⚠️ Documents Bug | **Category**: Known Issue

Documents bug where AdaptiveColumns in an AdaptiveColumnSet have inconsistent heights instead of matching the tallest column. Needs verification if still current.

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

Last Updated: 2026-06-09
