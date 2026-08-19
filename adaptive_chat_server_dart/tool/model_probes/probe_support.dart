/// Shared plumbing for the model probes in this directory.
///
/// Every probe answers some version of "does this model, with these decoding
/// settings, produce a card the server can actually render?" — so they all
/// need the same three things: the bundled card system prompt, one
/// `/api/chat` round trip, and a verdict from the server's **own** card
/// detection. Sharing them here keeps a probe file down to its experiment.
///
/// The verdict deliberately reuses `card_detect.dart` and
/// `checkNoDuplicateJsonKeys` rather than re-implementing "looks like a
/// card". A probe that judged replies by its own rules could report a pass
/// rate the running server does not agree with.
library;

import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Default local Ollama endpoint (IPv4 — see the README's `localhost` note).
const defaultProbeUrl = 'http://127.0.0.1:11434';

/// Options every probe accepts, so they can be pointed at another model or
/// host without editing source.
class ProbeArgs {
  /// Creates the parsed option set.
  const ProbeArgs({
    required this.model,
    required this.url,
    required this.samples,
  });

  /// Ollama model tag under test.
  final String model;

  /// Base URL of the Ollama server.
  final String url;

  /// Runs per cell. More samples cost time linearly; 3 is usually enough to
  /// see a deterministic failure repeat.
  final int samples;
}

/// Parses the common `--model` / `--url` / `--samples` options.
///
/// Exits with usage text on a bad argument rather than throwing, since these
/// are run by hand.
ProbeArgs parseProbeArgs(List<String> argv, {int defaultSamples = 3}) {
  final parser = ArgParser()
    ..addOption(
      'model',
      defaultsTo: defaultOllamaModel,
      help: 'Ollama model tag to probe.',
    )
    ..addOption('url', defaultsTo: defaultProbeUrl, help: 'Ollama base URL.')
    ..addOption(
      'samples',
      defaultsTo: '$defaultSamples',
      help: 'Runs per prompt per setting.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  try {
    final args = parser.parse(argv);
    if (args['help'] as bool) {
      stdout.writeln(parser.usage);
      exit(0);
    }
    return ProbeArgs(
      model: args['model'] as String,
      url: args['url'] as String,
      samples: int.parse(args['samples'] as String),
    );
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln()
      ..writeln(parser.usage);
    exit(2);
  }
}

/// Reads the bundled card system prompt — the same file the server sends.
///
/// Resolved from the script location, not the working directory, so a probe
/// runs the same from the package root or anywhere else.
String loadCardSystemPrompt() {
  final scriptDir = p.dirname(Platform.script.toFilePath());
  final assets = p.normalize(p.join(scriptDir, '..', '..', 'assets'));
  return File(
    p.join(assets, 'card_system_prompt.txt'),
  ).readAsStringSync().trim();
}

/// Path to the bundled seed-card asset — the same file the server sends.
///
/// Returned as a path rather than parsed content so `--seed-card-file` can
/// override it the same way the server's flag does, and so both sides go
/// through `loadSeedCardMessages` rather than keeping separate copies.
/// Resolved from the script location for the same reason as
/// [loadCardSystemPrompt].
String defaultSeedCardPath() {
  final scriptDir = p.dirname(Platform.script.toFilePath());
  final assets = p.normalize(p.join(scriptDir, '..', '..', 'assets'));
  return p.join(assets, 'seed_card.json');
}

/// Reads the bundled card schema, for probes exercising `format: <schema>`.
Map<String, dynamic> loadCardSchema() {
  final scriptDir = p.dirname(Platform.script.toFilePath());
  final assets = p.normalize(p.join(scriptDir, '..', '..', 'assets'));
  return jsonDecode(File(p.join(assets, 'card_schema.json')).readAsStringSync())
      as Map<String, dynamic>;
}

/// One reply, judged exactly as the running server would judge it.
class ProbeOutcome {
  /// Creates an outcome.
  const ProbeOutcome({
    required this.ok,
    required this.label,
    required this.chars,
    required this.ms,
    required this.hash,
    required this.reply,
  });

  /// Whether the reply was usable — a renderable card, or clean prose.
  ///
  /// Prose counts as a pass: the card system prompt explicitly allows a
  /// Markdown answer, so only a *broken* card is a failure. The exception is
  /// prose that *wraps* a card (see [replyWrapsCardInProse]) — the server
  /// renders that as Markdown, so the user sees raw JSON in a code block.
  /// It reads as a tidy Markdown answer and is scored a failure anyway,
  /// because it is the shape users actually report.
  final bool ok;

  /// Short human-readable verdict, e.g. `card[3]`, `prose`, `broken-card: …`.
  final String label;

  /// Reply length in characters.
  final int chars;

  /// Wall-clock round trip, milliseconds.
  final int ms;

  /// Short digest of the reply, for spotting identical outputs across runs.
  final String hash;

  /// The raw reply text, so a caller can score for a specific element rather
  /// than only for "is it broken?".
  final String reply;
}

/// Builds the `/api/chat` message list, mirroring `OllamaResponder`.
///
/// Extracted so the ordering is testable without an HTTP round trip. When
/// [reminder] is given it is inserted as a second `system` message **after**
/// the history and immediately before [userPrompt] — adjacency to generation
/// is the entire hypothesis it exists to test, so its position is asserted in
/// `test/probe_reinforce_test.dart` rather than left to inspection.
List<Map<String, String>> buildProbeMessages({
  required String systemPrompt,
  required String userPrompt,
  List<String> history = const [],
  String? reminder,
}) => [
  {'role': 'system', 'content': systemPrompt},
  for (final (i, turn) in history.indexed)
    {'role': i.isEven ? 'user' : 'assistant', 'content': turn},
  if (reminder != null) {'role': 'system', 'content': reminder},
  {'role': 'user', 'content': userPrompt},
];

/// Sends one `/api/chat` request and judges the reply.
///
/// [options] is merged into Ollama's `options` map, so a probe varies only
/// the setting it is studying. `think: false` and the system prompt mirror
/// what `OllamaResponder` sends, so results transfer to the real server.
Future<ProbeOutcome> probeOnce({
  required HttpClient client,
  required String url,
  required String model,
  required String systemPrompt,
  required String userPrompt,
  List<String> history = const [],
  String? reminder,
  Map<String, dynamic> options = const {},
  Object? format,
}) async {
  final started = DateTime.now();
  final request = await client.postUrl(Uri.parse('$url/api/chat'));
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'model': model,
      'messages': buildProbeMessages(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        history: history,
        reminder: reminder,
      ),
      'stream': false,
      'think': false,
      'keep_alive': '30m',
      'options': {'num_ctx': defaultNumCtx, ...options},
      'format': ?format,
    }),
  );
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final ms = DateTime.now().difference(started).inMilliseconds;

  if (response.statusCode != 200) {
    return ProbeOutcome(
      ok: false,
      label: 'HTTP ${response.statusCode}',
      chars: body.length,
      ms: ms,
      hash: '-',
      reply: body,
    );
  }
  final data = jsonDecode(body) as Map<String, dynamic>;
  final content =
      (data['message'] as Map<String, dynamic>)['content'] as String;
  return judgeReply(content, ms);
}

