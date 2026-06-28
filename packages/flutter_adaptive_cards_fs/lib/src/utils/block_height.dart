/// Whether an element's `height` property requests `"stretch"` (fill available
/// main-axis space) rather than the `"auto"` default.
///
/// Case-insensitive; tolerant of absent or non-string values (returns `false`).
/// Shared by the stretchable-column layout and `Layout.AreaGrid` in-cell stretch.
bool isStretchHeight(Map<String, dynamic> map) {
  final height = map['height'];
  return height is String && height.trim().toLowerCase() == 'stretch';
}
