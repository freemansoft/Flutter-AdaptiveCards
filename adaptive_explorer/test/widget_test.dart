import 'package:adaptive_explorer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts with empty state and buttons on AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveExplorerApp());

    // Verify that our app starts with the selection message.
    expect(find.text('Select a template to view'), findsOneWidget);

    // Validate that the open template and open data buttons are on the AppBar
    final appBar = find.byType(AppBar);
    expect(
      find.descendant(of: appBar, matching: find.text('Open Template')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: appBar, matching: find.text('Open Data')),
      findsOneWidget,
    );

    // Also verify icons for good measure
    expect(find.byIcon(Icons.file_open), findsOneWidget);
    expect(find.byIcon(Icons.data_object), findsOneWidget);
  });

  testWidgets('App bar has tab bar with Template, Data, and Merged tabs', (
    tester,
  ) async {
    final mockTemplate = {'type': 'AdaptiveCard', 'version': '1.0'};

    await tester.pumpWidget(
      AdaptiveExplorerApp(initialTemplateJson: mockTemplate),
    );

    // Verify tab bar is present
    expect(find.byType(TabBar), findsOneWidget);

    // Verify the three tab labels
    expect(find.text('Template'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Merged'), findsOneWidget);
  });

  testWidgets('App bar not shown when no files open', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveExplorerApp());

    // Verify tab bar is present
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('Save button is present in AppBar', (tester) async {
    await tester.pumpWidget(const AdaptiveExplorerApp());

    final appBar = find.byType(AppBar);
    expect(
      find.descendant(of: appBar, matching: find.text('Save')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.save), findsOneWidget);
  });

  testWidgets('Save button is disabled when no file is loaded', (tester) async {
    await tester.pumpWidget(const AdaptiveExplorerApp());

    await tester.pumpAndSettle();

    final saveButtonFinder = find
        .ancestor(
          of: find.text('Save'),
          matching: find.byWidgetPredicate(
            (widget) {
              try {
                // ignoring because the onPressed could take action
                // ignore: unnecessary_statements
                (widget as dynamic).onPressed;
                return true;
              } on Object catch (_) {
                return false;
              }
            },
          ),
        )
        .first;
    expect(saveButtonFinder, findsOneWidget);

    // Verify it is disabled (onPressed is null)
    final TextButton button = tester.widget<TextButton>(saveButtonFinder);
    expect(button.onPressed, isNull);
  });
}
