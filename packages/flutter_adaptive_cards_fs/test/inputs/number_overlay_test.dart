import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder inputFinder) {
  return ProviderScope.containerOf(tester.element(inputFinder));
}

void main() {
  testWidgets('initData seeds number overlay in resolvedElementProvider', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Number',
          'id': 'initNumber',
          'label': 'Init Number',
          'min': 10,
          'max': 20,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'Number initData overlay',
        initData: const {'initNumber': '15'},
      ),
    );
    await tester.pumpAndSettle();

    final numMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(numMap));
    final container = _documentContainer(tester, inputFinder);

    expect(
      container.read(resolvedElementProvider('initNumber'))?['value'],
      '15',
    );

    final field = tester.widget<TextFormField>(inputFinder);
    expect(field.controller!.text, '15');
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
}
