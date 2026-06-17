import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/icon.dart';
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

void main() {
  testWidgets('isVisible: false in JSON hides Icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.6',
          'body': [
            {
              'type': 'Icon',
              'id': 'icon1',
              'isVisible': false,
              'name': 'Star',
            },
          ],
        },
        title: 'icon visibility static',
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is AdaptiveIcon && w.id == 'icon1',
    );
    expect(_visibilityOf(tester, finder).visible, isFalse);
  });

  testWidgets('setVisibility toggles Icon visibility', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.6',
          'body': [
            {
              'type': 'Icon',
              'id': 'icon1',
              'name': 'Star',
            },
          ],
        },
        title: 'icon visibility overlay',
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is AdaptiveIcon && w.id == 'icon1',
    );
    expect(_visibilityOf(tester, finder).visible, isTrue);

    final notifier = ProviderScope.containerOf(
      tester.element(finder),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('icon1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(_visibilityOf(tester, finder).visible, isFalse);

    await setVis(visible: true);
    expect(_visibilityOf(tester, finder).visible, isTrue);
  });
}
