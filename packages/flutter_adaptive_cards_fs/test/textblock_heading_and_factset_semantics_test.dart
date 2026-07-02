import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// Regression tests for findings #10 (TextBlock heading level + icon token
/// suppression) and #11 (FactSet title/value semantic grouping).
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

  testWidgets('heading-styled TextBlock exposes header + HostConfig level', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({
        'type': 'TextBlock',
        'text': 'My Heading',
        'style': 'heading',
      }),
    );
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.text('My Heading'))
        .getSemanticsData();
    expect(data.flagsCollection.isHeader, isTrue);
    // Default HostConfig has no `textBlock` section, so level defaults to 2.
    expect(data.headingLevel, 2);
    handle.dispose();
  });

  testWidgets('non-heading TextBlock is not a header (level 0)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({'type': 'TextBlock', 'text': 'Just text'}),
    );
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.text('Just text'))
        .getSemanticsData();
    expect(data.flagsCollection.isHeader, isFalse);
    expect(data.headingLevel, 0);
    handle.dispose();
  });

  testWidgets('icon with a labeled selectAction does not double-announce', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({
        'type': 'Icon',
        'name': 'Home',
        'selectAction': {
          'type': 'Action.OpenUrl',
          'title': 'Open home',
          'url': 'https://example.com',
        },
      }),
    );
    await tester.pumpAndSettle();

    // The action title labels the button; the Fluent token is suppressed.
    expect(find.bySemanticsLabel('Open home'), findsWidgets);
    expect(find.bySemanticsLabel('Home'), findsNothing);
    handle.dispose();
  });

  testWidgets('standalone icon keeps its Fluent token label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({'type': 'Icon', 'name': 'Home'}),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Home'), findsWidgets);
    handle.dispose();
  });

  testWidgets('FactSet announces each fact as a combined "title: value" node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({
        'type': 'FactSet',
        'facts': [
          {'title': 'Name', 'value': 'John'},
          {'title': 'Age', 'value': '30'},
        ],
      }),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Name: John'), findsOneWidget);
    expect(find.bySemanticsLabel('Age: 30'), findsOneWidget);
    handle.dispose();
  });
}
