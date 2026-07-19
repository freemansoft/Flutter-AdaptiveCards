import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

/// Regression tests for the Microsoft Teams `roundedCorners` extension on
/// `Image`. See
/// https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format
/// and `AdaptiveImageState.build` in `lib/src/cards/elements/image.dart`.
/// The corner radius is resolved via `ReferenceResolver.resolveCornerRadius()`
/// (HostConfig `cornerRadius`, default 8 — see `FallbackConfigs.cornerRadius`).
/// `style: person` (a circle via `ClipOval`) takes precedence: if both
/// `person` and `roundedCorners` are set, the circle wins and no
/// `ClipRRect` is added.
void main() {
  Map<String, dynamic> buildImageMap({
    bool? roundedCorners,
    String? style,
  }) => {
    'type': 'Image',
    'id': 'roundedImage',
    'url': 'https://example.com/x.png',
    'style': ?style,
    'roundedCorners': ?roundedCorners,
  };

  ClipRRect? findClipRRect(
    WidgetTester tester,
    Map<String, dynamic> imageMap,
  ) {
    final key = generateAdaptiveWidgetKey(imageMap);
    final finder = find.descendant(
      of: find.byKey(key),
      matching: find.byType(ClipRRect),
    );
    if (finder.evaluate().isEmpty) {
      return null;
    }
    expect(finder, findsOneWidget);
    return tester.widget<ClipRRect>(finder);
  }

  ClipOval? findClipOval(
    WidgetTester tester,
    Map<String, dynamic> imageMap,
  ) {
    final key = generateAdaptiveWidgetKey(imageMap);
    final finder = find.descendant(
      of: find.byKey(key),
      matching: find.byType(ClipOval),
    );
    if (finder.evaluate().isEmpty) {
      return null;
    }
    expect(finder, findsOneWidget);
    return tester.widget<ClipOval>(finder);
  }

  testWidgets(
    'Image with roundedCorners:true renders a ClipRRect with the default '
    'HostConfig-resolved radius',
    (WidgetTester tester) async {
      final imageMap = buildImageMap(roundedCorners: true);
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [imageMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Image roundedCorners test',
          listView: false,
        ),
      );
      await tester.pump();

      final clipRRect = findClipRRect(tester, imageMap);
      expect(clipRRect, isNotNull);
      expect(clipRRect!.borderRadius, equals(BorderRadius.circular(8)));
    },
  );

  testWidgets(
    'Image with style:person and roundedCorners:true renders a ClipOval '
    'and no ClipRRect (person circle takes precedence)',
    (WidgetTester tester) async {
      final imageMap = buildImageMap(roundedCorners: true, style: 'person');
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [imageMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Image person + roundedCorners test',
          listView: false,
        ),
      );
      await tester.pump();

      expect(findClipOval(tester, imageMap), isNotNull);
      expect(findClipRRect(tester, imageMap), isNull);
    },
  );

  testWidgets(
    'Image without roundedCorners renders no ClipRRect (square, opt-in '
    'only)',
    (WidgetTester tester) async {
      final imageMap = buildImageMap();
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [imageMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Image square (default) test',
          listView: false,
        ),
      );
      await tester.pump();

      expect(findClipRRect(tester, imageMap), isNull);
    },
  );

  testWidgets(
    'Image with roundedCorners:true resolves the radius from HostConfig '
    '`cornerRadius` rather than a fixed value',
    (WidgetTester tester) async {
      final imageMap = buildImageMap(roundedCorners: true);
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [imageMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Image roundedCorners custom HostConfig test',
          listView: false,
          hostConfigs: HostConfigs(
            light: HostConfig.fromJson(<String, dynamic>{'cornerRadius': 20}),
          ),
        ),
      );
      await tester.pump();

      final clipRRect = findClipRRect(tester, imageMap);
      expect(clipRRect, isNotNull);
      expect(clipRRect!.borderRadius, equals(BorderRadius.circular(20)));
    },
  );
}
