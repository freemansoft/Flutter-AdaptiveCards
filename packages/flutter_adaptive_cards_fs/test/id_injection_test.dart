import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('injectIds tests', () {
    test(
      'should inject IDs into elements with type but no id '
      '(excluding root AdaptiveCard)',
      () {
        final map = <String, dynamic>{
          'type': 'AdaptiveCard',
          'body': [
            {'type': 'TextBlock', 'text': 'Hello'},
            {'type': 'Image', 'url': 'https://example.com/image.png'},
          ],
        };

        injectIds(map);

        final body = map['body'] as List;
        expect((body[0] as Map).containsKey('id'), isTrue);
        expect((body[1] as Map).containsKey('id'), isTrue);
        expect((body[0] as Map)['id'], startsWith('TextBlock-'));
        expect((body[1] as Map)['id'], startsWith('Image-'));
      },
    );

    test('should NOT inject IDs into objects without type', () {
      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'TextBlock',
            'text': 'Hello',
            'style': {'color': 'red'},
          },
        ],
      };

      injectIds(map);

      final body = map['body'] as List;
      expect(((body[0] as Map)['style'] as Map).containsKey('id'), isFalse);
    });

    test('should NOT overwrite existing IDs', () {
      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'id': 'my-custom-id',
        'body': [
          {'type': 'TextBlock', 'id': 'text-id', 'text': 'Hello'},
        ],
      };

      injectIds(map);

      expect(map['id'], equals('my-custom-id'));
      final body = map['body'] as List;
      expect((body[0] as Map)['id'], equals('text-id'));
    });

    test(
      'should generate different IDs for distinct map instances with '
      'same content',
      () {
        final map = <String, dynamic>{
          'type': 'AdaptiveCard',
          'body': [
            {'type': 'TextBlock', 'text': 'Hello'},
            {'type': 'TextBlock', 'text': 'Hello'},
          ],
        };

        injectIds(map);

        final body = map['body'] as List;
        final id1 = (body[0] as Map)['id'];
        final id2 = (body[1] as Map)['id'];

        expect(id1, isNotNull);
        expect(id2, isNotNull);
        expect(id1, isNot(equals(id2)));
      },
    );
  });
}
