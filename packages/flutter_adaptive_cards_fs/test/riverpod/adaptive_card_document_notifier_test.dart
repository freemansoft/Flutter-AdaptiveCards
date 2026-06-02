import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baselineFixture() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.3',
    'body': [
      {
        'type': 'Input.Text',
        'id': 'myText',
        'value': 'baseline',
      },
      {
        'type': 'Input.ChoiceSet',
        'id': 'myChoice',
        'choices': [
          {'title': 'Static', 'value': 'static'},
        ],
        'value': 'static',
      },
      {
        'type': 'TextBlock',
        'id': 'visibleBlock',
        'text': 'hello',
        'isVisible': true,
      },
    ],
  };
}

Map<String, dynamic> _dataQueryChoiceBaseline() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'Input.ChoiceSet',
        'id': 'queryChoice',
        'choices': [
          {'title': 'Static', 'value': 'static'},
        ],
        'choices.data': {
          'type': 'Data.Query',
          'dataset': 'test/dataset',
        },
      },
    ],
  };
}

ProviderContainer _createContainer(Map<String, dynamic> baseline) {
  return ProviderContainer(
    overrides: [
      baselineMapProvider.overrideWithValue(baseline),
    ],
  );
}

void main() {
  group('AdaptiveCardDocumentNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = _createContainer(_baselineFixture());
    });

    tearDown(() {
      container.dispose();
    });

    test('seedInputValues writes inputValue overlays for known ids only', () {
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..seedInputValues({
          'myText': 'seeded',
          'unknownId': 'ignored',
        });

      expect(notifier.state.overlaysById['myText']?.inputValue, 'seeded');
      expect(notifier.state.overlaysById.containsKey('unknownId'), isFalse);
    });

    test('setInputValue merges into resolvedElementProvider value', () {
      container
          .read(adaptiveCardDocumentProvider.notifier)
          .setInputValue(
            'myText',
            'overlay',
          );

      final resolved = container.read(resolvedElementProvider('myText'));
      expect(resolved?['value'], 'overlay');
    });

    test('setChoices replaces choices and clears inputValue overlay', () {
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..setInputValue('myChoice', 'static')
        ..setChoices('myChoice', const [
          Choice(title: 'Dynamic', value: 'dyn'),
        ]);

      expect(notifier.state.overlaysById['myChoice']?.inputValue, isNull);
      expect(notifier.state.overlaysById['myChoice']?.choices?.length, 1);
      expect(
        notifier.state.overlaysById['myChoice']?.choices?.first['value'],
        'dyn',
      );

      final resolved = container.read(resolvedElementProvider('myChoice'));
      final choices = resolved?['choices'] as List<dynamic>?;
      expect(choices?.length, 1);
      expect(choices?.first['value'], 'dyn');
    });

    test('appendChoices merges with baseline and dedupes by value', () {
      container.read(adaptiveCardDocumentProvider.notifier).appendChoices(
        'myChoice',
        const [
          Choice(title: 'Static Renamed', value: 'static'),
          Choice(title: 'New', value: 'new'),
        ],
      );

      final resolved = container.read(resolvedElementProvider('myChoice'));
      final choices = resolved?['choices'] as List<dynamic>?;
      expect(choices?.length, 2);

      final values = choices!.map((c) => (c as Map)['value']).toList();
      expect(values, containsAll(['static', 'new']));

      final staticTitles = choices
          .where((c) => (c as Map)['value'] == 'static')
          .map((c) => (c as Map)['title'])
          .toList();
      expect(staticTitles, ['Static Renamed']);
    });

    test(
      'resetAllInputs clears inputValue and choices but keeps isVisible',
      () {
        final notifier = container.read(adaptiveCardDocumentProvider.notifier)
          ..setInputValue('myText', 'typed')
          ..setVisibility('visibleBlock', visible: false)
          ..setChoices('myChoice', const [
            Choice(title: 'Only Dynamic', value: 'dyn'),
          ])
          ..resetAllInputs();

        expect(notifier.state.overlaysById['myText']?.inputValue, isNull);
        expect(notifier.state.overlaysById['myChoice']?.inputValue, isNull);
        expect(notifier.state.overlaysById['myChoice']?.choices, isNull);
        expect(notifier.state.overlaysById['visibleBlock']?.isVisible, isFalse);

        final resolvedText = container.read(resolvedElementProvider('myText'));
        expect(resolvedText?['value'], 'baseline');

        final resolvedChoice = container.read(
          resolvedElementProvider('myChoice'),
        );
        final choices = resolvedChoice?['choices'] as List<dynamic>?;
        expect(choices?.length, 1);
        expect(choices?.first['value'], 'static');
      },
    );

    test('collectInputValues prefers overlay over baseline', () {
      final values = (container.read(
        adaptiveCardDocumentProvider.notifier,
      )..setInputValue('myText', 'overlay')).collectInputValues();
      expect(values['myText'], 'overlay');
      expect(values['myChoice'], 'static');
    });

    test('setVisibility preserves inputValue overlay', () {
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..setInputValue('myText', 'typed')
        ..setVisibility('visibleBlock', visible: false);

      expect(notifier.state.overlaysById['myText']?.inputValue, 'typed');
      expect(notifier.state.overlaysById['visibleBlock']?.isVisible, isFalse);
    });

    test('setInputValue preserves choices overlay', () {
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..setChoices('myChoice', const [
          Choice(title: 'Dynamic', value: 'dyn'),
        ])
        ..setInputValue('myChoice', 'dyn');

      expect(notifier.state.overlaysById['myChoice']?.choices?.length, 1);
      expect(notifier.state.overlaysById['myChoice']?.inputValue, 'dyn');
    });

    test(
      'setDataQuerySession merges count and skip into resolved choices.data',
      () {
        final dataQueryContainer = _createContainer(_dataQueryChoiceBaseline());
        addTearDown(dataQueryContainer.dispose);

        dataQueryContainer
            .read(adaptiveCardDocumentProvider.notifier)
            .setDataQuerySession(
              'queryChoice',
              count: 10,
              skip: 20,
              searchText: 'search-term',
            );

        final resolved = dataQueryContainer.read(
          resolvedElementProvider('queryChoice'),
        );
        final choicesData = resolved?['choices.data'] as Map<String, dynamic>?;
        expect(choicesData?['dataset'], 'test/dataset');
        expect(choicesData?['count'], 10);
        expect(choicesData?['skip'], 20);
        expect(choicesData?.containsKey('searchText'), isFalse);

        final overlay = dataQueryContainer
            .read(adaptiveCardDocumentProvider)
            .overlaysById['queryChoice'];
        expect(overlay?.querySearchText, 'search-term');
      },
    );

    test(
      'setDataQuerySession preserves choices overlay when updating session',
      () {
        final dataQueryContainer = _createContainer(_dataQueryChoiceBaseline());
        addTearDown(dataQueryContainer.dispose);

        final notifier =
            dataQueryContainer.read(
                adaptiveCardDocumentProvider.notifier,
              )
              ..setChoices('queryChoice', const [
                Choice(title: 'Dynamic', value: 'dyn'),
              ])
              ..setDataQuerySession('queryChoice', count: 5);

        final resolved = dataQueryContainer.read(
          resolvedElementProvider('queryChoice'),
        );
        final choices = resolved?['choices'] as List<dynamic>?;
        expect(choices?.length, 1);
        expect(choices?.first['value'], 'dyn');

        final choicesData = resolved?['choices.data'] as Map<String, dynamic>?;
        expect(choicesData?['count'], 5);

        expect(
          notifier.state.overlaysById['queryChoice']?.choices?.length,
          1,
        );
      },
    );
  });
}
