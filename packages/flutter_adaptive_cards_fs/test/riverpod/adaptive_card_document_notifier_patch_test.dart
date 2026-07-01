import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/adaptive_card_document_notifier.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baseline() => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': [
    {
      'type': 'Input.Text',
      'id': 'txt',
      'value': 'base',
      'label': 'BaseLabel',
      'placeholder': 'BasePh',
      'isRequired': false,
    },
    {
      'type': 'Input.ChoiceSet',
      'id': 'cs',
      'choices': [
        {'title': 'Static', 'value': 'static'},
      ],
    },
    {'type': 'TextBlock', 'id': 'tb', 'text': 'baseText'},
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
    {'type': 'Image', 'id': 'img', 'url': 'https://e/base.png'},
  ],
  'actions': [
    {'type': 'Action.Submit', 'id': 'act', 'title': 'BaseTitle'},
  ],
};

ProviderContainer _container() => ProviderContainer(
  overrides: [baselineMapProvider.overrideWithValue(_baseline())],
);

void main() {
  group('updatesFromPatchMap + applyUpdates round trip', () {
    late ProviderContainer container;
    late AdaptiveCardDocumentNotifier notifier;

    setUp(() {
      container = _container();
      notifier = container.read(adaptiveCardDocumentProvider.notifier);
    });
    tearDown(() => container.dispose());

    test('routes element and action patches to merged overlays', () {
      final updates = notifier.updatesFromPatchMap({
        'txt': {
          'isRequired': true,
          'label': 'L',
          'placeholder': 'P',
          'value': 'V',
        },
        'cs': {
          'choices': [
            {'title': 'X', 'value': 'x'},
          ],
          'queryCount': 5,
          'querySkip': 2,
          'querySearchText': 'q',
        },
        'tb': {'text': 'newText'},
        'fs': {
          'facts': [
            {'title': 'A', 'value': '9'},
          ],
        },
        'rtb': {
          'inlines': [
            {'type': 'TextRun', 'text': 'run'},
          ],
        },
        'img': {'url': 'https://e/x.png'},
        'act': {
          'isEnabled': false,
          'title': 'T',
          'tooltip': 'tt',
          'iconUrl': 'i',
        },
      });

      notifier.applyUpdates(
        elements: updates.elements,
        actions: updates.actions,
      );

      final txt = container.read(resolvedElementProvider('txt'));
      expect(txt?['isRequired'], true);
      expect(txt?['label'], 'L');
      expect(txt?['placeholder'], 'P');
      expect(txt?['value'], 'V');

      final cs = container.read(resolvedElementProvider('cs'));
      expect((cs?['choices'] as List).first['value'], 'x');
      final csOverlay = notifier.state.overlaysById['cs'];
      expect(csOverlay?.queryCount, 5);
      expect(csOverlay?.querySkip, 2);
      expect(csOverlay?.querySearchText, 'q');

      expect(container.read(resolvedElementProvider('tb'))?['text'], 'newText');
      expect(
        (container.read(resolvedElementProvider('fs'))?['facts'] as List)
            .first['title'],
        'A',
      );
      expect(
        (container.read(resolvedElementProvider('rtb'))?['inlines'] as List)
            .first['text'],
        'run',
      );
      expect(
        container.read(resolvedElementProvider('img'))?['url'],
        'https://e/x.png',
      );

      final act = container.read(resolvedActionProvider('act'));
      expect(act?['isEnabled'], false);
      expect(act?['title'], 'T');
      expect(act?['tooltip'], 'tt');
      expect(act?['iconUrl'], 'i');
    });

    test('clear patches revert resolved values to baseline', () {
      notifier
        ..applyUpdates(
          elements: notifier.updatesFromPatchMap({
            'txt': {
              'isRequired': true,
              'label': 'L',
              'placeholder': 'P',
              'value': 'V',
            },
            'cs': {
              'choices': [
                {'title': 'X', 'value': 'x'},
              ],
            },
            'tb': {'text': 'newText'},
            'fs': {
              'facts': [
                {'title': 'A', 'value': '9'},
              ],
            },
            'rtb': {
              'inlines': [
                {'type': 'TextRun', 'text': 'run'},
              ],
            },
            'img': {'url': 'https://e/x.png'},
          }).elements,
        )
        ..applyUpdates(
          elements: notifier.updatesFromPatchMap({
            'txt': {
              'clearIsRequired': true,
              'clearLabel': true,
              'clearPlaceholder': true,
              'clearValue': true,
            },
            'cs': {'clearChoices': true},
            'tb': {'clearText': true},
            'fs': {'clearFacts': true},
            'rtb': {'clearInlines': true},
            'img': {'clearUrl': true},
          }).elements,
          actions: notifier.updatesFromPatchMap({
            'act': {
              'clearTitle': true,
              'clearTooltip': true,
              'clearIconUrl': true,
            },
          }).actions,
        );

      final txt = container.read(resolvedElementProvider('txt'));
      expect(txt?['label'], 'BaseLabel');
      expect(txt?['placeholder'], 'BasePh');
      expect(txt?['value'], 'base');
      expect(txt?['isRequired'], false);

      expect(
        (container.read(resolvedElementProvider('cs'))?['choices'] as List)
            .first['value'],
        'static',
      );
      expect(
        container.read(resolvedElementProvider('tb'))?['text'],
        'baseText',
      );
      expect(
        (container.read(resolvedElementProvider('fs'))?['facts'] as List)
            .first['title'],
        'BA',
      );
      expect(
        (container.read(resolvedElementProvider('rtb'))?['inlines'] as List)
            .first['text'],
        'Base',
      );
      expect(
        container.read(resolvedElementProvider('img'))?['url'],
        'https://e/base.png',
      );
      expect(
        container.read(resolvedActionProvider('act'))?['title'],
        'BaseTitle',
      );
    });
  });

  group('direct overlay clear and session helpers', () {
    late ProviderContainer container;
    late AdaptiveCardDocumentNotifier notifier;

    setUp(() {
      container = _container();
      notifier = container.read(adaptiveCardDocumentProvider.notifier);
    });
    tearDown(() => container.dispose());

    test('clearIsRequired reverts to baseline isRequired', () {
      notifier.setIsRequired('txt', required: true);
      expect(
        container.read(resolvedElementProvider('txt'))?['isRequired'],
        true,
      );

      notifier.clearIsRequired('txt');
      expect(
        container.read(resolvedElementProvider('txt'))?['isRequired'],
        false,
      );
    });

    test('clearUrl reverts to baseline url', () {
      notifier.setUrl('img', 'https://e/overlay.png');
      expect(
        container.read(resolvedElementProvider('img'))?['url'],
        'https://e/overlay.png',
      );

      notifier.clearUrl('img');
      expect(
        container.read(resolvedElementProvider('img'))?['url'],
        'https://e/base.png',
      );
    });

    test('setDataQuerySession stores typeahead fields on the overlay', () {
      notifier.setDataQuerySession('cs', count: 3, skip: 1, searchText: 's');

      final overlay = notifier.state.overlaysById['cs'];
      expect(overlay?.queryCount, 3);
      expect(overlay?.querySkip, 1);
      expect(overlay?.querySearchText, 's');
    });

    test('appendChoices twice merges onto the existing overlay choices', () {
      notifier
        ..appendChoices('cs', const [Choice(title: 'One', value: '1')])
        ..appendChoices('cs', const [Choice(title: 'Two', value: '2')]);

      final choices = notifier.state.overlaysById['cs']?.choices;
      expect(choices?.map((c) => c.value), containsAll(['static', '1', '2']));
    });
  });
}
