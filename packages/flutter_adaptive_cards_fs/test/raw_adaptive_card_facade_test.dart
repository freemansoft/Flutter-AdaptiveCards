import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Map<String, dynamic> _card() => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': [
    {'type': 'TextBlock', 'id': 'tb', 'text': 'base'},
    {'type': 'Input.Text', 'id': 'pwd', 'style': 'password'},
    {
      'type': 'FactSet',
      'id': 'fs',
      'facts': [
        {'title': 'BA', 'value': '1'},
      ],
    },
    {
      'type': 'RichTextBlock',
      'id': 'rtb',
      'inlines': [
        {'type': 'TextRun', 'text': 'Base'},
      ],
    },
    {
      'type': 'Input.ChoiceSet',
      'id': 'cs',
      'choices': [
        {'title': 'Static', 'value': 'static'},
      ],
    },
    {'type': 'Input.Text', 'id': 'txt', 'value': 'baseValue'},
  ],
  'actions': [
    {'type': 'Action.Submit', 'id': 'act', 'title': 'Go'},
  ],
};

void main() {
  testWidgets('host facade methods mutate document overlays', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _card(), title: 'facade'),
    );
    await tester.pumpAndSettle();

    final state = _cardState(tester);
    final container = state.documentContainer!;
    Map<String, dynamic>? resolved(String id) =>
        container.read(resolvedElementProvider(id));

    state.setText('tb', 'New');
    expect(resolved('tb')?['text'], 'New');
    state.clearText('tb');
    expect(resolved('tb')?['text'], 'base');

    state.setRevealPasswordEnabled('pwd', enabled: true);
    expect(
      container
          .read(adaptiveCardDocumentProvider)
          .overlaysById['pwd']
          ?.revealPasswordEnabled,
      isTrue,
    );
    state
      ..clearRevealPasswordEnabled('pwd')
      ..setFacts('fs', const [Fact(title: 'Overlay', value: 'x')]);
    expect((resolved('fs')?['facts'] as List).first['title'], 'Overlay');
    state.clearFacts('fs');
    expect((resolved('fs')?['facts'] as List).first['title'], 'BA');

    state.setInlines('rtb', [
      {'type': 'TextRun', 'text': 'Overlay'},
    ]);
    expect((resolved('rtb')?['inlines'] as List).first['text'], 'Overlay');
    state
      ..clearInlines('rtb')
      ..setActionEnabled('act', enabled: false);
    expect(container.read(resolvedActionProvider('act'))?['isEnabled'], false);

    state.loadInput('cs', {'Apple': 'a'});
    expect((resolved('cs')?['choices'] as List).first['value'], 'a');

    expect(() => state.resetInput('txt'), returnsNormally);
  });

  testWidgets('changeValue forwards to the onChange handler', (tester) async {
    InputChangeInvoke? captured;
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card(),
        title: 'changeValue',
        onChange: (invoke) => captured = invoke,
      ),
    );
    await tester.pumpAndSettle();

    _cardState(tester).changeValue('txt', 'hello');

    expect(captured?.inputId, 'txt');
    expect(captured?.value, 'hello');
  });

  testWidgets('showError surfaces a snackbar', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _card(), title: 'showError'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).showError('something went wrong');
    await tester.pump();

    expect(find.text('something went wrong'), findsOneWidget);
  });
}
