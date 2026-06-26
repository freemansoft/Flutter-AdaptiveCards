import 'package:flutter/foundation.dart';

/// MediaSource model for AdaptiveCards Media element
///
/// * https://adaptivecards.io/explorer/Media.html
/// * https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/media
/// * https://adaptivecards.io/explorer/MediaSource.html
/// * https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/media-source
@immutable
class MediaSource {
  /// One playback source for a Media element.
  const MediaSource({
    required this.url,
    this.mimeType,
  });

  /// Parses a Media `sources[]` entry from card JSON.
  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      url: json['url'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
    );
  }

  /// Playback URL for the Media element.
  final String url;

  /// Optional MIME hint (for example `video/mp4`) for the player.
  final String? mimeType;

  /// Serializes for host-driven Media source updates.
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      if (mimeType != null) 'mimeType': mimeType,
    };
  }

  @override
  String toString() => 'MediaSource(url: $url, mimeType: $mimeType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaSource &&
        other.url == url &&
        other.mimeType == mimeType;
  }

  @override
  int get hashCode => Object.hash(url, mimeType);
}

/// Parses Media `sources` array from card JSON.
List<MediaSource> mediaSourcesFromJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => MediaSource.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
