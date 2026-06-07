// don't want to bring in imports
// ignore_for_file: comment_references

import 'package:intl/intl.dart';

final DateFormat _adaptiveDateFormat = DateFormat('yyyy-MM-dd');

/// Extracts the calendar date portion from [text] for ISO-style datetimes.
///
/// Behavior A: time and timezone are ignored; only `yyyy-MM-dd` matters.
String _datePortion(String text) {
  if (text.contains('T')) {
    return text.split('T').first;
  }
  if (text.contains(' ')) {
    return text.split(' ').first;
  }
  return text;
}

/// Parses an Adaptive Card [Input.Date] value from host `initData` or JSON.
///
/// Accepts `yyyy-MM-dd` (spec) and ISO-8601 datetimes. For datetimes, only
/// the calendar date portion is used; time and timezone offsets are ignored.
DateTime? parseAdaptiveDateValue(Object? raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  try {
    return _adaptiveDateFormat.parseStrict(_datePortion(text));
  } on FormatException {
    return null;
  }
}

/// Formats a [DateTime] for Adaptive Card [Input.Date] submit / display.
String formatAdaptiveDateValue(DateTime date) =>
    _adaptiveDateFormat.format(date);
