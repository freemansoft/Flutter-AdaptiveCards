import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_style_config.dart';

/// HostConfig `textStyles` section mapping named text styles to default
/// typography.
class TextStylesConfig {
  /// Creates named text style defaults from explicit values.
  TextStylesConfig({
    required this.heading,
    required this.columnHeader,
  });

  /// Parses `textStyles` from HostConfig JSON.
  factory TextStylesConfig.fromJson(Map<String, dynamic> json) {
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

  /// Default typography for heading text (`textStyles.heading`).
  final TextStyleConfig heading;

  /// Default typography for column header text (`textStyles.columnHeader`).
  final TextStyleConfig columnHeader;
}
