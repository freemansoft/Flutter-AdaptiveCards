import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';

// probeAssetsDir() is the only thing standing between a probe and silently
// reading the wrong assets/ directory — every recorded digest and every
// prompt actually sent to a model comes from whatever path it returns, and
// this repo has more than one directory literally named `assets/`
// (widgetbook/ has its own). This is an ordinary unit test of that one
// function's fallback-walk logic, exercised against temp directories rather
// than the real tree so it can assert both the accept and the reject path
// without touching the process-wide working directory (see the comment on
// `startDir` below for why that matters under `package:test`).

void main() {
  group('probeAssetsDir', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('probe_assets_dir_test');
    });

    tearDown(() {
      tempRoot.deleteSync(recursive: true);
    });

    test(
      'a directory merely named assets is not accepted without the '
      'sentinel asset',
      () {
        // Mirrors the reported hazard: a sibling package (widgetbook/) has
        // its own unrelated assets/ directory. Walking upward from a start
        // directory whose immediate assets/ lacks card_system_prompt.txt
        // must not accept it just because the name matches — and since
        // this temp tree has no adaptive_chat_server_dart/assets above it
        // either, the walk should exhaust every ancestor and report the
        // informative failure rather than silently returning the wrong
        // directory.
        //
        // startDir substitutes for Directory.current here rather than
        // reassigning the process cwd: package:test runs test files
        // concurrently, and Directory.current is process-wide, so mutating
        // it would make every other file's relative-path lookups racy —
        // this broke check_results_test.dart the first time this test was
        // written with Directory.current = tempRoot.
        final decoy = Directory('${tempRoot.path}/assets')
          ..createSync(recursive: true);
        File('${decoy.path}/unrelated.json').writeAsStringSync('{}');

        expect(
          () => probeAssetsDir(startDir: tempRoot),
          throwsA(
            isA<FileSystemException>().having(
              (e) => e.message,
              'message',
              contains('Could not locate the assets/ directory'),
            ),
          ),
        );
      },
    );

    test('a directory holding the sentinel asset is accepted', () {
      final real = Directory('${tempRoot.path}/assets')
        ..createSync(recursive: true);
      File(
        '${real.path}/card_system_prompt.txt',
      ).writeAsStringSync('system prompt');

      // Compared by resolving both sides rather than as raw strings: on
      // macOS, systemTemp sits under a /private symlink that
      // resolveSymbolicLinksSync() collapses, so a literal string
      // comparison of the two paths can disagree despite naming the same
      // directory.
      expect(
        Directory(
          probeAssetsDir(startDir: tempRoot),
        ).resolveSymbolicLinksSync(),
        Directory(real.path).resolveSymbolicLinksSync(),
      );
    });
  });
}
