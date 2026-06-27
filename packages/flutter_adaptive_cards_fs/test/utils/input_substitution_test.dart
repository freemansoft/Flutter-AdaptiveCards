import 'package:flutter_adaptive_cards_fs/src/utils/input_substitution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('substituteInputValues', () {
    test('replaces a single token', () {
      expect(
        substituteInputValues(
          'https://x/?name={{nameInput.value}}',
          {'nameInput': 'David'},
        ),
        'https://x/?name=David',
      );
    });

    test('replaces multiple tokens', () {
      expect(
        substituteInputValues(
          '{{a.value}}-{{b.value}}',
          {'a': '1', 'b': '2'},
        ),
        '1-2',
      );
    });

    test('unknown id resolves to empty string', () {
      expect(
        substituteInputValues('x={{missing.value}}', const {}),
        'x=',
      );
    });

    test('null value resolves to empty string', () {
      expect(
        substituteInputValues('x={{a.value}}', {'a': null}),
        'x=',
      );
    });

    test('non-string values are stringified', () {
      expect(
        substituteInputValues('n={{n.value}}', {'n': 42}),
        'n=42',
      );
    });

    test('tolerates whitespace inside braces', () {
      expect(
        substituteInputValues('{{  a.value  }}', {'a': 'ok'}),
        'ok',
      );
    });

    test('text without tokens passes through unchanged', () {
      expect(
        substituteInputValues('https://example.com/api', const {}),
        'https://example.com/api',
      );
    });

    test('token embedded in larger string', () {
      expect(
        substituteInputValues(
          'prefix {{a.value}} suffix',
          {'a': 'MID'},
        ),
        'prefix MID suffix',
      );
    });
  });
}
