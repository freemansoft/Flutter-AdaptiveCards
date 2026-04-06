import 'package:flutter/foundation.dart';

/// TableCell model for AdaptiveCards Table element
///
/// * https://adaptivecards.io/explorer/Table.html
/// * https://adaptivecards.io/explorer/TableCell.html
@immutable
class TableCellModel {
  const TableCellModel({
    required this.items,
    this.style,
    this.verticalContentAlignment,
    this.horizontalContentAlignment,
    this.backgroundImage,
    this.minHeight,
    this.selectAction,
    this.fallback,
    this.separator,
    this.spacing,
    this.id,
    this.isVisible,
    this.requires,
    this.rtl,
  });

  /// Creates a TableCellModel from JSON map
  factory TableCellModel.fromJson(Map<String, dynamic> json) {
    return TableCellModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .toList() ??
          [],
      style: json['style'] as String?,
      verticalContentAlignment: json['verticalContentAlignment'] as String?,
      horizontalContentAlignment: json['horizontalContentAlignment'] as String?,
      backgroundImage: json['backgroundImage'],
      minHeight: json['minHeight'] as String?,
      selectAction: json['selectAction'] as Map<String, dynamic>?,
      fallback: json['fallback'],
      separator: json['separator'] as bool?,
      spacing: json['spacing'] as String?,
      id: json['id'] as String?,
      isVisible: json['isVisible'] as bool?,
      requires: (json['requires'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      rtl: json['rtl'] as bool?,
    );
  }

  /// List of AdaptiveCard elements contained in this cell
  final List<Map<String, dynamic>> items;

  /// Style hint for the cell
  final String? style;

  /// Vertical alignment of cell content
  final String? verticalContentAlignment;

  /// Horizontal alignment of cell content
  final String? horizontalContentAlignment;

  /// Background image for the cell
  final dynamic backgroundImage;

  /// Minimum height in pixels
  final String? minHeight;

  /// Select action when cell is tapped
  final Map<String, dynamic>? selectAction;

  /// Fallback content
  final dynamic fallback;

  /// Show separator
  final bool? separator;

  /// Spacing
  final String? spacing;

  /// Unique identifier
  final String? id;

  /// Visibility flag
  final bool? isVisible;

  /// Requirements
  final Map<String, String>? requires;

  /// Right-to-left text
  final bool? rtl;

  /// Converts TableCellModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'items': items,
      if (style != null) 'style': style,
      if (verticalContentAlignment != null)
        'verticalContentAlignment': verticalContentAlignment,
      if (horizontalContentAlignment != null)
        'horizontalContentAlignment': horizontalContentAlignment,
      if (backgroundImage != null) 'backgroundImage': backgroundImage,
      if (minHeight != null) 'minHeight': minHeight,
      if (selectAction != null) 'selectAction': selectAction,
      if (fallback != null) 'fallback': fallback,
      if (separator != null) 'separator': separator,
      if (spacing != null) 'spacing': spacing,
      if (id != null) 'id': id,
      if (isVisible != null) 'isVisible': isVisible,
      if (requires != null) 'requires': requires,
      if (rtl != null) 'rtl': rtl,
    };
  }

  @override
  String toString() => 'TableCellModel(items: ${items.length} items)';
}
