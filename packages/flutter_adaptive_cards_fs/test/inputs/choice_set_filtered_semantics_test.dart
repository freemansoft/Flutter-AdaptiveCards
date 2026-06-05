import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'filtered ChoiceSet dismiss does not add invisible semantics nodes',
    (WidgetTester tester) async {
      final semanticsHandle = SemanticsBinding.instance.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Semantics(
                container: true,
                explicitChildNodes: true,
                identifier: 'SemanticsAddon.Root',
                child: getTestWidgetFromMap(
                  map: {
                    'type': 'AdaptiveCard',
                    'version': '1.5',
                    'body': [
                      {
                        'type': 'Input.ChoiceSet',
                        'id': 'country',
                        'style': 'filtered',
                        'label': 'Country',
                        'choices': [
                          {'title': 'USA', 'value': 'usa'},
                          {'title': 'France', 'value': 'france'},
                          {'title': 'India', 'value': 'india'},
                        ],
                        'valueChangedAction': {
                          'type': 'Action.ResetInputs',
                          'targetInputIds': ['city'],
                        },
                      },
                      {
                        'type': 'Input.ChoiceSet',
                        'id': 'city',
                        'style': 'compact',
                        'label': 'City',
                        'choices': [
                          {'title': 'None Selected', 'value': ''},
                          {'title': 'Paris', 'value': 'paris'},
                          {'title': 'Lyon', 'value': 'lyon'},
                        ],
                        'value': 'lyon',
                      },
                    ],
                  },
                  title: 'filtered semantics',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(generateWidgetKeyFromId('country')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('country')).last,
          'fr',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('france').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      } finally {
        semanticsHandle.dispose();
      }
    },
  );
}
