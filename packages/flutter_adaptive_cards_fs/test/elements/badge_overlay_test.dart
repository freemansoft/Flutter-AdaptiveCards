import 'package:flutter_adaptive_cards_fs/src/cards/elements/badge.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder badgeFinder) {
  return ProviderScope.containerOf(tester.element(badgeFinder));
}

void main() {
  testWidgets('setText updates Badge display via overlay', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Badge',
          'id': 'badge1',
          'text': 'Baseline badge',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'Badge text overlay',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baseline badge'), findsOneWidget);

    final badgeFinder = find.byWidgetPredicate(
      (widget) => widget is AdaptiveBadge && widget.id == 'badge1',
    );
    final container = _documentContainer(tester, badgeFinder);

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setText(
          'badge1',
          'Updated',
        );
    await tester.pump();

    expect(find.text('Updated'), findsOneWidget);
    expect(find.text('Baseline badge'), findsNothing);
  });

  testWidgets('clearText restores baseline Badge text', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Badge',
          'id': 'badge1',
          'text': 'Baseline badge',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'clear Badge text overlay',
      ),
    );
    await tester.pumpAndSettle();

    final badgeFinder = find.byWidgetPredicate(
      (widget) => widget is AdaptiveBadge && widget.id == 'badge1',
    );
    final notifier = _documentContainer(tester, badgeFinder).read(
      adaptiveCardDocumentProvider.notifier,
    )..setText('badge1', 'Updated');
    await tester.pump();
    expect(find.text('Updated'), findsOneWidget);

    notifier.clearText('badge1');
    await tester.pump();
    expect(find.text('Baseline badge'), findsOneWidget);
    expect(find.text('Updated'), findsNothing);
  });

  testWidgets('applyUpdates patches Badge text overlay', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Badge',
          'id': 'badge1',
          'text': 'Baseline badge',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'Badge applyUpdates text overlay',
      ),
    );
    await tester.pumpAndSettle();

    tester
        .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
        .applyUpdates(
          elements: const [
            AdaptiveElementUpdate(id: 'badge1', text: 'From applyUpdates'),
          ],
        );
    await tester.pump();

    expect(find.text('From applyUpdates'), findsOneWidget);
    expect(find.text('Baseline badge'), findsNothing);
  });
}
