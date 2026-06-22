import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/containers/image_set.dart';
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
  testWidgets('isVisible: false in JSON hides ImageSet', (
    WidgetTester tester,
  ) async {
    final map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'ImageSet',
          'id': 'is1',
          'isVisible': false,
          'images': [
            {'type': 'Image', 'url': 'https://example.com/img.png'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'imageset visibility static'),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is AdaptiveImageSet && w.id == 'is1',
    );
    expect(_visibilityOf(tester, finder).visible, isFalse);
  });

  testWidgets('setVisibility toggles ImageSet visibility', (
    WidgetTester tester,
  ) async {
    final map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'ImageSet',
          'id': 'is1',
          'images': [
            {'type': 'Image', 'url': 'https://example.com/img.png'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'imageset visibility overlay'),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is AdaptiveImageSet && w.id == 'is1',
    );
    expect(_visibilityOf(tester, finder).visible, isTrue);

    final notifier = ProviderScope.containerOf(
      tester.element(finder),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('is1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(_visibilityOf(tester, finder).visible, isFalse);

    await setVis(visible: true);
    expect(_visibilityOf(tester, finder).visible, isTrue);
  });
}
