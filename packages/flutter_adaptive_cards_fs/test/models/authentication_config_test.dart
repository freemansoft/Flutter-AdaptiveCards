import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthenticationConfig.fromJson', () {
    test('parses text, connectionName, tokenExchangeResource and buttons', () {
      final config = AuthenticationConfig.fromJson({
        'text': 'Please sign in',
        'connectionName': 'myConnection',
        'tokenExchangeResource': {
          'id': 'res-id',
          'uri': 'api://example',
          'providerId': 'aad',
        },
        'buttons': [
          {
            'type': 'signin',
            'title': 'Sign in',
            'image': 'https://example.com/i.png',
            'value': 'https://login.example.com/oauth',
          },
        ],
      });

      expect(config.text, 'Please sign in');
      expect(config.connectionName, 'myConnection');
      expect(config.tokenExchangeResource?['uri'], 'api://example');
      expect(config.buttons, hasLength(1));
      expect(config.buttons.first.type, 'signin');
      expect(config.buttons.first.title, 'Sign in');
      expect(config.buttons.first.image, 'https://example.com/i.png');
      expect(config.buttons.first.value, 'https://login.example.com/oauth');
    });

    test('tolerates missing buttons and malformed entries', () {
      final config = AuthenticationConfig.fromJson({
        'text': 'Sign in',
        'buttons': [
          'not-a-map',
          {'type': 'signin', 'title': 'Go', 'value': 'https://x'},
        ],
      });

      expect(config.connectionName, isNull);
      expect(config.tokenExchangeResource, isNull);
      expect(config.buttons, hasLength(1));
      expect(config.buttons.first.value, 'https://x');
    });
  });
}
