import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// HostConfig pair for the chat demo.
///
/// The server authors bubbles as containers with `style: "accent"` (user,
/// right-aligned) and `style: "emphasis"` (assistant, left-aligned). When a
/// `HostConfig`'s `containerStyles` section is left unset (as here), the
/// renderer falls back to colors derived from the ambient `ThemeData`'s
/// `ColorScheme` — `accent` resolves to `colorScheme.primaryContainer` and
/// `emphasis` to `colorScheme.surfaceContainerHighest`. Under the app's
/// Material 3 theme those two tones are already visually distinct, so no
/// explicit color overrides are needed here; this pair exists to give the
/// app an explicit, named seam for bubble theming without depending on the
/// bare `HostConfigs()` default.
HostConfigs chatHostConfigs() {
  return HostConfigs();
}
