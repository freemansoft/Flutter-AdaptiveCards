import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

/// Regression tests for the Microsoft Teams `roundedCorners` extension on
/// `Container`. See
/// https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format
/// and `AdaptiveContainerState.build` in
/// `lib/src/cards/containers/container.dart`. The corner radius is resolved
/// via `ReferenceResolver.resolveCornerRadius()` (HostConfig `cornerRadius`,
/// default 8 — see `FallbackConfigs.cornerRadius`).
void main() {
  Map<String, dynamic> buildContainerMap({required bool roundedCorners}) => {
    'type': 'Container',
    'id': 'roundedContainer',
    'style': 'accent',
    'roundedCorners': roundedCorners,
    'items': [
      {'type': 'TextBlock', 'text': 'bubble'},
    ],
  };

  Map<String, dynamic> buildContainerMapWithoutFlag() => {
    'type': 'Container',
    'id': 'roundedContainer',
    'style': 'accent',
    'items': [
      {'type': 'TextBlock', 'text': 'bubble'},
    ],
  };

  // `AdaptiveContainerState.build` wraps its decorated `Container` inside
  // `SeparatorElement`, which itself builds a plain (undecorated) `Container`
  // for top spacing. Filter on `decoration != null` to land on the one this
  // test cares about rather than that spacing wrapper.
  Container findRenderedContainer(
    WidgetTester tester,
    Map<String, dynamic> containerMap,
  ) {
    final key = generateAdaptiveWidgetKey(containerMap);
    final containerFinder = find.descendant(
      of: find.byKey(key),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration != null,
      ),
    );
    expect(containerFinder, findsOneWidget);
    return tester.widget<Container>(containerFinder);
  }

  testWidgets(
    'Container with roundedCorners:true renders a non-null borderRadius '
    'and clips its content',
    (WidgetTester tester) async {
      final containerMap = buildContainerMap(roundedCorners: true);
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [containerMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Container roundedCorners test',
          listView: false,
        ),
      );
      await tester.pumpAndSettle();

      final rendered = findRenderedContainer(tester, containerMap);
      final decoration = rendered.decoration! as BoxDecoration;

      expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
      expect(rendered.clipBehavior, equals(Clip.antiAlias));
    },
  );

  testWidgets(
    'Container without roundedCorners renders a null borderRadius '
    '(square, opt-in only)',
    (WidgetTester tester) async {
      final containerMap = buildContainerMapWithoutFlag();
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [containerMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Container square (default) test',
          listView: false,
        ),
      );
      await tester.pumpAndSettle();

      final rendered = findRenderedContainer(tester, containerMap);
      final decoration = rendered.decoration! as BoxDecoration;

      expect(decoration.borderRadius, isNull);
      expect(rendered.clipBehavior, equals(Clip.none));
    },
  );

  testWidgets(
    'Container with roundedCorners:true resolves the radius from HostConfig '
    '`cornerRadius` rather than a fixed value',
    (WidgetTester tester) async {
      final containerMap = buildContainerMap(roundedCorners: true);
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [containerMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Container roundedCorners custom HostConfig test',
          listView: false,
          hostConfigs: HostConfigs(
            light: HostConfig.fromJson(<String, dynamic>{'cornerRadius': 20}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rendered = findRenderedContainer(tester, containerMap);
      final decoration = rendered.decoration! as BoxDecoration;

      expect(decoration.borderRadius, equals(BorderRadius.circular(20)));
      expect(rendered.clipBehavior, equals(Clip.antiAlias));
    },
  );
}
