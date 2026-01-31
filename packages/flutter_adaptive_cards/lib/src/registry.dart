import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_element.dart';
import 'package:flutter_adaptive_cards/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards/src/containers/column_set.dart';
import 'package:flutter_adaptive_cards/src/containers/container.dart';
import 'package:flutter_adaptive_cards/src/containers/fact_set.dart';
import 'package:flutter_adaptive_cards/src/containers/image_set.dart';
import 'package:flutter_adaptive_cards/src/containers/table.dart';
import 'package:flutter_adaptive_cards/src/elements/accordion.dart';
import 'package:flutter_adaptive_cards/src/elements/action_set.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/execute.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/insert_image.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/open_url.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/open_url_dialog.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/popover.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/reset_inputs.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/show_card.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/submit.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/toggle_visibility.dart';
import 'package:flutter_adaptive_cards/src/elements/badge.dart';
import 'package:flutter_adaptive_cards/src/elements/carousel.dart';
import 'package:flutter_adaptive_cards/src/elements/charts/bar_chart.dart';
import 'package:flutter_adaptive_cards/src/elements/charts/line_chart.dart';
import 'package:flutter_adaptive_cards/src/elements/charts/pie_donut_chart.dart';
import 'package:flutter_adaptive_cards/src/elements/code_block.dart';
import 'package:flutter_adaptive_cards/src/elements/compound_button.dart';
import 'package:flutter_adaptive_cards/src/elements/image.dart';
import 'package:flutter_adaptive_cards/src/elements/media.dart';
import 'package:flutter_adaptive_cards/src/elements/progress_bar.dart';
import 'package:flutter_adaptive_cards/src/elements/progress_ring.dart';
import 'package:flutter_adaptive_cards/src/elements/rating.dart';
import 'package:flutter_adaptive_cards/src/elements/tab_set.dart';
import 'package:flutter_adaptive_cards/src/elements/text_block.dart';
import 'package:flutter_adaptive_cards/src/elements/unknown.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards/src/inputs/date.dart';
import 'package:flutter_adaptive_cards/src/inputs/number.dart';
import 'package:flutter_adaptive_cards/src/inputs/text.dart';
import 'package:flutter_adaptive_cards/src/inputs/time.dart';
import 'package:flutter_adaptive_cards/src/inputs/toggle.dart';

typedef ElementCreator = Widget Function(Map<String, dynamic> map);

/// Entry point for registering adaptive cards
///
/// 1. Providing custom elements
/// Add the element to [addedElements]. It takes the name of the element
/// as its key and it takes a function which generates an [AdaptiveElement] with
/// a given map and a widgetState
///
/// 2. Overwriting custom elements
/// Just use the same name as the element you want to override
///
/// 3. Deleting existing elements
///
/// Delete an element even if you have provided it yourself via the [addedElements]
///
class CardTypeRegistry {
  const CardTypeRegistry({
    this.removedElements = const [],
    this.addedElements = const {},
    this.addedActions = const {},
    this.listView = false,
    this.supportMarkdown = true,
  });

  /// Provide custom elements to use.
  /// When providing an element which is already defined, it is overwritten
  final Map<String, ElementCreator> addedElements;

  final Map<String, ElementCreator> addedActions;

  /// Remove specific elements from the list
  final List<String> removedElements;

  // Due to https://github.com/flutter/flutter_markdown/issues/171,
  // markdown support doesn't work at the same time as content alignment in a column set
  final bool supportMarkdown;

  final bool listView;

  ///
  /// Gets an element from the type registry based on the 'type' property of the map
  ///
  Widget getElement({
    required Map<String, dynamic> map,
    String parentMode = 'stretch',
  }) {
    final String stringType = map['type'] as String;

    if (removedElements.contains(stringType)) {
      return AdaptiveUnknown(
        type: stringType,
        adaptiveMap: map,
      );
    }

    if (addedElements.containsKey(stringType)) {
      return addedElements[stringType]!(map);
    } else {
      return _getBaseElement(
        map: map,
        parentMode: parentMode,
        supportMarkdown: supportMarkdown,
      );
    }
  }

  Widget getAction({
    required Map<String, dynamic> map,
  }) {
    final String stringType = map['type'] as String;

    if (removedElements.contains(stringType)) {
      return AdaptiveUnknown(
        adaptiveMap: map,
        type: stringType,
      );
    }

    if (addedActions.containsKey(stringType)) {
      return addedActions[stringType]!(map);
    }

    return _getActionWidget(map: map);
  }

