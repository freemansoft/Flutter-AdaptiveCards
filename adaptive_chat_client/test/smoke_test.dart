import 'package:adaptive_chat_client/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders the Adaptive Chat app bar', (tester) async {
    await tester.pumpWidget(const AdaptiveChatApp());
    await tester.pump();
    expect(find.widgetWithText(AppBar, 'Adaptive Chat'), findsOneWidget);
  });

  testWidgets('app renders the Spanish app bar when locale is es', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveChatApp(locale: Locale('es')));
    await tester.pump();
    expect(find.widgetWithText(AppBar, 'Chat Adaptativo'), findsOneWidget);
  });
}
