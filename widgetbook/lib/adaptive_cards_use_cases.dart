import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/generic_page.dart';
import 'package:widgetbook_workspace/network_page.dart';
import 'package:widgetbook_workspace/widget_types.dart' as widget_types;

// =============================================================================
// Remember to run `dart run build_runner build -d` to update the widgetbook
// =============================================================================

// =============================================================================
// SAMPLES Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Examples,
  path: '[Components]',
)
Widget buildSamplesExample1(BuildContext context) {
  return const GenericPage(
    url: 'lib/samples/examples/example1.json',
    supportMarkdown: false,
  );
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example2.json');
}

@widgetbook.UseCase(
  name: 'Example 3',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample3(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example3.json');
}

@widgetbook.UseCase(
  name: 'Example 4',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample4(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example4.json');
}

@widgetbook.UseCase(
  name: 'Example 5',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample5(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example5.json');
}

@widgetbook.UseCase(
  name: 'Example 6',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample6(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example6.json');
}

@widgetbook.UseCase(
  name: 'Example 7',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample7(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example7.json');
}

@widgetbook.UseCase(
  name: 'Example 8',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample8(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example8.json');
}

@widgetbook.UseCase(
  name: 'Example 9',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample9(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example9.json');
}

@widgetbook.UseCase(
  name: 'Example 10',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample10(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example10.json');
}

@widgetbook.UseCase(
  name: 'Example 11',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample11(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example11.json');
}

@widgetbook.UseCase(
  name: 'Example 12',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample12(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example12.json');
}

@widgetbook.UseCase(
  name: 'Example 13',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample13(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example13.json');
}

@widgetbook.UseCase(
  name: 'Example 14',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample14(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example14.json');
}

// Won't run on windows
@widgetbook.UseCase(
  name: 'Example 15 (Video)',
  type: widget_types.Examples,
  path: '[Examples]',
)
Widget buildSamplesExample15(BuildContext context) {
  return const GenericPage(url: 'lib/samples/examples/example15.json');
}

// =============================================================================
// TEXT BLOCK Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example1.json');
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example2.json');
}

@widgetbook.UseCase(
  name: 'Example 3',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample3(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example3.json');
}

@widgetbook.UseCase(
  name: 'Example 4',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample4(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example4.json');
}

@widgetbook.UseCase(
  name: 'Example 5',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample5(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example5.json');
}

@widgetbook.UseCase(
  name: 'Example 6',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample6(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example6.json');
}

@widgetbook.UseCase(
  name: 'Example 7',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample7(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example7.json');
}

@widgetbook.UseCase(
  name: 'Example 8',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample8(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example8.json');
}

@widgetbook.UseCase(
  name: 'Example 9',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample9(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example9.json');
}

@widgetbook.UseCase(
  name: 'Example 10',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample10(BuildContext context) {
  return const GenericPage(url: 'lib/samples/text_block/example10.json');
}

@widgetbook.UseCase(
  name: 'Example 11 (no markdown)',
  type: widget_types.TextBlock,
  path: '[Components]',
)
Widget buildTextBlockExample11(BuildContext context) {
  return const GenericPage(
    url: 'lib/samples/text_block/example11.json',
    supportMarkdown: false,
  );
}

// =============================================================================
// IMAGE Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Image,
  path: '[Components]',
)
Widget buildImageExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image/example1.json');
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.Image,
  path: '[Components]',
)
Widget buildImageExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image/example2.json');
}

@widgetbook.UseCase(
  name: 'Example 4',
  type: widget_types.Image,
  path: '[Components]',
)
Widget buildImageExample4(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image/example4.json');
}

@widgetbook.UseCase(
  name: 'Example 5',
  type: widget_types.Image,
  path: '[Components]',
)
Widget buildImageExample5(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image/example5.json');
}

@widgetbook.UseCase(
  name: 'Example 6',
  type: widget_types.Image,
  path: '[Components]',
)
Widget buildImageExample6(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image/example6.json');
}

@widgetbook.UseCase(
  name: 'Width and Height Set in Pixels',
  type: widget_types.Image,
  path: '[Components]',
)
Widget buildImageWidthAndHeightSetInPixels(BuildContext context) {
  return const GenericPage(
    url: 'lib/samples/image/width_and_heigh_set_in_pixels.json',
  );
}

@widgetbook.UseCase(
  name: 'Width Set in Pixels',
  type: widget_types.Image,
  path: '[Components]',
)
Widget buildImageWidthSetInPixels(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image/width_set_in_pixels.json');
}

@widgetbook.UseCase(
  name: 'Height Set in Pixels',
  type: widget_types.Image,
  path: '[Components]',
)
Widget buildImageHeightSetInPixels(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image/height_set_in_pixels.json');
}

// =============================================================================
// CONTAINER Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Container,
  path: '[Components]',
)
Widget buildContainerExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/container/example1.json');
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.Container,
  path: '[Components]',
)
Widget buildContainerExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/container/example2.json');
}

@widgetbook.UseCase(
  name: 'Example 3',
  type: widget_types.Container,
  path: '[Components]',
)
Widget buildContainerExample3(BuildContext context) {
  return const GenericPage(url: 'lib/samples/container/example3.json');
}

@widgetbook.UseCase(
  name: 'Example 4',
  type: widget_types.Container,
  path: '[Components]',
)
Widget buildContainerExample4(BuildContext context) {
  return const GenericPage(url: 'lib/samples/container/example4.json');
}

@widgetbook.UseCase(name: 'Example 5', type: Container, path: '[Components]')
Widget buildContainerExample5(BuildContext context) {
  return const GenericPage(url: 'lib/samples/container/example5.json');
}

// =============================================================================
// COLUMN SET Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example1.json');
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example2.json');
}

@widgetbook.UseCase(
  name: 'Example 3',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample3(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example3.json');
}

@widgetbook.UseCase(
  name: 'Example 4',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample4(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example4.json');
}

@widgetbook.UseCase(
  name: 'Example 5',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample5(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example5.json');
}

@widgetbook.UseCase(
  name: 'Example 6',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample6(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example6.json');
}

@widgetbook.UseCase(
  name: 'Example 7',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample7(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example7.json');
}

@widgetbook.UseCase(
  name: 'Example 8',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample8(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example8.json');
}

@widgetbook.UseCase(
  name: 'Example 9',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample9(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example9.json');
}

@widgetbook.UseCase(
  name: 'Example 10',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetExample10(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column_set/example10.json');
}

@widgetbook.UseCase(
  name: 'Column width in pixels',
  type: widget_types.ColumnSet,
  path: '[Components]',
)
Widget buildColumnSetColumnWidthPixels(BuildContext context) {
  return const GenericPage(
    url: 'lib/samples/column_set/column_width_in_pixels.json',
  );
}

// =============================================================================
// COLUMN Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Column,
  path: '[Components]',
)
Widget buildColumnExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column/example1.json');
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.Column,
  path: '[Components]',
)
Widget buildColumnExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column/example2.json');
}

@widgetbook.UseCase(
  name: 'Example 3',
  type: widget_types.Column,
  path: '[Components]',
)
Widget buildColumnExample3(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column/example3.json');
}

@widgetbook.UseCase(
  name: 'Example 4',
  type: widget_types.Column,
  path: '[Components]',
)
Widget buildColumnExample4(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column/example4.json');
}

@widgetbook.UseCase(
  name: 'Example 5',
  type: widget_types.Column,
  path: '[Components]',
)
Widget buildColumnExample5(BuildContext context) {
  return const GenericPage(url: 'lib/samples/column/example5.json');
}

// =============================================================================
// FACT SET Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.FactSet,
  path: '[Components]',
)
Widget buildFactSetExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/fact_set/example1.json');
}

// =============================================================================
// IMAGE SET Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.ImageSet,
  path: '[Components]',
)
Widget buildImageSetExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image_set/example1.json');
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.ImageSet,
  path: '[Components]',
)
Widget buildImageSetExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/image_set/example2.json');
}

// =============================================================================
// ACTION SET Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.ActionSet,
  path: '[Components]',
)
Widget buildActionSetExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/action_set/example1.json');
}

// =============================================================================
// ACTION OPEN URL Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Action.OpenUrl Example 1',
  type: widget_types.Actions,
  path: '[Components]',
)
Widget buildActionOpenUrlExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/action_open_url/example1.json');
}

@widgetbook.UseCase(
  name: 'Action.OpenUrl Example 2',
  type: widget_types.Actions,
  path: '[Components]',
)
Widget buildActionOpenUrlExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/action_open_url/example2.json');
}

// =============================================================================
// ACTION SUBMIT Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Action.Submit Example 1',
  type: widget_types.Actions,
  path: '[Components]',
)
Widget buildActionSubmitExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/action_submit/example1.json');
}

// =============================================================================
// ACTION SUBMIT Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Action.Execute Example 1',
  type: widget_types.Actions,
  path: '[Components]',
)
Widget buildActionExecuteExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/action_execute/example1.json');
}

// =============================================================================
// ACTION SHOW CARD Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Action.ShowCard Example 1',
  type: widget_types.Actions,
  path: '[Components]',
)
Widget buildActionShowCardExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/action_show_card/example1.json');
}

// =============================================================================
// INPUT TEXT Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.InputText,
  path: '[Components]',
)
Widget buildInputTextExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/inputs/input_text/example1.json');
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.InputText,
  path: '[Components]',
)
Widget buildInputTextExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/inputs/input_text/example2.json');
}

