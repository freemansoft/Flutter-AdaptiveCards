import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

ReferenceResolver _resolver({
  String? inheritedContainerStyle,
  String? inheritedHorizontalAlignment,
}) {
  return ReferenceResolver(
    inheritedContainerStyle: inheritedContainerStyle,
    inheritedHorizontalAlignment: inheritedHorizontalAlignment,
    hostConfigs: HostConfigs(),
    colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
  );
}

const List<String?> _containerStyles = [
  null,
  'default',
  'emphasis',
  'accent',
  'good',
  'warning',
  'attention',
];

void main() {
  group('static inheritance helpers', () {
    test('container style: own non-default wins, else inherits parent', () {
      expect(
        ReferenceResolver.inheritedContainerStyleForChildren(
          parentInherited: 'accent',
          ownContainerStyle: 'Emphasis',
        ),
        'emphasis',
      );
      expect(
        ReferenceResolver.inheritedContainerStyleForChildren(
          parentInherited: 'accent',
          ownContainerStyle: 'default',
        ),
        'default',
      );
      expect(
        ReferenceResolver.inheritedContainerStyleForChildren(
          parentInherited: 'accent',
          ownContainerStyle: null,
        ),
        'accent',
      );
    });

    test('alignment: own non-empty wins, else inherits parent', () {
      expect(
        ReferenceResolver.inheritedHorizontalAlignmentForChildren(
          parentInherited: 'right',
          ownAlignment: 'Center',
        ),
        'center',
      );
      expect(
        ReferenceResolver.inheritedHorizontalAlignmentForChildren(
          parentInherited: 'right',
          ownAlignment: '',
        ),
        'right',
      );
      expect(
        ReferenceResolver.inheritedHorizontalAlignmentForChildren(
          parentInherited: 'right',
          ownAlignment: null,
        ),
        'right',
      );
    });
  });

  group('context-free resolvers', () {
    final resolver = _resolver();

    test('container background/foreground resolve for every style', () {
      for (final style in _containerStyles) {
        expect(
          () => resolver.resolveContainerBackgroundColor(style: style),
          returnsNormally,
        );
        for (final subtle in [true, false]) {
          expect(
            () => resolver.resolveContainerForegroundColor(
              style: style,
              isSubtle: subtle,
            ),
            returnsNormally,
          );
        }
      }
    });

    test('font weight orders lighter <= default <= bolder', () {
      final lighter = resolver.resolveFontWeight('lighter');
      final normal = resolver.resolveFontWeight(null);
      final bolder = resolver.resolveFontWeight('Bolder');
      expect(lighter.value, lessThanOrEqualTo(normal.value));
      expect(bolder.value, greaterThanOrEqualTo(normal.value));
    });

    test('text block style resolves named styles and overrides', () {
      for (final name in [
        'heading',
        'columnHeader',
        'column_header',
        'default',
        'bogus',
      ]) {
        expect(() => resolver.resolveTextBlockStyle(styleName: name),
            returnsNormally);
      }
      final overridden = resolver.resolveTextBlockStyle(
        styleName: 'heading',
        size: 'large',
        isSubtle: true,
      );
      expect(overridden.size, 'large');
      expect(overridden.isSubtle, isTrue);
    });

    test('orientation normalizes to Vertical/Horizontal', () {
      expect(resolver.resolveOrientation('vertical'), 'Vertical');
      expect(resolver.resolveOrientation('horizontal'), 'Horizontal');
      expect(resolver.resolveOrientation(null), 'Horizontal');
    });

    test('effective horizontal alignment applies inheritance', () {
      expect(_resolver().resolveEffectiveHorizontalAlignment('CENTER'), 'center');
      expect(
        _resolver(inheritedHorizontalAlignment: 'right')
            .resolveEffectiveHorizontalAlignment(null),
        'right',
      );
      expect(_resolver().resolveEffectiveHorizontalAlignment(null), 'left');
    });

    test('resolveAlignment maps to Flutter alignments', () {
      expect(resolver.resolveAlignment('left'), Alignment.centerLeft);
      expect(resolver.resolveAlignment('center'), Alignment.center);
      expect(resolver.resolveAlignment('right'), Alignment.centerRight);
      expect(resolver.resolveAlignment(null), Alignment.centerLeft);
    });

    test('image isPerson is true only for the person style', () {
      expect(resolver.resolveImageIsPerson('Person'), isTrue);
      expect(resolver.resolveImageIsPerson('default'), isFalse);
      expect(resolver.resolveImageIsPerson(null), isFalse);
    });

    test('copyWith overrides inherited context, keeps host config', () {
      final copy = resolver.copyWith(inheritedContainerStyle: 'emphasis');
      expect(copy.inheritedContainerStyle, 'emphasis');
      expect(copy.hostConfigs, same(resolver.hostConfigs));
    });
  });

  group('context-dependent resolvers', () {
    testWidgets('button/input/font resolvers use the theme', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      );

      final resolver = _resolver();
      final scheme = Theme.of(context).colorScheme;

      expect(
        resolver.resolveButtonBackgroundColor(context: context, style: 'default'),
        scheme.primary,
      );
      expect(
        resolver.resolveButtonBackgroundColor(
          context: context,
          style: 'positive',
        ),
        scheme.secondary,
      );
      expect(
        resolver.resolveButtonBackgroundColor(
          context: context,
          style: 'destructive',
        ),
        scheme.error,
      );
      expect(
        resolver.resolveButtonForegroundColor(
          context: context,
          style: 'positive',
        ),
        scheme.onSecondary,
      );

      expect(
        () => resolver.resolveInputBackgroundColor(
          context: context,
          style: 'emphasis',
        ),
        returnsNormally,
      );
      expect(
        () => resolver.resolveInputForegroundColor(context: context),
        returnsNormally,
      );

      // No color when a background image is present; a color for a style.
      expect(
        resolver.resolveContainerBackgroundColorIfNoBackgroundImage(
          context: context,
          style: 'emphasis',
          backgroundImageUrl: 'https://example.com/bg.png',
        ),
        isNull,
      );
      expect(
        resolver.resolveContainerBackgroundColorIfNoBackgroundImage(
          context: context,
          style: null,
          backgroundImageUrl: null,
        ),
        isNull,
      );
      expect(
        resolver.resolveContainerBackgroundColorIfNoBackgroundImage(
          context: context,
          style: 'emphasis',
          backgroundImageUrl: null,
        ),
        isNotNull,
      );

      final small = resolver.resolveFontSize(
        context: context,
        sizeString: 'small',
      );
      final defaultSize = resolver.resolveFontSize(context: context);
      final extraLarge = resolver.resolveFontSize(
        context: context,
        sizeString: 'extraLarge',
      );
      expect(small, lessThanOrEqualTo(defaultSize));
      expect(extraLarge, greaterThanOrEqualTo(defaultSize));

      expect(
        () => resolver.resolveFontType(context, 'monospace'),
        returnsNormally,
      );
    });
  });
}
