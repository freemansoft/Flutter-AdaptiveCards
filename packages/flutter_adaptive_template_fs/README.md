# Flutter Adaptive Template

A template engine for adaptive cards, enabling data binding and dynamic rendering of adaptive card payloads in Flutter.

## Microsoft Adaptive Cards

This project is in no way associated with Microsoft. It is an open source project to create an adaptive card implementation for Flutter.

### Flutter-AdaptiveCards mono repo

Libraries avaiable on pub.dev from this repository include:

| Package / Library                                         | pub.dev                                                                               |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| The core of Adaptive Cards is supported via               | [flutter_adaptive_cards_fs](https://pub.dev/packages/flutter_adaptive_cards_fs)       |
| Supplemental Adaptive Card based charts are supported via | [flutter_adaptive_charts_fs](https://pub.dev/packages/flutter_adaptive_charts_fs)     |
| Templating is supported via the                           | [flutter_adaptive_template_fs](https://pub.dev/packages/flutter_adaptive_template_fs) |

Utility programs available in this repository that are not published to pub.dev include:

| Design time utility                                      | Location                                                                                                |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| The Adaptive Card Explorer Editor                        | ([adaptive_explorer](https://github.com/freemansoft/Flutter-AdaptiveCards/tree/main/adaptive_explorer)) |
| A Widgetbook for demonstrating cards and their features: | ([widgetbook](https://github.com/freemansoft/Flutter-AdaptiveCards/tree/main/widgetbook))               |

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
