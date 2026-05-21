# Documentation Index

This directory contains design documents, implementation guides, and architectural documentation for the Flutter Adaptive Cards library.

## Quick Links

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

Comprehensive matrix tracking implementation status of all Adaptive Cards elements, containers, inputs, actions, HostConfig, and templating against the Microsoft v1.6 specification. Includes custom/extended elements, known gaps, and priority recommendations.

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

High-level system architecture showing package structure, widget hierarchy, and state management (Riverpod internals vs consumer API).

---

## Implementation Guides

### [AdaptiveWidget-Key-Generation.md](./AdaptiveWidget-Key-Generation.md)

**Status**: ✅ Current | **Category**: Implementation Guide

Widget key generation pattern using `generateWidgetKey()` for all AdaptiveElementWidget classes. Shows constructor pattern for reliable state binding.

### [form-inputs.md](./form-inputs.md)

**Status**: ✅ Current | **Category**: Implementation Guide

Guide for Flutter Form-based input implementation. Documents key naming conventions:

- Card widget: `{id}_adaptive`
- Input field: `{id}`
- Test requirements for validation, JSON loading, value changes

### [Implementing-IsVisible.md](./Implementing-IsVisible.md)

**Status**: ✅ Current | **Category**: Implementation Guide

Implementation of `isVisible` property for showing/hiding adaptive elements using Flutter's `Visibility` widget.

### [backgroundImage.md](./backgroundImage.md)

**Status**: ⚠️ Needs Verification | **Category**: Implementation Guide

Describes support for `backgroundImage` in both string (URL) and object (URL + fillMode) forms. Needs verification that both forms are implemented.

---

## Feature Specifications

### [adaptive-template-design.md](./adaptive-template-design.md)

**Status**: ✅ Current | **Category**: Feature Spec

Design specification for the Dart templating engine in `flutter_adaptive_template_fs` package. Documents:

- `$data`, `$root`, `$index` scoping
- Array binding
- Conditional rendering with `$when`
- `json()` function for embedded JSON
- Based on [Microsoft Templating Language](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)

### [Encoded-Image-Support.md](./Encoded-Image-Support.md)

**Status**: ✅ Current | **Category**: Feature Spec

Specification for base64 encoded inline image support using `Image.memory`. Includes JSON examples and implementation requirements.

---

## Test Requirements

### [hostconfig_tests.md](./hostconfig_tests.md)

**Status**: ✅ Current | **Category**: Test Requirements

Test requirements for HostConfig serialization. Each HostConfig entity should have:

- Test file: `packages/flutter_adaptive_cards_fs/test/hostconfig/{name}_test.dart`
- JSON file: `packages/flutter_adaptive_cards_fs/test/hostconfig/{name}.json`
- Validation against schema

---

## Known Issues & Future Work

### [Column-ColumnSet-Fill-Vertical-Height.md](./Column-ColumnSet-Fill-Vertical-Height.md)

**Status**: ⚠️ Documents Bug | **Category**: Known Issue

Documents bug where AdaptiveColumns in an AdaptiveColumnSet have inconsistent heights instead of matching the tallest column. Needs verification if still current.

---

## Reference Material

### [adaptive-template-design.md](./adaptive-template-design.md)

**Status**: ⚠️ Future Reference Only | **Category**: Reference

**NOT part of standard Adaptive Cards specification.** Documents Azure Bot Service expression functions for potential future integration. For standard templating, see [adaptive-template-design.md](./adaptive-template-design.md).

---

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

Last Updated: 2026-02-13
