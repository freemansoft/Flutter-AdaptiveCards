import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

void main() {
  testWidgets('applyUpdates cascades country to state ChoiceSet', (
    WidgetTester tester,
  ) async {
    final map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'country',
          'style': 'compact',
          'choices': [
            {'title': 'US', 'value': 'US'},
            {'title': 'CA', 'value': 'CA'},
          ],
        },
        {
          'type': 'Input.ChoiceSet',
          'id': 'state',
          'style': 'expanded',
          'choices': [
            {'title': 'Placeholder', 'value': ''},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'cascade choice set'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdates(
      elements: [
        const AdaptiveElementUpdate(
          id: 'state',
          choices: [
            Choice(title: 'California', value: 'CA'),
            Choice(title: 'Texas', value: 'TX'),
          ],
          clearValue: true,
          clearError: true,
        ),
      ],
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AdaptiveChoiceSet).first),
    );
    final resolved = container.read(resolvedElementProvider('state'));
    expect(resolved?['choices'], [
      {'title': 'California', 'value': 'CA'},
      {'title': 'Texas', 'value': 'TX'},
    ]);
    expect(resolved?['value'], isNull);

    expect(find.text('California'), findsOneWidget);
    expect(find.text('Texas'), findsOneWidget);
  });
}
