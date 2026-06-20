import 'package:flutter_adaptive_cards_fs/src/adaptive_cards_canvas.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('NetworkAdaptiveCardContentProvider blocks loopback (SSRF)', () async {
    final client = MockClient((_) async {
      fail('no HTTP request should be issued for a denied URL');
    });
    final provider = NetworkAdaptiveCardContentProvider(
      url: 'http://127.0.0.1/card.json',
      client: client,
    );

    await expectLater(
      provider.loadAdaptiveCardContent(),
      throwsA(isA<AdaptiveUriPolicyException>()),
    );
  });

  test('NetworkAdaptiveCardContentProvider caps oversized body', () async {
    final client = MockClient((_) async => http.Response('0' * 4096, 200));
    final provider = NetworkAdaptiveCardContentProvider(
      url: 'https://example.com/card.json',
      client: client,
      fetchPolicy: const AdaptiveFetchPolicy(maxBytes: 128),
    );

    await expectLater(
      provider.loadAdaptiveCardContent(),
      throwsA(isA<AdaptiveFetchTooLargeException>()),
    );
  });

  test('NetworkAdaptiveCardContentProvider loads an in-policy card', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"type":"AdaptiveCard","version":"1.0","body":[]}',
        200,
      ),
    );
    final provider = NetworkAdaptiveCardContentProvider(
      url: 'https://example.com/card.json',
      client: client,
    );

    final map = await provider.loadAdaptiveCardContent();
    expect(map['type'], 'AdaptiveCard');
  });
}
