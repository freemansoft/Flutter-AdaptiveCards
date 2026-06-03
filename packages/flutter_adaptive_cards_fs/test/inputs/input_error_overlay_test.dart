import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
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
      container.read(adaptiveCardDocumentProvider).overlaysById['errText']
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

    final cardState = tester.state<RawAdaptiveCardState>(
      find.byType(RawAdaptiveCard),
    )
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

    container.read(adaptiveCardDocumentProvider.notifier).setInputError(
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
}
