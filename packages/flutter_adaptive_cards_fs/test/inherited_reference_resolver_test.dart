import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('ProviderScope exposes raw-card scoped services', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': [
        <String, dynamic>{
          'type': 'TextBlock',
          'id': 'title',
          'text': 'Hello',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'Inherited scope'),
    );
    await tester.pumpAndSettle();

    final rawState = tester.state<RawAdaptiveCardState>(
      find.byType(RawAdaptiveCard),
    );
    final textState = tester.state<AdaptiveTextBlockState>(
      find.byType(AdaptiveTextBlock),
    );

    final container = ProviderScope.containerOf(textState.context);

    expect(container.read(rawAdaptiveCardStateProvider), same(rawState));
    expect(textState.rawRootCardWidgetState, same(rawState));
    final resolver = container.read(styleReferenceResolverProvider);
    expect(resolver, isNotNull);
    expect(container.read(cardTypeRegistryProvider), isNotNull);
    expect(container.read(actionTypeRegistryProvider), isNotNull);
  });

  testWidgets(
    'ProviderScope exposes per-card element state',
    (WidgetTester tester) async {
      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'version': '1.4',
        'body': [
          <String, dynamic>{
            'type': 'TextBlock',
            'id': 'title',
            'text': 'Hello',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'Element scope'),
      );
      await tester.pumpAndSettle();

      final cardElementState = tester.state<AdaptiveCardElementState>(
        find.byType(AdaptiveCardElement),
      );
      final textState = tester.state<AdaptiveTextBlockState>(
        find.byType(AdaptiveTextBlock),
      );

      final container = ProviderScope.containerOf(textState.context);

      expect(
        container.read(adaptiveCardElementStateProvider),
        same(cardElementState),
      );
      expect(textState.adaptiveCardElementState, same(cardElementState));
    },
  );
}
