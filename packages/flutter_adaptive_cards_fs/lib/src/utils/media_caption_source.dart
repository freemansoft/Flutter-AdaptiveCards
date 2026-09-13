/// A single closed-caption track descriptor for a `Media` element, parsed
/// from a `captionSources` entry. Hosts that support caption rendering read
/// [url] and [mimeType]; [label] is the human-readable track name.
class const CaptionSource({
  /// MIME type of the caption track (e.g. `vtt`).
  required final String mimeType,

  /// Absolute or data URL of the caption track.
  required final String url,

  /// Human-readable track label shown in caption selectors.
  required final String label,
}) {
  /// Creates a caption source from its parsed fields.
  this;
}

/// Parses a `captionSources` JSON array into [CaptionSource]s, skipping any
/// entry without a `url`. Returns an empty list for null or non-list input.
List<CaptionSource> captionSourcesFromJsonList(dynamic raw) {
  if (raw is! List) return const [];
  final result = <CaptionSource>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final url = entry['url']?.toString();
    if (url == null || url.isEmpty) continue;
    result.add(
      CaptionSource(
        mimeType: entry['mimeType']?.toString() ?? '',
        url: url,
        label: entry['label']?.toString() ?? '',
      ),
    );
  }
  return result;
}
