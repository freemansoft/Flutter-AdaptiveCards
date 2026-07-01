/// Returns whether [value] satisfies `Input.Number` validation rules for
/// [isRequired] and optional numeric [min]/[max] bounds.
///
/// An empty [value] is valid when the field is not required. A non-empty value
/// that cannot be parsed as a number is always invalid. A parseable value is
/// invalid when it falls outside the supplied bounds.
bool numberInputValueIsValid({
  required String? value,
  required bool isRequired,
  required num? min,
  required num? max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return !isRequired;
  final parsed = num.tryParse(text);
  if (parsed == null) return false;
  if (min != null && parsed < min) return false;
  if (max != null && parsed > max) return false;
  return true;
}

/// Returns whether [value] satisfies `Input.Date` validation rules for
/// [isRequired] and optional ISO `yyyy-MM-dd` [min]/[max] date strings.
///
/// An empty [value] is valid when the field is not required. A non-empty value
/// that cannot be parsed as a date is always invalid. A parseable date is
/// invalid when it falls outside the supplied bounds.
bool dateInputValueIsValid({
  required String? value,
  required bool isRequired,
  required String? min,
  required String? max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return !isRequired;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return false;
  final lower = (min == null || min.isEmpty) ? null : DateTime.tryParse(min);
  final upper = (max == null || max.isEmpty) ? null : DateTime.tryParse(max);
  if (lower != null && parsed.isBefore(lower)) return false;
  if (upper != null && parsed.isAfter(upper)) return false;
  return true;
}

/// Returns whether [value] satisfies `Input.Time` validation rules for
/// [isRequired] and optional `HH:mm` (or `H:mm`) [min]/[max] time strings.
///
/// An empty [value] is valid when the field is not required. A non-empty value
/// that cannot be parsed as a valid `HH:mm` time is always invalid (including
/// out-of-range hour/minute values). A parseable time is invalid when it falls
/// outside the supplied bounds.
bool timeInputValueIsValid({
  required String? value,
  required bool isRequired,
  required String? min,
  required String? max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return !isRequired;
  final minutes = _timeToMinutes(text);
  if (minutes == null) return false;
  final lower = _timeToMinutes(min);
  final upper = _timeToMinutes(max);
  if (lower != null && minutes < lower) return false;
  if (upper != null && minutes > upper) return false;
  return true;
}

/// Parses an `HH:mm` (or `H:mm`) string to minutes-since-midnight, or `null`
/// when the input is malformed or contains out-of-range hour/minute values.
int? _timeToMinutes(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hours = int.parse(match.group(1)!);
  final mins = int.parse(match.group(2)!);
  if (hours > 23 || mins > 59) return null;
  return hours * 60 + mins;
}
