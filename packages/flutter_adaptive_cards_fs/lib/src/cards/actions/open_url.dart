import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.OpenUrl.html
///
/// Renders `Action.OpenUrl` as an elevated button and opens the URL via the
/// host [GenericActionOpenUrl] handler.
class AdaptiveActionOpenUrl extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates an `Action.OpenUrl` widget from [adaptiveMap].
  AdaptiveActionOpenUrl({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionOpenUrlState createState() => AdaptiveActionOpenUrlState();
}

/// State for [AdaptiveActionOpenUrl].
class AdaptiveActionOpenUrlState extends State<AdaptiveActionOpenUrl>
    with AdaptiveActionMixin, AdaptiveElementMixin, ProviderScopeMixin {
  /// Resolved `Action.OpenUrl` handler from the action type registry.
  late GenericActionOpenUrl action;

  /// Optional `iconUrl` from the action JSON.
  late String? iconUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        actionTypeRegistry.getActionForType(
              map: adaptiveMap,
            )!
            as GenericActionOpenUrl;
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: (BuildContext context) {
        // [GenericActionOpenUrl]
        action.tap(
          context: context,
          rawAdaptiveCardState: rawRootCardWidgetState,
          adaptiveMap: adaptiveMap,
        );
      },
    );
  }
}
