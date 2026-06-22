import 'package:flutter_adaptive_cards_fs/src/cards/elements/media.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('setUrl overlay updates resolved Media sources url', (
    WidgetTester tester,
  ) async {
    final map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Media',
          'id': 'clip',
          'sources': [
            {'url': 'https://baseline.example/v.mp4'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'media url overlay',
        scrollable: true,
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AdaptiveMedia)),
    );

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setUrl('clip', 'https://signed.example/v.mp4');
    await tester.pump();

    final resolved = container.read(resolvedElementProvider('clip'));
    final sources = resolved?['sources'] as List<dynamic>?;
    expect(sources?.first['url'], 'https://signed.example/v.mp4');
    expect(
      tester.state<AdaptiveMediaState>(find.byType(AdaptiveMedia)).sourceUrl,
      'https://signed.example/v.mp4',
    );
  });
}
