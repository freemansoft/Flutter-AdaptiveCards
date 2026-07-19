import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

/// Regression tests for the Microsoft Teams `roundedCorners` extension on
/// `ColumnSet` and `Column`. See
/// https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format
/// and `AdaptiveColumnSetState.build` / `AdaptiveColumnState.build` in
/// `lib/src/cards/containers/column_set.dart` and `column.dart`. The corner
/// radius is resolved via `ReferenceResolver.resolveCornerRadius()`
/// (HostConfig `cornerRadius`, default 8 — see `FallbackConfigs.cornerRadius`),
/// mirroring the `Container` implementation (see
/// `container_rounded_corners_test.dart`).
void main() {
  Map<String, dynamic> buildColumnMap({
    bool? roundedCorners,
    bool hasItems = true,
  }) => {
    'type': 'Column',
    'id': 'roundedColumn',
    'style': 'accent',
    'width': 'stretch',
    'roundedCorners': ?roundedCorners,
    'items': hasItems
        ? [
            {'type': 'TextBlock', 'text': 'bubble'},
          ]
        : <Map<String, dynamic>>[],
  };

  Map<String, dynamic> buildColumnSetMap({
    required Map<String, dynamic> column,
    bool? roundedCorners,
  }) => {
    'type': 'ColumnSet',
    'id': 'roundedColumnSet',
    'style': 'accent',
    'roundedCorners': ?roundedCorners,
    'columns': [column],
  };

  // Both `AdaptiveColumnSetState.build` and `AdaptiveColumnState.build` build
  // a decorated `Container` (`decoration` is always a non-null `BoxDecoration`
  // instance, even when its fields are all null). A `ColumnSet` nests a
  // `Column`, which itself has its own decorated `Container`, so a plain
  // `find.descendant` predicate for "any decorated Container" is ambiguous —
  // it also matches the nested Column's container when searching from the
  // ColumnSet's key. Walk the element tree depth-first from the element's own
  // key and stop at the *first* decorated Container found (its own), without
  // recursing further into (and past) that match.
  Container findRenderedContainer(
    WidgetTester tester,
    Map<String, dynamic> elementMap,
  ) {
    final key = generateAdaptiveWidgetKey(elementMap);
    final element = tester.element(find.byKey(key));
    Container? result;
    void visit(Element e) {
      if (result != null) return;
      final widget = e.widget;
      if (widget is Container && widget.decoration != null) {
        result = widget;
        return;
      }
      e.visitChildren(visit);
    }

    visit(element);
    expect(
      result,
      isNotNull,
      reason: 'No decorated Container found under key $key',
    );
    return result!;
  }

  group('ColumnSet roundedCorners', () {
    testWidgets(
      'ColumnSet with roundedCorners:true renders a non-null borderRadius '
      'and clips its content',
      (WidgetTester tester) async {
        final columnMap = buildColumnMap();
        final columnSetMap = buildColumnSetMap(
          column: columnMap,
          roundedCorners: true,
        );
        final map = {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [columnSetMap],
        };

        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: map,
            title: 'ColumnSet roundedCorners test',
            listView: false,
          ),
        );
        await tester.pumpAndSettle();

        final rendered = findRenderedContainer(tester, columnSetMap);
        final decoration = rendered.decoration! as BoxDecoration;

        expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
        expect(rendered.clipBehavior, equals(Clip.antiAlias));
      },
    );

    testWidgets(
      'ColumnSet without roundedCorners renders a null borderRadius '
      '(square, opt-in only)',
      (WidgetTester tester) async {
        final columnMap = buildColumnMap();
        final columnSetMap = buildColumnSetMap(column: columnMap);
        final map = {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [columnSetMap],
        };

        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: map,
            title: 'ColumnSet square (default) test',
            listView: false,
          ),
        );
        await tester.pumpAndSettle();

        final rendered = findRenderedContainer(tester, columnSetMap);
        final decoration = rendered.decoration! as BoxDecoration;

        expect(decoration.borderRadius, isNull);
        expect(rendered.clipBehavior, equals(Clip.none));
      },
    );

    testWidgets(
      'ColumnSet with roundedCorners:true resolves the radius from '
      'HostConfig `cornerRadius` rather than a fixed value',
      (WidgetTester tester) async {
        final columnMap = buildColumnMap();
        final columnSetMap = buildColumnSetMap(
          column: columnMap,
          roundedCorners: true,
        );
        final map = {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [columnSetMap],
        };

        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: map,
            title: 'ColumnSet roundedCorners custom HostConfig test',
            listView: false,
            hostConfigs: HostConfigs(
              light: HostConfig.fromJson(<String, dynamic>{
                'cornerRadius': 20,
              }),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final rendered = findRenderedContainer(tester, columnSetMap);
        final decoration = rendered.decoration! as BoxDecoration;

        expect(decoration.borderRadius, equals(BorderRadius.circular(20)));
        expect(rendered.clipBehavior, equals(Clip.antiAlias));
      },
    );
  });

  group('Column roundedCorners', () {
    testWidgets(
      'Column with roundedCorners:true renders a non-null borderRadius '
      'and clips its content',
      (WidgetTester tester) async {
        final columnMap = buildColumnMap(roundedCorners: true);
        final columnSetMap = buildColumnSetMap(column: columnMap);
        final map = {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [columnSetMap],
        };

        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: map,
            title: 'Column roundedCorners test',
            listView: false,
          ),
        );
        await tester.pumpAndSettle();

        final rendered = findRenderedContainer(tester, columnMap);
        final decoration = rendered.decoration! as BoxDecoration;

        expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
        expect(rendered.clipBehavior, equals(Clip.antiAlias));
      },
    );

    testWidgets(
      'Column without roundedCorners renders a null borderRadius '
      '(square, opt-in only)',
      (WidgetTester tester) async {
        final columnMap = buildColumnMap();
        final columnSetMap = buildColumnSetMap(column: columnMap);
        final map = {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [columnSetMap],
        };

        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: map,
            title: 'Column square (default) test',
            listView: false,
          ),
        );
        await tester.pumpAndSettle();

        final rendered = findRenderedContainer(tester, columnMap);
        final decoration = rendered.decoration! as BoxDecoration;

        expect(decoration.borderRadius, isNull);
        expect(rendered.clipBehavior, equals(Clip.none));
      },
    );

    testWidgets(
      'Column with roundedCorners:true resolves the radius from HostConfig '
      '`cornerRadius` rather than a fixed value',
      (WidgetTester tester) async {
        final columnMap = buildColumnMap(roundedCorners: true);
        final columnSetMap = buildColumnSetMap(column: columnMap);
        final map = {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [columnSetMap],
        };

        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: map,
            title: 'Column roundedCorners custom HostConfig test',
            listView: false,
            hostConfigs: HostConfigs(
              light: HostConfig.fromJson(<String, dynamic>{
                'cornerRadius': 20,
              }),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final rendered = findRenderedContainer(tester, columnMap);
        final decoration = rendered.decoration! as BoxDecoration;

        expect(decoration.borderRadius, equals(BorderRadius.circular(20)));
        expect(rendered.clipBehavior, equals(Clip.antiAlias));
      },
    );

    testWidgets(
      'Column with roundedCorners:true and no items still renders a '
      'non-null borderRadius and clips its content',
      (WidgetTester tester) async {
        final columnMap = buildColumnMap(
          roundedCorners: true,
          hasItems: false,
        );
        final columnSetMap = buildColumnSetMap(column: columnMap);
        final map = {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [columnSetMap],
        };

        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: map,
            title: 'Column roundedCorners childless test',
            listView: false,
          ),
        );
        await tester.pumpAndSettle();

        final rendered = findRenderedContainer(tester, columnMap);
        final decoration = rendered.decoration! as BoxDecoration;

        expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
        expect(rendered.clipBehavior, equals(Clip.antiAlias));
      },
    );
  });
}
