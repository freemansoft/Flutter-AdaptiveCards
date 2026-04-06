///
/// Used for finding scoped styling that defined in hostconfig -
/// mapps strings in json to reguilar values
///
class Resolver {
  ///
  static dynamic resolve(dynamic data, String path) {
    if (data == null) return null;
    if (path.isEmpty || path == '.') return data;

    final parts = path.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current == null) return null;

      // Handle array indexing like items[0]
      if (part.contains('[') && part.endsWith(']')) {
        final openBracketIndex = part.indexOf('[');
        final propertyName = part.substring(0, openBracketIndex);
        final indexString = part.substring(
          openBracketIndex + 1,
          part.length - 1,
        );

        // Navigate to property if it exists (e.g. items in items[0])
        if (propertyName.isNotEmpty) {
          if (current is Map && current.containsKey(propertyName)) {
            current = current[propertyName];
          } else {
            return null;
          }
        }

        // Handle index
        if (current is List) {
          final index = int.tryParse(indexString);
          if (index != null && index >= 0 && index < current.length) {
            current = current[index];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        // Standard property access
        if (current is Map && current.containsKey(part)) {
          current = current[part];
        } else {
          return null;
        }
      }
    }

    return current;
  }
}
