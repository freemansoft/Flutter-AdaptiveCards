// Does the probes' own cancellation path free Ollama's generation slot?
//
// ModelBehavior.md's open question 11 records that the unload/disconnect tests
// were run with `curl` against `/api/generate`, while the probes use Dart's
// `HttpClient.abort()` against `/api/chat`, "which was not tested this way".
// This replicates probeOnce()'s exact sequence and separates the two actions
// in time so the server log can attribute a termination to one of them.
//
// Phases, each on a fixed-length generation:
//   A baseline   undisturbed, to calibrate the generation's length
//   B abort-new   abort at 3 s, then probe the slot on a FRESH HttpClient
//   C abort-same  abort at 3 s, then probe the slot on the SAME HttpClient
//                 (what the probes actually do: one client per run)
//   D unload-only unload at 3 s, connection left open
//   E separated   abort at 3 s, unload at 13 s
//
// The slot probe is a two-token request. On an idle server it returns in
// ~0.1-0.3 s; if the abandoned generation still holds the slot it queues.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const url = 'http://127.0.0.1:11434';
const model = 'granite4.1:3b';
const numPredict = 1150;
const numCtx = 16384;
const interruptAt = Duration(seconds: 3);
const unloadAt = Duration(seconds: 13);

/// A prompt that reliably generates to [numPredict] rather than stopping early.
const longPrompt =
    'Write a long, detailed description of how a bicycle is assembled from '
    'parts, step by step, in prose. Do not stop early. Keep going.';

Map<String, dynamic> _chatBody(String prompt, int predict) => {
  'model': model,
  'messages': [
    {'role': 'user', 'content': prompt},
  ],
  'stream': false,
  'think': false,
  'keep_alive': '30m',
  'options': {
    'num_ctx': numCtx,
    'temperature': 0,
    'seed': 7,
    'num_predict': predict,
  },
};

/// Mirrors `probe_support.dart`'s `evictModel`: a zero `keep_alive` unload.
Future<String> unload() async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse('$url/api/generate'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'model': model, 'keep_alive': 0}));
    final resp = await req.close().timeout(const Duration(seconds: 30));
    final body = await resp.transform(utf8.decoder).join();
    final reason = (jsonDecode(body) as Map)['done_reason'];
    return 'HTTP ${resp.statusCode}, done_reason=$reason';
  } on Object catch (e) {
    return 'failed: $e';
  } finally {
    client.close();
  }
}

/// Sends a two-token request and times it. Fast means the slot is free.
Future<String> slotProbe(HttpClient client, String label) async {
  final t = Stopwatch()..start();
  try {
    final req = await client.postUrl(Uri.parse('$url/api/chat'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(_chatBody('Say OK.', 2)));
    final resp = await req.close().timeout(const Duration(seconds: 900));
    await resp.transform(utf8.decoder).join();
    return '$label: ${t.elapsedMilliseconds} ms (HTTP ${resp.statusCode})';
  } on Object catch (e) {
    return '$label: ${t.elapsedMilliseconds} ms, failed: $e';
  }
}

/// Runs one long generation, optionally interrupting it, and reports.
Future<void> phase(
  String name, {
  bool abort = false,
  bool doUnload = false,
  bool separated = false,
  bool freshSlotClient = false,
}) async {
  stdout.writeln('\n--- $name ---');
  final client = HttpClient();
  final t = Stopwatch()..start();
  final req = await client.postUrl(Uri.parse('$url/api/chat'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(_chatBody(longPrompt, numPredict)));

  // Schedule the interruptions against the live generation.
  if (abort) {
    Timer(interruptAt, () {
      req.abort();
      stdout.writeln('  t=${t.elapsedMilliseconds} ms  abort() called');
    });
  }
  if (doUnload) {
    Timer(separated ? unloadAt : interruptAt, () async {
      final r = await unload();
      stdout.writeln('  t=${t.elapsedMilliseconds} ms  unload -> $r');
    });
  }

  try {
    final resp = await req.close().timeout(const Duration(seconds: 900));
    final body = await resp
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 900));
    final d = jsonDecode(body) as Map<String, dynamic>;
    stdout.writeln(
      '  long call returned at ${t.elapsedMilliseconds} ms, '
      'HTTP ${resp.statusCode}, eval_count=${d['eval_count']}, '
      'done_reason=${d['done_reason']}',
    );
  } on Object catch (e) {
    stdout.writeln(
      '  long call threw at ${t.elapsedMilliseconds} ms: '
      '${e.runtimeType} ${e.toString().split('\n').first}',
    );
  }

  if (abort) {
    // The question the probes care about: is the slot usable now?
    final probeClient = freshSlotClient ? HttpClient() : client;
    final label = freshSlotClient
        ? 'slot probe, fresh client'
        : 'slot probe, same client';
    stdout.writeln('  ${await slotProbe(probeClient, label)}');
    if (freshSlotClient) probeClient.close();
  }
  client.close();
}

Future<void> main() async {
  stdout.writeln('model=$model num_predict=$numPredict num_ctx=$numCtx');

  // Load the model so phase A measures generation, not a cold load.
  final warm = HttpClient();
  stdout.writeln('warm-up: ${await slotProbe(warm, "load")}');
  warm.close();

  await phase('A baseline, undisturbed');
  await phase(
    'B abort at 3 s, slot probe on a fresh client',
    abort: true,
    freshSlotClient: true,
  );
  await phase('C abort at 3 s, slot probe on the same client', abort: true);
  await phase('D unload at 3 s, connection left open', doUnload: true);
  await phase(
    'E abort at 3 s, unload at 13 s',
    abort: true,
    doUnload: true,
    separated: true,
  );
}
