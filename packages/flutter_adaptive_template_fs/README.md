# Flutter Adaptive Template

A template engine for adaptive cards, enabling data binding and dynamic rendering of adaptive card payloads in Flutter.

## Usage

You can use the `AdaptiveCardTemplate` to expand a JSON-based template with a data Map.

```dart
import 'dart:convert';
import 'package:flutter_adaptive_template_fs/flutter_adaptive_template_fs.dart';

void main() {
  // 1. Define your template (usually loaded from a file or asset using jsonDecode)
  final templateJson = {
    'type': 'TextBlock',
    'text': r'Hello, ${name}!'
  };

  // 2. Define your data (usually loaded from an API or local file)
  final data = {
    'name': 'Matt'
  };

  // 3. Create the template instance
  final template = AdaptiveCardTemplate(templateJson);

  // 4. Expand the template with the provided data
  final String mergedPayload = template.expand(data);

  // The output is a JSON string with the expanded placeholders
  print(mergedPayload); // {"type":"TextBlock","text":"Hello, Matt!"}
}
```

## Status: MVP Implemented

Current implementation supports:
- Basic property binding `${prop}`
- Deep property binding `${path.to.prop}`
- Array indexing `${map[0].prop}`
- Scope switching with `$data`
- Iteration with `$data` (applied to lists)
- Conditional rendering with `$when`
- Built-in expressions (e.g., `if()`, `json()`)
- Magic variables: `$root`, `$index`

## Additional information

This package is part of the [Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards) ecosystem. 

For more information, please visit the [Main GitHub Repository](https://github.com/freemansoft/Flutter-AdaptiveCards). There you can find details about how this package integrates with the core library, how to contribute, and how to file issues.


## Demonstration

The [Adaptive Card Explorer Editor](https://github.com/freemansoft/Flutter-AdaptiveCards/tree/main/adaptive_explorer) demonstrates the use of templates.
