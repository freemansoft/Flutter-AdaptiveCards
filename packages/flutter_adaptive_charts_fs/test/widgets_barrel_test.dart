import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_widgets_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registry builders produce the exported widget types', () {
    // Ties the barrel to the registry: fails if a `show` clause exports the
    // wrong class, a class is renamed, or a builder changes what it returns.
    // The import line is itself a compile-time guard on the barrel's surface.
    // Calling a builder only constructs the widget -- no BuildContext, no
    // pumping needed.
    final builders = CardChartsRegistry.additionalChartElements;

    expect(
      builders['Chart.Pie']!({'type': 'Chart.Pie'}),
      isA<AdaptivePieChart>(),
    );
    expect(
      builders['Chart.Donut']!({'type': 'Chart.Donut'}),
      isA<AdaptivePieChart>(),
    );
    expect(
      builders['Chart.VerticalBar']!({'type': 'Chart.VerticalBar'}),
      isA<AdaptiveBarChart>(),
    );
    expect(
      builders['Chart.HorizontalBar']!({'type': 'Chart.HorizontalBar'}),
      isA<AdaptiveBarChart>(),
    );
    expect(
      builders['Chart.Line']!({'type': 'Chart.Line'}),
      isA<AdaptiveLineChart>(),
    );
    expect(
      builders['Chart.Gauge']!({'type': 'Chart.Gauge'}),
      isA<AdaptiveGaugeChart>(),
    );
  });

  test('BarChartType covers the four bar layouts', () {
    // BarChartType is exported because AdaptiveBarChart's constructor
    // requires it; assert the values a caller would pass.
    expect(BarChartType.values, hasLength(4));
  });
}
