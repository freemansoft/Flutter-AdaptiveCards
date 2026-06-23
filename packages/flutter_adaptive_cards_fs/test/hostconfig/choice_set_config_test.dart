import 'package:flutter_adaptive_cards_fs/src/hostconfig/choice_set_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChoiceSetConfig', () {
    test('enableSearch defaults to true and requestFocusOnTap to null', () {
      final config = ChoiceSetConfig.fromJson({});
      expect(config.enableSearch, isTrue);
      expect(config.requestFocusOnTap, isNull);
    });

    test('parses explicit values', () {
      final config = ChoiceSetConfig.fromJson({
        'enableSearch': false,
        'requestFocusOnTap': true,
      });
      expect(config.enableSearch, isFalse);
      expect(config.requestFocusOnTap, isTrue);
    });
  });
}
