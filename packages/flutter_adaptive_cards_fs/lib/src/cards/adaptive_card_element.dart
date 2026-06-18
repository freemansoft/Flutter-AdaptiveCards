import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_handler.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/show_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_adaptive_cards_fs/src/models/refresh_config.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/card_width_scope.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The implementation of the `AdaptiveCard` card type.
///
/// This is actually classified under _cards_ and not _elements_ in the taxonomy
/// https://adaptivecards.io/explorer/
class AdaptiveCardElement extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates the root `AdaptiveCard` element from [adaptiveMap].
  ///
  /// When [listView] is true, body children are laid out in a [ListView].
  AdaptiveCardElement({
    required this.adaptiveMap,
    required this.listView,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;
  @override
  late final String id;

  /// Whether body content uses a scrollable [ListView] instead of a [Column].
  final bool listView;

  @override
  AdaptiveCardElementState createState() => AdaptiveCardElementState();
}

/// State for [AdaptiveCardElement].
class AdaptiveCardElementState extends State<AdaptiveCardElement>
    with AdaptiveElementMixin, ProviderScopeMixin {
  /// Adaptive Card schema `version` string from [adaptiveMap].
  String? version;

  /// Body elements resolved from `body` via the card type registry.
  late List<Widget> bodyChildren;

  /// Card-level primary action widgets rendered inline below the body.
  List<Widget> activeActions = [];

  /// Card-level overflow action widgets (secondary mode or beyond maxActions),
  /// revealed via the "•••" toggle. No action is silently discarded.
  List<Widget> overflowActions = [];

  /// Whether the overflow action panel is currently expanded.
  bool _overflowExpanded = false;

  /// `Action.ShowCard` instances among [activeActions].
  List<AdaptiveActionShowCard> showCardActions = [];

  /// Nested card elements targeted by [showCardActions].
  List<AdaptiveCardElement> showCardTargetElements = [];

  /// Layout axis for card-level actions from HostConfig `actions.orientation`.
  late Axis actionsOrientation;

  /// Support only one form per AdaptiveCardElement
  final formKey = GlobalKey<FormState>();

  RefreshConfig? _refreshConfig;
  var _refreshFired = false;
  var _expireRefreshScheduled = false;

  /// "metadata": {
  ///   "webUrl": "https://example.com/card-content"
  /// },
  String? get metadataUrl => adaptiveMap['metadata']?['webUrl']?.toString();

  @override
  void initState() {
    super.initState();

    version = adaptiveMap['version']?.toString();
    final refreshRaw = adaptiveMap['refresh'];
    if (refreshRaw is Map) {
      _refreshConfig = RefreshConfig.fromJson(
        Map<String, dynamic>.from(refreshRaw),
      );
    }
    // developer.log(
    //   format('AdaptiveCardElement: {} version: {}', id, version ?? ''),
    //   name: runtimeType.toString(),
    // );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bodyChildren =
        List<Map<String, dynamic>>.from(
              adaptiveMap['body'],
            )
            .map(
              (map) => cardTypeRegistry.getElement(
                map: map,
              ),
            )
            .toList();
    final String stringAxis = styleResolver.resolveOrientation(null);
    actionsOrientation = stringAxis == 'Vertical'
        ? Axis.vertical
        : Axis.horizontal;
    _maybeScheduleExpireRefresh();
  }

  void _maybeScheduleExpireRefresh() {
    if (_refreshFired || _expireRefreshScheduled) return;
    final expires = _refreshConfig?.expires;
    if (expires == null || !DateTime.now().isAfter(expires)) return;
    if (!_shouldAutoRefreshForUser()) return;
    _expireRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _refreshFired) return;
      _triggerRefresh(manual: false);
    });
  }

  bool _shouldAutoRefreshForUser() {
    final userIds = _refreshConfig?.userIds;
    if (userIds == null || userIds.isEmpty) return true;
    final currentUserId = ProviderScope.containerOf(
      context,
    ).read(currentUserIdProvider);
    return currentUserId != null && userIds.contains(currentUserId);
  }

  void _triggerRefresh({required bool manual}) {
    if (_refreshFired && !manual) return;
    final actionMap = _refreshConfig?.action;
    if (actionMap == null) return;
    if (!manual && !_shouldAutoRefreshForUser()) return;

    final container = ProviderScope.containerOf(context);
    final values = container
        .read(adaptiveCardDocumentProvider.notifier)
        .collectInputValues();
    final data = mergeActionData(
      actionData: (actionMap['data'] as Map<String, dynamic>?) != null
          ? Map<String, dynamic>.from(actionMap['data'] as Map)
          : <String, dynamic>{},
      inputValues: values,
      associatedInputs: actionMap['associatedInputs'] as String?,
    );
    final invoke = RefreshActionInvoke.fromActionMap(actionMap, data);

    final handlers = InheritedAdaptiveCardHandlers.of(context);
    if (handlers?.onRefresh != null) {
      handlers!.onRefresh!(invoke);
    } else if (handlers != null) {
      handlers.onExecute(ExecuteActionInvoke.fromActionMap(actionMap, data));
    }

    if (!manual) {
      _refreshFired = true;
    }
  }

  /// Resolves card-level actions into [activeActions] (primary) and
  /// [overflowActions] (secondary-mode or beyond the HostConfig maxActions).
  ///
  /// This is for actions directly on an AdaptiveCardElement.
  /// Not to be confused with actions in the body of an AdaptiveCardElement or
  /// on ActionSets.
  void loadNonBodyChildren() {
    if (adaptiveMap.containsKey('actions')) {
      final actionsConfig = styleResolver.getActionsConfig();
      final int maxActions = actionsConfig?.maxActions ?? 10;

      final List<Map<String, dynamic>> allMaps =
          List<Map<String, dynamic>>.from(adaptiveMap['actions'] ?? []);

      final List<Map<String, dynamic>> primaryMaps = [];
      final List<Map<String, dynamic>> overflowMaps = [];
      for (final map in allMaps) {
        final isSecondary =
            map['mode']?.toString().toLowerCase() == 'secondary';
        if (isSecondary || primaryMaps.length >= maxActions) {
          overflowMaps.add(map);
        } else {
          primaryMaps.add(map);
        }
      }

      activeActions = primaryMaps
          .map((map) => cardTypeRegistry.getAction(map: map))
          .toList();
      overflowActions = overflowMaps
          .map((map) => cardTypeRegistry.getAction(map: map))
          .toList();

      // Track ShowCard targets from both primary and overflow actions so a
      // secondary-mode ShowCard still expands its card once revealed.
      showCardActions = List<AdaptiveActionShowCard>.from(
        [
          ...activeActions.whereType<AdaptiveActionShowCard>(),
          ...overflowActions.whereType<AdaptiveActionShowCard>(),
        ],
      );
      showCardTargetElements = List<AdaptiveCardElement>.from(
        showCardActions
            .map(
              (action) =>
                  cardTypeRegistry.getElement(
                        map: action.adaptiveMap['card'],
                      )
                      as AdaptiveCardElement,
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // developer.log(
    //   'Building AdaptiveCardElement $id with ${bodyChildren.length} children',
    //   name: runtimeType.toString(),
    // );
    loadNonBodyChildren();

    final List<Widget> bodyItems = bodyChildren
        .map((element) => element)
        .toList();

    final Widget actionWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          direction: actionsOrientation,
          children: [
            ...activeActions,
            if (overflowActions.isNotEmpty)
              IconButton(
                key: const Key('action_set_overflow'),
                icon: const Icon(Icons.more_horiz),
                tooltip: 'More actions',
                onPressed: () =>
                    setState(() => _overflowExpanded = !_overflowExpanded),
              ),
          ],
        ),
        if (_overflowExpanded && overflowActions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: overflowActions,
          ),
      ],
    );

    // The action strip and expanded show-card host render below the body.
    final List<Widget> trailingWidgets = [
      actionWidget,
      Consumer(
        builder: (context, ref, _) {
          final expandedId = ref.watch(expandedShowCardIdProvider);
          if (expandedId == null) return const SizedBox.shrink();
          final target = showCardTargetElements.where(
            (c) => c.id == expandedId,
          );
          if (target.isEmpty) return const SizedBox.shrink();
          return target.first;
        },
      ),
    ];

    // Body items honor an optional root `layouts` array (Layout.Flow) chosen for
    // the current card width; reads CardWidthScope below, so it reflows on
    // resize. The listView path stays a flat list (Flow not applied there).
    final Widget bodyLayout = _AdaptiveCardBody(
      bodyItems: bodyItems,
      layouts: adaptiveMap['layouts'] as List<dynamic>?,
      styleResolver: styleResolver,
    );

    // default to result without a background image
    Widget result = Container(
      margin: const EdgeInsets.all(8),
      child: widget.listView
          ? ListView(
              shrinkWrap: true,
              children: [...bodyItems, ...trailingWidgets],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bodyLayout, ...trailingWidgets],
            ),
    );

    if (_refreshConfig?.action != null) {
      result = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _RefreshAffordance(
              onPressed: () => _triggerRefresh(manual: true),
            ),
          ),
          result,
        ],
      );
    }

    final backgroundImage = getBackgroundImageFromMap(adaptiveMap);

    // replace the result with a stack if there is a background image
    if (backgroundImage != null) {
      // wrap result in a stack with the background image
      result = Stack(
        children: <Widget>[
          Positioned.fill(
            child: backgroundImage,
          ),
          result,
        ],
      );
    }

    // The ProviderScope stays outermost and stable (not rebuilt by layout).
    // The width-derived bucket is published via a CardWidthScope inside the
    // LayoutBuilder, since it needs the card's measured width.
    return ProviderScope(
      overrides: [
        adaptiveCardElementStateProvider.overrideWithValue(this),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final WidthBucket bucket =
              styleResolver.resolveWidthBucket(constraints.maxWidth);
          return CardWidthScope(
            bucket: bucket,
            child: AdaptiveTappable(
              adaptiveMap: adaptiveMap,
              child: Form(key: formKey, child: result),
            ),
          );
        },
      ),
    );
  }
}

/// Lays out the card's body items, applying a root `Layout.Flow` when one in
/// the card's `layouts` array matches the current width bucket.
///
/// Reads [CardWidthScope] from the build context, so it reflows when the card
/// crosses a width boundary. Falls back to a vertical stack otherwise.
class _AdaptiveCardBody extends StatelessWidget {
  const _AdaptiveCardBody({
    required this.bodyItems,
    required this.layouts,
    required this.styleResolver,
  });

  final List<Widget> bodyItems;
  final List<dynamic>? layouts;
  final ReferenceResolver styleResolver;

  @override
  Widget build(BuildContext context) {
    final selected = selectLayout(layouts, CardWidthScope.of(context));
    if (selected != null && selected['type'] == 'Layout.Flow') {
      return AdaptiveFlowLayout(
        layoutMap: selected,
        styleResolver: styleResolver,
        children: bodyItems,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bodyItems,
    );
  }
}

/// Manual refresh control shown when root card JSON defines `refresh.action`.
class _RefreshAffordance extends StatelessWidget {
  const _RefreshAffordance({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Refresh card',
      child: IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh card',
        onPressed: onPressed,
      ),
    );
  }
}
