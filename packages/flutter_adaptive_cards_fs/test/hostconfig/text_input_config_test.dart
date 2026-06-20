import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_input_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextInputConfig', () {
    test('revealPasswordEnabled defaults to true when absent', () {
      final config = TextInputConfig.fromJson({});
      expect(config.revealPasswordEnabled, isTrue);
    });

    test('revealPasswordEnabled parses explicit false', () {
      final config = TextInputConfig.fromJson({'revealPasswordEnabled': false});
      expect(config.revealPasswordEnabled, isFalse);
    });
  });
}
