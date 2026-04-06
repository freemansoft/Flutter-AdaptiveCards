# Flutter Adaptive Charts

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

Please refer to the examples in the main repository for creating AdaptiveCards JSON that matches the charts 1.6 spec.

## Additional information

For more information, please visit the [Flutter-AdaptiveCards GitHub Repository](https://github.com/freemansoft/Flutter-AdaptiveCards).
There you can find more information about how this package integrates with the rest of the Adaptive Cards environment, how to contribute, and how to file issues.