/// Applies the server's card-detection rules to [content].
ProbeOutcome judgeReply(String content, int ms) {
  final hash = md5.convert(utf8.encode(content)).toString().substring(0, 8);
  ProbeOutcome outcome({required bool ok, required String label}) =>
      ProbeOutcome(
        ok: ok,
        label: label,
        chars: content.length,
        ms: ms,
        hash: hash,
        reply: content,
      );

  try {
    checkNoDuplicateJsonKeys(content);
  } on DuplicateJsonKeyException catch (e) {
    return outcome(ok: false, label: 'duplicate-key ($e)');
  }
  final card = tryParseCardBody(content);
  if (card != null) {
    return outcome(ok: true, label: 'card[${card.length}]');
  }
  if (replyWrapsCardInProse(content)) {
    return outcome(
      ok: false,
      label: 'prose-with-card (user sees raw JSON)',
    );
  }
  final why = cardParseFailureReason(content);
  return why == null
      ? outcome(ok: true, label: 'prose')
      : outcome(ok: false, label: 'broken: $why');
}

/// Prints a per-setting summary line plus every failure under it.
void printSummary(String setting, List<ProbeOutcome> outcomes) {
  final pass = outcomes.where((o) => o.ok).length;
  final avgMs =
      outcomes.map((o) => o.ms).reduce((a, b) => a + b) ~/ outcomes.length;
  stdout.writeln(
    '== ${setting.padRight(20)} pass $pass/${outcomes.length}  '
    'avg ${avgMs}ms ==',
  );
  for (final failure in outcomes.where((o) => !o.ok)) {
    stdout.writeln('     FAIL ${failure.label}');
  }
}

/// Every element `type` present anywhere in a parsed card [body], including
/// types nested inside `Carousel` pages, `Table` cells, and `Column` items.
///
/// Returns what the model actually emitted, which is what makes a shape
/// failure diagnosable: "carousel failed" and "carousel failed, it emitted
/// three TextBlocks" call for different fixes.
Set<String> collectElementTypes(List<Map<String, dynamic>> body) {
  final found = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      final type = node['type'];
      if (type is String && type.isNotEmpty) found.add(type);
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  body.forEach(walk);
  return found;
}

/// Whether any element in [body] has a type in [wanted].
///
/// [wanted] is a set rather than a single type because several shapes are
/// often equally correct — "summarize these specs" is defensibly a `FactSet`
/// or a `Table`, and forcing one would score a good reply as a failure.
bool cardContainsAnyType(
  List<Map<String, dynamic>> body,
  Set<String> wanted,
) => collectElementTypes(body).intersection(wanted).isNotEmpty;
