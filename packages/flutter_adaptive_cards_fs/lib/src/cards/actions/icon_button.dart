import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// Shared elevated-button renderer for Adaptive Card actions.
///
/// Reads title, style, `iconUrl`, and tooltip from [adaptiveMap] and invokes
/// [onTapped] when the action is enabled.
class IconButtonAction extends StatefulWidget with AdaptiveElementWidgetMixin {
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
class IconButtonActionState extends State<IconButtonAction>
    with
        AdaptiveActionMixin,
        AdaptiveActionStateMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  /// Optional `iconUrl` from the action JSON, shown beside the title.
  late String? iconUrl;

  @override
  void initState() {
    super.initState();
    iconUrl = adaptiveMap['iconUrl'] as String?;
  }

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

    final theButton = (iconUrl != null)
        ? ElevatedButton.icon(
            onPressed: onPressed,
            style: buttonStyle,
            icon: AdaptiveImageUtils.getImage(
              iconUrl!,
              height: 36,
              semanticsLabel: title,
            ),
            label: Text(title),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(title),
          );

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
