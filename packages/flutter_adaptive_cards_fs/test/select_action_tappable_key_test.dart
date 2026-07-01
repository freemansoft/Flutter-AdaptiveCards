import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// Regression tests for the `AdaptiveTappable` (`selectAction`) wrapper key.
///
/// Before the fix, the factory minted a fresh UUID on every build, so the
/// wrapper key was non-deterministic: it could not be located by a generated
/// key and the wrapped subtree was rebuilt from scratch each frame. These
/// tests pin the deterministic `{id}_selectAction` format and element reuse.
void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  Widget buildCard(Map<String, dynamic> map) => getTestWidgetFromMap(
    map: map,
    title: 'a test',
    onOpenUrl: (_) {},
    onSubmit: (_) {},
    onExecute: (_) {},
  );

  testWidgets(
    'AdaptiveTappable on a Container selectAction has a deterministic '
    '{id}_selectAction key',
    (tester) async {
      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'Container',
            'id': 'myContainer',
            'selectAction': {
              'type': 'Action.OpenUrl',
              'url': 'https://example.com',
            },
            'items': [
              {'type': 'TextBlock', 'text': 'tap me'},
            ],
          },
        ],
      };

      await tester.pumpWidget(buildCard(map));
      await tester.pumpAndSettle();

      final expectedKey = generateWidgetKeyFromId(
        'myContainer',
        suffix: 'selectAction',
      );
      expect(find.byKey(expectedKey), findsOneWidget);
    },
  );

  testWidgets(
    'AdaptiveTappable state survives a rebuild (deterministic key => element '
    'reuse)',
    (tester) async {
      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'Container',
            'id': 'myContainer',
            'selectAction': {
              'type': 'Action.OpenUrl',
              'url': 'https://example.com',
            },
            'items': [
              {'type': 'TextBlock', 'text': 'tap me'},
            ],
          },
        ],
      };

      await tester.pumpWidget(buildCard(map));
      await tester.pumpAndSettle();

      final key = generateWidgetKeyFromId(
        'myContainer',
        suffix: 'selectAction',
      );
      final stateBefore = tester.state<AdaptiveTappableState>(find.byKey(key));

      // Force a rebuild of the card subtree via a width change (drives the
      // responsive LayoutBuilder + container rebuilds).
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);
      await tester.pumpAndSettle();

      final stateAfter = tester.state<AdaptiveTappableState>(find.byKey(key));

      // Same State instance => Flutter reused the element across the rebuild,
      // which is only possible when the key is stable.
      expect(identical(stateBefore, stateAfter), isTrue);
    },
  );

  testWidgets(
    'AdaptiveTappable on a table cell selectAction uses the centralized cell '
    'key seed',
    (tester) async {
      final tableMap = <String, dynamic>{
        'type': 'Table',
        'id': 'myTable',
        'columns': [
          {'width': 1},
        ],
        'rows': [
          {
            'type': 'TableRow',
            'cells': [
              {
                'type': 'TableCell',
                'selectAction': {
                  'type': 'Action.OpenUrl',
                  'url': 'https://example.com',
                },
                'items': [
                  {'type': 'TextBlock', 'text': 'cell'},
                ],
              },
            ],
          },
        ],
      };

      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [tableMap],
      };

      await tester.pumpWidget(buildCard(map));
      await tester.pumpAndSettle();

      // The cell wrapper is seeded from generateTableCellKey(tableKey, 0, 0),
      // where tableKey is the table widget's {id}_adaptive key value.
      final tableKey = generateAdaptiveWidgetKey(tableMap).value;
      final cellSeed = generateTableCellKey(tableKey, 0, 0).value;
      final expectedKey = generateWidgetKeyFromId(
        cellSeed,
        suffix: 'selectAction',
      );

      expect(find.byKey(expectedKey), findsOneWidget);
    },
  );
}
