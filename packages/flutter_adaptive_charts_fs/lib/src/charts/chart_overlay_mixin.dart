import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listens to [resolvedElementProvider] and reparses chart state on overlay changes.
mixin ChartOverlayMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Stable element id; provided by [AdaptiveElementMixin] when mixed in.
  String get id;

  /// Baseline element JSON; provided by [AdaptiveElementMixin] when mixed in.
  Map<String, dynamic> get adaptiveMap;

  bool _chartMixinInitialized = false;

  /// Baseline JSON merged with chart overlays for this element [id].
  ///
  /// Uses [ref.read] (non-watching) so it is safe to call from
  /// [didChangeDependencies] and [build] callbacks.
  Map<String, dynamic> get resolvedChartMap =>
      ref.read(resolvedElementProvider(id)) ?? adaptiveMap;

  /// Subclasses reparsed chart fields from [resolvedChartMap].
  void onResolvedChartChanged();

  /// Performs the initial chart parse once, after the widget is fully mounted.
  ///
  /// Must run in [didChangeDependencies] rather than [initState] because
  /// [onResolvedChartChanged] implementations (e.g. [_parseSegments]) access
  /// [styleResolver] via [ProviderScope.containerOf], which calls
  /// [dependOnInheritedWidgetOfExactType] — forbidden inside [initState].
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_chartMixinInitialized) {
      _chartMixinInitialized = true;
      onResolvedChartChanged();
    }
  }

  /// Call at the top of [build] to subscribe to overlay changes.
  void listenForChartOverlayChanges() {
    ref.listen<Map<String, dynamic>?>(
      resolvedElementProvider(id),
      (previous, next) {
        onResolvedChartChanged();
        if (mounted) setState(() {});
      },
    );
  }
}
