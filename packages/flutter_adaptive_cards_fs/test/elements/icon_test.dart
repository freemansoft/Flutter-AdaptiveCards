import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('AdaptiveIcon renders Calendar with Medium size and Accent color', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [
            {
              'type': 'Icon',
              'id': 'calendarIcon',
              'name': 'Calendar',
              'size': 'Medium',
              'color': 'Accent',
              'style': 'Filled',
            },
          ],
        },
        title: 'Icon test',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Icon), findsOneWidget);

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.calendar_today);
    expect(icon.size, 20);
  });

  testWidgets('AdaptiveIcon Regular style uses outlined variant', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [
            {
              'type': 'Icon',
              'id': 'mailIcon',
              'name': 'Mail',
              'style': 'Regular',
            },
          ],
        },
        title: 'Icon regular style',
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.mail_outlined);
  });

  testWidgets('AdaptiveIcon unknown name falls back to help_outline', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [
            {
              'type': 'Icon',
              'id': 'unknownIcon',
              'name': 'NotARealFluentIcon',
            },
          ],
        },
        title: 'Icon unknown name',
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.help_outline);
  });

  testWidgets('AdaptiveIcon selectAction (OpenUrl) fires handler', (
    tester,
  ) async {
    var opened = false;

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [
            {
              'type': 'Icon',
              'id': 'tappableIcon',
              'name': 'Calendar',
              'selectAction': {
                'type': 'Action.OpenUrl',
                'url': 'https://example.com/icon',
              },
            },
          ],
        },
        title: 'Icon selectAction',
        onOpenUrl: (_) => opened = true,
      ),
    );
    await tester.pumpAndSettle();

    final iconInk = find.ancestor(
      of: find.byType(Icon),
      matching: find.byType(InkWell),
    );
    expect(iconInk, findsOneWidget);

    await tester.tap(iconInk);
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });
}
