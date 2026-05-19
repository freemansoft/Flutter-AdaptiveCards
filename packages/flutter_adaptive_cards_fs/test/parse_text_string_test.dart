import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('de', null);
  });

  void checkIfSameAfterParse(String text) {
    final String result = parseTextString(text);
    expect(result, equals(text));
  }

  void checkCorrectTransform(String text, String result, {String? locale}) {
    final String toTest = parseTextString(text, locale: locale);
    expect(toTest, equals(result));
  }

  test('Does not change normal or malformed text', () async {
    checkIfSameAfterParse('Hello');
    checkIfSameAfterParse('Some stuff {{ Hello');
    checkIfSameAfterParse('Hello my name is {{Norbert}}');
    checkIfSameAfterParse('This is the current date: {{text, SHORT}}');
    // escapes \a\0 are not supported in dart so they don't actually do anything
    // ignore: unnecessary_string_escapes
    checkIfSameAfterParse('{{\\\n\r\a\0 a123084 }}');
    checkIfSameAfterParse('{{DATE(2017-02-14T06:00Z, SHORTSSS)}}');
    checkIfSameAfterParse('{{DATE(2017-0322-14T06:00Z, SHORTSHORTSSS)}}');
    checkIfSameAfterParse('{{DDATE(2017-02-14T06:00Z, SHORT)}}');
    checkIfSameAfterParse('{{DATE(2017-02-14T06:00Z, SHORT))}}');

    checkIfSameAfterParse('{{TIME(2017-02-14T06:00Z, SHORT)}}');
    checkIfSameAfterParse('{{TIME(2017-02-14T06:00Z, )}}');
    checkIfSameAfterParse('{{TIMES(2017-02-14T06:00Z)}}');
  });

  test('Basic parsing', () {
    checkCorrectTransform(
      '{{DATE(2017-02-14T06:00Z, SHORT)}}',
      'Tue, Feb 14th, 2017',
    );

    checkCorrectTransform('{{DATE(2017-02-14T06:00Z, COMPACT)}}', '2/14/2017');
    checkCorrectTransform('{{DATE(2017-02-14T06:00Z)}}', '2/14/2017');
    checkCorrectTransform(
      '{{DATE(2017-02-14T06:00Z, LONG)}}',
      'Tuesday, February 14th, 2017',
    );

    // the character between time and AM/PM was a space and is now something else on a Mac
    checkCorrectTransform('{{TIME(2017-02-14T06:00Z)}}', '6:00 AM');
    checkCorrectTransform('{{TIME(2017-02-14T13:00Z)}}', '1:00 PM');

    checkCorrectTransform('{{TIME(2017-02-14T13:23Z)}}', '1:23 PM');
    checkCorrectTransform('{{TIME(2017-02-14T13:59Z)}}', '1:59 PM');
    checkCorrectTransform('{{TIME(2017-02-14T13:04Z)}}', '1:04 PM');
  });

  test('Locale parsing', () {
    // German
    checkCorrectTransform(
      '{{DATE(2017-02-14T06:00Z, SHORT)}}',
      'Di., Feb. 14th, 2017',
      locale: 'de',
    );
    checkCorrectTransform(
      '{{DATE(2017-02-14T06:00Z, COMPACT)}}',
      '14.2.2017',
      locale: 'de',
    );
    checkCorrectTransform(
      '{{DATE(2017-02-14T06:00Z, LONG)}}',
      'Dienstag, Februar 14th, 2017',
      locale: 'de',
    );
    checkCorrectTransform('{{TIME(2017-02-14T13:00Z)}}', '13:00', locale: 'de');

    // Spanish
    checkCorrectTransform(
      '{{DATE(2017-02-14T06:00Z, COMPACT)}}',
      '14/2/2017',
      locale: 'es',
    );
    checkCorrectTransform('{{TIME(2017-02-14T13:00Z)}}', '13:00', locale: 'es');
  });
}
