import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

const Map<String, dynamic> _submitActionWithIcon = {
  'type': 'Action.Submit',
  'id': 'submit',
  'title': 'Send',
  'iconUrl': 'https://example.com/old.png',
};

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Finder _submitActionFinder() {
  return find.byKey(generateAdaptiveWidgetKey(_submitActionWithIcon));
}

Finder _submitButtonFinder() {
  return find.descendant(
    of: _submitActionFinder(),
    matching: find.byType(ElevatedButton),
  );
}

NetworkImage _actionIconNetworkImage(WidgetTester tester) {
  final imageFinder = find.descendant(
    of: _submitActionFinder(),
    matching: find.byType(Image),
  );
  final image = tester.widget<Image>(imageFinder);
  return image.image as NetworkImage;
}

void main() {
  testWidgets('applyUpdates updates action iconUrl in UI', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Form',
        },
      ],
      'actions': [_submitActionWithIcon],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'action iconUrl overlay'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Send'), findsOneWidget);
    expect(_actionIconNetworkImage(tester).url, 'https://example.com/old.png');

    _cardState(tester).applyUpdates(
      actions: const [
        AdaptiveActionUpdate(
          id: 'submit',
          iconUrl: 'https://example.com/new.png',
        ),
      ],
    );
    await tester.pump();

    expect(_submitButtonFinder(), findsOneWidget);
    expect(_actionIconNetworkImage(tester).url, 'https://example.com/new.png');

    final container = ProviderScope.containerOf(
      tester.element(_submitButtonFinder()),
    );
    expect(
      container.read(resolvedActionProvider('submit'))?['iconUrl'],
      'https://example.com/new.png',
    );
  });

  testWidgets('applyUpdates clearIconUrl restores baseline iconUrl', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Form',
        },
      ],
      'actions': [_submitActionWithIcon],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'action clear iconUrl overlay'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdates(
      actions: const [
        AdaptiveActionUpdate(
          id: 'submit',
          iconUrl: 'https://example.com/new.png',
        ),
      ],
    );
    await tester.pump();
    expect(_actionIconNetworkImage(tester).url, 'https://example.com/new.png');

    _cardState(tester).applyUpdates(
      actions: const [
        AdaptiveActionUpdate(
          id: 'submit',
          clearIconUrl: true,
        ),
      ],
    );
    await tester.pump();

    expect(_submitButtonFinder(), findsOneWidget);
    expect(_actionIconNetworkImage(tester).url, 'https://example.com/old.png');

    final container = ProviderScope.containerOf(
      tester.element(_submitButtonFinder()),
    );
    expect(
      container.read(resolvedActionProvider('submit'))?['iconUrl'],
      'https://example.com/old.png',
    );
  });
}
