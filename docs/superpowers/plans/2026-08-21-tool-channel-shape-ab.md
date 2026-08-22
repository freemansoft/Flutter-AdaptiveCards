# Tool-Channel Shape A/B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Answer whether Ollama's tool channel produces _better cards_ than the prose channel, by running the existing 25 shape cases through it on the 8 models that support it (phase 2), and then whether it survives a real conversation (phase 3).

**Architecture:** `shape_ab.dart` gains a `--channel prose|tool` option. The tool path sends a `render_adaptive_card` tool and converts the returned `tool_calls[].function.arguments.body` into the same `ProbeOutcome.reply` string a prose reply would have produced, so `judgeShape` and every existing scoring rule apply unchanged. Only the tool arm is run; the prose baseline is already on disk.

**Tech Stack:** Dart 3 (no Flutter), `package:test`, Ollama `/api/chat`, FVM-pinned SDK.

**Spec:** [`2026-08-21-card-reliability-levers-design.md`](../specs/2026-08-21-card-reliability-levers-design.md), lever A, phases 2 and 3. Phase 1 is complete: 8 `supported`, 3 `supportedButDeclines`, 2 `overCalls`, 2 `unsupported`.

## Global Constraints

- Prefix EVERY `dart`/`flutter` command with `fvm`. Run from `adaptive_chat_server_dart/`.
- Analysis is `very_good_analysis` + `prefer_single_quotes` + `always_use_package_imports` + `avoid_print`. `fvm dart analyze adaptive_chat_server_dart/` must print `No issues found!` before any commit. Lints that have already bitten this work: `unnecessary_raw_strings` (raw string with no backslashes; `r'$defs'` IS necessary), `inference_failure_on_collection_literal` (untyped `{}`), `specify_nonobvious_property_types` (a `const` map needs an explicit type annotation), `lines_longer_than_80_chars`. Progress output uses `stdout.writeln`, never `print`.
- Files under `tool/model_probes/` sit outside `lib/` and import siblings relatively; anything from `lib/` uses its `package:` URI. In test files, `package:test/test.dart` comes before any relative import (`directives_ordering`).
- Format gates from the repo root before every commit: `fvm dart format adaptive_chat_server_dart/`, `npm run format:md:chat`, and `npm run format:md` if `docs/` changed.
- Every task adds a bullet to `adaptive_chat_server_dart/CHANGELOG.md` under `## [Unreleased]`, style `- Category: **bold one-line summary.** Detail.`
- **One Ollama model resident at a time, strictly serial.** `ollama stop` between models. Never parallelise, never one subagent per model. Three of the eight target models are 18–25 GB.
- **Never invent a number.** Every figure written into `ModelBehavior.md` must come from a run that happened, traceable to a results JSON.
- Do not modify anything under `packages/`. Do not push, merge, or touch `main`.

**Branch:** create `feat/tool-channel-shape-ab` off `docs/card-reliability-levers-spec` (that branch carries the canary this work depends on).

**Sequencing:** Task 1 → Task 2 (phase 2). Task 3 → Task 4 (phase 3) run only if Task 2's result justifies them — see the gate in Task 2 Step 6.

---

## File Structure

| File                                                   | Responsibility                                                                  | Task |
| ------------------------------------------------------ | ------------------------------------------------------------------------------- | ---- |
| `tool/model_probes/tool_channel.dart`                  | **New.** Shared tool definition + tool-call extraction, reusable by both probes | 1    |
| `tool/model_probes/tool_call_probe.dart`               | Drops its private copies, imports the shared ones                               | 1    |
| `tool/model_probes/shape_ab.dart`                      | `--channel prose\|tool`, tool-path call                                         | 1    |
| `test/tool_channel_test.dart`                          | **New.** Covers extraction and the prose-equivalence conversion                 | 1    |
| `tool/model_probes/results/<model>/shape_ab-tool.json` | Per-model tool-arm results                                                      | 2    |
| `ModelBehavior.md`                                     | The comparison column and its finding                                           | 2    |
| `tool/model_probes/cascade_ab.dart`                    | `--channel`, plus correct tool-call history replay                              | 3    |
| `test/cascade_judge_test.dart`                         | Extends existing coverage to the tool path                                      | 3    |

