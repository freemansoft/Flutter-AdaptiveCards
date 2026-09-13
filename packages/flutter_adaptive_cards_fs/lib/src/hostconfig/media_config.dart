/// HostConfig `media` section controlling Media element defaults.
class MediaConfig({
  /// Default poster image URL when a Media element omits `poster`
  /// (`defaultPoster`).
  required final String defaultPoster,

  /// Play button image URL overlay on media (`playButton`).
  required final String playButton,

  /// Whether video may play inline instead of opening externally
  /// (`allowInlinePlayback`).
  required final bool allowInlinePlayback,
}) {
  /// Creates media element settings from explicit values.
  this;

  /// Parses `media` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return MediaConfig(
      defaultPoster: json['defaultPoster']?.toString() ?? '',
      playButton: json['playButton']?.toString() ?? '',
      allowInlinePlayback: json['allowInlinePlayback'] as bool? ?? true,
    );
  }
}
