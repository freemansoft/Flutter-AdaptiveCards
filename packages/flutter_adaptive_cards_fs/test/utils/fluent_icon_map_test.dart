import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/fluent_icon_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveFluentIcon — newly added canonical names', () {
    const sample = <String>[
      'play', 'pause', 'stop', 'mic', 'bookmark', 'favorite', 'cart',
      'work', 'school', 'book', 'dashboard', 'analytics', 'chart',
      'lightbulb', 'verified', 'shield', 'account', 'trophy', 'comment',
      'reply', 'archive', 'cloudupload', 'clouddownload', 'checkcircle',
      'visibilityoff', 'calendarevent', 'timer', 'palette', 'tag',
      'restaurant', 'coffee', 'car', 'wifi', 'weather',
    ];

    test('each sample name resolves to a non-fallback icon (filled & regular)',
        () {
      for (final name in sample) {
        final filled = resolveFluentIcon(name, filled: true);
        final regular = resolveFluentIcon(name, filled: false);
        expect(filled, isNotNull, reason: '$name (filled) should resolve');
        expect(filled, isNot(Icons.help_outline), reason: '$name not fallback');
        expect(regular, isNotNull, reason: '$name (regular) should resolve');
      }
    });

    test('unknown name returns null (caller falls back to help_outline)', () {
      expect(resolveFluentIcon('definitely-not-an-icon', filled: true), isNull);
    });

    test('normalization variants resolve identically', () {
      expect(
        resolveFluentIcon('CloudUpload', filled: true),
        resolveFluentIcon('cloud_upload', filled: true),
      );
      expect(
        resolveFluentIcon('cloud-upload', filled: true),
        resolveFluentIcon('cloudupload', filled: true),
      );
    });
  });

  group('resolveFluentIcon — aliases', () {
    const aliases = <String, String>{
      'trash': 'delete',
      'bin': 'delete',
      'gear': 'settings',
      'options': 'settings',
      'pencil': 'edit',
      'find': 'search',
      'email': 'mail',
      'envelope': 'mail',
      'user': 'person',
      'contact': 'person',
      'group': 'people',
      'team': 'people',
      'photo': 'image',
      'picture': 'image',
      'information': 'info',
      'alert': 'warning',
      'error': 'errorcircle',
      'accept': 'checkmark',
      'check': 'checkmark',
      'date': 'calendar',
      'house': 'home',
      'question': 'help',
      'idea': 'lightbulb',
      'trophy_award': 'trophy',
    };

    test('each alias resolves to the same filled icon as its canonical name', () {
      aliases.forEach((alias, canonical) {
        expect(
          resolveFluentIcon(alias, filled: true),
          resolveFluentIcon(canonical, filled: true),
          reason: '"$alias" should match "$canonical"',
        );
      });
    });
  });

  test('catalog has >= 150 keys and every entry has a non-null filled icon', () {
    expect(kFluentIconMap.length, greaterThanOrEqualTo(150));
    for (final entry in kFluentIconMap.values) {
      expect(entry.filled, isA<IconData>());
    }
  });
}
