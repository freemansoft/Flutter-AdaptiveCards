// test/responsive/width_bucket_test.dart
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('targetWidthMatches', () {
    test('absent/empty targetWidth always matches', () {
      expect(targetWidthMatches(null, WidthBucket.narrow), isTrue);
      expect(targetWidthMatches('', WidthBucket.wide), isTrue);
    });

    test('bare bucket matches only that bucket', () {
      expect(targetWidthMatches('narrow', WidthBucket.narrow), isTrue);
      expect(targetWidthMatches('narrow', WidthBucket.wide), isFalse);
      expect(targetWidthMatches('veryNarrow', WidthBucket.veryNarrow), isTrue);
    });

    test('atLeast matches that bucket and wider', () {
      expect(targetWidthMatches('atLeast:standard', WidthBucket.standard), isTrue);
      expect(targetWidthMatches('atLeast:standard', WidthBucket.wide), isTrue);
      expect(targetWidthMatches('atLeast:standard', WidthBucket.narrow), isFalse);
    });

    test('atMost matches that bucket and narrower', () {
      expect(targetWidthMatches('atMost:narrow', WidthBucket.narrow), isTrue);
      expect(targetWidthMatches('atMost:narrow', WidthBucket.veryNarrow), isTrue);
      expect(targetWidthMatches('atMost:narrow', WidthBucket.standard), isFalse);
    });

    test('malformed targetWidth fails open (matches)', () {
      expect(targetWidthMatches('atleast:bogus', WidthBucket.narrow), isTrue);
      expect(targetWidthMatches('nonsense', WidthBucket.wide), isTrue);
      expect(targetWidthMatches('atLeast:', WidthBucket.wide), isTrue);
    });

    test('case-insensitive parsing', () {
      expect(targetWidthMatches('atleast:WIDE', WidthBucket.wide), isTrue);
    });
  });

  group('isExactBucketMatch', () {
    test('true only for bare bucket equal to current', () {
      expect(isExactBucketMatch('narrow', WidthBucket.narrow), isTrue);
      expect(isExactBucketMatch('atLeast:narrow', WidthBucket.narrow), isFalse);
      expect(isExactBucketMatch(null, WidthBucket.narrow), isFalse);
    });
  });
}
