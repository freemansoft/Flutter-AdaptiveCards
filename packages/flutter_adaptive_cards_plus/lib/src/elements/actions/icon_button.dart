import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/additional.dart';
import 'package:flutter_adaptive_cards_plus/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IconButtonAction extends StatefulWidget with AdaptiveElementWidgetMixin {
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

  final void Function(BuildContext context) onTapped;

  @override
  IconButtonActionState createState() => IconButtonActionState();
}

class IconButtonActionState extends State<IconButtonAction>
    with AdaptiveActionMixin, AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late String? iconUrl;

  @override
  void initState() {
    super.initState();
    iconUrl = adaptiveMap['iconUrl'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final resolver = ProviderScope.containerOf(
      context,
    ).read(styleReferenceResolverProvider);
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

    final theButton = (iconUrl != null)
        ? ElevatedButton.icon(
            onPressed: () => widget.onTapped(context),
            style: buttonStyle,
            icon: AdaptiveImageUtils.getImage(
              iconUrl!,
              height: 36,
              semanticsLabel: title,
            ),
            label: Text(title),
          )
        : ElevatedButton(
            onPressed: () => widget.onTapped(context),
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
