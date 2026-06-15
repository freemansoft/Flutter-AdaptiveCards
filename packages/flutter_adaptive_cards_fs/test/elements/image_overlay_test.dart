import 'package:flutter_adaptive_cards_fs/src/cards/elements/image.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('setUrl overlay updates resolved Image url', (
    WidgetTester tester,
  ) async {
    final map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Image',
          'id': 'photo',
          'url': 'https://baseline.example/photo.png',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'image url overlay'),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AdaptiveImage)),
    );

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setUrl('photo', 'https://signed.example/photo.png');
    await tester.pump();

    expect(
      container.read(resolvedElementProvider('photo'))?['url'],
      'https://signed.example/photo.png',
    );
    expect(
      tester.state<AdaptiveImageState>(find.byType(AdaptiveImage)).url,
      'https://signed.example/photo.png',
    );
  });
}
