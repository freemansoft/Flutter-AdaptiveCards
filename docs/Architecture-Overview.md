# Architecture Overview

**Status**: ✅ Current | **Category**: Architecture

This document provides a high-level overview of the system architecture for the Flutter Adaptive Cards monorepo.

## Package Structure

The repository is organized as a monorepo containing multiple related packages:

- **`flutter_adaptive_cards_fs`**: The core library that parses Adaptive Card JSON into Flutter widgets. It handles element rendering, layout, styling via HostConfig, and user interactions.
- **`flutter_adaptive_charts_fs`**: A supplemental library for rendering charting components (e.g., bar charts, pie charts) as extensions to the standard Adaptive Cards schema. **Not part of the core package** — see [optional-packages-and-extensions.md](./optional-packages-and-extensions.md).
- **`flutter_adaptive_template_fs`**: The templating engine that merges data JSON into template JSON (Adaptive Cards Templating language). **Not part of the core package** — see [optional-packages-and-extensions.md](./optional-packages-and-extensions.md).
- **`adaptive_explorer`**: A design studio desktop application that allows developers to author, preview, and debug Adaptive Cards, templates, and data payloads.

## Widget Hierarchy

When an Adaptive Card is rendered, the JSON is recursively parsed into a hierarchy of Flutter widgets:

1. **`AdaptiveCardsCanvas`**: Host entry widget that loads card JSON (asset, network, or in-memory) and builds a **`RawAdaptiveCard`** when content is ready.
2. **`RawAdaptiveCard`**: Installs the card-scoped `ProviderScope` (document notifier, registries, `ReferenceResolver`) and renders the parsed root element tree inside a `Card`.
3. **`AdaptiveCardElement`**: Represents the `AdaptiveCard` JSON root (`body`, `actions`), applying padding, background, and action layout.
4. **Containers and Elements**: Elements like `AdaptiveColumnSet`, `AdaptiveContainer`, `AdaptiveTextBlock`, and `AdaptiveImage` are rendered as individual Flutter widgets (often wrapping standard Flutter widgets like `Column`, `Row`, `Text`, and `Image`).
5. **Inputs**: Form inputs (`Input.Text`, `Input.Date`, etc.) use Flutter form controls. **Initial** values come from the adaptive map at widget construction; **runtime** values, validation, and visibility are stored in Riverpod document **overlays** (baseline JSON is never mutated). Inputs sync via `AdaptiveInputMixin` + `resolvedElementProvider(id)`. See [`reactive-riverpod.md`](reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map).
6. **Display elements**: `TextBlock` and other elements with natural ids can use the same overlay model (e.g. runtime `text` replacement via `setText` / `resolvedElementProvider`).
7. **Actions**: The action bar (e.g., `Action.Submit`, `Action.OpenUrl`) is typically rendered at the bottom of the card or within an `ActionSet`. Actions trigger callbacks routed through `GenericAction` handlers and, for default behaviors, `InheritedAdaptiveCardHandlers`. Submit/Execute payloads are typed invoke objects, not raw maps. AC 1.5 `isEnabled` is reactive via `resolvedActionProvider(id)`.

## State and dependency injection

`flutter_adaptive_cards_fs` uses **Riverpod (v3.x)** internally for card-scoped dependency injection and **reactive** document/UI state. The library installs its own `ProviderScope` per rendered card subtree, so host apps do not need to set up Riverpod to use the package.

See [`reactive-riverpod.md`](reactive-riverpod.md) for the scope map, provider architecture, and **baseline + overlay** document model.

### Document overlays (elements and actions)

