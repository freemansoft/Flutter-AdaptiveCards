import 'dart:convert';

import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('post encodes body and decodes JSON response', () async {
    final client = HttpAdaptiveCardBackendClient(
      endpoint: Uri.parse('https://api.example.com/invoke'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          jsonDecode(request.body),
          {'kind': 'execute', 'verb': 'save'},
        );
        return http.Response(
          jsonEncode({
            'type': 'adaptiveCard.invokeResponse',
            'effects': [
              {'type': 'noOp'},
            ],
          }),
          200,
        );
      }),
    );

    final response = await client.post({'kind': 'execute', 'verb': 'save'});
    expect(response['type'], 'adaptiveCard.invokeResponse');
  });

  test('post throws on non-2xx status', () async {
    final client = HttpAdaptiveCardBackendClient(
      endpoint: Uri.parse('https://api.example.com/invoke'),
      client: MockClient((request) async => http.Response('nope', 500)),
    );

    expect(
      () => client.post({'kind': 'execute'}),
      throwsA(isA<AdaptiveCardBackendException>()),
    );
  });
}
