import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_handler.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/show_card.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/stretchable_column.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_adaptive_cards_fs/src/models/authentication_config.dart';
import 'package:flutter_adaptive_cards_fs/src/models/refresh_config.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The implementation of the `AdaptiveCard` card type.
///
/// This is actually classified under _cards_ and not _elements_ in the taxonomy
/// https://adaptivecards.io/explorer/
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/adaptive-card
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

  /// Raw body JSON, index-aligned with [bodyChildren].
  late List<Map<String, dynamic>> bodyMaps;

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
  AuthenticationConfig? _authConfig;
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
    final authRaw = adaptiveMap['authentication'];
    if (authRaw is Map) {
      _authConfig = AuthenticationConfig.fromJson(
        Map<String, dynamic>.from(authRaw),
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
    bodyMaps = List<Map<String, dynamic>>.from(adaptiveMap['body']);
    bodyChildren = bodyMaps
        .map((map) => cardTypeRegistry.getElement(map: map))
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

  void _triggerSignin(AuthCardButton button) {
    if (button.type.toLowerCase() != 'signin') {
      assert(() {
        developer.log(
          'Ignoring non-signin authentication button: ${button.type}',
          name: runtimeType.toString(),
        );
        return true;
      }());
      return;
    }

    final invoke = SigninActionInvoke.fromButton(
      button,
      connectionName: _authConfig?.connectionName,
    );

    final handlers = InheritedAdaptiveCardHandlers.of(context);
    if (handlers?.onSignin != null) {
      handlers!.onSignin!(invoke);
      return;
    }

    final value = invoke.value;
    if (handlers != null && value.startsWith('http')) {
      handlers.onOpenUrl(OpenUrlActionInvoke(url: value));
      return;
    }

    assert(() {
      developer.log(
        'authentication sign-in tapped but no onSignin handler '
        'and value is not a URL: $value',
        name: runtimeType.toString(),
      );
      return true;
    }());
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
    // developer.log( 'Building AdaptiveCardElement $id with
    // ${bodyChildren.length} children', name: runtimeType.toString(), );
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

    // Body items honor an optional root `layouts` array (Layout.Flow) chosen
    // for the current card width; reads cardWidthBucketProvider below, so it
    // reflows on resize. The listView path stays a flat list (Flow not applied
    // there).
    final Widget bodyLayout = _AdaptiveCardBody(
      bodyItems: bodyItems,
      childMaps: bodyMaps,
      layouts: adaptiveMap['layouts'] as List<dynamic>?,
      styleResolver: styleResolver,
    );

    // Sign-in region (root `authentication`) renders between the body and the
    // action strip. Built here so both the listView and Column paths place it
    // in the same spot.
    final Widget? authRegion =
        (_authConfig != null && _authConfig!.buttons.isNotEmpty)
        ? _AuthenticationRegion(
            config: _authConfig!,
            onSignin: _triggerSignin,
          )
        : null;

    // default to result without a background image
    Widget result = Container(
      margin: const EdgeInsets.all(8),
      child: widget.listView
          ? ListView(
              shrinkWrap: true,
              children: [
                ...bodyItems,
                ?authRegion,
                ...trailingWidgets,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bodyLayout,
                ?authRegion,
                ...trailingWidgets,
              ],
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

    // Hoist the card subtree into ONE stable widget instance, captured by the
    // closure below. Because it is built once per `build()` (not per layout
    // pass) and passed by identity to the inner ProviderScope, Flutter reuses
    // its element and does not rebuild the subtree when only the width changes.
    final Widget cardBody = AdaptiveTappable(
      adaptiveMap: adaptiveMap,
      child: Form(key: formKey, child: result),
    );

    // Two scopes (see the responsive design doc, weakness W2):
    // - OUTER ProviderScope is stable (document state, registries, element
    //   state); it is never rebuilt by layout.
    // - INNER ProviderScope inside the LayoutBuilder publishes the
    //   width-derived bucket via overrideWithValue. It is re-created each
    //   layout pass (a trivial allocation) but its element/container persist,
    //   its `child` is the stable [cardBody], and overrideWithValue only
    //   notifies watchers when the bucket actually changes — so no per-pass
    //   subtree rebuild and no frame lag.
    return ProviderScope(
      overrides: [
        adaptiveCardElementStateProvider.overrideWithValue(this),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final WidthBucket bucket = styleResolver.resolveWidthBucket(
            constraints.maxWidth,
          );
          return ProviderScope(
            overrides: [
              cardWidthBucketProvider.overrideWithValue(bucket),
            ],
            child: cardBody,
          );
        },
      ),
    );
  }
}

/// Lays out the card's body items, applying a root `Layout.Flow` when one in
/// the card's `layouts` array matches the current width bucket.
///
/// Watches [cardWidthBucketProvider], so it reflows when the card crosses a
/// width boundary. Falls back to a vertical stack otherwise.
class _AdaptiveCardBody extends ConsumerWidget {
  const _AdaptiveCardBody({
    required this.bodyItems,
    required this.childMaps,
    required this.layouts,
    required this.styleResolver,
  });

  final List<Widget> bodyItems;

  /// Raw body JSON, index-aligned with [bodyItems].
  final List<Map<String, dynamic>> childMaps;
  final List<dynamic>? layouts;
  final ReferenceResolver styleResolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return buildLayoutChildren(
      layouts: layouts,
      bucket: ref.watch(cardWidthBucketProvider),
      styleResolver: styleResolver,
      children: bodyItems,
      childMaps: childMaps,
      stackBuilder: (items) => buildStretchableColumn(
        childMaps: childMaps,
        children: items,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

/// Sign-in affordance shown when root card JSON defines `authentication`.
///
/// Renders the optional prompt text and one button per
/// [AuthenticationConfig.buttons] entry.
class _AuthenticationRegion extends StatelessWidget {
  const _AuthenticationRegion({
    required this.config,
    required this.onSignin,
  });

  final AuthenticationConfig config;
  final void Function(AuthCardButton button) onSignin;

  @override
  Widget build(BuildContext context) {
    final text = config.text;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text != null && text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(text),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final button in config.buttons)
                Semantics(
                  button: true,
                  label: button.title ?? button.type,
                  child: ElevatedButton.icon(
                    icon: (button.image != null && button.image!.isNotEmpty)
                        ? Image.network(
                            button.image!,
                            width: 18,
                            height: 18,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          )
                        : const SizedBox.shrink(),
                    label: Text(button.title ?? 'Sign in'),
                    onPressed: () => onSignin(button),
                  ),
                ),
            ],
          ),
        ],
      ),
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
