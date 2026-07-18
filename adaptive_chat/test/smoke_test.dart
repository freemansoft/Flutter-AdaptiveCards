import 'package:adaptive_chat/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders the Adaptive Chat title', (tester) async {
    await tester.pumpWidget(const AdaptiveChatApp());
    expect(find.text('Adaptive Chat'), findsWidgets);
  });
}
