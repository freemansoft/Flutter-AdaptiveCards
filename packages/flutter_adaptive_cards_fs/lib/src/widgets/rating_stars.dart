import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';

/// Resolves the star [Color] for a Rating / Input.Rating `color` token.
Color resolveRatingStarColor(ReferenceResolver resolver, String color) {
  if (color == 'marigold') {
    return resolver.resolveContainerForegroundColor(style: 'warning') ??
        Colors.orange;
  }
  if (color == 'light') {
    return resolver.resolveContainerForegroundColor(
          style: 'default',
          isSubtle: true,
        ) ??
        Colors.white70;
  }
  return resolver.resolveContainerForegroundColor(
        style: 'default',
        isSubtle: false,
      ) ??
      Colors.grey;
}

/// Maps a Rating `size` token to icon size in logical pixels.
double resolveRatingIconSize(String size) {
  return switch (size) {
    'large' => 24,
    'small' => 12,
    _ => 16,
  };
}

/// Shared star row for display Rating elements and interactive Input.Rating.
class RatingStars extends StatelessWidget {
  /// Creates a row of [max] stars for [value].
  const RatingStars({
    required this.value,
    required this.max,
    required this.starColor,
    required this.iconSize,
    this.readOnly = true,
    this.allowHalfSteps = false,
    this.onRatingChanged,
    this.useHalfStarDisplay = false,
    super.key,
  });

  /// Current rating (0 when unset).
  final double value;

  /// Maximum star count.
  final double max;

  /// Color applied to each star icon.
  final Color starColor;

  /// Logical size of each star icon.
  final double iconSize;

  /// When true, stars are not tappable.
  final bool readOnly;

  /// Enables half-step selection and half-star icons when interactive.
  final bool allowHalfSteps;

  /// Called when the user selects a new rating (interactive mode only).
  final ValueChanged<double>? onRatingChanged;

  /// When true, fractional [value] renders with [Icons.star_half] (display only).
  final bool useHalfStarDisplay;

  IconData _iconForIndex(int index) {
    if (useHalfStarDisplay) {
      if (index + 1 <= value) {
        return Icons.star;
      }
      if (index < value) {
        return Icons.star_half;
      }
      return Icons.star_border;
    }

    if (index < value) {
      return Icons.star;
    }
    return Icons.star_border;
  }

  IconData _interactiveIconForIndex(int index) {
    final starValue = index + 1;
    if (value >= starValue) {
      return Icons.star;
    }
    if (allowHalfSteps && value >= starValue - 0.5) {
      return Icons.star_half;
    }
    return Icons.star_border;
  }

  void _handleTap(int index) {
    onRatingChanged?.call(index + 1.0);
  }

  void _handleTapUp(int index, TapUpDetails details, RenderBox box) {
    final isHalf = details.localPosition.dx < box.size.width / 2;
    final next = isHalf ? index + 0.5 : index + 1.0;
    onRatingChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max.toInt(), (index) {
        final iconData = readOnly
            ? _iconForIndex(index)
            : _interactiveIconForIndex(index);
        final icon = Icon(
          iconData,
          color: starColor,
          size: iconSize,
        );

        if (readOnly || onRatingChanged == null) {
          return icon;
        }

        if (allowHalfSteps) {
          return Builder(
            builder: (starContext) {
              return GestureDetector(
                onTapUp: (details) {
                  final box = starContext.findRenderObject();
                  if (box is! RenderBox) {
                    return;
                  }
                  _handleTapUp(index, details, box);
                },
                child: icon,
              );
            },
          );
        }

        return GestureDetector(
          onTap: () => _handleTap(index),
          child: icon,
        );
      }),
    );
  }
}