---

### Task 1: Add a tool channel to `shape_ab.dart`

**The design that makes this small:** `judgeShape(c, outcome)` reads only `outcome.reply`, `outcome.ok`, and `outcome.label`. So the tool path does not need its own scoring — it needs to produce a `ProbeOutcome` whose `reply` is the string a prose reply _would_ have contained. When the model calls the tool, that is `jsonEncode(arguments['body'])`; when it does not, it is `message.content` verbatim. Feed either through the existing `judgeReply` and every scoring rule, including the negative control, applies untouched.

That last point matters: the `prose` control case has an empty `accepted` set, so `judgeShape` passes it only when the reply is _not_ a card. On the tool channel that means the model correctly declined to call the tool — the same `overCalls` axis phase 1 measured, now scored across 25 cases for free.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/tool_channel.dart`
- Create: `adaptive_chat_server_dart/test/tool_channel_test.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/tool_call_probe.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `ProbeOutcome`, `judgeReply(String, int)`, `ProbeArgs`, `defaultNumCtx` from `probe_support.dart`; `judgeShape`, `ShapeCase` from `shape_cases.dart`.
- Produces, all in `tool_channel.dart`:

  - `Map<String, dynamic> renderCardTool(Map<String, dynamic> schema)`
  - `Map<String, dynamic>? toolCallArguments(Map<String, dynamic> message, String name)`
  - `String replyEquivalent(Map<String, dynamic> message, String toolName)` — the prose-equivalent string described above
  - `Future<ProbeOutcome> probeOnceViaTool({...})`

- [ ] **Step 1: Write the failing test**

Create `test/tool_channel_test.dart`:

```dart
import 'dart:convert';

import 'package:test/test.dart';

// Relative: these live outside lib/, so there is no package: URI.
import '../tool/model_probes/tool_channel.dart';

void main() {
  group('toolCallArguments', () {
    test('reads arguments returned as a decoded map', () {
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'render_adaptive_card',
              'arguments': {
                'body': [
                  {'type': 'TextBlock', 'text': 'hi'},
                ],
              },
            },
          },
        ],
      };
      expect(
        toolCallArguments(message, 'render_adaptive_card'),
        containsPair('body', isA<List<dynamic>>()),
      );
    });

    test('reads arguments returned as a JSON string', () {
      // Some Ollama builds return arguments as an unparsed string.
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'render_adaptive_card',
              'arguments': '{"body":[{"type":"TextBlock","text":"hi"}]}',
            },
          },
        ],
      };
      expect(
        toolCallArguments(message, 'render_adaptive_card'),
        containsPair('body', isA<List<dynamic>>()),
      );
    });

    test('returns null when a different tool was called', () {
      final message = {
        'tool_calls': [
          {
            'function': {'name': 'get_current_temperature', 'arguments': {}},
          },
        ],
      };
      expect(toolCallArguments(message, 'render_adaptive_card'), isNull);
    });

    test('returns null when there are no tool calls', () {
      expect(
        toolCallArguments(const {'content': 'hello'}, 'render_adaptive_card'),
        isNull,
      );
    });
  });

  group('replyEquivalent', () {
    test('a tool call becomes the JSON body a prose reply would carry', () {
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'render_adaptive_card',
              'arguments': {
                'body': [
                  {'type': 'Input.Date', 'id': 'when'},
                ],
              },
            },
          },
        ],
      };
      final reply = replyEquivalent(message, 'render_adaptive_card');
      // Must be exactly what the prose channel would have emitted, so the
      // existing shape scoring applies without a tool-aware branch.
      expect(jsonDecode(reply), [
        {'type': 'Input.Date', 'id': 'when'},
      ]);
    });

    test('no tool call falls through to the content verbatim', () {
      // This is what makes the negative control work: an uncalled tool must
      // look like prose to the judge, not like an empty card.
      const message = {'content': 'SDUI means server-driven UI.'};
      expect(
        replyEquivalent(message, 'render_adaptive_card'),
        'SDUI means server-driven UI.',
      );
    });

    test('a tool call with no body yields an empty string, not "null"', () {
      // Guards against jsonEncode(null) producing the literal text "null",
      // which tryParseCardBody would treat as a scalar rather than absence.
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'render_adaptive_card',
              'arguments': <String, dynamic>{},
            },
          },
        ],
      };
      expect(replyEquivalent(message, 'render_adaptive_card'), isEmpty);
    });
  });

  group('renderCardTool', () {
    test('wraps the schema ElementArray as the body parameter', () {
      final schema = {
        r'$defs': {
          'ElementArray': {'type': 'array'},
        },
      };
      final tool = renderCardTool(schema);
      final function = tool['function']! as Map<String, dynamic>;
      final params = function['parameters']! as Map<String, dynamic>;
      final props = params['properties']! as Map<String, dynamic>;
      expect(function['name'], 'render_adaptive_card');
      expect(params['required'], ['body']);
      expect(props['body'], {'type': 'array'});
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd adaptive_chat_server_dart
fvm dart test test/tool_channel_test.dart
```

