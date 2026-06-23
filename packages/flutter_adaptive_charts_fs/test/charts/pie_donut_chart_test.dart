import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

/// Reads the single rendered [PieChart]'s data from the widget tree.
PieChartData _pieData(WidgetTester tester) =>
    tester.widget<PieChart>(find.byType(PieChart)).data;

void main() {
  group('Chart.Pie', () {
    testWidgets('renders title, legend, and one section per data point', (
      tester,
    ) async {
      await tester.pumpWidget(
        getChartTestWidgetFromString(
          jsonString: '''
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "body": [
    {
      "type": "Chart.Pie",
      "title": "Sales",
      "showLegend": true,
      "data": [
        { "legend": "Alpha", "value": 30, "color": "#FF0000" },
        { "legend": "Beta", "value": 70, "color": "#00FF00" }
      ]
    }
  ]
}
''',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sales'), findsOneWidget);
      // Legend labels are rendered by ChartChrome when showLegend is true.
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      final data = _pieData(tester);
      expect(data.sections.length, 2);
      expect(data.sections.map((s) => s.value), [30.0, 70.0]);
      // With a legend shown, slice titles are blanked in favour of the legend.
      expect(data.sections.every((s) => s.title.isEmpty), isTrue);
    });

    testWidgets('without legend uses slice labels as section titles', (
      tester,
    ) async {
      await tester.pumpWidget(
        getChartTestWidgetFromString(
          jsonString: '''
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "body": [
    {
      "type": "Chart.Pie",
      "data": [
        { "title": "One", "value": 1 },
        { "title": "Two", "value": 2 }
      ]
    }
  ]
}
''',
        ),
      );
      await tester.pumpAndSettle();

      final data = _pieData(tester);
      expect(data.sections.map((s) => s.title), ['One', 'Two']);
    });

    testWidgets('reads y/x fallbacks when value/legend are absent', (
      tester,
    ) async {
      await tester.pumpWidget(
        getChartTestWidgetFromString(
          jsonString: '''
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "body": [
    {
      "type": "Chart.Pie",
      "data": [
        { "x": "Q1", "y": 5 }
      ]
    }
  ]
}
''',
        ),
      );
      await tester.pumpAndSettle();

      final data = _pieData(tester);
      expect(data.sections.single.value, 5.0);
      expect(data.sections.single.title, 'Q1');
    });

    testWidgets('renders without crashing when data is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        getChartTestWidgetFromString(
          jsonString: '''
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "body": [
    { "type": "Chart.Pie", "title": "Empty" }
  ]
}
''',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
      expect(_pieData(tester).sections, isEmpty);
    });
  });

  group('Chart.Donut', () {
    testWidgets('renders a hollow center (centerSpaceRadius > 0)', (
      tester,
    ) async {
      await tester.pumpWidget(
        getChartTestWidgetFromString(
          jsonString: '''
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "body": [
    {
      "type": "Chart.Donut",
      "data": [
        { "legend": "A", "value": 40 },
        { "legend": "B", "value": 60 }
      ]
    }
  ]
}
''',
        ),
      );
      await tester.pumpAndSettle();

      final data = _pieData(tester);
      expect(data.sections.length, 2);
      expect(data.centerSpaceRadius, greaterThan(0));
    });
  });
}
