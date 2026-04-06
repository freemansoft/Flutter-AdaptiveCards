import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  setUp(() {
    // Prevent image network calls from failing during tests
    HttpOverrides.global = MyTestHttpOverrides();
  });

  Widget buildCard(
    Map<String, dynamic> map, {
    required Function(String) onOpenUrl,
    required Function(Map) onSubmit,
  }) {
    return getTestWidgetFromMap(
      map: map,
      title: 'a test',
      onOpenUrl: onOpenUrl,
      onSubmit: onSubmit,
    );
  }

  testWidgets('AdaptiveCardElement selectAction (OpenUrl) fires handler', (
    tester,
  ) async {
    bool opened = false;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Card body',
        },
      ],
      'selectAction': {
        'type': 'Action.OpenUrl',
        'url': 'https://example.com/card',
      },
    };

    await tester.pumpWidget(
      buildCard(map, onOpenUrl: (url) => opened = true, onSubmit: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Card body'), findsOneWidget);

    await tester.tap(find.text('Card body'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('AdaptiveContainer selectAction (OpenUrl) fires handler', (
    tester,
  ) async {
    bool opened = false;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'Container',
          'selectAction': {
            'type': 'Action.OpenUrl',
            'url': 'https://example.com/container',
          },
          'items': [
            {'type': 'TextBlock', 'text': 'Tap container'},
            {'type': 'TextBlock', 'text': 'More content'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      buildCard(map, onOpenUrl: (url) => opened = true, onSubmit: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tap container'), findsOneWidget);

    await tester.tap(find.text('Tap container'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('AdaptiveColumn selectAction (OpenUrl) fires handler', (
    tester,
  ) async {
    bool opened = false;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'ColumnSet',
          'columns': [
            {
              'type': 'Column',
              'selectAction': {
                'type': 'Action.OpenUrl',
                'url': 'https://example.com/column',
              },
              'items': [
                {'type': 'TextBlock', 'text': 'Tap column'},
              ],
            },
          ],
        },
      ],
    };

    await tester.pumpWidget(
      buildCard(map, onOpenUrl: (url) => opened = true, onSubmit: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tap column'), findsOneWidget);

    await tester.tap(find.text('Tap column'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('AdaptiveImage selectAction (OpenUrl) fires handler', (
    tester,
  ) async {
    bool opened = false;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {'type': 'TextBlock', 'text': 'Image with Action'},
        {
          'type': 'Image',
          'url': 'https://example.com/image.png',
          'selectAction': {
            'type': 'Action.OpenUrl',
            'url': 'https://example.com/image',
          },
        },
      ],
    };

    await tester.pumpWidget(
      buildCard(map, onOpenUrl: (url) => opened = true, onSubmit: (_) {}),
    );
    await tester.pumpAndSettle();

    // image itself may be represented by an Image widget
    expect(find.byType(Image), findsOneWidget);

    final imageInk = find.ancestor(
      of: find.byType(Image),
      matching: find.byType(InkWell),
    );
    expect(imageInk, findsOneWidget);

    await tester.tap(imageInk);
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  }, skip: true);

  testWidgets(
    'AdaptiveContainer selectAction (Submit) calls onSubmit with provided data',
    (tester) async {
      Map? submitted;

      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'Container',
            'selectAction': {
              'type': 'Action.Submit',
              'data': {'foo': 'bar'},
            },
            'items': [
              {'type': 'TextBlock', 'text': 'Submit container'},
            ],
          },
        ],
      };

      await tester.pumpWidget(
        buildCard(map, onOpenUrl: (_) {}, onSubmit: (map) => submitted = map),
      );
      await tester.pumpAndSettle();

      expect(find.text('Submit container'), findsOneWidget);

      await tester.tap(find.text('Submit container'));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!['foo'], 'bar');
    },
  );
}
