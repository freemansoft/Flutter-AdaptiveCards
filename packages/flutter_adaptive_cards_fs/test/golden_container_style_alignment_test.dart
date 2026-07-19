import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// General golden proving three renderer capabilities together: a container's
/// fill comes from HostConfig `containerStyles.<style>.backgroundColor`
/// (not a hardcoded color), a ColumnSet with `stretch` + `auto` columns
/// produces a content-hugging container pushed to whichever side the
/// `stretch` spacer is not on, and `roundedCorners: true` (a Teams Adaptive
/// Cards property) rounds both bubbles' fills with radius resolved via
/// HostConfig (default 8) — the shape this sample models is a chat bubble.
void main() {
  testWidgets(
    'HostConfig container-style backgroundColor + ColumnSet alignment + '
    'roundedCorners golden',
    (tester) async {
      configureTestView(size: const Size(420, 240));

      // Custom container-style colors: a bug that ignored HostConfig would
      // render the wrong fills and diff against this golden.
      final hostConfig = HostConfig.fromJson(const {
        'containerStyles': {
          'default': {'backgroundColor': '#FFFFFFFF'},
          'emphasis': {'backgroundColor': '#FFECECEC'},
          'accent': {'backgroundColor': '#FF1565C0'},
        },
      });
      final hostConfigs = HostConfigs(light: hostConfig, dark: hostConfig);

      const key = ValueKey('paint');
      await tester.pumpWidget(
        getTestWidgetFromPath(
          path: 'hostconfig_container_style_alignment.json',
          key: key,
          hostConfigs: hostConfigs,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          getGoldenPath('hostconfig_container_style_alignment-base.png'),
        ),
      );
    },
    tags: ['golden'],
  );
}
