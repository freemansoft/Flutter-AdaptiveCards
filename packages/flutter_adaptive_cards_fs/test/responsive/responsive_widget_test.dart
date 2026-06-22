import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

/// Loads a card fixture from `test/samples/<path>` as a JSON map.
Map<String, dynamic> _loadCard(String path) {
  final raw = File('test/samples/$path').readAsStringSync();
  return json.decode(raw) as Map<String, dynamic>;
}

/// Renders [card] via the canonical test harness at a controlled card width.
///
/// The harness centers the card with loose constraints, so the card's measured
/// width equals the test surface width. We pin devicePixelRatio to 1.0 so the
/// logical width equals the value passed here, and reset both in tearDown.
Future<void> _pumpCardAtWidth(
  WidgetTester tester,
  Map<String, dynamic> card,
  double width,
) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(Size(width, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    getTestWidgetFromMap(map: card, title: 'responsive test'),
  );
  await tester.pumpAndSettle();
}

void main() {
  final targetWidthCard = _loadCard('responsive/target_width.json');
  final flowCard = _loadCard('responsive/flow_container.json');
  final rootFlowCard = _loadCard('responsive/flow_root.json');

  testWidgets('targetWidth hides element when card is narrow', (tester) async {
    await _pumpCardAtWidth(tester, targetWidthCard, 150);
    expect(find.text('always'), findsOneWidget);
    expect(find.text('wide-only'), findsNothing);
  });

  testWidgets('targetWidth shows element when card is wide', (tester) async {
    await _pumpCardAtWidth(tester, targetWidthCard, 1000);
    expect(find.text('always'), findsOneWidget);
    expect(find.text('wide-only'), findsOneWidget);
  });

  testWidgets('Container uses Flow when wide', (tester) async {
    await _pumpCardAtWidth(tester, flowCard, 1000);
    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('Container stays a stack when narrow', (tester) async {
    await _pumpCardAtWidth(tester, flowCard, 150);
    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('Flow items sit side-by-side when wide (not full-width stack)',
      (tester) async {
    await _pumpCardAtWidth(tester, flowCard, 1000);
    // Same row (equal dy), different columns (different dx): items size to
    // content and flow, rather than each expanding to the full row width.
    final alpha = tester.getTopLeft(find.text('Alpha'));
    final beta = tester.getTopLeft(find.text('Beta'));
    expect(alpha.dy, beta.dy);
    expect(alpha.dx, isNot(beta.dx));
  });

  testWidgets('root body uses Flow when wide', (tester) async {
    await _pumpCardAtWidth(tester, rootFlowCard, 1000);
    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
    expect(find.text('rootOne'), findsOneWidget);
    expect(find.text('rootTwo'), findsOneWidget);
  });

  testWidgets('root body stays a stack when narrow', (tester) async {
    await _pumpCardAtWidth(tester, rootFlowCard, 150);
    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.text('rootOne'), findsOneWidget);
    expect(find.text('rootTwo'), findsOneWidget);
  });
}
