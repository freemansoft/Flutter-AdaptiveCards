import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// Accessibility-semantics tests for input validation errors and the
/// ProgressBar / ProgressRing indicators.
///
/// Validation errors are announced via a `liveRegion` when they appear, and the
/// progress indicators expose a spoken percentage (and, for the ring, its
/// author label) so a screen reader conveys progress instead of silence.
void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  Widget buildCard(Map<String, dynamic> el) => getTestWidgetFromMap(
    map: {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [el],
    },
    title: 'a test',
    onOpenUrl: (_) {},
    onSubmit: (_) {},
    onExecute: (_) {},
  );

  testWidgets('input validation error is announced as a live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final el = {'type': 'Input.Number', 'id': 'n', 'label': 'Age'};
    await tester.pumpWidget(buildCard(el));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(generateWidgetKey(el))),
    );
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputError('n', errorMessage: 'Invalid age', isInvalid: true);
    await tester.pump();

    final node = tester.getSemantics(find.text('Invalid age'));
    expect(node, isSemantics(isLiveRegion: true, label: 'Invalid age'));
    handle.dispose();
  });

  testWidgets('ProgressBar exposes its completion percentage as a value', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildCard({'type': 'ProgressBar', 'value': 45}));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(LinearProgressIndicator));
    expect(node, isSemantics(label: 'Progress', value: '45%'));
    handle.dispose();
  });

  testWidgets('indeterminate ProgressBar still exposes a label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildCard({'type': 'ProgressBar'}));
    // An indeterminate bar animates forever, so pump one frame rather than
    // settling.
    await tester.pump(const Duration(milliseconds: 100));

    final data = tester
        .getSemantics(find.byType(LinearProgressIndicator))
        .getSemanticsData();
    expect(data.label, 'Progress');
    expect(data.value, isEmpty);
    handle.dispose();
  });

  testWidgets('ProgressRing exposes its label and percentage value', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({'type': 'ProgressRing', 'value': 30, 'label': 'Uploading'}),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(CircularProgressIndicator));
    expect(node, isSemantics(label: 'Uploading', value: '30%'));
    handle.dispose();
  });
}
