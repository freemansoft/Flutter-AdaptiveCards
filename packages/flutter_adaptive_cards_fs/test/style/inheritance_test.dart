import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  group('ReferenceResolver style inheritance', () {
    late HostConfigs hostConfigs;
    late ReferenceResolver root;

    setUp(() {
      hostConfigs = HostConfigs();
      root = ReferenceResolver(
        hostConfigs: hostConfigs,
        colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
      );
    });

    test('background does not inherit parent emphasis', () {
      final emphasis = root.copyWith(inheritedContainerStyle: 'emphasis');
      expect(
        emphasis.resolveContainerBackgroundColor(style: 'default'),
        root.resolveContainerBackgroundColor(style: 'default'),
      );
      expect(
        emphasis.resolveContainerBackgroundColor(style: null),
        root.resolveContainerBackgroundColor(style: null),
      );
    });

    test('foreground uses inherited emphasis palette', () {
      hostConfigs.current = HostConfig.fromJson({
        'containerStyles': {
          'default': {
            'foregroundColors': {
              'default': {
                'default': '#000000',
                'subtle': '#000000',
              },
            },
          },
          'emphasis': {
            'foregroundColors': {
              'default': {
                'default': '#FFFFFF',
                'subtle': '#FFFFFF',
              },
            },
          },
        },
      });
      final emphasis = root.copyWith(inheritedContainerStyle: 'emphasis');
      final defaultContext = root.copyWith(inheritedContainerStyle: 'default');

      final emphasisFg = emphasis.resolveContainerForegroundColor();
      final defaultFg = defaultContext.resolveContainerForegroundColor();

      expect(emphasisFg, isNotNull);
      expect(defaultFg, isNotNull);
      expect(emphasisFg, isNot(equals(defaultFg)));
    });

    test('inheritedContainerStyleForChildren explicit default resets', () {
      expect(
        ReferenceResolver.inheritedContainerStyleForChildren(
          parentInherited: 'emphasis',
          ownContainerStyle: 'default',
        ),
        'default',
      );
    });

    test('inheritedContainerStyleForChildren omitted inherits parent', () {
      expect(
        ReferenceResolver.inheritedContainerStyleForChildren(
          parentInherited: 'emphasis',
          ownContainerStyle: null,
        ),
        'emphasis',
      );
    });

    test('resolveTextBlockStyle merges heading HostConfig defaults', () {
      hostConfigs.current = HostConfig.fromJson({
        'textStyles': {
          'heading': {
            'weight': 'bolder',
            'size': 'large',
            'color': 'accent',
            'fontType': 'default',
            'isSubtle': false,
          },
        },
      });

      final appearance = root.resolveTextBlockStyle(styleName: 'heading');
      expect(appearance.weight, 'bolder');
      expect(appearance.size, 'large');
      expect(appearance.color, 'accent');
    });

    test('resolveTextBlockStyle element overrides beat HostConfig', () {
      hostConfigs.current = HostConfig.fromJson({
        'textStyles': {
          'heading': {
            'weight': 'bolder',
            'size': 'large',
          },
        },
      });

      final appearance = root.resolveTextBlockStyle(
        styleName: 'heading',
        size: 'small',
      );
      expect(appearance.size, 'small');
      expect(appearance.weight, 'bolder');
    });

    test('resolveImageIsPerson only true for person style', () {
      expect(root.resolveImageIsPerson('person'), isTrue);
      expect(root.resolveImageIsPerson('default'), isFalse);
      expect(root.resolveImageIsPerson('emphasis'), isFalse);
      expect(root.resolveImageIsPerson(null), isFalse);
    });

    test('resolveEffectiveHorizontalAlignment inherits from resolver', () {
      final centered = root.copyWith(inheritedHorizontalAlignment: 'center');
      expect(centered.resolveEffectiveHorizontalAlignment(null), 'center');
      expect(
        centered.resolveEffectiveHorizontalAlignment('right'),
        'right',
      );
    });
  });

  testWidgets('ChildStyler pushes emphasis context to nested TextBlock', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        <String, dynamic>{
          'type': 'Container',
          'id': 'outer',
          'style': 'emphasis',
          'items': [
            <String, dynamic>{
              'type': 'TextBlock',
              'id': 'nestedText',
              'text': 'Nested',
            },
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'ChildStyler emphasis'),
    );
    await tester.pumpAndSettle();

    final textState = tester.state<AdaptiveTextBlockState>(
      find.byType(AdaptiveTextBlock),
    );
    final fg = textState.getColor(textState.context);
    expect(fg, isNotNull);
  });

  testWidgets('nested default container keeps default background', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        <String, dynamic>{
          'type': 'Container',
          'id': 'outer',
          'style': 'emphasis',
          'items': [
            <String, dynamic>{
              'type': 'Container',
              'id': 'inner',
              'style': 'default',
              'items': [
                <String, dynamic>{
                  'type': 'TextBlock',
                  'id': 't',
                  'text': 'inner',
                },
              ],
            },
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'nested default bg'),
    );
    await tester.pumpAndSettle();

    final containers = tester.widgetList<Container>(find.byType(Container));
    final outerResolver = ReferenceResolver(
      hostConfigs: HostConfigs(),
      colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
    );
    final defaultBg = outerResolver.resolveContainerBackgroundColor(
      style: 'default',
    );
    final emphasisBg = outerResolver.resolveContainerBackgroundColor(
      style: 'emphasis',
    );

    expect(
      containers.any(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color == defaultBg,
      ),
      isTrue,
    );
    expect(
      containers.any(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color == emphasisBg,
      ),
      isTrue,
    );
  });

  testWidgets('ColumnSet horizontalAlignment inherited by TextBlock', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        <String, dynamic>{
          'type': 'ColumnSet',
          'id': 'cs',
          'horizontalAlignment': 'center',
          'columns': [
            <String, dynamic>{
              'type': 'Column',
              'id': 'col',
              'width': 'stretch',
              'items': [
                <String, dynamic>{
                  'type': 'TextBlock',
                  'id': 'tb',
                  'text': 'centered',
                },
              ],
            },
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'alignment inherit'),
    );
    await tester.pumpAndSettle();

    final textState = tester.state<AdaptiveTextBlockState>(
      find.byType(AdaptiveTextBlock),
    );
    expect(textState.textAlign, TextAlign.center);
  });

  testWidgets('Image person style uses circular clip', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        <String, dynamic>{
          'type': 'Image',
          'id': 'img',
          'url': 'https://example.com/cat.png',
          'style': 'person',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'person image'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('Image default style does not clip oval', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        <String, dynamic>{
          'type': 'Image',
          'id': 'img',
          'url': 'https://example.com/cat.png',
          'style': 'default',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'default image'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ClipOval), findsNothing);
  });

  testWidgets('brightnessMode light uses light HostConfig', (
    WidgetTester tester,
  ) async {
    const lightOnly = Color(0xFF111111);
    final hostConfigs = HostConfigs(
      light: HostConfig.fromJson({
        'containerStyles': {
          'default': {
            'backgroundColor': '#111111',
            'foregroundColors': {
              'default': {
                'default': '#111111',
                'subtle': '#111111',
              },
            },
          },
        },
      }),
      dark: HostConfig.fromJson({
        'containerStyles': {
          'default': {
            'backgroundColor': '#EEEEEE',
            'foregroundColors': {
              'default': {
                'default': '#EEEEEE',
                'subtle': '#EEEEEE',
              },
            },
          },
        },
      }),
    );

    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        <String, dynamic>{
          'type': 'TextBlock',
          'id': 't',
          'text': 'theme',
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: AdaptiveCardsCanvas.map(
            content: map,
            showDebugJson: false,
            hostConfigs: hostConfigs,
            brightnessMode: AdaptiveCardBrightnessMode.light,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, lightOnly);
  });
}
