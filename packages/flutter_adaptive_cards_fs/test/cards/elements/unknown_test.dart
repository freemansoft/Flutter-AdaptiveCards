import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/adaptive_error_placeholder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_utils.dart';

/// An unrecognized element `type` renders an [AdaptiveErrorPlaceholder] in
/// every build mode, replacing the old debug-only `ErrorWidget`.
void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
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

  testWidgets('unrecognized element type shows the error placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(buildCard({'type': 'NoSuchElement'}));
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveErrorPlaceholder), findsOneWidget);
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(find.textContaining('NoSuchElement'), findsOneWidget);
  });

  testWidgets('error placeholder announces its message as a live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildCard({'type': 'NoSuchElement'}));
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.textContaining('NoSuchElement'))
        .getSemanticsData();
    expect(data.flagsCollection.isLiveRegion, isTrue);

    handle.dispose();
  });
}
