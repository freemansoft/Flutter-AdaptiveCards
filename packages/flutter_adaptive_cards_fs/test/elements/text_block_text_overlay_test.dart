import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder textFinder) {
  return ProviderScope.containerOf(tester.element(textFinder));
}

void main() {
  testWidgets('setText updates TextBlock display via overlay', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'status',
          'text': 'Baseline status',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'TextBlock text overlay',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baseline status'), findsOneWidget);

    final textFinder = find.byWidgetPredicate(
      (widget) => widget is AdaptiveTextBlock && widget.id == 'status',
    );
    final container = _documentContainer(tester, textFinder);

    container.read(adaptiveCardDocumentProvider.notifier).setText(
          'status',
          'Replaced status',
        );
    await tester.pump();

    expect(find.text('Replaced status'), findsOneWidget);
    expect(find.text('Baseline status'), findsNothing);
  });

  testWidgets('clearText restores baseline TextBlock text', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'status',
          'text': 'Baseline status',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'clear TextBlock text overlay',
      ),
    );
    await tester.pumpAndSettle();

    final textFinder = find.byWidgetPredicate(
      (widget) => widget is AdaptiveTextBlock && widget.id == 'status',
    );
    final notifier = _documentContainer(tester, textFinder)
        .read(adaptiveCardDocumentProvider.notifier)
      ..setText('status', 'Replaced status');
    await tester.pump();
    expect(find.text('Replaced status'), findsOneWidget);

    notifier.clearText('status');
    await tester.pump();
    expect(find.text('Baseline status'), findsOneWidget);
    expect(find.text('Replaced status'), findsNothing);
  });

  testWidgets('RawAdaptiveCardState.setText delegates to notifier', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'status',
          'text': 'Baseline status',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'host setText',
      ),
    );
    await tester.pumpAndSettle();

    tester
        .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
        .setText('status', 'From host');
    await tester.pump();

    expect(find.text('From host'), findsOneWidget);
  });

  testWidgets('text overlay survives RawAdaptiveCard rebuild', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'status',
          'text': 'Baseline status',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'overlay survives rebuild',
      ),
    );
    await tester.pumpAndSettle();

    final cardState = tester.state<RawAdaptiveCardState>(
      find.byType(RawAdaptiveCard),
    );
    cardState.setText('status', 'Overlay after rebuild');
    await tester.pump();
    expect(find.text('Overlay after rebuild'), findsOneWidget);

    cardState.rebuild();
    await tester.pump();

    expect(find.text('Overlay after rebuild'), findsOneWidget);
    expect(find.text('Baseline status'), findsNothing);
  });
}
