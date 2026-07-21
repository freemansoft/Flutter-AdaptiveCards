import 'package:adaptive_chat_client/src/chat_host_config.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chatHostConfigs builds a light/dark pair defaulting to light', () {
    final configs = chatHostConfigs();
    expect(configs, isA<HostConfigs>());
    expect(configs.current, same(configs.light));
    expect(configs.light.cornerRadius, 16);
    expect(configs.dark.cornerRadius, 16);
  });
}