Expected: FAIL at compile time — `Error: Couldn't resolve … tool_channel.dart`.

- [ ] **Step 3: Write `tool_channel.dart`**

Create `tool/model_probes/tool_channel.dart`. Move `renderCardTool` and `toolCallArguments` out of `tool_call_probe.dart` (they are currently private `_renderCardTool` / `_toolCallArguments` there) and make them public here, keeping their existing bodies and doc comments. Then add:

```dart
/// The string a prose-channel reply would have carried for this [message].
///
/// The whole point of the tool channel is that a card arrives as structured
/// arguments rather than as text the server must guess about. But every
/// scoring rule in this directory — `judgeShape`, `judgeReply`, the negative
/// control — is written against a reply *string*. Converting here means the
/// tool path reuses all of it instead of growing a parallel set of rules that
/// could drift out of agreement with the prose path it is being compared to.
///
/// A reply with no tool call passes its `content` through untouched, which is
/// what makes the negative control meaningful: declining to call the tool must
/// read as prose, not as an empty card.
String replyEquivalent(Map<String, dynamic> message, String toolName) {
  final args = toolCallArguments(message, toolName);
  if (args == null) {
    final content = message['content'];
    return content is String ? content : '';
  }
  final body = args['body'];
  // Absence is an empty reply, never the four characters `null`, which
  // tryParseCardBody would read as a scalar rather than as nothing.
  if (body == null) return '';
  return jsonEncode(body);
}

/// One `/api/chat` call that offers [tool], scored exactly as a prose reply.
///
/// Mirrors `probeOnce`'s contract so a caller can swap channels without
/// changing how it handles the result.
Future<ProbeOutcome> probeOnceViaTool({
  required HttpClient client,
  required String url,
  required String model,
  required String systemPrompt,
  required String userPrompt,
  required Map<String, dynamic> tool,
  List<String> history = const [],
  Map<String, dynamic> options = const {},
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
      ),
      'stream': false,
      'think': false,
      'keep_alive': '30m',
      'options': {'num_ctx': defaultNumCtx, ...options},
      'tools': [tool],
    }),
  );

  final String rawBody;
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
    rawBody = await response.transform(utf8.decoder).join().timeout(timeout);
  } on TimeoutException {
    // abort() is what makes the bound real: without it a timed-out request
    // keeps its connection and a handful of them exhausts the pool.
    request.abort();
    return timedOut();
  }
  final ms = DateTime.now().difference(started).inMilliseconds;

  final Object? decoded;
  try {
    decoded = jsonDecode(rawBody);
  } on FormatException {
    return ProbeOutcome(
      ok: false,
      label: 'unexpected-response (body not JSON)',
      chars: rawBody.length,
      ms: ms,
      hash: '-',
      reply: rawBody,
    );
  }
  final message = decoded is Map<String, dynamic> ? decoded['message'] : null;
  if (message is! Map<String, dynamic>) {
    return ProbeOutcome(
      ok: false,
      label: 'unexpected-response (no message)',
      chars: rawBody.length,
      ms: ms,
      hash: '-',
      reply: rawBody,
    );
  }
  return judgeReply(replyEquivalent(message, 'render_adaptive_card'), ms);
}
```

Add the imports the file needs (`dart:async`, `dart:convert`, `dart:io`, and relative `probe_support.dart`), and a library doc comment saying this exists so both `tool_call_probe.dart` and `shape_ab.dart` share one tool definition rather than two that can drift.

