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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:adaptive_chat_server_dart/src/ollama_responder.dart';
import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Default local Ollama endpoint (IPv4 — see the README's `localhost` note).
const defaultProbeUrl = 'http://127.0.0.1:11434';

/// How long one call may take before it is scored a failure.
///
/// Generous on purpose: the longest legitimate generation recorded here is a
/// twelve-month table at roughly 49 s, so this leaves a wide margin and only
/// catches a model that has genuinely run away. Without it a sweep is
/// unbounded — one stuck call blocks every model queued behind it.
const defaultProbeTimeout = Duration(seconds: 180);

/// Options every probe accepts, so they can be pointed at another model or
/// host without editing source.
class ProbeArgs {
  /// Creates the parsed option set.
  const ProbeArgs({
    required this.model,
    required this.url,
    required this.samples,
    this.json,
    this.timeout = defaultProbeTimeout,
  });

  /// Ollama model tag under test.
  final String model;

  /// Base URL of the Ollama server.
  final String url;

  /// Runs per cell. More samples cost time linearly; 3 is usually enough to
  /// see a deterministic failure repeat.
  final int samples;

  /// Per-call ceiling before a reply is scored a timeout.
  final Duration timeout;

  /// Where to write the machine-readable record of this run, if anywhere.
  ///
  /// Shared across every probe so recording a run is one flag rather than a
  /// per-script convention — the alternative is what this directory had
  /// before, where the only durable copy of a measurement was whatever
  /// someone pasted into a Markdown table by hand.
  final String? json;
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
    ..addOption(
      'json',
      help:
          'Write the run to this JSON file: every call, plus the digests of '
          'the prompt assets it used, so the result can be re-derived and '
          'checked later instead of trusted.',
    )
    ..addOption(
      'timeout',
      defaultsTo: '${defaultProbeTimeout.inSeconds}',
      help:
          'Seconds one call may take before it is scored a timeout. Small '
          'models loop on the nested shapes, and an unbounded call stalls '
          'every model queued behind it.',
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
      json: args['json'] as String?,
      timeout: Duration(seconds: int.parse(args['timeout'] as String)),
    );
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln()
      ..writeln(parser.usage);
    exit(2);
  }
}

/// Directory holding the bundled prompt assets.
///
/// Resolved from the script location, not the working directory, so a probe
/// runs the same from the package root or anywhere else. Exposed rather than
/// inlined because a probe writing a result file has to digest these same
/// assets — a recorded digest and the prompt actually sent must come from one
/// path, or the staleness check is checking the wrong file.
String probeAssetsDir() => p.normalize(
  p.join(p.dirname(Platform.script.toFilePath()), '..', '..', 'assets'),
);

/// Reads the bundled card system prompt — the same file the server sends.
String loadCardSystemPrompt() => File(
  p.join(probeAssetsDir(), 'card_system_prompt.txt'),
).readAsStringSync().trim();

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
  Duration timeout = defaultProbeTimeout,
}) async {
  final started = DateTime.now();
  ProbeOutcome timedOut() => ProbeOutcome(
    ok: false,
    label: 'timeout (${timeout.inSeconds}s)',
    chars: 0,
    ms: DateTime.now().difference(started).inMilliseconds,
    hash: '-',
    reply: '',
  );

  // Acquiring the connection is bounded too, and this is the subtle half.
  // `Future.timeout` does not cancel the operation underneath it, so a call
  // that timed out mid-response leaves its socket checked out of the pool
  // forever. After enough of those, `postUrl` itself blocks waiting for a
  // free slot — the timeout meant to bound a stall becomes the cause of an
  // unbounded one. Observed as a sweep that sat for 3.5 hours using 1.9
  // seconds of CPU. The fix is both halves: bound this, and `abort()` below
  // so a timed-out request actually gives its connection back.
  final HttpClientRequest request;
  try {
    request = await client.postUrl(Uri.parse('$url/api/chat')).timeout(timeout);
  } on TimeoutException {
    return timedOut();
  }
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
  final String body;
  try {
    final response = await request.close().timeout(timeout);
    if (response.statusCode != 200) {
      final errorBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return ProbeOutcome(
        ok: false,
        label: 'HTTP ${response.statusCode}',
        chars: errorBody.length,
        ms: DateTime.now().difference(started).inMilliseconds,
        hash: '-',
        reply: errorBody,
      );
    }
    body = await response.transform(utf8.decoder).join().timeout(timeout);
  } on TimeoutException {
    // A generation that never returns is a failed reply, not a reason to
    // stall. Small models loop on the nested shapes — `granite4.1:3b` was
    // observed generating for 16 minutes on one `table` case — and without a
    // bound a single stuck call hangs an entire multi-model sweep with no
    // indication of which model or case did it. Recorded as its own label so
    // it is never mistaken for a wrong shape or invalid JSON.
    //
    // `abort()` is what makes the bound real: without it the request keeps
    // its connection, and a handful of timeouts exhausts the pool and hangs
    // every later call.
    request.abort();
    return timedOut();
  }
  final ms = DateTime.now().difference(started).inMilliseconds;

  // Ollama can answer 200 with a body carrying no `message.content` — an
  // error object, or a reply the runner cut short. Casting straight through
  // crashes the probe with a type error that names none of that, so the
  // unusable body is reported the way `OllamaResponder` reports it instead.
  final content = _contentOrNull(body);
  if (content == null) {
    return ProbeOutcome(
      ok: false,
      label: 'unexpected-response (no message.content)',
      chars: body.length,
      ms: ms,
      hash: '-',
      reply: body,
    );
  }
  return judgeReply(content, ms);
}

/// Pulls `message.content` out of an `/api/chat` body, or null if it is absent
/// or not a string.
///
/// Shared by every probe: a 200 without usable content is a condition to
/// report, never one to crash on.
String? _contentOrNull(String body) {
  try {
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic>) return null;
    final message = data['message'];
    if (message is! Map<String, dynamic>) return null;
    final content = message['content'];
    return content is String ? content : null;
  } on FormatException {
    return null;
  }
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
  final cards = outcomes
      .where((o) => o.ok && o.label.startsWith('card['))
      .length;
  final prose = outcomes.where((o) => o.ok && o.label == 'prose').length;
  final avgMs =
      outcomes.map((o) => o.ms).reduce((a, b) => a + b) ~/ outcomes.length;
  // The pass count alone cannot answer "is this model still producing
  // cards?". `ok` is true for a renderable card *and* for clean prose,
  // because the card prompt permits a Markdown answer and only a broken card
  // is a failure — right for "did anything break", wrong for "did we get
  // cards". A model has swept this set 5/5 with four of ten cells answered in
  // prose, and reading that as ten good cards is the exact mistake
  // `shape_ab.dart` was written to stop. Splitting the tally puts the
  // distinction in the output instead of leaving it to whoever reads the
  // per-call labels.
  final split = pass == 0 ? '' : '  ($cards card, $prose prose)';
  stdout.writeln(
    '== ${setting.padRight(20)} pass $pass/${outcomes.length}$split  '
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
