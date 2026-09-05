# M1 Max: Schema A/B and Second-Host Prefill Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the Apple M1 Max / 64 GB, answer the two questions the 16 GB M5 cannot — whether `--json-format schema` now repairs the shapes `qwen3.6:27b-coding-nvfp4` misses, and whether the prompt-cache figures hold on a second host — then carry whichever way each lands into the notebook and the blog, and retire the 0.32.x references the answers supersede.

**Architecture:** Two experiments meant to be separated by an Ollama upgrade, in that order for a reason: the schema A/B matched to the published **0.33.2** canary verdicts, then the prefill-cache work, which needs `prompt_eval_cached_count` and does not exist before **0.33.3**. That premise did not hold — the host was already serving 0.33.3 when Task 2 began. The plan's own escape hatch (Task 2 Step 1) fired: the format canary was re-established first, under Task 4, and the schema A/B then ran under 0.33.3 with every figure labelled accordingly. Tasks 7 and 8 close the loop: the blog is derived from the notebook and drifts silently when it moves, and a runtime reference that no longer carries a difference is noise once the difference has been measured.

_Written 2026-09-04: "The schema A/B must run under 0.33.2 … Upgrading first would strand the A/B; running the A/B first costs nothing." Execution found the host already upgraded, which the plan had anticipated as a stop condition rather than the default path._

**Tech Stack:** zsh, Ollama 0.33.2 then 0.33.3 (server), Dart 3.12.0 via FVM, Prettier (Markdown format gate).

**Spec:** No separate spec document. This plan's premises were read from the working tree and from `adaptive_chat_server_dart/ModelBehavior.md` on 2026-09-04; the "Facts established before writing this plan" section is the spec, and every claim in it was read from a file rather than recalled.

_Executed 2026-09-04 on `feat/cached-prompt-tokens-prefill-probe`. Tasks 1–9 are complete and reviewed. Task 10 was added after this plan was written and is complete. Between Tasks 1 and 4, at the user's direction, an additional unnumbered task renamed the two finished archives to carry their runtime: `results-m1max-64gb-ollama033/` to `results-m1max-64gb-ollama0332/`, `results-m5-16gb-ollama033/` to `results-m5-16gb-ollama0331/`._

**Markers on checked steps below:**

- `- [x]` — ran as written.
- `- [x] ⚠️ **DIVERGED**` — ran, but differently than written; the step text now records what was done.
- `- [x] ⏭️ **SUPERSEDED**` — not run; the requirement was satisfied another way.
- `- [x] ❗ **PLAN DEFECT**` — the step as written was wrong and would have failed or misled; corrected text is what ran.
- `- [x] 🔍 **UNEXPECTED RESULT**` — ran as written, but the outcome contradicted the step's own stated expectation.

## Global Constraints

- **Branch strategy.** This plan is committed on `feat/cached-prompt-tokens-prefill-probe` so it travels to the other machine, but the work splits: **Tasks 1–3 (the schema A/B) belong on a new branch off `main`** — they are the follow-up recorded from PR #77 and are unrelated to cached prompt tokens. **Tasks 4–8 belong on this branch** (or its successor if it has merged), because they strengthen claims this branch publishes. Do not mix the two in one commit.

  _Executed 2026-09-04: all ten tasks ran on `feat/cached-prompt-tokens-prefill-probe`, at the user's explicit direction, rather than splitting the schema A/B onto a separate branch._

- **Prefix every `flutter` and `dart` command with `fvm`.** Bare `dart` may not be the pinned SDK.
- **One model resident at a time.** Never run two probes concurrently, and never start a probe while `ollama ps` lists a model. Load, run every probe for that model, unload, wait, switch. A number collected any other way is not comparable to anything.
- **Re-run a suspicious row on an idle machine before recording it.** This rule has already caught two bad rows in this notebook.
- **The server version is what `/api/version` reports**, never the `ollama --version` client line. They skewed on the M5 during this work: the client read 0.33.3 while the resident daemon still served 0.33.1, because `Ollama.app` had been upgraded on disk without the running daemon being replaced. Check `curl -s http://127.0.0.1:11434/api/version` and, after an upgrade, confirm the daemon actually restarted.
- **Do not write into `results-m1max-64gb-ollama0332/` or `results-m5-16gb-ollama0331/`.** Both are finished archives that `check_results.dart` reads and CI polices. Anything measured under 0.33.3 on this host goes to a new sibling, `results-m1max-64gb-ollama0333/`, per the sibling-naming rule in `CLAUDE.md`.
- **Documentation tone (CLAUDE.md).** Flat analytical register: no amplifying adverbs, replace superlatives with the figure, bold reserved for a section's load-bearing claim and for figures, hedge inferred mechanisms, end on the last factual sentence.
- **Markdown format gate.** `adaptive_chat_server_dart/**` is covered by `npm run check:md:chat`, **not** by `npm run check:md`. Run the `:chat` one.
- **Blog length cap.** `blog/README.md` sets ~2,000 prose words per article, hard cap 3,000. Article 5 currently sits at **2,996** — four words of headroom. Any addition to it must be paid for by a trim, or the cap raised deliberately.

  _Executed 2026-09-04: article 5 was 2,999 words when this plan was written; it was trimmed to 2,996 to pay for the additions in Task 7._

- **Never commit or push without explicit user confirmation** (CLAUDE.md git gate), except the standing exception for subagent-driven plan execution committing completed tasks to the feature branch.

## Facts established before writing this plan

Recorded here so no task has to re-derive them. Read from the tree on 2026-09-04.

| Fact                                 | Value                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `shape_ab.dart` `--json-format` flag | **Does not exist.** Its parser has `baseline`, `candidate`, `only`, `channel`, `reinforce`, `seed-card`, `seed-card-file`, `json`, `model`, `url`, `samples`, `timeout`, `help`. This is why Task 1 exists.                                                                                                                                                                                                                                                |
| `probeOnce` format support           | Already present: `probe_support.dart:270` takes `Object? format` and sends `'format': ?format`. Only the CLI wiring is missing.                                                                                                                                                                                                                                                                                                                            |
| Card schema loader                   | `loadCardSchema()` in `probe_support.dart:155`, returns `Map<String, dynamic>`.                                                                                                                                                                                                                                                                                                                                                                            |
| Result-file naming                   | `shape_ab.dart:365` sets `variant` from the channel and seeding only: `channel == 'tool' ? 'channel-tool' : (seeded ? 'seeded' : 'unaided')`. A constrained run would therefore record as plain `seeded`.                                                                                                                                                                                                                                                  |
| **The collision this creates**       | `sync_shape_table.dart:131` selects the canonical shape-table row with `r.probe == 'shape_ab' && r.variant == 'seeded'`, an exact match, and `results-m1max-64gb-ollama0332/` is `shapeTableDir` — the directory the published table derives from. A schema run filed there as `seeded` becomes a **second** run matching that filter for the same model, and which one `pick()` returns is not defined. Task 1 extends the variant so this cannot happen. |
| Unknown result files                 | Safe. `check_results.dart` reports only **missing** expected probes (`expectedProbes`, line 37); an extra file is not flagged. Do **not** add the A/B to `expectedProbes` — it is a one-off, not a per-model sweep probe.                                                                                                                                                                                                                                  |
| M1 Max runtime as last measured      | **0.33.2** (the 2026-09-01 sweep).                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Canary verdicts under 0.33.2         | `qwen3.6:27b-coding-nvfp4` **honored**, `qwen3.8:27b-nvfp4` **honored**, `gpt-oss:20b` `ignored-destructively`, unsloth GGUF `ignored-harmlessly`.                                                                                                                                                                                                                                                                                                         |
| The shapes under test                | `qwen3.6:27b-coding-nvfp4` permanently misses `carousel` and `columnset` as **invalid JSON** — the failure constrained decoding exists to prevent.                                                                                                                                                                                                                                                                                                         |
| Model weights                        | `qwen3.6:27b-coding-nvfp4` 18.4 GB, `qwen3.8:27b-nvfp4` 16.9 GB. Neither fits a 16 GB host, which is why this is M1 Max work.                                                                                                                                                                                                                                                                                                                              |
| `prompt_eval_cached_count`           | Ollama **0.33.3** and later only. Absent on 0.33.2.                                                                                                                                                                                                                                                                                                                                                                                                        |
| M5 cache figures to compare against  | identical repeat 2142/2143 cached, 2017 ms → 18 ms; new question 2136/2144, 60 ms; growing turns 2–3 ~94 ms; interleaved 2136/2143, 55 ms; retry after abort 2443/2444, 29 ms.                                                                                                                                                                                                                                                                             |
| Duplicate-key risk                   | `ModelBehavior.md` records duplicate-key corruption "seen under schema-constrained decoding". `judgeShape` already runs `checkNoDuplicateJsonKeys`, so a schema arm that corrupts this way will be scored a failure rather than a pass.                                                                                                                                                                                                                    |