Then update `tool_call_probe.dart` to import `tool_channel.dart` and delete its private copies, leaving its behavior identical.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd adaptive_chat_server_dart
fvm dart test test/tool_channel_test.dart test/tool_call_probe_test.dart
```

Expected: PASS, 8 + 8 = 16 tests. `tool_call_probe_test.dart` passing unchanged is the signal that extracting the helpers changed no behavior.

- [ ] **Step 5: Wire `--channel` into `shape_ab.dart`**

Add the option beside the existing ones:

```dart
    ..addOption(
      'channel',
      defaultsTo: 'prose',
      allowed: ['prose', 'tool'],
      help:
          'Reply channel. prose asks for card JSON in the message body and '
          'guesses whether it is a card; tool offers a render_adaptive_card '
          'function and reads its arguments. Only models verdicted supported '
          'by tool_call_probe.dart can answer on the tool channel.',
    )
```

Thread it through `runPrompt` and `runCondition` as a `String channel` parameter. In `runCondition`, choose the call:

```dart
      final outcome = channel == 'tool'
          ? await probeOnceViaTool(
              client: client,
              url: args.url,
              model: args.model,
              systemPrompt: systemPrompt,
              userPrompt: c.prompt,
              tool: cardTool,
              history: [
                ...seedTurns,
                if (withHistory) ...[shapeHistoryUser, shapeHistoryAssistant],
              ],
              options: const {'temperature': 0.0},
              timeout: args.timeout,
            )
          : await probeOnce(
              // …existing call, unchanged…
            );
```

`cardTool` is built once in `main()` as `renderCardTool(loadCardSchema())` and passed down.

Two guards in `main()`, both of which refuse rather than silently measuring the wrong thing:

```dart
  final channel = parsed['channel'] as String;
  if (channel == 'tool' && (parsed['seed-card'] as bool)) {
    stderr.writeln(
      'shape_ab: --channel tool cannot be combined with the seed card. The '
      'seed is a prose-channel artifact — a synthetic assistant turn holding '
      'raw card JSON — so seeding the tool channel measures neither channel '
      'cleanly. Pass --no-seed-card; the tool arm is compared against the '
      'recorded unaided prose run.',
    );
    exitCode = 2;
    return;
  }
```

and the prompt must match the channel:

```dart
  final defaultPrompt = channel == 'tool'
      ? 'assets/card_tool_prompt.txt'
      : 'assets/card_system_prompt.txt';
```

Use `defaultPrompt` when `--baseline` was not explicitly passed. The prose-channel prompt tells the model the entire message must be raw JSON, which is false when a tool is offered; pairing them would measure a contradiction.

Finally, record the channel in the run so a result file cannot be misread:

```dart
      variant: channel == 'tool' ? 'tool' : (seeded ? 'seeded' : 'unaided'),
```

and pass `assetNames: const ['card_tool_prompt.txt']` to the run when the channel is tool, matching what it actually sent.

- [ ] **Step 6: Verify the wiring without calling a model**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/shape_ab.dart --help
fvm dart run tool/model_probes/shape_ab.dart --channel tool --model x --only prose
```

Expected: the help text lists `--channel`; the second command exits 2 with the seed-card refusal message, proving the guard fires before any network call.

- [ ] **Step 7: Full suite, analyze, changelog, commit**

```bash
cd adaptive_chat_server_dart
fvm dart test
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart analyze adaptive_chat_server_dart/
```

Expected: all tests pass (316 before this task, plus 8 new = 324); `No issues found!`

Changelog:

```markdown
- Added: **`shape_ab.dart --channel prose|tool`.** The tool arm offers a
  `render_adaptive_card` function and converts its arguments into the reply
  string a prose answer would have carried, so `judgeShape` and every existing
  scoring rule — including the negative control — apply unchanged rather than
  growing a parallel set that could drift from the path it is compared against.
  The shared tool definition moves to `tool_channel.dart` so the canary and the
  A/B cannot disagree about what they offered. `--channel tool` refuses to run
  with the seed card and defaults to `card_tool_prompt.txt`.
```