// =============================================================================
// INPUT NUMBER Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.InputNumber,
  path: '[Components]',
)
Widget buildInputNumberExample1(BuildContext context) {
  return const GenericPage(
    url: 'lib/samples/inputs/input_number/example1.json',
  );
}

// =============================================================================
// MEDIA Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Media,
  path: '[Components]',
)
Widget buildMediaExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/media/example1.json');
}

// =============================================================================
// INPUT DATE Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.InputDate,
  path: '[Components]',
)
Widget buildInputDateExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/inputs/input_date/example1.json');
}

// =============================================================================
// INPUT TIME Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.InputTime,
  path: '[Components]',
)
Widget buildInputTimeExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/inputs/input_time/example1.json');
}

@widgetbook.UseCase(
  name: 'Example 2',
  type: widget_types.InputTime,
  path: '[Components]',
)
Widget buildInputTimeExample2(BuildContext context) {
  return const GenericPage(url: 'lib/samples/inputs/input_time/example2.json');
}

// =============================================================================
// INPUT TOGGLE Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.InputToggle,
  path: '[Components]',
)
Widget buildInputToggleExample1(BuildContext context) {
  return const GenericPage(
    url: 'lib/samples/inputs/input_toggle/example1.json',
  );
}

// =============================================================================
// INPUT CHOICE SET Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.InputChoiceSet,
  path: '[Components]',
)
Widget buildInputChoiceSetExample1(BuildContext context) {
  return const GenericPage(
    url: 'lib/samples/inputs/input_choice_set/example1.json',
  );
}

