import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

void main() {
  testWidgets('initData ignores unknown ids without creating overlays', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'known',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'initData unknown id',
        initData: const {'unknownId': 'value'},
      ),
    );
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(generateWidgetKey(textMap))),
    );
    final doc = container.read(adaptiveCardDocumentProvider);

    expect(doc.overlaysById.containsKey('unknownId'), isFalse);
  });

  testWidgets('initInput then applyUpdates enrich without conflict', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'email',
        },
        {
          'type': 'TextBlock',
          'id': 'status',
          'text': 'Loading',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'initInput applyUpdates'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).initInput({'email': 'user@example.com'});
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdatesFromMap({
      'status': {'text': 'Ready'},
    });
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(generateWidgetKey(textMap))),
    );

    expect(
      container.read(resolvedElementProvider('email'))?['value'],
      'user@example.com',
    );
    expect(
      container.read(resolvedElementProvider('status'))?['text'],
      'Ready',
    );
  });
}
