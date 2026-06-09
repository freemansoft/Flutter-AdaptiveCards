import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/rich_text_block.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

TextSpan? findTextSpanWithText(TextSpan span, String text) {
  if (span.text == text) return span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) {
      final found = findTextSpanWithText(child, text);
      if (found != null) return found;
    }
  }
  return null;
}

void main() {
  test('TextRunModel.fromJson maps styling fields', () {
    final run = TextRunModel.fromJson({
      'type': 'TextRun',
      'text': 'Hello',
      'weight': 'Bolder',
      'color': 'Accent',
      'italic': true,
      'underline': true,
      'highlight': true,
      'selectAction': {'type': 'Action.OpenUrl', 'url': 'https://example.com'},
    });

    expect(run.text, 'Hello');
    expect(run.weight, 'Bolder');
    expect(run.color, 'Accent');
    expect(run.italic, isTrue);
    expect(run.underline, isTrue);
    expect(run.highlight, isTrue);
    expect(run.selectAction?['url'], 'https://example.com');
  });

  testWidgets('RichTextBlock renders bold and regular runs', (tester) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.2',
      'body': [
        {
          'type': 'RichTextBlock',
          'inlines': [
            {'type': 'TextRun', 'text': 'Hello ', 'weight': 'Default'},
            {'type': 'TextRun', 'text': 'world', 'weight': 'Bolder'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'rich text bold',
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hello'), findsOneWidget);
    expect(find.textContaining('world'), findsOneWidget);

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(AdaptiveRichTextBlock),
        matching: find.byType(RichText),
      ),
    );
    final hello = findTextSpanWithText(richText.text as TextSpan, 'Hello ');
    final world = findTextSpanWithText(richText.text as TextSpan, 'world');
    expect(hello, isNotNull);
    expect(world, isNotNull);
    expect(world!.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('RichTextBlock applies color token on a run', (tester) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.2',
      'body': [
        {
          'type': 'RichTextBlock',
          'inlines': [
            {'type': 'TextRun', 'text': 'Accent text', 'color': 'Accent'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'rich text color',
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accent text'), findsOneWidget);

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(AdaptiveRichTextBlock),
        matching: find.byType(RichText),
      ),
    );
    final span = findTextSpanWithText(
      richText.text as TextSpan,
      'Accent text',
    );
    expect(span, isNotNull);
    expect(span!.style?.color, isNotNull);
  });

  testWidgets('TextRun selectAction OpenUrl invokes onOpenUrl', (tester) async {
    OpenUrlActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.2',
      'body': [
        {
          'type': 'RichTextBlock',
          'inlines': [
            {
              'type': 'TextRun',
              'text': 'Tap me',
              'selectAction': {
                'type': 'Action.OpenUrl',
                'url': 'https://example.com/run',
              },
            },
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'rich text selectAction',
        onOpenUrl: (invoke) => captured = invoke,
        onSubmit: (_) {},
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.url, 'https://example.com/run');
  });
}
