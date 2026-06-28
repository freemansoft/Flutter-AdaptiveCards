import 'package:flutter_adaptive_cards_fs/src/utils/block_height.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isStretchHeight', () {
    test('true only for "stretch" (case-insensitive)', () {
      expect(isStretchHeight({'height': 'stretch'}), isTrue);
      expect(isStretchHeight({'height': 'Stretch'}), isTrue);
    });
    test('false for auto/absent/non-string', () {
      expect(isStretchHeight({'height': 'auto'}), isFalse);
      expect(isStretchHeight({}), isFalse);
      expect(isStretchHeight({'height': 42}), isFalse);
      expect(isStretchHeight({'height': null}), isFalse);
    });
  });
}
