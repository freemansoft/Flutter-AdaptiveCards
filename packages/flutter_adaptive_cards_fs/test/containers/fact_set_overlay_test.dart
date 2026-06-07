import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Map<String, dynamic> factSetOverlayTestCard() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'FactSet',
        'id': 'demoFactSet',
        'facts': [
          {'title': 'Fact 1', 'value': 'Value 1'},
          {'title': 'Fact 2', 'value': 'Value 2'},
        ],
      },
    ],
  };
}

void main() {
  testWidgets('setFacts replaces FactSet UI via overlay', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: factSetOverlayTestCard(),
        title: 'FactSet overlay test',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fact 1'), findsOneWidget);
    expect(find.text('Red'), findsNothing);

    _cardState(tester).setFacts('demoFactSet', const [
      Fact(title: 'Red', value: '#FF0000'),
      Fact(title: 'Blue', value: '#0000FF'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Fact 1'), findsNothing);
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('#FF0000'), findsOneWidget);
  });

  testWidgets('clearFacts restores baseline FactSet UI', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: factSetOverlayTestCard(),
        title: 'FactSet clearFacts test',
      ),
    );
    await tester.pumpAndSettle();

    _cardState(tester).setFacts('demoFactSet', const [
      Fact(title: 'Red', value: '#FF0000'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Red'), findsOneWidget);

    _cardState(tester).clearFacts('demoFactSet');
    await tester.pumpAndSettle();

    expect(find.text('Red'), findsNothing);
    expect(find.text('Fact 1'), findsOneWidget);
    expect(find.text('Value 1'), findsOneWidget);
  });
}
