import 'package:flutter_adaptive_cards_fs/src/hostconfig/choice_set_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/error_message_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/label_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_input_config.dart';

/// HostConfig `inputs` section controlling input label and error message
/// styling, and `Input.Text`-specific settings (`inputs.text`).
class InputsConfig({
  /// Label typography for required and optional inputs (`inputs.label`).
  required final LabelConfig label,

  /// Validation error message typography (`inputs.errorMessage`).
  required final ErrorMessageConfig errorMessage,

  /// `Input.Text`-specific settings (`inputs.text`).
  ///
  /// **Non-standard:** `inputs.text` is a custom extension, not part of the
  /// official Adaptive Cards HostConfig schema.
  required final TextInputConfig text,

  /// Compact `Input.ChoiceSet` dropdown settings (`inputs.choiceSet`).
  ///
  /// **Non-standard:** `inputs.choiceSet` is a custom extension, not part of
  /// the official Adaptive Cards HostConfig schema.
  required final ChoiceSetConfig choiceSet,
}) {
  /// Creates input styling settings from explicit values.
  this;

  /// Parses `inputs` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return InputsConfig(
      label: LabelConfig.fromJson(json['label'] ?? {}),
      errorMessage: ErrorMessageConfig.fromJson(json['errorMessage'] ?? {}),
      text: TextInputConfig.fromJson(json['text'] ?? {}),
      choiceSet: ChoiceSetConfig.fromJson(json['choiceSet'] ?? {}),
    );
  }
}
