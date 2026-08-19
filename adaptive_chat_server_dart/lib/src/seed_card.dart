/// Loads the synthetic card-shaped exchange `OllamaResponder` prepends to
/// every request.
///
/// A conversation answered once in Markdown tends to stay in Markdown: once
/// prose is the established format, models keep replying in prose even for a
/// question a card would answer better ("warm-start prose drift", measured in
/// `ModelBehavior.md` under "Multi-turn set — history replay"). Prepending
/// this exchange ahead of the real history — regardless of whether the real
/// history exists — makes a card the conversation's format *before* any
/// prose can accumulate, so there is nothing for a model to drift back
/// toward.
///
/// This was screened as candidate N2 (`--seed-card`) against four other
/// mechanisms — none of which moved the deciding model — and confirmed across
/// six models on the full 25-case set: cold-start shape coverage rose on 6/6,
/// with-history coverage rose on 5/6. The seed itself is unconditional (there
/// is no flag to send requests without one) because that is what was
/// measured; only its *content* is configurable, via `--seed-card-file`. The
/// cost is real and unconditional too: every request spends the tokens for
/// two extra turns, and a `table` reply newly erodes with history present on
/// 4 of the 6 measured models. Full numbers are in `ModelBehavior.md`.
///
/// The exchange lives in `assets/seed_card.json` rather than in this file so
/// it sits with the other prompt assets and can be re-tuned without a
/// rebuild — the same reason `card_system_prompt.txt` is a file. `t=0` shape
/// coverage was measured against the shipped bytes, so
/// `test/seed_card_test.dart` pins them: changing the asset fails that test
/// until the new content is measured and the record updated.
library;

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

final _log = Logger('adaptive_chat_server_dart.seed_card');

/// One turn of the seed exchange, in Ollama's `/api/chat` message shape.
typedef SeedCardMessage = ({String role, String content});

/// Reads the seed exchange from [path].
///
/// Returns an empty list when the file is missing, unreadable, or malformed,
/// after logging why. A server that cannot read its seed still answers — it
/// just answers without the measured drift protection — which is the same
/// degradation `OllamaResponder` applies to an unreadable system prompt, and
/// preferable to refusing every request over a tuning asset. `/status`
/// reports `seedCardTurns: 0` when this happens, so the loss is visible
/// rather than silent.
///
/// The file is a JSON array of `{"role": …, "content": …}` objects. Roles must
/// alternate starting with `user`, because the seed is replayed as
/// conversation and Ollama's chat templates assume that ordering.
List<SeedCardMessage> loadSeedCardMessages(String path) {
  final String raw;
  try {
    raw = File(path).readAsStringSync();
  } on IOException catch (e) {
    _log.warning('Seed card unreadable ($e) at $path — sending no seed.');
    return const [];
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    _log.warning(
      'Seed card is not valid JSON ($e) at $path — sending no seed.',
    );
    return const [];
  }

  if (decoded is! List) {
    _log.warning('Seed card at $path is not a JSON array — sending no seed.');
    return const [];
  }

  final messages = <SeedCardMessage>[];
  for (var i = 0; i < decoded.length; i++) {
    final entry = decoded[i];
    if (entry is! Map<String, dynamic>) {
      _log.warning('Seed card entry $i at $path is not an object — no seed.');
      return const [];
    }
    final role = entry['role'];
    final content = entry['content'];
    if (role is! String || content is! String) {
      _log.warning(
        'Seed card entry $i at $path needs string "role" and "content" '
        '— sending no seed.',
      );
      return const [];
    }
    final expected = i.isEven ? 'user' : 'assistant';
    if (role != expected) {
      _log.warning(
        'Seed card entry $i at $path has role "$role"; roles must alternate '
        'from "user", so entry $i must be "$expected" — sending no seed.',
      );
      return const [];
    }
    messages.add((role: role, content: content));
  }
  return messages;
}
