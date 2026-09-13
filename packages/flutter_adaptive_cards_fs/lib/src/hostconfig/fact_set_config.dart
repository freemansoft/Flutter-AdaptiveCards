/// HostConfig `factSet.title` or `factSet.value` text styling defaults.
class FactSetTextConfig({
  /// Font size token for fact title or value text.
  required final String size,

  /// Font weight token for fact title or value text.
  required final String weight,

  /// Foreground color token for fact title or value text.
  required final String color,

  /// Font family token (`default` or `monospace`).
  required final String fontType,

  /// Whether fact text uses the subtle color variant.
  required final bool isSubtle,

  /// Whether fact text wraps to multiple lines.
  required final bool wrap,

  /// Maximum width in pixels before wrapping; `0` means no limit.
  required final int maxWidth,
}) {
  /// Creates fact-set text settings from explicit values.
  this;

  /// Parses a fact-set text object from HostConfig JSON.
  factory fromJson(
    Map<String, dynamic> json, {
    FactSetTextConfig? defaults,
  }) {
    return FactSetTextConfig(
      size: json['size']?.toString() ?? defaults?.size ?? 'default',
      weight: json['weight']?.toString() ?? defaults?.weight ?? 'default',
      color: json['color']?.toString() ?? defaults?.color ?? 'default',
      fontType: json['fontType']?.toString() ?? defaults?.fontType ?? 'default',
      isSubtle: json['isSubtle'] as bool? ?? defaults?.isSubtle ?? false,
      wrap: json['wrap'] as bool? ?? defaults?.wrap ?? true,
      maxWidth: json['maxWidth'] as int? ?? defaults?.maxWidth ?? 0,
    );
  }
}

/// HostConfig `factSet` section controlling FactSet title/value typography
/// and row spacing.
class FactSetConfig({
  /// Default typography for fact titles (`factSet.title`).
  required final FactSetTextConfig title,

  /// Default typography for fact values (`factSet.value`).
  required final FactSetTextConfig value,

  /// Vertical spacing in pixels between fact rows (`factSet.spacing`).
  required final int spacing,
}) {
  /// Creates fact-set settings from explicit values.
  this;

  /// Parses `factSet` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return FactSetConfig(
      title: FactSetTextConfig.fromJson(
        json['title'] ?? {},
        defaults: FactSetTextConfig(
          weight: 'bolder',
          size: 'default',
          color: 'default',
          fontType: 'default',
          isSubtle: false,
          wrap: true,
          maxWidth: 150,
        ),
      ),
      value: FactSetTextConfig.fromJson(
        json['value'] ?? {},
        defaults: FactSetTextConfig(
          weight: 'default',
          size: 'default',
          color: 'default',
          fontType: 'default',
          isSubtle: false,
          wrap: true,
          maxWidth: 0,
        ),
      ),
      spacing: json['spacing'] as int? ?? 10,
    );
  }
}
