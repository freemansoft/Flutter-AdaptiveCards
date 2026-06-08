import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseIsVisible', () {
    test('null defaults to true', () {
      expect(parseIsVisible(null), isTrue);
    });

    test('bool passthrough', () {
      expect(parseIsVisible(true), isTrue);
      expect(parseIsVisible(false), isFalse);
    });

    test('string true/false is case insensitive', () {
      expect(parseIsVisible('true'), isTrue);
      expect(parseIsVisible('TRUE'), isTrue);
      expect(parseIsVisible('false'), isFalse);
    });

    test('other types default to true', () {
      expect(parseIsVisible(1), isTrue);
    });
  });

  group('parseHostConfigColor', () {
    test('parses #RRGGBB with opaque alpha', () {
      expect(parseHostConfigColor('#FF0000'), const Color(0xFFFF0000));
    });

    test('parses #AARRGGBB', () {
      expect(parseHostConfigColor('#80FF0000'), const Color(0x80FF0000));
    });

    test('returns null for invalid input', () {
      expect(parseHostConfigColor(null), isNull);
      expect(parseHostConfigColor('red'), isNull);
      expect(parseHostConfigColor('#FFF'), isNull);
      expect(parseHostConfigColor('FF0000'), isNull);
    });
  });
}
