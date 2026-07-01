import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_widths_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostWidthsConfig.resolveBucket (defaults)', () {
    test('maps widths to buckets at and around boundaries', () {
      expect(HostWidthsConfig.resolveBucket(null, 100), WidthBucket.veryNarrow);
      expect(HostWidthsConfig.resolveBucket(null, 164), WidthBucket.veryNarrow);
      expect(HostWidthsConfig.resolveBucket(null, 165), WidthBucket.narrow);
      expect(HostWidthsConfig.resolveBucket(null, 349), WidthBucket.narrow);
      expect(HostWidthsConfig.resolveBucket(null, 350), WidthBucket.standard);
      expect(HostWidthsConfig.resolveBucket(null, 767), WidthBucket.standard);
      expect(HostWidthsConfig.resolveBucket(null, 768), WidthBucket.wide);
      expect(HostWidthsConfig.resolveBucket(null, 2000), WidthBucket.wide);
    });
  });

  group('HostWidthsConfig.resolveBucket (unbounded width)', () {
    test('resolveBucket returns wide for non-finite (unbounded) width', () {
      expect(
        HostWidthsConfig.resolveBucket(null, double.infinity),
        WidthBucket.wide,
      );
      expect(
        HostWidthsConfig.resolveBucket(null, double.nan),
        WidthBucket.wide,
      );
    });
  });

  group('HostWidthsConfig.fromJson', () {
    test('honors host overrides', () {
      final config = HostWidthsConfig.fromJson(
        const {'veryNarrow': 100, 'narrow': 200, 'standard': 300},
      );
      expect(HostWidthsConfig.resolveBucket(config, 150), WidthBucket.narrow);
      expect(HostWidthsConfig.resolveBucket(config, 250), WidthBucket.standard);
      expect(HostWidthsConfig.resolveBucket(config, 350), WidthBucket.wide);
    });

    test('falls back to defaults for missing keys', () {
      final config = HostWidthsConfig.fromJson(const {'narrow': 200});
      expect(config.veryNarrowMax, 165);
      expect(config.narrowMax, 200);
      expect(config.standardMax, 768);
    });
  });

  group('ReferenceResolver.resolveWidthBucket', () {
    test('parses hostWidthBreakpoints from HostConfig JSON and resolves', () {
      final hostConfig = HostConfig.fromJson(const {
        'hostWidthBreakpoints': {
          'veryNarrow': 100,
          'narrow': 200,
          'standard': 300,
        },
      });
      final resolver = ReferenceResolver(
        hostConfigs: HostConfigs(light: hostConfig, dark: hostConfig),
        colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
      );
      expect(resolver.resolveWidthBucket(150), WidthBucket.narrow);
      expect(resolver.resolveWidthBucket(350), WidthBucket.wide);
    });

    test('uses spec defaults when section absent', () {
      final resolver = ReferenceResolver(
        hostConfigs: HostConfigs(),
        colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
      );
      expect(resolver.resolveWidthBucket(100), WidthBucket.veryNarrow);
      expect(resolver.resolveWidthBucket(800), WidthBucket.wide);
    });
  });
}
