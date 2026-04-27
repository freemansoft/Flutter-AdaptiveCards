---
name: adaptive-cards-templating
description: How the flutter_adaptive_template_fs package implements Adaptive Card templating, its architecture, and its missing features or shortcomings.
---

# Adaptive Card Templating

This skill outlines how Adaptive Card templating is supported in the Flutter-AdaptiveCards monorepo, specifically via the `flutter_adaptive_template_fs` package.

## Overview

Templating in Adaptive Cards allows authors to define structural templates (UI definition) and separate data binding. The template is merged with a JSON payload at runtime.
Microsoft's official specification utilizes the Adaptive Expressions Language (AEL) for complex data manipulation, math, and logical evaluations.

In this project, the `flutter_adaptive_template_fs` package is responsible for data binding and template expansion. It takes an Adaptive Card json template and a data payload to produce a finalized JSON string that can be decoded and fed into the `flutter_adaptive_cards_fs` rendering engine.

## `flutter_adaptive_template_fs` Architecture

The engine is primarily composed of three components:

1. `AdaptiveCardTemplate`: The public API that accepts the initial template Map. Its `expand(Map<String, dynamic> data)` method delegates to the Evaluator and returns a resolved JSON String.
2. `Evaluator`: The core parser that traverses the template JSON structure (Maps, Lists, Strings).
3. `Resolver`: A utility class for safely looking up dot-notation (`root.property`) and array-indexing (`items[0]`) paths within a JSON structure.

## Core Implemented Features

The templating engine is a custom implementation of the Adaptive Card templating spec.
The outer template traversal uses a recursive parser and regex-based string interpolation (`${expression}`), while the contents of the expressions are passed to an Abstract Syntax Tree (AST) parser (`ExpressionParser`) for evaluation.

It supports the following core structural features:

- **String Interpolation**: Binding resolution using `${property}` or static text alongside bindings.
- **Context Iteration (`$data`)**:
  - **Array Binding**: When `$data` is bound to an array, the evaluator acts as a repeater, duplicating the surrounding template object for each item.
  - **Scope Shifting**: When `$data` binds to an object, it shifts the current evaluation scope into that object child.
- **Conditional Layout (`$when`)**: Allows a template block to be dropped entirely if the expression resolves to `false`.
- **Reserved Keywords**:
  - `$root` to always refer to the base data payload.
  - `$data` to refer to the current scoped context.
  - `$index` to refer to the current iteration counter inside array binding.

### Adaptive Expressions (AST)

Expressions inside `${...}` are parsed into an AST. Supported syntax includes:

- **Math and Operations**: Supports arithmetic (`+`, `-`, `*`, `/`, `%`, `^`), numeric comparisons (`>`, `<=`, `==`, `!=`), and boolean logical operators (`&&`, `||`, `!`).
- **String Functions**: Contains implementations for `toUpper`, `toLower`, `substring`, `trim`, `replace`, `length`, `concat`, `empty`.
- **Math Functions**: Contains implementations for `min`, `max`, `round`, `floor`, `ceil`.
- **JSON Functions**: Contains `json()` to transform a string into a map, and `if()` for inline logic.

## Shortcomings & Missing Features

While a significant portion of the Adaptive Expressions spec is implemented, there are a few notable gaps:

### 1. Missing Spec Functions

- **Advanced Functions**: While common math and string functions are present, Microsoft’s full Adaptive Expressions ecosystem defines dozens of more complex built-in functions (e.g., date-time formatting) that are not yet implemented.

### 2. Missing Key Expansion

- Currently, the package only expands _values_. The Adaptive Cards templating spec technically allows for dynamic object key names using string interpolation (`"${dynamicKey}": "value"`). The current `_expandMapObject` implementation skips evaluating keys dynamically.

### 3. Advanced Resolution Limitations

- `Resolver.resolve` is hardcoded to parse simple `part` splits and `[index]` bracket notation but will fail if bracket keys contain dots or complex string values.

## Summary

When working with `flutter_adaptive_template_fs`, be aware that **while it uses a real AST**, some edge-case functions and complex runtime logic might not be mapped. Complex datetime formatting must typically be handled by the host application _before_ injecting the data payload into the template.
