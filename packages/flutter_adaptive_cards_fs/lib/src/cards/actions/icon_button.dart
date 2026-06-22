import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared elevated-button renderer for Adaptive Card actions.
///
/// Reads title, style, `iconUrl`, and tooltip from [adaptiveMap] and invokes
/// [onTapped] when the action is enabled.
class IconButtonAction extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates an action button for [adaptiveMap] that calls [onTapped] on press.
  IconButtonAction({
    required this.adaptiveMap,
    required this.onTapped,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  /// Invoked when the user taps the button and the action is enabled.
  final void Function(BuildContext context) onTapped;

  @override
  IconButtonActionState createState() => IconButtonActionState();
}

/// State for [IconButtonAction].
class IconButtonActionState extends ConsumerState<IconButtonAction>
    with
        AdaptiveActionMixin,
        AdaptiveActionStateMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  @override
  Widget build(BuildContext context) {
    final resolver = styleResolver;
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: resolver.resolveButtonBackgroundColor(
        context: context,
        style: style,
      ),
      foregroundColor: resolver.resolveButtonForegroundColor(
        context: context,
        style: style,
      ),
    );

    final onPressed = actionEnabled ? () => widget.onTapped(context) : null;
    final resolvedIconUrl = iconUrl;

    final iconPlacement =
        resolver.getActionsConfig()?.iconPlacement ?? 'aboveTitle';

    Widget theButton;
    if (resolvedIconUrl == null) {
      theButton = ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Text(title),
      );
    } else if (iconPlacement == 'aboveTitle') {
      theButton = ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdaptiveImageUtils.getImage(
              resolvedIconUrl,
              height: 24,
              semanticsLabel: title,
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      );
    } else {
      theButton = ElevatedButton.icon(
        onPressed: onPressed,
        style: buttonStyle,
        icon: AdaptiveImageUtils.getImage(
          resolvedIconUrl,
          height: 36,
          semanticsLabel: title,
        ),
        label: Text(title),
      );
    }

    final wrappedButton = (tooltip != null)
        ? Tooltip(
            message: tooltip,
            child: theButton,
          )
        : theButton;

    final result = Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: wrappedButton,
      ),
    );

    return result;
  }
}
