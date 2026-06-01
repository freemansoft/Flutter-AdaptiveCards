# Architecture Overview

**Status**: ✅ Current | **Category**: Architecture

This document provides a high-level overview of the system architecture for the Flutter Adaptive Cards monorepo.

## Package Structure

The repository is organized as a monorepo containing multiple related packages:

- **`flutter_adaptive_cards_fs`**: The core library that parses Adaptive Card JSON into Flutter widgets. It handles element rendering, layout, styling via HostConfig, and user interactions.
- **`flutter_adaptive_template_fs`**: The templating engine that merges data JSON into a template JSON structure, following the Adaptive Cards Templating language specification.
- **`flutter_adaptive_charts_fs`**: A supplemental library for rendering charting components (e.g., bar charts, pie charts) as extensions to the standard Adaptive Cards schema.
- **`adaptive_explorer`**: A design studio desktop application that allows developers to author, preview, and debug Adaptive Cards, templates, and data payloads.

## Widget Hierarchy

When an Adaptive Card is rendered, the JSON is recursively parsed into a hierarchy of Flutter widgets:

1. **`AdaptiveCardCanvas`**: The root widget that initializes the `CardTypeRegistry`, `ActionTypeRegistry`, and provides the `HostConfig` context. It wraps the entire card in necessary providers.
2. **`AdaptiveCardWidget`**: Represents the `AdaptiveCard` root element, applying the overall padding, background color, and layout constraints.
3. **Containers and Elements**: Elements like `AdaptiveColumnSet`, `AdaptiveContainer`, `AdaptiveTextBlock`, and `AdaptiveImage` are rendered as individual Flutter widgets (often wrapping standard Flutter widgets like `Column`, `Row`, `Text`, and `Image`).
4. **Inputs**: Form inputs (`Input.Text`, `Input.Date`, etc.) are rendered using standard Flutter form controls. Values and validation live in per-input `StatefulWidget` state (`AdaptiveInputMixin` + `setState`), not in Riverpod.
5. **Actions**: The action bar (e.g., `Action.Submit`, `Action.OpenUrl`) is typically rendered at the bottom of the card or within an `ActionSet`. Actions trigger callbacks routed through `GenericAction` handlers and, for default behaviors, `InheritedAdaptiveCardHandlers`.

## State and dependency injection

The core library uses **`InheritedWidget` scopes** for cross-cutting services (not Riverpod). See [`doc/replace-riverpod.md`](replace-riverpod.md) for the migration notes and scope map.

### Where state actually lives

| Concern | Mechanism |
| --- | --- |
| Input values, visibility, show-card targets | `StatefulWidget` + `AdaptiveInputMixin` / `AdaptiveVisibilityMixin` and per-`AdaptiveCardElement` `Form` state |
| Host callbacks (`onSubmit`, `onChange`, …) | `InheritedAdaptiveCardHandlers` |
| Registries, `ReferenceResolver`, root card state | `InheritedReferenceResolver.resolver` (outer, via `rawCardScopeOf`) |
| Per-card form, widget registry, show-card | `InheritedReferenceResolver` (inner, via `elementScopeOf`) |
| Theme / `HostConfig` updates | `RawAdaptiveCardState.didChangeDependencies` + `setState` |

### Inherited scopes

`RawAdaptiveCard` and each `AdaptiveCardElement` install nested `InheritedReferenceResolver` nodes (outer vs inner). Element and action `State` classes use `ProviderScopeMixin` to read `rawCardScopeOf` / `elementScopeOf` without constructor drilling.

### Consumer API

From the perspective of a host integrating `flutter_adaptive_cards_fs`:

1. Provide JSON and `HostConfig` via `AdaptiveCardsCanvas` (or `RawAdaptiveCard`).
2. Optionally pass custom `CardTypeRegistry` / `ActionTypeRegistry`, or wrap the tree with `InheritedAdaptiveCardHandlers` for submit/execute/open-url/change callbacks.
3. Listen to events such as `onSubmit` and receive gathered input data as a `Map`.

No third-party DI package is required at the app level.

## Extension Points

The architecture is designed to be extensible:

- **`CardTypeRegistry`**: Allows consumers to register custom parsers and widgets for new element types (e.g., adding a custom `MyCompany.MapWidget`).
- **`ActionTypeRegistry`**: Allows consumers to override default action behaviors or add support for custom action types.
- **`HostConfig`**: Provides a robust theming system to ensure the rendered cards match the host application's branding and design language.