// =============================================================================
// TABLE Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Table,
  path: '[Components]',
)
Widget buildTableExample1(BuildContext context) {
  return const GenericPage(url: 'lib/samples/table/example1.json');
}

// =============================================================================
// V1.6 Components - Badge
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Badge,
  path: '[Components]',
)
Widget buildV16Badge(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/badge.json');
}

// =============================================================================
// V1.6 Components - Rating
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Rating,
  path: '[Components]',
)
Widget buildV16Rating(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/rating.json');
}

// =============================================================================
// V1.6 Components - Carousel
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Carousel,
  path: '[Components]',
)
Widget buildV16Carousel(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/carousel.json');
}

// =============================================================================
// V1.6 Components - Accordion
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.Accordion,
  path: '[Components]',
)
Widget buildV16Accordion(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/accordion.json');
}

// =============================================================================
// V1.6 Components - Charts
// =============================================================================

@widgetbook.UseCase(
  name: 'Donut',
  type: widget_types.Charts,
  path: '[Components]',
)
Widget buildV16ChartDonut(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/chart_donut.json');
}

@widgetbook.UseCase(
  name: 'Pie',
  type: widget_types.Charts,
  path: '[Components]',
)
Widget buildV16Chart(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/chart_pie.json');
}

@widgetbook.UseCase(
  name: 'Bar Vertical',
  type: widget_types.Charts,
  path: '[Components]',
)
Widget buildV16ChartBar(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/chart_bar_vertical.json');
}

