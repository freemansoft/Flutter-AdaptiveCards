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
4. **Inputs**: Form inputs (`Input.Text`, `Input.Date`, etc.) are rendered using standard Flutter form controls, with their values tracked within the card's state.
5. **Actions**: The action bar (e.g., `Action.Submit`, `Action.OpenUrl`) is typically rendered at the bottom of the card or within an `ActionSet`. Actions trigger callbacks that are routed through the `GenericAction` handlers.

## State Management

The core library uses **Riverpod** for internal state management, primarily for handling input values, visibility toggling, and data fetching (e.g., dynamic choice sets).

### Riverpod Internals

- **`RawAdaptiveCardState`**: The central state object that holds the current values of all inputs, tracks which elements are visible/hidden, and manages the execution of actions.
- **Providers**: Various Riverpod providers are used to expose state to the widget tree. For example, a `StateNotifierProvider` might track the selected items in a `ChoiceSet` or the text in a `TextInput`.
- **Consumer Widgets**: Deeply nested widgets that need to read or update state use Riverpod's `ConsumerWidget` or `ConsumerStatefulWidget` to access the providers without passing callbacks manually down the tree.

### Consumer API

From the perspective of a consumer integrating `flutter_adaptive_cards_fs`:

1. The consumer provides the JSON payload and a `HostConfig` to the `AdaptiveCardCanvas`.
2. The consumer registers custom element or action handlers if needed.
3. The consumer listens to events, such as `onSubmit` (when an `Action.Submit` is triggered), receiving the gathered input data as a Dart `Map`.
4. The internal Riverpod state is abstracted away from the consumer. They interact primarily through the widget's constructor parameters and event callbacks.

## Extension Points

The architecture is designed to be extensible:

- **`CardTypeRegistry`**: Allows consumers to register custom parsers and widgets for new element types (e.g., adding a custom `MyCompany.MapWidget`).
- **`ActionTypeRegistry`**: Allows consumers to override default action behaviors or add support for custom action types.
- **`HostConfig`**: Provides a robust theming system to ensure the rendered cards match the host application's branding and design language.
