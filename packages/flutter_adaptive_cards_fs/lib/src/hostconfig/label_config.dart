import 'package:flutter_adaptive_cards_fs/src/hostconfig/input_label_config.dart';

class LabelConfig {
  LabelConfig({
    required this.inputSpacing,
    required this.requiredInputs,
    required this.optionalInputs,
  });

  factory LabelConfig.fromJson(Map<String, dynamic> json) {
    return LabelConfig(
      inputSpacing: json['inputSpacing']?.toString() ?? 'default',
      requiredInputs: InputLabelConfig.fromJson(json['requiredInputs'] ?? {}),
      optionalInputs: InputLabelConfig.fromJson(json['optionalInputs'] ?? {}),
    );
  }

  final String inputSpacing;
  final InputLabelConfig requiredInputs;
  final InputLabelConfig optionalInputs;
}
