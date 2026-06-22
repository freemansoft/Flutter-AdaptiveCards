import 'package:flutter_adaptive_cards_host_fs/src/security/bounded_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodeJsonMapWithLimit throws on oversized body', () {
    final huge = '{"a":[${List.filled(200000, '"x"').join(',')}]}';
    expect(
      () => decodeJsonMapWithLimit(huge, maxBytes: 1024),
      throwsA(isA<AdaptiveJsonTooLargeException>()),
    );
  });

  test('decodeJsonMapWithLimit returns the decoded map within the cap', () {
    final map = decodeJsonMapWithLimit('{"type":"AdaptiveCard"}');
    expect(map['type'], 'AdaptiveCard');
  });

  test('decodeJsonMapWithLimit rejects non-object JSON', () {
    expect(
      () => decodeJsonMapWithLimit('[1,2,3]'),
      throwsA(isA<FormatException>()),
    );
  });
}
