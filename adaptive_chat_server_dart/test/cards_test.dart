import 'package:adaptive_chat_server_dart/src/cards.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:test/test.dart';

// Ordinary behavioral unit test of cards.dart's bubble builders. The client
// is deliberately "dumb" — cards.dart says so in its own doc comment — and
// renders whatever card JSON it is handed full-width and stacked, so every
// bit of chat-bubble layout (left/right alignment, the 3:1 weighted-column
// split, which style each role gets, whether a role label appears at all)
// lives only in the JSON these functions build. A regression here changes
// what the user sees in the chat UI with no compiler or renderer to catch
// it: e.g. swapping a bubble's column order silently flips its alignment,
// and dropping the guard against a stray ColumnSet in a card reply would
// resurrect the intrinsic-height rendering crash noted in
// _fullWidthBubble's doc comment.
void main() {
  group('userBubble', () {
    // Pins the layout mechanism itself: alignment lives in which column
    // carries the spacer, not in a flag the renderer interprets. Swap the
    // column order and the bubble silently renders on the wrong side.
    test('is right-aligned accent style with the text in a spacer/content ColumnSet', () {
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
          ((columns[1] as Map)['items'] as List).single as Map<String, dynamic>;
      expect(container['style'], 'accent');
      expect(container['roundedCorners'], true);
      final textBlock =
          (container['items'] as List).single as Map<String, dynamic>;
      expect(textBlock['text'], 'hello');
    });

    // The default label is user-facing chrome shown above every anonymous
    // conversation's bubbles, not an internal placeholder.
    test('defaults the role label to "user"', () {
      final card = userBubble('hello');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'user');
    });

    // A client may supply its own label (e.g. a real display name); this is
    // the override path, distinct from the compiled-in default above.
    test('accepts a caller-supplied role label', () {
      final card = userBubble('hello', label: 'Me');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'Me');
    });
  });

  group('assistantBubble', () {
    // Mirrors userBubble's layout test, but confirms assistantBubble's
    // column order actually reverses left-vs-right rather than reusing
    // userBubble's ordering by accident.
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

    // See userBubble's default-label test above — this pins the
    // assistant-side default shown when no caller override arrives.
    test('defaults the role label to "assistant"', () {
      final card = assistantBubble('hi there');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'assistant');
    });

    // Same override contract as userBubble; checked separately here because
    // a shared-helper regression could break one role's label while leaving
    // the other's intact.
    test('accepts a caller-supplied role label', () {
      final card = assistantBubble('hi there', label: 'Bot');
      final body = card['body'] as List;
      expect((body[0] as Map)['text'], 'Bot');
    });
  });

  group('assistantCardBubble', () {
    // The full-width, no-ColumnSet shape is a rendering workaround, not a
    // stylistic choice: see _fullWidthBubble's doc comment — a Carousel
    // nested inside a ColumnSet's IntrinsicHeight pass renders blank or
    // asserts, so any card reply must skip ColumnSet entirely.
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

    // Same override contract as the two bubble builders above, checked here
    // too because this builder's body shape (bodyItems embedded directly,
    // no _textItems wrapping) is different code from theirs.
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
    test('renders full-width attention style with no role label, embedding '
        'the given body items', () {
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
    });
  });

  group('envelope', () {
    // This is the wire contract a client parses by field name; a renamed or
    // reshaped key here breaks every client with no Dart-level error to
    // catch it.
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
