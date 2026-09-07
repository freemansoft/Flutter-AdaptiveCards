import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:adaptive_chat_server_dart/src/seed_card.dart';
import 'package:test/test.dart';

// Two different kinds of test share this file. "the shipped seed card" below
// is a data-consistency check, not a behavioral test: it pins
// assets/seed_card.json's bytes against the exact exchange every recorded
// shape-coverage figure in ModelBehavior.md was measured with (see the
// comment on the literals below for what to do if it fails — this is a check
// meant to be tripped by a re-tune, not a bug to work around). The
// "loadSeedCardMessages" group is the genuine unit test in this file: it
// exercises the loader's degrade-instead-of-crash contract (see
// lib/src/seed_card.dart) so a malformed or missing seed file falls back to
// sending no seed rather than taking the server down.

/// The exact bytes of the seed exchange that `ModelBehavior.md`'s numbers were
/// measured against.
///
/// Duplicated here on purpose. Every shape-coverage figure on record — the
/// full-set confirmation across six models, and the promotion decision that
/// rests on it — was produced with this content in front of the conversation.
/// Editing `assets/seed_card.json` without re-measuring would silently
/// invalidate all of it, so the asset and this literal are two independent
/// copies that must agree.
///
/// **If this test fails because you re-tuned the seed:** that is the test
/// working. Re-run `shape_ab.dart --seed-card` on at least the deciding model
/// (`qwen2.5-coder:7b`), record the new numbers in `ModelBehavior.md`, then
/// update this literal in the same change.
const _measuredUser = 'what timezone should I use for the nightly build?';
const _measuredAssistant =
    '[{"type":"TextBlock","text":"Pick a timezone for the nightly '
    'build:","wrap":true},{"type":"Input.ChoiceSet","id":"tz","'
    'style":"compact","choices":[{"title":"UTC","value":"+0000"},{'
    '"title":"CET","value":"+0100"}]}]';

void main() {
  const shippedPath = 'assets/seed_card.json';

  group('the shipped seed card', () {
    test('matches the content ModelBehavior.md was measured against', () {
      final messages = loadSeedCardMessages(shippedPath);
      expect(
        messages.map((m) => m.content).toList(),
        [_measuredUser, _measuredAssistant],
        reason:
            'assets/seed_card.json no longer matches the seed the recorded '
            "shape-coverage numbers were measured with. See this file's "
            'header for what to do.',
      );
    });

    // Role order isn't incidental — loadSeedCardMessages enforces strict
    // alternation starting from user, so a shipped asset that violated its
    // own loader's contract would silently ship as "no seed" instead of the
    // seed everyone measured.
    test('is a user turn then an assistant turn, in that order', () {
      final messages = loadSeedCardMessages(shippedPath);
      expect(messages.map((m) => m.role).toList(), ['user', 'assistant']);
    });

    test('seeds a real card, not just any reply', () {
      // The seed's whole mechanism is that the assistant half models the
      // output shape the card prompt asks for. A seed that no longer parses
      // as a card would still load and still cost tokens while teaching the
      // model nothing.
      final outcome = tryParseCardBody(_measuredAssistant);
      expect(outcome, isNotNull);
    });
  });

  group('loadSeedCardMessages', () {
    late Directory tempDir;
    late String path;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('seed_card_test');
      path = '${tempDir.path}/seed.json';
    });
    tearDown(() => tempDir.deleteSync(recursive: true));

    // The happy path every degrade-to-empty case below is contrasted
    // against.
    test('reads a well-formed file', () {
      File(path).writeAsStringSync(
        jsonEncode([
          {'role': 'user', 'content': 'q'},
          {'role': 'assistant', 'content': 'a'},
        ]),
      );
      expect(loadSeedCardMessages(path), [
        (role: 'user', content: 'q'),
        (role: 'assistant', content: 'a'),
      ]);
    });

    // A missing file must not crash request handling — see
    // loadSeedCardMessages' doc comment: the server still answers, just
    // without the seed's drift protection, and /status reports the loss
    // instead of hiding it.
    test('degrades to no seed when the file is missing', () {
      expect(loadSeedCardMessages('${tempDir.path}/nope.json'), isEmpty);
    });

    // A hand-edited asset that breaks JSON syntax must fail this loader
    // quietly, not the server that reads it.
    test('degrades to no seed on invalid JSON', () {
      File(path).writeAsStringSync('{not json');
      expect(loadSeedCardMessages(path), isEmpty);
    });

    // Guards a shape mistake (e.g. a single object instead of a list of
    // turns) that would otherwise need its own crash path to reject.
    test('degrades to no seed when the top level is not an array', () {
      File(path).writeAsStringSync(jsonEncode({'role': 'user'}));
      expect(loadSeedCardMessages(path), isEmpty);
    });

    // A turn missing either field is unusable as chat history;
    // loadSeedCardMessages must reject the whole file rather than silently
    // replaying a hole in it.
    test('degrades to no seed when a turn is missing content', () {
      File(path).writeAsStringSync(
        jsonEncode([
          {'role': 'user'},
        ]),
      );
      expect(loadSeedCardMessages(path), isEmpty);
    });

    test('rejects roles that do not alternate from user', () {
      // Ollama's chat templates assume alternating roles; a seed that opens
      // with an assistant turn is silently mangled by some of them, which
      // would look like a model failure rather than a bad asset.
      File(path).writeAsStringSync(
        jsonEncode([
          {'role': 'assistant', 'content': 'a'},
          {'role': 'user', 'content': 'q'},
        ]),
      );
      expect(loadSeedCardMessages(path), isEmpty);
    });

    // The format supports more than the single exchange actually shipped;
    // nothing about the alternation check should special-case exactly two
    // turns.
    test('accepts more than one exchange', () {
      File(path).writeAsStringSync(
        jsonEncode([
          {'role': 'user', 'content': 'q1'},
          {'role': 'assistant', 'content': 'a1'},
          {'role': 'user', 'content': 'q2'},
          {'role': 'assistant', 'content': 'a2'},
        ]),
      );
      expect(loadSeedCardMessages(path), hasLength(4));
    });
  });
}