This table is a dated snapshot, left as written. Execution corrected three of its premises: the `shape_ab.dart:365` variant logic (Task 1 Step 6 changed it as planned, so the collision it describes did not occur); the result-record field names, which are `case` and `pass`, not `caseId` and `ok`; and `qwen3.6:27b-coding-nvfp4`'s `carousel`/`columnset` misses, which the schema arm changed on some but not all cases rather than leaving as a permanent miss — see Task 2 Step 7's corrected snippet and Task 3's recorded result.

---

### Task 1: Teach the probes to send `format`

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/probe_support.dart` (add `resolveProbeFormat`)
- Modify: `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart:206` (add the option), `:100-112` (pass it), `:266-274` (leave the forwarding list alone — `json-format` is consumed locally, not forwarded to `parseProbeArgs`)
- Test: `adaptive_chat_server_dart/test/probe_format_test.dart` (create)

**Interfaces:**

- Consumes: `loadCardSchema()` from `probe_support.dart`.
- Produces: `Object? resolveProbeFormat(String mode)` — `'json'` → the string `'json'`, `'schema'` → the schema map, anything else → `null`. Task 2 invokes the flag it enables.

Run every command below from `adaptive_chat_server_dart/`.

- [x] **Step 1: Write the failing test**

Create `test/probe_format_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';

void main() {
  group('resolveProbeFormat', () {
    test('none yields no constraint', () {
      expect(resolveProbeFormat('none'), isNull);
    });

    test('json yields the bare json constraint', () {
      expect(resolveProbeFormat('json'), 'json');
    });

    test('schema yields the bundled card schema', () {
      final format = resolveProbeFormat('schema');
      expect(format, isA<Map<String, dynamic>>());
      expect((format! as Map<String, dynamic>).containsKey('oneOf'), isTrue);
    });
  });

  group('probeOnce format pass-through', () {
    late HttpServer server;
    late HttpClient client;
    late List<Map<String, dynamic>> bodies;

    setUp(() async {
      bodies = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(() async {
        await for (final request in server) {
          final raw = await utf8.decoder.bind(request).join();
          bodies.add(jsonDecode(raw) as Map<String, dynamic>);
          request.response
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'message': {'content': '[]'},
                'prompt_eval_count': 1,
                'eval_count': 1,
              }),
            );
          await request.response.close();
        }
      }());
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    test('a format reaches the wire when one is asked for', () async {
      await probeOnce(
        client: client,
        url: 'http://127.0.0.1:${server.port}',
        model: 'test-model',
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        format: resolveProbeFormat('json'),
      );
      expect(bodies.single['format'], 'json');
    });

    test('no format key is sent when none is asked for', () async {
      await probeOnce(
        client: client,
        url: 'http://127.0.0.1:${server.port}',
        model: 'test-model',
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        format: resolveProbeFormat('none'),
      );
      expect(bodies.single.containsKey('format'), isFalse);
    });
  });
}
```

If `unawaited` is unresolved, add `import 'dart:async';` — `probe_timeout_test.dart` is the reference for this fake-server pattern.

- [x] **Step 2: Run the test to verify it fails**

```bash
fvm dart test test/probe_format_test.dart
```

Expected: FAIL — `resolveProbeFormat` is not defined.

- [x] **Step 3: Add `resolveProbeFormat`**

In `probe_support.dart`, directly beneath `loadCardSchema()`:

```dart
/// Maps a `--json-format` mode to what [probeOnce] should send as `format`.
///
/// Mirrors the server's own `--json-format` flag so a probe measures what the
/// server would do rather than a probe-only convention: `none` sends no
/// constraint at all, `json` asks only for valid JSON, and `schema` sends the
/// bundled card schema. Whether a model honors any of it is per-model **and**
/// per-runtime — check `json_format_probe.dart` before reading a result.
Object? resolveProbeFormat(String mode) => switch (mode) {
  'json' => 'json',
  'schema' => loadCardSchema(),
  _ => null,
};
```

- [x] **Step 4: Run the test to verify it passes**

```bash
fvm dart test test/probe_format_test.dart
```

Expected: PASS, 5 tests.

- [x] **Step 5: Add the flag to `shape_ab.dart`**

In the `ArgParser`, immediately after the `only` option (line 206):

```dart
    ..addOption(
      'json-format',
      defaultsTo: 'none',
      allowed: ['none', 'json', 'schema'],
      help:
          'Constrained decoding for the prose channel, mirroring the '
          "server's --json-format. Only meaningful for a model whose "
          'json_format_probe verdict is honored on the runtime under test; '
          'a model that ignores the constraint produces an identical arm.',
    )
```

Then read it once, above the case loop, beside `final reinforce = ...`:

```dart
  final probeFormat = resolveProbeFormat(parsed['json-format'] as String);
