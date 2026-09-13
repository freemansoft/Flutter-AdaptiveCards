/// HostConfig `textBlock` section controlling TextBlock heading defaults.
class TextBlockConfig({
  /// Default heading level (1–6) for TextBlock elements styled as headings
  /// (`headingLevel`).
  required final int headingLevel,
}) {
  /// Creates TextBlock settings from explicit values.
  this;

  /// Parses `textBlock` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return TextBlockConfig(
      headingLevel: json['headingLevel'] as int? ?? 2,
    );
  }
}
