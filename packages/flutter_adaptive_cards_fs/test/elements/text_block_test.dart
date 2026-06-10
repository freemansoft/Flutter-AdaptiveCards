import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('plain TextBlock honors maxLines when markdown disabled', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'One two three four five six seven eight nine ten',
          'wrap': true,
          'maxLines': 2,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'text block maxLines',
        supportMarkdown: false,
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(AdaptiveTextBlock),
        matching: find.text('One two three four five six seven eight nine ten'),
      ),
    );
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('plain TextBlock applies color and isSubtle without markdown', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Styled plain text',
          'color': 'Accent',
          'weight': 'Bolder',
          'isSubtle': true,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'text block plain style',
        supportMarkdown: false,
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(AdaptiveTextBlock),
        matching: find.text('Styled plain text'),
      ),
    );
    expect(text.style?.color, isNotNull);
    expect(text.style?.fontWeight, FontWeight.w700);
  });
}
