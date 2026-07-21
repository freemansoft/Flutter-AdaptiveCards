import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Corner radius applied to chat bubbles, in logical pixels.
///
/// The server marks each bubble `Container` with `roundedCorners: true`
/// (see `_text_container` in `adaptive_chat_server/app/cards.py`); that
/// flag opts the container into `HostConfig.cornerRadius` rather than the
/// library's sharp-corner default. 16 reads as a chat-bubble radius rather
/// than the library-wide default of 8.
const double _bubbleCornerRadius = 16;

/// HostConfig pair for the chat demo.
///
/// The server authors bubbles as containers with `style: "accent"` (user,
/// right-aligned) and `style: "emphasis"` (assistant, left-aligned), each
/// with `roundedCorners: true`. When a `HostConfig`'s `containerStyles`
/// section is left unset (as here), the renderer falls back to colors
/// derived from the ambient `ThemeData`'s `ColorScheme` — `accent` resolves
/// to `colorScheme.primaryContainer` and `emphasis` to
/// `colorScheme.surfaceContainerHighest`. Under the app's Material 3 theme
/// those two tones are already visually distinct, so no explicit color
/// overrides are needed here. `cornerRadius` is set to [_bubbleCornerRadius]
/// so the server's `roundedCorners` opt-in renders as a proper chat-bubble
/// shape instead of the library's default 8px radius.
HostConfigs chatHostConfigs() {
  return HostConfigs(
    light: const HostConfig(cornerRadius: _bubbleCornerRadius),
    dark: const HostConfig(cornerRadius: _bubbleCornerRadius),
  );
}