@widgetbook.UseCase(
  name: 'Bar Horizontal (crashes)',
  type: widget_types.Charts,
  path: '[Components]',
)
Widget buildV16ChartBarHorizontal(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/chart_bar_horizontal.json');
}

@widgetbook.UseCase(
  name: 'Line',
  type: widget_types.Charts,
  path: '[Components]',
)
Widget buildV16ChartLine(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/chart_line.json');
}

// =============================================================================
// V1.6 Components - Actions
// =============================================================================

@widgetbook.UseCase(
  name: 'Actions.Popover Actions.Reset',
  type: widget_types.Actions,
  path: '[Components]',
)
Widget buildV16Actions(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/action.json');
}

// =============================================================================
// V1.6 Components - CodeBlock
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.CodeBlock,
  path: '[Components]',
)
Widget buildV16CodeBlock(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/code_block.json');
}

// =============================================================================
// V1.6 Components - ProgressBar
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.ProgressBar,
  path: '[Components]',
)
Widget buildV16ProgressBar(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/progress_bar.json');
}

// =============================================================================
// V1.6 Components - ProgressRing
// =============================================================================

@widgetbook.UseCase(
  name: 'Example 1',
  type: widget_types.ProgressRing,
  path: '[Components]',
)
Widget buildV16ProgressRing(BuildContext context) {
  return const GenericPage(url: 'lib/samples/v1.6/progress_ring.json');
}

// =============================================================================
// NETWORK SAMPLES Component
// =============================================================================

@widgetbook.UseCase(
  name: 'Expense Report',
  type: widget_types.Microsoft15,
  path: '[Remote]',
)
Widget buildNetworkExpenseReport(BuildContext context) {
  return const NetworkPage(
    url:
        'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/ExpenseReport.json',
  );
}

@widgetbook.UseCase(
  name: 'Show Card Wizard',
  type: widget_types.Microsoft15,
  path: '[Remote]',
)
Widget buildNetworkShowCardWizard(BuildContext context) {
  return const NetworkPage(
    url:
        'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/ShowCardWizard.json',
  );
}

@widgetbook.UseCase(
  name: 'Agenda',
  type: widget_types.Microsoft15,
  path: '[Remote]',
)
Widget buildNetworkAgenda(BuildContext context) {
  return const NetworkPage(
    url:
        'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/Agenda.json',
  );
}

@widgetbook.UseCase(
  name: 'Flight Update Table',
  type: widget_types.Microsoft15,
  path: '[Remote]',
)
Widget buildNetworkFlightUpdateTable(BuildContext context) {
  return const NetworkPage(
    url:
        'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/FlightUpdateTable.json',
  );
}

// =============================================================================
// FORMS Component (assets-based)
// =============================================================================

@widgetbook.UseCase(
  name: 'Form via Assets',
  type: widget_types.Forms,
  path: '[Forms]',
)
Widget buildFormViaAssets(BuildContext context) {
  return const GenericPage(url: 'assets/ac-qv-faqs.json');
}

@widgetbook.UseCase(
  name: 'Form with initData',
  type: widget_types.Forms,
  path: '[Forms]',
)
Widget buildFormWithInitData(BuildContext context) {
  return const GenericPage(
    url: 'assets/ac-qv-faqs.json',
    initData: {
      'fullname': 'a full name',
      'phonenumber': '1234567890',
      'bookingdate': '2023-05-08',
      'gender': 'female',
    },
  );
}
