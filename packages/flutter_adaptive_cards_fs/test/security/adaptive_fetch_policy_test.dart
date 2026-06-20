import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readBodyWithLimit throws when body exceeds cap', () {
    final body = List<int>.filled(
      AdaptiveFetchPolicy.standard.maxBytes + 1,
      0x41,
    );
    expect(
      () => readBodyWithLimit(body, AdaptiveFetchPolicy.standard.maxBytes),
      throwsA(isA<AdaptiveFetchTooLargeException>()),
    );
  });

  test('readBodyWithLimit returns body when within cap', () {
    final body = [72, 73]; // "HI"
    expect(readBodyWithLimit(body, 10), body);
  });
}
