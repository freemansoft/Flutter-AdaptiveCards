import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listens to [resolvedElementProvider] and reparses chart state on overlay changes.
mixin ChartOverlayMixin<T extends AdaptiveElementWidgetMixin> on State<T>,
    AdaptiveElementMixin<T>, ProviderScopeMixin<T> {
  ProviderSubscription<Map<String, dynamic>?>? _chartSubscription;

  /// Baseline JSON merged with chart overlays for this element [id].
  Map<String, dynamic> get resolvedChartMap {
    final container = ProviderScope.containerOf(context);
    return container.read(resolvedElementProvider(id)) ?? adaptiveMap;
  }

  /// Subclasses reparsed chart fields from [resolvedChartMap].
  void onResolvedChartChanged();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chartSubscription?.close();
    final container = ProviderScope.containerOf(context);
    _chartSubscription = container.listen<Map<String, dynamic>?>(
      resolvedElementProvider(id),
      (previous, next) {
        onResolvedChartChanged();
        if (mounted) {
          setState(() {});
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _chartSubscription?.close();
    _chartSubscription = null;
    super.dispose();
  }
}
