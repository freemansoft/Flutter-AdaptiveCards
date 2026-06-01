import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/inherited_reference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('InheritedReferenceResolver rawCardScopeOf exposes outer services', (
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

    final scope = InheritedReferenceResolver.rawCardScopeOf(textState.context);

    expect(scope.rawAdaptiveCardState, same(rawState));
    expect(textState.rawRootCardWidgetState, same(rawState));
    expect(scope.resolver, isNotNull);
    expect(scope.resolver.cardTypeRegistry, isNotNull);
    expect(scope.resolver.actionTypeRegistry, isNotNull);
  });

  testWidgets(
    'InheritedReferenceResolver elementScopeOf exposes per-card element state',
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

      final elementScope = InheritedReferenceResolver.elementScopeOf(
        textState.context,
      );

      expect(elementScope.adaptiveCardElementState, same(cardElementState));
      expect(textState.adaptiveCardElementState, same(cardElementState));
    },
  );
}
