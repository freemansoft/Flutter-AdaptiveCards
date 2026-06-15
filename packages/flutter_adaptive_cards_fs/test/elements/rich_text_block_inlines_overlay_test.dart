import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Map<String, dynamic> richTextBlockOverlayTestCard() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'RichTextBlock',
        'id': 'demoRichText',
        'inlines': [
          {'type': 'TextRun', 'text': 'Baseline run'},
        ],
      },
    ],
  };
}

void main() {
  testWidgets('setInlines replaces RichTextBlock content via overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: richTextBlockOverlayTestCard(),
        title: 'RichTextBlock inlines overlay',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baseline run'), findsOneWidget);
    expect(find.text('Updated run'), findsNothing);

    _cardState(tester).setInlines('demoRichText', [
      {'type': 'TextRun', 'text': 'Updated run'},
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Baseline run'), findsNothing);
    expect(find.text('Updated run'), findsOneWidget);
  });

  testWidgets('clearInlines restores baseline RichTextBlock inlines', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: richTextBlockOverlayTestCard(),
        title: 'RichTextBlock clearInlines',
      ),
    );
    await tester.pumpAndSettle();

    _cardState(tester).setInlines('demoRichText', [
      {'type': 'TextRun', 'text': 'Overlay run'},
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Overlay run'), findsOneWidget);

    _cardState(tester).clearInlines('demoRichText');
    await tester.pumpAndSettle();

    expect(find.text('Overlay run'), findsNothing);
    expect(find.text('Baseline run'), findsOneWidget);
  });
}
