import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

// 1x1 transparent PNG.
const _dataUri =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ'
    '/pLvAAAAAElFTkSuQmCC';

Map<String, dynamic> _columnCarouselCard() => {
  'type': 'AdaptiveCard',
  'version': '1.3',
  'body': [
    {
      'type': 'ColumnSet',
      'horizontalAlignment': 'Center', // inherits to the stretch column
      'columns': [
        {
          'type': 'Column',
          'width': 'stretch',
          'minHeight': '240px',
          'backgroundImage': {'url': _dataUri},
        },
        {
          'type': 'Column',
          'width': '56px',
          'items': [
            {'type': 'TextBlock', 'text': 'x'},
          ],
        },
      ],
    },
  ],
};

Map<String, dynamic> _containerCard() => {
  'type': 'AdaptiveCard',
  'version': '1.3',
  'body': [
    {
      'type': 'Container',
      'horizontalAlignment': 'Center',
      'minHeight': '240px',
      'backgroundImage': {'url': _dataUri},
    },
  ],
};

void main() {
  testWidgets('stretch Column backgroundImage fills the cell (not centered)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _columnCarouselCard(), title: 'col'),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    // The (foreground) background image fills the wide stretch column, not a
    // narrow centered band; height comes from the 240px row band.
    final image = find.byType(Image);
    expect(image, findsOneWidget);
    final size = tester.getSize(image);
    expect(size.width, greaterThan(200));
    expect(size.height, 240);
  });

  testWidgets('Container backgroundImage (no items) fills the cell', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _containerCard(), title: 'cont'),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final image = find.byType(Image);
    expect(image, findsOneWidget);
    final size = tester.getSize(image);
    expect(size.width, greaterThan(200));
    expect(size.height, 240);
  });
}
