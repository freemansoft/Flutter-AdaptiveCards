import 'package:flutter/material.dart';
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
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';
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
    required RawAdaptiveCardState widgetState,
    String parentMode = 'stretch',
  }) {
    final String stringType = map['type'] as String;

    if (removedElements.contains(stringType)) {
      return AdaptiveUnknown(
        type: stringType,
        adaptiveMap: map,
        widgetState: widgetState,
      );
    }

    if (addedElements.containsKey(stringType)) {
      return addedElements[stringType]!(map);
    } else {
      return _getBaseElement(
        map: map,
        widgetState: widgetState,
        parentMode: parentMode,
        supportMarkdown: supportMarkdown,
      );
    }
  }

  ///
  /// Gets an action from the action type registry based on the 'type' property of the map
  ///
  GenericAction? getGenericAction({
    required Map<String, dynamic> map,
    required RawAdaptiveCardState state,
  }) {
    final String stringType = map['type'] as String;

    switch (stringType) {
      case 'Action.ShowCard':
        assert(
          false,
          'Action.ShowCard can only be used directly by the root card',
        );
        return null;
      case 'Action.OpenUrl':
        return GenericActionOpenUrl(
          adaptiveMap: map,
          rawAdaptiveCardState: state,
        );
      case 'Action.Submit':
        return GenericSubmitAction(
          adaptiveMap: map,
          rawAdaptiveCardState: state,
        );
      case 'Action.Execute':
        return GenericExecuteAction(
          adaptiveMap: map,
          rawAdaptiveCardState: state,
        );
      case 'Action.ResetInputs':
        return GenericActionResetInputs(
          adaptiveMap: map,
          rawAdaptiveCardState: state,
        );
      case 'Action.OpenUrlDialog':
        assert(false, 'Action.OpenUrlDialog is not supported');
        return null;
      case 'Action.ToggleVisibility':
        assert(false, 'Action.ToggleVisibility is not supported');
        return null;
      case 'Action.InsertImage':
        assert(false, 'Action.InsertImage is not supported');
        return null;
      case 'Action.Popup':
        assert(false, 'Action.Popup is not supported');
        return null;
      default:
        assert(false, 'No action found with type $stringType');
        return null;
    }
  }

  Widget getAction({
    required Map<String, dynamic> map,
    required RawAdaptiveCardState state,
  }) {
    final String stringType = map['type'] as String;

    if (removedElements.contains(stringType)) {
      return AdaptiveUnknown(
        adaptiveMap: map,
        widgetState: state,
        type: stringType,
      );
    }

    if (addedActions.containsKey(stringType)) {
      return addedActions[stringType]!(map);
    }

    return _getActionWidget(map: map, widgetState: state);
  }

  /// This returns an [AdaptiveElement] with the correct type.
  ///
  /// It looks at the 'type' property and decides which object to construct
  Widget _getBaseElement({
    required Map<String, dynamic> map,
    required RawAdaptiveCardState widgetState,
    String parentMode = 'stretch',
    required bool supportMarkdown,
  }) {
    final String stringType = map['type'] as String;

    switch (stringType) {
      case 'Media':
        return AdaptiveMedia(adaptiveMap: map, widgetState: widgetState);
      case 'Container':
        return AdaptiveContainer(adaptiveMap: map, widgetState: widgetState);
      case 'TextBlock':
        return AdaptiveTextBlock(
          adaptiveMap: map,
          widgetState: widgetState,
          supportMarkdown: supportMarkdown,
        );
      case 'ActionSet':
        return ActionSet(adaptiveMap: map, widgetState: widgetState);
      case 'AdaptiveCard':
        return AdaptiveCardElement(
          adaptiveMap: map,
          widgetState: widgetState,
          listView: listView,
        );
      case 'ColumnSet':
        return AdaptiveColumnSet(
          adaptiveMap: map,
          widgetState: widgetState,
          supportMarkdown: supportMarkdown,
        );
      case 'Image':
        return AdaptiveImage(
          adaptiveMap: map,
          widgetState: widgetState,
          parentMode: parentMode,
          supportMarkdown: supportMarkdown,
        );
      case 'FactSet':
        return AdaptiveFactSet(adaptiveMap: map, widgetState: widgetState);
      case 'Table':
        return AdaptiveTable(
          adaptiveMap: map,
          widgetState: widgetState,
          supportMarkdown: supportMarkdown,
        );
      case 'ImageSet':
        return AdaptiveImageSet(
          adaptiveMap: map,
          widgetState: widgetState,
          supportMarkdown: supportMarkdown,
        );
      case 'Input.Text':
        return AdaptiveTextInput(adaptiveMap: map, widgetState: widgetState);
      case 'Input.Number':
        return AdaptiveNumberInput(adaptiveMap: map, widgetState: widgetState);
      case 'Input.Date':
        return AdaptiveDateInput(adaptiveMap: map, widgetState: widgetState);
      case 'Input.Time':
        return AdaptiveTimeInput(adaptiveMap: map, widgetState: widgetState);
      case 'Input.Toggle':
        return AdaptiveToggle(adaptiveMap: map, widgetState: widgetState);
      case 'Input.ChoiceSet':
        return AdaptiveChoiceSet(adaptiveMap: map, widgetState: widgetState);

      // New Elements
      case 'Badge':
        return AdaptiveBadge(adaptiveMap: map, widgetState: widgetState);
      case 'Rating':
      case 'Input.Rating': // Just in case
        return AdaptiveRating(adaptiveMap: map, widgetState: widgetState);
      case 'CodeBlock':
        return AdaptiveCodeBlock(adaptiveMap: map, widgetState: widgetState);
      case 'ProgressBar':
        return AdaptiveProgressBar(adaptiveMap: map, widgetState: widgetState);
      case 'ProgressRing':
        return AdaptiveProgressRing(adaptiveMap: map, widgetState: widgetState);
      case 'CompoundButton':
        return AdaptiveCompoundButton(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      case 'Carousel':
        return AdaptiveCarousel(adaptiveMap: map, widgetState: widgetState);
      case 'CarouselPage':
        return AdaptiveCarouselPage(adaptiveMap: map, widgetState: widgetState);
      case 'Accordion':
        return AdaptiveAccordion(adaptiveMap: map, widgetState: widgetState);
      case 'TabSet':
      case 'TabPage': // Fallback if TabPage is used as container or we map it to TabSet
        // Actually "TabPage" is likely a child. But if user used "Other" for type...
        // Let's support TabSet as the container.
        return AdaptiveTabSet(adaptiveMap: map, widgetState: widgetState);

      // Charts
      case 'Chart.Donut':
        return AdaptivePieChart(
          adaptiveMap: map,
          isDonut: true,
          widgetState: widgetState,
        );
      case 'Chart.Pie':
        return AdaptivePieChart(
          adaptiveMap: map,
          isDonut: false,
          widgetState: widgetState,
        );
      case 'Chart.Gauge':
        // Implementing Gauge as Donut for now (or Pie)
        return AdaptivePieChart(
          adaptiveMap: map,
          isDonut: true,
          widgetState: widgetState,
        );

      case 'Chart.Line':
        return AdaptiveLineChart(adaptiveMap: map, widgetState: widgetState);

      case 'Chart.VerticalBar':
        return AdaptiveBarChart(
          adaptiveMap: map,
          type: BarChartType.vertical,
          widgetState: widgetState,
        );
      case 'Chart.HorizontalBar':
        return AdaptiveBarChart(
          adaptiveMap: map,
          widgetState: widgetState,
          type: BarChartType.horizontal,
        );
      case 'Chart.HorizontalBar.Stacked':
        return AdaptiveBarChart(
          adaptiveMap: map,
          widgetState: widgetState,
          type: BarChartType.horizontalStacked,
        );
      case 'Chart.VerticalBar.Grouped':
        return AdaptiveBarChart(
          adaptiveMap: map,
          widgetState: widgetState,
          type: BarChartType.grouped,
        );
    }
    return AdaptiveUnknown(
      adaptiveMap: map,
      widgetState: widgetState,
      type: stringType,
    );
  }

  Widget _getActionWidget({
    required Map<String, dynamic> map,
    required RawAdaptiveCardState widgetState,
  }) {
    final String stringType = map['type'] as String;

    switch (stringType) {
      case 'Action.ShowCard':
        return AdaptiveActionShowCard(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      case 'Action.OpenUrl':
        return AdaptiveActionOpenUrl(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      case 'Action.Submit':
        return AdaptiveActionSubmit(adaptiveMap: map, widgetState: widgetState);
      case 'Action.Execute':
        return AdaptiveActionExecute(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      case 'Action.ResetInputs':
        return AdaptiveActionResetInputs(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      case 'Action.Popover':
        return AdaptiveActionPopover(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      case 'Action.OpenUrlDialog':
        return AdaptiveActionOpenUrlDialog(
          adaptiveMap: map,
          widgetState: widgetState,
        ); // Custom wrapper
      case 'Action.ToggleVisibility':
        assert(false, 'Action.ToggleVisibility is not supported');
        return AdaptiveUnknown(
          adaptiveMap: map,
          widgetState: widgetState,
          type: stringType,
        );
      case 'Action.InsertImage':
        return AdaptiveActionInsertImage(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      default:
        assert(false, 'No action found with type $stringType');
        return AdaptiveUnknown(
          adaptiveMap: map,
          widgetState: widgetState,
          type: stringType,
        );
    }
  }
}

/// Used to find the current CardRegistry
class DefaultCardRegistry extends InheritedWidget {
  const DefaultCardRegistry({
    super.key,
    required this.cardRegistry,
    required super.child,
  });

  /// Used to convert card type strings into Card instances
  final CardTypeRegistry cardRegistry;

  static CardTypeRegistry? of(BuildContext context) {
    final DefaultCardRegistry? cardRegistry = context
        .dependOnInheritedWidgetOfExactType<DefaultCardRegistry>();
    if (cardRegistry == null) return null;
    return cardRegistry.cardRegistry;
  }

  @override
  bool updateShouldNotify(DefaultCardRegistry oldWidget) => oldWidget != this;
}
