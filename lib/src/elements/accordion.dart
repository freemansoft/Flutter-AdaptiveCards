import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';

class AdaptiveAccordion extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveAccordion({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveAccordionState createState() => AdaptiveAccordionState();
}

class AdaptiveAccordionState extends State<AdaptiveAccordion>
    with AdaptiveElementMixin {
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    // Support "items" or "pages" or whatever the schema uses.
    // User mentioned AccordionPage, so likely items are type AccordionPage.
    var rawItems = widget.adaptiveMap['items'] ?? widget.adaptiveMap['pages'];
    items = [];
    if (rawItems is List) {
      items = List<Map<String, dynamic>>.from(rawItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return SizedBox.shrink();

    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: Column(
        children: items.map((itemMap) {
          // Each item should be an AccordionPage (or similar)
          // We extract title and content from it.
          String title = itemMap['title'] ?? 'Untitled';

          // The content of the page is likely in 'items' or 'body' of the AccordionPage
          // OR the AccordionPage itself is to be rendered?
          // If we use Registry to render AccordionPage, we need AccordionPage to be a Column-like container.
          // But ExpansionTile expects a widget for body.

          // Approach: If the Registry can render AccordionPage as a widget (Column), we put it in children.
          // But AccordionPage might just be a data holder for Accordion.

          // Let's assume AccordionPage has 'items' (list of elements).
          List<Widget> children = [];
          var contentItems = itemMap['items'] ?? itemMap['body'];
          if (contentItems is List) {
            for (var c in contentItems) {
              var el = widgetState.cardRegistry.getElement(c);
              children.add(el);
            }
          }

          return ExpansionTile(
            title: Text(title),
            children: children,
          );
        }).toList(),
      ),
    );
  }
}
