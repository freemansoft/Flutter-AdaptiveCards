// ignore_for_file: prefer_single_quotes

import 'package:flutter/material.dart';

import '../../adaptive_mixins.dart';

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
    iconUrl = adaptiveMap["iconUrl"];
  }

  @override
  Widget build(BuildContext context) {
    Widget result = ElevatedButton(onPressed: onTapped, child: Text(title));

    if (iconUrl != null) {
      result = ElevatedButton.icon(
        onPressed: onTapped,
        icon: Image.network(iconUrl!, height: 36.0),
        label: Text(title),
      );
    }
    return result;
  }

  @override
  void onTapped() => widget.onTapped();
}
