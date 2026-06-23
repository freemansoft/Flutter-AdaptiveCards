import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'Action.InsertImage renders a button and shows a stub snackbar on tap',
    (tester) async {
      final card = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': <Map<String, dynamic>>[],
        'actions': [
          {
            'type': 'Action.InsertImage',
            'id': 'insertImg',
            'title': 'Insert',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: card, title: 'insert image'),
      );
      await tester.pump();

      final actionMap = (card['actions']! as List)[0] as Map<String, dynamic>;
      // The action wrapper and its inner IconButtonAction share the id-derived
      // key, so the key resolves to widgets in the tree for this action.
      expect(find.byKey(generateAdaptiveWidgetKey(actionMap)), findsWidgets);
      expect(find.text('Insert'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // kick off the SnackBar entrance animation

      expect(
        find.text('Action.InsertImage triggered (Not fully implemented)'),
        findsOneWidget,
      );
    },
  );
}
