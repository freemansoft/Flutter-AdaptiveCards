class TextBlockConfig {
  TextBlockConfig({
    required this.headingLevel,
  });

  factory TextBlockConfig.fromJson(Map<String, dynamic> json) {
    return TextBlockConfig(
      headingLevel: json['headingLevel'] as int? ?? 2,
    );
  }

  final int headingLevel;
}
