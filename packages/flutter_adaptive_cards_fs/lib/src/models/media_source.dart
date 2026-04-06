import 'package:flutter/foundation.dart';

/// MediaSource model for AdaptiveCards Media element
///
/// * https://adaptivecards.io/explorer/Media.html
/// * https://adaptivecards.io/explorer/MediaSource.html
@immutable
class MediaSource {
  const MediaSource({
    required this.url,
    this.mimeType,
  });

  /// Creates a MediaSource from JSON map
  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      url: json['url'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
    );
  }

  /// URL to media source
  final String url;

  /// MIME type of the media source (e.g., 'video/mp4')
  final String? mimeType;

  /// Converts MediaSource to JSON map
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
