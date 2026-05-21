import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_style_config.dart';

class TextStylesConfig {
  TextStylesConfig({
    required this.heading,
    required this.columnHeader,
  });

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

  final TextStyleConfig heading;
  final TextStyleConfig columnHeader;
}
