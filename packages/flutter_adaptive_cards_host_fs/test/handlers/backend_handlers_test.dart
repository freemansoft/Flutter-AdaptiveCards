import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onSubmit posts invoke and applies setInputErrors response', (
    tester,
  ) async {
    final cardKey = GlobalKey<RawAdaptiveCardState>();
    final client = _FakeBackendClient({
      'type': 'adaptiveCard.invokeResponse',
      'effects': [
        {
          'type': 'setInputErrors',
          'errors': {'email': 'Required'},
        },
      ],
    });

    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        <String, dynamic>{
          'type': 'Input.Text',
          'id': 'email',
          'value': 'user@example.com',
        },
      ],
      'actions': [
        <String, dynamic>{
          'type': 'Action.Submit',
          'title': 'Submit',
          'associatedInputs': 'none',
          'data': <String, dynamic>{},
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveCardBackendHandlers(
            client: client,
            cardKey: cardKey,
          ).wrap(
            RawAdaptiveCard.fromMap(
              key: cardKey,
              map: map,
              hostConfigs: HostConfigs(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(client.postCount, 1);
    expect(client.lastBody?['kind'], 'submit');
    expect(find.text('Required'), findsOneWidget);
  });
}

class _FakeBackendClient implements AdaptiveCardBackendClient {
  _FakeBackendClient(this.response);

  final Map<String, dynamic> response;
  int postCount = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    postCount++;
    lastBody = body;
    return response;
  }
}
