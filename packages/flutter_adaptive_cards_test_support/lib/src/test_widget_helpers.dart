import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Builds a [MaterialApp] + [AdaptiveCardsCanvas] from a JSON file under [samplesDirectory];
/// use [key] on [RepaintBoundary] for golden capture.
Widget getTestWidgetFromPath({
  required String path,
  Key? key,
  void Function(OpenUrlActionInvoke invoke)? onOpenUrl,
  void Function(OpenUrlDialogActionInvoke invoke)? onOpenUrlDialog,
  void Function(SubmitActionInvoke invoke)? onSubmit,
  void Function(ExecuteActionInvoke invoke)? onExecute,
  void Function(InputChangeInvoke invoke)? onChange,
  void Function(RefreshActionInvoke invoke)? onRefresh,
  String? currentUserId,
  Map? initData,
  HostConfigs? hostConfigs,
  CardTypeRegistry cardTypeRegistry = const CardTypeRegistry(),
  bool supportMarkdown = true,
  bool listView = false,
  bool scrollable = false,
  String samplesDirectory = 'test/samples',
}) {
  final File file = File('$samplesDirectory/$path');
  final Map<String, dynamic> map =
      json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return getTestWidgetFromMap(
    map: map,
    key: key,
    title: path,
    onOpenUrl: onOpenUrl,
    onOpenUrlDialog: onOpenUrlDialog,
    onSubmit: onSubmit,
    onExecute: onExecute,
    onChange: onChange,
    onRefresh: onRefresh,
    currentUserId: currentUserId,
    initData: initData,
    hostConfigs: hostConfigs,
    cardTypeRegistry: cardTypeRegistry,
    supportMarkdown: supportMarkdown,
    listView: listView,
    scrollable: scrollable,
  );
}

/// Renders [map] as an adaptive card with optional [InheritedAdaptiveCardHandlers]
/// callbacks for interaction tests.
Widget getTestWidgetFromMap({
  required Map<String, dynamic> map,
  required String title,
  Key? key,
  void Function(OpenUrlActionInvoke invoke)? onOpenUrl,
  void Function(OpenUrlDialogActionInvoke invoke)? onOpenUrlDialog,
  void Function(SubmitActionInvoke invoke)? onSubmit,
  void Function(ExecuteActionInvoke invoke)? onExecute,
  void Function(InputChangeInvoke invoke)? onChange,
  void Function(RefreshActionInvoke invoke)? onRefresh,
  String? currentUserId,
  Map? initData,
  HostConfigs? hostConfigs,
  CardTypeRegistry cardTypeRegistry = const CardTypeRegistry(),
  AdaptiveCardBrightnessMode brightnessMode = AdaptiveCardBrightnessMode.auto,
  bool supportMarkdown = true,
  bool listView = false,
  bool scrollable = false,
}) {
  final Widget adaptiveCard = AdaptiveCardsCanvas.map(
    content: map,
    cardTypeRegistry: cardTypeRegistry,
    // debug "show json" panes don't show in prod
    // so dislable them in the golden images
    showDebugJson: false,
    initData: initData,
    onChange: onChange,
    currentUserId: currentUserId,
    supportMarkdown: supportMarkdown,
    hostConfigs: hostConfigs ?? HostConfigs(),
    brightnessMode: brightnessMode,
    listView: listView,
  );

  Widget wrapBody(Widget child) {
    if (scrollable) {
      return SingleChildScrollView(child: child);
    }
    return Center(child: child);
  }

  // this should generate an action handler set instead but the LLM
  // saw that we could rely on InheritedAdaptiveCardHandlers here
  if (onOpenUrl != null ||
      onOpenUrlDialog != null ||
      onSubmit != null ||
      onExecute != null ||
      onChange != null ||
      onRefresh != null) {
    // wrap in handlers
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        // tests look for this value key as the root for golden
        body: RepaintBoundary(
          key: key,
          child: wrapBody(
            InheritedAdaptiveCardHandlers(
              onOpenUrl: onOpenUrl ?? (_) {},
              onOpenUrlDialog: onOpenUrlDialog ?? (_) {},
              onSubmit: onSubmit ?? (_) {},
              onExecute: onExecute ?? (_) {},
              onChange: onChange ?? (_) {},
              onRefresh: onRefresh,
              child: adaptiveCard,
            ),
          ),
        ),
      ),
    );
  } else {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        // tests look for this value key as the root for golden
        body: RepaintBoundary(
          key: key,
          child: wrapBody(adaptiveCard),
        ),
      ),
    );
  }
}

/// Same as [getTestWidgetFromMap] but parses [jsonString] first — handy for inline
/// fixture JSON in tests.
Widget getTestWidgetFromString({required String jsonString, Key? key}) {
  final Map<String, dynamic> map =
      json.decode(jsonString) as Map<String, dynamic>;
  return getTestWidgetFromMap(map: map, key: key, title: 'Test');
}
