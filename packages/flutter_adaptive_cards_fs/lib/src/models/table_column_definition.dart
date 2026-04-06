import 'package:flutter/foundation.dart';

/// TableColumnDefinition model for AdaptiveCards Table element
///
/// Represents a column definition with width configuration.
/// * https://adaptivecards.io/explorer/Table.html
@immutable
class TableColumnDefinition {
  const TableColumnDefinition({
    this.width,
  });

  /// Creates a TableColumnDefinition from JSON map
  factory TableColumnDefinition.fromJson(Map<String, dynamic> json) {
    return TableColumnDefinition(
      width: json['width'], // Can be num (flex ratio) or String (pixels)
    );
  }

  /// Column width - number (flex ratio) or string (pixel value like "50px")
  /// If null, column uses equal flex distribution
  final dynamic width;

  /// Converts TableColumnDefinition to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (width != null) 'width': width,
    };
  }

  @override
  String toString() => 'TableColumnDefinition(width: $width)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableColumnDefinition && other.width == width;
  }

  @override
  int get hashCode => width.hashCode;
}
