/// HostConfig `media` section controlling Media element defaults.
class MediaConfig {
  /// Creates media element settings from explicit values.
  MediaConfig({
    required this.defaultPoster,
    required this.playButton,
    required this.allowInlinePlayback,
  });

  /// Parses `media` from HostConfig JSON.
  factory MediaConfig.fromJson(Map<String, dynamic> json) {
    return MediaConfig(
      defaultPoster: json['defaultPoster']?.toString() ?? '',
      playButton: json['playButton']?.toString() ?? '',
      allowInlinePlayback: json['allowInlinePlayback'] as bool? ?? true,
    );
  }

  /// Default poster image URL when a Media element omits `poster`
  /// (`defaultPoster`).
  final String defaultPoster;

  /// Play button image URL overlay on media (`playButton`).
  final String playButton;

  /// Whether video may play inline instead of opening externally
  /// (`allowInlinePlayback`).
  final bool allowInlinePlayback;
}
