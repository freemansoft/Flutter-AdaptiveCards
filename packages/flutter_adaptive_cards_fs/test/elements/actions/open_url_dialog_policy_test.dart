import 'package:flutter_adaptive_cards_fs/src/action/open_url_dialog_executor.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('blocks private-network fetch without issuing a request', () async {
    final client = MockClient((_) async {
      fail('no HTTP request should be issued for a denied URL');
    });

    await expectLater(
      fetchOpenUrlDialogContent(
        'http://192.168.1.1/card.json',
        client: client,
      ),
      throwsA(isA<AdaptiveUriPolicyException>()),
    );
  });

  test('rejects an oversized response body', () async {
    final big = '0' * 2048;
    final client = MockClient((_) async {
      return http.Response(
        big,
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await expectLater(
      fetchOpenUrlDialogContent(
        'https://example.com/card.json',
        client: client,
        fetchPolicy: const AdaptiveFetchPolicy(maxBytes: 64),
      ),
      throwsA(isA<AdaptiveFetchTooLargeException>()),
    );
  });

  test('allows an in-policy JSON response', () async {
    final client = MockClient((_) async {
      return http.Response(
        '{"type":"AdaptiveCard","version":"1.0","body":[]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await fetchOpenUrlDialogContent(
      'https://example.com/card.json',
      client: client,
      uriPolicy: AdaptiveUriPolicy.standard,
    );

    expect(result, isA<Map<String, dynamic>>());
    expect((result as Map<String, dynamic>)['type'], 'AdaptiveCard');
  });
}
