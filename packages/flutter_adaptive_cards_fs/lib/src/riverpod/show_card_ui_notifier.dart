// The patch tool sometimes drops the trailing newline; silence until stable.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which nested card id is expanded for ShowCard UI within one
/// `AdaptiveCardElement` scope.
///
/// State is `null` when no show-card body is expanded. Scoped via
/// `expandedShowCardIdProvider` on each card-element `ProviderScope`.
class ExpandedShowCardIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Expands `targetCardId`, or collapses if it is already expanded.
  void toggle(String targetCardId) {
    state = state == targetCardId ? null : targetCardId;
  }
}
