import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/adaptive_error_placeholder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// A network image URL that passes the URI policy but returns bytes that
/// fail to decode ends up in `Image.network`'s `errorBuilder`, which must
/// render the same [AdaptiveErrorPlaceholder] used for unrecognized elements.
void main() {
  ({List<int> bytes, String contentType}) undecodableResponder(Uri url) =>
      (bytes: const [1, 2, 3], contentType: 'image/png');

  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides(
      urlResponder: undecodableResponder,
    );
  });

  Widget buildCard(Map<String, dynamic> el) => getTestWidgetFromMap(
    map: {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [el],
    },
    title: 'a test',
    onOpenUrl: (_) {},
    onSubmit: (_) {},
    onExecute: (_) {},
  );

  testWidgets('undecodable image response shows the error placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCard({
        'type': 'Image',
        'url': 'https://example.com/broken.png',
        'altText': 'A picture',
      }),
    );
    // The image codec failure surfaces asynchronously.
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveErrorPlaceholder), findsOneWidget);
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(
      find.textContaining(
        'Failed to load image: https://example.com/broken.png',
      ),
      findsOneWidget,
    );
  });
}
