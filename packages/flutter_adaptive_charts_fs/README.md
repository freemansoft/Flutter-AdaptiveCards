# Flutter Adaptive Charts

A set of adaptive cards that are charts based on the 1.6 spec. Packaged as a separate library to remove the dependency on the charting library from the main adaptive cards library.

## Features

- `Chart.VerticalBar` : Vertical Bar Charts
- `chart.HorizontalBar` : Horizontal Bar Charts
- `Chart.Donutz` : Donut Chart
- `Chart.Pie` : Pie Chart
- `Chart.Line` : Line Charts

## Not tested

- `Chart.VerticalBar.Grouped` : Vertical Grouped Bar Charts
- `Chart.HorizontalBar.Stacked` : Horizontal Stacked Bar Charts

## Not Implemented

- `Chart.Gauge` : Gauge Charts - no clear way to implement in fl_chart

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

This package is part of the [Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards) ecosystem.

For more information, please visit the [Main GitHub Repository](https://github.com/freemansoft/Flutter-AdaptiveCards). There you can find details about how this package integrates with the core library, how to contribute, and how to file issues.
