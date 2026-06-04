import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

void main() {
  testWidgets('applyUpdates updates input label and placeholder in UI', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'name',
          'label': 'Name',
          'placeholder': 'Enter name',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'label placeholder overlay'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);

    _cardState(tester).applyUpdates(
      elements: const [
        AdaptiveElementUpdate(
          id: 'name',
          label: 'Full name',
          placeholder: 'Type here',
        ),
      ],
    );
    await tester.pump();

    expect(find.text('Full name'), findsOneWidget);

    final textMap = map['body'][0] as Map<String, dynamic>;
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(generateWidgetKey(textMap))),
    );
    expect(
      container.read(resolvedElementProvider('name'))?['label'],
      'Full name',
    );
    expect(
      container.read(resolvedElementProvider('name'))?['placeholder'],
      'Type here',
    );
  });

  testWidgets('resetAllInputs restores baseline label and placeholder', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'name',
          'label': 'Name',
          'placeholder': 'Enter name',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'reset label placeholder'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdates(
      elements: const [
        AdaptiveElementUpdate(
          id: 'name',
          label: 'Full name',
          placeholder: 'Type here',
        ),
      ],
    );
    await tester.pump();
    expect(find.text('Full name'), findsOneWidget);

    _cardState(tester).documentContainer!
        .read(adaptiveCardDocumentProvider.notifier)
        .resetAllInputs();
    await tester.pump();

    expect(find.text('Name'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(generateWidgetKey(map['body'][0]))),
    );
    expect(
      container.read(resolvedElementProvider('name'))?['label'],
      'Name',
    );
    expect(
      container.read(resolvedElementProvider('name'))?['placeholder'],
      'Enter name',
    );
  });
}
