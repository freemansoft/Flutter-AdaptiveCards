import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_test_support/flutter_adaptive_cards_test_support.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';

export 'package:flutter_adaptive_cards_test_support/flutter_adaptive_cards_test_support.dart';

/// [CardTypeRegistry] with chart element types registered for chart package tests.
final CardTypeRegistry chartCardTypeRegistry = CardTypeRegistry(
  addedElements: CardChartsRegistry.additionalChartElements,
  overlayExtensions: CardChartsRegistry.overlayExtensions,
);

/// Loads a chart sample JSON fixture and wraps it in the shared test harness.
Widget getChartTestWidgetFromPath({
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
  bool supportMarkdown = true,
  bool listView = false,
  bool scrollable = false,
  String samplesDirectory = 'test/samples',
}) {
  return getTestWidgetFromPath(
    path: path,
    key: key,
    onOpenUrl: onOpenUrl,
    onOpenUrlDialog: onOpenUrlDialog,
    onSubmit: onSubmit,
    onExecute: onExecute,
    onChange: onChange,
    onRefresh: onRefresh,
    currentUserId: currentUserId,
    initData: initData,
    hostConfigs: hostConfigs,
    cardTypeRegistry: chartCardTypeRegistry,
    supportMarkdown: supportMarkdown,
    listView: listView,
    scrollable: scrollable,
    samplesDirectory: samplesDirectory,
  );
}

/// Builds a chart sample widget from an in-memory Adaptive Card map.
Widget getChartTestWidgetFromMap({
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
  bool supportMarkdown = true,
  bool listView = false,
  bool scrollable = false,
}) {
  return getTestWidgetFromMap(
    map: map,
    title: title,
    key: key,
    onOpenUrl: onOpenUrl,
    onOpenUrlDialog: onOpenUrlDialog,
    onSubmit: onSubmit,
    onExecute: onExecute,
    onChange: onChange,
    onRefresh: onRefresh,
    currentUserId: currentUserId,
    initData: initData,
    hostConfigs: hostConfigs,
    cardTypeRegistry: chartCardTypeRegistry,
    supportMarkdown: supportMarkdown,
    listView: listView,
    scrollable: scrollable,
  );
}

/// Builds a chart sample widget from a JSON string.
Widget getChartTestWidgetFromString({
  required String jsonString,
  Key? key,
  HostConfigs? hostConfigs,
}) {
  final map = json.decode(jsonString) as Map<String, dynamic>;
  return getChartTestWidgetFromMap(
    map: map,
    title: 'Test',
    key: key,
    hostConfigs: hostConfigs,
  );
}

/// Loads a v1.6 chart sample for golden tests.
Widget getChartSampleForGoldenTest(
  Key key,
  String sampleName, {
  String samplesDirectory = 'test/samples',
}) {
  return getChartTestWidgetFromPath(
    path: 'v1.6/$sampleName.json',
    key: key,
    samplesDirectory: samplesDirectory,
  );
}
