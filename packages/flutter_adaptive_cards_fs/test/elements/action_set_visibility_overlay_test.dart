import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/action_set.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Visibility _visibilityOf(WidgetTester tester, Finder widgetFinder) =>
    tester.widget<Visibility>(
      find
          .descendant(of: widgetFinder, matching: find.byType(Visibility))
          .first,
    );

Map<String, dynamic> _actionSetCard({bool? isVisible}) => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [
    {
      'type': 'ActionSet',
      'id': 'as1',
      if (isVisible != null) 'isVisible': isVisible,
      'actions': [
        {
          'type': 'Action.OpenUrl',
          'title': 'Go',
          'url': 'https://example.com',
        },
      ],
    },
  ],
};

void main() {
  testWidgets('isVisible: false in JSON hides ActionSet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _actionSetCard(isVisible: false),
        title: 'actionset visibility static',
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is ActionSet && w.id == 'as1',
    );
    expect(_visibilityOf(tester, finder).visible, isFalse);
  });

  testWidgets('setVisibility toggles ActionSet visibility', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _actionSetCard(),
        title: 'actionset visibility overlay',
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is ActionSet && w.id == 'as1',
    );
    expect(_visibilityOf(tester, finder).visible, isTrue);

    final notifier = ProviderScope.containerOf(
      tester.element(finder),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('as1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(_visibilityOf(tester, finder).visible, isFalse);

    await setVis(visible: true);
    expect(_visibilityOf(tester, finder).visible, isTrue);
  });
}
