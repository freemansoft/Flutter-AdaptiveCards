import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/utils/adaptive_image_utils.dart';

class AdaptiveCompoundButton extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveCompoundButton({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveCompoundButtonState createState() => AdaptiveCompoundButtonState();
}

class AdaptiveCompoundButtonState extends State<AdaptiveCompoundButton>
    with AdaptiveElementMixin {
  late String title;
  late String? description;
  late String? iconUrl;

  @override
  void initState() {
    super.initState();
    title = widget.adaptiveMap['title']?.toString() ?? '';
    description = widget.adaptiveMap['description']?.toString();
    iconUrl = widget.adaptiveMap['iconUrl']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: ElevatedButton(
        onPressed: () {
          // TODO(username): What does it do? Usually triggers an action or is part of an input?
          // If it's an "Element" it might be static or act like a button?
          // If it has selectAction, we should handle it.
          // For now, no-op or check for selectAction.
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