  /// This returns an [AdaptiveElement] with the correct type.
  ///
  /// It looks at the 'type' property and decides which object to construct
  Widget _getBaseElement({
    required Map<String, dynamic> map,
    String parentMode = 'stretch',
    required bool supportMarkdown,
  }) {
    final String stringType = map['type'] as String;

    switch (stringType) {
      case 'Media':
        return AdaptiveMedia(adaptiveMap: map);
      case 'Container':
        return AdaptiveContainer(adaptiveMap: map);
      case 'TextBlock':
        return AdaptiveTextBlock(
          adaptiveMap: map,
          supportMarkdown: supportMarkdown,
        );
      case 'ActionSet':
        return ActionSet(adaptiveMap: map);
      case 'AdaptiveCard':
        return AdaptiveCardElement(
          adaptiveMap: map,
          listView: listView,
        );
      case 'ColumnSet':
        return AdaptiveColumnSet(
          adaptiveMap: map,
          supportMarkdown: supportMarkdown,
        );
      case 'Image':
        return AdaptiveImage(
          adaptiveMap: map,
          parentMode: parentMode,
          supportMarkdown: supportMarkdown,
        );
      case 'FactSet':
        return AdaptiveFactSet(adaptiveMap: map);
      case 'Table':
        return AdaptiveTable(
          adaptiveMap: map,
          supportMarkdown: supportMarkdown,
        );
      case 'ImageSet':
        return AdaptiveImageSet(
          adaptiveMap: map,
          supportMarkdown: supportMarkdown,
        );
      case 'Input.Text':
        return AdaptiveTextInput(adaptiveMap: map);
      case 'Input.Number':
        return AdaptiveNumberInput(adaptiveMap: map);
      case 'Input.Date':
        return AdaptiveDateInput(adaptiveMap: map);
      case 'Input.Time':
        return AdaptiveTimeInput(adaptiveMap: map);
      case 'Input.Toggle':
        return AdaptiveToggle(adaptiveMap: map);
      case 'Input.ChoiceSet':
        return AdaptiveChoiceSet(adaptiveMap: map);

      // New Elements
      case 'Badge':
        return AdaptiveBadge(adaptiveMap: map);
      case 'Rating':
      case 'Input.Rating': // Just in case
        return AdaptiveRating(adaptiveMap: map);
      case 'CodeBlock':
        return AdaptiveCodeBlock(adaptiveMap: map);
      case 'ProgressBar':
        return AdaptiveProgressBar(adaptiveMap: map);
      case 'ProgressRing':
        return AdaptiveProgressRing(adaptiveMap: map);
      case 'CompoundButton':
        return AdaptiveCompoundButton(
          adaptiveMap: map,
        );
      case 'Carousel':
        return AdaptiveCarousel(adaptiveMap: map);
      case 'CarouselPage':
        return AdaptiveCarouselPage(adaptiveMap: map);
      case 'Accordion':
        return AdaptiveAccordion(adaptiveMap: map);
      case 'TabSet':
      case 'TabPage': // Fallback if TabPage is used as container or we map it to TabSet
        // Actually "TabPage" is likely a child. But if user used "Other" for type...
        // Let's support TabSet as the container.
        return AdaptiveTabSet(adaptiveMap: map);

      // Charts
      case 'Chart.Donut':
        return AdaptivePieChart(
          adaptiveMap: map,
          isDonut: true,
        );
      case 'Chart.Pie':
        return AdaptivePieChart(
          adaptiveMap: map,
          isDonut: false,
        );
      case 'Chart.Gauge':
        // Implementing Gauge as Donut for now (or Pie)
        return AdaptivePieChart(
          adaptiveMap: map,
          isDonut: true,
        );

      case 'Chart.Line':
        return AdaptiveLineChart(adaptiveMap: map);

      case 'Chart.VerticalBar':
        return AdaptiveBarChart(
          adaptiveMap: map,
          type: BarChartType.vertical,
        );
      case 'Chart.HorizontalBar':
        return AdaptiveBarChart(
          adaptiveMap: map,
          type: BarChartType.horizontal,
        );
      case 'Chart.HorizontalBar.Stacked':
        return AdaptiveBarChart(
          adaptiveMap: map,
          type: BarChartType.horizontalStacked,
        );
      case 'Chart.VerticalBar.Grouped':
        return AdaptiveBarChart(
          adaptiveMap: map,
          type: BarChartType.grouped,
        );
    }
    return AdaptiveUnknown(
      adaptiveMap: map,
      type: stringType,
    );
  }

  Widget _getActionWidget({
    required Map<String, dynamic> map,
  }) {
    final String stringType = map['type'] as String;

    switch (stringType) {
      case 'Action.ShowCard':
        return AdaptiveActionShowCard(
          adaptiveMap: map,
        );
      case 'Action.OpenUrl':
        return AdaptiveActionOpenUrl(
          adaptiveMap: map,
        );
      case 'Action.Submit':
        return AdaptiveActionSubmit(adaptiveMap: map);
      case 'Action.Execute':
        return AdaptiveActionExecute(
          adaptiveMap: map,
        );
      case 'Action.ResetInputs':
        return AdaptiveActionResetInputs(
          adaptiveMap: map,
        );
      case 'Action.Popover':
        return AdaptiveActionPopover(
          adaptiveMap: map,
        );
      case 'Action.OpenUrlDialog':
        return AdaptiveActionOpenUrlDialog(
          adaptiveMap: map,
        ); // Custom wrapper
      case 'Action.ToggleVisibility':
        return AdaptiveActionToggleVisibility(
          adaptiveMap: map,
        );
      case 'Action.InsertImage':
        return AdaptiveActionInsertImage(
          adaptiveMap: map,
        );
      default:
        assert(false, 'No action found with type $stringType');
        return AdaptiveUnknown(
          adaptiveMap: map,
          type: stringType,
        );
    }
  }
}
