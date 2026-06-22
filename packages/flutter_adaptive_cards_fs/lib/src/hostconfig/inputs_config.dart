import 'package:flutter_adaptive_cards_fs/src/hostconfig/error_message_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/label_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_input_config.dart';

/// HostConfig `inputs` section controlling input label and error message
/// styling, and `Input.Text`-specific settings (`inputs.text`).
class InputsConfig {
  /// Creates input styling settings from explicit values.
  InputsConfig({
    required this.label,
    required this.errorMessage,
    required this.text,
  });

  /// Parses `inputs` from HostConfig JSON.
  factory InputsConfig.fromJson(Map<String, dynamic> json) {
    return InputsConfig(
      label: LabelConfig.fromJson(json['label'] ?? {}),
      errorMessage: ErrorMessageConfig.fromJson(json['errorMessage'] ?? {}),
      text: TextInputConfig.fromJson(json['text'] ?? {}),
    );
  }

  /// Label typography for required and optional inputs (`inputs.label`).
  final LabelConfig label;

  /// Validation error message typography (`inputs.errorMessage`).
  final ErrorMessageConfig errorMessage;

  /// `Input.Text`-specific settings (`inputs.text`).
  ///
  /// **Non-standard:** `inputs.text` is a custom extension, not part of the
  /// official Adaptive Cards HostConfig schema.
  final TextInputConfig text;
}
