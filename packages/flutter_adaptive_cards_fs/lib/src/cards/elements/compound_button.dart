import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the Adaptive Cards **CompoundButton** element.
///
/// See https://adaptivecards.io/explorer/CompoundButton.html
class AdaptiveCompoundButton extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a compound button from [adaptiveMap] JSON.
  AdaptiveCompoundButton({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveCompoundButtonState createState() => AdaptiveCompoundButtonState();
}

/// State for [AdaptiveCompoundButton]; lays out icon, title, and description.
class AdaptiveCompoundButtonState extends ConsumerState<AdaptiveCompoundButton>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Primary label from `title`.
  late String title;

  /// Optional secondary text from `description`.
  late String? description;

  /// Optional leading image URL from `iconUrl`.
  late String? iconUrl;

  /// Optional short badge label from `badge`.
  late String? badge;

  /// Resolved handler for the optional `selectAction`, if present.
  ///
  /// When absent the button has nothing to do and renders disabled.
  GenericAction? selectAction;

  @override
  void initState() {
    super.initState();
    title = adaptiveMap['title']?.toString() ?? '';
    description = adaptiveMap['description']?.toString();
    iconUrl = adaptiveMap['iconUrl']?.toString();
    badge = adaptiveMap['badge']?.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The selectAction could be any of the action types, so resolve it via the
    // registry the same way AdaptiveTappable does for element selectActions.
    if (adaptiveMap.containsKey('selectAction')) {
      selectAction = actionTypeRegistry.getActionForType(
        map: adaptiveMap['selectAction'] as Map<String, dynamic>,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolver = styleResolver;
    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: ElevatedButton(
          onPressed: selectAction == null
              ? null
              : () => selectAction!.tap(
                    context: context,
                    rawAdaptiveCardState: rawRootCardWidgetState,
                    adaptiveMap:
                        adaptiveMap['selectAction'] as Map<String, dynamic>,
                  ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Row(
            children: [
              if (iconUrl != null) ...[
                AdaptiveImageUtils.getImage(iconUrl!, width: 40, height: 40),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: resolver.resolveCompoundButtonTitleStyle(),
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: resolver.resolveCompoundButtonDescriptionStyle(),
                      ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
