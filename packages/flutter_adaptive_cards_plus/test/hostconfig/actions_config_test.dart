import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards_plus/src/hostconfig/actions_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActionsConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/actions_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ActionsConfig.fromJson(jsonMap);

      expect(config.actionsOrientation, 'vertical');
      expect(config.actionAlignment, 'center');
      expect(config.buttonSpacing, 20);
      expect(config.maxActions, 10);
      expect(config.spacing, 'large');

      expect(config.showCard.actionMode, 'popup');
      expect(config.showCard.style, 'default');
      expect(config.showCard.inlineTopMargin, 32);

      expect(config.iconPlacement, 'leftOfTitle');
      expect(config.iconSize, 40);
    });

    test('should use default values when JSON is empty', () {
      final config = ActionsConfig.fromJson({});

      expect(config.actionsOrientation, 'horizontal');
      expect(config.actionAlignment, 'stretch');
      expect(config.buttonSpacing, 10);
      expect(config.maxActions, 5);
      expect(config.spacing, 'default');

      expect(config.showCard.actionMode, 'inline');
      expect(config.showCard.style, 'emphasis');
      expect(config.showCard.inlineTopMargin, 16);

      expect(config.iconPlacement, 'aboveTitle');
      expect(config.iconSize, 30);
    });
  });
}
