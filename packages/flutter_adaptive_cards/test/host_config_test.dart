import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/host_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostConfig Tests', () {
    // this test isn't valid.  Hostconfi first level properties can be null and have no defaults
    test('HostConfig defaults with empty json', () {
      final config = HostConfig.fromJson({});

      expect(config.imageSet?.imageSizeSmall, 64);
      expect(
        config.foregroundColors?.defaultColor.defaultColor,
        const Color(0xFF000000),
      );
      expect(
        config.foregroundColors?.accent.defaultColor,
        const Color(0xFF0000FF),
      );
      expect(config.textStyles?.heading.weight, 'bolder');
      expect(config.textStyles?.heading.size, 'large');
    }, skip: true);

    test('HostConfig custom values', () {
      final json = {
        'imageSet': {
          'imageSizeSmall': 40,
        },
        'foregroundColors': {
          'default': {
            'default': '#FF112233',
            'subtle': '#B2112233',
          },
        },
      };

      final config = HostConfig.fromJson(json);

      expect(config.imageSet?.imageSizeSmall, 40);
      expect(config.imageSet?.imageSizeMedium, 64); // default
      expect(
        config.foregroundColors?.defaultColor.defaultColor,
        const Color(0xFF112233),
      );
      expect(
        config.foregroundColors?.defaultColor.subtleColor,
        const Color(0xB2112233),
      );
    });

    test('ForegroundColorsConfig.fontColorConfig lookup', () {
      final config = HostConfig.fromJson({});

      expect(
        config.foregroundColors?.fontColorConfig('accent'),
        config.foregroundColors?.accent,
      );
      expect(
        config.foregroundColors?.fontColorConfig('invalid'),
        config.foregroundColors?.defaultColor,
      );
    });

    test('FontColorConfig hex parsing', () {
      final json = {
        'default': '#123456',
        'subtle': '#80123456',
      };
      final config = HostConfig.fromJson({
        'foregroundColors': {'default': json},
      });

      expect(
        config.foregroundColors?.defaultColor.defaultColor,
        const Color(0xFF123456),
      );
      expect(
        config.foregroundColors?.defaultColor.subtleColor,
        const Color(0x80123456),
      );
    });

    test('BadgeStylesConfig custom values', () {
      final json = {
        'badgeStyles': {
          'filled': {
            'backgroundColors': {
              'accent': {
                'default': '#FF0000FF',
                'subtle': '#B20000FF',
              },
              'good': {
                'default': '#FF0000FF',
                'subtle': '#B20000FF',
              },
            },
            'foregroundColors': {
              'accent': {
                'default': '#FFFFFFFF',
                'subtle': '#B2FF00FF',
              },
              'good': {
                'default': '#FFFFFFFF',
                'subtle': '#B2FF00FF',
              },
            },
          },
          'tint': {
            'backgroundColors': {
              'accent': {
                'default': '#FF0000FF',
                'subtle': '#B20000FF',
              },
              'good': {
                'default': '#FF0000FF',
                'subtle': '#B20000FF',
              },
            },
            'foregroundColors': {
              'accent': {
                'default': '#FFFFFFFF',
                'subtle': '#B2FF00FF',
              },
              'good': {
                'default': '#FFFFFFFF',
                'subtle': '#B2FF00FF',
              },
            },
          },
        },
      };

      final config = HostConfig.fromJson(json);

      expect(
        config.badgeStyles?.filled.backgroundColors.accent.defaultColor,
        const Color(0xFF0000FF),
      );
      expect(
        config.badgeStyles?.filled.foregroundColors.accent.defaultColor,
        const Color(0xFFFFFFFF),
      );
    });
  });
}
