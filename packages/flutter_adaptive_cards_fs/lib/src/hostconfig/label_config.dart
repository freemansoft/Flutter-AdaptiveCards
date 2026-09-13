import 'package:flutter_adaptive_cards_fs/src/hostconfig/input_label_config.dart';

/// HostConfig `inputs.label` section controlling input label appearance.
class LabelConfig({
  /// Spacing token between an input label and its control (`inputSpacing`).
  required final String inputSpacing,

  /// Label styling for required inputs (`requiredInputs`).
  required final InputLabelConfig requiredInputs,

  /// Label styling for optional inputs (`optionalInputs`).
  required final InputLabelConfig optionalInputs,
}) {
  /// Creates input label settings from explicit values.
  this;

  /// Parses `inputs.label` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return LabelConfig(
      inputSpacing: json['inputSpacing']?.toString() ?? 'default',
      requiredInputs: InputLabelConfig.fromJson(json['requiredInputs'] ?? {}),
      optionalInputs: InputLabelConfig.fromJson(json['optionalInputs'] ?? {}),
    );
  }
}
