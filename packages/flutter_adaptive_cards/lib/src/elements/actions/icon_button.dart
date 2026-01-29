import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

class IconButtonAction extends StatefulWidget with AdaptiveElementWidgetMixin {
  IconButtonAction({
    required this.adaptiveMap,
    required this.onTapped,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  final VoidCallback onTapped;

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
    final resolver = InheritedReferenceResolver.of(context).resolver;
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: resolver.resolveButtonBackgroundColor(
        context: context,
        style: adaptiveMap['style'],
      ),
      foregroundColor: resolver.resolveButtonForegroundColor(
        context: context,
        style: adaptiveMap['style'],
      ),
    );

    Widget result = Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: ElevatedButton(
          onPressed: onTapped,
          style: buttonStyle,
          child: Text(title),
        ),
      ),
    );

    if (iconUrl != null) {
      result = Visibility(
        visible: isVisible,
        child: SeparatorElement(
          adaptiveMap: adaptiveMap,
          child: ElevatedButton.icon(
            onPressed: onTapped,
            style: buttonStyle,
            icon: AdaptiveImageUtils.getImage(iconUrl!, height: 36),
            label: Text(title),
          ),
        ),
      );
    }
    return result;
  }

  @override
  void onTapped() => widget.onTapped();
}