Runtime changes (input values, visibility, TextBlock text, validation, ChoiceSet choices, action enabled state) do not mutate the host JSON. The document notifier keeps a deep-copied **baseline** (cached on `RawAdaptiveCardState` so host rebuilds do not reset overlays) plus sparse **overlays** (`overlaysById`, `actionOverlaysById`); widgets read merged maps via `resolvedElementProvider(id)` and `resolvedActionProvider(id)`. Submit and reset use the notifier (`collectInputValues`, `resetAllInputs`). Details: [How overlays change values](reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map). Test inventory: [Overlay test coverage](reactive-riverpod.md#overlay-test-coverage).

### Where state actually lives

| Concern | Mechanism |
| --- | --- |
| Card JSON + runtime overlays | Riverpod document notifier (`ElementOverlay` + `ActionOverlay` tables) |
| Show-card expanded/collapsed state | Riverpod per-`AdaptiveCardElement` UI notifier |
| Host callbacks (`onSubmit`, `onChange`, …) | `InheritedAdaptiveCardHandlers` |
| `CardTypeRegistry` / `ActionTypeRegistry` | Riverpod `cardTypeRegistryProvider` / `actionTypeRegistryProvider` (overridden per raw-card scope) |
| `ReferenceResolver` (HostConfig / theme) | Riverpod `styleReferenceResolverProvider` (overridden at card root and per subtree by `ChildStyler`; **does not** carry registries) |
| Root card scope (`RawAdaptiveCardState`) | Riverpod `rawAdaptiveCardStateProvider` |
| Theme / `HostConfig` updates | `ReferenceResolver` rebuilt when host/theme changes; `ProviderScope` keyed on brightness so descendants re-resolve styles |

### Style inheritance

Container foreground context and horizontal alignment flow down the element tree via **`ChildStyler`** nested `ProviderScope` overrides. Container **background** colors use each element's own `style` property only. See [Style inheritance data flow](adaptive-style.md#style-inheritance-data-flow) and [Resolver field lifecycle](adaptive-style.md#resolver-field-lifecycle) in `adaptive-style.md`.

### Inherited scopes

Host callbacks remain an `InheritedWidget` (`InheritedAdaptiveCardHandlers`). Most other cross-cutting services and reactive state live in Riverpod providers scoped to the card subtree.

### Consumer API

From the perspective of a host integrating `flutter_adaptive_cards_fs`:

1. Provide JSON and `HostConfig` via `AdaptiveCardsCanvas` (or `RawAdaptiveCard`).
2. Optionally pass custom `CardTypeRegistry` / `ActionTypeRegistry`, or wrap the tree with `InheritedAdaptiveCardHandlers` for submit/execute/open-url/change callbacks.
3. Wrap the card with **`InheritedAdaptiveCardHandlers`** for Submit, Execute, OpenUrl, and input **`onChange`** callbacks. All five callbacks receive typed invoke payloads: **`SubmitActionInvoke`**, **`ExecuteActionInvoke`**, **`OpenUrlActionInvoke`**, **`OpenUrlDialogActionInvoke`**, and **`InputChangeInvoke`**. **`AdaptiveCardsCanvas`** accepts **`onChange`** directly (same **`InputChangeInvoke`** type); it does **not** expose Submit/Execute/OpenUrl handlers on the widget or its state.

No third-party DI package is required at the app level.

## Optional packages and third-party isolation

Charts and templating live in **separate packages** so apps that do not use those features do not pull in **fl_chart** or the templating evaluator. Optional extensions register through `CardTypeRegistry.addedElements` (for example `CardChartsRegistry.additionalChartElements`).

See [optional-packages-and-extensions.md](./optional-packages-and-extensions.md) for the full strategy, consumer checklist, and rules for future extension packages.

## Extension Points

The architecture is designed to be extensible:

- **`CardTypeRegistry`**: Allows consumers to register custom parsers and widgets for new element types (e.g., adding a custom `MyCompany.MapWidget`, or merging chart/gauge registries from optional packages).
- **`ActionTypeRegistry`**: Allows consumers to override default action behaviors or add support for custom action types.
- **`HostConfig`**: Provides a robust theming system to ensure the rendered cards match the host application's branding and design language.