```bash
fvm dart format adaptive_chat_server_dart/
npm run format:md:chat
git add adaptive_chat_server_dart/tool/model_probes/tool_channel.dart adaptive_chat_server_dart/test/tool_channel_test.dart adaptive_chat_server_dart/tool/model_probes/tool_call_probe.dart adaptive_chat_server_dart/tool/model_probes/shape_ab.dart adaptive_chat_server_dart/CHANGELOG.md
git commit -m "feat(chat-server): add a tool channel to the shape A/B probe"
```

---

### Task 2: Run the tool arm and record the comparison

**Needs a live Ollama.** Eight models, 25 cases, 2 samples, both conditions — roughly 800 calls. Three of the eight are 18–25 GB. Budget hours, not minutes.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results/<model>/shape_ab-tool.json` (×8)
- Modify: `adaptive_chat_server_dart/ModelBehavior.md`, `tool/model_probes/check_results.dart`, `tool/model_probes/sweep.sh`, `CHANGELOG.md`

**Interfaces:** consumes Task 1's `--channel tool`.

- [ ] **Step 1: Confirm the machine is idle**

```bash
curl -s http://127.0.0.1:11434/api/tags | head -c 200
ollama ps
```

Expected: a model list, and an empty `ollama ps`. A stalling measurement looks identical whether the model is slow or the machine is busy — check before, not after.

- [ ] **Step 2: Derive the eight target models from the recorded phase 1 verdicts**

Do not copy a list from any document, including this one. Read it from the data:

```bash
cd adaptive_chat_server_dart
python3 - <<'PY'
import json, glob, os
for f in sorted(glob.glob('tool/model_probes/results/*/tool_call_probe.json')):
    d = json.load(open(f))
    if d['summary']['verdict'] == 'supported':
        print(d['model'])
