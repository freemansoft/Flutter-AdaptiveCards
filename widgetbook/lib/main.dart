import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/adaptive_cards_widgetbook_home.dart';

// If this file does not exist yet, it will be generated in build runner
import 'package:widgetbook_workspace/main.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      addons: [
        // DeviceFrame AddOn deprecated in favor of ViewportAddon
        ViewportAddon(Viewports.all),
        SemanticsAddon(),
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(
              name: 'Light',
              data: ThemeData.light(),
            ),
            WidgetbookTheme(
              name: 'Dark',
              data: ThemeData.dark(),
            ),
          ],
        ),
        // Accessibility AddOn deprecated in favor of BuilderAddon/AccessibilityTools
        BuilderAddon(
          name: 'Accessibility',
          builder: (context, child) => AccessibilityTools(
            child: child,
          ),
        ),
        AlignmentAddon(),
      ],
      // to see snackbar messages. Maybe should use some other way to do this?
      appBuilder: (context, child) => MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US'), Locale('vi', '')],
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Material(child: child)),
      ),
      home: const AdaptiveCardsWidgetbookHome(),
    );
  }
}
