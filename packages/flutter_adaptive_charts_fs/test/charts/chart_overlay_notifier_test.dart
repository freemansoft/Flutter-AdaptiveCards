import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _chartOverlayContainer() {
  return ProviderContainer(
    overrides: [
      baselineMapProvider.overrideWithValue({
        'type': 'AdaptiveCard',
        'version': '1.6',
        'body': [
          {
            'type': 'Chart.VerticalBar',
            'id': 'demoChart',
            'title': 'Baseline',
            'data': [
              {'x': 'A', 'y': 10},
            ],
          },
        ],
      }),
      cardTypeRegistryProvider.overrideWithValue(
        CardTypeRegistry(
          addedElements: CardChartsRegistry.additionalChartElements,
          overlayExtensions: CardChartsRegistry.overlayExtensions,
        ),
      ),
    ],
  );
}

void main() {
  group('Chart overlay extension', () {
    late ProviderContainer container;

    setUp(() {
      container = _chartOverlayContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('patchExtensionOverlay merges chart data into resolved element', () {
      container
          .read(adaptiveCardDocumentProvider.notifier)
          .patchExtensionOverlay(
            'demoChart',
            chartOverlayExtensionId,
            {
              'chartData': [
                {'x': 'B', 'y': 99},
              ],
            },
          );

      final resolved = container.read(resolvedElementProvider('demoChart'));
      final data = resolved?['data'] as List<dynamic>?;
      expect(data, hasLength(1));
      expect(data!.first['y'], 99);
    });

    test('patchExtensionOverlay merges whitelisted chart properties only', () {
      container
          .read(adaptiveCardDocumentProvider.notifier)
          .patchExtensionOverlay(
            'demoChart',
            chartOverlayExtensionId,
            {
              'chartProperties': {
                'title': 'Updated',
                'ignoredKey': 'skip',
              },
            },
          );

      final resolved = container.read(resolvedElementProvider('demoChart'));
      expect(resolved?['title'], 'Updated');
      expect(resolved?.containsKey('ignoredKey'), isFalse);
    });

    test('clearChartData restores baseline chart data', () {
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..patchExtensionOverlay(
          'demoChart',
          chartOverlayExtensionId,
          {
            'chartData': [
              {'x': 'B', 'y': 99},
            ],
          },
        )
        ..patchExtensionOverlay(
          'demoChart',
          chartOverlayExtensionId,
          {'clearChartData': true},
        );

      expect(
        notifier.state.overlaysById['demoChart']?.extensionPayloads?[
            chartOverlayExtensionId]?['chartData'],
        isNull,
      );

      final resolved = container.read(resolvedElementProvider('demoChart'));
      final data = resolved?['data'] as List<dynamic>?;
      expect(data!.first['y'], 10);
    });
  });
}
