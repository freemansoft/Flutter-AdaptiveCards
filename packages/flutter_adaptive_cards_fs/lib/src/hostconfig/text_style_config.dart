/// Sets default properties for text of a given style
/// https://adaptivecards.io/explorer/TextStyleConfig.html
class TextStyleConfig({
  /// Font weight token for this text style.
  required final String weight,

  /// Font size token for this text style.
  required final String size,

  /// Foreground color token for this text style.
  required final String color,

  /// Font family token (`default` or `monospace`).
  required final String fontType,

  /// Whether this text style uses the subtle color variant.
  required final bool isSubtle,
}) {
  /// Creates text style defaults from explicit values.
  this;

  /// Parses a text style object from HostConfig JSON.
  factory fromJson(
    Map<String, dynamic> json, {
    TextStyleConfig? defaults,
  }) {
    return TextStyleConfig(
      weight: json['weight']?.toString() ?? defaults?.weight ?? 'default',
      size: json['size']?.toString() ?? defaults?.size ?? 'default',
      color: json['color']?.toString() ?? defaults?.color ?? 'default',
      fontType: json['fontType']?.toString() ?? defaults?.fontType ?? 'default',
      isSubtle: json['isSubtle'] as bool? ?? defaults?.isSubtle ?? false,
    );
  }
}
