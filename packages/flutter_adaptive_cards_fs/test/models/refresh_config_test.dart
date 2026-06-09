import 'package:flutter_adaptive_cards_fs/src/models/refresh_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RefreshConfig.fromJson parses action, userIds, expires', () {
    final config = RefreshConfig.fromJson({
      'action': {'type': 'Action.Execute', 'verb': 'refreshCard'},
      'userIds': ['a'],
      'expires': '2026-06-08T12:00:00Z',
    });
    expect(config.action?['verb'], 'refreshCard');
    expect(config.userIds, ['a']);
    expect(config.expires, isNotNull);
  });

  test('RefreshConfig.fromJson handles missing optional fields', () {
    final config = RefreshConfig.fromJson({
      'action': {'type': 'Action.Execute', 'verb': 'refreshCard'},
    });
    expect(config.userIds, isNull);
    expect(config.expires, isNull);
  });
}
