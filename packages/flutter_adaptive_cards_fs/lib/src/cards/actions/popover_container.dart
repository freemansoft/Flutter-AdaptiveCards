import 'package:flutter/material.dart';

/// Marker wrapper around popover card content for widget tests and tree lookup.
class AdaptivePopoverContainer extends StatelessWidget {
  /// Creates a popover content container with [child].
  const AdaptivePopoverContainer({super.key, required this.child});

  /// Popover card subtree rendered inside the dialog.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
