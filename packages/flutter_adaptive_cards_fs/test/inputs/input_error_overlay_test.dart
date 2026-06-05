import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder inputFinder) {
  return ProviderScope.containerOf(tester.element(inputFinder));
}

void main() {
  testWidgets('setInputError shows error message and validation state', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'errText',
          'label': 'Name',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'input error overlay',
      ),
    );
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(textMap));
    final container = _documentContainer(tester, inputFinder);

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputError(
          'errText',
          errorMessage: 'Required field',
          isInvalid: true,
        );
    await tester.pump();

    expect(find.text('Required field'), findsOneWidget);

    final resolved = container.read(resolvedElementProvider('errText'));
    expect(resolved?['isInvalid'], isTrue);
  });

  testWidgets('clearInputError hides overlay error text', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'errText',
          'label': 'Name',
          'errorMessage': 'Baseline message',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'clear input error overlay',
      ),
    );
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(textMap));
    final container = _documentContainer(tester, inputFinder);
    final notifier = container.read(adaptiveCardDocumentProvider.notifier)
      ..setInputError(
        'errText',
        errorMessage: 'Overlay message',
        isInvalid: true,
      );
    await tester.pump();
    expect(find.text('Overlay message'), findsOneWidget);

    notifier.clearInputError('errText');
    await tester.pump();
    expect(find.text('Overlay message'), findsNothing);
  });

  testWidgets('editing input clears validation overlay', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'errText',
          'label': 'Name',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'edit clears input error overlay',
      ),
    );
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(textMap));
    final container = _documentContainer(tester, inputFinder);

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputError(
          'errText',
          errorMessage: 'Required field',
          isInvalid: true,
        );
    await tester.pump();
    expect(find.text('Required field'), findsOneWidget);

    await tester.enterText(inputFinder, 'typed');
    await tester.pump();

    expect(
      container
          .read(adaptiveCardDocumentProvider)
          .overlaysById['errText']
          ?.isInvalid,
      isNull,
    );
    expect(find.text('Required field'), findsNothing);
  });

  testWidgets('RawAdaptiveCardState.setInputError delegates to notifier', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'errText',
          'label': 'Name',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'host setInputError',
      ),
    );
    await tester.pumpAndSettle();

    tester
        .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
        .setInputError('errText', message: 'From host');
    await tester.pump();

    expect(find.text('From host'), findsOneWidget);
  });

  testWidgets('RawAdaptiveCardState.clearInputError delegates to notifier', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'errText',
          'label': 'Name',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'host clearInputError',
      ),
    );
    await tester.pumpAndSettle();

    tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
      ..setInputError('errText', message: 'From host')
      ..clearInputError('errText');
    await tester.pump();

    expect(find.text('From host'), findsNothing);
  });

  testWidgets('setInputError shows overlay error on Input.Number', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.Number',
          'id': 'errNumber',
          'label': 'Age',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'number input error overlay',
      ),
    );
    await tester.pumpAndSettle();

    final numMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(numMap));
    final container = _documentContainer(tester, inputFinder);

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputError(
          'errNumber',
          errorMessage: 'Invalid age',
          isInvalid: true,
        );
    await tester.pump();

    expect(find.text('Invalid age'), findsOneWidget);
    expect(
      container.read(resolvedElementProvider('errNumber'))?['isInvalid'],
      isTrue,
    );
  });

  testWidgets('applyUpdates sets validation on multiple inputs', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {'type': 'Input.Text', 'id': 'email', 'label': 'Email'},
        {'type': 'Input.Text', 'id': 'phone', 'label': 'Phone'},
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'batch validation'),
    );
    await tester.pumpAndSettle();

    tester
        .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
        .applyUpdates(
          elements: const [
            AdaptiveElementUpdate(
              id: 'email',
              errorMessage: 'Invalid email',
              isInvalid: true,
            ),
            AdaptiveElementUpdate(id: 'phone', clearError: true),
          ],
        );
    await tester.pump();

    expect(find.text('Invalid email'), findsOneWidget);
  });

  testWidgets('Form required failure sets overlay isInvalid', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'requiredText',
          'label': 'Required',
          'isRequired': true,
          'errorMessage': 'This field is required',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'form overlay validation'),
    );
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final container = _documentContainer(
      tester,
      find.byKey(generateWidgetKey(textMap)),
    );

    expect(
      container.read(resolvedElementProvider('requiredText'))?['isInvalid'],
      isNot(true),
    );

    final cardState = tester.state<AdaptiveCardElementState>(
      find.byType(AdaptiveCardElement),
    );
    expect(cardState.formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(
      container.read(resolvedElementProvider('requiredText'))?['isInvalid'],
      isTrue,
    );
    expect(find.text('This field is required'), findsOneWidget);

    await tester.enterText(find.byKey(generateWidgetKey(textMap)), 'ok');
    await tester.pump();

    expect(
      container.read(resolvedElementProvider('requiredText'))?['isInvalid'],
      isNull,
    );
  });

  testWidgets(
    'isInvalid overlay shows baseline errorMessage then overlay replaces it',
    (WidgetTester tester) async {
      const baselineMessage = 'Baseline message';
      const overlayMessage = 'Overlay message';
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'errText',
            'label': 'Name',
            'errorMessage': baselineMessage,
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'baseline then overlay errorMessage',
        ),
      );
      await tester.pumpAndSettle();

      final textMap = map['body'][0] as Map<String, dynamic>;
      final container = _documentContainer(
        tester,
        find.byKey(generateWidgetKey(textMap)),
      );
      final notifier = container.read(adaptiveCardDocumentProvider.notifier);

      expect(find.text(baselineMessage), findsNothing);
      expect(find.text(overlayMessage), findsNothing);

      notifier.setInputError('errText', isInvalid: true);
      await tester.pump();

      expect(find.text(baselineMessage), findsOneWidget);
      expect(find.text(overlayMessage), findsNothing);
      expect(
        container.read(resolvedElementProvider('errText'))?['isInvalid'],
        isTrue,
      );
      expect(
        container.read(resolvedElementProvider('errText'))?['errorMessage'],
        baselineMessage,
      );

      notifier.setInputError(
        'errText',
        errorMessage: overlayMessage,
        isInvalid: true,
      );
      await tester.pump();

      expect(find.text(baselineMessage), findsNothing);
      expect(find.text(overlayMessage), findsOneWidget);
      expect(
        container.read(resolvedElementProvider('errText'))?['errorMessage'],
        overlayMessage,
      );
      expect(
        container.read(resolvedElementProvider('errText'))?['isInvalid'],
        isTrue,
      );
    },
  );
}
