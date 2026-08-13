/// Direct access to the `Chart.*` widget classes.
///
/// Import this **in addition to** `flutter_adaptive_charts_fs.dart` when you
/// need to name a chart widget type rather than just register it — most often
/// in a host's widget tests, where `find.byType(AdaptivePieChart)` is a more
/// direct assertion than matching the chart's rendered title text. It also
/// lets a host embed a chart widget outside a card.
///
/// Rendering a chart inside a card needs none of this: register
/// `CardChartsRegistry.additionalChartElements` from the main barrel and the
/// renderer builds these widgets for you.
///
/// Kept separate from `flutter_adaptive_charts_fs.dart` so the default import
/// stays narrow — the same split as `flutter_adaptive_cards_fs.dart` versus
/// `flutter_adaptive_cards_extend_fs.dart`. The `show` clauses are deliberate:
/// the chart chrome (`ChartChrome`, `GaugePainter`, …) stays private.
library;

export 'package:flutter_adaptive_charts_fs/src/charts/bar_chart.dart'
    show AdaptiveBarChart, AdaptiveBarChartState, BarChartType;
export 'package:flutter_adaptive_charts_fs/src/charts/gauge_chart.dart'
    show AdaptiveGaugeChart, AdaptiveGaugeChartState;
export 'package:flutter_adaptive_charts_fs/src/charts/line_chart.dart'
    show AdaptiveLineChart, AdaptiveLineChartState;
export 'package:flutter_adaptive_charts_fs/src/charts/pie_donut_chart.dart'
    show AdaptivePieChart, AdaptivePieChartState;
