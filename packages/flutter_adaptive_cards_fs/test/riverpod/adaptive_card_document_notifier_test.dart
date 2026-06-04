import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/adaptive_card_document_notifier.dart';
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

Map<String, dynamic> _actionAndInputBaseline() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'Input.Text',
        'id': 'myText',
        'value': 'baseline',
        'errorMessage': 'baseline error',
      },
    ],
    'actions': [
      {
        'type': 'Action.Submit',
        'id': 'submitEnabled',
        'title': 'Enabled',
        'isEnabled': true,
      },
      {
        'type': 'Action.Submit',
        'id': 'submitDisabled',
        'title': 'Disabled',
        'isEnabled': false,
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

    group('validation and action overlays', () {
      late ProviderContainer actionContainer;

      setUp(() {
        actionContainer = _createContainer(_actionAndInputBaseline());
      });

      tearDown(() {
        actionContainer.dispose();
      });

      test('setInputError merges errorMessage and isInvalid', () {
        actionContainer
            .read(adaptiveCardDocumentProvider.notifier)
            .setInputError(
              'myText',
              errorMessage: 'Host error',
              isInvalid: true,
            );

        final resolved = actionContainer.read(
          resolvedElementProvider('myText'),
        );
        expect(resolved?['errorMessage'], 'Host error');
        expect(resolved?['isInvalid'], isTrue);
      });

      test('clearInputError restores baseline validation fields', () {
        final notifier =
            actionContainer.read(
                adaptiveCardDocumentProvider.notifier,
              )
              ..setInputError(
                'myText',
                errorMessage: 'Host error',
                isInvalid: true,
              )
              ..clearInputError('myText');

        expect(
          notifier.state.overlaysById['myText']?.errorMessage,
          isNull,
        );
        expect(notifier.state.overlaysById['myText']?.isInvalid, isNull);

        final resolved = actionContainer.read(
          resolvedElementProvider('myText'),
        );
        expect(resolved?['errorMessage'], 'baseline error');
        expect(resolved?.containsKey('isInvalid'), isFalse);
      });

      test('resetAllInputs clears validation overlays on inputs', () {
        final notifier =
            actionContainer.read(
                adaptiveCardDocumentProvider.notifier,
              )
              ..setInputError(
                'myText',
                errorMessage: 'Host error',
                isInvalid: true,
              )
              ..resetAllInputs();

        expect(
          notifier.state.overlaysById['myText']?.errorMessage,
          isNull,
        );
        expect(notifier.state.overlaysById['myText']?.isInvalid, isNull);

        final resolved = actionContainer.read(
          resolvedElementProvider('myText'),
        );
        expect(resolved?['errorMessage'], 'baseline error');
      });

      test('setInputValue clears validation overlays', () {
        final notifier =
            actionContainer.read(
                adaptiveCardDocumentProvider.notifier,
              )
              ..setInputError(
                'myText',
                errorMessage: 'Host error',
                isInvalid: true,
              )
              ..setInputValue('myText', 'edited');

        expect(
          notifier.state.overlaysById['myText']?.errorMessage,
          isNull,
        );
        expect(notifier.state.overlaysById['myText']?.isInvalid, isNull);
      });

      test('setActionEnabled merges into resolvedActionProvider', () {
        actionContainer
            .read(adaptiveCardDocumentProvider.notifier)
            .setActionEnabled('submitEnabled', enabled: false);

        final resolved = actionContainer.read(
          resolvedActionProvider('submitEnabled'),
        );
        expect(resolved?['isEnabled'], isFalse);
      });

      test('setActionsEnabled bulk-updates multiple actions', () {
        actionContainer
            .read(adaptiveCardDocumentProvider.notifier)
            .setActionsEnabled({
              'submitEnabled': false,
              'submitDisabled': true,
            });

        expect(
          actionContainer.read(
            resolvedActionProvider('submitEnabled'),
          )?['isEnabled'],
          isFalse,
        );
        expect(
          actionContainer.read(
            resolvedActionProvider('submitDisabled'),
          )?['isEnabled'],
          isTrue,
        );
        expect(
          actionContainer
              .read(adaptiveCardDocumentProvider)
              .actionOverlaysById['submitEnabled']
              ?.isEnabled,
          isFalse,
        );
        expect(
          actionContainer
              .read(adaptiveCardDocumentProvider)
              .actionOverlaysById['submitDisabled']
              ?.isEnabled,
          isTrue,
        );
      });

      test('baseline isEnabled false without overlay stays false', () {
        final resolved = actionContainer.read(
          resolvedActionProvider('submitDisabled'),
        );
        expect(resolved?['isEnabled'], isFalse);
      });

      test('resetAllInputs preserves actionOverlaysById', () {
        final notifier =
            actionContainer.read(
                adaptiveCardDocumentProvider.notifier,
              )
              ..setActionEnabled('submitEnabled', enabled: false)
              ..setInputError(
                'myText',
                errorMessage: 'Host error',
                isInvalid: true,
              )
              ..resetAllInputs();

        expect(
          notifier.state.actionOverlaysById['submitEnabled']?.isEnabled,
          isFalse,
        );
        expect(
          notifier.state.overlaysById['myText']?.errorMessage,
          isNull,
        );
      });
    });

    group('TextBlock text overlays', () {
      late ProviderContainer textContainer;

      setUp(() {
        textContainer = _createContainer({
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': [
            {
              'type': 'TextBlock',
              'id': 'status',
              'text': 'Baseline status',
            },
            {
              'type': 'Input.Text',
              'id': 'myText',
              'value': '',
            },
          ],
        });
      });

      tearDown(() {
        textContainer.dispose();
      });

      test('setText merges into resolvedElementProvider', () {
        textContainer
            .read(adaptiveCardDocumentProvider.notifier)
            .setText('status', 'Updated status');

        final resolved = textContainer.read(resolvedElementProvider('status'));
        expect(resolved?['text'], 'Updated status');
      });

      test('clearText restores baseline text', () {
        final notifier =
            textContainer.read(
                adaptiveCardDocumentProvider.notifier,
              )
              ..setText('status', 'Updated status')
              ..clearText('status');

        expect(notifier.state.overlaysById['status']?.text, isNull);

        final resolved = textContainer.read(resolvedElementProvider('status'));
        expect(resolved?['text'], 'Baseline status');
      });

      test('resetAllInputs preserves TextBlock text overlay', () {
        final notifier =
            textContainer.read(
                adaptiveCardDocumentProvider.notifier,
              )
              ..setText('status', 'Updated status')
              ..setInputValue('myText', 'typed')
              ..resetAllInputs();

        expect(notifier.state.overlaysById['status']?.text, 'Updated status');
        expect(notifier.state.overlaysById['myText']?.inputValue, isNull);

        final resolvedStatus = textContainer.read(
          resolvedElementProvider('status'),
        );
        expect(resolvedStatus?['text'], 'Updated status');
      });
    });

    group('applyUpdates', () {
      test('bulk merge updates multiple properties in one revision', () {
        final notifier = container.read(adaptiveCardDocumentProvider.notifier);
        final startRevision = notifier.state.revision;

        notifier.applyUpdates(
          elements: [
            const AdaptiveElementUpdate(
              id: 'myText',
              value: 'patched',
            ),
            const AdaptiveElementUpdate(
              id: 'visibleBlock',
              isVisible: false,
              text: 'Updated',
            ),
          ],
        );

        expect(notifier.state.revision, startRevision + 1);
        expect(
          container.read(resolvedElementProvider('myText'))?['value'],
          'patched',
        );
        expect(
          container.read(resolvedElementProvider('visibleBlock'))?['isVisible'],
          isFalse,
        );
        expect(
          container.read(resolvedElementProvider('visibleBlock'))?['text'],
          'Updated',
        );
      });

      test('applyUpdates ignores unknown ids', () {
        final notifier = container.read(adaptiveCardDocumentProvider.notifier)
          ..applyUpdates(
            elements: [
              const AdaptiveElementUpdate(id: 'missing', value: 'x'),
            ],
          );

        expect(notifier.state.overlaysById.containsKey('missing'), isFalse);
      });

      test('applyUpdates clear flags work', () {
        final notifier = container.read(adaptiveCardDocumentProvider.notifier)
          ..setInputError('myText', errorMessage: 'err', isInvalid: true)
          ..setInputValue('myText', 'typed')
          ..applyUpdates(
            elements: const [
              AdaptiveElementUpdate(id: 'myText', clearError: true),
            ],
          );

        expect(notifier.state.overlaysById['myText']?.errorMessage, isNull);
        expect(notifier.state.overlaysById['myText']?.inputValue, 'typed');
      });

      test('applyUpdates choices clears value unless value also set', () {
        final notifier = container.read(adaptiveCardDocumentProvider.notifier)
          ..setInputValue('myChoice', 'static')
          ..applyUpdates(
            elements: const [
              AdaptiveElementUpdate(
                id: 'myChoice',
                choices: [Choice(title: 'New', value: 'new')],
              ),
            ],
          );

        expect(
          container.read(resolvedElementProvider('myChoice'))?['choices'],
          [
            {'title': 'New', 'value': 'new'},
          ],
        );
        expect(
          notifier.state.overlaysById['myChoice']?.inputValue,
          isNull,
        );
        expect(
          container.read(resolvedElementProvider('myChoice'))?['value'],
          'static',
        );
      });

      test('seedInputValues matches applyUpdates value-only semantics', () {
        final notifier = container.read(adaptiveCardDocumentProvider.notifier)
          ..setInputError('myText', errorMessage: 'err', isInvalid: true)
          ..seedInputValues({'myText': 'seeded'});

        expect(notifier.state.overlaysById['myText']?.inputValue, 'seeded');
        expect(notifier.state.overlaysById['myText']?.errorMessage, isNull);
      });

      test('updatesFromPatchMap parses scalar and patch entries', () {
        final parsed =
            AdaptiveCardDocumentNotifier.updatesFromPatchMapWithNodes(
              {
                'myText': 'scalar',
                'visibleBlock': {'text': 'Hi', 'isVisible': false},
              },
              nodesById: container.read(adaptiveCardDocumentProvider).nodesById,
            );

        expect(parsed.elements, hasLength(2));
        expect(parsed.elements.first.id, 'myText');
        expect(parsed.elements.first.value, 'scalar');
        expect(parsed.elements.last.text, 'Hi');
      });

      test('setIsRequired and setUrl merge into resolved element', () {
        final imageBaseline = _createContainer({
          'type': 'AdaptiveCard',
          'body': [
            {
              'type': 'Image',
              'id': 'img',
              'url': 'https://baseline.example/image.png',
            },
            {
              'type': 'Input.Text',
              'id': 'reqField',
              'isRequired': false,
            },
          ],
        });

        imageBaseline.read(adaptiveCardDocumentProvider.notifier)
          ..setUrl('img', 'https://signed.example/image.png')
          ..setIsRequired('reqField', required: true);

        expect(
          imageBaseline.read(resolvedElementProvider('img'))?['url'],
          'https://signed.example/image.png',
        );
        expect(
          imageBaseline.read(
            resolvedElementProvider('reqField'),
          )?['isRequired'],
          isTrue,
        );

        imageBaseline.dispose();
      });

      test('applyUpdates merges label, placeholder, title, and tooltip', () {
        final actionCard = _createContainer({
          'type': 'AdaptiveCard',
          'body': [
            {
              'type': 'Input.Text',
              'id': 'name',
              'label': 'Name',
              'placeholder': 'Enter name',
            },
          ],
          'actions': [
            {
              'type': 'Action.Submit',
              'id': 'submit',
              'title': 'Send',
              'tooltip': 'Submit form',
            },
          ],
        });

        actionCard
            .read(adaptiveCardDocumentProvider.notifier)
            .applyUpdates(
              elements: const [
                AdaptiveElementUpdate(
                  id: 'name',
                  label: 'Full name',
                  placeholder: 'Type here',
                ),
              ],
              actions: const [
                AdaptiveActionUpdate(
                  id: 'submit',
                  title: 'Submit now',
                  tooltip: 'Send the form',
                ),
              ],
            );

        expect(
          actionCard.read(resolvedElementProvider('name'))?['label'],
          'Full name',
        );
        expect(
          actionCard.read(resolvedElementProvider('name'))?['placeholder'],
          'Type here',
        );
        expect(
          actionCard.read(resolvedActionProvider('submit'))?['title'],
          'Submit now',
        );
        expect(
          actionCard.read(resolvedActionProvider('submit'))?['tooltip'],
          'Send the form',
        );

        actionCard.dispose();
      });

      test('updatesFromPatchMap routes action title patches by node type', () {
        final nodes = {
          'submit': {
            'type': 'Action.Submit',
            'id': 'submit',
            'title': 'Send',
          },
        };
        final parsed =
            AdaptiveCardDocumentNotifier.updatesFromPatchMapWithNodes(
              {
                'submit': {'title': 'Go'},
              },
              nodesById: nodes,
            );

        expect(parsed.elements, isEmpty);
        expect(parsed.actions, hasLength(1));
        expect(parsed.actions.single.title, 'Go');

        final parsedInput =
            AdaptiveCardDocumentNotifier.updatesFromPatchMapWithNodes(
              {
                'name': {'label': 'Name'},
              },
              nodesById: {
                'name': {'type': 'Input.Text', 'id': 'name'},
              },
            );
        expect(parsedInput.actions, isEmpty);
        expect(parsedInput.elements.single.label, 'Name');
      });
    });
  });
}
