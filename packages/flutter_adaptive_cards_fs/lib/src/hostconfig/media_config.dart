class MediaConfig {
  MediaConfig({
    required this.defaultPoster,
    required this.playButton,
    required this.allowInlinePlayback,
  });

  factory MediaConfig.fromJson(Map<String, dynamic> json) {
    return MediaConfig(
      defaultPoster: json['defaultPoster']?.toString() ?? '',
      playButton: json['playButton']?.toString() ?? '',
      allowInlinePlayback: json['allowInlinePlayback'] as bool? ?? true,
    );
  }

  final String defaultPoster;
  final String playButton;
  final bool allowInlinePlayback;
}
