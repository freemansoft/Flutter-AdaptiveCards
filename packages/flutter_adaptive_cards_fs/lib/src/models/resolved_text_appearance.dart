/// Merged TextBlock JSON properties and HostConfig TextStylesConfig defaults.
class ResolvedTextAppearance {
  const ResolvedTextAppearance({
    this.size,
    this.weight,
    this.color,
    this.fontType,
    this.isSubtle = false,
  });

  final String? size;
  final String? weight;
  final String? color;
  final String? fontType;
  final bool isSubtle;
}
