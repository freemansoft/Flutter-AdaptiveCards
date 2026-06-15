import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Map<String, dynamic> chartOverlayTestCard() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.6',
    'body': [
      {
        'type': 'Chart.VerticalBar',
        'id': 'demoChart',
        'title': 'Baseline title',
        'data': [
          {'x': 'Category A', 'y': 10, 'color': '#FF0000'},
          {'x': 'Category B', 'y': 25, 'color': '#00FF00'},
        ],
      },
    ],
  };
}

void main() {
  testWidgets('patchChartProperties updates chart title via overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      getChartTestWidgetFromMap(
        map: chartOverlayTestCard(),
        title: 'Chart overlay title',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baseline title'), findsOneWidget);
    expect(find.text('Updated title'), findsNothing);

    _cardState(tester).patchChartProperties('demoChart', {
      'title': 'Updated title',
    });
    await tester.pumpAndSettle();

    expect(find.text('Baseline title'), findsNothing);
    expect(find.text('Updated title'), findsOneWidget);
  });

  testWidgets('setChartData replaces chart series via overlay', (tester) async {
    await tester.pumpWidget(
      getChartTestWidgetFromMap(
        map: chartOverlayTestCard(),
        title: 'Chart overlay data',
      ),
    );
    await tester.pumpAndSettle();

    _cardState(tester).setChartData('demoChart', [
      {'x': 'Category A', 'y': 50, 'color': '#FF0000'},
      {'x': 'Category B', 'y': 5, 'color': '#00FF00'},
    ]);
    await tester.pumpAndSettle();

    expect(find.text('50'), findsWidgets);
  });

  testWidgets('setVisibility hides chart element', (tester) async {
    await tester.pumpWidget(
      getChartTestWidgetFromMap(
        map: chartOverlayTestCard(),
        title: 'Chart overlay visibility',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baseline title'), findsOneWidget);

    _cardState(tester).applyUpdates(
      elements: const [
        AdaptiveElementUpdate(id: 'demoChart', isVisible: false),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Baseline title'), findsNothing);
  });
}
