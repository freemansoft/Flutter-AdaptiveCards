import 'package:flutter_adaptive_cards_fs/src/hostconfig/input_label_config.dart';

/// HostConfig `inputs.label` section controlling input label appearance.
class LabelConfig {
  /// Creates input label settings from explicit values.
  LabelConfig({
    required this.inputSpacing,
    required this.requiredInputs,
    required this.optionalInputs,
  });

  /// Parses `inputs.label` from HostConfig JSON.
  factory LabelConfig.fromJson(Map<String, dynamic> json) {
    return LabelConfig(
      inputSpacing: json['inputSpacing']?.toString() ?? 'default',
      requiredInputs: InputLabelConfig.fromJson(json['requiredInputs'] ?? {}),
      optionalInputs: InputLabelConfig.fromJson(json['optionalInputs'] ?? {}),
    );
  }

  /// Spacing token between an input label and its control (`inputSpacing`).
  final String inputSpacing;

  /// Label styling for required inputs (`requiredInputs`).
  final InputLabelConfig requiredInputs;

  /// Label styling for optional inputs (`optionalInputs`).
  final InputLabelConfig optionalInputs;
}
