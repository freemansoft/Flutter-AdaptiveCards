import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

const Map<String, dynamic> _enabledAction = {
  'type': 'Action.Submit',
  'id': 'submitEnabled',
  'title': 'Enabled Submit',
};

const Map<String, dynamic> _disabledAction = {
  'type': 'Action.Submit',
  'id': 'submitDisabled',
  'title': 'Disabled Submit',
  'isEnabled': false,
};

const Map<String, dynamic> _submitAction = {
  'type': 'Action.Submit',
  'id': 'submit',
  'title': 'Send',
  'tooltip': 'Submit the form',
};

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

ElevatedButton _elevatedButtonUnderAction(
  WidgetTester tester,
  Map<String, dynamic> actionMap,
) {
  final actionFinder = find.byKey(generateAdaptiveWidgetKey(actionMap));
  final buttonFinder = find.descendant(
    of: actionFinder,
    matching: find.byType(ElevatedButton),
  );
  return tester.widget<ElevatedButton>(buttonFinder);
}

Finder _actionButtonFinder(Map<String, dynamic> actionMap) {
  return find.descendant(
    of: find.byKey(generateAdaptiveWidgetKey(actionMap)),
    matching: find.byType(ElevatedButton),
  );
}

Finder _namedSubmitButtonFinder() {
  return find.descendant(
    of: find.byKey(generateAdaptiveWidgetKey(_submitAction)),
    matching: find.byType(ElevatedButton),
  );
}

void main() {
  testWidgets('baseline isEnabled false disables submit button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromPath(
        path: 'v1.5/action_is_enabled.json',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _elevatedButtonUnderAction(tester, _disabledAction).onPressed,
      isNull,
    );
    expect(
      _elevatedButtonUnderAction(tester, _enabledAction).onPressed,
      isNotNull,
    );
  });

  testWidgets('setActionEnabled toggles submit handler', (
    WidgetTester tester,
  ) async {
    var submitCount = 0;
    await tester.pumpWidget(
      getTestWidgetFromPath(
        path: 'v1.5/action_is_enabled.json',
        onSubmit: (_) => submitCount++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_actionButtonFinder(_disabledAction));
    await tester.pump();
    expect(submitCount, 0);

    final cardState = tester.state<RawAdaptiveCardState>(
      find.byType(RawAdaptiveCard),
    )..setActionEnabled('submitDisabled', enabled: true);
    await tester.pump();

    expect(
      _elevatedButtonUnderAction(tester, _disabledAction).onPressed,
      isNotNull,
    );

    await tester.tap(_actionButtonFinder(_disabledAction));
    await tester.pump();
    expect(submitCount, 1);

    cardState.setActionEnabled('submitEnabled', enabled: false);
    await tester.pump();
    expect(
      _elevatedButtonUnderAction(tester, _enabledAction).onPressed,
      isNull,
    );

    final container = ProviderScope.containerOf(
      tester.element(_actionButtonFinder(_enabledAction)),
    );
    expect(
      container.read(resolvedActionProvider('submitEnabled'))?['isEnabled'],
      isFalse,
    );
  });

  testWidgets('applyUpdates updates action title and tooltip in UI', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Form',
        },
      ],
      'actions': [_submitAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'action title tooltip overlay'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Send'), findsOneWidget);

    _cardState(tester).applyUpdates(
      actions: const [
        AdaptiveActionUpdate(
          id: 'submit',
          title: 'Submit now',
          tooltip: 'Send it',
        ),
      ],
    );
    await tester.pump();

    expect(find.text('Submit now'), findsOneWidget);
    expect(find.text('Send'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(_namedSubmitButtonFinder()),
    );
    expect(
      container.read(resolvedActionProvider('submit'))?['title'],
      'Submit now',
    );
    expect(
      container.read(resolvedActionProvider('submit'))?['tooltip'],
      'Send it',
    );
  });

  testWidgets('applyUpdatesFromMap patches action title by id', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      // cause its a test and I don't care
      // ignore: inference_failure_on_collection_literal
      'body': [],
      'actions': [_submitAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'action title from map'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdatesFromMap({
      'submit': {'title': 'Go'},
    });
    await tester.pump();

    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets(
    'Submit skips overlay-required empty field without calling host',
    (
      WidgetTester tester,
    ) async {
      var submitCount = 0;
      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'optionalNowRequired',
            'isRequired': false,
          },
        ],
        'actions': [
          {
            'type': 'Action.Submit',
            'id': 'submitAction',
            'title': 'Send',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'submit resolved isRequired',
          onSubmit: (_) => submitCount++,
        ),
      );
      await tester.pumpAndSettle();

      final textMap = map['body'][0] as Map<String, dynamic>;
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(generateWidgetKey(textMap))),
      );
      container
          .read(adaptiveCardDocumentProvider.notifier)
          .setIsRequired('optionalNowRequired', required: true);
      await tester.pump();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(submitCount, 0);

      container
          .read(adaptiveCardDocumentProvider.notifier)
          .setInputValue('optionalNowRequired', 'filled');
      await tester.pump();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(submitCount, 1);
    },
  );

  testWidgets(
    'Submit marks empty required input invalid and shows baseline errorMessage',
    (WidgetTester tester) async {
      var submitCount = 0;
      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'requiredField',
            'isRequired': true,
            'errorMessage': 'Field is required',
          },
        ],
        'actions': [
          {
            'type': 'Action.Submit',
            'id': 'submitAction',
            'title': 'Send',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'submit shows validation overlay',
          onSubmit: (_) => submitCount++,
        ),
      );
      await tester.pumpAndSettle();

      final textMap = map['body'][0] as Map<String, dynamic>;
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(generateWidgetKey(textMap))),
      );

      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(submitCount, 0);
      expect(
        container.read(resolvedElementProvider('requiredField'))?['isInvalid'],
        isTrue,
      );
      expect(find.text('Field is required'), findsOneWidget);
    },
  );
}
