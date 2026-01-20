import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

class IconButtonAction extends StatefulWidget with AdaptiveElementWidgetMixin {
  IconButtonAction({
    super.key,
    required this.adaptiveMap,
    required this.onTapped,
  });

  @override
  final Map<String, dynamic> adaptiveMap;

  final VoidCallback onTapped;

  @override
  IconButtonActionState createState() => IconButtonActionState();
}

class IconButtonActionState extends State<IconButtonAction>
    with AdaptiveActionMixin, AdaptiveElementMixin {
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

    Widget result = ElevatedButton(
      onPressed: onTapped,
      style: buttonStyle,
      child: Text(title),
    );

    if (iconUrl != null) {
      result = ElevatedButton.icon(
        onPressed: onTapped,
        style: buttonStyle,
        icon: Image.network(iconUrl!, height: 36),
        label: Text(title),
      );
    }
    return result;
  }

  @override
  void onTapped() => widget.onTapped();
}
