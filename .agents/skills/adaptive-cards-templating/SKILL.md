---
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

The current system is a **custom, naive implementation** of the Adaptive Card templating spec. 
It supports the following core structural features:

- **String Interpolation**: Simple binding resolution using `${property}` or static text alongside bindings.
- **Context Iteration (`$data`)**: 
  - **Array Binding**: When `$data` is bound to an array, the evaluator acts as a repeater, duplicating the surrounding template object for each item.
  - **Scope Shifting**: When `$data` binds to an object, it shifts the current evaluation scope into that object child.
- **Conditional Layout (`$when`)**: Allows a template block to be dropped entirely if the expression resolves to `false` (e.g., `"${price > 30}"`).
- **Reserved Keywords**: 
  - `$root` to always refer to the base data payload.
  - `$data` to refer to the current scoped context.
  - `$index` to refer to the current iteration counter inside array binding.
- **Limited Functions**: Exposes `json(string)` and `if(condition, trueResult, falseResult)`.

## Shortcomings & Missing Features

The `flutter_adaptive_template_fs` package uses simple RegExp and manual string manipulation rather than a compiled AST (Abstract Syntax Tree) expression parser. This leads to several notable deviations from the spec:

### 1. Incomplete Expression Language (AEL)
- **Functions**: Microsoft’s Adaptive Expressions ecosystem defines dozens of built-in functions (e.g., `formatDateTime`, `subString`, `length`, `concat`, etc.). The current package only implements `json()` and `if()`.
- **Math and Operations**: Supports very basic numeric comparisons (`>`, `<=`). It lacks full boolean logical operators (e.g., `&&`, `||`) or arithmetic (`+`, `-`, `*`, `/`).

### 2. Naive Parsing Logic
- **Regex Limitations**: The evaluator uses a basic `RegExp(r'\$\{(.*?)\}')` search to find interpolations. It does not handle deeply nested braces well.
- **Argument Splitting**: The `_splitArgs` method splits on commas indiscriminately. This means using a comma inside a string literal (e.g., `if(cond, 'Yes, okay', 'No')`) will break the `if()` function because the quotes are not respected during splitting.
- **Parentheses Counting**: While function calls do use a parentheses balancing loop, it is basic and lacks error recovery.

### 3. Missing Key Expansion
- Currently, the package only expands *values*. The Adaptive Cards templating spec technically allows for dynamic object key names using string interpolation (`"${dynamicKey}": "value"`). The current `_expandMapObject` implementation skips this entirely.

### 4. Advanced Resolution Limitations
- `Resolver.resolve` is hardcoded to parse simple `part` splits and `[index]` bracket notation but will fail if bracket keys contain dots or complex string values.

## Summary

When working with `flutter_adaptive_template_fs`, be aware that **it is not a full Adaptive Expressions engine**. Complex logical conditions and string formatting must typically be handled by the host application *before* injecting the data payload into the template, rather than expecting the templating engine to mutate strings on the fly.
