import 'package:flutter_adaptive_cards_plus/src/hostconfig/error_message_config.dart';

class InputLabelConfig {
  InputLabelConfig({
    required this.color,
    required this.isSubtle,
    required this.size,
    required this.suffix,
    required this.weight,
  });

  factory InputLabelConfig.fromJson(
    Map<String, dynamic> json, {
    InputLabelConfig? defaults,
  }) {
    return InputLabelConfig(
      color: json['color']?.toString() ?? defaults?.color ?? 'default',
      isSubtle: json['isSubtle'] as bool? ?? defaults?.isSubtle ?? false,
      size: json['size']?.toString() ?? defaults?.size ?? 'default',
      suffix: json['suffix']?.toString() ?? defaults?.suffix ?? '',
      weight: json['weight']?.toString() ?? defaults?.weight ?? 'default',
    );
  }

  final String color;
  final bool isSubtle;
  final String size;
  final String suffix;
  final String weight;
}

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
