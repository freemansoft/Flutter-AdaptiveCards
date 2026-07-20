import 'package:adaptive_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders the Adaptive Chat app bar', (tester) async {
    await tester.pumpWidget(const AdaptiveChatApp());
    await tester.pump();
    expect(find.widgetWithText(AppBar, 'Adaptive Chat'), findsOneWidget);
  });
}
