import 'package:flutter_adaptive_cards_fs/src/cards/elements/accordion.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _accordionCard({bool? isVisible}) => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [
    {
      'type': 'Accordion',
      'id': 'acc1',
      if (isVisible != null) 'isVisible': isVisible,
      'items': [
        {
          'title': 'Section Title',
          'items': [
            {'type': 'TextBlock', 'text': 'Accordion body'},
          ],
        },
      ],
    },
  ],
};

void main() {
  testWidgets('isVisible: false in JSON hides Accordion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _accordionCard(isVisible: false),
        title: 'accordion visibility static',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Section Title'), findsNothing);
  });

  testWidgets('setVisibility toggles Accordion visibility', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _accordionCard(),
        title: 'accordion visibility overlay',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Section Title'), findsOneWidget);

    final notifier = ProviderScope.containerOf(
      tester.element(
        find.byWidgetPredicate(
          (w) => w is AdaptiveAccordion && w.id == 'acc1',
        ),
      ),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('acc1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(find.text('Section Title'), findsNothing);

    await setVis(visible: true);
    expect(find.text('Section Title'), findsOneWidget);
  });
}
