import 'package:adaptive_chat_server_dart/src/cards.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:test/test.dart';

void main() {
  group('userBubble', () {
    test(
      'is right-aligned accent style with the text in a spacer/content ColumnSet',
      () {
        final card = userBubble('hello');
        expect(card['type'], 'AdaptiveCard');
        final body = card['body'] as List;
        final columnSet = body[1] as Map<String, dynamic>;
        final columns = columnSet['columns'] as List;
        expect(columns, hasLength(2));
        // spacer (weight 1) first, content (weight 3) second, for right
        // alignment.
        expect((columns[0] as Map)['width'], 1);
        expect((columns[1] as Map)['width'], 3);
        final container =
            ((columns[1] as Map)['items'] as List).single
                as Map<String, dynamic>;
        expect(container['style'], 'accent');
        expect(container['roundedCorners'], true);
        final textBlock =
            (container['items'] as List).single as Map<String, dynamic>;
        expect(textBlock['text'], 'hello');
      },
    );

    test('defaults the role label to "user"', () {
      final card = userBubble('hello');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'user');
    });

    test('accepts a caller-supplied role label', () {
      final card = userBubble('hello', label: 'Me');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'Me');
    });
  });

  group('assistantBubble', () {
    test('is left-aligned emphasis style', () {
      final card = assistantBubble('hi there');
      final body = card['body'] as List;
      final columnSet = body[1] as Map<String, dynamic>;
      final columns = columnSet['columns'] as List;
      // content (weight 3) first, spacer (weight 1) second, for left alignment.
      expect((columns[0] as Map)['width'], 3);
      expect((columns[1] as Map)['width'], 1);
      final container =
          ((columns[0] as Map)['items'] as List).single as Map<String, dynamic>;
      expect(container['style'], 'emphasis');
    });

    test('defaults the role label to "assistant"', () {
      final card = assistantBubble('hi there');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'assistant');
    });

    test('accepts a caller-supplied role label', () {
      final card = assistantBubble('hi there', label: 'Bot');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'Bot');
    });
  });

  group('assistantCardBubble', () {
    test(
      'renders full-width with no ColumnSet, embedding the given body items',
      () {
        final bodyItems = [
          {'type': 'TextBlock', 'text': 'card content', 'wrap': true},
        ];
        final card = assistantCardBubble(bodyItems);
        final body = card['body'] as List;
        expect(body[0], {
          'type': 'TextBlock',
          'text': 'assistant',
          'wrap': true,
        });
        final container = body[1] as Map<String, dynamic>;
        expect(container['type'], 'Container');
        expect(container['style'], 'emphasis');
        expect(container['roundedCorners'], true);
        expect(container['items'], bodyItems);
        // No ColumnSet anywhere in a card reply.
        expect(
          body.any((item) => (item as Map)['type'] == 'ColumnSet'),
          isFalse,
        );
      },
    );

    test('accepts a caller-supplied role label', () {
      final bodyItems = [
        {'type': 'TextBlock', 'text': 'card content', 'wrap': true},
      ];
      final card = assistantCardBubble(bodyItems, label: 'Bot');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'Bot');
    });
  });

  group('noticeCard', () {
    test(
      'renders full-width attention style with no role label, embedding '
      'the given body items',
      () {
        final bodyItems = [
          {'type': 'TextBlock', 'text': 'notice', 'wrap': true},
        ];
        final card = noticeCard(bodyItems);
        expect(card['type'], 'AdaptiveCard');
        final body = card['body'] as List;
        // No role-label TextBlock ahead of the container: a notice card has
        // no author.
        expect(body, hasLength(1));
        final container = body[0] as Map<String, dynamic>;
        expect(container['type'], 'Container');
        expect(container['style'], 'attention');
        expect(container['roundedCorners'], true);
        expect(container['items'], bodyItems);
      },
    );
  });

  group('envelope', () {
    test('carries conversationId, interactionId, message cards, and links', () {
      final messages = [
        Message(role: 'user', card: userBubble('hi')),
        Message(role: 'assistant', card: assistantBubble('hello')),
      ];
      final result = envelope('c_abc', 'i_0001', messages);
      expect(result['conversationId'], 'c_abc');
      expect(result['interactionId'], 'i_0001');
      expect(result['messages'], [messages[0].card, messages[1].card]);
      expect(result['links'], {
        'self': '/conversations/c_abc/interactions/i_0001',
        'postNext': '/conversations/c_abc/interactions',
      });
    });
  });
}
