import 'dart:developer' as developer;

/// Card render-width bucket used by responsive layout (`targetWidth`, `layouts`).
///
/// Ordered narrowest → widest; the enum index doubles as the comparison rank
/// for `atLeast:` / `atMost:` relational matching.
enum WidthBucket {
  /// Narrowest bucket (e.g. compact phone width).
  veryNarrow,

  /// Narrow bucket.
  narrow,

  /// Standard bucket (default desktop card width).
  standard,

  /// Widest bucket.
  wide,
}

/// Whether [targetWidth] applies at the given [bucket].
///
/// Card authors set `targetWidth` on an element to gate it by card width.
/// Accepts a bare bucket name (`'narrow'`), or the relational forms
/// `'atLeast:<bucket>'` / `'atMost:<bucket>'`. A `null`/empty value always
/// matches. Parsing is case-insensitive and **fails open**: any unrecognized
/// value matches (and logs), so an authoring typo never silently hides content.
bool targetWidthMatches(String? targetWidth, WidthBucket bucket) {
  if (targetWidth == null || targetWidth.trim().isEmpty) return true;
  final raw = targetWidth.trim();

  if (raw.contains(':')) {
    final parts = raw.split(':');
    if (parts.length != 2) return _failOpen(raw);
    final op = parts[0].trim().toLowerCase();
    final target = _parseBucket(parts[1]);
    if (target == null) return _failOpen(raw);
    switch (op) {
      case 'atleast':
        return bucket.index >= target.index;
      case 'atmost':
        return bucket.index <= target.index;
      default:
        return _failOpen(raw);
    }
  }

  final target = _parseBucket(raw);
  if (target == null) return _failOpen(raw);
  return bucket == target;
}

/// Whether [targetWidth] is a bare bucket name exactly equal to [bucket].
///
/// Used by layout selection to prefer an exact-bucket layout over a relational
/// or default one.
bool isExactBucketMatch(String? targetWidth, WidthBucket bucket) {
  if (targetWidth == null || targetWidth.contains(':')) return false;
  return _parseBucket(targetWidth) == bucket;
}

WidthBucket? _parseBucket(String value) {
  switch (value.trim().toLowerCase()) {
    case 'verynarrow':
      return WidthBucket.veryNarrow;
    case 'narrow':
      return WidthBucket.narrow;
    case 'standard':
      return WidthBucket.standard;
    case 'wide':
      return WidthBucket.wide;
    default:
      return null;
  }
}

bool _failOpen(String raw) {
  developer.log('Unrecognized targetWidth "$raw"; treating as always-visible',
      name: 'responsive.width_bucket');
  return true;
}
