import 'package:flutter_adaptive_cards_fs/src/hostconfig/error_message_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/label_config.dart';

class InputsConfig {
  InputsConfig({
    required this.label,
    required this.errorMessage,
  });

  factory InputsConfig.fromJson(Map<String, dynamic> json) {
    return InputsConfig(
      label: LabelConfig.fromJson(json['label'] ?? {}),
      errorMessage: ErrorMessageConfig.fromJson(json['errorMessage'] ?? {}),
    );
  }

  final LabelConfig label;
  final ErrorMessageConfig errorMessage;
}
