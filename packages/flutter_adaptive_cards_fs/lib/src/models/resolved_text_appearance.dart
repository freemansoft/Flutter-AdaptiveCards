/// Merged TextBlock JSON properties and HostConfig TextStylesConfig defaults.
class ResolvedTextAppearance {
  /// Creates resolved typography defaults for a `TextBlock` element.
  const ResolvedTextAppearance({
    this.size,
    this.weight,
    this.color,
    this.fontType,
    this.isSubtle = false,
  });

  /// Resolved size token (element override or HostConfig default).
  final String? size;

  /// Resolved weight token (element override or HostConfig default).
  final String? weight;

  /// Resolved color style name.
  final String? color;

  /// Resolved font family token from `fontType`.
  final String? fontType;

  /// Whether subtle foreground coloring is applied.
  final bool isSubtle;
}
