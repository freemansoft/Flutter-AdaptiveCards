/// HostConfig `textBlock` section controlling TextBlock heading defaults.
class TextBlockConfig {
  /// Creates TextBlock settings from explicit values.
  new({
    required this.headingLevel,
  });

  /// Parses `textBlock` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return TextBlockConfig(
      headingLevel: json['headingLevel'] as int? ?? 2,
    );
  }

  /// Default heading level (1–6) for TextBlock elements styled as headings
  /// (`headingLevel`).
  final int headingLevel;
}
