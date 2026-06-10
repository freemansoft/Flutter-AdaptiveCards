import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/adaptive_cards_widgetbook_home.dart';

// If this file does not exist yet, it will be generated in build runner
import 'package:widgetbook_workspace/main.directories.g.dart';

// Light/dark themes shared by MaterialThemeAddon and the MaterialApp appBuilder.
final ThemeData _widgetbookLightTheme = ThemeData.light();
final ThemeData _widgetbookDarkTheme = ThemeData.dark();

final MaterialThemeAddon _materialThemeAddon = MaterialThemeAddon(
  themes: [
    WidgetbookTheme(
      name: 'Light',
      data: _widgetbookLightTheme,
    ),
    WidgetbookTheme(
      name: 'Dark',
      data: _widgetbookDarkTheme,
    ),
  ],
);

/// [MaterialApp] sits outside the addon tree, so forward the active theme
/// addon selection via [WidgetbookState] (same source [MaterialThemeAddon] uses).
Widget _widgetbookAppBuilder(BuildContext context, Widget child) {
  final state = WidgetbookState.of(context);
  return ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final groupMap = FieldCodec.decodeQueryGroup(
        state.queryParams[_materialThemeAddon.groupName],
      );
      final selectedTheme = _materialThemeAddon.valueFromQueryGroup(groupMap);
      final isDark = selectedTheme.data.brightness == Brightness.dark;

      return MaterialApp(
        theme: _widgetbookLightTheme,
        darkTheme: _widgetbookDarkTheme,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US'), Locale('vi', '')],
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Material(child: child)),
      );
    },
  );
}

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
        // Required for Widgetbook accessibility tooling, experimental usage is expected
        // ignore: experimental_member_use
        SemanticsAddon(),
        _materialThemeAddon,
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
      appBuilder: _widgetbookAppBuilder,
      home: const AdaptiveCardsWidgetbookHome(),
    );
  }
}
