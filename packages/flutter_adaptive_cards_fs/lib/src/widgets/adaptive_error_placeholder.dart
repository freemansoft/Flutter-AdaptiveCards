import 'package:flutter/material.dart';

/// Visual placeholder shown when a card element fails to render.
///
/// Pairs a broken-image glyph with [message], so a host or card author can
/// see what went wrong in any build mode, not only in a debugger. Used for
/// unrecognized element/action types (`AdaptiveUnknown`) and for images that
/// fail to load (`AdaptiveImageUtils.getImage`).
class AdaptiveErrorPlaceholder extends StatelessWidget {
  /// Creates a placeholder showing [message] beside a broken-image icon.
  ///
  /// [width]/[height] size the placeholder to match the element it replaces
  /// (e.g. an `Image`'s resolved dimensions), avoiding layout shift.
  /// [semanticsLabel] is applied to the icon, e.g. an image's `altText`.
  const AdaptiveErrorPlaceholder({
    required this.message,
    this.width,
    this.height,
    this.semanticsLabel,
    super.key,
  });

  /// Description of what failed to render.
  final String message;

  /// Optional width to size the placeholder, matching the failed element.
  final double? width;

  /// Optional height to size the placeholder, matching the failed element.
  final double? height;

  /// Accessible name for the icon, e.g. an image's `altText`.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.broken_image,
          color: errorColor,
          size: width ?? height,
          semanticLabel: semanticsLabel,
        ),
        const SizedBox(height: 4),
        // liveRegion asks assistive technology to announce the message when
        // it appears, matching how input validation errors are announced.
        Semantics(
          liveRegion: true,
          child: Text(message, style: TextStyle(color: errorColor)),
        ),
      ],
    );

    if (width == null && height == null) return content;
    return SizedBox(width: width, height: height, child: content);
  }
}
