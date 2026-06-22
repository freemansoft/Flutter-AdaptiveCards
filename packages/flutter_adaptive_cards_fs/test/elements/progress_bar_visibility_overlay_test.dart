import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/progress_bar.dart';
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
  testWidgets('isVisible: false in JSON hides ProgressBar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.6',
          'body': [
            {
              'type': 'ProgressBar',
              'id': 'pb1',
              'isVisible': false,
              'value': 50,
            },
          ],
        },
        title: 'progress bar visibility static',
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is AdaptiveProgressBar && w.id == 'pb1',
    );
    expect(_visibilityOf(tester, finder).visible, isFalse);
  });

  testWidgets('setVisibility toggles ProgressBar visibility', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.6',
          'body': [
            {
              'type': 'ProgressBar',
              'id': 'pb1',
              'value': 50,
            },
          ],
        },
        title: 'progress bar visibility overlay',
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is AdaptiveProgressBar && w.id == 'pb1',
    );
    expect(_visibilityOf(tester, finder).visible, isTrue);

    final notifier = ProviderScope.containerOf(
      tester.element(finder),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('pb1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(_visibilityOf(tester, finder).visible, isFalse);

    await setVis(visible: true);
    expect(_visibilityOf(tester, finder).visible, isTrue);
  });
}
