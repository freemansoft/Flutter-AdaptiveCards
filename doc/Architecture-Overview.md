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
4. **Inputs**: Form inputs (`Input.Text`, `Input.Date`, etc.) use Flutter form controls. **Initial** values come from the adaptive map at widget construction; **runtime** values and visibility are stored in Riverpod document **overlays** (baseline JSON is never mutated). Inputs sync via `AdaptiveInputMixin` + `resolvedElementProvider(id)`. See [`doc/reactive-riverpod.md`](reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map).
5. **Actions**: The action bar (e.g., `Action.Submit`, `Action.OpenUrl`) is typically rendered at the bottom of the card or within an `ActionSet`. Actions trigger callbacks routed through `GenericAction` handlers and, for default behaviors, `InheritedAdaptiveCardHandlers`.

## State and dependency injection

`flutter_adaptive_cards_fs` uses **Riverpod (v3.x)** internally for card-scoped dependency injection and **reactive** document/UI state. The library installs its own `ProviderScope` per rendered card subtree, so host apps do not need to set up Riverpod to use the package.

See [`doc/reactive-riverpod.md`](reactive-riverpod.md) for the scope map, provider architecture, and **baseline + overlay** document model.

### Document overlays (inputs and visibility)

Runtime changes to input values and element visibility do not mutate the host JSON. The document notifier keeps a deep-copied **baseline** plus sparse **overlays** per element id; widgets read a merged **resolved** view via `resolvedElementProvider(id)`. Submit and reset use the notifier (`collectInputValues`, `resetAllInputs`). Details: [How overlays change values](reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map).

### Where state actually lives

| Concern | Mechanism |
| --- | --- |
| Card JSON + runtime overlays (inputs, visibility) | Riverpod document notifier (baseline JSON + overlay tables) |
| Show-card expanded/collapsed state | Riverpod per-`AdaptiveCardElement` UI notifier |
| Host callbacks (`onSubmit`, `onChange`, …) | `InheritedAdaptiveCardHandlers` |
| `CardTypeRegistry` / `ActionTypeRegistry` | Riverpod `cardTypeRegistryProvider` / `actionTypeRegistryProvider` (overridden per raw-card scope) |
| `ReferenceResolver` (HostConfig / theme) | Riverpod `styleReferenceResolverProvider` (overridden per raw-card scope; **does not** carry registries) |
| Root card scope (`RawAdaptiveCardState`) | Riverpod `rawAdaptiveCardStateProvider` |
| Theme / `HostConfig` updates | `ReferenceResolver` rebuilt when host/theme changes (card-scoped) |

### Inherited scopes

Host callbacks remain an `InheritedWidget` (`InheritedAdaptiveCardHandlers`). Most other cross-cutting services and reactive state live in Riverpod providers scoped to the card subtree.

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