```

and pass it in the **prose** branch of the `probeOnce` call (the `: await probeOnce(` arm), after `reminder:`:

```dart
              format: probeFormat,
```

Leave `probeOnceViaTool` alone: the tool channel carries the schema in the tool definition already, and combining the two measures neither.

- [x] **Step 6: Extend `variant` so a constrained run cannot impersonate the canonical one**

This is the load-bearing half of the task. At `shape_ab.dart:365` the variant is currently:

```dart
      variant: channel == 'tool'
          ? 'channel-tool'
          : (seeded ? 'seeded' : 'unaided'),
```

Replace it with a form that carries the constraint, so `sync_shape_table.dart`'s exact `variant == 'seeded'` match keeps selecting only unconstrained runs:

```dart
      variant: switch (channel) {
        'tool' => 'channel-tool',
        // The format mode is part of the identity of a run: an unconstrained
        // arm and a schema-constrained one are different measurements, and
        // sync_shape_table.dart selects the canonical row by an exact
        // `variant == 'seeded'` match. A constrained run recorded as plain
        // `seeded` would become a second candidate for that row.
        _ =>
          '${seeded ? 'seeded' : 'unaided'}'
              '${parsed['json-format'] == 'none' ? '' : '-format-${parsed['json-format']}'}',
      },
```

Verify the unconstrained default is byte-identical to what the archive already holds — an unconstrained seeded run must still record `variant: "seeded"`, or every archived row stops matching:

```bash
fvm dart run tool/model_probes/check_results.dart
```

Expected: OK, with no new missing-probe findings.

- [x] **Step 7: Guard the combination that cannot mean anything**

After the existing `channel == 'tool'` guard block, add:

```dart
  if (channel == 'tool' && parsed['json-format'] as String != 'none') {
    stderr.writeln(
      'shape_ab: --channel tool already carries the schema in the tool '
      'definition, so --json-format on top of it measures neither '
      'constraint cleanly. Drop one.',
    );
    exitCode = 2;
    return;
  }
```

- [x] **Step 8: Verify the whole suite and the gates**

```bash
fvm dart test
fvm dart analyze
fvm dart format --output=none --set-exit-if-changed lib/ test/ tool/
fvm dart run tool/model_probes/shape_ab.dart --help
```

Expected: all tests pass, no analyzer issues, format clean, and `--json-format` visible in the usage text.

- [x] **Step 9: Commit**

```bash
git add test/probe_format_test.dart tool/model_probes/probe_support.dart \
        tool/model_probes/shape_ab.dart
git commit -m "feat(chat-server): let shape_ab send Ollama's format constraint"
```

_Executed 2026-09-04: review of this task found `probeAssetsDir()`'s fallback accepted any directory named `assets` without checking it held the probe assets. A follow-up commit, `011e07e` ("require the assets sentinel before accepting a probeAssetsDir() candidate"), added a sentinel check plus `test/probe_assets_dir_test.dart`._

---

### Task 1b: Rename the results archives so every directory states its runtime

_Executed 2026-09-04, between Tasks 1 and 4, at the user's direction. Not part of the plan as written — added because `ollama033` had come to denote 0.33.2 on the M1 Max and 0.33.1 on the M5, one label for two runtimes, the exact failure `CLAUDE.md`'s sibling-naming rule describes._

- [x] `results-m1max-64gb-ollama033/` → `results-m1max-64gb-ollama0332/` (held 0.33.2)
- [x] `results-m5-16gb-ollama033/` → `results-m5-16gb-ollama0331/` (held 0.33.1, per its own `MODELS.md`)
- [x] Renamed with `git mv`; 172 files moved with zero content change
- [x] Updated every reference that must resolve: `check_results.dart`'s `shapeTableDir` and its doc comment, `perf_table.py`, `sweep.sh`, `tool/model_probes/README.md`, `ModelBehavior.md`, the active plan, and `CLAUDE.md`'s sibling-naming worked example — which used these very directories and would otherwise have prescribed names the tree no longer holds
- [x] Left alone, per `CLAUDE.md`'s own rule that records are not references: the completed `2026-09-01` sweep plan and the dated `CHANGELOG.md` entries
- [x] `sync_shape_table.dart` and `test/check_results_test.dart` needed no edit — both compose their path from the `shapeTableDir` constant
- [x] Commit `84a5334`

---

### Task 2: Measure the schema A/B on `qwen3.6:27b-coding-nvfp4`, under 0.33.3

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama0333/qwen3.6_27b-coding-nvfp4/shape_ab-seeded-format-schema.json`

**Interfaces:**

- Consumes: the `--json-format` flag from Task 1.
- Produces: two comparable runs — the recorded baseline already in the archive, and the new schema arm — for Task 3 to write up.

🔍 **UNEXPECTED RESULT, task-level:** the schema arm showed `carousel` warm passing 3/3, which did not reproduce. A 1-sample confirm and a 3-sample recheck on an idle machine, required by the standing "re-run a suspicious row" rule, both returned timeouts, giving an aggregate of cold 0/7 and warm 3/7 with all passes in the earliest run. Those two extra runs are not in the plan as written; they are archived as `shape_ab-seeded-format-schema-confirm.json` and `shape_ab-seeded-format-schema-recheck.json`.

- [x] ⚠️ **DIVERGED** — **Step 1: Confirm the runtime, and act on what it reads**

```bash
curl -s http://127.0.0.1:11434/api/version
```

_Executed 2026-09-04: the runtime read `{"version":"0.33.3"}`, not 0.33.2. The step's own stop condition fired — the host was already upgraded, ahead of this plan. Task 4's canary re-run ran first; every Task 2 figure below is labelled 0.33.3._

- [x] **Step 2: Confirm the model is present and the machine is idle**

```bash
ollama ps
curl -s http://127.0.0.1:11434/api/tags | grep -o 'qwen3.6:27b-coding-nvfp4'
```

Expected: `ollama ps` lists nothing resident; the tag is present. If another model is resident, `ollama stop <model>` and wait for the GPU to go idle.

- [x] ⏭️ **SUPERSEDED** — **Step 3: Confirm this model still honors `format` on this runtime**

```bash
python3 -c "import json; print(json.load(open('tool/model_probes/results-m1max-64gb-ollama0333/qwen3.6_27b-coding-nvfp4/json_format_probe.json'))['summary']['verdict'])"
```

_Executed 2026-09-04: not re-run. Task 4 had already measured the canary under this runtime; the verdict was read from `summary.verdict` in the recorded file above (`honored`) rather than paying a second ~20 GB model load._

- [x] ⚠️ **DIVERGED** — **Step 4: Run the schema arm on the shapes under test plus controls**

`carousel` and `columnset` are the failures; `prose`, `date`, and `choice1` are controls that must not regress. Both arms are seeded, matching how the server ships.

```bash
fvm dart run tool/model_probes/shape_ab.dart \
  --model qwen3.6:27b-coding-nvfp4 \
  --json-format schema \
  --only carousel,columnset,prose,date,choice1 \
  --samples 3 \
  --json tool/model_probes/results-m1max-64gb-ollama0333/qwen3.6_27b-coding-nvfp4/shape_ab-seeded-format-schema.json
```

_Executed 2026-09-04: written to `…ollama0333/…`, not `…0332/`, because `…0332/` is a finished archive that a Global Constraint forbids writing into._

With Task 1's variant change this records `variant: "seeded-format-schema"`, which `sync_shape_table.dart`'s exact `variant == 'seeded'` match ignores. **Confirm that before trusting the run:** `python3 -c "import json;print(json.load(open('<path>'))['variant'])"` must print `seeded-format-schema`. If it prints `seeded`, Task 1 Step 6 did not land — delete the file and fix it, or the published shape table gains a second candidate row for this model.

- [x] ⚠️ **DIVERGED** — **Step 5: Run the matching unconstrained arm for a same-session baseline**

The archived `shape_ab-seeded.json` covers all 25 cases from an earlier session. Re-running the same five cases now removes session-to-session drift from the comparison.

```bash
fvm dart run tool/model_probes/shape_ab.dart \
  --model qwen3.6:27b-coding-nvfp4 \
  --json-format none \
  --only carousel,columnset,prose,date,choice1 \
  --samples 3 \
  --json tool/model_probes/results-m1max-64gb-ollama0333/qwen3.6_27b-coding-nvfp4/shape_ab-seeded-format-none.json
```

_Executed 2026-09-04: the control arm went to the plan workspace, not `/tmp`, and was archived at the path above rather than discarded._

- [x] **Step 6: Unload the model**

```bash
ollama stop qwen3.6:27b-coding-nvfp4
ollama ps
```

Expected: nothing resident.

- [x] ❗ **PLAN DEFECT** — **Step 7: Read both runs and write down the four numbers that matter**

For each arm record: `carousel` pass/fail, `columnset` pass/fail, whether any control regressed, and whether any reply failed on **duplicate keys** — the corruption `ModelBehavior.md` associates with schema-constrained decoding.

```bash
python3 -c "
import json
for name, path in [('none','tool/model_probes/results-m1max-64gb-ollama0333/qwen3.6_27b-coding-nvfp4/shape_ab-seeded-format-none.json'),
                   ('schema','tool/model_probes/results-m1max-64gb-ollama0333/qwen3.6_27b-coding-nvfp4/shape_ab-seeded-format-schema.json')]:
    d = json.load(open(path))
    print(name, d.get('summary'))
    for c in d['calls']:
        print(' ', c['case'], c.get('label'), c.get('pass'))
"
```

_Executed 2026-09-04: as written, the snippet reads `c['caseId']` and `c.get('ok')`. Neither field exists — the recorded JSON keys are `case` and `pass` — so as written it raises `KeyError` after the model load, at the most expensive moment. The corrected snippet above, with the paths from Steps 4–5, is what ran._

- [x] ⚠️ **DIVERGED** — **Step 8: Commit the recorded run**

```bash
git add tool/model_probes/results-m1max-64gb-ollama0333/qwen3.6_27b-coding-nvfp4/shape_ab-seeded-format-schema.json
git commit -m "measure(chat-server): schema-constrained shape A/B for qwen3.6 under 0.33.3"
```

_Executed 2026-09-04: committed under `…0333/…`, not `…0332/`, matching Step 4's output path (commit `5ff136f`). A follow-up run archived the carousel-warm contradiction noted at the top of this task (commit `4cac46b`)._

---

### Task 3: Record the A/B result, whichever way it went

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md:452` (the format-canary section's closing limit), `:755` (the `qwen3.6` per-model note)
- Modify: `adaptive_chat_server_dart/CHANGELOG.md` (`## [Unreleased]`)

- [x] **Step 1: Replace the "has not been measured" clause at line 452**

The sentence currently ends: "…whether `--json-format schema` improves the shapes the `nvfp4` builds actually miss (`qwen3.6:27b-coding-nvfp4`'s `Carousel`/`ColumnSet` invalid-JSON failures) has not been measured." Replace that clause with the measured outcome, in the file's register — the figure, the condition, and no adverbs. A null result is written as plainly as a positive one: "Measured at `--samples 3` on five cases, the schema arm changed no case" — plus the date and runtime — is a complete finding.

- [x] **Step 2: Replace the open-follow-up sentence in the `qwen3.6` per-model note at line 755**

It currently reads "…Whether the now-enforced constraint helps its permanent `Carousel`/`ColumnSet` invalid-JSON failures has not been measured; that A/B is the open follow-up the flip creates." Replace with the result and its condition.

- [x] **Step 3: If the schema arm helped, do not promote it in the same change**

Recording a measurement and changing what `launch.json` ships are separate decisions, and the constraint has a known cost: it forbids the prompt's legal Markdown escape hatch, so it changes reply semantics rather than only tightening JSON. Note that trade-off beside the result and leave the promotion to the user.

- [x] **Step 4: Add a `CHANGELOG.md` bullet under `## [Unreleased]`**

Keep it in the existing list — no blank line between bullets, which renders the list loose.

- [x] **Step 5: Verify the gates**

```bash
cd .. && npm run format:md:chat && npm run check:md:chat && cd adaptive_chat_server_dart
fvm dart run tool/model_probes/check_results.dart
```

Expected: prettier clean, and `check_results` OK.

- [x] **Step 6: Commit**

```bash
git add ModelBehavior.md CHANGELOG.md
git commit -m "docs(chat-server): record the schema-constrained shape A/B for qwen3.6"
```

---

### Task 4: Upgrade to 0.33.3 and re-establish what the upgrade invalidates

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama0333/` (new sibling directory)

Everything from here belongs on the cached-prompt-tokens branch, not the A/B branch.

- [x] ⏭️ **SUPERSEDED** — **Step 1: Confirm the daemon is serving 0.33.3**

```bash
curl -s http://127.0.0.1:11434/api/version
```

Expected: `{"version":"0.33.3"}`. The client binary upgrading is not enough — on the M5 the resident daemon kept serving 0.33.1 after the app was updated on disk, and `ollama --version` printed a `Warning: client version is …` line. If the version has not moved, restart `Ollama.app` and re-check.

_Executed 2026-09-04: no upgrade was required. The host was already serving 0.33.3 when this task began, per Task 2 Step 1's stop condition._

- [x] **Step 2: Re-run the format canary for the two `nvfp4` builds**

The published `honored` verdicts were measured on 0.33.2, and the file's own rule is that the canary is per-runtime. One model at a time.

```bash
fvm dart run tool/model_probes/json_format_probe.dart \
  --model qwen3.6:27b-coding-nvfp4 --samples 2 \
  --json tool/model_probes/results-m1max-64gb-ollama0333/qwen3.6_27b-coding-nvfp4/json_format_probe.json
ollama stop qwen3.6:27b-coding-nvfp4

fvm dart run tool/model_probes/json_format_probe.dart \
  --model qwen3.8:27b-nvfp4 --samples 2 \
  --json tool/model_probes/results-m1max-64gb-ollama0333/qwen3.8_27b-nvfp4/json_format_probe.json
ollama stop qwen3.8:27b-nvfp4
```

- [x] **Step 3: Record whether the verdicts held**

If both still read `honored`, say so in one sentence at `ModelBehavior.md:452` — a verdict that survives a runtime bump is worth recording precisely because the section's claim is that it might not. If either moved, that is a larger finding and supersedes the A/B's premise; say so plainly and note that Task 2's figures were measured under 0.33.2.

- [x] **Step 4: Note the sampled-temperature caveat without re-running the sweep**

Ollama 0.33.3 adds "Honor GGUF model defined default parameters". The probes pin `temperature`, `think`, and `num_ctx` but **not** `top_p`/`top_k`/`repeat_penalty`, so figures sampled at `t=0.2`/`0.6` may not be comparable across the upgrade; `t=0` greedy figures are shielded. Add one sentence recording that, and do **not** re-run the full sweep — that is a separate decision with its own cost.

- [x] **Step 5: Commit**

```bash
git add tool/model_probes/results-m1max-64gb-ollama0333 ModelBehavior.md CHANGELOG.md
git commit -m "measure(chat-server): re-run the format canary on the M1 Max under 0.33.3"
```

---

### Task 5: Run the prefill cache probe on the second host

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md:897` (the "one model, one host, one runtime" caveat)

- [x] **Step 1: Run the committed probe against the same model the M5 used**

Holding the model fixed is what makes this a host comparison rather than a new experiment.

```bash
fvm dart run tool/model_probes/prefill_cache_probe.dart --model llama3.2:latest
```

- [x] **Step 2: Compare against the M5 run, and expect the shape rather than the digits**

The M5 figures are in the table at `ModelBehavior.md:883`. What should reproduce is the **pattern** — a cold prefill in the seconds, a warm repeat in the tens of milliseconds, a growing conversation paying only for its new tokens, the cache surviving an interleaved request, and a retry after an abort costing a warm repeat. Absolute milliseconds will differ; the M1 Max is a different machine. Do not report a difference in absolute prefill time as a finding without a same-host control, which is the trap the `qwen3.5:9b` 1.54x position bias already sprang once.

- [x] 🔍 **UNEXPECTED RESULT** — **Step 3: Run it again on a large model, which the M5 could not hold**

```bash
fvm dart run tool/model_probes/prefill_cache_probe.dart --model qwen3.8:27b-nvfp4
ollama stop qwen3.8:27b-nvfp4
```

This is the half of the caveat the M5 cannot retire: whether cache behavior is a property of the runtime or of a 2 GB model.

- [x] 🔍 **UNEXPECTED RESULT** — **Step 4: Rewrite the caveat to match what is now established**

Line 897 currently reads "Caveat: one model, one host, one runtime, single-turn-scale replies." Narrow it to whatever survives — two hosts and two models, if both runs agree — and keep the parts that do not (single-turn-scale replies; retention limits and eviction policy under memory pressure still unprobed).

_Executed 2026-09-04, Steps 3–4: `qwen3.8:27b-nvfp4` agreed with the M5 pattern on three of five cases but returned full cold prefills (`cached=4` of roughly 3,177, roughly 40 s) for "same system prompt, different question" and for the interleaved request, and its retry-after-abort was unstable (148 ms at 3472 cached, then 18,154 ms at 2063 cached). A full repeat run on an idle machine, not in the plan, confirmed both readings as measured and destabilised the retry row. The interleaved-unrelated miss was later reframed as structurally expected on any model — the interleaved prompt shares only a short instruction prefix before diverging entirely — rather than a large-model-specific miss, leaving the cross-question miss as the one reading that is genuinely model-specific. The caveat below was widened on this dimension while narrowing on the two-host claim._

- [x] **Step 5: Verify and commit**

```bash
cd .. && npm run format:md:chat && npm run check:md:chat && cd adaptive_chat_server_dart
fvm dart run tool/model_probes/check_results.dart
git add ModelBehavior.md CHANGELOG.md
git commit -m "measure(chat-server): prompt-cache figures reproduce on a second host"
```

---

### Task 6: Confirm the truncation warning fires against a live server

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md` (Measurement lessons, the silent-truncation bullet)

The `_logContextFill` fix is proven only against a mocked response. This is the one code change in the branch, and the failure it detects is the one that invalidated an entire probe run.

- [x] **Step 1: Start the server with a small window**

```bash
fvm dart run bin/server.dart --port 18434 \
  --ollama-model llama3.2:latest \
  --system-prompt-file assets/card_system_prompt.txt \
  --num-ctx 2048
```

The shipped card system prompt is ~3,800 tokens, so a 2,048-token window guarantees the overflow this checks for.

- [x] **Step 2: Send one interaction and read the log**

```bash
CID=$(curl -s -X POST http://127.0.0.1:18434/conversations \
  -H 'Content-Type: application/json' -d '{}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['conversationId'])")
curl -s -X POST "http://127.0.0.1:18434/conversations/$CID/interactions" \
  -H 'Content-Type: application/json' -H 'X-Interaction-Id: trunc1' \
  -d '{"data":{"message":"Briefly, what is SDUI?"}}' > /dev/null
```

Expected in the server log: a **warning** containing `Ollama prompt truncated`, naming an estimate above 2,048 and an evaluated count below it. Before the fix this logged a calm `context filling … (50%)` info line.

- [x] **Step 3: Confirm the negative case**

Restart with `--num-ctx 8192` and repeat. Expected: **no** `prompt truncated` warning.

- [x] **Step 4: Stop the server and unload**

```bash
curl -s http://127.0.0.1:11434/api/chat -d '{"model":"llama3.2:latest","keep_alive":0}' > /dev/null
ollama ps
```

- [x] **Step 5: Record the confirmation in one sentence**

Add to the silent-truncation bullet in Measurement lessons that the detector now warns on it, confirmed against a live server at `num_ctx` 2048 with the shipped card prompt. Keep it to one clause — the bullet's subject is the trap, not the fix.

- [x] **Step 6: Commit**

```bash
git add ModelBehavior.md CHANGELOG.md
git commit -m "docs(chat-server): confirm the truncation warning against a live server"
```

---

### Task 7: Propagate to the blog, and retire the 0.32.x references this plan supersedes

**Files:**

- Modify: `adaptive_chat_server_dart/blog/2026-08-30-article-2-tuning-process-draft.md:121` (the decoding-levers row)
- Modify: `adaptive_chat_server_dart/blog/2026-08-30-article-5-measurement-hygiene-draft.md` (the prompt-cache section, ~line 251)
- Modify: `adaptive_chat_server_dart/ModelBehavior.md` (the 0.32.x pass)

Two separate jobs that touch the same files, so they share a task: carrying this plan's measurements into the blog, and cleaning up runtime references the measurements make obsolete.

#### Part A — the blog claims these measurements can change

The blog is derived from the notebook and drifts silently when the notebook moves. Three specific claims are downstream of Tasks 2–6:

- [x] **Step 1: Article 2, the `format` lever row (line 121)**

It currently reads `Per-model and per-runtime, unreliable` with evidence naming the `nvfp4` flip. If Task 2 found the schema arm repairs `carousel`/`columnset`, this row understates the lever and needs the new figure; if it found no change, the row needs the null stated, because "honored" without "and it helps" is exactly the misreading the row exists to prevent. Either way the row cannot stay as it is once the A/B is measured.

- [x] ❗ **PLAN DEFECT** — **Step 2: Article 5, the prompt-cache section**

Its table is attributed `Apple M5 / 16 GB, Ollama 0.33.3, llama3.2:latest`. Update the attribution to what Task 5 actually found, not the "two hosts and two models" the step as written assumes. Update the attribution line, not the figures — the M5 numbers stay as the published run.

_Executed 2026-09-04: the step's premise — that a Task 5 reproduction on the M1 Max makes this "two hosts and two models" — is false. `qwen3.8:27b-nvfp4` agreed with the M5 pattern on three of five cache cases and disagreed on two (Task 5 Steps 3–4), so the article states the qualified result instead of the broader claim._

- [x] **Step 3: Article 5, the truncation lesson**

If Task 6 confirmed the warning fires against a live server, the section's closing can say the detector now catches it. One clause, not a paragraph — the section's subject is the trap, not the fix.

- [x] **Step 4: Respect the length cap while doing it**

Article 5 sits at **2,999 prose words against a 3,000 cap**. Every addition above must be paid for with a trim in the same edit, or the cap raised deliberately in `blog/README.md`. Measure with the command in Task 8 Step 2 before and after.

#### Part B — retire the superseded 0.32.x references

The rule: **a 0.32.x reference stays only when it carries a cross-runtime difference or the provenance of a figure that was never re-measured. Everything else goes.** Three categories, and the middle one is the trap.

- [x] **Step 5: Inventory what is actually there**

```bash
cd adaptive_chat_server_dart
grep -n '0\.32\.14' ModelBehavior.md | wc -l   # 28 as of 2026-09-04
grep -rn '0\.32\.14' blog/                     # 5 as of 2026-09-04
```

- [x] **Step 6: Classify each hit before editing any of them**

**Keep — the reference _is_ the finding.** The sentence states something that changed between runtimes, and deleting the old runtime destroys the claim. These are most of them:

- The `format` canary flip (`:21`, `:41`, `:450`, `:452`, `:755`, `:782-783`) — "ignored under 0.32.14, honored under 0.33.2" is the whole result.
- The `gpt-oss:20b` seed reversal (`:82`, `:375`, `:377`, `:379`, `:871`).
- The latency null result (`:265`) — "13 of 15 medians within 0.86-1.05x of the same host's 0.32.14 figures" is a comparison; without the baseline it says nothing.
- The stall and eviction comparisons (`:293`, `:302`, `:307`, `:309`).
- `granite4.1:3b`'s clean-versus-clean reading (`:817`).

**Keep — provenance of a figure never re-measured.** This is the trap: Task 4 upgrades the runtime but deliberately does **not** re-sweep, so several published figures remain 0.32.14 measurements. `ModelBehavior.md:237` says exactly that ("The everyday and stress figures elsewhere in this file remain the older **Ollama 0.32.14** measurement on the same M1 Max"). Deleting it would make figures from a two-versions-old runtime read as current. Keep it, and if Task 4 upgraded the host, extend it to say the runtime has since moved on without those figures being re-taken.

**Remove or rewrite — incidental provenance for a superseded figure.** Where a 0.32.14 stamp only dates a figure that a 0.33.x run has since replaced, the stamp is noise. Candidates to read in full and decide individually: `:279`, `:323`, `:741`, `:815`. Do not batch-delete these — read the sentence, confirm a 0.33.x measurement actually supersedes it, and only then drop the stamp.

- [x] **Step 7: The blog needs almost none of this**

Of the five blog hits, four are already cross-runtime claims and stay: article 2's seed reversal (`:93`) and lever row (`:121`), article 5's upgrade delta (`:108`) and granite comparison (`:168`). The fifth, article 5's `:92` ("Under Ollama 0.32.14, the bound changes what one figure means"), is the never-re-measured category — it qualifies a figure correctly and should stay qualified.

- [x] **Step 8: Never change a figure while changing wording**

The CLAUDE.md tone rule and this branch's own history both say so: a trim on this article already dropped a figure that a presence-only check missed. Diff **counts**, not presence, with the script in Task 8 Step 3, and confirm every decrease was intended.

- [x] **Step 9: Verify and commit**

```bash
cd .. && npm run format:md:chat && npm run check:md:chat && cd adaptive_chat_server_dart
git add ModelBehavior.md blog/ CHANGELOG.md
git commit -m "docs(chat-server): carry the M1 Max findings into the blog, retire superseded 0.32.x stamps"
```

---

### Task 8: Full verification

- [x] ⚠️ **DIVERGED** — **Step 1: Run every gate from `adaptive_chat_server_dart/`**

```bash
fvm dart analyze
fvm dart test
fvm dart format --output=none --set-exit-if-changed lib/ test/ tool/
fvm dart run tool/model_probes/check_results.dart
cd .. && npm run check:md:chat && npm run check:md
```

Expected: no analyzer issues; all tests pass; format clean; `check_results` OK; prettier clean.

_Executed 2026-09-04: the gate list as written names only `check:md:chat`. Execution also ran `npm run check:md`, added above, because the branch modified root `CLAUDE.md` and `docs/`, which only the non-`:chat` script covers, and CI runs both._

- [x] **Step 2: Check the blog cap before touching article 5**

```bash
cd adaptive_chat_server_dart && python3 -c "
import re
t=open('blog/2026-08-30-article-5-measurement-hygiene-draft.md').read()
t2=re.sub(r'\`\`\`.*?\`\`\`','',t,flags=re.S); t2=re.sub(r'^\|.*\$','',t2,flags=re.M)
t2=re.sub(r'\(https?://[^)]*\)','',t2); t2=re.sub(r'https?://\S+','',t2)
print('prose:',len(t2.split()),'(cap 3000)')"
```

It sits at 2,999. If any task added to that article, pay for it with a trim or raise the cap deliberately in `blog/README.md` — do not let it drift over silently.

- [x] ⚠️ **DIVERGED** — **Step 3: Diff the numeric tokens of every changed document**

The trim in this branch's history dropped a figure that a token-presence check missed, because the token still appeared elsewhere in the file. Compare **counts**, not just presence, across every changed Markdown file — not only `ModelBehavior.md`:

```bash
python3 - <<'EOF'
import re, subprocess
from collections import Counter
for path in ['adaptive_chat_server_dart/ModelBehavior.md']:  # extend to every changed .md file
    old = subprocess.run(['git','show',f'main:{path}'],capture_output=True,text=True).stdout
    new = open(path).read()
    tok = lambda s: Counter(re.findall(r'\d+(?:[./:x]\d+)*', s))
    co, cn = tok(old), tok(new)
    print(path, 'count decreased:', dict(co-cn))
    print(path, 'count increased:', dict(cn-co))
EOF
```

Every decrease must be one you meant.

_Executed 2026-09-04: the snippet as written diffs one file against `main`. Execution swept every changed Markdown file across the branch instead. It found five decreases, all adjudicated legitimate: an archive rename in two files, two duplicated readings merged into one line, and one restatement removed whose content survives verbatim earlier._

- [x] **Step 4: Report results with the command output, not a summary**

Invoke `superpowers:verification-before-completion` and paste exit codes and pass/fail counts before claiming the plan is complete.

---

### Task 9: Measure whether 0.33.3 honoring GGUF default parameters moves sampled output

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/gguf_defaults_probe.dart`
- Create: `adaptive_chat_server_dart/test/gguf_defaults_probe_test.dart`
- Create: `adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama0333/qwen3.5_9b/gguf_defaults_probe.json`
- Modify: `adaptive_chat_server_dart/ModelBehavior.md` (the sampled-temperature caveat Task 4 added)
- Modify: `adaptive_chat_server_dart/CHANGELOG.md` (`## [Unreleased]`)

**Why this task exists.** Task 4 records a caveat rather than a measurement: Ollama 0.33.3 adds "Honor GGUF
model defined default parameters", the probes pin `temperature`, `think` and `num_ctx` but not
`top_p`/`top_k`/`repeat_penalty`/`presence_penalty`, so figures sampled at `t=0.2`/`0.6` **may** not be
comparable across the upgrade. That is a suspected comparability break published as a limitation. It is
cheap to convert into a yes/no, and the answer changes how every sampled figure in the notebook should be
read. `t=0` greedy figures are shielded either way, because greedy decoding takes the argmax and the
candidate-set parameters cannot change it — so this probe must run at a sampled temperature or it measures
nothing.

**Model choice, already verified.** `qwen3.5:9b` (6.6 GB) is the right subject and the only strong one
installed. Its Modelfile sets `top_k 20`, `top_p 0.95`, `presence_penalty 1.5` and `temperature 1` — the
first three all differ from Ollama's historical defaults (`top_k 40`, `top_p 0.9`, `presence_penalty 0`),
so if 0.33.3 now honors them the effective sampling distribution moved. Checked on 2026-09-04 with
`ollama show --modelfile`: `llama3.2:latest`, `granite4.1:3b`, `granite4.1:8b` and `qwen2.5-coder:7b`
declare no sampling parameters at all and would produce a vacuous, identical-by-construction result.
`nemotron-3-nano:4b` declares only `top_p 1`, a weaker signal. `qwen3.5:9b` also already has baseline rows
in both archives, and its `temperature 1` is neutralised because the probes pin `temperature` explicitly.

**Design.** Two arms against the same model, same prompt, same fixed `seed`, differing only in whether the
candidate-set parameters are sent:

- **Arm `unpinned`** — send what the probes send today: `temperature`, `think`, `num_ctx`, `seed`. Under
  0.33.3 the unsent parameters should take the Modelfile's values.
- **Arm `pinned-historical`** — the same, plus `top_k 40`, `top_p 0.9`, `presence_penalty 0` sent
  explicitly: the effective sampling a pre-0.33.3 server would have applied.

A fixed `seed` removes sampling noise, so a difference between the arms is attributable to the parameters
rather than to chance. Identical replies across arms mean the Modelfile values are not being applied on
this path and the caveat can be narrowed; differing replies mean the comparability break is real and
dated to the upgrade.

- [x] **Step 1: Write the probe's failing test first**

Create `test/gguf_defaults_probe_test.dart`. Test the arm-construction logic against a fake loopback
server the way `probe_format_test.dart` and `probe_timeout_test.dart` already do — assert on the request
bodies that reach the wire, not on model output:

- the `unpinned` arm's `options` carries `temperature`, `num_ctx` and `seed` and does **not** carry
  `top_k`, `top_p` or `presence_penalty`
- the `pinned-historical` arm's `options` carries all of those, with `top_k` 40, `top_p` 0.9,
  `presence_penalty` 0
- both arms send the identical `seed` and identical messages

```bash
fvm dart test test/gguf_defaults_probe_test.dart
```

Expected: FAIL — the probe does not exist.

- [x] **Step 2: Write `gguf_defaults_probe.dart` and make the test pass**

Reuse `probe_support.dart` (`probeOnce`, `parseProbeArgs`, `probeAssetsDir`) rather than re-deriving any
of it. Take `--model` (default `qwen3.5:9b`), `--samples` (default 3), `--temperature` (default 0.6),
`--seed` (default a fixed constant), `--json` and `--url`, matching the other probes' flags. Record for
each arm: the reply hash, character count, and `ms`. Follow the repo's serialization convention —
hand-written `toJson()`, no code-gen — and give the file a `///` header explaining **why** the probe
exists and how to read a result, as the sibling probes do.

Going through `probeOnce` also inherits the timeout behaviour deliberately, and the probe must not
bypass it: a timed-out call issues `evictModel()` (`probe_support.dart:295`), a `keep_alive: 0` unload
to `/api/generate`, so a hung or runaway generation cannot cascade into the calls after it. Two
consequences for this probe. Do not add a competing timeout or unload path. And note that an eviction
forces the next call to pay a cold load, so **`ms` either side of a timeout is not comparable** — the
reply-hash comparison is the load-bearing measurement here and is unaffected, because the seed and the
parameters determine the output regardless of whether the runner was reloaded first.

```bash
fvm dart test test/gguf_defaults_probe_test.dart
fvm dart analyze
```

Expected: PASS, no analyzer issues.

- [x] **Step 3: Confirm the machine is idle and the model's parameters are still what this assumes**

```bash
ollama ps
curl -s http://127.0.0.1:11434/api/version
ollama show --modelfile qwen3.5:9b | grep -i '^PARAMETER'
```

Expected: nothing resident; `{"version":"0.33.3"}`; `top_k 20`, `top_p 0.95`, `presence_penalty 1.5`
present. **If the parameters are absent, stop** — the premise is gone and the probe cannot produce a
result. Record that instead.

- [x] **Step 4: Run both arms at a sampled temperature**

```bash
fvm dart run tool/model_probes/gguf_defaults_probe.dart \
  --model qwen3.5:9b --temperature 0.6 --samples 3 \
  --json tool/model_probes/results-m1max-64gb-ollama0333/qwen3.5_9b/gguf_defaults_probe.json
ollama stop qwen3.5:9b
ollama ps
```

Expected: nothing resident afterwards.

- [x] 🔍 **UNEXPECTED RESULT** — **Step 5: Run the greedy control**

```bash
fvm dart run tool/model_probes/gguf_defaults_probe.dart \
  --model qwen3.5:9b --temperature 0 --samples 2 \
  --json /dev/null
ollama stop qwen3.5:9b
```

At `t=0` the two arms **should** agree, because greedy decoding takes the argmax regardless of the
candidate-set parameters. If they disagree here, something other than sampling differs between the arms
and the `t=0.6` result cannot be attributed to the parameters — investigate before recording anything.
This control is what makes the main result interpretable.

_Executed 2026-09-04: the control disagreed, contradicting the step's own expectation. Traced to `presence_penalty`, which shifts logits before the argmax and so is not shielded by greedy decoding, the way `top_k`/`top_p` are — this narrowed a claim the notebook already published, that `t=0` figures are shielded from the upgrade, and became a finding rather than a blocker. The isolation was first done with a throwaway script, then folded into the committed probe as two further arms (commit `210ad9b`) so it is re-runnable._

- [x] **Step 6: Read the result and record it**

Compare reply hashes per sample between arms. Report: how many of the `t=0.6` samples differ between
arms, how many of the `t=0` control samples differ (expected 0), and the model, runtime and date.

Then rewrite the caveat Task 4 added to `ModelBehavior.md`. Locate it by grepping its wording, not by
line number. Replace the hedged "may not be comparable" with what was measured, in the file's register.
A null result is written as plainly as a positive one. **Hedge the mechanism, not the count**: how many
replies differed is measured; _why_ Ollama applied or ignored the Modelfile values is not, unless it was
confirmed from server logs.

Keep the claim scoped to what one model shows. One GGUF model on one host is evidence about that path,
not a property of every GGUF build — say so.

- [x] **Step 7: Add a `CHANGELOG.md` bullet under `## [Unreleased]`**

Inside the existing list, no blank line between bullets.

- [x] **Step 8: Verify the gates**

```bash
fvm dart analyze
fvm dart test
fvm dart format --output=none --set-exit-if-changed lib/ test/ tool/
fvm dart run tool/model_probes/check_results.dart
cd .. && npm run format:md:chat && npm run check:md:chat
```

Do **not** add this probe to `expectedProbes` in `check_results.dart` — it is a one-off on a single
model, and adding it would report every other model as incomplete.

- [x] **Step 9: Commit**

```bash
git add tool/model_probes/gguf_defaults_probe.dart test/gguf_defaults_probe_test.dart \
        tool/model_probes/results-m1max-64gb-ollama0333/qwen3.5_9b/gguf_defaults_probe.json \
        ModelBehavior.md CHANGELOG.md
git commit -m "measure(chat-server): whether 0.33.3 honoring GGUF defaults moves sampled output"
```

---

### Task 10: Give `prefill_cache_probe.dart` a `--json` flag, and archive the runs it has been reporting to stdout

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/prefill_cache_probe.dart`
- Test: `adaptive_chat_server_dart/test/prefill_cache_probe_test.dart` (create)
- Create: `adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama0333/llama3.2_latest/prefill_cache_probe.json`
- Create: `adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama0333/qwen3.8_27b-nvfp4/prefill_cache_probe.json`
- Modify: `adaptive_chat_server_dart/ModelBehavior.md` (the prompt-cache section)
- Modify: `adaptive_chat_server_dart/CHANGELOG.md` (`## [Unreleased]`)

**Why this task exists.** Every prompt-cache figure in the notebook — both hosts, both models, roughly twenty numbers — has no archived run behind it. `prefill_cache_probe.dart` prints to stdout and writes nothing, so the figures were transcribed from terminal output and `check_results.dart` cannot verify any of them. The notebook discloses this honestly, calling them "a spot measurement to be re-run rather than an archived row", so this is not a correctness defect. But it is inconsistent with how the rest of this tree treats published figures: a 5-case control arm was archived during the 2026-09-04 work on the explicit reasoning that a published figure with no archived provenance is worse than the naming hazard of archiving it. That reasoning applies with more force to twenty cache numbers than it did to the control arm.

**What this task is not.** It is not a re-measurement that replaces the published figures, and it must not quietly overwrite them. The `qwen3.8:27b-nvfp4` retry-after-abort row is **known unstable** — 148 ms with 3472/3477 cached on one run, 18,154 ms with 2063/3477 on the next — so a fresh run is a third observation, not a correction. Treat it as one.

- [x] **Step 1: Write the failing test first**

Create `test/prefill_cache_probe_test.dart`. Follow `probe_format_test.dart` and `gguf_defaults_probe_test.dart`: stand up a fake loopback `HttpServer`, drive the probe's result-building against it, and assert on structure rather than on model output. Assert that a run written with `--json`:

- produces a `ProbeRun` whose `calls` carry one entry per request the probe issues, with the phase name in `caseId`
- records `prompt`, `cached` and prefill milliseconds for each call somewhere machine-readable, not only inside a human label string
- round-trips: reading the written file back yields the same figures the probe reported

```bash
fvm dart test test/prefill_cache_probe_test.dart
```

Expected: FAIL — no `--json` support exists.

- [x] **Step 2: Add `--json` using the existing result API**

`parseProbeArgs` already supplies `--json`; the probe currently ignores it. Write results with `writeProbeRun` from `probe_results.dart` (`:367`) — do not invent a second result format. Its parameters are `path`, `probe`, `model`, `samples`, `assetsDir`, `calls`, and optionally `variant`, `temperature`, `summary`, `notes`, `assetNames`. `machine`, `ollama` and `measuredAt` are filled in for you by `detectMachine()`/`detectOllamaVersion()`.

Two modelling decisions to make deliberately and record in the doc comment:

- **`caseId`** carries the phase: `identical-repeat`, `new-question`, `growing-conversation`, `interleaved`, `retry-after-abort`. Note that `ProbeCall.caseId` serialises to the JSON key **`case`**, not `caseId` — a reader of the file sees `case`.
- **`pass` means the call completed**, not that the cache behaved as hoped. This probe scores no cards and asserts no cache expectation; baking a pass/fail judgement about cache reuse into the record would freeze today's interpretation into the archive. Put the interpretation in `summary` and `notes` instead, where `gguf_defaults_probe.dart` already sets the precedent.

Put the per-phase cache figures in `summary` as structured values (prompt tokens, cached tokens, prefill ms) so a later reader can compute against them without parsing prose.

- [x] **Step 3: Verify the test passes and the gates are clean**

```bash
fvm dart test
fvm dart analyze
fvm dart format --output=none --set-exit-if-changed lib/ test/ tool/
```

- [x] ⚠️ **DIVERGED** — **Step 4: Confirm the machine is idle, then archive both models**

One model resident at a time. `llama3.2:latest` is ~2 GB, `qwen3.8:27b-nvfp4` ~18 GB.

```bash
ollama ps
curl -s http://127.0.0.1:11434/api/version

fvm dart run tool/model_probes/prefill_cache_probe.dart --model llama3.2:latest \
  --json tool/model_probes/results-m1max-64gb-ollama0333/llama3.2_latest/prefill_cache_probe.json
ollama stop llama3.2:latest
ollama ps

fvm dart run tool/model_probes/prefill_cache_probe.dart --model qwen3.8:27b-nvfp4 \
  --json tool/model_probes/results-m1max-64gb-ollama0333/qwen3.8_27b-nvfp4/prefill_cache_probe.json
ollama stop qwen3.8:27b-nvfp4
ollama ps
```

If `ollama ps` sticks at `Stopping...` and will not clear, stop and report it. That happened twice during the 2026-09-04 work, both times after schema-constrained `carousel` timeouts, and an acknowledged `keep_alive: 0` unload did not clear it.

_Executed 2026-09-05: the probe ran four times on `qwen3.8:27b-nvfp4`, not once — the archived run, a same-day unarchived corroboration run of its full five-phase probe (kept in `scratchpad`, not committed, taken to check a since-retracted "flip" reading before it was recorded), and both archives (`llama3.2:latest` and `qwen3.8:27b-nvfp4`) were later regenerated after a probe-recording defect was found and fixed — `prefill_cache_probe.dart` recorded digests for asset files (`card_system_prompt.txt`, `seed_card.json`) it never reads — so the records would come from the code that claims to produce them, with no cache-figure changes intended._

- [x] 🔍 **UNEXPECTED RESULT** — **Step 5: Reconcile the new run against the published figures**

This is the load-bearing step. Compare each phase against what `ModelBehavior.md` already publishes.

- Where the new run **agrees**, say so and cite the archived file as the backing run. The figures do not need to change.
- Where it **disagrees**, do not overwrite. Add it as a further observation, following the presentation the notebook already uses for `qwen3.8:27b-nvfp4`, which shows two runs side by side.
- The **retry-after-abort row is expected to vary**. A third observation is worth having precisely because two points showed roughly 100x spread without establishing a distribution. Report what it reads; do not average the three, and do not claim a frequency that three points cannot support.
- The **M5 figures cannot be re-archived** from this host. Whatever else changes, the notebook must keep disclosing that the M5 readings remain a stdout-only spot measurement.

_Executed 2026-09-05: this step produced a wrong finding first, not the reconciliation as planned. Reconciling the new run against the interleaved-request row surfaced an apparent day-to-day behavioural "flip", which was traced to a pre-existing mislabeled table row — the unrelated request's own miss figures had been recorded under the label for the repeat that follows it — and retracted once the mislabeling was found, not reported as a finding. A second over-claim was then found and corrected: the interleaved-unrelated miss is structurally expected on any model sending a genuinely different prompt sharing only a short instruction prefix, not a large-model-specific finding, so the notebook's "two confirmed misses" became one — only the cross-question miss is genuinely model-specific._

- [x] **Step 6: Update the notebook and the changelog**

Amend the prompt-cache section to say which figures now have an archived run behind them and which do not. Locate the section by grepping `prompt_eval_cached_count` rather than by line number.

Register: flat analytical, no amplifying adverbs, figures rather than superlatives, bold only for a section's load-bearing claim or a figure, hedge inferred mechanisms, end on the last factual sentence. **Never change an existing figure while changing wording** — and note that this task legitimately _may_ change figures if the re-run disagrees, so the numeric-token diff's job here is to confirm every decrease was intended, not that there are none.

Add one `CHANGELOG.md` bullet under `## [Unreleased]`, inside the existing list, no blank line between bullets.

- [x] **Step 7: Verify**

```bash
fvm dart test
fvm dart analyze
fvm dart format --output=none --set-exit-if-changed lib/ test/ tool/
fvm dart run tool/model_probes/check_results.dart
cd .. && npm run format:md:chat && npm run check:md:chat
```

`check_results.dart` will read two more runs than before. **Do not add `prefill_cache_probe` to `expectedProbes`** — it is a standalone diagnostic, `sweep.sh` does not run it, and adding it would report every model in every archive as missing it.

- [x] **Step 8: Commit**

```bash
git add tool/model_probes/prefill_cache_probe.dart test/prefill_cache_probe_test.dart \
        tool/model_probes/results-m1max-64gb-ollama0333/llama3.2_latest/prefill_cache_probe.json \
        tool/model_probes/results-m1max-64gb-ollama0333/qwen3.8_27b-nvfp4/prefill_cache_probe.json \
        ModelBehavior.md CHANGELOG.md
git commit -m "feat(chat-server): archive prefill cache probe runs behind a --json flag"
```

---

## Deliberately out of scope

- **Promoting `--json-format schema` into `launch.json`.** Measuring is this plan; shipping is a separate decision with a known cost (it forbids the prompt's Markdown escape hatch).
- **A full 0.33.3 re-sweep of all fifteen models.** Task 4 records the comparability caveat instead. A re-sweep is ~5 hours of wall clock and its own plan.
- **The `granite4.1:3b` cascade-damaged rows** and the open question of whether a runaway generation can be cancelled at all (`ModelBehavior.md:311`, `:350`). Still open, still M1 Max work, not this plan.
- **`gpt-oss:20b`.** Its canary is `ignored-destructively` on both runtimes measured; the constraint eliminates card production there rather than tightening it.
