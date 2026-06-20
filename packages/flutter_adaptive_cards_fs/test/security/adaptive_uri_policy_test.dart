import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = AdaptiveUriPolicy.standard;

  group('AdaptiveUriPolicy.standard', () {
    test('allows https public host', () {
      final result = policy.validate('https://example.com/path');
      expect(result, isA<AdaptiveUriAllowed>());
      expect((result as AdaptiveUriAllowed).uri.host, 'example.com');
    });

    test('denies javascript scheme', () {
      final result = policy.validate('javascript:alert(1)');
      expect(result, isA<AdaptiveUriDenied>());
      expect((result as AdaptiveUriDenied).reason, contains('scheme'));
    });

    test('denies file scheme', () {
      final result = policy.validate('file:///etc/passwd');
      expect(result, isA<AdaptiveUriDenied>());
    });

    test('denies loopback when disabled', () {
      final result = policy.validate('http://127.0.0.1/admin');
      expect(result, isA<AdaptiveUriDenied>());
      expect((result as AdaptiveUriDenied).reason, contains('loopback'));
    });

    test('denies RFC1918 private IPv4', () {
      final result = policy.validate('http://192.168.1.1/internal');
      expect(result, isA<AdaptiveUriDenied>());
      expect((result as AdaptiveUriDenied).reason, contains('private'));
    });

    test('denies empty url', () {
      final result = policy.validate('');
      expect(result, isA<AdaptiveUriDenied>());
    });

    test('permits loopback when policy allows', () {
      const devPolicy = AdaptiveUriPolicy(
        allowedSchemes: {'http', 'https'},
        allowLoopback: true,
        allowPrivateHosts: true,
      );
      final result = devPolicy.validate('http://127.0.0.1:8080');
      expect(result, isA<AdaptiveUriAllowed>());
    });

    test('permits mailto and tel schemes when added to allowedSchemes', () {
      const customPolicy = AdaptiveUriPolicy(
        allowedSchemes: {'https', 'http', 'mailto', 'tel'},
      );
      final mailtoResult = customPolicy.validate('mailto:someone@example.com');
      expect(mailtoResult, isA<AdaptiveUriAllowed>());

      final telResult = customPolicy.validate('tel:123-456-7890');
      expect(telResult, isA<AdaptiveUriAllowed>());
    });

    test('denies mailto when not in allowedSchemes', () {
      const policy = AdaptiveUriPolicy.standard;
      final result = policy.validate('mailto:someone@example.com');
      expect(result, isA<AdaptiveUriDenied>());
      expect((result as AdaptiveUriDenied).reason, contains('scheme'));
    });
  });
}
