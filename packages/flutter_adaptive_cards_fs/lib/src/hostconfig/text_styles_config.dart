import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_style_config.dart';

/// HostConfig `textStyles` section mapping named text styles to default
/// typography.
class TextStylesConfig({
  /// Default typography for heading text (`textStyles.heading`).
  required final TextStyleConfig heading,

  /// Default typography for column header text (`textStyles.columnHeader`).
  required final TextStyleConfig columnHeader,
}) {
  /// Creates named text style defaults from explicit values.
  this;

  /// Parses `textStyles` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return TextStylesConfig(
      heading: TextStyleConfig.fromJson(
        json['heading'] ?? {},
        defaults: TextStyleConfig(
          weight: 'bolder',
          size: 'large',
          color: 'default',
          fontType: 'default',
          isSubtle: false,
        ),
      ),
      columnHeader: TextStyleConfig.fromJson(
        json['columnHeader'] ?? {},
        defaults: TextStyleConfig(
          weight: 'bolder',
          size: 'default',
          color: 'default',
          fontType: 'default',
          isSubtle: false,
        ),
      ),
    );
  }
}
