import 'package:flutter_adaptive_cards_fs/src/cards/elements/media.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'Media source on a private host is blocked: no player is created',
    (tester) async {
      final map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Media',
            'id': 'clip',
            'sources': [
              {'url': 'http://192.168.1.10/internal.mp4'},
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'media policy test',
          scrollable: true,
        ),
      );
      await tester.pump();

      final state = tester.state<AdaptiveMediaState>(
        find.byType(AdaptiveMedia),
      );
      expect(state.sourceUrl, 'http://192.168.1.10/internal.mp4');
      // The standard policy denies the private-network source, so the network
      // player is never initialized.
      expect(state.videoPlayerController, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Media renders its poster placeholder without a LateInitializationError',
    (tester) async {
      final map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Media',
            'id': 'clip',
            'poster': 'https://example.com/poster.png',
            'altText': 'Overview video',
            // Blocked source → no player → build falls back to getPlaceholder,
            // which reads altText. Regression: altText was never initialized.
            'sources': [
              {'url': 'http://192.168.1.10/internal.mp4'},
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'media poster test',
          scrollable: true,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(AdaptiveMedia), findsOneWidget);
    },
  );
}
