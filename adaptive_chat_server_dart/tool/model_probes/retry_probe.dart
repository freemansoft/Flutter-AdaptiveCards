/// Does re-asking through the tool channel rescue a card the prose channel
/// failed to serialize?
///
/// The tool-channel comparison established two facts that point at each other.
/// Malformed JSON is the prose channel's largest failure, 50 calls per 100
/// across the seven models measured, and a tool call structurally cannot carry
/// one, because Ollama returns its arguments already decoded. It also
/// established why the channel did not ship as a default: models decline to
/// call the tool on 16 to 30 calls per 100, and ordinary conversation history
/// makes that worse.
///
/// A retry sidesteps the second problem. It fires only on a reply that already
/// failed to parse, so it cannot depress adoption on the calls that worked, and
/// it costs a second round trip only on the fraction that broke. Whether it
/// actually rescues those calls is what this probe measures, and nothing had
/// measured it.
///
/// Each case runs in prose first, exactly as `shape_ab.dart --channel prose`
/// would. A reply the server's own detector cannot parse is retried once,
/// discarding the broken reply and re-asking with `render_adaptive_card`
/// offered under `card_tool_prompt_matched.txt`. Showing the model its own
/// broken output would measure self-correction as well as the channel, which
/// is a second variable and a separate question.
///
/// Both phases are recorded per call, distinguished by `setting`:
/// `prose` and `retry-tool`. The denominator is therefore the full case list
/// rather than a list of known failures, so the rescue rate can be read
/// against how often a retry was needed at all.
///
/// ```shell
/// fvm dart run tool/model_probes/retry_probe.dart --model qwen3-coder:30b \
///   --samples 2 --json out.json
/// ```
library;

import 'dart:io';

import 'package:adaptive_chat_server_dart/src/element_types.dart'
    show loadKnownElementTypes;
import 'package:path/path.dart' as p;

// Relative: these live outside lib/, beside this file.
import 'probe_results.dart';
import 'probe_support.dart';
import 'shape_cases.dart';
import 'tool_channel.dart';

/// Whether [result] failed because the reply could not be parsed as a card.
///
/// The retry exists for serialization failures only. A model that answered in
/// prose, or produced a renderable card of the wrong shape, has not failed in
/// a way a different channel would fix, and retrying it would inflate the
/// rescue rate with calls that never needed rescuing.
bool isParseFailure(ShapeResult result) =>
    result.label.startsWith('broken: invalid JSON') ||
    result.label.startsWith('broken: duplicate-key');

Future<void> main(List<String> argv) async {
  final args = parseProbeArgs(argv, defaultSamples: 2);
  final proseSystem = File(p.join(probeAssetsDir(), 'card_system_prompt.txt'))
      .readAsStringSync()
      .trim();
  final toolSystem = File(
    p.join(probeAssetsDir(), 'card_tool_prompt_matched.txt'),
  ).readAsStringSync().trim();
  final cardTool = renderCardTool(loadCardSchema());
  final knownTypes = loadKnownElementTypes(
    p.join(probeAssetsDir(), 'card_schema.json'),
  );
  final client = HttpClient()..idleTimeout = const Duration(minutes: 5);

  final calls = <ProbeCall>[];
  var proseFailures = 0;
  var rescued = 0;
  var retriedViaTool = 0;

  for (final withHistory in [false, true]) {
    final condition = withHistory ? 'warm' : 'cold';
    stdout.writeln('\n########## $condition ##########');
    final history = withHistory
        ? [shapeHistoryUser, shapeHistoryAssistant]
        : <String>[];

    for (final c in shapeCases) {
      // The negative control wants prose, so a reply that is not a card is
      // correct there and there is nothing for a retry to rescue.
      if (c.accepted.isEmpty) continue;

      for (var i = 0; i < args.samples; i++) {
        final prose = judgeShape(
          c,
          await probeOnce(
            client: client,
            url: args.url,
            model: args.model,
            systemPrompt: proseSystem,
            userPrompt: c.prompt,
            history: history,
            options: const {'temperature': 0.0},
            timeout: args.timeout,
          ),
        );
        calls.add(
          ProbeCall(
            caseId: c.id,
            sample: i,
            pass: prose.pass,
            label: prose.describe(),
            condition: condition,
            setting: 'prose',
          ),
        );
        if (!isParseFailure(prose)) {
          stdout.writeln(
            '${prose.pass ? "PASS" : "FAIL"}  ${c.id.padRight(13)} '
            'prose  ${prose.describe()}',
          );
          continue;
        }

        proseFailures++;
        final outcome = await probeOnceViaTool(
          client: client,
          url: args.url,
          model: args.model,
          systemPrompt: toolSystem,
          userPrompt: c.prompt,
          tool: cardTool,
          history: history,
          options: const {'temperature': 0.0},
          timeout: args.timeout,
        );
        final retry = judgeShape(c, outcome);
        if (retry.pass) rescued++;
        if (outcome.toolUsed ?? false) retriedViaTool++;
        calls.add(
          ProbeCall(
            caseId: c.id,
            sample: i,
            pass: retry.pass,
            label: retry.describe(),
            condition: condition,
            setting: 'retry-tool',
            toolUsed: outcome.toolUsed,
            unknownTypes: unrenderableTypes(outcome.reply, knownTypes),
          ),
        );
        stdout.writeln(
          'FAIL  ${c.id.padRight(13)} prose  ${prose.describe()}\n'
          '  ${retry.pass ? "RESCUED" : "still failed"}  retry-tool  '
          '${retry.describe()}'
          '${(outcome.toolUsed ?? false) ? "" : "  (in message.content)"}',
        );
      }
    }
  }

  stdout.writeln(
    '\n== prose parse failures $proseFailures, '
    'rescued by a tool retry $rescued, '
    'retries that used the tool $retriedViaTool ==',
  );

  final path = args.json;
  if (path != null) {
    ProbeRun(
      probe: 'retry_probe',
      model: args.model,
      measuredAt: DateTime.now().toIso8601String().split('T').first,
      machine: detectMachine(),
      ollama: detectOllamaVersion(),
      samples: args.samples,
      temperature: 0,
      assets: currentAssetDigests(
        probeAssetsDir(),
        assetNames: const [
          'card_system_prompt.txt',
          'card_tool_prompt_matched.txt',
        ],
      ),
      summary: {
        'proseParseFailures': proseFailures,
        'rescued': rescued,
        'retriedViaTool': retriedViaTool,
        'cardCases': shapeCases.where((c) => c.accepted.isNotEmpty).length,
      },
      notes:
          'Unseeded. Each card case runs in prose; a reply that fails to '
          'parse is retried once through the tool channel, discarding the '
          'broken reply. setting=prose and setting=retry-tool separate the '
          'two phases.',
      calls: calls,
    ).write(File(path));
    stdout.writeln('\nwrote $path');
  }
}
