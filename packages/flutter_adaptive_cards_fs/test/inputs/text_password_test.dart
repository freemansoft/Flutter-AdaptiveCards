import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

Map<String, dynamic> _cardWith(Map<String, dynamic> input) => {
  'type': 'AdaptiveCard',
  'body': [input],
};

void main() {
  testWidgets('password style obscures the text field', (tester) async {
    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'pwd',
        'label': 'Password',
        'style': 'password',
      }),
      title: 'Password Input Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
  });

  testWidgets('non-password style does not obscure', (tester) async {
    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'plain',
        'label': 'Name',
      }),
      title: 'Plain Input Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isFalse);
  });

  testWidgets('password style disables suggestions and autocorrect', (
    tester,
  ) async {
    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'pwd',
        'style': 'password',
      }),
      title: 'Password Suggestions Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.enableSuggestions, isFalse);
    expect(editable.autocorrect, isFalse);
  });

  testWidgets('multiline password field collapses to single line', (
    tester,
  ) async {
    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'mp',
        'style': 'password',
        'isMultiline': true,
      }),
      title: 'Multiline Password Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.maxLines, 1);
  });

  testWidgets('eye-icon shows by default and toggles obscure state', (
    tester,
  ) async {
    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'pwd',
        'label': 'Password',
        'style': 'password',
      }),
      title: 'Password Reveal Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
  });

  testWidgets('eye-icon hidden when HostConfig disables it', (tester) async {
    final hostConfigs = HostConfigs(
      light: HostConfig.fromJson(const {
        'inputs': {
          'text': {'revealPasswordEnabled': false},
        },
      }),
      dark: HostConfig.fromJson(const {
        'inputs': {
          'text': {'revealPasswordEnabled': false},
        },
      }),
    );

    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'pwd',
        'label': 'Password',
        'style': 'password',
      }),
      title: 'Password No Reveal Test',
      hostConfigs: hostConfigs,
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility), findsNothing);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
  });
}