PY
```

Expected: 8 model tags. If it prints a different count, stop and report — the gate rests on this number.

- [ ] **Step 3: Run the tool arm, serially**

One model resident at a time. Run each as a foreground command; do not background them.

```bash
cd adaptive_chat_server_dart
for m in $(python3 -c "
import json,glob
print('\n'.join(json.load(open(f))['model'] for f in sorted(glob.glob('tool/model_probes/results/*/tool_call_probe.json')) if json.load(open(f))['summary']['verdict']=='supported'))
"); do
  echo "=== $m ==="
  slug=$(printf '%s' "$m" | sed -e 's#/#__#g' -e 's#:#_#g')
  fvm dart run tool/model_probes/shape_ab.dart \
    --channel tool --no-seed-card --model "$m" --samples 2 \
    --json "tool/model_probes/results/$slug/shape_ab-tool.json"
  ollama stop "$m" || true
done
```

If a model times out or errors, record what happened and continue to the next. One bad model must not abort the run.

- [ ] **Step 4: Build the comparison**

For each model, compare `shape_ab-tool.json` against the recorded `shape_ab-unaided.json` — **not** `shape_ab-seeded.json`. The tool arm ran unseeded, and comparing it to a seeded prose score hands prose an advantage the tool arm structurally cannot have.

```bash
cd adaptive_chat_server_dart
python3 - <<'PY'
import json, glob, os
print(f"{'model':46} {'prose cold':>10} {'tool cold':>9} {'prose warm':>10} {'tool warm':>9}")
for f in sorted(glob.glob('tool/model_probes/results/*/shape_ab-tool.json')):
    d = os.path.dirname(f)
    tool = json.load(open(f))['summary']
    base = os.path.join(d, 'shape_ab-unaided.json')
    if not os.path.exists(base):
        print(f"{os.path.basename(d):46} NO UNAIDED BASELINE")
        continue
    prose = json.load(open(base))['summary']
    print(f"{os.path.basename(d):46} {prose['coldStart']:>10} {tool['coldStart']:>9} "
          f"{prose['withHistory']:>10} {tool['withHistory']:>9}")
PY
```

- [ ] **Step 5: Register the new variant**

Add `'shape_ab-tool'` to `expectedProbes` in `tool/model_probes/check_results.dart`, and a `run` line to `sweep.sh` beside the existing `shapes-unaided` one. Then:

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/check_results.dart
```

Expected: no `missing probe` finding for a model that has a `shape_ab-tool.json`. Models that are not `supported` will legitimately lack one — if `check_results.dart` flags those as missing, make the expectation conditional rather than recording a fake run.

- [ ] **Step 6: Write the finding, and apply the phase 3 gate**

Add a subsection under the tool-calling canary section in `ModelBehavior.md` carrying the per-model comparison table from Step 4 and one sentence naming what it means. Report the result honestly whichever way it falls — "the tool channel scored the same or worse" is a publishable finding and is the outcome the thin headroom predicts, since these models already score 23–24 of 25 on the prose path.

**The phase 3 gate:** proceed to Tasks 3–4 only if the tool arm is at least as good as the prose arm on a majority of the eight models. If the tool channel is worse single-turn, its multi-turn behavior is moot and phase 3 is not built — record that and stop.

- [ ] **Step 7: Verify and commit**

```bash
cd adaptive_chat_server_dart
fvm dart test
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart analyze adaptive_chat_server_dart/
npm run format:md:chat
```

Commit the results, the `ModelBehavior.md` section, the registration changes, and a CHANGELOG bullet naming the outcome.

---

### Task 3: Teach `cascade_ab.dart` the tool channel — GATED on Task 2 Step 6

**Do not start this task until Task 2's gate has been applied and recorded.**

**The prerequisite that makes this different from Task 1.** `cascade_ab.dart` asks a model to widen the card it just sent, referring back to it ("more than one of _those_") rather than restating the items. That means turn 1's reply is replayed as history. On the prose channel that is an assistant text turn containing raw card JSON, which is exactly what the server stores today. **On the tool channel it is not.** A prior tool call belongs in history as an assistant message carrying `tool_calls`, optionally followed by a `tool`-role result. Replaying it as text would measure a model reading its own output in the wrong format, which answers no useful question.

So this task's first job is settling the history representation, and its tests must pin it before any model is called.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/cascade_ab.dart`
- Modify: `adaptive_chat_server_dart/tool/model_probes/tool_channel.dart` (history construction)
- Modify: `adaptive_chat_server_dart/test/cascade_judge_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: `renderCardTool`, `toolCallArguments`, `replyEquivalent`, `probeOnceViaTool` from Task 1.
- Produces: `List<Map<String, dynamic>> toolCallHistory({required String userTurn, required List<Map<String, dynamic>> cardBody})` in `tool_channel.dart` — the Ollama message list representing one prior user turn and the assistant tool call that answered it.

- [ ] **Step 1: Write the failing test**

Add to `test/cascade_judge_test.dart`:

```dart
  group('toolCallHistory', () {
    test('represents a prior card as an assistant tool call, not as text', () {
      // The point of the tool channel is that a card is structured data. If
      // the previous card were replayed as assistant text containing JSON,
      // the model would be reading its own output in a format it never
      // produced, and the cascade result would mean nothing.
      final messages = toolCallHistory(
        userTurn: 'which log level should I use?',
        cardBody: [
          {'type': 'Input.ChoiceSet', 'id': 'level'},
        ],
      );
      expect(messages.first['role'], 'user');
      final assistant = messages[1];
      expect(assistant['role'], 'assistant');
      expect(assistant.containsKey('tool_calls'), isTrue);
      expect(
        assistant['content'],
        anyOf(isNull, isEmpty),
        reason:
            'the card must not also appear as text, or the model sees it '
            'twice in two different formats',
      );
      final call = (assistant['tool_calls']! as List).single
          as Map<String, dynamic>;
      final function = call['function']! as Map<String, dynamic>;
      expect(function['name'], 'render_adaptive_card');
      expect(
        toolCallArguments(assistant, 'render_adaptive_card'),
        containsPair('body', isA<List<dynamic>>()),
      );
    });
  });
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd adaptive_chat_server_dart
fvm dart test test/cascade_judge_test.dart -n 'toolCallHistory'
```

Expected: FAIL — `toolCallHistory` is not defined.

- [ ] **Step 3: Implement `toolCallHistory` and thread `--channel` through `cascade_ab.dart`**

Add to `tool_channel.dart`:

```dart
/// The Ollama message list for one prior exchange answered with a card.
///
/// A card that arrived through the tool channel must be replayed the way it
/// arrived — as an assistant turn carrying `tool_calls` — not as assistant
/// text that happens to contain JSON. The server today stores a card reply's
/// raw JSON as `replyText` and replays it verbatim, which is correct for the
/// prose channel and wrong for this one; a model shown its own structured
/// output as prose is being asked a different question than the one the
/// cascade probe means to ask.
List<Map<String, dynamic>> toolCallHistory({
  required String userTurn,
  required List<Map<String, dynamic>> cardBody,
}) => [
  {'role': 'user', 'content': userTurn},
  {
    'role': 'assistant',
    'content': '',
    'tool_calls': [
      {
        'function': {
          'name': 'render_adaptive_card',
          'arguments': {'body': cardBody},
        },
      },
    ],
  },
];
```

Then give `cascade_ab.dart` a `--channel prose|tool` option matching Task 1's, using `probeOnceViaTool` for turn 1 and, for turn 2, a call whose messages are `toolCallHistory(...)` plus the follow-up user turn. Turn 2's card body comes from `toolCallArguments` on turn 1's message.

`probeOnceViaTool` currently takes a flat `List<String> history`. Extend it with an optional `List<Map<String, dynamic>> rawHistory` that, when present, is used verbatim instead — a tool-call turn cannot be expressed as a plain string.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd adaptive_chat_server_dart
fvm dart test test/cascade_judge_test.dart test/tool_channel_test.dart
```

Expected: PASS, including the pre-existing cascade judging tests unchanged.

- [ ] **Step 5: Analyze, changelog, commit**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm dart analyze adaptive_chat_server_dart/
fvm dart format adaptive_chat_server_dart/
npm run format:md:chat
```

Expected: `No issues found!` Commit with a CHANGELOG bullet explaining the history-representation decision and why replaying a tool call as text would have been wrong.

---

### Task 4: Run the multi-turn arm and record it — GATED on Task 2 Step 6

**Needs a live Ollama.** Same serial rules.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results/<model>/cascade_ab-tool.json`
- Modify: `ModelBehavior.md`, `check_results.dart`, `sweep.sh`, `CHANGELOG.md`

- [ ] **Step 1: Run the cascade on the tool channel, serially**

Same eight models, same one-resident-at-a-time discipline, `--channel tool`, writing to `cascade_ab-tool.json` per model.

- [ ] **Step 2: Compare against the recorded prose cascade**

On the prose channel this axis did not discriminate — fourteen of fifteen models scored 3/3 — so the interesting outcome is any model that _drops_ on the tool channel. A tool-channel score below 3/3 means the model can produce a card but cannot edit one it produced through the same channel, which would be a genuine argument against the channel that single-turn measurement cannot see.

- [ ] **Step 3: Test warm-start drift**

Run `shape_ab.dart --channel tool` with history already present (the `withHistory` condition from Task 2 covers this) and compare its erosion against the prose channel's recorded erosion. The ledger records that `table` erodes with history on 4 of 6 seeded models; whether the tool channel erodes differently is the question.

- [ ] **Step 4: Record, register, verify, commit**

Add the multi-turn findings to `ModelBehavior.md`, register `cascade_ab-tool` in `expectedProbes` and `sweep.sh`, run the full verification, and commit.

**If the tool channel holds up multi-turn**, the next question — explicitly out of scope here — is whether the server should get a `--reply-channel` flag. That needs its own spec, because it raises design questions this plan does not answer: whether the channel forces the prompt, whether `checkReadiness()` should refuse a model that cannot call tools, and what a tool-channel reply with no tool call means to the server.

---

## Final Task: Full verification

- [ ] **Step 1: Full suite**

```bash
cd adaptive_chat_server_dart
fvm dart test
```

- [ ] **Step 2: Analyze the whole repo**

```bash
cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
fvm flutter analyze
```

- [ ] **Step 3: Format gates**

```bash
fvm dart format --output=none --set-exit-if-changed adaptive_chat_server_dart/
npm run check:md:chat
npm run check:md
```

- [ ] **Step 4: Confirm scope**

```bash
git diff --stat main -- packages/
```

Expected: no output.

- [ ] **Step 5: Invoke `superpowers:verification-before-completion`**

Paste command output — exit codes and pass/fail counts — before any success claim.
