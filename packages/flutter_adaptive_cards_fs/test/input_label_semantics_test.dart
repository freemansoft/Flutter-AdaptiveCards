import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/rating_stars.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// Regression tests for input label → field association.
///
/// The visible label built by `loadLabel` is a sibling widget; on its own a
/// screen reader announces it as an unlinked node. These tests pin that each
/// control's own semantics node carries the author label (and a spoken
/// "required" hint) so focusing the field announces its name:
/// `Input.Text` / `Input.Number` / `Input.Date` / `Input.Time`, `Input.Toggle`
/// (Switch), `Input.Rating`, and `Input.ChoiceSet` (compact/filtered/expanded).
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

  testWidgets('Input.Text field node carries the input label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({'type': 'Input.Text', 'id': 't', 'label': 'Full name'}),
    );
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.byType(TextFormField))
        .getSemanticsData();
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.label, contains('Full name'));
    handle.dispose();
  });

  testWidgets('Input.Text required field announces a "required" hint', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({
        'type': 'Input.Text',
        'id': 't',
        'label': 'Email',
        'isRequired': true,
      }),
    );
    await tester.pumpAndSettle();

    // The visible label conveys required only with a `*` glyph; the semantics
    // label spells it out so assistive tech announces it.
    final data = tester
        .getSemantics(find.byType(TextFormField))
        .getSemanticsData();
    expect(data.label, contains('Email'));
    expect(data.label, contains('required'));
    handle.dispose();
  });

  testWidgets('Input.Number field node carries the input label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({'type': 'Input.Number', 'id': 'n', 'label': 'Age'}),
    );
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.byType(TextFormField))
        .getSemanticsData();
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.label, contains('Age'));
    handle.dispose();
  });

  testWidgets('Input.Date field node carries the input label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({'type': 'Input.Date', 'id': 'd', 'label': 'Due date'}),
    );
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.byType(TextFormField))
        .getSemanticsData();
    expect(data.label, contains('Due date'));
    handle.dispose();
  });

  testWidgets('Input.Time button node carries the input label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({'type': 'Input.Time', 'id': 'tm', 'label': 'Start time'}),
    );
    await tester.pumpAndSettle();

    // Input.Time renders a picker button; the label is merged onto it so the
    // control announces its name (previously the label was dropped entirely).
    final data = tester
        .getSemantics(find.byType(ElevatedButton))
        .getSemanticsData();
    expect(data.label, contains('Start time'));
    handle.dispose();
  });

  testWidgets('Input.Toggle switch node carries the input label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({'type': 'Input.Toggle', 'id': 't', 'label': 'Accept terms'}),
    );
    await tester.pumpAndSettle();

    // The Switch + its label are merged into one node (SwitchListTile pattern),
    // so the toggle control itself announces the label.
    final data = tester.getSemantics(find.byType(Switch)).getSemanticsData();
    expect(data.label, contains('Accept terms'));
    handle.dispose();
  });

  testWidgets('Input.ChoiceSet compact dropdown field carries the label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({
        'type': 'Input.ChoiceSet',
        'id': 'c',
        'label': 'Country',
        'choices': [
          {'title': 'United States', 'value': 'us'},
        ],
      }),
    );
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.byType(DropdownMenu<String>))
        .getSemanticsData();
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.label, contains('Country'));
    handle.dispose();
  });

  testWidgets('Input.ChoiceSet filtered field carries the label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({
        'type': 'Input.ChoiceSet',
        'id': 'c',
        'label': 'Country',
        'style': 'filtered',
        'choices': [
          {'title': 'United States', 'value': 'us'},
        ],
      }),
    );
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.byType(TextFormField))
        .getSemanticsData();
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.label, contains('Country'));
    handle.dispose();
  });

  testWidgets(
    'Input.ChoiceSet expanded exposes a group label and per-option titles',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildCard({
          'type': 'Input.ChoiceSet',
          'id': 'c',
          'label': 'Country',
          'style': 'expanded',
          'choices': [
            {'title': 'United States', 'value': 'us'},
            {'title': 'Canada', 'value': 'ca'},
          ],
        }),
      );
      await tester.pumpAndSettle();

      // Options keep their own titles (individually focusable).
      expect(find.bySemanticsLabel('United States'), findsWidgets);
      expect(find.bySemanticsLabel('Canada'), findsWidgets);

      // The visual label's own semantics are excluded, so the only 'Country'
      // node is the group container — its presence confirms the group label.
      expect(find.bySemanticsLabel('Country'), findsWidgets);
      handle.dispose();
    },
  );

  testWidgets('Input.Rating control node carries the input label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard({
        'type': 'Input.Rating',
        'id': 'r',
        'label': 'Satisfaction',
        'value': 2,
        'max': 5,
      }),
    );
    await tester.pumpAndSettle();

    // The label is merged with the rating slider, so the control announces the
    // input label alongside its value.
    final data = tester
        .getSemantics(find.byType(RatingStars))
        .getSemanticsData();
    expect(data.label, contains('Satisfaction'));
    expect(data.value, contains('2 of 5 stars'));
    handle.dispose();
  });
}
