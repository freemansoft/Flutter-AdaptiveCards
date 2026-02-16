A set of adaptive cards that are charts based on the 1.6 spec. Packaged as a separate library to remove the dependency on the charting library from the main adaptive cards library.

## Features

- Pie and Donut Charts
- Bar Charts (Vertical, Horizontal, Stacked, Grouped)
- Line Charts
- Gauge Charts

## Getting started

Pass in the additional charting elements to Registry on start up

```dart
  const AdaptiveCard({
    super.key,
    required this.adaptiveCardContentProvider,
    this.placeholder,
    this.cardRegistry = const CardTypeRegistry(
      addedElements: additionalChartElements,
    ),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    required this.hostConfigs,
  });
```

## Usage

TODO: Create AdaptiveCards JSON that matches the charts 1.6 spec.

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
