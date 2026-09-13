import 'package:flutter/material.dart';

/// Marker wrapper around popover card content for widget tests and tree lookup.
class const AdaptivePopoverContainer({
  super.key,

  /// Popover card subtree rendered inside the dialog.
  required final Widget child,
}) extends StatelessWidget {
  /// Creates a popover content container with [child].
  this;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
