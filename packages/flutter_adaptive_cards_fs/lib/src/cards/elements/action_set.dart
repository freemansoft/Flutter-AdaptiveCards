import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/ActionSet.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/action-set
///
/// This class is described as a _Container_ in the docs but is located in
/// elements for some reason
///
class ActionSet extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates an action set from [adaptiveMap] JSON.
  ActionSet({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  ActionSetState createState() => ActionSetState();
}

/// State for [ActionSet]; resolves and lays out child actions.
///
/// Primary actions (those without `mode: secondary` and within the HostConfig
/// maxActions limit) are shown inline. Secondary-mode actions and any actions
/// that exceed the limit are routed to an overflow panel revealed by a "•••"
/// toggle, so no action is silently discarded.
class ActionSetState extends ConsumerState<ActionSet>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Primary action widgets rendered inline in the main row.
  List<Widget> activeActions = [];

  /// Overflow action widgets (secondary mode or beyond maxActions), revealed
  /// via the "•••" toggle. These are the same self-contained action widgets
  /// as [activeActions]; they are simply deferred until the user requests them.
  List<Widget> overflowActions = [];

  bool _overflowExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolver = styleResolver;
    final actionsConfig = resolver.getActionsConfig();

    activeActions.clear();
    overflowActions.clear();
    final List actionMaps = adaptiveMap['actions'] as List<dynamic>? ?? [];
    final int maxActions = actionsConfig?.maxActions ?? 10;

    final List<Map<String, dynamic>> primaryMaps = [];
    final List<Map<String, dynamic>> overflowMaps = [];
    for (final raw in actionMaps) {
      final map = Map<String, dynamic>.from(raw as Map);
      final isSecondary = map['mode']?.toString().toLowerCase() == 'secondary';
      if (isSecondary || primaryMaps.length >= maxActions) {
        overflowMaps.add(map);
      } else {
        primaryMaps.add(map);
      }
    }

    activeActions.addAll(
      primaryMaps.map((map) => cardTypeRegistry.getAction(map: map)),
    );
    overflowActions.addAll(
      overflowMaps.map((map) => cardTypeRegistry.getAction(map: map)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolver = styleResolver;
    final actionsConfig = resolver.getActionsConfig();

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: actionsConfig?.buttonSpacing.toDouble() ?? 10,
              runSpacing: actionsConfig?.buttonSpacing.toDouble() ?? 10,
              direction:
                  actionsConfig?.actionsOrientation.toLowerCase() == 'vertical'
                  ? Axis.vertical
                  : Axis.horizontal,
              alignment: _getWrapAlignment(
                actionsConfig?.actionAlignment ?? 'left',
              ),
              children: [
                ...activeActions,
                if (overflowActions.isNotEmpty)
                  IconButton(
                    key: const Key('action_set_overflow'),
                    icon: const Icon(Icons.more_horiz),
                    tooltip: 'More actions',
                    onPressed: () => setState(
                      () => _overflowExpanded = !_overflowExpanded,
                    ),
                  ),
              ],
            ),
            if (_overflowExpanded && overflowActions.isNotEmpty)
              Wrap(
                spacing: actionsConfig?.buttonSpacing.toDouble() ?? 10,
                runSpacing: actionsConfig?.buttonSpacing.toDouble() ?? 10,
                children: overflowActions,
              ),
          ],
        ),
      ),
    );
  }

  WrapAlignment _getWrapAlignment(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'left':
        return WrapAlignment.start;
      case 'center':
        return WrapAlignment.center;
      case 'right':
        return WrapAlignment.end;
      case 'stretch':
      default:
        // Wrap doesn't have a direct "stretch" that behaves like Flex's
        // crossAxisAlignment.stretch but for actions it usually means spread or
        // start depending on orientation.
        return WrapAlignment.start;
    }
  }
}
