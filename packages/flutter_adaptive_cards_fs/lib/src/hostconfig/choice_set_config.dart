import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `inputs.choiceSet` section — settings specific to the compact
/// `Input.ChoiceSet` dropdown (Material 3 `DropdownMenu`).
///
/// Hosts use this to tune the dropdown's keyboard behavior without touching the
/// element JSON. Defaults reproduce the dropdown's prior hardcoded behavior, so
/// omitting the section is a no-op.
///
/// **Non-standard:** this is a custom extension to HostConfig and is not part of
/// the official Adaptive Cards HostConfig schema.
class ChoiceSetConfig {
  /// Creates compact `Input.ChoiceSet` dropdown settings from explicit values.
  ChoiceSetConfig({required this.enableSearch, this.requestFocusOnTap});

  /// Parses `inputs.choiceSet` from HostConfig JSON.
  factory ChoiceSetConfig.fromJson(Map<String, dynamic> json) {
    return ChoiceSetConfig(
      enableSearch: json['enableSearch'] as bool? ??
          FallbackConfigs.inputsConfig.choiceSet.enableSearch,
      requestFocusOnTap: json['requestFocusOnTap'] as bool?,
    );
  }

  /// Whether typing in the compact dropdown jumps to / highlights the matching
  /// entry (the closest analog to a native HTML `<select>`).
  ///
  /// **Non-standard:** custom extension, not in the official Adaptive Cards
  /// HostConfig schema.
  ///
  /// Host default; maps to `DropdownMenu.enableSearch`.
  final bool enableSearch;

  /// Overrides whether the compact dropdown takes focus (and thus enables
  /// keyboard type-ahead) when tapped.
  ///
  /// `null` keeps `DropdownMenu`'s platform-aware default: focusable on desktop
  /// (macOS/Linux/Windows) and tap-only on mobile (iOS/Android/Fuchsia). Set
  /// `true`/`false` to force the behavior regardless of platform.
  ///
  /// **Non-standard:** custom extension, not in the official Adaptive Cards
  /// HostConfig schema.
  ///
  /// Host default; maps to `DropdownMenu.requestFocusOnTap`.
  final bool? requestFocusOnTap;
}
