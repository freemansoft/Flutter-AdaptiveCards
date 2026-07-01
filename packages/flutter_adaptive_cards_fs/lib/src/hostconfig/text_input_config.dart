import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `inputs.text` section — settings specific to `Input.Text`.
///
/// **Non-standard:** this is a custom extension to HostConfig and is not part of
/// the official Adaptive Cards HostConfig schema.
class TextInputConfig {
  /// Creates `Input.Text` settings from explicit values.
  TextInputConfig({required this.revealPasswordEnabled});

  /// Parses `inputs.text` from HostConfig JSON.
  factory TextInputConfig.fromJson(Map<String, dynamic> json) {
    return TextInputConfig(
      revealPasswordEnabled:
          json['revealPasswordEnabled'] as bool? ??
          FallbackConfigs.inputsConfig.text.revealPasswordEnabled,
    );
  }

  /// Whether `Input.Text` password fields show a show/hide eye-icon toggle.
  ///
  /// **Non-standard:** custom extension, not in the official Adaptive Cards
  /// HostConfig schema.
  ///
  /// Host default; a per-element overlay can override this at runtime.
  final bool revealPasswordEnabled;
}
